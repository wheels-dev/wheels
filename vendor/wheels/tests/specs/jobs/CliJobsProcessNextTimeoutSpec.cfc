/**
 * `wheels jobs work` runs each job with its own class's timeout (4517). The CLI worker polls the
 * jobsProcessNext bridge command, which used to default to timeout=300 and so cut every job off
 * at 300 seconds whatever its this.timeout. It now claims and runs each job with its own
 * timeout, like processQueue(), unless the CLI passes --timeout as a cap. The spec reads the
 * timeout each claim recorded (claimTimeout) rather than waiting 300+ seconds.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("jobsProcessNext (wheels jobs work) timeouts", function() {

			beforeEach(function() {
				var bootstrapJob = new wheels.Job();
				bootstrapJob.$ensureJobTable();
				$cleanup();
			});

			afterEach(function() {
				$cleanup();
			});

			it("claims a job with its own class's timeout when no cap is given", function() {
				var id = $insertJob(queue = "test_cpn_own", jobClass = "wheels.tests._assets.jobs.LongTimeoutJob");
				var rv = $processNext({queues = "test_cpn_own"});
				expect(rv.success).toBeTrue(rv.message ?: "");
				expect(Val($claimTimeout(id))).toBe(900, "not the bridge's old 300-second default");
			});

			it("caps the timeout when --timeout is passed", function() {
				var id = $insertJob(queue = "test_cpn_cap", jobClass = "wheels.tests._assets.jobs.LongTimeoutJob");
				$processNext({queues = "test_cpn_cap", timeout = 120});
				expect(Val($claimTimeout(id))).toBe(120);
			});

			it("keeps a default-timeout job at 300 seconds", function() {
				var id = $insertJob(queue = "test_cpn_default");
				$processNext({queues = "test_cpn_default"});
				expect(Val($claimTimeout(id))).toBe(300);
			});

		});

	}

	private struct function $processNext(required struct params) {
		var bridge = new wheels.public.CliBridge();
		return bridge.dispatch(command = "jobsProcessNext", context = {}, params = arguments.params);
	}

	private void function $cleanup() {
		try {
			queryExecute("DELETE FROM wheels_jobs WHERE queue LIKE 'test_cpn_%'", {}, {datasource = application.wheels.dataSourceName});
		} catch (any e) {
		}
	}

	private string function $insertJob(
		required string queue,
		string jobClass = "wheels.tests._assets.jobs.ProcessOrdersJob"
	) {
		var id = CreateUUID();
		var stamp = DateAdd("s", -5, Now());
		queryExecute(
			"INSERT INTO wheels_jobs (id, jobClass, queue, data, priority, status, attempts, maxRetries, runAt, createdAt, updatedAt)
			VALUES (:id, :jobClass, :queue, '{}', 0, 'pending', 0, 3, :runAt, :createdAt, :updatedAt)",
			{
				id = {value = id, cfsqltype = "cf_sql_varchar"},
				jobClass = {value = arguments.jobClass, cfsqltype = "cf_sql_varchar"},
				queue = {value = arguments.queue, cfsqltype = "cf_sql_varchar"},
				runAt = {value = stamp, cfsqltype = "cf_sql_timestamp"},
				createdAt = {value = stamp, cfsqltype = "cf_sql_timestamp"},
				updatedAt = {value = stamp, cfsqltype = "cf_sql_timestamp"}
			},
			{datasource = application.wheels.dataSourceName}
		);
		return id;
	}

	private string function $claimTimeout(required string id) {
		var q = queryExecute(
			"SELECT claimTimeout FROM wheels_jobs WHERE id = :id",
			{id = {value = arguments.id, cfsqltype = "cf_sql_varchar"}},
			{datasource = application.wheels.dataSourceName}
		);
		return q.recordCount && !IsNull(q.claimTimeout[1]) ? q.claimTimeout[1] : "";
	}

}
