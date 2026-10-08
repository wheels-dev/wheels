/**
 * heartbeat() keeps a long-running job's claim alive: the reaper measures staleness from the
 * later of its last heartbeat and its claim, so a job that heartbeats on time is never reaped.
 * A heartbeat after the claim was reaped and re-issued throws Wheels.Job.Fenced. After a reap,
 * a job is retried only when its class has this.idempotent = true (the default); a class with
 * this.idempotent = false is not re-run and ends 'interrupted'.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("Job heartbeat", function() {

			beforeEach(function() {
				var bootstrapJob = new wheels.Job();
				bootstrapJob.$ensureJobTable();
				$cleanup();
			});

			afterEach(function() {
				$cleanup();
			});

			it("does not reap a job that heartbeats, however old its claim", function() {
				var id = $insertJob(queue = "test_hb_alive", jobClass = "wheels.tests._assets.jobs.HeartbeatThroughReapJob");
				var worker = new wheels.JobWorker();
				var result = worker.processNext(queues = "test_hb_alive", timeout = 300);

				expect($signal(id).reaped).toBe(0, "a job that just heartbeat must not be reaped");
				expect(result.success).toBeTrue();
				expect($jobRow(id).status).toBe("completed");
			});

			it("throws Wheels.Job.Fenced from a heartbeat after the claim was reaped (worker path)", function() {
				var id = $insertJob(queue = "test_hb_fenced", jobClass = "wheels.tests._assets.jobs.HeartbeatAfterReapJob");
				var worker = new wheels.JobWorker();
				worker.processNext(queues = "test_hb_fenced", timeout = 300);

				expect($signal(id).type).toBe("Wheels.Job.Fenced");
				expect($jobRow(id).status).toBe("processing", "the attempt that replaced it keeps its claim");
			});

			it("throws Wheels.Job.Fenced from a heartbeat after the claim was reaped (processQueue path)", function() {
				var id = $insertJob(queue = "test_hb_fenced_q", jobClass = "wheels.tests._assets.jobs.HeartbeatAfterReapJob");
				var processor = new wheels.Job();
				processor.processQueue(queue = "test_hb_fenced_q", limit = 1);

				expect($signal(id).type).toBe("Wheels.Job.Fenced");
				expect($jobRow(id).status).toBe("processing");
			});

			it("does not retry a reaped job whose class is not idempotent: it ends 'interrupted'", function() {
				var id = $insertJob(
					queue = "test_hb_nonidem",
					jobClass = "wheels.tests._assets.jobs.NonIdempotentJob",
					status = "processing",
					attempts = 1,
					stale = true
				);
				var reaper = new wheels.JobWorker();
				expect(reaper.checkTimeouts(timeout = 300, queues = "test_hb_nonidem")).toBe(1);

				var row = $jobRow(id);
				expect(row.status).toBe("interrupted", "a non-idempotent job must not be re-run after a reap");
				expect(Val(row.attempts)).toBe(1);
			});

			it("retries a reaped job by default (this.idempotent defaults to true)", function() {
				var job = new wheels.tests._assets.jobs.ProcessOrdersJob();
				expect(job.idempotent).toBeTrue();
				var id = $insertJob(queue = "test_hb_idem", status = "processing", attempts = 1, stale = true);
				var reaper = new wheels.JobWorker();
				expect(reaper.checkTimeouts(timeout = 300, queues = "test_hb_idem")).toBe(1);
				expect($jobRow(id).status).toBe("pending", "the default keeps today's retry after a reap");
			});

			it("clears an earlier attempt's heartbeat when the job is claimed again", function() {
				var id = $insertJob(queue = "test_hb_reset");
				queryExecute(
					"UPDATE wheels_jobs SET heartbeatAt = :old WHERE id = :id",
					{
						old = {value = DateAdd("h", -3, Now()), cfsqltype = "cf_sql_timestamp"},
						id = {value = id, cfsqltype = "cf_sql_varchar"}
					},
					{datasource = application.wheels.dataSourceName}
				);
				var worker = new wheels.JobWorker();
				expect(worker.$claimJob(id, 300)).toBeTrue();
				expect($jobRow(id).heartbeatAt).toBe("", "a fresh claim must not inherit an old heartbeat, or it looks stale at once");
				expect(worker.checkTimeouts(timeout = 300, queues = "test_hb_reset")).toBe(0);
			});

			it("is a no-op when perform() runs outside a worker", function() {
				var job = new wheels.tests._assets.jobs.ProcessOrdersJob();
				job.heartbeat();
				expect(true).toBeTrue();
			});

			it("counts interrupted jobs in the queue stats", function() {
				$insertJob(queue = "test_hb_stats", status = "interrupted");
				var job = new wheels.Job();
				expect(job.queueStats(queue = "test_hb_stats").interrupted).toBe(1);
				var worker = new wheels.JobWorker();
				expect(worker.getStats(queue = "test_hb_stats").totals.interrupted).toBe(1);
			});

		});
	}

	private void function $cleanup() {
		try {
			queryExecute("DELETE FROM wheels_jobs WHERE queue LIKE 'test_hb_%'", {}, {datasource = application.wheels.dataSourceName});
		} catch (any e) {
		}
		for (var key in StructKeyArray(server)) {
			if (Left(key, 21) == "$wheelsHeartbeatSpec_") {
				StructDelete(server, key);
			}
		}
	}

	private string function $insertJob(
		required string queue,
		string jobClass = "wheels.tests._assets.jobs.ProcessOrdersJob",
		string status = "pending",
		numeric attempts = 0,
		boolean stale = false
	) {
		var id = CreateUUID();
		var stamp = arguments.stale ? DateAdd("h", -2, Now()) : DateAdd("s", -5, Now());
		queryExecute(
			"INSERT INTO wheels_jobs (id, jobClass, queue, data, priority, status, attempts, maxRetries, runAt, createdAt, updatedAt)
			VALUES (:id, :jobClass, :queue, :data, 0, :status, :attempts, 3, :runAt, :createdAt, :updatedAt)",
			{
				id = {value = id, cfsqltype = "cf_sql_varchar"},
				jobClass = {value = arguments.jobClass, cfsqltype = "cf_sql_varchar"},
				queue = {value = arguments.queue, cfsqltype = "cf_sql_varchar"},
				data = {value = SerializeJSON({jobId = id, queue = arguments.queue}), cfsqltype = "cf_sql_longvarchar"},
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

	/**
	 * What the job's perform() recorded, or an empty marker when it never ran.
	 */
	private struct function $signal(required string id) {
		var key = "$wheelsHeartbeatSpec_" & arguments.id;
		return StructKeyExists(server, key) ? server[key] : {reaped = -1, type = "perform never ran"};
	}

	private struct function $jobRow(required string id) {
		var q = queryExecute(
			"SELECT * FROM wheels_jobs WHERE id = :id",
			{id = {value = arguments.id, cfsqltype = "cf_sql_varchar"}},
			{datasource = application.wheels.dataSourceName}
		);
		var rv = {status = "", attempts = 0, heartbeatAt = ""};
		if (!q.recordCount) {
			return rv;
		}
		rv.status = q.status[1];
		rv.attempts = q.attempts[1];
		if (ListFindNoCase(q.columnList, "heartbeatAt") && !IsNull(q.heartbeatAt[1])) {
			rv.heartbeatAt = ToString(q.heartbeatAt[1]);
		}
		return rv;
	}

}
