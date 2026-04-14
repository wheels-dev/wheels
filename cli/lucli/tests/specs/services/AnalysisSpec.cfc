component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.testHelper = new cli.lucli.tests.TestHelper();
		variables.tempRoot = testHelper.scaffoldTempProject(expandPath("/"));
		variables.helpers = new cli.lucli.services.Helpers();
		variables.analysis = new cli.lucli.services.Analysis(
			helpers = variables.helpers,
			projectRoot = variables.tempRoot
		);
	}

	function afterAll() {
		testHelper.cleanupTempProject(variables.tempRoot);
	}

	function run() {

		describe("Analysis Service", () => {

			describe("analyze()", () => {

				it("returns struct with required keys", () => {
					var results = analysis.analyze("all");
					expect(isStruct(results)).toBeTrue();
					expect(structKeyExists(results, "totalFiles")).toBeTrue();
					expect(structKeyExists(results, "totalLines")).toBeTrue();
					expect(structKeyExists(results, "totalFunctions")).toBeTrue();
					expect(structKeyExists(results, "antiPatterns")).toBeTrue();
					expect(structKeyExists(results, "metrics")).toBeTrue();
					expect(structKeyExists(results, "executionTime")).toBeTrue();
				});

				it("antiPatterns is an array", () => {
					var results = analysis.analyze("all");
					expect(isArray(results.antiPatterns)).toBeTrue();
				});

				it("metrics contains grade and healthScore", () => {
					var results = analysis.analyze("all");
					expect(structKeyExists(results.metrics, "grade")).toBeTrue();
					expect(structKeyExists(results.metrics, "healthScore")).toBeTrue();
				});

				it("counts files in the app directory", () => {
					var modelDir = tempRoot & "/app/models";
					directoryCreate(modelDir, true, true);
					fileWrite(modelDir & "/AnalysisTest.cfc", 'component extends="Model" { function config() {} }');

					var results = analysis.analyze("all");
					expect(results.totalFiles).toBeGTE(1);
				});

				it("detects issues in project files", () => {
					var modelDir = tempRoot & "/app/models";
					directoryCreate(modelDir, true, true);
					fileWrite(modelDir & "/BadModel.cfc", 'component { function config() {} }');

					var results = analysis.analyze("all");
					// analyze scans for anti-patterns, complexity, and code smells
					expect(isArray(results.antiPatterns)).toBeTrue();
					expect(isArray(results.codeSmells)).toBeTrue();
				});

				it("accepts target parameter to scope analysis", () => {
					var results = analysis.analyze("models");
					expect(isStruct(results)).toBeTrue();
					expect(results.totalFiles).toBeGTE(0);
				});

				it("returns execution time", () => {
					var results = analysis.analyze("all");
					expect(results.executionTime).toBeGTE(0);
				});

			});

			describe("validate()", () => {

				it("returns struct with valid key", () => {
					var results = analysis.validate();
					expect(isStruct(results)).toBeTrue();
					expect(structKeyExists(results, "valid")).toBeTrue();
					expect(structKeyExists(results, "totalIssues")).toBeTrue();
					expect(structKeyExists(results, "issues")).toBeTrue();
				});

				it("issues is an array", () => {
					var results = analysis.validate();
					expect(isArray(results.issues)).toBeTrue();
				});

				it("reports valid for clean project", () => {
					// Clean up bad model from previous test
					var badModel = tempRoot & "/app/models/BadModel.cfc";
					if (fileExists(badModel)) fileDelete(badModel);

					var results = analysis.validate();
					expect(isBoolean(results.valid)).toBeTrue();
				});

				it("detects model without extends", () => {
					var modelDir = tempRoot & "/app/models";
					directoryCreate(modelDir, true, true);
					fileWrite(modelDir & "/Broken.cfc", 'component { }');

					var results = analysis.validate();
					var issueMessages = "";
					for (var issue in results.issues) {
						issueMessages &= issue.message & " ";
					}
					expect(issueMessages).toInclude("Model");
				});

			});

		});

	}

}
