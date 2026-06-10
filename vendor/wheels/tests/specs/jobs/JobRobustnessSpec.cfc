/**
 * Regression tests for job-system robustness fixes:
 * - $processJob must surface job failures instead of throwing a secondary
 *   "variable doesn't exist" error that aborts the whole processQueue batch
 * - JobWorker.$executeJob must restore tenant context and strip the internal
 *   $wheelsTenantContext key exactly like Job.$processJob
 * - JobWorker.retryFailed without a limit must report only the rows actually reset
 * - Retry backoff must honor the failing job class's own delay settings
 * - JobWorker.processNext must deliver the full payload after the single-row claim
 * - JobWorker.$ensureJobTable must actually create the table on a fresh database
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("Job processing robustness", function() {

			beforeEach(function() {
				// Make sure the table exists, then clear leftovers from prior runs
				local.bootstrapJob = new wheels.Job();
				local.bootstrapJob.$ensureJobTable();
				try {
					queryExecute("DELETE FROM wheels_jobs WHERE queue LIKE 'test_rob_%'", {}, {datasource = application.wheels.dataSourceName});
				} catch (any e) {
				}
			});

			afterEach(function() {
				// Never leak tenant context or probe state into the rest of the suite
				if (StructKeyExists(request, "wheels")) {
					StructDelete(request.wheels, "tenant");
				}
				StructDelete(request, "$wheelsJobProbe");
				try {
					queryExecute("DELETE FROM wheels_jobs WHERE queue LIKE 'test_rob_%'", {}, {datasource = application.wheels.dataSourceName});
				} catch (any e) {
				}
			});

			it("reports an unresolvable job class as a job failure instead of throwing", function() {
				local.id = CreateUUID();
				$insertTestJob(id = local.id, jobClass = "wheels.tests._assets.jobs.NoSuchJobZZZ", queue = "test_rob_badclass");

				local.processor = new wheels.Job();
				prepareMock(local.processor);
				makePublic(local.processor, "$processJob");
				local.jobRow = {
					id = local.id,
					jobClass = "wheels.tests._assets.jobs.NoSuchJobZZZ",
					queue = "test_rob_badclass",
					data = "{}",
					attempts = 0,
					maxRetries = 3
				};

				// Pre-fix this threw "variable [hasTenantContext] doesn't exist", which
				// escaped $processJob and aborted the whole processQueue batch
				local.jobResult = local.processor.$processJob(jobRow = local.jobRow);

				expect(local.jobResult.success).toBeFalse();
				expect(local.jobResult.skipped).toBeFalse();
				expect(local.jobResult.error).toInclude(local.id);
			});

			it("schedules retries using the failing job class's own backoff settings", function() {
				local.id = CreateUUID();
				$insertTestJob(id = local.id, jobClass = "wheels.tests._assets.jobs.FailingBackoffJob", queue = "test_rob_backoff");

				local.processor = new wheels.Job();
				prepareMock(local.processor);
				makePublic(local.processor, "$processJob");
				local.jobRow = {
					id = local.id,
					jobClass = "wheels.tests._assets.jobs.FailingBackoffJob",
					queue = "test_rob_backoff",
					data = "{}",
					attempts = 0,
					maxRetries = 3
				};
				local.jobResult = local.processor.$processJob(jobRow = local.jobRow);
				expect(local.jobResult.success).toBeFalse();

				// FailingBackoffJob declares baseDelay=600, so the first retry is
				// scheduled Min(600 * 2^1, 7200) = 1200 seconds out. The base processing
				// instance's defaults (baseDelay=2) would schedule it only 4 seconds out.
				local.threshold = DateAdd("s", 600, Now());
				local.check = queryExecute(
					"SELECT COUNT(*) AS cnt FROM wheels_jobs WHERE id = :id AND status = 'pending' AND runAt > :threshold",
					{
						id = {value = local.id, cfsqltype = "cf_sql_varchar"},
						threshold = {value = local.threshold, cfsqltype = "cf_sql_timestamp"}
					},
					{datasource = application.wheels.dataSourceName}
				);
				expect(local.check.cnt).toBe(1);
			});

			it("worker path restores tenant context and strips the internal key", function() {
				local.payload = {orderId = 42};
				local.payload["$wheelsTenantContext"] = {id = "tenant-1", dataSource = "wheels_test_tenant_ds", config = {}};

				local.worker = new wheels.JobWorker();
				prepareMock(local.worker);
				makePublic(local.worker, "$executeJob");
				local.jobRow = {
					id = CreateUUID(),
					jobClass = "wheels.tests._assets.jobs.ProbeJob",
					queue = "test_rob_tenant",
					data = SerializeJSON(local.payload),
					attempts = 0,
					maxRetries = 3
				};
				local.execResult = local.worker.$executeJob(jobRow = local.jobRow);

				expect(local.execResult.success).toBeTrue();
				expect(request).toHaveKey("$wheelsJobProbe");
				expect(request.$wheelsJobProbe.sawInternalKey).toBeFalse();
				expect(request.$wheelsJobProbe.tenantRestored).toBeTrue();
				expect(request.$wheelsJobProbe.tenantDataSource).toBe("wheels_test_tenant_ds");
				expect(request.$wheelsJobProbe.tenantId).toBe("tenant-1");

				// And the context must be cleaned up after execution
				expect(IsDefined("request.wheels.tenant")).toBeFalse();
			});

			it("in-app path still restores tenant context via the shared helper", function() {
				local.id = CreateUUID();
				local.payload = {orderId = 7};
				local.payload["$wheelsTenantContext"] = {id = "tenant-2", dataSource = "wheels_test_tenant_ds", config = {}};
				$insertTestJob(
					id = local.id,
					jobClass = "wheels.tests._assets.jobs.ProbeJob",
					queue = "test_rob_tenant_app",
					data = SerializeJSON(local.payload)
				);

				local.processor = new wheels.Job();
				prepareMock(local.processor);
				makePublic(local.processor, "$processJob");
				local.jobRow = {
					id = local.id,
					jobClass = "wheels.tests._assets.jobs.ProbeJob",
					queue = "test_rob_tenant_app",
					data = SerializeJSON(local.payload),
					attempts = 0,
					maxRetries = 3
				};
				local.jobResult = local.processor.$processJob(jobRow = local.jobRow);

				expect(local.jobResult.success).toBeTrue();
				expect(request.$wheelsJobProbe.sawInternalKey).toBeFalse();
				expect(request.$wheelsJobProbe.tenantRestored).toBeTrue();
				expect(request.$wheelsJobProbe.tenantDataSource).toBe("wheels_test_tenant_ds");
				expect(IsDefined("request.wheels.tenant")).toBeFalse();
			});

			it("retryFailed without a limit reports only the rows actually reset", function() {
				local.failedId = CreateUUID();
				local.pendingId = CreateUUID();
				$insertTestJob(id = local.failedId, jobClass = "app.jobs.ProcessOrdersJob", queue = "test_rob_retry", status = "failed", attempts = 3);
				$insertTestJob(id = local.pendingId, jobClass = "app.jobs.ProcessOrdersJob", queue = "test_rob_retry", status = "pending");

				local.worker = new wheels.JobWorker();
				local.count = local.worker.retryFailed(queue = "test_rob_retry");

				// Pre-fix this returned 2: the count of ALL pending rows after the UPDATE
				expect(local.count).toBe(1);

				local.row = queryExecute(
					"SELECT status, attempts FROM wheels_jobs WHERE id = :id",
					{id = {value = local.failedId, cfsqltype = "cf_sql_varchar"}},
					{datasource = application.wheels.dataSourceName}
				);
				expect(local.row.status).toBe("pending");
				expect(local.row.attempts).toBe(0);
			});

			it("processNext delivers the full payload to perform after the single-row claim", function() {
				StructDelete(request, "$wheelsJobProbe");
				local.probe = CreateObject("component", "wheels.tests._assets.jobs.ProbeJob").init();
				local.enqueued = local.probe.enqueue(data = {orderId = 99, note = "payload-check"}, queue = "test_rob_payload");
				expect(local.enqueued.persisted).toBeTrue();

				local.worker = new wheels.JobWorker();
				local.result = local.worker.processNext(queues = "test_rob_payload");

				expect(local.result.success).toBeTrue();
				expect(request).toHaveKey("$wheelsJobProbe");
				expect(request.$wheelsJobProbe.data).toHaveKey("orderId");
				expect(request.$wheelsJobProbe.data.orderId).toBe(99);
				expect(request.$wheelsJobProbe.data.note).toBe("payload-check");
			});

			it("worker can bootstrap the wheels_jobs table on a fresh database", function() {
				try {
					queryExecute("DROP TABLE wheels_jobs", {}, {datasource = application.wheels.dataSourceName});
				} catch (any e) {
					// If the drop is not permitted, the ensure call below still verifies existence
				}

				local.worker = new wheels.JobWorker();
				prepareMock(local.worker);
				makePublic(local.worker, "$ensureJobTable");
				expect(local.worker.$ensureJobTable()).toBeTrue();

				// Pre-fix $ensureJobTable returned true without creating anything, so this
				// SELECT threw because the table still did not exist
				local.check = queryExecute(
					"SELECT COUNT(*) AS cnt FROM wheels_jobs WHERE 1=0",
					{},
					{datasource = application.wheels.dataSourceName}
				);
				expect(local.check.recordCount).toBe(1);
			});
		});
	}

	/**
	 * Insert a wheels_jobs row directly so specs control class, status, and attempts.
	 */
	private void function $insertTestJob(
		required string id,
		required string jobClass,
		required string queue,
		string status = "pending",
		string data = "{}",
		numeric attempts = 0,
		numeric maxRetries = 3
	) {
		local.now = Now();
		queryExecute(
			"INSERT INTO wheels_jobs (id, jobClass, queue, data, priority, status, attempts, maxRetries, runAt, createdAt, updatedAt)
			VALUES (:id, :jobClass, :queue, :data, 0, :status, :attempts, :maxRetries, :runAt, :createdAt, :updatedAt)",
			{
				id = {value = arguments.id, cfsqltype = "cf_sql_varchar"},
				jobClass = {value = arguments.jobClass, cfsqltype = "cf_sql_varchar"},
				queue = {value = arguments.queue, cfsqltype = "cf_sql_varchar"},
				data = {value = arguments.data, cfsqltype = "cf_sql_longvarchar"},
				status = {value = arguments.status, cfsqltype = "cf_sql_varchar"},
				attempts = {value = arguments.attempts, cfsqltype = "cf_sql_integer"},
				maxRetries = {value = arguments.maxRetries, cfsqltype = "cf_sql_integer"},
				runAt = {value = local.now, cfsqltype = "cf_sql_timestamp"},
				createdAt = {value = local.now, cfsqltype = "cf_sql_timestamp"},
				updatedAt = {value = local.now, cfsqltype = "cf_sql_timestamp"}
			},
			{datasource = application.wheels.dataSourceName}
		);
	}
}
