/**
 * events/init/debugging.cfm on a cold start (#3671). The minimal startup
 * error page reads showErrorInformation, so it must never be true in
 * production, not even briefly: an exception later in the file (the
 * Host-derived error address once threw on a Host such as "example.") would
 * otherwise leave it true and put the full failure on a production page.
 *
 * Each spec stages a scratch application.$wheels, the struct a cold start
 * builds, and restores the real one afterwards, as
 * engineAdapterScopedReadersSpec does.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("debugging.cfm defaults on a cold start (##3671)", () => {

			it("keeps showErrorInformation false in production with a one-label Host ('example.')", () => {
				var state = runDebugging("production", "example.");
				expect(state.error).toBe("");
				expect(state.settings.showErrorInformation).toBeFalse();
				expect(state.settings.errorEmailAddress).toBe("");
				expect(state.settings.sendEmailOnError).toBeTrue();
			});

			it("turns showErrorInformation on outside production, whatever the Host", () => {
				for (var host in ["example.", "localhost", "app.example.com"]) {
					var state = runDebugging("development", host);
					expect(state.error).toBe("", "threw for Host [#host#]");
					expect(state.settings.showErrorInformation).toBeTrue("Host [#host#]");
					expect(state.settings.showDebugInformation).toBeTrue("Host [#host#]");
				}
				var testing = runDebugging("testing", "localhost");
				expect(testing.settings.showErrorInformation).toBeTrue();
				expect(testing.settings.showDebugInformation).toBeFalse();
			});

			it("still derives the error address from a host with two or more labels", () => {
				expect(runDebugging("production", "www.example.com").settings.errorEmailAddress).toBe("webmaster@example.com");
				expect(runDebugging("production", "localhost").settings.errorEmailAddress).toBe("");
				expect(runDebugging("production", ".").settings.errorEmailAddress).toBe("");
			});

		});

	}

	/** Include debugging.cfm against a scratch application.$wheels; returns {error, settings}. */
	private struct function runDebugging(required string environment, required string host) {
		var state = {error = "", settings = {}};
		var hadStaging = StructKeyExists(application, "$wheels");
		var savedStaging = hadStaging ? application.$wheels : {};
		var hadCgi = StructKeyExists(request, "cgi");
		var savedCgi = hadCgi ? request.cgi : {};
		var scratchCgi = hadCgi ? Duplicate(savedCgi) : {};
		scratchCgi.server_name = arguments.host;
		request.cgi = scratchCgi;
		application.$wheels = {environment = arguments.environment};
		try {
			include "/wheels/events/init/debugging.cfm";
		} catch (any e) {
			state.error = e.message;
		} finally {
			state.settings = application.$wheels;
			if (hadStaging) {
				application.$wheels = savedStaging;
			} else {
				StructDelete(application, "$wheels");
			}
			if (hadCgi) {
				request.cgi = savedCgi;
			} else {
				StructDelete(request, "cgi");
			}
		}
		return state;
	}

}
