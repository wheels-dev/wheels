/**
 * Route-tester hardening (issue #2961, section D — held behind PR #2909):
 *
 * SEC-8: the verb-mismatch error message interpolated raw `arguments.path`
 * while the sibling 404 branch already wrapped it in EncodeForHTML — a
 * reflected-XSS sink rendered by routetester.cfm / routetesterprocess.cfm.
 *
 * P14: the alternative-verbs scan (a second full pass over the route table,
 * including lazy `.regex` writes onto application-scope route structs) ran
 * unconditionally on every invocation; it is only consumed when nothing
 * matched, so it now lives inside the no-match branch, matching
 * Dispatch.cfc's structure.
 */
component extends="wheels.WheelsTest" {

	function beforeAll() {
		variables.publicCfc = CreateObject("component", "wheels.Public").$init();
		variables.helperSource = FileRead(ExpandPath("/wheels/public/helpers.cfm"));
	}

	function run() {

		describe("Route tester hardening (##2961 D)", () => {

			it("HTML-encodes the path in the verb-mismatch message", () => {
				// Hermetic route table: the app's (and earlier specs') routes
				// include catch-alls that would genuinely MATCH the payload
				// path and bypass the error branch entirely. Swap in a single
				// POST-only route whose [id] variable swallows the payload
				// (default constraint excludes only dots and slashes), then
				// restore the real table in finally.
				local.originalRoutes = application.wheels.routes;
				application.wheels.routes = [
					{
						pattern = "/xsstest/[id]",
						methods = "POST",
						controller = "xsstest",
						action = "create",
						name = "xsstestCreate"
					}
				];

				try {
					local.payload = "xsstest/<img src=x onerror=alert(1)>";
					local.result = variables.publicCfc.$$findMatchingRoutes(
						path = local.payload,
						requestMethod = "GET"
					);

					expect(ArrayLen(local.result.errors)).toBeGT(0);
					// The verb-mismatch branch (not the 404 branch) must be hit.
					expect(local.result.errors[1].message).toInclude("Incorrect HTTP Verb");
					local.message = local.result.errors[1].extendedInfo;
					expect(local.message).notToInclude("<img",
						"The raw path must never reach the route-tester output buffer.");
					expect(local.message).toInclude("&lt;img");
				} finally {
					application.wheels.routes = local.originalRoutes;
				}
			});

			it("runs the alternative-verbs scan only in the no-match branch", () => {
				// Structure pin: the scan must start AFTER the no-match guard.
				local.fnStart = Find("$$findMatchingRoutes", variables.helperSource);
				expect(local.fnStart).toBeGT(0);
				local.body = Mid(variables.helperSource, local.fnStart, 4000);

				local.guardPos = Find("!ArrayLen(local.matches)", local.body);
				local.scanPos = Find("alternativeMatchingMethodsForURL", local.body);
				expect(local.guardPos).toBeGT(0);
				expect(local.scanPos).toBeGT(
					local.guardPos,
					"The alternative-verbs scan (and its lazy .regex writes onto application-scope routes) must only run when no route matched."
				);
			});

		});

	}

}
