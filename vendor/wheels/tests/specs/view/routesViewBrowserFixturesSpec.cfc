component extends="wheels.WheelsTest" {

	// Regression guard for issue ##2577. The Routes UI at
	// vendor/wheels/public/views/routes.cfm splits the route table into
	// "Application" and "Internal" tabs using a single inline predicate.
	// Originally the predicate only matched controller == "wheels.public"
	// or pattern == "/wheels/app/tests", so the `/_browser/*` fixture
	// routes (registered when loadBrowserTestFixtures is enabled) fell
	// through to the App tab even though they ship with the framework
	// and have no corresponding files under /app. The fix is to also
	// classify routes whose pattern begins with "/_browser" as internal.
	//
	// These tests pin the routes.cfm source so the classification can't
	// drift back. They mirror the structural-assertion pattern used by
	// packageListViewTestsLinkSpec.cfc and MigratorViewIconsSpec.cfc.

	function run() {
		describe("routes.cfm internal-route classification", () => {
			it("treats routes with a pattern starting with /_browser as internal (regression for ##2577)", () => {
				var src = fileRead(expandPath("/wheels/public/views/routes.cfm"));
				// The predicate must look at r.pattern and check for the
				// "/_browser" prefix. We accept any of the common shapes
				// (Left, StartsWith, FindNoCase==1) but require the literal
				// string "/_browser" to appear in the categorization block.
				var anchor = findNoCase("internalRoutes", src);
				expect(anchor).toBeGT(0, "routes.cfm must classify routes into an internalRoutes bucket.");

				// Look in the categorization region (the first ~600 chars
				// after the bucket declaration). The /_browser literal must
				// be present in that window so it is part of the predicate.
				var windowLen = Min(800, Len(src) - anchor);
				var classifyBlock = Mid(src, anchor, windowLen);
				expect(classifyBlock).toInclude(
					"/_browser",
					"routes.cfm must classify routes whose pattern begins with /_browser as internal so the browser-testing fixture routes do not appear under the Application tab."
				);
			});

			it("still classifies wheels.public controller routes as internal", () => {
				var src = fileRead(expandPath("/wheels/public/views/routes.cfm"));
				expect(src).toInclude(
					"wheels.public",
					"routes.cfm must continue to classify wheels.public routes as internal."
				);
			});

			it("still classifies /wheels/app/tests as internal", () => {
				var src = fileRead(expandPath("/wheels/public/views/routes.cfm"));
				expect(src).toInclude(
					"/wheels/app/tests",
					"routes.cfm must continue to classify /wheels/app/tests as internal."
				);
			});
		});
	}

}
