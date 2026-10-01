/**
 * Layout check for an extracted package. The staging directory must contain
 * exactly one entry: a directory named after the package, holding a
 * package.json, with no symbolic links anywhere in the tree.
 *
 * Tarballs packed on macOS also carry AppleDouble metadata: `._*` files and,
 * from Finder archives, a `__MACOSX` folder. GNU tar extracts these as
 * ordinary entries. At the top level a regular `._*` file and a `__MACOSX`
 * directory are ignored; inside `<name>/` they are deleted so they never
 * reach vendor/. Links among them are refused like any other link.
 */
component {

	/**
	 * Throws Wheels.Packages.ExtractionFailed describing the first mismatch.
	 * Once every check passes, also deletes the Mac metadata inside `<name>/`.
	 */
	public void function assertSingleTree(required string stageDir, required string name) {
		var files = createObject("java", "java.nio.file.Files");
		var paths = createObject("java", "java.nio.file.Paths");
		var stage = arguments.stageDir & (right(arguments.stageDir, 1) == "/" ? "" : "/");
		var entries = [];
		var macDirs = [];
		for (var entry in directoryList(stage, false, "name")) {
			var entryPath = stage & entry;
			var isLink = files.isSymbolicLink(paths.get(entryPath, []));
			if (!isLink && left(entry, 2) == "._" && fileExists(entryPath)) {
				continue;
			}
			if (!isLink && entry == "__MACOSX" && directoryExists(entryPath)) {
				arrayAppend(macDirs, entryPath);
				continue;
			}
			arrayAppend(entries, entry);
		}
		if (arrayLen(entries) != 1 || entries[1] != arguments.name) {
			$fail(arguments.name, "expected a single top-level '#arguments.name#/' directory, found: " & (arrayLen(entries) ? arrayToList(entries, ", ") : "nothing"));
		}
		var root = stage & arguments.name;
		if (files.isSymbolicLink(paths.get(root, [])) || !directoryExists(root)) {
			$fail(arguments.name, "'#arguments.name#' is not a plain directory");
		}
		if (!fileExists(root & "/package.json")) {
			$fail(arguments.name, "'#arguments.name#/package.json' is missing");
		}
		for (var macDir in macDirs) {
			for (var path in directoryList(macDir, true, "path")) {
				if (files.isSymbolicLink(paths.get(path, []))) {
					$fail(arguments.name, "the package contains a link: " & replace(path, stage, ""));
				}
			}
		}
		var metadata = [];
		for (var path in directoryList(root, true, "path")) {
			if (files.isSymbolicLink(paths.get(path, []))) {
				$fail(arguments.name, "the package contains a link: " & replace(path, root & "/", ""));
			}
			var leaf = getFileFromPath(path);
			if ((left(leaf, 2) == "._" && fileExists(path)) || (leaf == "__MACOSX" && directoryExists(path))) {
				arrayAppend(metadata, path);
			}
		}
		// Every link check has passed, so nothing deleted here is a link.
		for (var path in metadata) {
			if (directoryExists(path)) {
				directoryDelete(path, true);
			} else if (fileExists(path)) {
				fileDelete(path);
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
