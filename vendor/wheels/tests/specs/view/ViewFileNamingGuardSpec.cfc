/**
 * Structural cross-engine guard for the view-path casing trap.
 *
 * `$generateIncludeTemplatePath()` (vendor/wheels/controller/rendering.cfc)
 * ends with `return LCase(local.rv);` — the whole resolved template path is
 * folded to lowercase before the include. On a case-INsensitive filesystem
 * (macOS dev machines) a camelCase view file still resolves, and Lucee and
 * BoxLang resolve it even on Linux. Adobe ColdFusion on Linux does not: the
 * lookup is literal, so `_groupRow.cfm` is simply not found once the path has
 * been lowercased to `_grouprow.cfm`.
 *
 * That is exactly how `vendor/wheels/tests/_assets/views/test/_groupRow.cfm`
 * (added with contentSpec's grouped-partial case) went unnoticed: green on
 * every local run, green on lucee6/lucee7/boxlang in CI, and 11 failing legs
 * across adobe2023 and adobe2025 — visible only in the compat matrix, which
 * is `continue-on-error: true` and does not run on PRs (#3302).
 *
 * Lowercase view filenames are the framework's de facto convention: at the
 * time this guard was written there was not a single camelCase `.cfm` under
 * `app/views`, `vendor/wheels/public/views`, or the `wheels new` templates.
 * This spec makes that convention enforceable on every engine, including the
 * ones where the mismatch would otherwise resolve silently.
 *
 * Scope note: this guards the framework's OWN view trees. It does not (and
 * cannot) stop an application from shipping a camelCase view — that remains a
 * real limitation of the `LCase()` normalization, and is worth documenting for
 * users rather than silently changing a long-standing path rule.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("Cross-engine guard: view template filenames are lowercase", () => {

			it("no .cfm under the framework view trees has an uppercase filename", () => {
				var roots = ["/wheels/public/views", "/wheels/tests/_assets/views"];
				var offenders = [];

				for (var root in roots) {
					var absolute = ExpandPath(root);
					if (!DirectoryExists(absolute)) {
						continue;
					}
					var files = DirectoryList(absolute, true, "path", "*.cfm");
					for (var filePath in files) {
						var fileName = ListLast(filePath, "/\");
						if (fileName != LCase(fileName)) {
							ArrayAppend(offenders, root & " -> " & fileName);
						}
					}
				}

				expect(ArrayLen(offenders)).toBe(
					0,
					"View templates must be named in lowercase — $generateIncludeTemplatePath() lowercases the "
					& "resolved path, so these files are unreachable on Adobe ColdFusion running on a "
					& "case-sensitive filesystem: " & ArrayToList(offenders, ", ")
				);
			});

		});

	}

}
