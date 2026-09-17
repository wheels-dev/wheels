/**
 * Guards the non-HTML formats of the public API docs endpoint.
 *
 * `/wheels/api?format=json&type=core` is a PUBLISHED interface, not just a
 * page. The Wheels Snapshots workflow (`.github/workflows/publish-snapshot.yml`)
 * fetches it with `curl -sf` and then requires BOTH `.functions` and
 * `.sections` in the payload to build the API snapshot the docs site consumes,
 * and `/wheels/ai` derives its condensed summary from the same data.
 *
 * When the browsable page moved to the prebuilt Starlight bundle, `api()`
 * started serving the bundle unconditionally and the JSON route returned 404 —
 * `curl -sf` exited 22 and the Snapshots workflow failed on develop. Nothing in
 * the local suite noticed, because the failure only appeared in CI after merge.
 *
 * This spec pins the contract so it cannot regress silently again. Structural
 * rather than behavioural for the same reason DebugBarCollapseSpec is: it costs
 * no request and no running server to check.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("Public API docs endpoint formats", () => {

			it("keeps the non-HTML formats on the CFML renderer", () => {
				var source = FileRead(ExpandPath("/wheels/Public.cfc"));

				var apiAt = FindNoCase("function api()", source);
				expect(apiAt).toBeGT(0, "Public.cfc must define api()");

				// Look at a window covering the handler body. It is short by
				// design — a format branch, the bundle serve, then the
				// unavailable fallback.
				var body = Mid(source, apiAt, 1000);

				expect(FindNoCase("request.wheels.params.format", body)).toBeGT(
					0,
					"api() must read the requested format — ?format=json is a published interface, "
					& "not a page, and the Snapshots workflow fetches it"
				);
				expect(FindNoCase("public/views/api.cfm", body)).toBeGT(
					0,
					"api() must still include views/api.cfm for the non-HTML formats"
				);
			});

			it("still ships the CFML renderer those formats depend on", () => {
				// /wheels/ai and the JSON snapshot both read this file, so it
				// cannot be deleted while they exist.
				expect(FileExists(ExpandPath("/wheels/public/docs/core.cfm"))).toBeTrue(
					"public/docs/core.cfm backs ?format=json and /wheels/ai — it is not dead code"
				);
			});

		});

	}
}
