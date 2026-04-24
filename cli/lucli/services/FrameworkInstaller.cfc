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
	 * vendor/wheels/box.json when the source is identifiable as a dev checkout
	 * of the wheels-dev/wheels monorepo (GH ##2279).
	 *
	 * Released framework tarballs have the placeholder replaced at build time
	 * by tools/build/scripts, so their box.json already carries a real version.
	 * A dev checkout does not — the placeholder is literal. Copying that file
	 * verbatim into a scaffolded app makes the homepage display "0.0.0-dev"
	 * because $readFrameworkVersion()'s fallback can only identify the monorepo
	 * when the enclosing box.json is the monorepo's own — never true inside a
	 * generated app.
	 *
	 * When the source's enclosing root box.json identifies the monorepo
	 * (slug="wheels" or name="Wheels.fw") and carries a real version, rewrite
	 * the copy's placeholder to "<rootversion>-dev" so the new app reports a
	 * meaningful version. Otherwise leave the placeholder alone — the
	 * framework's runtime fallback still returns "0.0.0-dev", matching pre-fix
	 * behavior for unusual third-party layouts.
	 *
	 * @wheelsSource Absolute path of the source vendor/wheels/ directory.
	 * @vendorDir    Absolute path of the newly-written vendor/wheels/ directory
	 *               inside the scaffolded app.
	 * @return       True if the placeholder was rewritten, false otherwise.
	 */
	public boolean function rewriteVersionPlaceholder(
		required string wheelsSource,
		required string vendorDir
	) {
		var targetBox = arguments.vendorDir & "/box.json";
		if (!fileExists(targetBox)) return false;

		var content = fileRead(targetBox);
		if (!findNoCase("@build.version@", content)) return false;

		// The source is a vendor/wheels/ directory; the monorepo root lives two
		// levels up (repo-root/vendor/wheels/ -> repo-root/box.json).
		var File = createObject("java", "java.io.File");
		var sourceCanonical = File.init(arguments.wheelsSource).getCanonicalPath();
		var rootCandidate = File.init(sourceCanonical & "/../../box.json").getCanonicalPath();
		if (!fileExists(rootCandidate)) return false;

		try {
			var rootBox = deserializeJSON(fileRead(rootCandidate));
		} catch (any e) {
			return false;
		}

		var isMonorepo = isStruct(rootBox)
			&& (
				(structKeyExists(rootBox, "slug") && rootBox.slug == "wheels")
				|| (structKeyExists(rootBox, "name") && rootBox.name == "Wheels.fw")
			);
		if (!isMonorepo) return false;
		if (!structKeyExists(rootBox, "version") || !len(rootBox.version)) return false;
		if (rootBox.version == "@build.version@") return false;

		var devVersion = rootBox.version & "-dev";
		fileWrite(targetBox, replace(content, "@build.version@", devVersion, "all"));
		return true;
	}

}
