/**
 * Regression: scaffolded files shipped `See https://...` doc URLs pointing at
 * guide paths that no longer exist on the docs site.
 *
 * Round 1 (issue ##2635): config/routes.cfm templates pointed at the retired
 * `guides.wheels.dev/docs/routing` path.
 *
 * Round 2 (2026-07): the pre-GA `v4-0-0-snapshot` slug was retired when the
 * 4.0 docs consolidated onto `v4-0-0`, which killed every templated URL still
 * carrying it — including the `working-with-wheels/*` paths that only ever
 * existed in the v3 tree. The scaffolded settings.cfm/routes.cfm/environment.cfm,
 * three template READMEs, two runtime CLI messages (Module.cfc, Doctor.cfc),
 * and the demo app's config all linked 404s. All were repointed at live
 * `guides.wheels.dev/v4-0-0/...` pages.
 *
 * This spec pins the canonical routing URL in the routes templates AND scans
 * the scaffold template tree plus the known runtime-message files for any
 * reintroduction of retired URL shapes: `v4-0-0-snapshot`, `wheels.dev/3.1.0`,
 * and the rebrand-retired cfwheels.org / cfwheels.com / docs.cfwheels.org hosts.
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
			var canonical = "https://guides.wheels.dev/v4-0-0/basics/routing/";

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
							& " — the live v4 routing guide."
						);

						expect(content contains "guides.wheels.dev/docs/routing").toBeFalse(
							relPath & " still references the stale /docs/routing path on guides.wheels.dev."
						);
					});
				})(rel);
			}

		});

		describe("Retired guide URL shapes", () => {

			var repoRoot = expandPath("/wheels/../..");

			// Files outside the template tree that print or ship guide URLs.
			var extraFiles = [
				"cli/README.md",
				"cli/lucli/Module.cfc",
				"cli/lucli/services/Doctor.cfc",
				"cli/src/templates/ConfigRoutes.txt",
				"cli/src/commands/wheels/analyze/code.cfc",
				"config/settings.cfm",
				"config/environment.cfm"
			];

			it("no retired guide URLs under cli/lucli/templates/ or the known runtime-message files", () => {
				var scanned = [];
				var templateRoot = repoRoot & "/cli/lucli/templates";
				var templateFiles = directoryList(templateRoot, true, "path");
				for (var path in templateFiles) {
					if (reFindNoCase("\.(cfm|cfc|txt|md|json)$", path)) {
						arrayAppend(scanned, path);
					}
				}
				for (var rel in extraFiles) {
					arrayAppend(scanned, repoRoot & "/" & rel);
				}

				var offenders = [];
				for (var path in scanned) {
					if (!fileExists(path)) {
						continue;
					}
					var content = fileRead(path);
					if (
						findNoCase("v4-0-0-snapshot", content)
						|| findNoCase("wheels.dev/3.1.0", content)
						|| findNoCase("docs.cfwheels.org", content)
						|| reFindNoCase("cfwheels\.(org|com)", content)
					) {
						arrayAppend(offenders, path);
					}
				}

				expect(arrayLen(offenders) == 0).toBeTrue(
					"Retired guide URL shape (v4-0-0-snapshot, wheels.dev/3.1.0, or a cfwheels.org-era host) found in: "
					& arrayToList(offenders, "; ")
					& ". Point these at live guides.wheels.dev/v4-0-0/ pages instead."
				);
			});

		});

	}

}
