/**
 * A .cfm in a subfolder of public/ runs (4470). public/Application.cfc used to build its
 * mappings with expandPath("../vendor/") and friends, which resolve against the requested
 * template's directory: for /sub/page.cfm that is public/vendor/, so /wheels pointed at a
 * folder that doesn't exist and the request failed with "can't find component
 * [wheels.events.EventMethods]". The spec writes a throwaway page in public/files/,
 * requests it over HTTP, and removes it.
 */
component extends="wheels.WheelsTest" {

	function beforeAll() {
		// Directly in public/files/: a folder the rewrite rules serve as is (other paths go
		// to index.cfm) with no Application.cfc of its own, so public/Application.cfc handles
		// the request. One level down, as in the issue: Wheels answers 404 for a requested
		// page nested deeper than vendor/wheels/ ($abortInvalidRequest()).
		variables.probeFile = ExpandPath("/files/") & "_wheels_subdir_probe_" & LCase(Left(Hash(CreateUUID()), 8)) & ".cfm";
		FileWrite(
			variables.probeFile,
			// ExpandPath() of a mapped path shows the mapping on every engine (Adobe has no
			// GetApplicationSettings()).
			'<cfcontent type="text/plain" reset="true"><cfoutput>ok|##ExpandPath("/wheels/Global.cfc")##</cfoutput>'
		);
		variables.probePath = "/files/" & GetFileFromPath(variables.probeFile);
	}

	function afterAll() {
		if (FileExists(variables.probeFile)) {
			FileDelete(variables.probeFile);
		}
	}

	function run() {

		describe("a .cfm in a subfolder of public/ (4470)", () => {

			it("runs, with /wheels mapped to the project's vendor/wheels, in the live application", () => {
				var tc = new wheels.wheelstest.TestClient(baseUrl = $getTestBaseUrl(), testContext = false);
				tc.get(variables.probePath).assertOk();
				expect(ListFirst(tc.content(), "|")).toBe("ok");
				var mapped = Replace(ListRest(tc.content(), "|"), "\", "/", "all");
				expect(mapped).toInclude("/vendor/wheels/Global.cfc");
				expect(mapped).notToInclude("/public/vendor");
			});

			it("runs in the test application too", () => {
				var tc = $testClient();
				tc.get(variables.probePath).assertOk();
				expect(ListFirst(tc.content(), "|")).toBe("ok");
			});

		});

	}

}
