/**
 * Source-level regression for the `wheels reload` hot-vs-cold contract.
 *
 * The reload command makes a real HTTP request, which is hard to unit-test
 * without spinning up a server. Test the *output formatting* by asserting
 * the relevant strings appear in Module.cfc::reload(). A heavier integration
 * test for reload behavior is out of scope here.
 *
 * See finding #8 in
 * docs/superpowers/plans/2026-04-29-fresh-vm-onboarding-findings.md
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function run() {

		describe("wheels reload — output hints", () => {

			it("emits a note that onApplicationStart does NOT re-fire on a hot reload", () => {
				var moduleSource = fileRead(expandPath("/cli/lucli/Module.cfc"));
				expect(moduleSource).toInclude("onApplicationStart does NOT re-fire");
				expect(moduleSource).toInclude("wheels stop && wheels start");
			});

		});

	}

}
