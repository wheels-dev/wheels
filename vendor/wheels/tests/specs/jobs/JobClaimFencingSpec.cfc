/**
 * Per-attempt claim fencing. Every claim writes a fresh claimToken, and an attempt can only
 * complete, retry or fail its job while the row still carries that token. Without it, a worker
 * whose attempt was reaped and re-claimed finishes anyway and its status-only UPDATE lands on
 * the NEW attempt's 'processing' row: the job is marked done (or requeued) while attempt 2 is
 * still running, and attempt 2's own completion then matches nothing.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("Job claim fencing", function() {

			beforeEach(function() {
				var bootstrapJob = new wheels.Job();
				bootstrapJob.$ensureJobTable();
				try {
					jobsQuery("DELETE FROM wheels_jobs WHERE queue LIKE 'test_fence_%'", {}, {datasource = application.wheels.dataSourceName});
				} catch (any e) {
				}
			});

			afterEach(function() {
				try {
					jobsQuery("DELETE FROM wheels_jobs WHERE queue LIKE 'test_fence_%'", {}, {datasource = application.wheels.dataSourceName});
				} catch (any e) {
				}
			});

			it("a reaped attempt's late completion does not overwrite the re-claim (worker path)", function() {
				var id = $insertReclaimJob(queue = "test_fence_worker_ok", mode = "complete");
				var worker = new wheels.JobWorker();
				var result = worker.processNext(queues = "test_fence_worker_ok", timeout = 300);

				var row = $jobRow(id);
				expect(row.status).toBe("processing", "the second attempt's claim must survive the first attempt finishing late");
				expect(Val(row.attempts)).toBe(2);
				expect(result.success).toBeFalse("a fenced attempt must not report success");
				expect(result.fenced).toBeTrue("a fenced attempt must say so");
				expect(worker.jobsProcessed).toBe(0);
			});

			it("a reaped attempt's late failure does not requeue the re-claim (worker path)", function() {
				var id = $insertReclaimJob(queue = "test_fence_worker_fail", mode = "fail");
				var worker = new wheels.JobWorker();
				var result = worker.processNext(queues = "test_fence_worker_fail", timeout = 300);

				var row = $jobRow(id);
				expect(row.status).toBe("processing", "the first attempt's retry must not requeue the second attempt");
				expect(Val(row.attempts)).toBe(2);
				expect(result.fenced).toBeTrue();
			});

			it("a reaped attempt's late completion does not overwrite the re-claim (processQueue path)", function() {
				var id = $insertReclaimJob(queue = "test_fence_queue_ok", mode = "complete");
				var processor = new wheels.Job();
				var result = processor.processQueue(queue = "test_fence_queue_ok", limit = 1);

				var row = $jobRow(id);
				expect(row.status).toBe("processing", "the second attempt's claim must survive the first attempt finishing late");
				expect(Val(row.attempts)).toBe(2);
				expect(result.processed).toBe(0);
				expect(result.fenced).toBe(1);
			});

			it("a reaped attempt's late failure does not requeue the re-claim (processQueue path)", function() {
				var id = $insertReclaimJob(queue = "test_fence_queue_fail", mode = "fail");
				var processor = new wheels.Job();
				var result = processor.processQueue(queue = "test_fence_queue_fail", limit = 1);

				var row = $jobRow(id);
				expect(row.status).toBe("processing", "the first attempt's retry must not requeue the second attempt");
				expect(Val(row.attempts)).toBe(2);
				expect(result.fenced).toBe(1);
			});

			it("writes a fresh claimToken and the claiming host on every claim", function() {
				var id = CreateUUID();
				$insertJob(id = id, queue = "test_fence_token");
				var worker = new wheels.JobWorker();
				expect(worker.$claimJob(id, 300)).toBeTrue();
				var first = $jobRow(id);
				expect(Len(first.claimToken)).toBeGT(0, "a claim must write a token");
				expect(Len(first.claimedBy)).toBeGT(0, "a claim must record the claiming host");

				// Reap it, then claim again: the second attempt must get a different token.
				jobsQuery(
					"UPDATE wheels_jobs SET updatedAt = :stale WHERE id = :id",
					{
						stale = {value = jobsNow() - 7200, cfsqltype = "wheels_epoch"},
						id = {value = id, cfsqltype = "cf_sql_varchar"}
					},
					{datasource = application.wheels.dataSourceName}
				);
				expect(worker.checkTimeouts(timeout = 300, queues = "test_fence_token")).toBe(1);
				var reaped = $jobRow(id);
				expect(reaped.status).toBe("pending");
				expect(Len(reaped.claimToken)).toBe(0, "the reaper must clear the reaped attempt's token");

				expect(worker.$claimJob(id, 300)).toBeTrue();
				var second = $jobRow(id);
				expect(Len(second.claimToken)).toBeGT(0);
				expect(second.claimToken).notToBe(first.claimToken, "each attempt must get its own token");
			});

			it("an unreaped attempt still completes normally", function() {
				var job = new wheels.tests._assets.jobs.ProcessOrdersJob();
				var enqueued = job.enqueue(data = {}, queue = "test_fence_normal");
				var worker = new wheels.JobWorker();
				var result = worker.processNext(queues = "test_fence_normal", timeout = 300);
				expect(result.success).toBeTrue();
				expect(result.fenced).toBeFalse();
				expect($jobRow(enqueued.id).status).toBe("completed");
			});

		});
	}

	/**
	 * A pending job whose perform() is reaped and re-claimed mid-flight.
	 */
	private string function $insertReclaimJob(required string queue, required string mode) {
		var id = CreateUUID();
		$insertJob(
			id = id,
			queue = arguments.queue,
			jobClass = "wheels.tests._assets.jobs.ReclaimDuringPerformJob",
			data = SerializeJSON({jobId = id, queue = arguments.queue, mode = arguments.mode})
		);
		return id;
	}

	private void function $insertJob(
		required string id,
		required string queue,
		string jobClass = "wheels.tests._assets.jobs.ProcessOrdersJob",
		string data = "{}"
	) {
		var stamp = jobsNow() - 5;
		jobsQuery(
			"INSERT INTO wheels_jobs (id, jobClass, queue, data, priority, status, attempts, maxRetries, runAt, createdAt, updatedAt)
			VALUES (:id, :jobClass, :queue, :data, 0, 'pending', 0, 3, :runAt, :createdAt, :updatedAt)",
			{
				id = {value = arguments.id, cfsqltype = "cf_sql_varchar"},
				jobClass = {value = arguments.jobClass, cfsqltype = "cf_sql_varchar"},
				queue = {value = arguments.queue, cfsqltype = "cf_sql_varchar"},
				data = {value = arguments.data, cfsqltype = "cf_sql_longvarchar"},
				runAt = {value = stamp, cfsqltype = "wheels_epoch"},
				createdAt = {value = stamp, cfsqltype = "wheels_epoch"},
				updatedAt = {value = stamp, cfsqltype = "wheels_epoch"}
			},
			{datasource = application.wheels.dataSourceName}
		);
	}

	/**
	 * The row's status and attempts, plus the fencing columns when the table has them, as a
	 * struct (a query column is an epoch number on BoxLang, so read scalars out explicitly).
	 */
	private struct function $jobRow(required string id) {
		var q = jobsQuery(
			"SELECT * FROM wheels_jobs WHERE id = :id",
			{id = {value = arguments.id, cfsqltype = "cf_sql_varchar"}},
			{datasource = application.wheels.dataSourceName}
		);
		var rv = {status = "", attempts = 0, claimToken = "", claimedBy = ""};
		if (!q.recordCount) {
			return rv;
		}
		rv.status = q.status[1];
		rv.attempts = q.attempts[1];
		if (ListFindNoCase(q.columnList, "claimToken")) {
			rv.claimToken = IsNull(q.claimToken[1]) ? "" : ToString(q.claimToken[1]);
		}
		if (ListFindNoCase(q.columnList, "claimedBy")) {
			rv.claimedBy = IsNull(q.claimedBy[1]) ? "" : ToString(q.claimedBy[1]);
		}
		return rv;
	}

	/**
	 * Now on the jobs clock (wheels.JobClock): UTC epoch seconds from the database's clock, which
	 * job rows are stamped with.
	 */
	private numeric function jobsNow() {
		return new wheels.Job().$jobClock().nowEpoch();
	}

	/**
	 * queryExecute() with wheels_epoch timestamp parameters, as the jobs code binds them.
	 */
	private any function jobsQuery(required string sql, struct params = {}, struct options = {}) {
		return new wheels.Job().$jobClock().query(arguments.sql, arguments.params, arguments.options);
	}

}
