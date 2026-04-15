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

	/**
	 * Classic Levenshtein edit distance via dynamic programming.
	 * Pure CFML — no JVM library dependency to avoid cross-engine risk.
	 */
	public numeric function $levenshtein(required string a, required string b) {
		local.lenA = Len(arguments.a);
		local.lenB = Len(arguments.b);

		if (local.lenA == 0) {
			return local.lenB;
		}
		if (local.lenB == 0) {
			return local.lenA;
		}

		// Two-row DP: previous row + current row
		local.prev = [];
		ArrayResize(local.prev, local.lenB + 1);
		for (local.j = 0; local.j <= local.lenB; local.j++) {
			local.prev[local.j + 1] = local.j;
		}

		for (local.i = 1; local.i <= local.lenA; local.i++) {
			local.curr = [];
			ArrayResize(local.curr, local.lenB + 1);
			local.curr[1] = local.i;
			local.charA = Mid(arguments.a, local.i, 1);

			for (local.j = 1; local.j <= local.lenB; local.j++) {
				local.charB = Mid(arguments.b, local.j, 1);
				local.cost = (local.charA == local.charB) ? 0 : 1;
				local.curr[local.j + 1] = Min(
					Min(
						local.curr[local.j] + 1,       // insertion
						local.prev[local.j + 1] + 1    // deletion
					),
					local.prev[local.j] + local.cost   // substitution
				);
			}

			local.prev = local.curr;
		}

		return local.prev[local.lenB + 1];
	}

}
