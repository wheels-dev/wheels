component extends="wheels.WheelsTest" {

	// Regression guard for issue ##3173.
	//
	// The ForgeBox `wheels-base-template` ships the static files under
	// tools/build/base/ verbatim — tools/build/scripts/prepare-base.sh only
	// substitutes @build.version@ / @build.number@, nothing else. The legacy
	// `|appName|` / `|cfmlEngine|` / `|datasourceName|` / `|reloadPassword|`
	// tokens were only ever resolved by the retired CommandBox `cfwheels-cli`
	// (`wheels create app`) flow, so on the README's documented direct-install
	// path (`box install wheels-base-template` -> `box server start`) they
	// reach the user unresolved and `box server start` aborts with
	// "Invalid slug detected" while resolving the `|cfmlEngine|` engine slug.
	//
	// The shipped files must therefore carry inert working defaults, never
	// pipe-delimited placeholders. Structural source assertion in the spirit
	// of buildArtifactLicenseSpec.cfc / buildInfoSpec.cfc — invoking the
	// CommandBox install path inside a test is not feasible.
	//
	// expandPath("/wheels") resolves to vendor/wheels via the configured
	// Lucee mapping; the repo root is two levels above.

	function run() {

		describe("Base template (tools/build/base) ships working defaults, not placeholders (issue ##3173)", () => {

			var repoRoot = expandPath("/wheels/../..");

			// Pipe-delimited legacy CLI tokens, e.g. |appName|, |cfmlEngine|.
			var placeholderRegex = "\|[A-Za-z][A-Za-z0-9_]*\|";

			var baseFiles = [
				"tools/build/base/server.json",
				"tools/build/base/config/app.cfm",
				"tools/build/base/config/settings.cfm"
			];

			for (var rel in baseFiles) {
				// Capture the loop variable so each closure binds the current
				// value, not the final iteration's value.
				(function(relPath) {
					it("ships " & relPath & " without unsubstituted |placeholder| tokens", () => {
						var content = fileRead(repoRoot & "/" & relPath);
						var matches = reMatch(placeholderRegex, content);
						expect(arrayLen(matches)).toBe(
							0,
							relPath & " still contains legacy |placeholder| token(s): "
							& arrayToList(matches, ", ")
							& ". These are never substituted on the `box install wheels-base-template` "
							& "path and break `box server start`. Ship inert working defaults instead. See issue ##3173."
						);
					});
				})(rel);
			}

			it("pins server.json cfengine to a concrete engine slug", () => {
				var server = deserializeJSON(fileRead(repoRoot & "/tools/build/base/server.json"));
				expect(server.app.cfengine).notToInclude("|");
				expect(len(server.app.cfengine)).toBeGT(0);
			});

			it("box.json postInstall does not reference the non-shipped env.example", () => {
				var box = deserializeJSON(fileRead(repoRoot & "/tools/build/base/box.json"));
				var postInstall = box.keyExists("scripts") && box.scripts.keyExists("postInstall")
					? box.scripts.postInstall
					: "";
				expect(postInstall).notToInclude("env.example");
			});

		});

	}

}
