component extends="wheels.WheelsTest" {

	/**
	 * Covers the legacy RocketUnit runner's error handling (wheels.Test /
	 * $runTest): a throwing test must be recorded as a test error, never crash
	 * the whole suite (#3458). On Lucee 7 the pre-fix inline message assembly
	 * inside the catch could throw "variable [MESSAGE] doesn't exist" for some
	 * exception shapes, masking the original error with a suite-wide 500.
	 */
	function run() {

		describe("RocketUnit runner error handling", function() {

			beforeEach(function() {
				g = application.wo;
				_resultKey = "wheelsRocketUnitRunnerSpec";
			});

			afterEach(function() {
				if (StructKeyExists(request, _resultKey)) {
					StructDelete(request, _resultKey);
				}
			});

			it("composes an error message from a cfcatch without throwing", function() {
				var caught = "";
				try {
					Throw(type = "Wheels.ProbeBoom", message = "deliberate boom");
				} catch (any e) {
					caught = e;
				}
				var runner = new wheels.Test();
				var msg = "";
				expect(function() {
					msg = runner.$testErrorMessage(caught);
				}).notToThrow();
				expect(msg).toInclude("deliberate boom");
			});

			it("records a throwing test as an error instead of crashing the suite", function() {
				// RustCFML's and BoxLang's legacy-runner surface (Invoke()/
				// evaluate) has known gaps; the handler itself is covered by the
				// spec above on every engine.
				if (g.$engineAdapter().isRustCFML() || g.$engineAdapter().isBoxLang()) return;
				var testCase = new wheels.tests._assets.global.RocketUnitThrowingTest();
				expect(function() {
					testCase.$runTest(_resultKey);
				}).notToThrow();
				var results = request[_resultKey];
				expect(results.numTests).toBe(2);
				expect(results.numSuccesses).toBe(1);
				expect(results.numErrors).toBe(1);
				expect(results.ok).toBeFalse();
				var messages = "";
				for (var r in results.results) {
					messages = messages & r.message;
				}
				expect(messages).toInclude("deliberate boom");
			});

		});

	}

}
