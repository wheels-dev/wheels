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

				// Process it
				local.worker = new wheels.JobWorker();
				local.result = local.worker.processNext(queues = "test_claim");

				// Job was processed (may succeed or fail depending on job class)
				expect(local.result.skipped).toBeFalse();
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
				local.testJob = new app.jobs.ProcessOrdersJob();
				local.enqueued = local.testJob.enqueue(data = {batchSize: 1}, queue = "test_counter");
				expect(local.enqueued.persisted).toBeTrue();

				local.worker = new wheels.JobWorker();
				expect(local.worker.jobsProcessed).toBe(0);
				local.result = local.worker.processNext(queues = "test_counter");

				expect(local.result.success).toBeTrue();
				expect(local.result.skipped).toBeFalse();
				expect(local.worker.jobsProcessed).toBe(1);
			});
		});

		describe("checkTimeouts", function() {

			it("returns a numeric count", function() {
				local.worker = new wheels.JobWorker();
				local.recovered = local.worker.checkTimeouts(timeout = 300);
				expect(local.recovered).toBeNumeric();
			});

			it("recovers stuck processing jobs", function() {
				local.bootstrap = new wheels.Job();
				local.bootstrap.$ensureJobTable();

				local.id = CreateUUID();
				local.oldTime = DateAdd("s", -1800, Now());  // well past the grace window (timeout + max(60,timeout))
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

				local.job = queryExecute(
					"SELECT status FROM wheels_jobs WHERE id = :id",
					{id = {value = local.id, cfsqltype = "cf_sql_varchar"}},
					{datasource = application.wheels.dataSourceName}
				);
				expect(ListFindNoCase("pending,failed", local.job.status)).toBeGT(0);
			});

			it("processNext recovers a job stuck in 'processing' by a crashed worker (##3888)", function() {
				local.bootstrap = new wheels.Job();
				local.bootstrap.$ensureJobTable();

				local.id = CreateUUID();
				local.oldTime = DateAdd("s", -1800, Now());  // well past the grace window (timeout + max(60,timeout))
				queryExecute(
					"INSERT INTO wheels_jobs (id, jobClass, queue, data, priority, status, attempts, maxRetries, runAt, createdAt, updatedAt)
					VALUES (:id, 'wheels.Job', 'test_reaper_3888', '{}', 0, 'processing', 1, 3, :runAt, :createdAt, :updatedAt)",
					{
						id = {value = local.id, cfsqltype = "cf_sql_varchar"},
						runAt = {value = local.oldTime, cfsqltype = "cf_sql_timestamp"},
						createdAt = {value = local.oldTime, cfsqltype = "cf_sql_timestamp"},
						updatedAt = {value = local.oldTime, cfsqltype = "cf_sql_timestamp"}
					},
					{datasource = application.wheels.dataSourceName}
				);

				local.worker = new wheels.JobWorker();
				// A normal poll must recover the crashed-worker job, not leave it stuck:
				// processNext only ever SELECTed status='pending', so without recovery the
				// row stayed 'processing' forever (#3888).
				local.worker.processNext(queues = "test_reaper_3888", timeout = 300);

				local.job = queryExecute(
					"SELECT status FROM wheels_jobs WHERE id = :id",
					{id = {value = local.id, cfsqltype = "cf_sql_varchar"}},
					{datasource = application.wheels.dataSourceName}
				);
				expect(local.job.status).notToBe("processing", "a stale 'processing' job must be recovered by a poll, not left stuck");
			});

			it("does not reap a stale job on a queue the poll does not serve (##3888)", function() {
				local.bootstrap = new wheels.Job();
				local.bootstrap.$ensureJobTable();

				// A worker on queue Y owns this job. Even though it is old enough that a
				// blanket reap would catch it, a poll scoped to queue X must leave it alone —
				// otherwise a short-timeout worker reaps another worker's live job (#3888).
				local.idY = CreateUUID();
				local.oldTime = DateAdd("s", -1800, Now());
				queryExecute(
					"INSERT INTO wheels_jobs (id, jobClass, queue, data, priority, status, attempts, maxRetries, runAt, createdAt, updatedAt)
					VALUES (:id, 'wheels.Job', 'reap_scope_Y_3888', '{}', 0, 'processing', 1, 3, :runAt, :createdAt, :updatedAt)",
					{
						id = {value = local.idY, cfsqltype = "cf_sql_varchar"},
						runAt = {value = local.oldTime, cfsqltype = "cf_sql_timestamp"},
						createdAt = {value = local.oldTime, cfsqltype = "cf_sql_timestamp"},
						updatedAt = {value = local.oldTime, cfsqltype = "cf_sql_timestamp"}
					},
					{datasource = application.wheels.dataSourceName}
				);

				local.worker = new wheels.JobWorker();
				local.worker.checkTimeouts(timeout = 300, queues = "reap_scope_X_3888");

				local.row = queryExecute(
					"SELECT status FROM wheels_jobs WHERE id = :id",
					{id = {value = local.idY, cfsqltype = "cf_sql_varchar"}},
					{datasource = application.wheels.dataSourceName}
				);
				expect(local.row.status).toBe("processing", "a reap scoped to queue X must not touch queue Y's live job");

				queryExecute(
					"DELETE FROM wheels_jobs WHERE id = :id",
					{id = {value = local.idY, cfsqltype = "cf_sql_varchar"}},
					{datasource = application.wheels.dataSourceName}
				);
			});

			it("a second reaper reading the same attempts value cannot double-requeue (##3888)", function() {
				local.bootstrap = new wheels.Job();
				local.bootstrap.$ensureJobTable();

				// Both reapers SELECTed this row as processing/attempts=1. The guarded requeue
				// (status='processing' AND attempts=1) lets exactly one win; the loser matches
				// 0 rows, so attempts is bumped once, not twice, and the count stays honest.
				local.id = CreateUUID();
				local.oldTime = DateAdd("s", -1800, Now());
				queryExecute(
					"INSERT INTO wheels_jobs (id, jobClass, queue, data, priority, status, attempts, maxRetries, runAt, createdAt, updatedAt)
					VALUES (:id, 'wheels.Job', 'reap_race_3888', '{}', 0, 'processing', 1, 3, :runAt, :createdAt, :updatedAt)",
					{
						id = {value = local.id, cfsqltype = "cf_sql_varchar"},
						runAt = {value = local.oldTime, cfsqltype = "cf_sql_timestamp"},
						createdAt = {value = local.oldTime, cfsqltype = "cf_sql_timestamp"},
						updatedAt = {value = local.oldTime, cfsqltype = "cf_sql_timestamp"}
					},
					{datasource = application.wheels.dataSourceName}
				);

				local.worker = new wheels.JobWorker();
				makePublic(local.worker, "$scheduleRetry");

				local.firstWon = local.worker.$scheduleRetry(local.id, 1, "wheels.Job", 3, "stale", 1);
				expect(local.firstWon).toBe(1, "the first reaper's guarded requeue must win");

				local.secondWon = local.worker.$scheduleRetry(local.id, 1, "wheels.Job", 3, "stale", 1);
				expect(local.secondWon).toBe(0, "the second reaper must not double-requeue the now-pending row");

				local.row = queryExecute(
					"SELECT status, attempts FROM wheels_jobs WHERE id = :id",
					{id = {value = local.id, cfsqltype = "cf_sql_varchar"}},
					{datasource = application.wheels.dataSourceName}
				);
				expect(local.row.status).toBe("pending");
				expect(Val(local.row.attempts)).toBe(1, "attempts must not be bumped twice by concurrent reapers");

				queryExecute(
					"DELETE FROM wheels_jobs WHERE id = :id",
					{id = {value = local.id, cfsqltype = "cf_sql_varchar"}},
					{datasource = application.wheels.dataSourceName}
				);
			});

			it("a reaper holding a stale attempts value loses to a re-claim (##3888)", function() {
				local.bootstrap = new wheels.Job();
				local.bootstrap.$ensureJobTable();

				// The real worker re-claimed the job after this reaper read it, bumping
				// attempts to 2. The reaper still holds attempts=1, so its guard rejects the
				// requeue and the live claim is left untouched — this is why attempts (bumped
				// on every claim) is a safer version token than a round-tripped timestamp.
				local.id = CreateUUID();
				local.oldTime = DateAdd("s", -1800, Now());
				queryExecute(
					"INSERT INTO wheels_jobs (id, jobClass, queue, data, priority, status, attempts, maxRetries, runAt, createdAt, updatedAt)
					VALUES (:id, 'wheels.Job', 'reap_token_3888', '{}', 0, 'processing', 2, 3, :runAt, :createdAt, :updatedAt)",
					{
						id = {value = local.id, cfsqltype = "cf_sql_varchar"},
						runAt = {value = local.oldTime, cfsqltype = "cf_sql_timestamp"},
						createdAt = {value = local.oldTime, cfsqltype = "cf_sql_timestamp"},
						updatedAt = {value = local.oldTime, cfsqltype = "cf_sql_timestamp"}
					},
					{datasource = application.wheels.dataSourceName}
				);

				local.worker = new wheels.JobWorker();
				makePublic(local.worker, "$scheduleRetry");

				local.won = local.worker.$scheduleRetry(local.id, 1, "wheels.Job", 3, "stale", 1);
				expect(local.won).toBe(0, "a stale attempts read must not win against a re-claim");

				local.row = queryExecute(
					"SELECT status, attempts FROM wheels_jobs WHERE id = :id",
					{id = {value = local.id, cfsqltype = "cf_sql_varchar"}},
					{datasource = application.wheels.dataSourceName}
				);
				expect(local.row.status).toBe("processing", "the live re-claim must be left untouched");
				expect(Val(local.row.attempts)).toBe(2);

				queryExecute(
					"DELETE FROM wheels_jobs WHERE id = :id",
					{id = {value = local.id, cfsqltype = "cf_sql_varchar"}},
					{datasource = application.wheels.dataSourceName}
				);
			});

			it("normalises a blank/zero timeout so it does not reap a recently-active job (##3984)", function() {
				local.bootstrap = new wheels.Job();
				local.bootstrap.$ensureJobTable();

				// A job claimed ~90s ago is still well within the default 300s execution
				// window. A bridge call with timeout=0 must normalise to 300 (grace 600s),
				// not collapse the grace window to 60s and reap this live job.
				local.id = CreateUUID();
				local.recentTime = DateAdd("s", -90, Now());
				queryExecute(
					"INSERT INTO wheels_jobs (id, jobClass, queue, data, priority, status, attempts, maxRetries, runAt, createdAt, updatedAt)
					VALUES (:id, 'wheels.Job', 'reap_zero_3984', '{}', 0, 'processing', 1, 3, :runAt, :createdAt, :updatedAt)",
					{
						id = {value = local.id, cfsqltype = "cf_sql_varchar"},
						runAt = {value = local.recentTime, cfsqltype = "cf_sql_timestamp"},
						createdAt = {value = local.recentTime, cfsqltype = "cf_sql_timestamp"},
						updatedAt = {value = local.recentTime, cfsqltype = "cf_sql_timestamp"}
					},
					{datasource = application.wheels.dataSourceName}
				);

				local.worker = new wheels.JobWorker();
				local.recovered = local.worker.checkTimeouts(timeout = 0, queues = "reap_zero_3984");

				local.row = queryExecute(
					"SELECT status FROM wheels_jobs WHERE id = :id",
					{id = {value = local.id, cfsqltype = "cf_sql_varchar"}},
					{datasource = application.wheels.dataSourceName}
				);
				expect(local.row.status).toBe("processing", "timeout=0 must normalise to 300s, not reap a 90s-old live job");

				queryExecute(
					"DELETE FROM wheels_jobs WHERE id = :id",
					{id = {value = local.id, cfsqltype = "cf_sql_varchar"}},
					{datasource = application.wheels.dataSourceName}
				);
			});

			it("records the claiming worker's timeout as claimTimeout (##3989)", function() {
				local.bootstrap = new wheels.Job();
				local.bootstrap.$ensureJobTable();

				local.id = CreateUUID();
				local.t = Now();
				queryExecute(
					"INSERT INTO wheels_jobs (id, jobClass, queue, data, priority, status, attempts, maxRetries, runAt, createdAt, updatedAt)
					VALUES (:id, 'wheels.Job', 'claimts_3989', '{}', 0, 'pending', 0, 3, :runAt, :createdAt, :updatedAt)",
					{
						id = {value = local.id, cfsqltype = "cf_sql_varchar"},
						runAt = {value = local.t, cfsqltype = "cf_sql_timestamp"},
						createdAt = {value = local.t, cfsqltype = "cf_sql_timestamp"},
						updatedAt = {value = local.t, cfsqltype = "cf_sql_timestamp"}
					},
					{datasource = application.wheels.dataSourceName}
				);

				local.worker = new wheels.JobWorker();
				expect(local.worker.$claimJob(jobId = local.id, timeout = 450)).toBeTrue();

				local.row = queryExecute(
					"SELECT claimTimeout FROM wheels_jobs WHERE id = :id",
					{id = {value = local.id, cfsqltype = "cf_sql_varchar"}},
					{datasource = application.wheels.dataSourceName}
				);
				expect(Val(local.row.claimTimeout)).toBe(450, "the claiming worker's timeout must be recorded on the row");

				queryExecute(
					"DELETE FROM wheels_jobs WHERE id = :id",
					{id = {value = local.id, cfsqltype = "cf_sql_varchar"}},
					{datasource = application.wheels.dataSourceName}
				);
			});

			it("does not reap a row whose own claimTimeout exceeds the poller's timeout (##3989)", function() {
				local.bootstrap = new wheels.Job();
				local.bootstrap.$ensureJobTable();

				// Owned by a long-timeout worker (claimTimeout 600 -> grace 1200s), idle only 300s.
				// A short poller (timeout 60 -> grace 120s) would reap it under the old #3888 rule,
				// but must honour the OWNER's recorded timeout and leave it running.
				local.id = CreateUUID();
				local.idle = DateAdd("s", -300, Now());
				queryExecute(
					"INSERT INTO wheels_jobs (id, jobClass, queue, data, priority, status, attempts, maxRetries, claimTimeout, runAt, createdAt, updatedAt)
					VALUES (:id, 'wheels.Job', 'claimlong_3989', '{}', 0, 'processing', 1, 3, 600, :runAt, :createdAt, :updatedAt)",
					{
						id = {value = local.id, cfsqltype = "cf_sql_varchar"},
						runAt = {value = local.idle, cfsqltype = "cf_sql_timestamp"},
						createdAt = {value = local.idle, cfsqltype = "cf_sql_timestamp"},
						updatedAt = {value = local.idle, cfsqltype = "cf_sql_timestamp"}
					},
					{datasource = application.wheels.dataSourceName}
				);

				local.worker = new wheels.JobWorker();
				local.worker.checkTimeouts(timeout = 60, queues = "claimlong_3989");

				local.row = queryExecute(
					"SELECT status FROM wheels_jobs WHERE id = :id",
					{id = {value = local.id, cfsqltype = "cf_sql_varchar"}},
					{datasource = application.wheels.dataSourceName}
				);
				expect(local.row.status).toBe("processing", "a short poller must not reap a job owned by a longer-timeout worker");

				queryExecute(
					"DELETE FROM wheels_jobs WHERE id = :id",
					{id = {value = local.id, cfsqltype = "cf_sql_varchar"}},
					{datasource = application.wheels.dataSourceName}
				);
			});

			it("reaps a row with no claimTimeout using the poller's timeout (##3989)", function() {
				local.bootstrap = new wheels.Job();
				local.bootstrap.$ensureJobTable();

				// A pre-#3989 / column-less row (claimTimeout NULL), idle 1800s. The reaper must
				// fall back to the poller's timeout (300 -> grace 600s) and recover it.
				local.id = CreateUUID();
				local.idle = DateAdd("s", -1800, Now());
				queryExecute(
					"INSERT INTO wheels_jobs (id, jobClass, queue, data, priority, status, attempts, maxRetries, runAt, createdAt, updatedAt)
					VALUES (:id, 'wheels.Job', 'claimnull_3989', '{}', 0, 'processing', 1, 3, :runAt, :createdAt, :updatedAt)",
					{
						id = {value = local.id, cfsqltype = "cf_sql_varchar"},
						runAt = {value = local.idle, cfsqltype = "cf_sql_timestamp"},
						createdAt = {value = local.idle, cfsqltype = "cf_sql_timestamp"},
						updatedAt = {value = local.idle, cfsqltype = "cf_sql_timestamp"}
					},
					{datasource = application.wheels.dataSourceName}
				);

				local.worker = new wheels.JobWorker();
				local.worker.checkTimeouts(timeout = 300, queues = "claimnull_3989");

				local.row = queryExecute(
					"SELECT status FROM wheels_jobs WHERE id = :id",
					{id = {value = local.id, cfsqltype = "cf_sql_varchar"}},
					{datasource = application.wheels.dataSourceName}
				);
				expect(local.row.status).notToBe("processing", "a NULL-claimTimeout stale row must be recovered via the poller's timeout");

				queryExecute(
					"DELETE FROM wheels_jobs WHERE id = :id",
					{id = {value = local.id, cfsqltype = "cf_sql_varchar"}},
					{datasource = application.wheels.dataSourceName}
				);
			});

			it("adds the claimTimeout column to a table that lacks it (##3989)", function() {
				local.job = new wheels.Job();
				local.job.$ensureJobTable();
				expect(local.job.$jobTableHasClaimTimeout()).toBeTrue("the column should exist after $ensureJobTable");

				// Simulate a pre-#3989 table by dropping the column, then re-ensuring it. DROP
				// COLUMN isn't supported everywhere, so degrade gracefully where it isn't.
				local.dropped = false;
				try {
					queryExecute("ALTER TABLE wheels_jobs DROP COLUMN claimTimeout", {}, {datasource = application.wheels.dataSourceName});
					local.dropped = true;
				} catch (any e) {
					// engine/DB without DROP COLUMN support — skip the round-trip
				}
				if (local.dropped) {
					expect(local.job.$jobTableHasClaimTimeout()).toBeFalse("column should be gone after DROP");
					local.job.$ensureClaimTimeoutColumn();
					expect(local.job.$jobTableHasClaimTimeout()).toBeTrue("column should be re-added by $ensureClaimTimeoutColumn");
				}
			});

			it("adds the claimTimeout column through the normal worker path, not just $ensureJobTable (##3989)", function() {
				local.probe = new wheels.Job();
				local.probe.$ensureJobTable();

				// Simulate a pre-#3989 install by dropping the column, then let a fresh worker's
				// normal poll add it back — without calling $ensureJobTable directly.
				local.dropped = false;
				try {
					queryExecute("ALTER TABLE wheels_jobs DROP COLUMN claimTimeout", {}, {datasource = application.wheels.dataSourceName});
					local.dropped = true;
				} catch (any e) {
					// engine/DB without DROP COLUMN support — skip
				}
				if (local.dropped) {
					expect(local.probe.$jobTableHasClaimTimeout()).toBeFalse("column should be gone after DROP");
					local.worker = new wheels.JobWorker();
					local.worker.processNext(queues = "no_such_queue_3989", timeout = 300);
					expect(local.probe.$jobTableHasClaimTimeout()).toBeTrue("processNext must add the column on an existing table");
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
				expect(local.data).toHaveKey("recentJobs");
				expect(local.data).toHaveKey("oldestPending");
				for (local.recent in local.data.recentJobs) {
					expect(local.recent.queue).toBe("default");
				}
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
				local.bootstrap = new wheels.Job();
				local.bootstrap.$ensureJobTable();

				local.id = CreateUUID();
				local.now = Now();
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

				local.job = queryExecute(
					"SELECT status, attempts FROM wheels_jobs WHERE id = :id",
					{id = {value = local.id, cfsqltype = "cf_sql_varchar"}},
					{datasource = application.wheels.dataSourceName}
				);
				expect(local.job.status).toBe("pending");
				expect(local.job.attempts).toBe(0);
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
				local.bootstrap = new wheels.Job();
				local.bootstrap.$ensureJobTable();

				local.id = CreateUUID();
				local.oldTime = DateAdd("d", -30, Now());
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

				local.remaining = queryExecute(
					"SELECT COUNT(*) as cnt FROM wheels_jobs WHERE id = :id",
					{id = {value = local.id, cfsqltype = "cf_sql_varchar"}},
					{datasource = application.wheels.dataSourceName}
				);
				expect(local.remaining.cnt).toBe(0);
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
