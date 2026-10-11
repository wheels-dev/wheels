/**
 * The /wheels/cli bridge commands behind `wheels jobs drain|resume|status`: jobsDrain and
 * jobsResume change this server's drain flag, jobsHostStatus reports its job state, and
 * jobsStatus now carries the same host state next to the queue stats. Runs under its own
 * jobsHostName so a drain never leaks into other suites.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("CliBridge jobs host commands", function() {

			beforeEach(function() {
				request.$wheelsBridgeHostSpec = {host = "wheels-bridge-spec-" & Left(Replace(CreateUUID(), "-", "", "all"), 16)};
				application.wheels.jobsHostName = request.$wheelsBridgeHostSpec.host;
			});

			afterEach(function() {
				try {
					queryExecute(
						"DELETE FROM wheels_job_hosts WHERE host = :host",
						{host = {value = request.$wheelsBridgeHostSpec.host, cfsqltype = "cf_sql_varchar"}},
						{datasource = application.wheels.dataSourceName}
					);
				} catch (any e) {
				}
				StructDelete(application.wheels, "jobsHostName");
				StructDelete(request, "$wheelsBridgeHostSpec");
			});

			it("drains, reports and resumes this server", function() {
				var bridge = new wheels.public.CliBridge();

				var drained = bridge.jobsDrain(context = {}, params = {expiresInSeconds = 120});
				expect(drained.success).toBeTrue(drained.message);
				expect(drained.host.host).toBe(request.$wheelsBridgeHostSpec.host);
				expect(drained.host.draining).toBeTrue();

				var status = bridge.jobsHostStatus(context = {}, params = {});
				expect(status.success).toBeTrue(status.message);
				expect(status.host.draining).toBeTrue();
				expect(status.host.running).toBe(0);

				var resumed = bridge.jobsResume(context = {}, params = {});
				expect(resumed.success).toBeTrue(resumed.message);
				expect(resumed.host.draining).toBeFalse();
			});

			it("includes this server's state in jobsStatus", function() {
				var bridge = new wheels.public.CliBridge();
				var status = bridge.jobsStatus(context = {}, params = {});
				expect(status.success).toBeTrue(status.message);
				expect(status).toHaveKey("host");
				expect(status.host.host).toBe(request.$wheelsBridgeHostSpec.host);
			});

			it("treats drain and resume as mutating commands", function() {
				var publicCfc = CreateObject("component", "wheels.Public").$init();
				expect(publicCfc.$cliCommandIsMutating("jobsDrain")).toBeTrue();
				expect(publicCfc.$cliCommandIsMutating("jobsResume")).toBeTrue();
				expect(publicCfc.$cliCommandIsMutating("jobsHostStatus")).toBeFalse();
			});

		});
	}

}
