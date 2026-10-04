/**
 * The framework's own test runners (the core runner and the RocketUnit runner) never use
 * the app's primary datasource unless the request asks for it: `?db=`, the
 * |datasourceName| placeholder and a dedicated coreTestDataSourceName behave as before;
 * a coreTestDataSourceName that is the app's own datasource gets `<datasource>_test` or
 * a refusal.
 */
component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo;

		describe("$coreTestDataSource()", () => {

			it("uses wheelstestdb_<db> for a known ?db=", () => {
				var choice = g.$coreTestDataSource(primary = "myapp", coreName = "myapp", requestUrl = {db = "sqlite"});
				expect(choice.action).toBe("use");
				expect(choice.target).toBe("wheelstestdb_sqlite");
			});

			it("maps both SQL Server values to wheelstestdb_sqlserver", () => {
				expect(g.$coreTestDataSource(primary = "myapp", coreName = "myapp", requestUrl = {db = "sqlserver"}).target).toBe("wheelstestdb_sqlserver");
				expect(g.$coreTestDataSource(primary = "myapp", coreName = "myapp", requestUrl = {db = "sqlserver_cicd"}).target).toBe("wheelstestdb_sqlserver");
			});

			it("uses wheelstestdb for the |datasourceName| placeholder", () => {
				var choice = g.$coreTestDataSource(primary = "myapp", coreName = "|datasourceName|", requestUrl = {});
				expect(choice.action).toBe("use");
				expect(choice.target).toBe("wheelstestdb");
			});

			it("uses a coreTestDataSourceName that is not the app's primary datasource as it is", () => {
				var choice = g.$coreTestDataSource(primary = "myapp", coreName = "myapp_core", requestUrl = {}, candidateRegistered = false);
				expect(choice.action).toBe("use");
				expect(choice.target).toBe("myapp_core");
			});

			it("uses <datasource>_test when coreTestDataSourceName is the app's primary datasource", () => {
				var choice = g.$coreTestDataSource(primary = "myapp", coreName = "myapp", requestUrl = {}, candidateRegistered = true);
				expect(choice.action).toBe("swap");
				expect(choice.target).toBe("myapp_test");
			});

			it("refuses when coreTestDataSourceName is the app's primary datasource and <datasource>_test is missing", () => {
				var choice = g.$coreTestDataSource(primary = "myapp", coreName = "myapp", requestUrl = {}, candidateRegistered = false);
				expect(choice.action).toBe("refuse");
				expect(choice.decision.candidate).toBe("myapp_test");
			});

			it("runs on the primary datasource only for an explicit useTestDB=false", () => {
				var choice = g.$coreTestDataSource(primary = "myapp", coreName = "myapp", requestUrl = {useTestDB = false}, candidateRegistered = false);
				expect(choice.action).toBe("primary");
				expect(choice.target).toBe("myapp");
			});

			it("only accepts ?db= values from the runner's own list", () => {
				var choice = g.$coreTestDataSource(
					primary = "myapp",
					coreName = "myapp",
					requestUrl = {db = "sqlite"},
					testDbList = "mysql,sqlserver,postgres,h2,cockroachdb",
					candidateRegistered = false
				);
				expect(choice.action).toBe("refuse");
			});

		});

		describe("runner wiring", () => {

			it("the core runner picks its datasource with $coreTestDataSource() before swapping in the test config", () => {
				var source = FileRead(ExpandPath("/wheels/tests/runner.cfm"));
				var pickPos = FindNoCase("$coreTestDataSource(", source);
				var swapPos = FindNoCase("variables.$_setTestboxEnv();", source);
				expect(pickPos).toBeGT(0);
				expect(swapPos).toBeGT(pickPos);
				expect(FindNoCase("application.wheels.dataSourceName = variables.$_coreTestDataSourceName", source)).toBeGT(0);
			});

			it("the RocketUnit runner picks its datasource with $coreTestDataSource()", () => {
				var source = FileRead(ExpandPath("/wheels/rocketunit_tests/env.cfm"));
				expect(FindNoCase("$coreTestDataSource(", source)).toBeGT(0);
				expect(FindNoCase("application.wheels.dataSourceName = application.wheels.coreTestDataSourceName", source)).toBe(0);
			});

		});

	}

}
