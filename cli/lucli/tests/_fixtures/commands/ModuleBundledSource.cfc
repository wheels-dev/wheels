/**
 * Output-capturing Module whose "CLI-bundled framework" can be pointed at
 * a spec-controlled directory, so `wheels upgrade apply` specs can pin the
 * bundled version (e.g. older than the app's vendor/wheels/) instead of
 * depending on whatever this checkout's vendor/wheels/ happens to carry.
 */
component extends="cli.lucli.tests._fixtures.commands.ModuleOutputCapture" {

	public void function setBundledFrameworkSource(required string path) {
		variables.bundledFrameworkSourceOverride = arguments.path;
	}

	private string function $resolveBundledFrameworkSource() {
		if (structKeyExists(variables, "bundledFrameworkSourceOverride")) {
			return variables.bundledFrameworkSourceOverride;
		}
		return super.$resolveBundledFrameworkSource();
	}

}
