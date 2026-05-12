/**
 * Framework-installation helpers for `wheels new`.
 *
 * Isolated from Module.cfc so tests can exercise the behavior without
 * instantiating the full LuCLI module (which depends on a `modules.BaseModule`
 * mapping that only exists when LuCLI is hosting the runtime).
 */
component {

	public function init() {
		return this;
	}

	/**
	 * Substitute the @build.version@ placeholder in a freshly-copied
	 * vendor/wheels/wheels.json so the scaffolded app's homepage reports a
	 * meaningful version instead of "0.0.0-dev".
	 *
	 * Released framework tarballs have the placeholder replaced at build time
	 * by tools/build/scripts, so their wheels.json already carries a real version.
	 * A dev checkout doesn't — the placeholder is literal. Some release-install
	 * paths (e.g. the homebrew formula) also ship the framework with the
	 * placeholder unsubstituted; those need a fallback too.
	 *
	 * Resolution order, highest priority first:
	 *
	 * 1. **Monorepo dev checkout** — when the source's enclosing root manifest
	 *    identifies the monorepo (name="Wheels.fw"), use "<rootversion>-dev".
	 * 2. **CLI version fallback** — when no monorepo is identifiable but the
	 *    caller passed `cliVersion`, use that. The brew/scoop formulas bundle
	 *    the LuCLI module and the framework together at the same version, so
	 *    the LuCLI's known version is the right answer for the framework too.
	 * 3. **Leave alone** — without either signal, the placeholder stays and
	 *    `$readFrameworkVersion()`'s runtime fallback returns "0.0.0-dev".
	 *
	 * Manifest filename transition: this function reads `wheels.json` if present,
	 * falling back to `box.json` so brew bottles built before the rename
	 * (and projects scaffolded against pre-rename framework checkouts) still
	 * work correctly. The fallback can be removed two releases after the
	 * rename ships in stable.
	 *
	 * @wheelsSource Absolute path of the source vendor/wheels/ directory.
	 * @vendorDir    Absolute path of the newly-written vendor/wheels/ directory
	 *               inside the scaffolded app.
	 * @cliVersion   Optional. The LuCLI module's own version, used as a fallback
	 *               when the source isn't a monorepo checkout. Skipped if empty
	 *               or equal to LuCLI's "Version not specified" sentinel.
	 * @return       True if the placeholder was rewritten, false otherwise.
	 */
	public boolean function rewriteVersionPlaceholder(
		required string wheelsSource,
		required string vendorDir,
		string cliVersion = ""
	) {
		var targetManifest = $resolveManifest(arguments.vendorDir);
		if (!len(targetManifest)) return false;

		var content = fileRead(targetManifest);
		if (!findNoCase("@build.version@", content)) return false;

		// 1. Try monorepo dev checkout: the source is a vendor/wheels/ directory;
		//    the monorepo root lives two levels up.
		var File = createObject("java", "java.io.File");
		var sourceCanonical = File.init(arguments.wheelsSource).getCanonicalPath();
		var rootDir = File.init(sourceCanonical & "/../..").getCanonicalPath();
		var rootCandidate = $resolveManifest(rootDir);

		if (len(rootCandidate)) {
			try {
				var rootManifest = deserializeJSON(fileRead(rootCandidate));
				// Accept either the new wheels.json schema (name only) or the
				// legacy box.json schema (which also had a `slug` field).
				var isMonorepo = isStruct(rootManifest)
					&& (
						(structKeyExists(rootManifest, "name") && rootManifest.name == "Wheels.fw")
						|| (structKeyExists(rootManifest, "slug") && rootManifest.slug == "wheels")
					);
				if (
					isMonorepo
					&& structKeyExists(rootManifest, "version")
					&& len(rootManifest.version)
					&& rootManifest.version != "@build.version@"
				) {
					var devVersion = rootManifest.version & "-dev";
					fileWrite(targetManifest, replace(content, "@build.version@", devVersion, "all"));
					return true;
				}
			} catch (any e) {
				// fall through to the CLI-version fallback
			}
		}

		// 2. Fall back to the CLI's own version. brew/scoop ship LuCLI +
		//    framework at the same version, so this is the right answer for
		//    release-install paths where the framework's manifest placeholder
		//    wasn't substituted at packaging time.
		var trimmedCli = trim(arguments.cliVersion);
		if (
			len(trimmedCli)
			&& trimmedCli != "Version not specified"
			&& trimmedCli != "@build.version@"
		) {
			fileWrite(targetManifest, replace(content, "@build.version@", trimmedCli, "all"));
			return true;
		}

		// 3. No usable signal — leave the placeholder so the framework's
		//    runtime fallback path still produces "0.0.0-dev".
		return false;
	}

	/**
	 * Resolve a directory's manifest file path, preferring the new wheels.json
	 * over the legacy box.json. Returns the full path of whichever exists, or
	 * an empty string if neither is present.
	 *
	 * The fallback supports the rename transition: brew bottles produced before
	 * the rename ship `box.json`, and pre-rename apps' `vendor/wheels/` was
	 * committed to source with `box.json`. Both must keep working under the
	 * post-rename CLI.
	 */
	private string function $resolveManifest(required string dir) {
		var newPath = arguments.dir & "/wheels.json";
		if (fileExists(newPath)) return newPath;
		var legacyPath = arguments.dir & "/box.json";
		if (fileExists(legacyPath)) return legacyPath;
		return "";
	}

}
