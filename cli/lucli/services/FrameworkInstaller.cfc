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
	 * vendor/wheels/box.json so the scaffolded app's homepage reports a
	 * meaningful version instead of "0.0.0-dev".
	 *
	 * Released framework tarballs have the placeholder replaced at build time
	 * by tools/build/scripts, so their box.json already carries a real version.
	 * A dev checkout doesn't — the placeholder is literal. Some release-install
	 * paths (e.g. the homebrew formula) also ship the framework with the
	 * placeholder unsubstituted; those need a fallback too.
	 *
	 * Resolution order, highest priority first:
	 *
	 * 1. **Monorepo dev checkout** — when the source's enclosing root box.json
	 *    identifies the monorepo (slug="wheels" or name="Wheels.fw"), use
	 *    "<rootversion>-dev". (GH ##2279.)
	 * 2. **CLI version fallback** — when no monorepo is identifiable but the
	 *    caller passed `cliVersion`, use that. The brew/chocolatey formulas
	 *    bundle the LuCLI module and the framework together at the same
	 *    version, so the LuCLI's known version is the right answer for the
	 *    framework too. (GH ##2333.)
	 * 3. **Leave alone** — without either signal, the placeholder stays and
	 *    `$readFrameworkVersion()`'s runtime fallback returns "0.0.0-dev".
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
		var targetBox = arguments.vendorDir & "/box.json";
		if (!fileExists(targetBox)) return false;

		var content = fileRead(targetBox);
		if (!findNoCase("@build.version@", content)) return false;

		// 1. Try monorepo dev checkout: the source is a vendor/wheels/ directory;
		//    the monorepo root lives two levels up.
		var File = createObject("java", "java.io.File");
		var sourceCanonical = File.init(arguments.wheelsSource).getCanonicalPath();
		var rootCandidate = File.init(sourceCanonical & "/../../box.json").getCanonicalPath();

		if (fileExists(rootCandidate)) {
			try {
				var rootBox = deserializeJSON(fileRead(rootCandidate));
				var isMonorepo = isStruct(rootBox)
					&& (
						(structKeyExists(rootBox, "slug") && rootBox.slug == "wheels")
						|| (structKeyExists(rootBox, "name") && rootBox.name == "Wheels.fw")
					);
				if (
					isMonorepo
					&& structKeyExists(rootBox, "version")
					&& len(rootBox.version)
					&& rootBox.version != "@build.version@"
				) {
					var devVersion = rootBox.version & "-dev";
					fileWrite(targetBox, replace(content, "@build.version@", devVersion, "all"));
					return true;
				}
			} catch (any e) {
				// fall through to the CLI-version fallback
			}
		}

		// 2. Fall back to the CLI's own version. brew/chocolatey ship LuCLI +
		//    framework at the same version, so this is the right answer for
		//    release-install paths where the framework's box.json placeholder
		//    wasn't substituted at packaging time.
		var trimmedCli = trim(arguments.cliVersion);
		if (
			len(trimmedCli)
			&& trimmedCli != "Version not specified"
			&& trimmedCli != "@build.version@"
		) {
			fileWrite(targetBox, replace(content, "@build.version@", trimmedCli, "all"));
			return true;
		}

		// 3. No usable signal — leave the placeholder so the framework's
		//    runtime fallback path still produces "0.0.0-dev".
		return false;
	}

}
