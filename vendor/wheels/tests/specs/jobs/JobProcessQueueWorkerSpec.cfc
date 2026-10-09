/**
 * processQueue() runs through the worker: it reaps stale jobs on every call and records each
 * job's claimTimeout, like `wheels jobs work`. Each job is claimed and run with its own class's
 * timeout (as processQueue always ran it), unless the caller passes a timeout cap.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("processQueue through the worker", function() {

			beforeEach(function() {
				var bootstrapJob = new wheels.Job();
				bootstrapJob.$ensureJobTable();
				$cleanup();
			});

			afterEach(function() {
				$cleanup();
			});

			it("reaps a stale job on each call", function() {
				var staleId = $insertJob(queue = "test_pq_reap", status = "processing", attempts = 1, stale = true);
				new wheels.Job().processQueue(queue = "test_pq_reap");
				expect($row(staleId).status).toBe("pending", "a job stranded by a dead worker must be requeued");
			});

			it("doesn't reap a row with no claimTimeout inside the job timeout when the cap is small", function() {
				// Idle 5 minutes, no claimTimeout recorded: a 60s cap alone would reap it at 120s.
				var id = $insertJob(queue = "test_pq_legacy", status = "processing", attempts = 1, idleSeconds = 300);
				new wheels.Job().processQueue(queue = "test_pq_legacy", timeout = 60);
				expect($row(id).status).toBe("processing", "an older job may still be running under its own timeout");
			});

			it("records the job class's own timeout as claimTimeout", function() {
				var id = $insertJob(queue = "test_pq_own", jobClass = "wheels.tests._assets.jobs.LongTimeoutJob");
				var result = new wheels.Job().processQueue(queue = "test_pq_own");
				expect(result.processed).toBe(1);
				var row = $row(id);
				expect(row.status).toBe("completed");
				expect(Val(row.claimTimeout)).toBe(900, "the reap window must match the job's own timeout, not the caller's 300");
			});

			it("caps the timeout when the caller passes one", function() {
				var id = $insertJob(queue = "test_pq_cap", jobClass = "wheels.tests._assets.jobs.LongTimeoutJob");
				new wheels.Job().processQueue(queue = "test_pq_cap", timeout = 120);
				expect(Val($row(id).claimTimeout)).toBe(120);
			});

			it("falls back to the caller's timeout when the job class can't be loaded", function() {
				var id = $insertJob(queue = "test_pq_missing", jobClass = "wheels.tests._assets.jobs.NoSuchJobForProcessQueueSpec");
				var result = new wheels.Job().processQueue(queue = "test_pq_missing");
				expect(result.failed).toBe(1);
				expect(Val($row(id).claimTimeout)).toBe(300);
			});

			it("processes at most limit jobs, and all of them with limit 0", function() {
				for (var i = 1; i <= 4; i++) {
					$insertJob(queue = "test_pq_limit");
				}
				expect(new wheels.Job().processQueue(queue = "test_pq_limit", limit = 3).processed).toBe(3);
				expect(new wheels.Job().processQueue(queue = "test_pq_limit", limit = 0).processed).toBe(1);
			});

		});
	}

	private void function $cleanup() {
		try {
			queryExecute("DELETE FROM wheels_jobs WHERE queue LIKE 'test_pq_%'", {}, {datasource = application.wheels.dataSourceName});
		} catch (any e) {
		}
	}

	private string function $insertJob(
		required string queue,
		string jobClass = "wheels.tests._assets.jobs.ProcessOrdersJob",
		string status = "pending",
		numeric attempts = 0,
		boolean stale = false,
		numeric idleSeconds = 0
	) {
		var id = CreateUUID();
		var stamp = arguments.stale ? DateAdd("h", -2, jobsNow()) : DateAdd("s", -5, jobsNow());
		if (arguments.idleSeconds > 0) {
			stamp = DateAdd("s", -arguments.idleSeconds, jobsNow());
		}
		queryExecute(
			"INSERT INTO wheels_jobs (id, jobClass, queue, data, priority, status, attempts, maxRetries, runAt, createdAt, updatedAt)
			VALUES (:id, :jobClass, :queue, '{}', 0, :status, :attempts, 3, :runAt, :createdAt, :updatedAt)",
			{
				id = {value = id, cfsqltype = "cf_sql_varchar"},
				jobClass = {value = arguments.jobClass, cfsqltype = "cf_sql_varchar"},
				queue = {value = arguments.queue, cfsqltype = "cf_sql_varchar"},
				status = {value = arguments.status, cfsqltype = "cf_sql_varchar"},
				attempts = {value = arguments.attempts, cfsqltype = "cf_sql_integer"},
				runAt = {value = stamp, cfsqltype = "cf_sql_timestamp"},
				createdAt = {value = stamp, cfsqltype = "cf_sql_timestamp"},
				updatedAt = {value = stamp, cfsqltype = "cf_sql_timestamp"}
			},
			{datasource = application.wheels.dataSourceName}
		);
		return id;
	}

	private struct function $row(required string id) {
		var q = queryExecute(
			"SELECT status, claimTimeout FROM wheels_jobs WHERE id = :id",
			{id = {value = arguments.id, cfsqltype = "cf_sql_varchar"}},
			{datasource = application.wheels.dataSourceName}
		);
		return {status = q.recordCount ? q.status : "", claimTimeout = q.recordCount && !IsNull(q.claimTimeout[1]) ? q.claimTimeout[1] : ""};
	}

	/**
	 * Now on the jobs clock (wheels.JobClock): UTC from the database's clock, which job rows and
	 * memos are stamped with. A row stamped with the app's local Now() is hours out on a server
	 * that isn't on UTC.
	 */
	private date function jobsNow() {
		return new wheels.Job().$jobClock().utcNow();
	}

}
