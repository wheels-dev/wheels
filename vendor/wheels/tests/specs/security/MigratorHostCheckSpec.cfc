component extends="wheels.WheelsTest" {

	// The Host-header parser is the shared Public.$wheelsHostIsLocal, exercised in
	// DevToolsLocalAccessSpec. This spec only checks that the migrator guard still
	// enforces a local Host header (defence in depth behind the dispatch-level
	// gate) and that it routes through the shared parser / setting.

	private string function readPublic(required string rel) {
		return FileRead(ExpandPath("/wheels/public/" & arguments.rel));
	}

	function run() {
		describe("the migrator guard enforces a local host name via the shared parser", () => {

			it("the shared guard defines the hostname gate and the local-access combiner", () => {
				var g = readPublic("migrator/_guard.cfm");
				expect(g).toInclude("$migratorEnforceLocalHostname");
				expect(g).toInclude("$migratorEnforceLocalAccess");
			});

			it("the hostname gate uses the shared $wheelsHostIsLocal parser (one parser)", () => {
				var g = readPublic("migrator/_guard.cfm");
				expect(g).toInclude("$wheelsHostIsLocal(hostHeader");
				// The migrator no longer defines or uses its own parser / setting.
				expect(FindNoCase("$migratorHostIsLocal", g)).toBe(0, "the duplicate parser is removed");
				expect(FindNoCase("migratorAllowedHosts", g)).toBe(0, "the duplicate setting is removed");
			});

			it("the command endpoint enforces the local host name", () => {
				var c = readPublic("migrator/command.cfm");
				expect(c).toInclude("$migratorEnforceLocalHostname()");
			});

			it("the 403 names the exact fix using the unified setting", () => {
				var g = readPublic("migrator/_guard.cfm");
				expect(g).toInclude("add it with set(devToolsAllowedHosts");
				expect(g).toInclude("myapp.test");
			});

			it("the token-issuing views enforce local access before issuing a token", () => {
				for (var rel in ["views/migrator.cfm", "views/templating.cfm"]) {
					var v = readPublic(rel);
					expect(v).toInclude("/wheels/public/migrator/_guard.cfm");
					var guardPos = Find("$migratorEnforceLocalAccess()", v);
					var tokenPos = Find("$migratorCsrfToken =", v);
					expect(guardPos).toBeGT(0, rel & " must call $migratorEnforceLocalAccess()");
					expect(tokenPos).toBeGT(0, rel & " must issue the token");
					expect(guardPos).toBeLT(tokenPos, rel & " must gate before issuing the token");
				}
			});

		});
	}
}
