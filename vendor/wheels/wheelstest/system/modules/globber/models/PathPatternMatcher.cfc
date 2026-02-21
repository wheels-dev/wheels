/**
 * Minimal path pattern matcher for TestBox bundle discovery.
 * Matches file paths against glob-style patterns (e.g. "*Spec*.cfc", "*Test*.bx").
 */
component {

	/**
	 * Check if a path matches any of the given patterns.
	 *
	 * @patterns Array of glob patterns (e.g. ["*Spec*.cfc", "*Test*.bx"])
	 * @path     The file path to test
	 * @return   true if the path matches at least one pattern
	 */
	boolean function matchPatterns(required array patterns, required string path) {
		// Extract just the filename from the full path
		var filename = listLast(replace(arguments.path, "\", "/", "all"), "/");

		for (var pattern in arguments.patterns) {
			if (matchPattern(trim(pattern), filename)) {
				return true;
			}
		}
		return false;
	}

	/**
	 * Match a single glob pattern against a filename.
	 * Supports * (any chars) and ? (single char) wildcards.
	 */
	private boolean function matchPattern(required string pattern, required string filename) {
		// Convert glob to regex by processing char-by-char
		var regex = "";
		var chars = arguments.pattern.toCharArray();
		for (var c in chars) {
			if (c == "*") {
				regex &= ".*";
			} else if (c == "?") {
				regex &= ".";
			} else if (c == ".") {
				regex &= "\.";
			} else {
				regex &= c;
			}
		}
		// Match the full filename (case-insensitive)
		return reFindNoCase("^" & regex & "$", arguments.filename) > 0;
	}

}
