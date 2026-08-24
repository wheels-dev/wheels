/**
 * Hardener proofs for Jobs BLOCKERs B1–B4 and SHOULDs S1–S10.
 * Desk IDs are stable. Do not renumber.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("Jobs hardener B1–B4", function() {

			beforeEach(function() {
				local.bootstrapJob = new wheels.Job();
				local.bootstrapJob.$ensureJobTable();
				try {
					queryExecute("DELETE FROM wheels_jobs WHERE queue LIKE 'test_hard_%'", {}, {datasource = application.wheels.dataSourceName});
				} catch (any e) {
				}
			});

			afterEach(function() {
				if (StructKeyExists(request, "wheels")) {
					StructDelete(request.wheels, "tenant");
				}
				StructDelete(request, "$wheelsSlowJobFinished");
				StructDelete(request, "$wheelsOffPathConstructed");
				StructDelete(request, "$wheelsOffPathRan");
				try {
					queryExecute("DELETE FROM wheels_jobs WHERE queue LIKE 'test_hard_%'", {}, {datasource = application.wheels.dataSourceName});
				} catch (any e) {
				}
			});

			it("B1: fail/retry UPDATE does not overwrite a stolen job already completed", function() {
				local.id = CreateUUID();
				local.payload = SerializeJSON({jobId: local.id});
				$insertTestJob(
					id = local.id,
					jobClass = "wheels.tests._assets.jobs.StealDuringPerformJob",
					queue = "test_hard_b1_fail",
					data = local.payload
				);

				local.processor = new wheels.Job();
				prepareMock(local.processor);
				makePublic(local.processor, "$processJob");
				local.jobResult = local.processor.$processJob(
					jobRow = {
						id = local.id,
						jobClass = "wheels.tests._assets.jobs.StealDuringPerformJob",
						queue = "test_hard_b1_fail",
						data = local.payload,
						attempts = 0,
						maxRetries = 3
					}
				);

				expect(local.jobResult.success).toBeFalse();
				expect(local.jobResult.skipped).toBeFalse();

				local.row = queryExecute(
					"SELECT status FROM wheels_jobs WHERE id = :id",
					{id = {value = local.id, cfsqltype = "cf_sql_varchar"}},
					{datasource = application.wheels.dataSourceName}
				);
				expect(local.row.status).toBe("completed");
			});

			it("B1: complete UPDATE does not overwrite a stolen job already failed", function() {
				local.id = CreateUUID();
				local.payload = SerializeJSON({jobId: local.id});
				$insertTestJob(
					id = local.id,
					jobClass = "wheels.tests._assets.jobs.StealToFailedJob",
					queue = "test_hard_b1_complete",
					data = local.payload
				);

				local.worker = new wheels.JobWorker();
				prepareMock(local.worker);
				makePublic(local.worker, "$executeJob");
				local.execResult = local.worker.$executeJob(
					jobRow = {
						id = local.id,
						jobClass = "wheels.tests._assets.jobs.StealToFailedJob",
						queue = "test_hard_b1_complete",
						data = local.payload,
						attempts = 0,
						maxRetries = 3
					}
				);

				expect(local.execResult.success).toBeTrue();

				local.row = queryExecute(
					"SELECT status FROM wheels_jobs WHERE id = :id",
					{id = {value = local.id, cfsqltype = "cf_sql_varchar"}},
					{datasource = application.wheels.dataSourceName}
				);
				expect(local.row.status).toBe("failed");
			});

			it("B1: checkTimeouts retry/fail UPDATE does not overwrite completed", function() {
				local.id = CreateUUID();
				local.oldTime = DateAdd("s", -600, Now());
				$insertTestJob(
					id = local.id,
					jobClass = "app.jobs.ProcessOrdersJob",
					queue = "test_hard_b1_timeout",
					status = "processing",
					attempts = 1,
					createdAt = local.oldTime,
					updatedAt = local.oldTime
				);
				local.now = Now();
				queryExecute(
					"UPDATE wheels_jobs SET status = 'completed', completedAt = :now WHERE id = :id",
					{
						id = {value = local.id, cfsqltype = "cf_sql_varchar"},
						now = {value = local.now, cfsqltype = "cf_sql_timestamp"}
					},
					{datasource = application.wheels.dataSourceName}
				);

				local.worker = new wheels.JobWorker();
				prepareMock(local.worker);
				makePublic(local.worker, "$scheduleRetry");
				local.worker.$scheduleRetry(
					jobId = local.id,
					currentAttempts = 1,
					jobClass = "app.jobs.ProcessOrdersJob",
					maxRetries = 3,
					errorMessage = "Job timed out after 300 seconds"
				);

				local.row = queryExecute(
					"SELECT status FROM wheels_jobs WHERE id = :id",
					{id = {value = local.id, cfsqltype = "cf_sql_varchar"}},
					{datasource = application.wheels.dataSourceName}
				);
				expect(local.row.status).toBe("completed");
			});

			it("B2: persist fail does not return status=pending", function() {
				local.job = new wheels.tests._assets.jobs.PersistFailJob();
				local.result = local.job.enqueue(data = {test: true});

				expect(local.result).toHaveKey("persisted");
				expect(local.result.persisted).toBeFalse();
				expect(local.result).toHaveKey("error");
				expect(Len(local.result.error)).toBeGT(0);
				if (StructKeyExists(local.result, "status")) {
					expect(local.result.status).notToBe("pending");
				}
			});

			it("B2: successful enqueue still returns status=pending and persisted=true", function() {
				local.job = new app.jobs.ProcessOrdersJob();
				local.result = local.job.enqueue(data = {batchSize: 1}, queue = "test_hard_b2_ok");

				expect(local.result.persisted).toBeTrue();
				expect(local.result.status).toBe("pending");
				expect(local.result).toHaveKey("id");
				expect(Len(local.result.id)).toBeGT(0);
			});

			it("B3: getMonitorData queue filter applies to recentJobs and oldestPending", function() {
				local.otherCreated = DateAdd("h", -2, Now());
				local.targetCreated = DateAdd("h", -1, Now());
				local.otherPending = CreateUUID();
				local.targetPending = CreateUUID();
				local.otherDone = CreateUUID();
				local.targetDone = CreateUUID();

				$insertTestJob(
					id = local.otherPending,
					jobClass = "app.jobs.ProcessOrdersJob",
					queue = "test_hard_b3_other",
					status = "pending",
					createdAt = local.otherCreated,
					updatedAt = local.otherCreated
				);
				$insertTestJob(
					id = local.targetPending,
					jobClass = "app.jobs.ProcessOrdersJob",
					queue = "test_hard_b3_target",
					status = "pending",
					createdAt = local.targetCreated,
					updatedAt = local.targetCreated
				);
				$insertTestJob(
					id = local.otherDone,
					jobClass = "app.jobs.ProcessOrdersJob",
					queue = "test_hard_b3_other",
					status = "completed"
				);
				$insertTestJob(
					id = local.targetDone,
					jobClass = "app.jobs.ProcessOrdersJob",
					queue = "test_hard_b3_target",
					status = "completed"
				);

				local.worker = new wheels.JobWorker();
				local.data = local.worker.getMonitorData(queue = "test_hard_b3_target", minutes = 180);

				expect(local.data).toHaveKey("recentJobs");
				expect(ArrayLen(local.data.recentJobs)).toBeGT(0);
				for (local.recent in local.data.recentJobs) {
					expect(local.recent.queue).toBe("test_hard_b3_target");
				}

				expect(IsDate(local.data.oldestPending)).toBeTrue();
				expect(Abs(DateDiff("s", local.targetCreated, local.data.oldestPending))).toBeLTE(2);
			});

			it("S2/S3: config() backoff is applied and linear stays exponential", function() {
				local.configId = CreateUUID();
				local.linearId = CreateUUID();
				$insertTestJob(id = local.configId, jobClass = "wheels.tests._assets.jobs.ConfigBackoffJob", queue = "test_hard_s3");
				$insertTestJob(id = local.linearId, jobClass = "wheels.tests._assets.jobs.LinearBackoffJob", queue = "test_hard_s2");

				local.processor = new wheels.Job();
				prepareMock(local.processor);
				makePublic(local.processor, "$processJob");

				local.processor.$processJob(
					jobRow = {
						id = local.configId,
						jobClass = "wheels.tests._assets.jobs.ConfigBackoffJob",
						queue = "test_hard_s3",
						data = "{}",
						attempts = 0,
						maxRetries = 3
					}
				);
				local.processor.$processJob(
					jobRow = {
						id = local.linearId,
						jobClass = "wheels.tests._assets.jobs.LinearBackoffJob",
						queue = "test_hard_s2",
						data = "{}",
						attempts = 0,
						maxRetries = 3
					}
				);

				local.threshold = DateAdd("s", 600, Now());
				local.configCheck = queryExecute(
					"SELECT COUNT(*) AS cnt FROM wheels_jobs WHERE id = :id AND status = 'pending' AND runAt > :threshold",
					{
						id = {value = local.configId, cfsqltype = "cf_sql_varchar"},
						threshold = {value = local.threshold, cfsqltype = "cf_sql_timestamp"}
					},
					{datasource = application.wheels.dataSourceName}
				);
				local.linearCheck = queryExecute(
					"SELECT COUNT(*) AS cnt FROM wheels_jobs WHERE id = :id AND status = 'pending' AND runAt > :threshold",
					{
						id = {value = local.linearId, cfsqltype = "cf_sql_varchar"},
						threshold = {value = local.threshold, cfsqltype = "cf_sql_timestamp"}
					},
					{datasource = application.wheels.dataSourceName}
				);
				expect(local.configCheck.cnt).toBe(1);
				expect(local.linearCheck.cnt).toBe(1);
			});

			it("S5/S6: idle queue stays skipped and does not throw", function() {
				local.worker = new wheels.JobWorker();
				local.result = local.worker.processNext(queues = "test_hard_idle_#CreateUUID()#");
				expect(local.result.skipped).toBeTrue();
				expect(local.result.success).toBeFalse();
				expect(local.result.error).toBe("");

				local.job = new wheels.Job();
				local.batch = local.job.processQueue(queue = "test_hard_idle_#CreateUUID()#");
				expect(local.batch.processed).toBe(0);
				expect(local.batch.failed).toBe(0);
			});

			it("S1: enqueue persists timeout=300 and perform honors it", function() {
				local.job = new app.jobs.ProcessOrdersJob();
				local.enqueued = local.job.enqueue(data = {batchSize: 1}, queue = "test_hard_s1_persist");
				expect(local.enqueued.persisted).toBeTrue();
				local.row = queryExecute(
					"SELECT data FROM wheels_jobs WHERE id = :id",
					{id = {value = local.enqueued.id, cfsqltype = "cf_sql_varchar"}},
					{datasource = application.wheels.dataSourceName}
				);
				local.stored = DeserializeJSON(local.row.data);
				expect(local.stored).toHaveKey("$wheelsJobTimeout");
				expect(Val(local.stored["$wheelsJobTimeout"])).toBe(300);

				local.slowId = CreateUUID();
				$insertTestJob(
					id = local.slowId,
					jobClass = "wheels.tests._assets.jobs.SlowTimeoutJob",
					queue = "test_hard_s1_honor",
					data = SerializeJSON({"$wheelsJobTimeout": 1})
				);
				local.processor = new wheels.Job();
				prepareMock(local.processor);
				makePublic(local.processor, "$processJob");
				local.jobResult = local.processor.$processJob(
					jobRow = {
						id = local.slowId,
						jobClass = "wheels.tests._assets.jobs.SlowTimeoutJob",
						queue = "test_hard_s1_honor",
						data = SerializeJSON({"$wheelsJobTimeout": 1}),
						attempts = 0,
						maxRetries = 3
					}
				);
				expect(local.jobResult.success).toBeFalse();
				expect(StructKeyExists(request, "$wheelsSlowJobFinished")).toBeFalse();
			});

			it("S4: unknown db pending SELECT is bounded by candidateLimit", function() {
				local.worker = new wheels.JobWorker();
				prepareMock(local.worker);
				makePublic(local.worker, "$candidateLimitClause");
				local.clause = local.worker.$candidateLimitClause(dbType = "unknown");
				expect(local.clause).toInclude("LIMIT");
				expect(local.clause).toInclude("25");
			});

			it("S7: enqueue does not persist tenant.config and restore allowlists dataSource", function() {
				if (!StructKeyExists(request, "wheels")) {
					request.wheels = {};
				}
				request.wheels.tenant = {
					id = "t-s7",
					dataSource = application.wheels.dataSourceName,
					config = {secret = "s7-must-not-persist", nested = {token = "abc"}}
				};
				local.job = new app.jobs.ProcessOrdersJob();
				local.enqueued = local.job.enqueue(data = {orderId = 1}, queue = "test_hard_s7");
				expect(local.enqueued.persisted).toBeTrue();
				local.row = queryExecute(
					"SELECT data FROM wheels_jobs WHERE id = :id",
					{id = {value = local.enqueued.id, cfsqltype = "cf_sql_varchar"}},
					{datasource = application.wheels.dataSourceName}
				);
				local.stored = DeserializeJSON(local.row.data);
				expect(SerializeJSON(local.stored)).notToInclude("s7-must-not-persist");
				expect(local.stored).toHaveKey("$wheelsTenantContext");
				expect(local.stored["$wheelsTenantContext"]).notToHaveKey("config");
				StructDelete(request.wheels, "tenant");

				local.evil = {orderId = 9};
				local.evil["$wheelsTenantContext"] = {
					id = "evil",
					dataSource = "wheels_jobs_arbitrary_ds_zzz",
					config = {secret = "s7-must-not-restore"}
				};
				local.bridge = new wheels.Job();
				expect(local.bridge.$restoreTenantContext(local.evil)).toBeFalse();
				expect(IsDefined("request.wheels.tenant")).toBeFalse();

				local.ok = {};
				local.ok["$wheelsTenantContext"] = {
					id = "tenant-ok",
					dataSource = application.wheels.dataSourceName,
					config = {secret = "s7-must-not-restore"}
				};
				expect(local.bridge.$restoreTenantContext(local.ok)).toBeTrue();
				expect(request.wheels.tenant.dataSource).toBe(application.wheels.dataSourceName);
				expect(request.wheels.tenant).notToHaveKey("config");
				local.bridge.$clearTenantContext();
			});

			it("S8: off-path class with perform() is not instantiated", function() {
				var thrown = {type: ""};
				StructDelete(request, "$wheelsOffPathConstructed");
				StructDelete(request, "$wheelsOffPathRan");
				local.bridge = new wheels.Job();
				try {
					local.bridge.$instantiateJobClass(jobClass = "wheels.tests._assets.offpath.OffPathPerformJob");
				} catch (any e) {
					thrown.type = e.type;
				}
				expect(thrown.type).toBe("Wheels.JobClassNotAllowed");
				expect(StructKeyExists(request, "$wheelsOffPathConstructed")).toBeFalse();
				expect(StructKeyExists(request, "$wheelsOffPathRan")).toBeFalse();
			});

			it("S9: maxRetries=3 allows 4 tries (retries after first fail)", function() {
				local.id = CreateUUID();
				$insertTestJob(
					id = local.id,
					jobClass = "wheels.tests._assets.jobs.FailingBackoffJob",
					queue = "test_hard_s9",
					attempts = 2,
					maxRetries = 3
				);
				local.processor = new wheels.Job();
				prepareMock(local.processor);
				makePublic(local.processor, "$processJob");
				local.processor.$processJob(
					jobRow = {
						id = local.id,
						jobClass = "wheels.tests._assets.jobs.FailingBackoffJob",
						queue = "test_hard_s9",
						data = "{}",
						attempts = 2,
						maxRetries = 3
					}
				);
				local.row = queryExecute(
					"SELECT status FROM wheels_jobs WHERE id = :id",
					{id = {value = local.id, cfsqltype = "cf_sql_varchar"}},
					{datasource = application.wheels.dataSourceName}
				);
				expect(local.row.status).toBe("pending");
			});

			it("S10: retryFailed and purgeCompleted return the real DML count", function() {
				local.emptyQ = "test_hard_s10_empty_#CreateUUID()#";
				local.job = new wheels.Job();
				expect(local.job.retryFailed(queue = local.emptyQ)).toBe(0);

				local.failA = CreateUUID();
				local.failB = CreateUUID();
				$insertTestJob(id = local.failA, jobClass = "app.jobs.ProcessOrdersJob", queue = "test_hard_s10_retry", status = "failed", attempts = 3);
				$insertTestJob(id = local.failB, jobClass = "app.jobs.ProcessOrdersJob", queue = "test_hard_s10_retry", status = "failed", attempts = 3);
				expect(local.job.retryFailed(queue = "test_hard_s10_retry")).toBe(2);

				local.oldTime = DateAdd("d", -30, Now());
				local.doneA = CreateUUID();
				local.doneB = CreateUUID();
				$insertTestJob(id = local.doneA, jobClass = "app.jobs.ProcessOrdersJob", queue = "test_hard_s10_purge", status = "completed", createdAt = local.oldTime, updatedAt = local.oldTime);
				$insertTestJob(id = local.doneB, jobClass = "app.jobs.ProcessOrdersJob", queue = "test_hard_s10_purge", status = "completed", createdAt = local.oldTime, updatedAt = local.oldTime);
				queryExecute(
					"UPDATE wheels_jobs SET completedAt = :oldTime WHERE id IN (:a, :b)",
					{
						oldTime = {value = local.oldTime, cfsqltype = "cf_sql_timestamp"},
						a = {value = local.doneA, cfsqltype = "cf_sql_varchar"},
						b = {value = local.doneB, cfsqltype = "cf_sql_varchar"}
					},
					{datasource = application.wheels.dataSourceName}
				);
				expect(local.job.purgeCompleted(days = 7, queue = "test_hard_s10_purge")).toBe(2);
			});

		});
	}

	private void function $insertTestJob(
		required string id,
		required string jobClass,
		required string queue,
		string status = "pending",
		string data = "{}",
		numeric attempts = 0,
		numeric maxRetries = 3,
		createdAt = "",
		updatedAt = ""
	) {
		local.stamp = Now();
		local.createdAt = IsDate(arguments.createdAt) ? arguments.createdAt : local.stamp;
		local.updatedAt = IsDate(arguments.updatedAt) ? arguments.updatedAt : local.stamp;
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
				runAt = {value = local.createdAt, cfsqltype = "cf_sql_timestamp"},
				createdAt = {value = local.createdAt, cfsqltype = "cf_sql_timestamp"},
				updatedAt = {value = local.updatedAt, cfsqltype = "cf_sql_timestamp"}
			},
			{datasource = application.wheels.dataSourceName}
		);
	}

}
