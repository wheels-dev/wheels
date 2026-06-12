/**
 * Source-level regression for the `wheels reload` hot-vs-cold contract.
 *
 * The reload command makes a real HTTP request, which is hard to unit-test
 * without spinning up a server. Test the *output formatting* by asserting
 * the relevant strings appear in Module.cfc::reload(). A heavier integration
 * test for reload behavior is out of scope here.
 *
 * Contract (verified live on Lucee 7, see #3110): an authorized
 * `?reload=true&password=...` calls applicationStop(), so the next request
 * re-fires onApplicationStart in full — config/services.cfm and the
 * PackageLoader re-run. The earlier "does NOT re-fire" note was wrong; it
 * stemmed from reloads whose password never resolved (a missing/wrong
 * password silently skips the restart, see #3059 / #3062).
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function run() {

		describe("wheels reload — output hints", () => {

			it("emits a note that an authorized reload re-fires onApplicationStart", () => {
				var moduleSource = fileRead(expandPath("/cli/lucli/Module.cfc"));
				expect(moduleSource).toInclude("re-fires onApplicationStart");
				// The old, false claim must be gone.
				expect(moduleSource).notToInclude("onApplicationStart does NOT re-fire");
			});

			it("honors an explicit --password override before falling back to auto-detect", () => {
				// reload() parses --password via parseConsoleArgs and only
				// auto-detects when no override is supplied (parity with
				// `wheels console`). Source-scanned for the same reason as above:
				// reload() makes a live HTTP call, so we assert the wiring rather
				// than exercise it. Window the reload() body and confirm the
				// override-wins-then-fallback shape.
				var moduleSource = fileRead(expandPath("/cli/lucli/Module.cfc"));
				var startIdx = reFindNoCase("(?m)^[ \t]*public\s+string\s+function\s+reload\s*\(", moduleSource);
				expect(startIdx).toBeGT(0);
				var body = mid(moduleSource, startIdx, 1200);
				expect(body).toInclude("parseConsoleArgs(structuredArgs(arguments))");
				expect(body).toInclude("detectReloadPassword()");
				expect(reFindNoCase("len\(\s*reloadOpts\.password\s*\)\s*\?", body)).toBeGT(0);
			});

		});

	}

}
