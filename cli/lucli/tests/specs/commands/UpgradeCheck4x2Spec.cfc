/**
 * `wheels upgrade check` for an upgrade that crosses 4.2.0: the 4.1 → 4.2
 * checks run, and the report points at the 4.1 → 4.2 guide instead of
 * "no new breaking changes". Each spec writes the one file its check reads
 * and asserts on that check's description in the JSON report.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.testHelper = new cli.lucli.tests.TestHelper();
		// chr(60) keeps literal CFML tags out of this file (Lucee's tag scanner).
		variables.lt = chr(60);
	}

	private void function seed(string version = "4.1.2") {
		directoryCreate(variables.tempRoot & "/vendor/wheels", true, true);
		fileWrite(variables.tempRoot & "/vendor/wheels/wheels.json", '{"name":"wheels","version":"' & arguments.version & '"}');
	}

	private void function put(required string relPath, required string content) {
		var path = variables.tempRoot & "/" & arguments.relPath;
		directoryCreate(getDirectoryFromPath(path), true, true);
		fileWrite(path, arguments.content);
	}

	/** Run the check as JSON; return the report plus whether it exited non-zero. */
	private struct function runCheck(string to = "4.2.0") {
		var state = {threw: false};
		try {
			mod.upgrade(argumentCollection = {"arg1": "check", "to": arguments.to, "format": "json"});
		} catch (Wheels.UpgradeCheckFailed e) {
			state.threw = true;
		}
		var printed = trim(mod.capturedOutput());
		var report = deserializeJSON(mid(printed, find("{", printed), len(printed)));
		report.threw = state.threw;
		return report;
	}

	private boolean function has(required array entries, required string description) {
		for (var entry in arguments.entries) {
			var text = isStruct(entry) ? entry.description : entry;
			if (findNoCase(arguments.description, text)) {
				return true;
			}
		}
		return false;
	}

	function run() {

		describe("wheels upgrade check, 4.1 -> 4.2", () => {

			beforeEach(() => {
				variables.tempRoot = testHelper.scaffoldTempProject(expandPath("/"));
				variables.mod = new cli.lucli.tests._fixtures.commands.ModuleOutputCapture(cwd = variables.tempRoot);
				seed();
			});

			afterEach(() => {
				testHelper.cleanupTempProject(variables.tempRoot);
			});

			it("points at the 4.1 -> 4.2 guide", () => {
				var report = runCheck();
				expect(report.guide).toInclude("upgrading/4x-1-to-4x-2/");
			});

			it("is an error when environment.cfm selects the environment without WHEELS_ENV", () => {
				put("config/environment.cfm", lt & "cfscript>set(environment=application.env.environment);" & lt & "/cfscript>");
				var report = runCheck();
				expect(has(report.breaking, "selects the environment without WHEELS_ENV")).toBeTrue();
				expect(report.threw).toBeTrue();
			});

			it("is an error for a host lookup that picks between quoted literals", () => {
				put("config/environment.cfm", lt & "cfscript>if (cgi.server_name == ""www.example.com"") { set(environment=""production""); } else { set(environment=""development""); }" & lt & "/cfscript>");
				var report = runCheck();
				expect(has(report.breaking, "selects the environment without WHEELS_ENV")).toBeTrue();
				expect(has(report.advisories, "hardcodes the environment")).toBeFalse();
			});

			it("is an error for the same lookup written with cfif tags", () => {
				put("config/environment.cfm", lt & "cfif cgi.server_name is ""www.example.com"">" & lt & "cfset set(environment=""production"")>" & lt & "cfelse>" & lt & "cfset set(environment=""development"")>" & lt & "/cfif>");
				expect(has(runCheck().breaking, "selects the environment without WHEELS_ENV")).toBeTrue();
			});

			it("is an error for an interpolated value", () => {
				put("config/environment.cfm", lt & "cfscript>set(environment=""##application.envName##"");" & lt & "/cfscript>");
				expect(has(runCheck().breaking, "selects the environment without WHEELS_ENV")).toBeTrue();
			});

			it("is an error for more than one set(environment=)", () => {
				put("config/environment.cfm", lt & "cfscript>set(environment=""development"");" & chr(10) & "set(environment=""production"");" & lt & "/cfscript>");
				expect(has(runCheck().breaking, "selects the environment without WHEELS_ENV")).toBeTrue();
			});

			it("is advisory when environment.cfm hardcodes the environment", () => {
				put("config/environment.cfm", lt & "cfscript>set(environment=""development"");" & lt & "/cfscript>");
				var report = runCheck();
				expect(has(report.advisories, "hardcodes the environment")).toBeTrue();
				expect(has(report.breaking, "selects the environment without WHEELS_ENV")).toBeFalse();
			});

			it("passes an environment.cfm that reads WHEELS_ENV", () => {
				fileCopy(expandPath("/cli/lucli/templates/app/config/environment.cfm"), variables.tempRoot & "/config/environment.cfm");
				var report = runCheck();
				expect(has(report.breaking, "selects the environment without WHEELS_ENV")).toBeFalse();
				expect(has(report.advisories, "hardcodes the environment")).toBeFalse();
				expect(has(report.passed, "selects the environment without WHEELS_ENV")).toBeTrue();
			});

			it("lists event templates that are not wrapped in cfsilent, or end with a newline", () => {
				put("app/events/onrequeststart.cfm", lt & "cfscript>x = 1;" & lt & "/cfscript>" & chr(10));
				put("app/events/onrequestend.cfm", lt & "cfsilent>" & lt & "/cfsilent>" & chr(10));
				put("app/events/onsessionstart.cfm", lt & "cfsilent>" & lt & "cfscript>x = 1;" & lt & "/cfscript>" & lt & "/cfsilent>");
				var report = runCheck();
				var entry = {};
				for (var a in report.advisories) {
					if (findNoCase("Event templates", a.description)) entry = a;
				}
				expect(structIsEmpty(entry)).toBeFalse();
				expect(entry.matches).toInclude("app/events/onrequeststart.cfm");
				expect(entry.matches).toInclude("app/events/onrequestend.cfm");
				expect(arrayFind(entry.matches, "app/events/onsessionstart.cfm")).toBe(0);
			});

			it("flags a .gitignore that ignores vendor/", () => {
				put(".gitignore", ".env" & chr(10) & "/vendor" & chr(10));
				expect(has(runCheck().advisories, ".gitignore ignores vendor/")).toBeTrue();
			});

			it("is an error for a joinType outside inner, outer, left and left outer", () => {
				put("app/models/Spec4x2Bad.cfc", "component extends=""Model"" { function config() { hasMany(name=""items"", joinType=""left join""); } }");
				var report = runCheck();
				expect(has(report.breaking, "joinType")).toBeTrue();
			});

			it("accepts the four joinType values", () => {
				put("app/models/Spec4x2Good.cfc", "component extends=""Model"" { function config() { hasMany(name=""a"", joinType=""left outer""); hasMany(name=""b"", joinType=""inner""); } }");
				var report = runCheck();
				var entry = {};
				for (var b in report.breaking) {
					if (findNoCase("joinType", b.description)) entry = b;
				}
				var hits = structIsEmpty(entry) ? [] : entry.matches;
				for (var m in hits) {
					expect(m).notToInclude("Spec4x2Good.cfc");
				}
			});

			it("is an error when a route targets renderNotFound", () => {
				put("config/routes.cfm", lt & "cfscript>mapper().get(name=""gone"", to=""pages##renderNotFound"").end();" & lt & "/cfscript>");
				expect(has(runCheck().breaking, "renderNotFound")).toBeTrue();
			});

			it("is an error when a MySQL datasource sets tinyInt1isBit=false", () => {
				put("config/app.cfm", lt & "cfscript>this.datasources[""a""] = {connectionString: ""jdbc:mysql://h/db?tinyInt1isBit=false""};" & lt & "/cfscript>");
				expect(has(runCheck().breaking, "tinyInt1isBit=false")).toBeTrue();
			});

			it("is an error for a condition that uses is/and/or with this.", () => {
				put("app/models/Spec4x2Cond.cfc", "component extends=""Model"" { function config() { validatesPresenceOf(property=""a"", condition=""this.status is 'x'""); } }");
				expect(has(runCheck().breaking, "is, and, or with this.")).toBeTrue();
			});

			it("skips the X-Forwarded-Proto check when trustProxyHeaders is on", () => {
				put("app/controllers/Spec4x2Proxy.cfc", "component extends=""Controller"" { function index() { x = cgi.http_x_forwarded_proto; } }");
				expect(has(runCheck().advisories, "X-Forwarded-Proto")).toBeTrue();
				put("config/settings.cfm", lt & "cfscript>set(trustProxyHeaders=true);" & lt & "/cfscript>");
				variables.mod = new cli.lucli.tests._fixtures.commands.ModuleOutputCapture(cwd = variables.tempRoot);
				expect(has(runCheck().advisories, "X-Forwarded-Proto")).toBeFalse();
			});

			it("runs none of the 4.2 checks when the upgrade doesn't cross 4.2.0", () => {
				seed("4.2.0");
				var same = runCheck("4.2.0");
				expect(has(same.passed, "selects the environment without WHEELS_ENV")).toBeFalse();
				expect(same.guide).notToInclude("4x-1-to-4x-2");

				variables.mod = new cli.lucli.tests._fixtures.commands.ModuleOutputCapture(cwd = variables.tempRoot);
				seed("4.0.1");
				var older = runCheck("4.1.0");
				expect(has(older.passed, "selects the environment without WHEELS_ENV")).toBeFalse();
			});
		});

		describe("$upgradeCrosses42()", () => {
			it("is true only from below 4.2.0 to 4.2.0 or later", () => {
				var m = new cli.lucli.Module(cwd = getTempDirectory());
				expect(m.$upgradeCrosses42("4.1.2", "4.2.0")).toBeTrue();
				expect(m.$upgradeCrosses42("4.0.6", "4.2.1")).toBeTrue();
				expect(m.$upgradeCrosses42("4.2.0", "4.2.1")).toBeFalse();
				expect(m.$upgradeCrosses42("4.1.0", "4.1.2")).toBeFalse();
				expect(m.$upgradeCrosses42("@build.version@", "4.2.0")).toBeFalse();
			});
		});
	}
}
