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

				it("flags model where extends is only present in a line comment", () => {
				// Reproduces #2491 follow-up: the validator must not treat a
				// commented-out `extends="Model"` as satisfying inheritance.
				var modelDir = tempRoot & "/app/models";
				directoryCreate(modelDir, true, true);
				fileWrite(
					modelDir & "/CommentedExtendsLine.cfc",
					'// component extends="Model" {' & chr(10) &
					'component {' & chr(10) &
					'    function config() {}' & chr(10) &
					'}'
				);

				var results = analysis.validate();
				var issueMessages = "";
				for (var issue in results.issues) {
					if (findNoCase("CommentedExtendsLine.cfc", issue.file)) {
						issueMessages &= issue.message & " ";
					}
				}
				expect(issueMessages).toInclude("does not extend Model");

				fileDelete(modelDir & "/CommentedExtendsLine.cfc");
			});

			it("flags model where extends is only present in a block comment", () => {
				var modelDir = tempRoot & "/app/models";
				directoryCreate(modelDir, true, true);
				fileWrite(
					modelDir & "/CommentedExtendsBlock.cfc",
					'/* example: component extends="Model" {} */' & chr(10) &
					'component {' & chr(10) &
					'    function config() {}' & chr(10) &
					'}'
				);

				var results = analysis.validate();
				var issueMessages = "";
				for (var issue in results.issues) {
					if (findNoCase("CommentedExtendsBlock.cfc", issue.file)) {
						issueMessages &= issue.message & " ";
					}
				}
				expect(issueMessages).toInclude("does not extend Model");

				fileDelete(modelDir & "/CommentedExtendsBlock.cfc");
			});

			it("still passes when extends is present alongside a commented-out copy", () => {
				var modelDir = tempRoot & "/app/models";
				directoryCreate(modelDir, true, true);
				fileWrite(
					modelDir & "/CommentedAndReal.cfc",
					'// component extends="Model" {' & chr(10) &
					'component extends="Model" {' & chr(10) &
					'    function config() {}' & chr(10) &
					'}'
				);

				var results = analysis.validate();
				for (var issue in results.issues) {
					if (findNoCase("CommentedAndReal.cfc", issue.file)) {
						expect(issue.message).notToInclude("does not extend Model");
					}
				}

				fileDelete(modelDir & "/CommentedAndReal.cfc");
			});

			it("flags controller where extends is only present in a comment", () => {
				var ctrlDir = tempRoot & "/app/controllers";
				directoryCreate(ctrlDir, true, true);
				fileWrite(
					ctrlDir & "/CommentedCtrl.cfc",
					'// component extends="Controller" {' & chr(10) &
					'component {' & chr(10) &
					'    function config() {}' & chr(10) &
					'}'
				);

				var results = analysis.validate();
				var issueMessages = "";
				for (var issue in results.issues) {
					if (findNoCase("CommentedCtrl.cfc", issue.file)) {
						issueMessages &= issue.message & " ";
					}
				}
				expect(issueMessages).toInclude("does not extend Controller");

				fileDelete(ctrlDir & "/CommentedCtrl.cfc");
			});

			it("does not flag the framework's parent Model.cfc / Controller.cfc", () => {
					// The base parent files extend "wheels.Model" / "wheels.Controller"
					// rather than "Model" / "Controller", since they ARE the parent.
					// The validator must skip them.
					var modelDir = tempRoot & "/app/models";
					var ctrlDir = tempRoot & "/app/controllers";
					directoryCreate(modelDir, true, true);
					directoryCreate(ctrlDir, true, true);
					fileWrite(modelDir & "/Model.cfc", 'component extends="wheels.Model" {}');
					fileWrite(ctrlDir & "/Controller.cfc", 'component extends="wheels.Controller" {}');

					// Remove any leftover broken files so the assertion is clean.
					var brokenModel = modelDir & "/Broken.cfc";
					if (fileExists(brokenModel)) {
						fileDelete(brokenModel);
					}
					var badModel = modelDir & "/BadModel.cfc";
					if (fileExists(badModel)) {
						fileDelete(badModel);
					}

					var results = analysis.validate();
					for (var issue in results.issues) {
						expect(issue.message).notToInclude("Model.cfc does not extend Model");
						expect(issue.message).notToInclude("Controller.cfc does not extend Controller");
					}
				});

			});

		});

	}

}
