/**
 * Layout check for an extracted package. The staging directory must contain
 * exactly one entry: a directory named after the package, holding a
 * package.json, with no symbolic links anywhere in the tree.
 */
component {

	/** Throws Wheels.Packages.ExtractionFailed describing the first mismatch. */
	public void function assertSingleTree(required string stageDir, required string name) {
		var entries = directoryList(arguments.stageDir, false, "name");
		if (arrayLen(entries) != 1 || entries[1] != arguments.name) {
			$fail(arguments.name, "expected a single top-level '#arguments.name#/' directory, found: " & (arrayLen(entries) ? arrayToList(entries, ", ") : "nothing"));
		}
		var root = arguments.stageDir & (right(arguments.stageDir, 1) == "/" ? "" : "/") & arguments.name;
		var files = createObject("java", "java.nio.file.Files");
		var paths = createObject("java", "java.nio.file.Paths");
		if (files.isSymbolicLink(paths.get(root, [])) || !directoryExists(root)) {
			$fail(arguments.name, "'#arguments.name#' is not a plain directory");
		}
		if (!fileExists(root & "/package.json")) {
			$fail(arguments.name, "'#arguments.name#/package.json' is missing");
		}
		for (var path in directoryList(root, true, "path")) {
			if (files.isSymbolicLink(paths.get(path, []))) {
				$fail(arguments.name, "the package contains a link: " & replace(path, root & "/", ""));
			}
		}
	}

	private void function $fail(required string name, required string detail) {
		throw(
			type = "Wheels.Packages.ExtractionFailed",
			message = "The tarball for '#arguments.name#' does not have the expected '<name>/...' layout: #arguments.detail#."
		);
	}

}
