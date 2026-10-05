/**
 * The test-context PATH trigger must match a test-runner endpoint only when the request path targets
 * it, anchored at the START of the path. `TestContext.$pathTriggersTestContext()` checks `path_info`
 * and `script_name`: it strips the query string, rejects a non-canonical value (a `..` traversal or an
 * empty `//` segment), then requires the value to EQUAL a runner path or start with one followed by
 * `/`. The inline copy in events/testcontext.cfm is kept in lockstep.
 *
 * These cases pin the boundary: the real runner paths (including reached via an index.cfm script, so
 * the runner is in path_info) match; a runner path that merely appears later in an application route,
 * or is reached through `//` or a `..` traversal, does NOT.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("TestContext path trigger — anchored to the runner endpoints", () => {

			variables.tc = new wheels.events.TestContext();

			// ── Bound: the request path targets a runner endpoint ──

			it("matches the core runner path in path_info", () => {
				expect(variables.tc.$pathTriggersTestContext({path_info = "/wheels/core/tests"})).toBeTrue();
			});

			it("matches the app runner path in path_info", () => {
				expect(variables.tc.$pathTriggersTestContext({path_info = "/wheels/app/tests"})).toBeTrue();
			});

			it("matches a runner path in script_name", () => {
				expect(variables.tc.$pathTriggersTestContext({script_name = "/wheels/core/tests"})).toBeTrue();
			});

			it("matches the runner reached via an index.cfm script (path_info carries the runner)", () => {
				expect(variables.tc.$pathTriggersTestContext({script_name = "/index.cfm", path_info = "/wheels/app/tests"})).toBeTrue();
			});

			it("matches a runner sub-path (runner followed by a slash)", () => {
				expect(variables.tc.$pathTriggersTestContext({path_info = "/wheels/core/tests/suite"})).toBeTrue();
			});

			it("matches a runner path carrying a query string", () => {
				expect(variables.tc.$pathTriggersTestContext({path_info = "/wheels/core/tests?reload=true"})).toBeTrue();
			});

			it("matches a runner path whose query string contains // and .. (query is cut before the reject checks)", () => {
					expect(variables.tc.$pathTriggersTestContext({path_info = "/wheels/core/tests?redirect=http://evil/../x"})).toBeTrue();
				});

			it("matches the testbox app-runner convention path", () => {
				expect(variables.tc.$pathTriggersTestContext({path_info = "/wheels/testbox"})).toBeTrue();
			});

			it("matches the tests_testbox core-runner convention path", () => {
				expect(variables.tc.$pathTriggersTestContext({path_info = "/wheels/tests_testbox"})).toBeTrue();
			});

			it("matches a runner path case-insensitively (path case varies by engine/web server)", () => {
				expect(variables.tc.$pathTriggersTestContext({path_info = "/WHEELS/TestBox"})).toBeTrue();
				expect(variables.tc.$pathTriggersTestContext({script_name = "/Wheels/Core/Tests"})).toBeTrue();
			});

			it("matches a testbox sub-path (runner followed by a slash)", () => {
				expect(variables.tc.$pathTriggersTestContext({path_info = "/wheels/testbox/bundles"})).toBeTrue();
			});

				// ── Not bound: the runner path is not what the request targets ──

			it("does NOT match a runner path embedded later in an application route", () => {
				expect(variables.tc.$pathTriggersTestContext({path_info = "/files/x/wheels/app/tests"})).toBeFalse();
			});

			it("does NOT match a testbox path that is only a prefix of a longer segment", () => {
				expect(variables.tc.$pathTriggersTestContext({path_info = "/wheels/testboxer"})).toBeFalse();
			});

			it("does NOT match a testbox runner embedded later in an application route", () => {
				expect(variables.tc.$pathTriggersTestContext({path_info = "/files/x/wheels/testbox"})).toBeFalse();
			});

			it("does NOT match a path with a double slash", () => {
				expect(variables.tc.$pathTriggersTestContext({path_info = "//wheels/app/tests"})).toBeFalse();
			});

			it("does NOT match a path reached through a .. traversal", () => {
				expect(variables.tc.$pathTriggersTestContext({path_info = "/wheels/app/tests/../../files/x"})).toBeFalse();
			});

			it("does NOT match a runner path that is only a prefix of a longer segment", () => {
				expect(variables.tc.$pathTriggersTestContext({path_info = "/wheels/core/testsuite"})).toBeFalse();
			});

			it("does NOT match an empty path scope", () => {
				expect(variables.tc.$pathTriggersTestContext({})).toBeFalse();
			});

			it("does NOT match a value that starts with a query marker (cut yields an empty path)", () => {
				expect(variables.tc.$pathTriggersTestContext({path_info = "?/wheels/core/tests"})).toBeFalse();
			});

		});

	}

}
