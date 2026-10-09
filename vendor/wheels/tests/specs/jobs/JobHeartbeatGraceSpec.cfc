/**
 * Heartbeat grace: a running job that has heartbeated is reclaimed once its heartbeats stop
 * for its grace (jobsHeartbeatGraceSeconds, default 300, or the job's this.heartbeatGrace),
 * even while its long timeout hasn't passed. Jobs that never heartbeat keep the claim window
 * alone. Each row here claims a one-hour timeout, so only the heartbeat grace can reap it.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("heartbeat grace", function() {

			beforeEach(function() {
				new wheels.Job().$ensureJobTable();
				$cleanup();
				application.wheels.jobsHeartbeatGraceSeconds = 300;
			});

			afterEach(function() {
				$cleanup();
				application.wheels.jobsHeartbeatGraceSeconds = 300;
			});

			it("reclaims a job whose heartbeats stopped longer ago than the grace", function() {
				var id = $insertRunning(queue = "test_grace_stale", heartbeatMinutesAgo = 10);
				expect(new wheels.JobWorker().checkTimeouts(timeout = 300, queues = "test_grace_stale")).toBe(1);
				expect($status(id)).toBe("pending", "retried: its worker stopped heartbeating");
			});

			it("leaves a job that heartbeated within the grace", function() {
				var id = $insertRunning(queue = "test_grace_fresh", heartbeatMinutesAgo = 1);
				new wheels.JobWorker().checkTimeouts(timeout = 300, queues = "test_grace_fresh");
				expect($status(id)).toBe("processing");
			});

			it("leaves a job that never heartbeated to its claim window, as before", function() {
				var id = $insertRunning(queue = "test_grace_never", claimedMinutesAgo = 10);
				new wheels.JobWorker().checkTimeouts(timeout = 300, queues = "test_grace_never");
				expect($status(id)).toBe("processing", "without heartbeats only the one-hour claim window applies");
			});

			it("turns off with jobsHeartbeatGraceSeconds = 0", function() {
				application.wheels.jobsHeartbeatGraceSeconds = 0;
				var id = $insertRunning(queue = "test_grace_off", heartbeatMinutesAgo = 10);
				new wheels.JobWorker().checkTimeouts(timeout = 300, queues = "test_grace_off");
				expect($status(id)).toBe("processing");
			});

			it("uses the job's own this.heartbeatGrace over the setting", function() {
				var longGrace = $insertRunning(queue = "test_grace_class", heartbeatMinutesAgo = 10, jobClass = "wheels.tests._assets.jobs.LongGraceJob");
				var noGrace = $insertRunning(queue = "test_grace_class", heartbeatMinutesAgo = 10, jobClass = "wheels.tests._assets.jobs.NoGraceJob");
				new wheels.JobWorker().checkTimeouts(timeout = 300, queues = "test_grace_class");
				expect($status(longGrace)).toBe("processing", "its own grace is 20 minutes");
				expect($status(noGrace)).toBe("processing", "it turned the grace off");
			});

			it("raises a grace below 30 seconds to 30", function() {
				application.wheels.jobsHeartbeatGraceSeconds = 5;
				expect(new wheels.Job().$heartbeatGraceSeconds()).toBe(30);
				var id = $insertRunning(queue = "test_grace_floor", heartbeatSecondsAgo = 15);
				new wheels.JobWorker().checkTimeouts(timeout = 300, queues = "test_grace_floor");
				expect($status(id)).toBe("processing", "15 seconds is inside the 30-second minimum");
			});

			it("reclaims a job idle past the 30-second minimum when the setting is below it", function() {
				application.wheels.jobsHeartbeatGraceSeconds = 5;
				var id = $insertRunning(queue = "test_grace_floor_past", heartbeatSecondsAgo = 45);
				var reaped = new wheels.JobWorker().checkTimeouts(timeout = 300, queues = "test_grace_floor_past");
				expect(reaped).toBe(1);
				expect($status(id)).toBe("pending", "45 seconds is past the 30-second minimum, so the job is retried");
			});

			it("renews an exclusive job's lease by the heartbeat grace window", function() {
				application.wheels.jobsHeartbeatGraceSeconds = 100;
				var job = new wheels.Job();
				expect(job.$heartbeatGraceSeconds()).toBe(100);
				job.$setLeaseContext(name = "spec:grace", owner = "o", windowSeconds = 7200);
				expect(job.$leaseRenewalSeconds()).toBe(200, "grace + Max(60, grace), not the 2-hour claim window");
				application.wheels.jobsHeartbeatGraceSeconds = 0;
				expect(job.$leaseRenewalSeconds()).toBe(7200, "without a grace the lease keeps its window");
			});

		});
	}

	private void function $cleanup() {
		try {
			jobsQuery("DELETE FROM wheels_jobs WHERE queue LIKE 'test_grace_%'", {}, {datasource = application.wheels.dataSourceName});
		} catch (any e) {
		}
	}

	/**
	 * A row claimed with a one-hour timeout: claimed claimedMinutesAgo, and last heartbeat
	 * heartbeatMinutesAgo / heartbeatSecondsAgo (none when both are 0).
	 */
	private string function $insertRunning(
		required string queue,
		numeric claimedMinutesAgo = 2,
		numeric heartbeatMinutesAgo = 0,
		numeric heartbeatSecondsAgo = 0,
		string jobClass = "wheels.tests._assets.jobs.ProcessOrdersJob"
	) {
		var id = CreateUUID();
		var claimedAt = (jobsNow() - (Max(arguments.claimedMinutesAgo, arguments.heartbeatMinutesAgo + 1)) * 60);
		var beatSeconds = arguments.heartbeatMinutesAgo * 60 + arguments.heartbeatSecondsAgo;
		var params = {
			id = {value = id, cfsqltype = "cf_sql_varchar"},
			jobClass = {value = arguments.jobClass, cfsqltype = "cf_sql_varchar"},
			queue = {value = arguments.queue, cfsqltype = "cf_sql_varchar"},
			runAt = {value = claimedAt, cfsqltype = "wheels_epoch"},
			createdAt = {value = claimedAt, cfsqltype = "wheels_epoch"},
			updatedAt = {value = claimedAt, cfsqltype = "wheels_epoch"},
			heartbeatAt = {value = jobsNow() - beatSeconds, cfsqltype = "wheels_epoch", null = beatSeconds == 0}
		};
		jobsQuery(
			"INSERT INTO wheels_jobs (id, jobClass, queue, data, priority, status, attempts, maxRetries, runAt, createdAt, updatedAt, claimTimeout, heartbeatAt)
			VALUES (:id, :jobClass, :queue, '{}', 0, 'processing', 1, 3, :runAt, :createdAt, :updatedAt, 3600, :heartbeatAt)",
			params,
			{datasource = application.wheels.dataSourceName}
		);
		return id;
	}

	private string function $status(required string id) {
		var q = jobsQuery(
			"SELECT status FROM wheels_jobs WHERE id = :id",
			{id = {value = arguments.id, cfsqltype = "cf_sql_varchar"}},
			{datasource = application.wheels.dataSourceName}
		);
		return q.recordCount ? q.status : "";
	}

	/**
	 * Now on the jobs clock (wheels.JobClock): UTC epoch seconds from the database's clock, which
	 * job rows and memos are stamped with. A row stamped with the app's local Now() is hours out
	 * on a server that isn't on UTC.
	 */
	private numeric function jobsNow() {
		return new wheels.Job().$jobClock().nowEpoch();
	}

	/**
	 * jobsQuery() with wheels_epoch timestamp parameters, as the jobs code binds them.
	 */
	private any function jobsQuery(required string sql, struct params = {}, struct options = {}) {
		return new wheels.Job().$jobClock().query(arguments.sql, arguments.params, arguments.options);
	}

}
