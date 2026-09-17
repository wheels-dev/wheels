component extends="wheels.WheelsTest" {

	function run() {
		describe("debug.cfm Complexity panel rendering", () => {
			// The Complexity panel is cfinclude'd from inside debug.cfm's
			// cfsavecontent/cfoutput block. At least one supported engine does
			// not inherit the cfoutput context across the include boundary, so the
			// panel's expressions leaked literally into the HTML instead of
			// evaluating (issue #3548). This spec renders debug.cfm with a
			// pre-seeded codeComplexity payload and asserts the panel shows real
			// numbers/paths rather than raw CFML identifiers.
			it("renders evaluated summary and per-file values, never raw CFML identifiers", () => {
				var priorReqWheels = StructKeyExists(request, "wheels") ? Duplicate(request.wheels) : {};
				var hadCodeComplexity = StructKeyExists(application.wheels, "codeComplexity");
				var priorCodeComplexity = hadCodeComplexity ? application.wheels.codeComplexity : {};

				try {
					if (!StructKeyExists(request, "wheels")) {
						request.wheels = {};
					}
					request.wheels.execution = {total = 0};
					request.wheels.params = {controller = "wheels", action = "tests", route = ""};

					// Pre-seed the cached CodeComplexity payload so the panel renders
					// deterministic values without scanning app/ during the spec.
					application.wheels.codeComplexity = {
						summary = {files = 12, functions = 34, maxComplexity = 56, avgComplexity = 7},
						files = [
							{file = "app/models/Post.cfc", functions = 5, complexity = 42, avg = 8.4}
						]
					};

					// debug.cfm bails out (cfexit) when url.format is one of
					// json/xml/csv/pdf so it never breaks an API response. The
					// test runner is hit with format=json — clear it for the
					// duration of the include so the template renders.
					var hadUrlFormat = StructKeyExists(url, "format");
					var priorUrlFormat = hadUrlFormat ? url.format : "";
					if (hadUrlFormat) {
						StructDelete(url, "format");
					}

					var output = "";
					try {
						output = application.wo.$includeAndReturnOutput($template = "/wheels/events/onrequestend/debug.cfm");
					} finally {
						if (hadUrlFormat) {
							url.format = priorUrlFormat;
						}
					}

					expect(output contains "12 files").toBeTrue(
						"the Complexity panel must show the evaluated summary.files count"
					);
					expect(output contains "34 functions").toBeTrue(
						"the Complexity panel must show the evaluated summary.functions count"
					);
					expect(output contains "max <strong>56</strong>").toBeTrue(
						"the Complexity panel must show the evaluated summary.maxComplexity value"
					);
					expect(output contains "avg <strong>7</strong>").toBeTrue(
						"the Complexity panel must show the evaluated summary.avgComplexity value"
					);
					expect(output contains "app/models/Post.cfc").toBeTrue(
						"the Complexity panel must show evaluated per-file paths"
					);
					expect(output contains ">42</td>").toBeTrue(
						"the Complexity panel must show evaluated per-file complexity values"
					);
					expect(output contains ">8.4</td>").toBeTrue(
						"the Complexity panel must show evaluated per-file avg values"
					);
					expect(output contains "local.codeComplexity.summary").toBeFalse(
						"raw CFML identifiers must not leak into the Complexity panel summary"
					);
					expect(output contains "##local.cf.complexity##").toBeFalse(
						"raw CFML identifiers must not leak into the Complexity panel per-file rows"
					);
				} finally {
					request.wheels = priorReqWheels;
					if (hadCodeComplexity) {
						application.wheels.codeComplexity = priorCodeComplexity;
					} else {
						StructDelete(application.wheels, "codeComplexity");
					}
				}
			});
		});
	}

}
