/**
 * Name and path rules shared by the generators. Names given to `wheels
 * generate` become file paths and CFML identifiers, so they are checked before
 * anything is written, and every generated file must resolve inside the
 * project root.
 */
component {

	// Each rule is a character class plus a first-character rule, checked
	// separately: `$` in the CFML regex dialect also matches before a trailing
	// line feed, so an anchored ^...$ pattern would admit "Name<LF>".
	variables.maxNameLength = 128;

	/**
	 * A component name: one identifier, or "package/Name" segments of
	 * identifiers (e.g. "api/Products"). Throws Wheels.Generate.InvalidName.
	 */
	public string function componentName(required string name, required string kind) {
		var segments = listToArray(arguments.name, "/", true);
		var ok = arrayLen(segments) > 0;
		for (var segment in segments) {
			if (!$isIdentifier(segment)) {
				ok = false;
				break;
			}
		}
		if (!ok) {
			$invalid(arguments.kind, arguments.name, "letters, digits and underscores, starting with a letter (optionally package/Name)");
		}
		return arguments.name;
	}

	/** A single identifier (model, property, column or app name). */
	public string function identifier(required string name, required string kind) {
		if (!$isIdentifier(arguments.name)) {
			$invalid(arguments.kind, arguments.name, "letters, digits and underscores, starting with a letter");
		}
		return arguments.name;
	}

	/** A route or resource name: letters, digits, underscores and hyphens, starting with a letter. */
	public string function token(required string name, required string kind) {
		if (!isToken(arguments.name) || !reFind("^[A-Za-z]", arguments.name)) {
			$invalid(arguments.kind, arguments.name, "letters, digits, underscores and hyphens, starting with a letter");
		}
		return arguments.name;
	}

	/** A view action / file name: identifiers plus a leading underscore (partials) or hyphens. */
	public string function viewAction(required string name) {
		if (!isToken(arguments.name) || !reFind("^[A-Za-z_]", arguments.name)) {
			$invalid("view action", arguments.name, "letters, digits, underscores and hyphens");
		}
		return arguments.name;
	}

	/**
	 * Returns the path when it resolves inside projectRoot; throws
	 * Wheels.Generate.OutsideProject otherwise.
	 */
	public string function assertInside(required string projectRoot, required string path) {
		var root = $canonical(arguments.projectRoot);
		var target = $canonical(arguments.path);
		// Path.startsWith compares whole components on every OS ("/app" does not
		// contain "/apple"), unlike a string prefix test.
		var paths = createObject("java", "java.nio.file.Paths");
		if (!paths.get(target, []).startsWith(paths.get(root, []))) {
			// Name the file only: absolute paths of the project or the machine stay out
			// of the message (it can reach an MCP client or a log).
			throw(
				type = "Wheels.Generate.OutsideProject",
				message = "Refusing to write #getFileFromPath(target)#: its path leads outside the project."
			);
		}
		return arguments.path;
	}

	/**
	 * Creates dir (and any missing parents) only after checking it resolves
	 * inside projectRoot, so an existing symlinked parent can't send the new
	 * directories, or the files later written into them, outside the project.
	 */
	public string function ensureDirectoryInside(required string projectRoot, required string dir) {
		assertInside(arguments.projectRoot, arguments.dir);
		// `wheels generate --dry-run` writes nothing, directories included.
		if (request.$wheelsGenerateDryRun ?: false) {
			return arguments.dir;
		}
		if (!directoryExists(arguments.dir)) {
			directoryCreate(arguments.dir, true);
		}
		return arguments.dir;
	}

	private boolean function $isIdentifier(required string name) {
		return len(arguments.name)
			&& len(arguments.name) <= variables.maxNameLength
			&& !reFind("[^A-Za-z0-9_]", arguments.name)
			&& reFind("^[A-Za-z]", arguments.name);
	}

	/** Letters, digits and underscores only, starting with a letter, 1-128 characters. */
	public boolean function isIdentifier(required string value) {
		return $isIdentifier(arguments.value);
	}

	/** Letters, digits, underscores and hyphens only, 1-128 characters (enum values, app names). */
	public boolean function isToken(required string value) {
		return len(arguments.value)
			&& len(arguments.value) <= variables.maxNameLength
			&& !reFind("[^A-Za-z0-9_-]", arguments.value);
	}

	private string function $canonical(required string path) {
		return createObject("java", "java.io.File").init(arguments.path).getCanonicalPath();
	}

	private void function $invalid(required string kind, required string name, required string rule) {
		throw(
			type = "Wheels.Generate.InvalidName",
			message = "Invalid #arguments.kind# name '#arguments.name#': use #arguments.rule#."
		);
	}

}
