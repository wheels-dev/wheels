/**
 * Helper extracted from app-runner.cfm so the directory-scoping rule is
 * unit-testable without spinning up an HTTP request. app-runner.cfm reads
 * url.directory, hands it to this resolver, and uses the returned dotted
 * path as the TestBox directory mapping.
 *
 * Convention: only accept dotted paths beginning with "tests." so the
 * resolver cannot be tricked into compiling arbitrary CFCs (e.g. by
 * passing `?directory=vendor.wheels.lib`). Empty / whitespace / malformed
 * inputs fall back to the project's `tests.specs` default, matching how
 * the framework's own runner behaves when no scope is requested.
 *
 * The CLI's `$normalizeTestFilter()` is responsible for converting short
 * forms (`models`, `controllers`) into the dotted form this resolver
 * accepts (`tests.specs.models`, `tests.specs.controllers`). If a bare
 * short name reaches here, the regex rejects it and the resolver returns
 * the default — silent fallback is the failure mode this helper exists
 * to make testable.
 *
 * See issue #2489.
 */
component {

	variables.DEFAULT_DIRECTORY = "tests.specs";
	variables.ACCEPTED_PATH_REGEX = "^tests(\.[a-zA-Z0-9_]+)*$";

	public string function resolveDirectory(required struct url) {
		if (!StructKeyExists(arguments.url, "directory")) {
			return variables.DEFAULT_DIRECTORY;
		}
		var requested = Trim(arguments.url.directory);
		if (!Len(requested)) {
			return variables.DEFAULT_DIRECTORY;
		}
		if (ReFindNoCase(variables.ACCEPTED_PATH_REGEX, requested)) {
			return requested;
		}
		return variables.DEFAULT_DIRECTORY;
	}

}
