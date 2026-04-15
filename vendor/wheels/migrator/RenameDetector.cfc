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

	/**
	 * Similarity score in [0.0, 1.0]. 1.0 means identical normalized
	 * tokens (case/underscore/hyphen variants of the same name).
	 * Otherwise 1 - (Levenshtein / maxLength) of normalized forms.
	 */
	public numeric function $score(required string nameA, required string nameB) {
		local.a = $normalizeToken(arguments.nameA);
		local.b = $normalizeToken(arguments.nameB);
		local.maxLen = Max(Len(local.a), Len(local.b));
		if (local.maxLen == 0) {
			return 0;
		}
		if (local.a == local.b) {
			return 1.0;
		}
		local.dist = $levenshtein(local.a, local.b);
		return 1.0 - (local.dist / local.maxLen);
	}

	/**
	 * Main entry point. Pairs added columns with removed columns based
	 * on explicit hints and heuristic similarity.
	 *
	 * @addColumns    Array of {name, type, nullable, default}.
	 * @removeColumns Array of {name}.
	 * @addTypes      Struct keyed by add column name → migration type.
	 * @removeTypes   Struct keyed by remove column name → migration type.
	 * @hints         {renames: {"oldCol": "newCol", ...}}
	 * @threshold     Heuristic confidence cutoff (default 0.7).
	 */
	public struct function detect(
		required array addColumns,
		required array removeColumns,
		required struct addTypes,
		required struct removeTypes,
		struct hints = {},
		numeric threshold = 0.7
	) {
		if (arguments.threshold < 0 || arguments.threshold > 1) {
			Throw(
				type = "Wheels.InvalidThreshold",
				message = "heuristicThreshold must be between 0 and 1, got " & arguments.threshold
			);
		}

		// Work on shallow copies so callers' arrays aren't mutated
		local.remainingAdds = Duplicate(arguments.addColumns);
		local.remainingRemoves = Duplicate(arguments.removeColumns);
		local.confirmedRenames = [];
		local.suggestedRenames = [];

		return {
			confirmedRenames: local.confirmedRenames,
			suggestedRenames: local.suggestedRenames,
			remainingAdds: local.remainingAdds,
			remainingRemoves: local.remainingRemoves
		};
	}

}
