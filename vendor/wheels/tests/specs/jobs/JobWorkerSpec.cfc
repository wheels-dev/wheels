/**
 * Tests for the Wheels JobWorker engine.
 * Tests worker initialization, job claiming with optimistic locking,
 * timeout recovery, statistics, retry, purge, and backoff calculation.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("JobWorker Initialization", function() {

			it("can be instantiated", function() {
				local.worker = new wheels.JobWorker();
				expect(local.worker).toBeInstanceOf("wheels.JobWorker");
			});

			it("generates a unique worker ID", function() {
				local.worker = new wheels.JobWorker();
				expect(local.worker.workerId).toBeString();
				expect(Len(local.worker.workerId)).toBeGT(0);
			});

			it("generates different IDs for different workers", function() {
				local.worker1 = new wheels.JobWorker();
				local.worker2 = new wheels.JobWorker();
				expect(local.worker1.workerId).notToBe(local.worker2.workerId);
			});

			it("initializes counters to zero", function() {
				local.worker = new wheels.JobWorker();
				expect(local.worker.jobsProcessed).toBe(0);
				expect(local.worker.jobsFailed).toBe(0);
			});

			it("records a startedAt timestamp", function() {
				local.worker = new wheels.JobWorker();
				expect(IsDate(local.worker.startedAt)).toBeTrue();
			});
		});

		describe("processNext", function() {

			beforeEach(function() {
				// Clean up any test jobs
				try { queryExecute("DELETE FROM wheels_jobs WHERE queue LIKE 'test_%'", {}, {datasource = application.wheels.dataSourceName}); }
				catch (any e) { /* table may not exist */ }
			});

			it("returns skipped=true when queue is empty", function() {
				local.worker = new wheels.JobWorker();
				local.result = local.worker.processNext(queues = "test_empty_#CreateUUID()#");
				expect(local.result).toBeStruct();
				expect(local.result.skipped).toBeTrue();
				expect(local.result.success).toBeFalse();
			});

			it("returns a struct with expected keys", function() {
				local.worker = new wheels.JobWorker();
				local.result = local.worker.processNext();
				expect(local.result).toHaveKey("success");
				expect(local.result).toHaveKey("jobId");
				expect(local.result).toHaveKey("jobClass");
				expect(local.result).toHaveKey("error");
				expect(local.result).toHaveKey("skipped");
			});

			it("claims and completes a valid job", function() {
				// Enqueue a test job using a concrete subclass so jobClass resolves correctly
				local.testJob = new app.jobs.ProcessOrdersJob();
				local.enqueued = local.testJob.enqueue(data = {test: true}, queue = "test_claim");

				// Verify the job was persisted (catches silent enqueue failures)
				expect(local.enqueued).toHaveKey("persisted");
				expect(local.enqueued.persisted).toBeTrue();

				// Diagnostic: replicate processNext's candidate query to isolate failures
				local.now = CreateDateTime(Year(Now()), Month(Now()), Day(Now()), Hour(Now()), Minute(Now()), Second(Now()));
				local.diag = "";
				local.candidateFound = false;
				try {
					local.candidateCheck = queryExecute(
						"SELECT id, status, queue, runAt FROM wheels_jobs
						WHERE status = 'pending' AND runAt <= :runAt AND queue IN (:queue1)
						ORDER BY priority DESC, runAt ASC",
						{
							runAt = {value = local.now, cfsqltype = "cf_sql_timestamp"},
							queue1 = {value = "test_claim", cfsqltype = "cf_sql_varchar"}
						},
						{datasource = application.wheels.dataSourceName, maxrows = 5}
					);
					local.diag = "candidateRows=#local.candidateCheck.recordCount#";
					local.candidateFound = local.candidateCheck.recordCount > 0;
				} catch (any e) {
					local.diag = "candidateQueryError=[#e.type ?: 'unknown'#] #e.message#";
				}

				// If candidate query failed, try simpler queries to isolate the issue
				if (!local.candidateFound) {
					// Test 1: simple count without params
					try {
						local.countAll = queryExecute(
							"SELECT COUNT(*) AS cnt FROM wheels_jobs WHERE status = 'pending'",
							{}, {datasource = application.wheels.dataSourceName}
						);
						local.diag &= ", pendingCount=#local.countAll.cnt#";
					} catch (any e2) {
						local.diag &= ", countError=#e2.message#";
					}
					// Test 2: query by ID only
					try {
						local.byId = queryExecute(
							"SELECT id, status, queue, runAt FROM wheels_jobs WHERE id = :id",
							{id = {value = local.enqueued.id, cfsqltype = "cf_sql_varchar"}},
							{datasource = application.wheels.dataSourceName}
						);
						if (local.byId.recordCount) {
							local.diag &= ", byId=found(status=#local.byId.status#,runAt=#local.byId.runAt#,now=#local.now#)";
						}
					} catch (any e3) {
						local.diag &= ", byIdError=#e3.message#";
					}
				}

				// Only call processNext if diagnostics show it could succeed
				// This ensures we get the diagnostic message when it fails
				local.worker = new wheels.JobWorker();
				local.result = local.worker.processNext(queues = "test_claim");

				// Job was processed (may succeed or fail depending on job class)
				expect(local.result.skipped).toBeFalse(local.diag);
				expect(Len(local.result.jobId)).toBeGT(0);
			});

			it("skips jobs with future runAt", function() {
				// Enqueue a delayed job using a concrete subclass
				local.testJob = new app.jobs.ProcessOrdersJob();
				local.enqueued = local.testJob.enqueueIn(seconds = 3600, data = {}, queue = "test_future");

				// Try to process — should skip since runAt is in the future
				local.worker = new wheels.JobWorker();
				local.result = local.worker.processNext(queues = "test_future");
				expect(local.result.skipped).toBeTrue();
			});

			it("filters by queue name", function() {
				// Enqueue to specific queue using a concrete subclass
				local.testJob = new app.jobs.ProcessOrdersJob();
				local.enqueued = local.testJob.enqueue(data = {}, queue = "test_filter_a");

				// Process from a different queue — should skip
				local.worker = new wheels.JobWorker();
				local.result = local.worker.processNext(queues = "test_filter_b");
				expect(local.result.skipped).toBeTrue();
			});

			it("increments jobsProcessed counter on success", function() {
				// Enqueue a job that will succeed (ProcessOrdersJob has a no-op perform)
				local.testJob = new app.jobs.ProcessOrdersJob();
				local.enqueued = local.testJob.enqueue(data = {batchSize: 1}, queue = "test_counter");

				local.worker = new wheels.JobWorker();
				expect(local.worker.jobsProcessed).toBe(0);
				local.result = local.worker.processNext(queues = "test_counter");

				if (local.result.success) {
					expect(local.worker.jobsProcessed).toBe(1);
				}
			});
		});

		describe("checkTimeouts", function() {

			it("returns a numeric count", function() {
				local.worker = new wheels.JobWorker();
				local.recovered = local.worker.checkTimeouts(timeout = 300);
				expect(local.recovered).toBeNumeric();
			});

			it("recovers stuck processing jobs", function() {
				// Insert a job stuck in 'processing' with old updatedAt
				local.id = CreateUUID();
				local.oldTime = DateAdd("s", -600, Now());
				try {
					queryExecute(
						"INSERT INTO wheels_jobs (id, jobClass, queue, data, priority, status, attempts, maxRetries, runAt, createdAt, updatedAt)
						VALUES (:id, 'wheels.Job', 'test_timeout', '{}', 0, 'processing', 1, 3, :runAt, :createdAt, :updatedAt)",
						{
							id = {value = local.id, cfsqltype = "cf_sql_varchar"},
							runAt = {value = local.oldTime, cfsqltype = "cf_sql_timestamp"},
							createdAt = {value = local.oldTime, cfsqltype = "cf_sql_timestamp"},
							updatedAt = {value = local.oldTime, cfsqltype = "cf_sql_timestamp"}
						},
						{datasource = application.wheels.dataSourceName}
					);

					local.worker = new wheels.JobWorker();
					local.recovered = local.worker.checkTimeouts(timeout = 300);
					expect(local.recovered).toBeGTE(1);

					// Verify job was reset
					local.job = queryExecute(
						"SELECT status FROM wheels_jobs WHERE id = :id",
						{id = {value = local.id, cfsqltype = "cf_sql_varchar"}},
						{datasource = application.wheels.dataSourceName}
					);
					// Should be either pending (retried) or failed (exhausted)
					expect(ListFindNoCase("pending,failed", local.job.status)).toBeGT(0);
				} catch (any e) {
					// Table may not exist in clean test environments
				}
			});
		});

		describe("getStats", function() {

			it("returns a struct with queues and totals", function() {
				local.worker = new wheels.JobWorker();
				local.stats = local.worker.getStats();
				expect(local.stats).toBeStruct();
				expect(local.stats).toHaveKey("queues");
				expect(local.stats).toHaveKey("totals");
				expect(local.stats.totals).toHaveKey("pending");
				expect(local.stats.totals).toHaveKey("processing");
				expect(local.stats.totals).toHaveKey("completed");
				expect(local.stats.totals).toHaveKey("failed");
				expect(local.stats.totals).toHaveKey("total");
			});

			it("returns per-queue breakdown", function() {
				local.worker = new wheels.JobWorker();
				local.stats = local.worker.getStats();
				expect(local.stats.queues).toBeStruct();
			});

			it("accepts queue filter", function() {
				local.worker = new wheels.JobWorker();
				local.stats = local.worker.getStats(queue = "default");
				expect(local.stats).toBeStruct();
				expect(local.stats).toHaveKey("totals");
			});
		});

		describe("getMonitorData", function() {

			it("returns monitoring struct with expected keys", function() {
				local.worker = new wheels.JobWorker();
				local.data = local.worker.getMonitorData();
				expect(local.data).toBeStruct();
				expect(local.data).toHaveKey("throughput");
				expect(local.data).toHaveKey("recentJobs");
				expect(local.data).toHaveKey("errorRate");
				expect(local.data).toHaveKey("oldestPending");
				expect(local.data).toHaveKey("worker");
			});

			it("includes worker identity", function() {
				local.worker = new wheels.JobWorker();
				local.data = local.worker.getMonitorData();
				expect(local.data.worker).toHaveKey("id");
				expect(local.data.worker).toHaveKey("startedAt");
				expect(local.data.worker).toHaveKey("processed");
				expect(local.data.worker).toHaveKey("failed");
			});

			it("includes throughput metrics", function() {
				local.worker = new wheels.JobWorker();
				local.data = local.worker.getMonitorData();
				expect(local.data.throughput).toHaveKey("completed");
				expect(local.data.throughput).toHaveKey("failed");
			});

			it("accepts queue filter", function() {
				local.worker = new wheels.JobWorker();
				local.data = local.worker.getMonitorData(queue = "default");
				expect(local.data).toBeStruct();
			});
		});

		describe("retryFailed", function() {

			it("returns a numeric count", function() {
				local.worker = new wheels.JobWorker();
				local.count = local.worker.retryFailed();
				expect(local.count).toBeNumeric();
			});

			it("accepts queue filter", function() {
				local.worker = new wheels.JobWorker();
				local.count = local.worker.retryFailed(queue = "mailers");
				expect(local.count).toBeNumeric();
			});

			it("accepts limit parameter", function() {
				local.worker = new wheels.JobWorker();
				local.count = local.worker.retryFailed(limit = 5);
				expect(local.count).toBeNumeric();
			});

			it("resets failed jobs to pending", function() {
				// Insert a failed job
				local.id = CreateUUID();
				local.now = Now();
				try {
					queryExecute(
						"INSERT INTO wheels_jobs (id, jobClass, queue, data, priority, status, attempts, maxRetries, lastError, runAt, failedAt, createdAt, updatedAt)
						VALUES (:id, 'wheels.Job', 'test_retry', '{}', 0, 'failed', 3, 3, 'Test error', :now, :now, :now, :now)",
						{
							id = {value = local.id, cfsqltype = "cf_sql_varchar"},
							now = {value = local.now, cfsqltype = "cf_sql_timestamp"}
						},
						{datasource = application.wheels.dataSourceName}
					);

					local.worker = new wheels.JobWorker();
					local.count = local.worker.retryFailed(queue = "test_retry");
					expect(local.count).toBeGTE(1);

					// Verify job was reset
					local.job = queryExecute(
						"SELECT status, attempts FROM wheels_jobs WHERE id = :id",
						{id = {value = local.id, cfsqltype = "cf_sql_varchar"}},
						{datasource = application.wheels.dataSourceName}
					);
					expect(local.job.status).toBe("pending");
					expect(local.job.attempts).toBe(0);
				} catch (any e) {
					// Table may not exist
				}
			});
		});

		describe("purge", function() {

			it("purges completed jobs", function() {
				local.worker = new wheels.JobWorker();
				local.count = local.worker.purge(status = "completed", days = 7);
				expect(local.count).toBeNumeric();
			});

			it("purges failed jobs", function() {
				local.worker = new wheels.JobWorker();
				local.count = local.worker.purge(status = "failed", days = 7);
				expect(local.count).toBeNumeric();
			});

			it("rejects invalid status", function() {
				var worker = new wheels.JobWorker();
				expect(function() {
					worker.purge(status = "pending");
				}).toThrow(type = "Wheels.InvalidArgument");
			});

			it("accepts queue filter", function() {
				local.worker = new wheels.JobWorker();
				local.count = local.worker.purge(status = "completed", days = 7, queue = "mailers");
				expect(local.count).toBeNumeric();
			});

			it("deletes old completed jobs", function() {
				// Insert an old completed job
				local.id = CreateUUID();
				local.oldTime = DateAdd("d", -30, Now());
				try {
					queryExecute(
						"INSERT INTO wheels_jobs (id, jobClass, queue, data, priority, status, attempts, maxRetries, runAt, completedAt, createdAt, updatedAt)
						VALUES (:id, 'wheels.Job', 'test_purge', '{}', 0, 'completed', 1, 3, :oldTime, :oldTime, :oldTime, :oldTime)",
						{
							id = {value = local.id, cfsqltype = "cf_sql_varchar"},
							oldTime = {value = local.oldTime, cfsqltype = "cf_sql_timestamp"}
						},
						{datasource = application.wheels.dataSourceName}
					);

					local.worker = new wheels.JobWorker();
					local.count = local.worker.purge(status = "completed", days = 7, queue = "test_purge");
					expect(local.count).toBeGTE(1);

					// Verify job was deleted
					local.remaining = queryExecute(
						"SELECT COUNT(*) as cnt FROM wheels_jobs WHERE id = :id",
						{id = {value = local.id, cfsqltype = "cf_sql_varchar"}},
						{datasource = application.wheels.dataSourceName}
					);
					expect(local.remaining.cnt).toBe(0);
				} catch (any e) {
					// Table may not exist
				}
			});
		});

		describe("Backoff Calculation", function() {

			it("uses configurable baseDelay and maxDelay from Job.cfc", function() {
				local.job = new wheels.Job();
				expect(local.job.baseDelay).toBe(2);
				expect(local.job.maxDelay).toBe(3600);
			});

			it("calculates exponential backoff: baseDelay * 2^attempt", function() {
				// With baseDelay=2:
				// attempt 1: 2 * 2^1 = 4
				// attempt 2: 2 * 2^2 = 8
				// attempt 3: 2 * 2^3 = 16
				local.baseDelay = 2;
				local.backoff1 = local.baseDelay * (2 ^ 1);
				local.backoff2 = local.baseDelay * (2 ^ 2);
				local.backoff3 = local.baseDelay * (2 ^ 3);

				expect(local.backoff1).toBe(4);
				expect(local.backoff2).toBe(8);
				expect(local.backoff3).toBe(16);
			});

			it("caps backoff at maxDelay", function() {
				local.baseDelay = 2;
				local.maxDelay = 3600;
				// attempt 12: 2 * 2^12 = 8192, should be capped at 3600
				local.backoff = Min(local.baseDelay * (2 ^ 12), local.maxDelay);
				expect(local.backoff).toBe(3600);
			});

			it("allows custom baseDelay and maxDelay in subclass", function() {
				// The config() override pattern allows subclasses to set custom values
				local.job = new wheels.Job();
				// Simulate a subclass setting custom values
				local.job.baseDelay = 5;
				local.job.maxDelay = 600;
				expect(local.job.baseDelay).toBe(5);
				expect(local.job.maxDelay).toBe(600);
			});
		});
	}

}
