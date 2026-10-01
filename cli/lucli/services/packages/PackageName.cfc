/**
 * A package name is one plain path segment: it names vendor/<name>/, the cached
 * manifest file and the registry directory. Anything that could be read as a
 * path (separators, "." / "..", leading dots or spaces) is rejected before it
 * reaches the filesystem or a URL.
 */
component {

	/** Returns the name unchanged when valid; throws Wheels.Packages.BadInput otherwise. */
	public string function assert(required string name) {
		// Bounds, character class and first character are checked separately:
		// `$` in the CFML regex dialect also matches before a trailing line feed.
		if (
			len(arguments.name) < 1 || len(arguments.name) > 100
			|| reFind("[^A-Za-z0-9._-]", arguments.name)
			|| !reFind("^[A-Za-z0-9]", arguments.name)
		) {
			throw(
				type = "Wheels.Packages.BadInput",
				message = "Invalid package name '#arguments.name#': use letters, digits, dots, underscores or hyphens, starting with a letter or digit."
			);
		}
		return arguments.name;
	}

	/**
	 * Returns <canonical vendorDir>/<name>. The name is validated first, so the
	 * result is always a direct child of vendorDir. The child itself is not
	 * canonicalized, so a package symlinked into vendor/ stays addressable.
	 */
	public string function childOf(required string vendorDir, required string name) {
		assert(arguments.name);
		var base = $canonical(arguments.vendorDir);
		var target = base & "/" & arguments.name;
		if (createObject("java", "java.io.File").init(target).getParent() != base) {
			throw(
				type = "Wheels.Packages.BadInput",
				message = "Package '#arguments.name#' does not resolve inside #base#."
			);
		}
		return target;
	}

	private string function $canonical(required string path) {
		return createObject("java", "java.io.File").init(arguments.path).getCanonicalPath();
	}

}
