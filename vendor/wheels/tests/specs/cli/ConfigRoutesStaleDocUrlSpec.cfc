/**
 * Regression: scaffolded config/routes.cfm shipped a `// See https://...` doc
 * URL pointing at `https://guides.wheels.dev/docs/routing` — a path that
 * doesn't exist on the current docs site. The lucli scaffolder's active
 * `config/routes.cfm` template was already updated to the canonical
 * `/v4-0-0-snapshot/handling-requests-with-controllers/routing` URL, but two
 * sibling templates that produce the same comment for older code paths still
 * had the broken link:
 *
 *   - cli/src/templates/ConfigRoutes.txt
 *   - cli/lucli/templates/app/app/snippets/ConfigRoutes.txt
 *
 * Both are user-facing on freshly scaffolded apps. Issue ##2635.
 *
 * Also guards against any reintroduction of `cfwheels.org`, `cfwheels.com`,
 * or `docs.cfwheels.org` URLs in these template files, since those domains
 * were retired at the 3.0 rebrand and only `wheels.dev` / `guides.wheels.dev`
 * remain canonical.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("Scaffolded routes.cfm doc URL", () => {

			// expandPath("/wheels") resolves to vendor/wheels via the
			// configured Lucee mapping; the repo root is two levels above.
			var repoRoot = expandPath("/wheels/../..");
			var targets = [
				"cli/src/templates/ConfigRoutes.txt",
				"cli/lucli/templates/app/app/snippets/ConfigRoutes.txt",
				"cli/lucli/templates/app/config/routes.cfm"
			];
			var canonical = "https://guides.wheels.dev/v4-0-0-snapshot/handling-requests-with-controllers/routing";

			for (var rel in targets) {
				// Capture the loop variable so the closure body binds the
				// current value, not the final iteration's value.
				(function(relPath) {
					it("points to the canonical guides.wheels.dev path in " & relPath, () => {
						var absolute = repoRoot & "/" & relPath;
						expect(fileExists(absolute)).toBeTrue("Missing file: " & absolute);

						var content = fileRead(absolute);

						expect(content contains canonical).toBeTrue(
							relPath & " should reference " & canonical
							& " — the same URL used by cli/lucli/templates/app/config/routes.cfm."
						);

						expect(content contains "guides.wheels.dev/docs/routing").toBeFalse(
							relPath & " still references the stale /docs/routing path on guides.wheels.dev."
						);

						expect(content contains "docs.cfwheels.org").toBeFalse(
							relPath & " still references the retired docs.cfwheels.org host."
						);

						expect(reFindNoCase("cfwheels\.(org|com)", content) > 0).toBeFalse(
							relPath & " still references a retired cfwheels.org / cfwheels.com URL."
						);
					});
				})(rel);
			}

		});

	}

}
