/**
 * Pure-logic rename detection engine for AutoMigrator.
 *
 * Pairs removed columns with added columns using explicit hints and
 * heuristic similarity (normalized-token + Levenshtein). No DB or
 * model dependencies — fully unit-testable in isolation.
 */
component {

	/**
	 * Normalizes a column name for comparison. Lowercases and strips
	 * underscores/hyphens so snake_case, camelCase, and kebab-case
	 * with the same tokens collapse to identical strings.
	 */
	public string function $normalizeToken(required string name) {
		local.result = LCase(arguments.name);
		local.result = Replace(local.result, "_", "", "all");
		local.result = Replace(local.result, "-", "", "all");
		return local.result;
	}

}
