/**
 * A project's own tests/runner.cfm runs under the same datasource rule as the
 * built-in app runner: on `<datasource>_test`, on the primary datasource only when
 * asked to, otherwise refused. Covers the decision helper, the swap / restore
 * helpers Public.cfc wraps around the project runner, and the WheelsTest backstop.
 */
component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo;

		describe("$testDataSourceDecision()", () => {

			beforeEach(() => {
				variables.allowWas = StructKeyExists(application.wheels, "allowTestsAgainstPrimaryDatasource")
					? application.wheels.allowTestsAgainstPrimaryDatasource
					: "";
				application.wheels.allowTestsAgainstPrimaryDatasource = false;
			});

			afterEach(() => {
				application.wheels.allowTestsAgainstPrimaryDatasource = variables.allowWas;
			});

			it("uses <datasource>_test when it is registered", () => {
				var decision = g.$testDataSourceDecision(primary = "myapp", requestUrl = {}, candidateRegistered = true);
				expect(decision.action).toBe("swap");
				expect(decision.target).toBe("myapp_test");
				expect(decision.candidate).toBe("myapp_test");
			});

			it("refuses when <datasource>_test is missing and useTestDB was omitted", () => {
				var decision = g.$testDataSourceDecision(primary = "myapp", requestUrl = {}, candidateRegistered = false);
				expect(decision.action).toBe("refuse");
			});

			it("refuses when <datasource>_test is missing and useTestDB=true", () => {
				var decision = g.$testDataSourceDecision(primary = "myapp", requestUrl = {useTestDB = true}, candidateRegistered = false);
				expect(decision.action).toBe("refuse");
			});

			it("runs on the primary datasource for an explicit useTestDB=false", () => {
				var decision = g.$testDataSourceDecision(primary = "myapp", requestUrl = {useTestDB = false}, candidateRegistered = false);
				expect(decision.action).toBe("primary");
				expect(decision.target).toBe("myapp");
				expect(decision.warn).toBeFalse();
			});

			it("runs on the primary datasource, with a warning, when useTestDB is omitted and the app allows it", () => {
				application.wheels.allowTestsAgainstPrimaryDatasource = true;
				var decision = g.$testDataSourceDecision(primary = "myapp", requestUrl = {}, candidateRegistered = false);
				expect(decision.action).toBe("primary");
				expect(decision.warn).toBeTrue();
			});

			it("still refuses an explicit useTestDB=true when the app allows the primary datasource", () => {
				application.wheels.allowTestsAgainstPrimaryDatasource = true;
				var decision = g.$testDataSourceDecision(primary = "myapp", requestUrl = {useTestDB = true}, candidateRegistered = false);
				expect(decision.action).toBe("refuse");
			});

			it("treats a useTestDB value that is not a boolean as a request for the test datasource", () => {
				application.wheels.allowTestsAgainstPrimaryDatasource = true;
				var decision = g.$testDataSourceDecision(primary = "myapp", requestUrl = {useTestDB = "maybe"}, candidateRegistered = false);
				expect(decision.action).toBe("refuse");
			});

			it("names the missing datasource and the runner to replace in the refusal", () => {
				var decision = g.$testDataSourceDecision(primary = "myapp", requestUrl = {}, candidateRegistered = false);
				var refusal = g.$testDataSourceRefusal(decision = decision);
				expect(refusal.error).toBe("Test database not available");
				expect(refusal.message).toInclude("myapp_test");
				expect(refusal.message).toInclude("tests/runner.cfm");
				expect(refusal.message).toInclude("--no-test-db");
				expect(refusal.message).toInclude("allowTestsAgainstPrimaryDatasource");
			});

		});

		describe("$beginTestRunDataSource() / $endTestRunDataSource()", () => {

			it("points dataSourceName and coreTestDataSourceName at the test datasource, then restores both", () => {
				var state = {
					primary = application.wheels.dataSourceName,
					hadCore = StructKeyExists(application.wheels, "coreTestDataSourceName"),
					core = StructKeyExists(application.wheels, "coreTestDataSourceName") ? application.wheels.coreTestDataSourceName : "",
					during = {}
				};
				var decision = {action = "swap", primary = state.primary, candidate = state.primary & "_test", target = state.primary & "_test", warn = false};
				var saved = g.$beginTestRunDataSource(decision = decision);
				try {
					state.during.dataSourceName = application.wheels.dataSourceName;
					state.during.coreTestDataSourceName = application.wheels.coreTestDataSourceName;
					state.during.preSwap = request.wheels.$testRunPreSwap;
					state.during.outer = request.wheels.$testRunnerOuter;
					state.during.token = StructKeyExists(application, "$$$appTestRunToken");
					state.during.marker = StructKeyExists(application, "$$$appTestOriginalDataSource") ? application.$$$appTestOriginalDataSource : "";
					state.during.deadline = StructKeyExists(application, "$$$appTestRunDeadline");
				} finally {
					g.$endTestRunDataSource(saved = saved);
				}

				expect(state.during.dataSourceName).toBe(state.primary & "_test");
				expect(state.during.coreTestDataSourceName).toBe(state.primary & "_test");
				expect(state.during.preSwap.original).toBe(state.primary);
				expect(state.during.outer).toBeTrue();
				expect(state.during.token).toBeTrue();
				expect(state.during.marker).toBe(state.primary);
				expect(state.during.deadline).toBeTrue();
				expect(StructKeyExists(application, "$$$appTestRunToken")).toBeFalse();
				expect(StructKeyExists(application, "$$$appTestOriginalDataSource")).toBeFalse();
				expect(StructKeyExists(application, "$$$appTestRunDeadline")).toBeFalse();

				expect(application.wheels.dataSourceName).toBe(state.primary);
				expect(StructKeyExists(application.wheels, "coreTestDataSourceName")).toBe(state.hadCore);
				if (state.hadCore) {
					expect(application.wheels.coreTestDataSourceName).toBe(state.core);
				}
				expect(StructKeyExists(request.wheels, "$testRunPreSwap")).toBeFalse();
				expect(StructKeyExists(request.wheels, "$testDataSourceDecision")).toBeFalse();
				expect(StructKeyExists(request.wheels, "$testRunnerOuter")).toBeFalse();
			});

			it("leaves the datasource alone for a run on the primary datasource", () => {
				var state = {primary = application.wheels.dataSourceName, during = ""};
				var decision = {action = "primary", primary = state.primary, candidate = state.primary & "_test", target = state.primary, warn = false};
				var saved = g.$beginTestRunDataSource(decision = decision);
				try {
					state.during = application.wheels.dataSourceName;
				} finally {
					g.$endTestRunDataSource(saved = saved);
				}
				expect(state.during).toBe(state.primary);
				expect(application.wheels.dataSourceName).toBe(state.primary);
			});

		});

		describe("$recoverStrandedTestRun()", () => {

			it("restores the settings a run left switched once its deadline has passed", () => {
				var state = {
					primary = application.wheels.dataSourceName,
					hadCore = StructKeyExists(application.wheels, "coreTestDataSourceName"),
					core = StructKeyExists(application.wheels, "coreTestDataSourceName") ? application.wheels.coreTestDataSourceName : "",
					restored = false,
					after = {}
				};
				try {
					g.$markTestRunSwap(original = state.primary);
					application.$$$appTestRunDeadline = DateAdd("n", -1, Now());
					application.wheels.dataSourceName = state.primary & "_stranded";
					application.wheels.coreTestDataSourceName = state.primary & "_stranded";
					state.restored = g.$recoverStrandedTestRun(force = false);
					state.after.dataSourceName = application.wheels.dataSourceName;
					state.after.core = StructKeyExists(application.wheels, "coreTestDataSourceName") ? application.wheels.coreTestDataSourceName : "";
					state.after.marker = StructKeyExists(application, "$$$appTestOriginalDataSource");
				} finally {
					application.wheels.dataSourceName = state.primary;
					if (state.hadCore) {
						application.wheels.coreTestDataSourceName = state.core;
					} else {
						StructDelete(application.wheels, "coreTestDataSourceName");
					}
					g.$clearTestRunSwapMarkers();
				}
				expect(state.restored).toBeTrue();
				expect(state.after.dataSourceName).toBe(state.primary);
				expect(state.after.core).toBe(state.hadCore ? state.core : "");
				expect(state.after.marker).toBeFalse();
			});

			it("leaves a run that may still be in progress alone until its deadline, unless forced", () => {
				var state = {primary = application.wheels.dataSourceName, early = true, earlyDs = "", forced = false, forcedDs = ""};
				try {
					g.$markTestRunSwap(original = state.primary);
					application.wheels.dataSourceName = state.primary & "_stranded";
					state.early = g.$recoverStrandedTestRun(force = false);
					state.earlyDs = application.wheels.dataSourceName;
					state.forced = g.$recoverStrandedTestRun(force = true);
					state.forcedDs = application.wheels.dataSourceName;
				} finally {
					application.wheels.dataSourceName = state.primary;
					g.$clearTestRunSwapMarkers();
				}
				expect(state.early).toBeFalse();
				expect(state.earlyDs).toBe(state.primary & "_stranded");
				expect(state.forced).toBeTrue();
				expect(state.forcedDs).toBe(state.primary);
			});

			it("is held off while the run keeps building spec bundles", () => {
				var state = {primary = application.wheels.dataSourceName, extended = false, recovered = true, ds = ""};
				try {
					g.$markTestRunSwap(original = state.primary);
					application.$$$appTestRunDeadline = DateAdd("n", -1, Now());
					application.wheels.dataSourceName = state.primary & "_running";
					var bundle = new wheels.WheelsTest();
					state.extended = DateCompare(application.$$$appTestRunDeadline, Now()) > 0;
					state.recovered = g.$recoverStrandedTestRun(force = false);
					state.ds = application.wheels.dataSourceName;
				} finally {
					application.wheels.dataSourceName = state.primary;
					g.$clearTestRunSwapMarkers();
				}
				expect(state.extended).toBeTrue("building a spec bundle must move the run's deadline forward");
				expect(state.recovered).toBeFalse("recovery must not fire while the run keeps building bundles");
				expect(state.ds).toBe(state.primary & "_running");
			});

			it("does nothing when no run left markers", () => {
				expect(g.$recoverStrandedTestRun(force = true)).toBeFalse();
			});

			it("runs at the start of every request and of every test run", () => {
				expect(FindNoCase("application.wo.$recoverStrandedTestRun(force = false)", FileRead(ExpandPath("/wheels/events/EventMethods.cfc")))).toBeGT(0);
				expect(FindNoCase("application.wo.$recoverStrandedTestRun(force = true)", FileRead(ExpandPath("/wheels/tests/app-runner.cfm")))).toBeGT(0);
				expect(FindNoCase("application.wo.$recoverStrandedTestRun(force = true)", FileRead(ExpandPath("/wheels/Public.cfc")))).toBeGT(0);
			});

		});

		describe("WheelsTest datasource backstop", () => {

			afterEach(() => {
				StructDelete(request.wheels, "$testDataSourceDecision");
			});

			it("refuses to build a spec bundle when a test-datasource run has the primary datasource active", () => {
				request.wheels.$testDataSourceDecision = {
					action = "swap",
					primary = application.wheels.dataSourceName,
					candidate = application.wheels.dataSourceName & "_test",
					target = application.wheels.dataSourceName & "_test",
					warn = false
				};
				var build = function() {
					return new wheels.WheelsTest();
				};
				expect(build).toThrow(type = "Wheels.TestDatabaseNotAvailable");
			});

			it("builds spec bundles normally for a run on the primary datasource", () => {
				request.wheels.$testDataSourceDecision = {
					action = "primary",
					primary = application.wheels.dataSourceName,
					candidate = application.wheels.dataSourceName & "_test",
					target = application.wheels.dataSourceName,
					warn = false
				};
				var build = function() {
					return new wheels.WheelsTest();
				};
				expect(build).notToThrow();
			});

		});

		describe("project runner wiring", () => {

			it("Public.cfc runs a project tests/runner.cfm through the datasource guard", () => {
				var source = FileRead(ExpandPath("/wheels/Public.cfc"));
				expect(FindNoCase("$runProjectTestRunner()", source)).toBeGT(0);
				expect(FindNoCase("$testDataSourceDecision(", source)).toBeGT(0);
				expect(FindNoCase("$endTestRunDataSource(", source)).toBeGT(0);
			});

			it("app-runner.cfm leaves the lock and the swap to an outer project runner", () => {
				var source = FileRead(ExpandPath("/wheels/tests/app-runner.cfm"));
				expect(FindNoCase("local.runnerOwnsSwap = !local.outerRunner", source)).toBeGT(0);
				expect(FindNoCase("local.swappedDataSource = !StructIsEmpty(local.preSwap)", source)).toBeGT(0);
			});

		});

	}

}
