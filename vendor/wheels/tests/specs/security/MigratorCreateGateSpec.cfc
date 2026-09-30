component extends="wheels.WheelsTest" {

	private string function readPublic(required string rel) {
		return FileRead(ExpandPath("/wheels/public/" & arguments.rel));
	}

	function run() {
		describe("migrator create-migration endpoint is gated like command", () => {

			it("the shared guard defines the three gates and a combined caller", () => {
				var g = readPublic("migrator/_guard.cfm");
				expect(g).toInclude("$migratorEnforceLocalhost");
				expect(g).toInclude("$migratorEnforceNoForwardedClients");
				expect(g).toInclude("$migratorVerifyCsrfToken");
				expect(g).toInclude("$migratorApplyDevToolGuards");
			});

			it("the create endpoint applies the dev-tool guards before writing a migration", () => {
				var t = readPublic("migrator/templating.cfm");
				expect(t).toInclude("/wheels/public/migrator/_guard.cfm");
				var guardPos = Find("$migratorApplyDevToolGuards()", t);
				var createPos = Find("createMigration(", t);
				expect(guardPos).toBeGT(0, "guard call missing");
				expect(createPos).toBeGT(0, "createMigration missing");
				expect(guardPos).toBeLT(createPos, "guard must run before createMigration");
			});

			it("the command endpoint still applies the guards via the shared include", () => {
				var c = readPublic("migrator/command.cfm");
				expect(c).toInclude("/wheels/public/migrator/_guard.cfm");
				expect(c).toInclude("$migratorVerifyCsrfToken()");
			});

			it("the create GUI form sends the anti-CSRF header", () => {
				var v = readPublic("views/templating.cfm");
				expect(v).toInclude("X-Wheels-Csrf-Token");
				expect(v).toInclude("migratorCsrfToken");
			});

		});
	}
}
