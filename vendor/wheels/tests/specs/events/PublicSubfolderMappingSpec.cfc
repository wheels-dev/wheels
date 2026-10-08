/**
 * A .cfm in a subfolder of public/ runs (4470). public/Application.cfc used to build its
 * mappings with expandPath("../vendor/") and friends, which resolve against the requested
 * template's directory: for /sub/page.cfm that is public/vendor/, so /wheels pointed at a
 * folder that doesn't exist and the request failed with "can't find component
 * [wheels.events.EventMethods]". The spec writes a throwaway page under public/files/,
 * requests it over HTTP, and removes it.
 */
component extends="wheels.WheelsTest" {

	function beforeAll() {
		// Under public/files/: a folder the rewrite rules serve directly (other paths go to
		// index.cfm) and that has no Application.cfc of its own, so public/Application.cfc
		// handles the request.
		variables.probeName = "_wheels_subdir_probe_" & LCase(Left(Hash(CreateUUID()), 8));
		variables.probeDir = ExpandPath("/files/") & variables.probeName & "/";
		DirectoryCreate(variables.probeDir);
		FileWrite(
			variables.probeDir & "probe.cfm",
			'<cfcontent type="text/plain" reset="true"><cfoutput>ok|##GetApplicationSettings().mappings["/wheels"]##</cfoutput>'
		);
		variables.probePath = "/files/" & variables.probeName & "/probe.cfm";
	}

	function afterAll() {
		if (DirectoryExists(variables.probeDir)) {
			DirectoryDelete(variables.probeDir, true);
		}
	}

	function run() {

		describe("a .cfm in a subfolder of public/ (4470)", () => {

			it("runs, with /wheels mapped to the project's vendor/wheels, in the live application", () => {
				var tc = new wheels.wheelstest.TestClient(baseUrl = $getTestBaseUrl(), testContext = false);
				tc.get(variables.probePath).assertOk();
				expect(ListFirst(tc.content(), "|")).toBe("ok");
				var mapped = Replace(ListRest(tc.content(), "|"), "\", "/", "all");
				expect(mapped).toInclude("/vendor/wheels");
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
