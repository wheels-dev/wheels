/**
 * Per-host job control: the wheels_job_hosts registry, the per-host concurrency cap
 * (jobsMaxConcurrentPerHost, or tick(maxConcurrent=)), and drain()/resume() with an expiry.
 * Every spec runs under its own jobsHostName, so a cap or a drain never leaks into other suites.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("Job hosts", function() {

			beforeEach(function() {
				var bootstrapJob = new wheels.Job();
				bootstrapJob.$ensureJobTable();
				request.$wheelsHostsSpec = {host = "wheels-spec-" & Left(Replace(CreateUUID(), "-", "", "all"), 20)};
				application.wheels.jobsHostName = request.$wheelsHostsSpec.host;
				StructDelete(application.wheels, "jobsMaxConcurrentPerHost");
				$cleanup();
			});

			afterEach(function() {
				$cleanup();
				StructDelete(application.wheels, "jobsHostName");
				StructDelete(application.wheels, "jobsMaxConcurrentPerHost");
				StructDelete(request, "$wheelsHostsSpec");
			});

			it("uses jobsHostName as the claiming host", function() {
				var job = new wheels.Job();
				expect(job.$jobHostName()).toBe(request.$wheelsHostsSpec.host);
			});

			it("starts nothing while this host already runs jobsMaxConcurrentPerHost jobs", function() {
				application.wheels.jobsMaxConcurrentPerHost = 1;
				$insertJob(queue = "test_hosts_cap", status = "processing", claimedBy = request.$wheelsHostsSpec.host);
				var pendingId = $insertJob(queue = "test_hosts_cap");

				var worker = new wheels.JobWorker();
				var result = worker.processNext(queues = "test_hosts_cap", timeout = 300);

				expect(result.capped).toBeTrue("a full host must not claim another job");
				expect(result.skipped).toBeTrue();
				expect($status(pendingId)).toBe("pending");
			});

			it("runs a job when the host is below its cap", function() {
				application.wheels.jobsMaxConcurrentPerHost = 2;
				$insertJob(queue = "test_hosts_room", status = "processing", claimedBy = request.$wheelsHostsSpec.host);
				var pendingId = $insertJob(queue = "test_hosts_room");

				var worker = new wheels.JobWorker();
				var result = worker.processNext(queues = "test_hosts_room", timeout = 300);

				expect(result.success).toBeTrue();
				expect($status(pendingId)).toBe("completed");
			});

			it("does not count other hosts' running jobs against this host's cap", function() {
				application.wheels.jobsMaxConcurrentPerHost = 1;
				$insertJob(queue = "test_hosts_other", status = "processing", claimedBy = "some-other-host");
				var pendingId = $insertJob(queue = "test_hosts_other");

				var worker = new wheels.JobWorker();
				expect(worker.processNext(queues = "test_hosts_other", timeout = 300).success).toBeTrue();
				expect($status(pendingId)).toBe("completed");
			});

			it("starts nothing on a draining host and resumes on resume()", function() {
				var pendingId = $insertJob(queue = "test_hosts_drain");
				var runner = new wheels.JobRunner();
				runner.drain();

				var worker = new wheels.JobWorker();
				var drained = worker.processNext(queues = "test_hosts_drain", timeout = 300);
				expect(drained.draining).toBeTrue("a draining host must not start new jobs");
				expect($status(pendingId)).toBe("pending");

				runner.resume();
				expect(worker.processNext(queues = "test_hosts_drain", timeout = 300).success).toBeTrue();
				expect($status(pendingId)).toBe("completed");
			});

			it("treats an expired drain as resumed", function() {
				var pendingId = $insertJob(queue = "test_hosts_expired");
				var runner = new wheels.JobRunner();
				runner.drain(expiresInSeconds = 600);
				jobsQuery(
					"UPDATE wheels_job_hosts SET drainExpiresAt = :past WHERE host = :host",
					{
						past = {value = jobsNow() - 1 * 60, cfsqltype = "wheels_epoch"},
						host = {value = request.$wheelsHostsSpec.host, cfsqltype = "cf_sql_varchar"}
					},
					{datasource = application.wheels.dataSourceName}
				);
				var worker = new wheels.JobWorker();
				expect(worker.processNext(queues = "test_hosts_expired", timeout = 300).success).toBeTrue();
				expect($status(pendingId)).toBe("completed");
			});

			it("tick registers the host and runs up to maxJobs jobs", function() {
				$insertJob(queue = "test_hosts_tick");
				$insertJob(queue = "test_hosts_tick");
				$insertJob(queue = "test_hosts_tick");
				var runner = new wheels.JobRunner();
				var result = runner.tick(queues = "test_hosts_tick", maxConcurrent = 5, maxJobs = 2);

				expect(result.processed).toBe(2);
				expect(result.host).toBe(request.$wheelsHostsSpec.host);
				var row = $hostRow();
				expect(row.recordCount).toBe(1, "tick must register the host");
				expect(Val(row.maxConcurrent)).toBe(5);
				expect(Len(row.codeVersion)).toBeGT(0);
			});

			it("tick on a draining host starts nothing but still reaps stale jobs", function() {
				$insertJob(queue = "test_hosts_tickdrain");
				var staleId = $insertJob(queue = "test_hosts_tickdrain", status = "processing", claimedBy = "a-dead-host", stale = true, attempts = 1);
				var runner = new wheels.JobRunner();
				runner.drain();
				var result = runner.tick(queues = "test_hosts_tickdrain", maxJobs = 5);

				expect(result.processed).toBe(0);
				expect(result.draining).toBeTrue();
				expect($status(staleId)).toBe("pending", "reaping continues while draining");
			});

			it("status reports this host's running jobs, cap and drain", function() {
				application.wheels.jobsMaxConcurrentPerHost = 3;
				$insertJob(queue = "test_hosts_status", status = "processing", claimedBy = request.$wheelsHostsSpec.host);
				var runner = new wheels.JobRunner();
				runner.drain(expiresInSeconds = 300);
				var status = runner.status();

				expect(status.host).toBe(request.$wheelsHostsSpec.host);
				expect(status.running).toBe(1);
				expect(status.maxConcurrent).toBe(3);
				expect(status.draining).toBeTrue();
			});

			// Kept last: it replaces wheels_job_hosts, then puts the real table back.
			it("fails closed when the registry exists but can't be read", function() {
				var job = new wheels.Job();
				job.$ensureHostsTable();
				jobsQuery("DROP TABLE wheels_job_hosts", {}, {datasource = application.wheels.dataSourceName});
				// A table without drainExpiresAt: the drain query fails although the table exists.
				jobsQuery("CREATE TABLE wheels_job_hosts (host VARCHAR(128) NOT NULL PRIMARY KEY, draining INT DEFAULT 0 NOT NULL)", {}, {datasource = application.wheels.dataSourceName});
				try {
					var state = {threw = false};
					try {
						job.$hostDraining(request.$wheelsHostsSpec.host);
					} catch (any e) {
						state.threw = true;
					}
					expect(state.threw).toBeTrue("a registry that exists but can't be read must not count as 'not draining'");
				} finally {
					jobsQuery("DROP TABLE wheels_job_hosts", {}, {datasource = application.wheels.dataSourceName});
					job.$ensureHostsTable();
				}
				expect(job.$hostDraining(request.$wheelsHostsSpec.host)).toBeFalse();
			});

		});
	}

	private void function $cleanup() {
		try {
			jobsQuery("DELETE FROM wheels_jobs WHERE queue LIKE 'test_hosts_%'", {}, {datasource = application.wheels.dataSourceName});
		} catch (any e) {
		}
		if (StructKeyExists(request, "$wheelsHostsSpec")) {
			try {
				jobsQuery(
					"DELETE FROM wheels_job_hosts WHERE host = :host",
					{host = {value = request.$wheelsHostsSpec.host, cfsqltype = "cf_sql_varchar"}},
					{datasource = application.wheels.dataSourceName}
				);
			} catch (any e) {
			}
		}
	}

	private string function $insertJob(
		required string queue,
		string status = "pending",
		string claimedBy = "",
		boolean stale = false,
		numeric attempts = 0
	) {
		var id = CreateUUID();
		var stamp = arguments.stale ? jobsNow() - 2 * 3600 : jobsNow() - 5;
		var columns = "id, jobClass, queue, data, priority, status, attempts, maxRetries, runAt, createdAt, updatedAt";
		var values = ":id, 'wheels.tests._assets.jobs.ProcessOrdersJob', :queue, '{}', 0, :status, :attempts, 3, :runAt, :createdAt, :updatedAt";
		var params = {
			id = {value = id, cfsqltype = "cf_sql_varchar"},
			queue = {value = arguments.queue, cfsqltype = "cf_sql_varchar"},
			status = {value = arguments.status, cfsqltype = "cf_sql_varchar"},
			attempts = {value = arguments.attempts, cfsqltype = "cf_sql_integer"},
			runAt = {value = stamp, cfsqltype = "wheels_epoch"},
			createdAt = {value = stamp, cfsqltype = "wheels_epoch"},
			updatedAt = {value = stamp, cfsqltype = "wheels_epoch"}
		};
		if (Len(arguments.claimedBy)) {
			columns &= ", claimedBy";
			values &= ", :claimedBy";
			params.claimedBy = {value = arguments.claimedBy, cfsqltype = "cf_sql_varchar"};
		}
		jobsQuery("INSERT INTO wheels_jobs (#columns#) VALUES (#values#)", params, {datasource = application.wheels.dataSourceName});
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

	private query function $hostRow() {
		return jobsQuery(
			"SELECT * FROM wheels_job_hosts WHERE host = :host",
			{host = {value = request.$wheelsHostsSpec.host, cfsqltype = "cf_sql_varchar"}},
			{datasource = application.wheels.dataSourceName}
		);
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
