/**
 * Lease locks: wheels.LeaseLock (the cross-process lease the Migrator uses, now reusable) and
 * the jobs built on it. A job with this.exclusive = true, or a concurrency key, holds a lease
 * in wheels_job_locks while it runs, so a second run can't start on any server until it ends.
 * A run that finds the lease busy waits as 'pending' without using up an attempt.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("wheels.LeaseLock", function() {

			beforeEach(function() {
				new wheels.Job().$jobLeaseLock();
				$cleanup();
			});

			afterEach(function() {
				$cleanup();
			});

			it("lets one owner take a free lease, and no other until it is released", function() {
				var leaseLock = $lock();
				expect(leaseLock.tryAcquire(name = "spec:one", owner = "a", host = "h1", now = 1000, expiresAt = 9000000000000)).toBeTrue();
				expect(leaseLock.tryAcquire(name = "spec:one", owner = "b", host = "h2", now = 2000, expiresAt = 9000000000000)).toBeFalse();
				expect(leaseLock.ownerOf("spec:one")).toBe("a");
				expect(leaseLock.release(name = "spec:one", owner = "b")).toBeFalse("only the owner can release it");
				expect(leaseLock.release(name = "spec:one", owner = "a")).toBeTrue();
				expect(leaseLock.tryAcquire(name = "spec:one", owner = "b", host = "h2", now = 3000, expiresAt = 9000000000000)).toBeTrue();
			});

			it("takes over an expired lease, and the old owner can neither renew nor release it", function() {
				var leaseLock = $lock();
				leaseLock.tryAcquire(name = "spec:two", owner = "a", host = "h1", now = 1000, expiresAt = 5000);
				expect(leaseLock.tryAcquire(name = "spec:two", owner = "b", host = "h2", now = 4000, expiresAt = 90000)).toBeFalse("not expired yet");
				expect(leaseLock.tryAcquire(name = "spec:two", owner = "b", host = "h2", now = 6000, expiresAt = 90000)).toBeTrue();
				expect(leaseLock.renew(name = "spec:two", owner = "a", expiresAt = 99000)).toBeFalse();
				expect(leaseLock.release(name = "spec:two", owner = "a")).toBeFalse();
				var row = leaseLock.read("spec:two");
				expect(row.owner).toBe("b");
				expect(row.host).toBe("h2");
				expect(row.expiresAt).toBe(90000);
			});

			it("extends the lease while the owner holds it", function() {
				var leaseLock = $lock();
				leaseLock.tryAcquire(name = "spec:three", owner = "a", host = "h1", now = 1000, expiresAt = 5000);
				expect(leaseLock.renew(name = "spec:three", owner = "a", expiresAt = 1791039632175)).toBeTrue();
				expect(leaseLock.read("spec:three").expiresAt).toBe(1791039632175, "epoch milliseconds survive the round trip");
				expect(leaseLock.tryAcquire(name = "spec:three", owner = "b", host = "h2", now = 6000, expiresAt = 90000)).toBeFalse();
			});

			it("builds the Migrator's lock statements for the migrator's own table", function() {
				var m = CreateObject("component", "wheels.Migrator").init(
					migratePath = "/wheels/tests/_assets/migrator/migrations_4134/",
					sqlPath = "/wheels/tests/_assets/migrator/sql_4134/"
				);
				var statement = m.$migrationLease().releaseStatement(name = "migrate", owner = "x", expiredBefore = 5);
				expect(statement.sql).toBe("DELETE FROM #m.$migrationLockTable()# WHERE lockname = :lockName AND lockowner = :owner AND expiresat < :now");
				expect(statement.params.now.cfsqltype).toBe("cf_sql_bigint");
			});

		});

		describe("exclusive jobs", function() {

			beforeEach(function() {
				new wheels.Job().$ensureJobTable();
				new wheels.Job().$jobLeaseLock();
				$cleanup();
				application["$leaseSpecRuns"] = 0;
				application["$leaseSpecHolder"] = "";
			});

			afterEach(function() {
				$cleanup();
			});

			it("holds the job class's lease while it runs, and releases it", function() {
				var id = $insertJob(queue = "test_lease_run", jobClass = "wheels.tests._assets.jobs.ExclusiveProbeJob");
				var result = new wheels.JobWorker().processNext(queues = "test_lease_run", timeout = 300);
				expect(result.success).toBeTrue(result.error);
				expect(application["$leaseSpecRuns"]).toBe(1);
				expect(Len(application["$leaseSpecHolder"])).toBeGT(0, "the lease must be held during perform()");
				expect($leaseRows("job:wheels.tests._assets.jobs.ExclusiveProbeJob")).toBe(0, "released afterwards");
				expect($row(id).status).toBe("completed");
			});

			it("doesn't start while another server holds the lease, and waits as pending", function() {
				$holdLease("job:wheels.tests._assets.jobs.ExclusiveProbeJob");
				var id = $insertJob(queue = "test_lease_busy", jobClass = "wheels.tests._assets.jobs.ExclusiveProbeJob");
				var worker = new wheels.JobWorker();
				var result = worker.processNext(queues = "test_lease_busy", timeout = 300);
				expect(application["$leaseSpecRuns"]).toBe(0, "perform() must not run while another run holds the lease");
				expect(result.skipped).toBeTrue();
				expect(result.deferred).toBeTrue();
				expect(result.success).toBeFalse();
				expect(worker.jobsFailed).toBe(0);
				var row = $row(id);
				expect(row.status).toBe("pending");
				expect(Val(row.attempts)).toBe(0, "waiting for the lease must not use up an attempt");
				expect(row.due).toBeFalse("it waits before it is tried again");
				expect($leaseOwner("job:wheels.tests._assets.jobs.ExclusiveProbeJob")).toBe("spec-other-server");
			});

			it("never uses up its retries while the lease stays busy", function() {
				$holdLease("key:nightly-report");
				var id = $insertJob(queue = "test_lease_forever", jobClass = "wheels.tests._assets.jobs.StaticKeyJob", maxRetries = 1);
				for (var i = 1; i <= 4; i++) {
					$makeDue(id);
					new wheels.JobWorker().processNext(queues = "test_lease_forever", timeout = 300);
				}
				var row = $row(id);
				expect(row.status).toBe("pending", "a busy lease is not a failure");
				expect(Val(row.attempts)).toBe(0);
			});

			it("counts a busy lease as skipped in processQueue()", function() {
				$holdLease("job:wheels.tests._assets.jobs.ExclusiveProbeJob");
				var id = $insertJob(queue = "test_lease_pq", jobClass = "wheels.tests._assets.jobs.ExclusiveProbeJob");
				var result = new wheels.Job().processQueue(queue = "test_lease_pq");
				expect(result.skipped).toBe(1);
				expect(result.failed).toBe(0);
				expect(application["$leaseSpecRuns"]).toBe(0);
				expect(Val($row(id).attempts)).toBe(0);
			});

			it("runs once the other server's lease has expired", function() {
				$holdLease(name = "job:wheels.tests._assets.jobs.ExclusiveProbeJob", expiresAt = 1000);
				$insertJob(queue = "test_lease_expired", jobClass = "wheels.tests._assets.jobs.ExclusiveProbeJob");
				var result = new wheels.JobWorker().processNext(queues = "test_lease_expired", timeout = 300);
				expect(result.success).toBeTrue(result.error);
				expect(application["$leaseSpecRuns"]).toBe(1);
			});

			it("finishes a job whose lease was taken over while it ran, and reports the lost lease", function() {
				var id = $insertJob(queue = "test_lease_lost", jobClass = "wheels.tests._assets.jobs.LeaseThiefJob");
				var worker = new wheels.JobWorker();
				var result = worker.processNext(queues = "test_lease_lost", timeout = 300);
				expect(result.success).toBeTrue("an already-finished job is not failed: " & result.error);
				expect(result.leaseLost).toBeTrue();
				expect(worker.leasesLost).toBe(1);
				expect($row(id).status).toBe("completed");
				expect($leaseOwner("job:wheels.tests._assets.jobs.LeaseThiefJob")).toBe("spec-thief", "another owner's lease is not released");
			});

		});

		describe("job lease names", function() {

			it("uses the concurrencyKeyFor(data) method over this.concurrencyKey, then the job class", function() {
				var bridge = new wheels.Job();
				var keyed = new wheels.tests._assets.jobs.KeyedProbeJob();
				expect(bridge.$jobLeaseName(jobInstance = keyed, jobData = {account = "a1"}, jobClass = "x.KeyedProbeJob")).toBe("key:acct-a1");
				var fixed = new wheels.tests._assets.jobs.StaticKeyJob();
				expect(bridge.$jobLeaseName(jobInstance = fixed, jobData = {}, jobClass = "x.StaticKeyJob")).toBe("key:nightly-report");
				var exclusive = new wheels.tests._assets.jobs.ExclusiveProbeJob();
				expect(bridge.$jobLeaseName(jobInstance = exclusive, jobData = {}, jobClass = "x.ExclusiveProbeJob")).toBe("job:x.ExclusiveProbeJob");
				var plain = new wheels.tests._assets.jobs.ProcessOrdersJob();
				expect(bridge.$jobLeaseName(jobInstance = plain, jobData = {}, jobClass = "x.ProcessOrdersJob")).toBe("");
			});

			it("hashes a name too long for the lock table", function() {
				var name = new wheels.Job().$fitLeaseName(prefix = "key:", value = RepeatString("k", 120));
				expect(Len(name)).toBe(68);
				expect(Left(name, 4)).toBe("key:");
			});

		});
	}

	private any function $lock() {
		return new wheels.LeaseLock(table = "wheels_job_locks", datasource = application.wheels.dataSourceName);
	}

	private void function $cleanup() {
		try {
			queryExecute("DELETE FROM wheels_jobs WHERE queue LIKE 'test_lease_%'", {}, {datasource = application.wheels.dataSourceName});
		} catch (any e) {
		}
		try {
			queryExecute(
				"DELETE FROM wheels_job_locks WHERE lockname LIKE 'spec:%' OR lockname LIKE 'job:wheels.tests.%' OR lockname = 'key:nightly-report'",
				{},
				{datasource = application.wheels.dataSourceName}
			);
		} catch (any e) {
		}
	}

	private void function $holdLease(required string name, numeric expiresAt = 9000000000000) {
		$lock().tryAcquire(name = arguments.name, owner = "spec-other-server", host = "other", now = 500, expiresAt = arguments.expiresAt);
	}

	private string function $leaseOwner(required string name) {
		return $lock().ownerOf(arguments.name);
	}

	private numeric function $leaseRows(required string name) {
		return $lock().read(arguments.name).held ? 1 : 0;
	}

	private string function $insertJob(required string queue, required string jobClass, numeric maxRetries = 3) {
		var id = CreateUUID();
		var stamp = DateAdd("s", -5, Now());
		queryExecute(
			"INSERT INTO wheels_jobs (id, jobClass, queue, data, priority, status, attempts, maxRetries, runAt, createdAt, updatedAt)
			VALUES (:id, :jobClass, :queue, '{}', 0, 'pending', 0, :maxRetries, :runAt, :createdAt, :updatedAt)",
			{
				id = {value = id, cfsqltype = "cf_sql_varchar"},
				jobClass = {value = arguments.jobClass, cfsqltype = "cf_sql_varchar"},
				queue = {value = arguments.queue, cfsqltype = "cf_sql_varchar"},
				maxRetries = {value = arguments.maxRetries, cfsqltype = "cf_sql_integer"},
				runAt = {value = stamp, cfsqltype = "cf_sql_timestamp"},
				createdAt = {value = stamp, cfsqltype = "cf_sql_timestamp"},
				updatedAt = {value = stamp, cfsqltype = "cf_sql_timestamp"}
			},
			{datasource = application.wheels.dataSourceName}
		);
		return id;
	}

	private void function $makeDue(required string id) {
		queryExecute(
			"UPDATE wheels_jobs SET runAt = :runAt WHERE id = :id",
			{
				runAt = {value = DateAdd("s", -5, Now()), cfsqltype = "cf_sql_timestamp"},
				id = {value = arguments.id, cfsqltype = "cf_sql_varchar"}
			},
			{datasource = application.wheels.dataSourceName}
		);
	}

	private struct function $row(required string id) {
		var q = queryExecute(
			"SELECT status, attempts FROM wheels_jobs WHERE id = :id",
			{id = {value = arguments.id, cfsqltype = "cf_sql_varchar"}},
			{datasource = application.wheels.dataSourceName}
		);
		var due = queryExecute(
			"SELECT id FROM wheels_jobs WHERE id = :id AND runAt <= :now",
			{
				id = {value = arguments.id, cfsqltype = "cf_sql_varchar"},
				now = {value = Now(), cfsqltype = "cf_sql_timestamp"}
			},
			{datasource = application.wheels.dataSourceName}
		);
		return {status = q.recordCount ? q.status : "", attempts = q.recordCount ? q.attempts : 0, due = due.recordCount > 0};
	}

}
