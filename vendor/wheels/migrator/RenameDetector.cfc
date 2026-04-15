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

		// Deep-copy inputs so callers' arrays aren't mutated
		local.remainingAdds = Duplicate(arguments.addColumns);
		local.remainingRemoves = Duplicate(arguments.removeColumns);
		local.confirmedRenames = [];
		local.suggestedRenames = [];

		// --- Explicit-hint pass ---
		local.hintRenames = StructKeyExists(arguments.hints, "renames") ? arguments.hints.renames : {};

		// Detect duplicate `to` mappings (duplicate `from` impossible — struct keys are unique)
		local.seenTos = {};
		for (local.oldName in local.hintRenames) {
			local.newName = local.hintRenames[local.oldName];
			if (StructKeyExists(local.seenTos, LCase(local.newName))) {
				Throw(
					type = "Wheels.DuplicateRenameHint",
					message = "duplicate rename hint: column '" & local.newName
						& "' appears as destination of multiple renames"
				);
			}
			local.seenTos[LCase(local.newName)] = true;
		}

		// Process each hint
		for (local.oldName in local.hintRenames) {
			local.newName = local.hintRenames[local.oldName];
			local.removeIdx = $findColumnIndex(local.remainingRemoves, local.oldName);
			local.addIdx = $findColumnIndex(local.remainingAdds, local.newName);

			if (local.removeIdx == 0) {
				Throw(
					type = "Wheels.InvalidRenameHint",
					message = "rename hint references column '" & local.oldName
						& "' which is not in the removed-columns set"
				);
			}
			if (local.addIdx == 0) {
				Throw(
					type = "Wheels.InvalidRenameHint",
					message = "rename hint references column '" & local.newName
						& "' which is not in the added-columns set"
				);
			}

			local.rType = arguments.removeTypes[local.oldName];
			local.aType = arguments.addTypes[local.newName];
			if (local.rType != local.aType) {
				Throw(
					type = "Wheels.RenameHintTypeMismatch",
					message = "rename hint " & local.oldName & " -> " & local.newName
						& " has type mismatch: " & local.rType & " -> " & local.aType
						& ". Rename + retype requires separate migrations."
				);
			}

			ArrayAppend(local.confirmedRenames, {
				from: local.oldName,
				to: local.newName,
				type: local.aType,
				source: "hint"
			});
			ArrayDeleteAt(local.remainingRemoves, local.removeIdx);
			ArrayDeleteAt(local.remainingAdds, local.addIdx);
		}

		return {
			confirmedRenames: local.confirmedRenames,
			suggestedRenames: local.suggestedRenames,
			remainingAdds: local.remainingAdds,
			remainingRemoves: local.remainingRemoves
		};
	}

	/**
	 * Case-insensitive column lookup in an array of {name: ...} structs.
	 * Returns 1-based index, or 0 if not found.
	 */
	public numeric function $findColumnIndex(required array columns, required string name) {
		local.target = LCase(arguments.name);
		for (local.i = 1; local.i <= ArrayLen(arguments.columns); local.i++) {
			if (LCase(arguments.columns[local.i].name) == local.target) {
				return local.i;
			}
		}
		return 0;
	}

}
