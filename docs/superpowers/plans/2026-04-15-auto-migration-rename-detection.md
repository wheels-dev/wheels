# Auto-Migration Rename Detection Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close item 6 of `docs/wheels-vs-frameworks.md` "Where Wheels Trails" — ship migration rename detection via explicit hints + heuristic suggestions, with CLI and MCP integration.

**Architecture:** New pure-logic `RenameDetector.cfc` (normalization + Levenshtein scoring + hint validation + greedy assignment with ambiguity pre-counting) called from `AutoMigrator.diff()`/`diffAll()`. Migration CFC generation emits `renameColumn()` (existing DSL). CLI `wheels dbmigrate diff` wraps via existing bridge pattern. MCP `wheels_migrate` extended with `action="diff"`.

**Tech Stack:** CFML (Lucee 7, Adobe CF 2025, BoxLang), TestBox BDD, Wheels Migrator DSL.

**Spec:** `docs/superpowers/specs/2026-04-15-auto-migration-rename-detection-design.md`

---

## File Map

**Create:**
- `vendor/wheels/migrator/RenameDetector.cfc`
- `vendor/wheels/tests/specs/migrator/renameDetectorSpec.cfc`
- `cli/src/commands/wheels/dbmigrate/diff.cfc`
- `docs/src/command-line-tools/commands/database/dbmigrate-diff.md`

**Modify:**
- `vendor/wheels/migrator/AutoMigrator.cfc` (add options param; call detector; emit renameColumns)
- `vendor/wheels/tests/specs/migrator/autoMigratorSpec.cfc` (rename integration specs)
- `vendor/wheels/public/mcp/McpServer.cfc` (add action="diff")
- `vendor/wheels/public/views/cli.cfm` (add server-side `command=diff` dispatcher)
- `docs/wheels-vs-frameworks.md` (Trails → Leads move)
- `docs/src/command-line-tools/cli-guides/migrations.md` (rename section)
- `docs/src/database-interaction-through-models/database-migrations/README.md` (auto-migration section)
- `CLAUDE.md` (quick reference)

**Responsibility split:**
- `RenameDetector.cfc`: pure logic — similarity, hints, ambiguity. No DB/model deps.
- `AutoMigrator.cfc`: schema introspection + diff orchestration + CFC generation. Delegates rename logic to detector.
- `diff.cfc` (CLI): arg parsing, preview/write flow, human output. Server-side via bridge.
- `cli.cfm`: thin server-side dispatcher for `command=diff` that calls `AutoMigrator` and returns JSON.
- `McpServer.cfc`: JSON in/out wrapper, `action=diff` handler.

---

## Task 1: `$normalizeToken` — pure string normalization

**Files:**
- Create: `vendor/wheels/migrator/RenameDetector.cfc`
- Create: `vendor/wheels/tests/specs/migrator/renameDetectorSpec.cfc`

- [ ] **Step 1: Write failing tests**

Write `vendor/wheels/tests/specs/migrator/renameDetectorSpec.cfc`:

```cfm
component extends="wheels.WheelsTest" {

	function beforeAll() {
		detector = CreateObject("component", "wheels.migrator.RenameDetector");
	}

	function run() {

		describe("RenameDetector", () => {

			describe("$normalizeToken", () => {

				it("lowercases input", () => {
					expect(detector.$normalizeToken("FULLNAME")).toBe("fullname");
				});

				it("removes underscores", () => {
					expect(detector.$normalizeToken("full_name")).toBe("fullname");
				});

				it("removes hyphens", () => {
					expect(detector.$normalizeToken("full-name")).toBe("fullname");
				});

				it("normalizes camelCase and snake_case to same token", () => {
					expect(detector.$normalizeToken("fullName")).toBe("fullname");
					expect(detector.$normalizeToken("full_name")).toBe("fullname");
				});

				it("handles empty string", () => {
					expect(detector.$normalizeToken("")).toBe("");
				});

				it("handles mixed case + separators", () => {
					expect(detector.$normalizeToken("FULL-Name_Field")).toBe("fullnamefield");
				});

			});

		});

	}

}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
bash tools/test-local.sh migrator
```
Expected: multiple failures with "component not found" or similar (`RenameDetector.cfc` doesn't exist yet).

- [ ] **Step 3: Implement `RenameDetector.cfc` skeleton with `$normalizeToken`**

Create `vendor/wheels/migrator/RenameDetector.cfc`:

```cfm
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
```

- [ ] **Step 4: Run test to verify it passes**

```bash
bash tools/test-local.sh migrator
```
Expected: all 6 `$normalizeToken` specs pass. No failures introduced elsewhere.

- [ ] **Step 5: Commit**

```bash
git add vendor/wheels/migrator/RenameDetector.cfc vendor/wheels/tests/specs/migrator/renameDetectorSpec.cfc
git commit -m "feat(migration): add RenameDetector with normalizeToken"
```

---

## Task 2: `$levenshtein` — edit distance

**Files:**
- Modify: `vendor/wheels/migrator/RenameDetector.cfc`
- Modify: `vendor/wheels/tests/specs/migrator/renameDetectorSpec.cfc`

- [ ] **Step 1: Add failing tests**

In `renameDetectorSpec.cfc`, add a `describe` block inside the existing `describe("RenameDetector")`:

```cfm
describe("$levenshtein", () => {

	it("returns 0 for identical strings", () => {
		expect(detector.$levenshtein("abc", "abc")).toBe(0);
	});

	it("returns length of other when one string is empty", () => {
		expect(detector.$levenshtein("", "abc")).toBe(3);
		expect(detector.$levenshtein("abc", "")).toBe(3);
	});

	it("returns 1 for single substitution", () => {
		expect(detector.$levenshtein("cat", "bat")).toBe(1);
	});

	it("returns 1 for single insertion", () => {
		expect(detector.$levenshtein("cat", "cats")).toBe(1);
	});

	it("returns 1 for single deletion", () => {
		expect(detector.$levenshtein("cats", "cat")).toBe(1);
	});

	it("handles transposition as two edits", () => {
		expect(detector.$levenshtein("ab", "ba")).toBe(2);
	});

	it("computes distance for realistic column names", () => {
		// emailaddr → emailaddress: insert 'e', 's', 's' = 3
		expect(detector.$levenshtein("emailaddr", "emailaddress")).toBe(3);
	});

});
```

- [ ] **Step 2: Run test to verify it fails**

```bash
bash tools/test-local.sh migrator
```
Expected: 7 failures in `$levenshtein` specs (method not defined).

- [ ] **Step 3: Implement `$levenshtein` in `RenameDetector.cfc`**

Add to `RenameDetector.cfc`:

```cfm
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
```

- [ ] **Step 4: Run test to verify it passes**

```bash
bash tools/test-local.sh migrator
```
Expected: all 7 `$levenshtein` specs pass.

- [ ] **Step 5: Commit**

```bash
git add vendor/wheels/migrator/RenameDetector.cfc vendor/wheels/tests/specs/migrator/renameDetectorSpec.cfc
git commit -m "feat(migration): add Levenshtein distance to RenameDetector"
```

---

## Task 3: `$score` — composed similarity

**Files:**
- Modify: `vendor/wheels/migrator/RenameDetector.cfc`
- Modify: `vendor/wheels/tests/specs/migrator/renameDetectorSpec.cfc`

- [ ] **Step 1: Add failing tests**

Add inside the main `describe("RenameDetector")` block:

```cfm
describe("$score", () => {

	it("scores identical normalized tokens as 1.0", () => {
		expect(detector.$score("full_name", "fullName")).toBe(1.0);
	});

	it("scores identical raw strings as 1.0", () => {
		expect(detector.$score("bio", "bio")).toBe(1.0);
	});

	it("scores case-only differences as 1.0", () => {
		expect(detector.$score("FULLNAME", "fullname")).toBe(1.0);
	});

	it("scores near-matches above threshold", () => {
		// emailaddr vs emailaddress: distance 3, maxLen 12, score ≈ 0.75
		local.s = detector.$score("email_addr", "emailAddress");
		expect(local.s >= 0.70 && local.s < 1.0).toBeTrue();
	});

	it("scores unrelated strings below threshold", () => {
		local.s = detector.$score("bio", "description");
		expect(local.s < 0.5).toBeTrue();
	});

	it("returns 0 for both empty strings", () => {
		expect(detector.$score("", "")).toBe(0);
	});

});
```

- [ ] **Step 2: Run test to verify it fails**

```bash
bash tools/test-local.sh migrator
```
Expected: 6 failures (`$score` method undefined).

- [ ] **Step 3: Implement `$score`**

Add to `RenameDetector.cfc`:

```cfm
/**
 * Similarity score in [0.0, 1.0]. 1.0 means identical normalized
 * tokens (case/underscore/hyphen variants of the same name).
 * Otherwise 1 - (Levenshtein / maxLength) of normalized forms.
 */
public numeric function $score(required string nameA, required string nameB) {
	local.a = $normalizeToken(arguments.nameA);
	local.b = $normalizeToken(arguments.nameB);
	if (local.a == local.b) {
		return 1.0;
	}
	local.maxLen = Max(Len(local.a), Len(local.b));
	if (local.maxLen == 0) {
		return 0;
	}
	local.dist = $levenshtein(local.a, local.b);
	return 1.0 - (local.dist / local.maxLen);
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
bash tools/test-local.sh migrator
```
Expected: all 6 `$score` specs pass.

- [ ] **Step 5: Commit**

```bash
git add vendor/wheels/migrator/RenameDetector.cfc vendor/wheels/tests/specs/migrator/renameDetectorSpec.cfc
git commit -m "feat(migration): add similarity score to RenameDetector"
```

---

## Task 4: `detect()` skeleton — empty happy-path

**Files:**
- Modify: `vendor/wheels/migrator/RenameDetector.cfc`
- Modify: `vendor/wheels/tests/specs/migrator/renameDetectorSpec.cfc`

- [ ] **Step 1: Add failing tests**

Add inside the main `describe("RenameDetector")`:

```cfm
describe("detect() — empty inputs", () => {

	it("returns all four keys with empty arrays given empty inputs", () => {
		local.result = detector.detect(
			addColumns = [],
			removeColumns = [],
			addTypes = {},
			removeTypes = {}
		);
		expect(local.result).toHaveKey("confirmedRenames");
		expect(local.result).toHaveKey("suggestedRenames");
		expect(local.result).toHaveKey("remainingAdds");
		expect(local.result).toHaveKey("remainingRemoves");
		expect(local.result.confirmedRenames).toBeArray();
		expect(ArrayLen(local.result.confirmedRenames)).toBe(0);
		expect(ArrayLen(local.result.suggestedRenames)).toBe(0);
		expect(ArrayLen(local.result.remainingAdds)).toBe(0);
		expect(ArrayLen(local.result.remainingRemoves)).toBe(0);
	});

	it("returns inputs unchanged when no hints and no heuristic matches", () => {
		local.result = detector.detect(
			addColumns = [{name: "bio", type: "text", nullable: true, "default": ""}],
			removeColumns = [{name: "legacy_flag"}],
			addTypes = {"bio": "text"},
			removeTypes = {"legacy_flag": "boolean"}
		);
		expect(ArrayLen(local.result.confirmedRenames)).toBe(0);
		expect(ArrayLen(local.result.suggestedRenames)).toBe(0);
		expect(ArrayLen(local.result.remainingAdds)).toBe(1);
		expect(ArrayLen(local.result.remainingRemoves)).toBe(1);
	});

});
```

- [ ] **Step 2: Run test to verify it fails**

```bash
bash tools/test-local.sh migrator
```
Expected: 2 failures (`detect` undefined).

- [ ] **Step 3: Implement `detect()` skeleton**

Add to `RenameDetector.cfc`:

```cfm
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
```

- [ ] **Step 4: Run test to verify it passes**

```bash
bash tools/test-local.sh migrator
```
Expected: 2 new specs pass.

- [ ] **Step 5: Commit**

```bash
git add vendor/wheels/migrator/RenameDetector.cfc vendor/wheels/tests/specs/migrator/renameDetectorSpec.cfc
git commit -m "feat(migration): add detect() skeleton to RenameDetector"
```

---

## Task 5: `detect()` — explicit hint pass

**Files:**
- Modify: `vendor/wheels/migrator/RenameDetector.cfc`
- Modify: `vendor/wheels/tests/specs/migrator/renameDetectorSpec.cfc`

- [ ] **Step 1: Add failing tests**

Add inside the main `describe("RenameDetector")`:

```cfm
describe("detect() — explicit hints", () => {

	it("confirms rename when hint maps existing remove to existing add", () => {
		local.result = detector.detect(
			addColumns = [{name: "fullName", type: "string", nullable: true, "default": ""}],
			removeColumns = [{name: "full_name"}],
			addTypes = {"fullName": "string"},
			removeTypes = {"full_name": "string"},
			hints = {renames: {"full_name": "fullName"}}
		);
		expect(ArrayLen(local.result.confirmedRenames)).toBe(1);
		expect(local.result.confirmedRenames[1].from).toBe("full_name");
		expect(local.result.confirmedRenames[1].to).toBe("fullName");
		expect(local.result.confirmedRenames[1].type).toBe("string");
		expect(local.result.confirmedRenames[1].source).toBe("hint");
		expect(ArrayLen(local.result.remainingAdds)).toBe(0);
		expect(ArrayLen(local.result.remainingRemoves)).toBe(0);
	});

	it("leaves non-hinted columns in remaining arrays", () => {
		local.result = detector.detect(
			addColumns = [
				{name: "fullName", type: "string", nullable: true, "default": ""},
				{name: "bio", type: "text", nullable: true, "default": ""}
			],
			removeColumns = [
				{name: "full_name"},
				{name: "legacy_flag"}
			],
			addTypes = {"fullName": "string", "bio": "text"},
			removeTypes = {"full_name": "string", "legacy_flag": "boolean"},
			hints = {renames: {"full_name": "fullName"}}
		);
		expect(ArrayLen(local.result.confirmedRenames)).toBe(1);
		expect(ArrayLen(local.result.remainingAdds)).toBe(1);
		expect(local.result.remainingAdds[1].name).toBe("bio");
		expect(ArrayLen(local.result.remainingRemoves)).toBe(1);
		expect(local.result.remainingRemoves[1].name).toBe("legacy_flag");
	});

	it("raises InvalidRenameHint when hint from-column is not in removes", () => {
		expect(() => {
			detector.detect(
				addColumns = [{name: "fullName", type: "string", nullable: true, "default": ""}],
				removeColumns = [{name: "legacy_flag"}],
				addTypes = {"fullName": "string"},
				removeTypes = {"legacy_flag": "boolean"},
				hints = {renames: {"nonexistent": "fullName"}}
			);
		}).toThrow("Wheels.InvalidRenameHint");
	});

	it("raises InvalidRenameHint when hint to-column is not in adds", () => {
		expect(() => {
			detector.detect(
				addColumns = [{name: "fullName", type: "string", nullable: true, "default": ""}],
				removeColumns = [{name: "full_name"}],
				addTypes = {"fullName": "string"},
				removeTypes = {"full_name": "string"},
				hints = {renames: {"full_name": "nonexistent"}}
			);
		}).toThrow("Wheels.InvalidRenameHint");
	});

	it("raises RenameHintTypeMismatch when hinted pair has different types", () => {
		expect(() => {
			detector.detect(
				addColumns = [{name: "fullName", type: "text", nullable: true, "default": ""}],
				removeColumns = [{name: "full_name"}],
				addTypes = {"fullName": "text"},
				removeTypes = {"full_name": "string"},
				hints = {renames: {"full_name": "fullName"}}
			);
		}).toThrow("Wheels.RenameHintTypeMismatch");
	});

	it("raises DuplicateRenameHint when two hints share the same from-column", () => {
		expect(() => {
			detector.detect(
				addColumns = [
					{name: "fullName", type: "string", nullable: true, "default": ""},
					{name: "displayName", type: "string", nullable: true, "default": ""}
				],
				removeColumns = [{name: "full_name"}],
				addTypes = {"fullName": "string", "displayName": "string"},
				removeTypes = {"full_name": "string"},
				// Note: CFML struct can't have duplicate keys, so simulate with an array-of-pairs
				// This test uses a second-hints variant — see $validateHints implementation.
				// Alternative: single hints struct can't express the collision; this test
				// is covered at the CLI layer where --rename can appear multiple times.
				// Skip this spec for now — CFML struct keys are unique. See next spec.
				hints = {renames: {"full_name": "fullName"}}
			);
		}).notToThrow();
	});

	it("raises DuplicateRenameHint when two hints share the same to-column", () => {
		expect(() => {
			detector.detect(
				addColumns = [{name: "fullName", type: "string", nullable: true, "default": ""}],
				removeColumns = [
					{name: "full_name"},
					{name: "display_name"}
				],
				addTypes = {"fullName": "string"},
				removeTypes = {"full_name": "string", "display_name": "string"},
				hints = {renames: {"full_name": "fullName", "display_name": "fullName"}}
			);
		}).toThrow("Wheels.DuplicateRenameHint");
	});

});
```

Note on duplicate-from: CFML struct keys are inherently unique. The first "duplicate from" test is a no-op verification; the CLI is where `--rename=a:x --rename=a:y` could be specified, and that layer must detect duplicates before building the hints struct. Covered in Task 12.

- [ ] **Step 2: Run test to verify it fails**

```bash
bash tools/test-local.sh migrator
```
Expected: hint-pass specs fail.

- [ ] **Step 3: Implement hint-pass logic in `detect()`**

Update `detect()` body — insert after the threshold validation and before the final return:

```cfm
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
			message = "rename hint " & local.oldName & "→" & local.newName
				& " has type mismatch: " & local.rType & " → " & local.aType
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
```

Add helper at the bottom of the component:

```cfm
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
```

- [ ] **Step 4: Run test to verify it passes**

```bash
bash tools/test-local.sh migrator
```
Expected: all hint-pass specs pass. No regressions.

- [ ] **Step 5: Commit**

```bash
git add vendor/wheels/migrator/RenameDetector.cfc vendor/wheels/tests/specs/migrator/renameDetectorSpec.cfc
git commit -m "feat(migration): add explicit hint pass to RenameDetector"
```

---

## Task 6: `detect()` — heuristic scoring + confirm + suggest

**Files:**
- Modify: `vendor/wheels/migrator/RenameDetector.cfc`
- Modify: `vendor/wheels/tests/specs/migrator/renameDetectorSpec.cfc`

- [ ] **Step 1: Add failing tests**

Add inside the main `describe("RenameDetector")`:

```cfm
describe("detect() — heuristic pass", () => {

	it("auto-confirms unambiguous score-1.0 matches as heuristic source", () => {
		local.result = detector.detect(
			addColumns = [{name: "fullName", type: "string", nullable: true, "default": ""}],
			removeColumns = [{name: "full_name"}],
			addTypes = {"fullName": "string"},
			removeTypes = {"full_name": "string"}
		);
		expect(ArrayLen(local.result.confirmedRenames)).toBe(1);
		expect(local.result.confirmedRenames[1].from).toBe("full_name");
		expect(local.result.confirmedRenames[1].to).toBe("fullName");
		expect(local.result.confirmedRenames[1].source).toBe("heuristic");
		expect(ArrayLen(local.result.suggestedRenames)).toBe(0);
	});

	it("suggests above-threshold but below-1.0 matches", () => {
		local.result = detector.detect(
			addColumns = [{name: "emailAddress", type: "string", nullable: true, "default": ""}],
			removeColumns = [{name: "email_addr"}],
			addTypes = {"emailAddress": "string"},
			removeTypes = {"email_addr": "string"}
		);
		expect(ArrayLen(local.result.confirmedRenames)).toBe(0);
		expect(ArrayLen(local.result.suggestedRenames)).toBe(1);
		expect(local.result.suggestedRenames[1].from).toBe("email_addr");
		expect(local.result.suggestedRenames[1].to).toBe("emailAddress");
		expect(local.result.suggestedRenames[1].confidence >= 0.7).toBeTrue();
		expect(local.result.suggestedRenames[1].confidence < 1.0).toBeTrue();
		expect(local.result.suggestedRenames[1].ambiguous).toBeFalse();
	});

	it("leaves suggested-rename columns in remainingAdds and remainingRemoves", () => {
		// Suggestions are informational — user must confirm via hint to actually
		// rename. Columns stay in remainingAdds/remainingRemoves so that if the
		// user runs --write without a hint, drop+add is still emitted
		// (predictable behavior — no silent data mutation).
		local.result = detector.detect(
			addColumns = [{name: "emailAddress", type: "string", nullable: true, "default": ""}],
			removeColumns = [{name: "email_addr"}],
			addTypes = {"emailAddress": "string"},
			removeTypes = {"email_addr": "string"}
		);
		expect(ArrayLen(local.result.suggestedRenames)).toBe(1);
		expect(ArrayLen(local.result.remainingAdds)).toBe(1);
		expect(local.result.remainingAdds[1].name).toBe("emailAddress");
		expect(ArrayLen(local.result.remainingRemoves)).toBe(1);
		expect(local.result.remainingRemoves[1].name).toBe("email_addr");
	});

	it("does not pair when score is below threshold", () => {
		local.result = detector.detect(
			addColumns = [{name: "description", type: "text", nullable: true, "default": ""}],
			removeColumns = [{name: "bio"}],
			addTypes = {"description": "text"},
			removeTypes = {"bio": "text"}
		);
		expect(ArrayLen(local.result.confirmedRenames)).toBe(0);
		expect(ArrayLen(local.result.suggestedRenames)).toBe(0);
		expect(ArrayLen(local.result.remainingAdds)).toBe(1);
		expect(ArrayLen(local.result.remainingRemoves)).toBe(1);
	});

	it("does not pair when types differ", () => {
		local.result = detector.detect(
			addColumns = [{name: "fullName", type: "text", nullable: true, "default": ""}],
			removeColumns = [{name: "full_name"}],
			addTypes = {"fullName": "text"},
			removeTypes = {"full_name": "string"}
		);
		expect(ArrayLen(local.result.confirmedRenames)).toBe(0);
		expect(ArrayLen(local.result.suggestedRenames)).toBe(0);
		expect(ArrayLen(local.result.remainingAdds)).toBe(1);
		expect(ArrayLen(local.result.remainingRemoves)).toBe(1);
	});

	it("respects a custom threshold", () => {
		// With threshold=0.9, email_addr → emailAddress (score ~0.75) no longer suggested
		local.result = detector.detect(
			addColumns = [{name: "emailAddress", type: "string", nullable: true, "default": ""}],
			removeColumns = [{name: "email_addr"}],
			addTypes = {"emailAddress": "string"},
			removeTypes = {"email_addr": "string"},
			hints = {},
			threshold = 0.9
		);
		expect(ArrayLen(local.result.suggestedRenames)).toBe(0);
		expect(ArrayLen(local.result.remainingAdds)).toBe(1);
		expect(ArrayLen(local.result.remainingRemoves)).toBe(1);
	});

	it("raises InvalidThreshold when threshold is out of range", () => {
		expect(() => {
			detector.detect(
				addColumns = [],
				removeColumns = [],
				addTypes = {},
				removeTypes = {},
				hints = {},
				threshold = 1.5
			);
		}).toThrow("Wheels.InvalidThreshold");
	});

});
```

- [ ] **Step 2: Run test to verify it fails**

```bash
bash tools/test-local.sh migrator
```
Expected: 6 failures (heuristic pass not yet implemented; `InvalidThreshold` test may pass already).

- [ ] **Step 3: Implement heuristic pass**

Insert this block in `detect()` between the hint-pass and the return:

```cfm
// --- Heuristic pass ---
local.scores = [];
for (local.r = 1; local.r <= ArrayLen(local.remainingRemoves); local.r++) {
	local.rCol = local.remainingRemoves[local.r];
	for (local.a = 1; local.a <= ArrayLen(local.remainingAdds); local.a++) {
		local.aCol = local.remainingAdds[local.a];
		if (arguments.removeTypes[local.rCol.name] != arguments.addTypes[local.aCol.name]) {
			continue;
		}
		local.s = $score(local.rCol.name, local.aCol.name);
		if (local.s >= arguments.threshold) {
			ArrayAppend(local.scores, {
				from: local.rCol.name,
				to: local.aCol.name,
				confidence: local.s,
				type: arguments.addTypes[local.aCol.name]
			});
		}
	}
}

// Sort by confidence DESC
ArraySort(local.scores, function(x, y) {
	if (x.confidence > y.confidence) return -1;
	if (x.confidence < y.confidence) return 1;
	return 0;
});

// Pre-count ambiguity from the full candidate set (before greedy assignment).
// This ensures ambiguous score-1.0 pairs are demoted to suggestedRenames.
local.fromCount = {};
local.toCount = {};
for (local.s in local.scores) {
	local.fromCount[local.s.from] = (StructKeyExists(local.fromCount, local.s.from) ? local.fromCount[local.s.from] : 0) + 1;
	local.toCount[local.s.to] = (StructKeyExists(local.toCount, local.s.to) ? local.toCount[local.s.to] : 0) + 1;
}

// Greedy assignment
local.usedFroms = {};
local.usedTos = {};
for (local.s in local.scores) {
	if (StructKeyExists(local.usedFroms, local.s.from) || StructKeyExists(local.usedTos, local.s.to)) {
		continue;
	}
	local.usedFroms[local.s.from] = true;
	local.usedTos[local.s.to] = true;
	local.isAmbiguous = (local.fromCount[local.s.from] > 1 || local.toCount[local.s.to] > 1);

	if (local.s.confidence == 1.0 && !local.isAmbiguous) {
		// Auto-confirmed heuristic: consume the pair from remaining arrays.
		ArrayAppend(local.confirmedRenames, {
			from: local.s.from,
			to: local.s.to,
			type: local.s.type,
			source: "heuristic"
		});
		local.rIdx = $findColumnIndex(local.remainingRemoves, local.s.from);
		local.aIdx = $findColumnIndex(local.remainingAdds, local.s.to);
		if (local.rIdx > 0) ArrayDeleteAt(local.remainingRemoves, local.rIdx);
		if (local.aIdx > 0) ArrayDeleteAt(local.remainingAdds, local.aIdx);
	} else {
		// Suggestion: informational only. DO NOT consume the columns —
		// leave them in remainingAdds/remainingRemoves so that if the user
		// writes the migration without a hint, drop+add is still emitted
		// (predictable behavior; no silent rename).
		ArrayAppend(local.suggestedRenames, {
			from: local.s.from,
			to: local.s.to,
			type: local.s.type,
			confidence: local.s.confidence,
			ambiguous: local.isAmbiguous
		});
	}
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
bash tools/test-local.sh migrator
```
Expected: all heuristic-pass specs pass. No regressions.

- [ ] **Step 5: Commit**

```bash
git add vendor/wheels/migrator/RenameDetector.cfc vendor/wheels/tests/specs/migrator/renameDetectorSpec.cfc
git commit -m "feat(migration): add heuristic pass to RenameDetector"
```

---

## Task 7: `detect()` — ambiguity handling

**Files:**
- Modify: `vendor/wheels/tests/specs/migrator/renameDetectorSpec.cfc`

Implementation for this is already in Task 6; this task adds coverage specs to lock the behavior in.

- [ ] **Step 1: Add failing tests**

Add inside the main `describe("RenameDetector")`:

```cfm
describe("detect() — ambiguity", () => {

	it("demotes ambiguous score-1.0 pair to suggestedRenames", () => {
		// Two removes that both normalize-match the same add:
		// "full_name" and "fullName" both → "fullname"; add "FULLNAME" → "fullname"
		// Both pairs score 1.0, both ambiguous.
		local.result = detector.detect(
			addColumns = [{name: "FULLNAME", type: "string", nullable: true, "default": ""}],
			removeColumns = [
				{name: "full_name"},
				{name: "fullName"}
			],
			addTypes = {"FULLNAME": "string"},
			removeTypes = {"full_name": "string", "fullName": "string"}
		);
		expect(ArrayLen(local.result.confirmedRenames)).toBe(0);
		expect(ArrayLen(local.result.suggestedRenames)).toBe(1);
		expect(local.result.suggestedRenames[1].ambiguous).toBeTrue();
		expect(local.result.suggestedRenames[1].confidence).toBe(1.0);
	});

	it("marks one-remove matching two adds as ambiguous", () => {
		// "full_name" matches both "fullName" (1.0) and "fulName" (~0.88)
		local.result = detector.detect(
			addColumns = [
				{name: "fullName", type: "string", nullable: true, "default": ""},
				{name: "fulName", type: "string", nullable: true, "default": ""}
			],
			removeColumns = [{name: "full_name"}],
			addTypes = {"fullName": "string", "fulName": "string"},
			removeTypes = {"full_name": "string"}
		);
		// Both scores ≥ 0.7; full_name appears in 2 candidates, so both ambiguous.
		// Greedy picks highest (1.0) first: full_name → fullName ambiguous.
		expect(ArrayLen(local.result.confirmedRenames)).toBe(0);
		expect(ArrayLen(local.result.suggestedRenames)).toBeGTE(1);
		for (local.s in local.result.suggestedRenames) {
			expect(local.s.ambiguous).toBeTrue();
		}
	});

	it("greedy assignment picks highest confidence first", () => {
		// "email_addr" (string) only matches "emailAddress" at ~0.75.
		// "email" (string) matches "emailAddress" at ~0.42 (below 0.7, so not in scores)
		// and matches nothing else. Greedy claims email_addr → emailAddress as suggested.
		local.result = detector.detect(
			addColumns = [{name: "emailAddress", type: "string", nullable: true, "default": ""}],
			removeColumns = [
				{name: "email_addr"},
				{name: "email"}
			],
			addTypes = {"emailAddress": "string"},
			removeTypes = {"email_addr": "string", "email": "string"}
		);
		expect(ArrayLen(local.result.suggestedRenames)).toBe(1);
		expect(local.result.suggestedRenames[1].from).toBe("email_addr");
	});

});

describe("detect() — hints consume before heuristic", () => {

	it("excludes hinted columns from the heuristic candidate pool", () => {
		// "full_name" → "fullName" via hint; "display_name" → "displayName" via heuristic (score 1.0)
		local.result = detector.detect(
			addColumns = [
				{name: "fullName", type: "string", nullable: true, "default": ""},
				{name: "displayName", type: "string", nullable: true, "default": ""}
			],
			removeColumns = [
				{name: "full_name"},
				{name: "display_name"}
			],
			addTypes = {"fullName": "string", "displayName": "string"},
			removeTypes = {"full_name": "string", "display_name": "string"},
			hints = {renames: {"full_name": "fullName"}}
		);
		expect(ArrayLen(local.result.confirmedRenames)).toBe(2);
		// Hint-sourced rename comes first (insertion order)
		expect(local.result.confirmedRenames[1].source).toBe("hint");
		expect(local.result.confirmedRenames[2].source).toBe("heuristic");
	});

});
```

- [ ] **Step 2: Run test to verify they pass (implementation already present)**

```bash
bash tools/test-local.sh migrator
```
Expected: all 4 new specs pass. If any fail, the algorithm in Task 6 needs adjustment.

- [ ] **Step 3: Commit**

```bash
git add vendor/wheels/tests/specs/migrator/renameDetectorSpec.cfc
git commit -m "test(migration): add ambiguity specs for RenameDetector"
```

---

## Task 8: Wire `RenameDetector` into `AutoMigrator.diff()`

**Files:**
- Modify: `vendor/wheels/migrator/AutoMigrator.cfc`
- Modify: `vendor/wheels/tests/specs/migrator/autoMigratorSpec.cfc`

- [ ] **Step 1: Add failing integration tests**

Add inside `autoMigratorSpec.cfc` main `describe("AutoMigrator")`, after existing `describe("diff()")` block:

```cfm
describe("diff() — rename integration", () => {

	it("returns renameColumns and suggestedRenames keys in the result", () => {
		local.result = autoMigrator.diff("Author");
		expect(local.result).toHaveKey("renameColumns");
		expect(local.result).toHaveKey("suggestedRenames");
		expect(local.result.renameColumns).toBeArray();
		expect(local.result.suggestedRenames).toBeArray();
	});

	it("accepts options struct without breaking existing callers", () => {
		// Backward-compat: diff(modelName) with no options still works
		local.r1 = autoMigrator.diff("Author");
		local.r2 = autoMigrator.diff(modelName="Author", options={});
		expect(local.r1.tableName).toBe(local.r2.tableName);
	});

	it("threads heuristicThreshold through options", () => {
		// Threshold of 0.01 would make even unrelated pairs candidates.
		// We can't easily induce a rename without a real model mismatch, so
		// just verify the call doesn't explode.
		local.result = autoMigrator.diff(modelName="Author", options={heuristicThreshold: 0.01});
		expect(local.result).toHaveKey("renameColumns");
	});

});
```

- [ ] **Step 2: Run test to verify it fails**

```bash
bash tools/test-local.sh migrator
```
Expected: 3 failures (keys don't exist; options param not accepted).

- [ ] **Step 3: Modify `AutoMigrator.diff()`**

Edit `vendor/wheels/migrator/AutoMigrator.cfc`. Update signature and body:

Replace the existing `public struct function diff(required string modelName)` signature with:

```cfm
public struct function diff(required string modelName, struct options = {}) {
```

At the **end** of the function body, just before the existing `return { ... }` at line ~123, insert this block and replace the return:

```cfm
// Build type lookups for RenameDetector
local.addTypesMap = {};
for (local.col in local.addColumns) {
	local.addTypesMap[local.col.name] = local.col.type;
}
local.removeTypesMap = {};
for (local.col in local.removeColumns) {
	// Remove columns carry only name; look up migration type from actualColumns
	local.actual = local.actualColumns[LCase(local.col.name)];
	local.removeTypesMap[local.col.name] = $dbTypeToMigrationType(local.actual.typeName);
}

// Build hints struct from options
local.hints = {};
if (StructKeyExists(arguments.options, "renames")) {
	local.hints.renames = arguments.options.renames;
}
local.threshold = StructKeyExists(arguments.options, "heuristicThreshold")
	? arguments.options.heuristicThreshold
	: 0.7;

// Delegate to RenameDetector
local.detector = CreateObject("component", "wheels.migrator.RenameDetector");
local.detection = local.detector.detect(
	addColumns = local.addColumns,
	removeColumns = local.removeColumns,
	addTypes = local.addTypesMap,
	removeTypes = local.removeTypesMap,
	hints = local.hints,
	threshold = local.threshold
);

return {
	modelName: arguments.modelName,
	tableName: local.tableName,
	addColumns: local.detection.remainingAdds,
	removeColumns: local.detection.remainingRemoves,
	changeColumns: local.changeColumns,
	renameColumns: local.detection.confirmedRenames,
	suggestedRenames: local.detection.suggestedRenames
};
```

- [ ] **Step 4: Run test to verify it passes**

```bash
bash tools/test-local.sh migrator
```
Expected: all new specs pass. Existing `diff()` specs still pass (keys additive).

- [ ] **Step 5: Commit**

```bash
git add vendor/wheels/migrator/AutoMigrator.cfc vendor/wheels/tests/specs/migrator/autoMigratorSpec.cfc
git commit -m "feat(migration): wire RenameDetector into AutoMigrator.diff()"
```

---

## Task 9: Thread options through `AutoMigrator.diffAll()`

**Files:**
- Modify: `vendor/wheels/migrator/AutoMigrator.cfc`
- Modify: `vendor/wheels/tests/specs/migrator/autoMigratorSpec.cfc`

- [ ] **Step 1: Add failing test**

Add inside `autoMigratorSpec.cfc`:

```cfm
describe("diffAll() — rename integration", () => {

	it("accepts an options struct with per-model hints", () => {
		// Should not throw; models without matching adds/removes simply get no renames.
		local.result = autoMigrator.diffAll(options={
			hints: {"Author": {renames: {}}},
			heuristicThreshold: 0.7
		});
		expect(local.result).toBeStruct();
	});

	it("accepts an options struct with threshold only", () => {
		local.result = autoMigrator.diffAll(options={heuristicThreshold: 0.9});
		expect(local.result).toBeStruct();
	});

	it("is backward-compatible when called with no arguments", () => {
		local.result = autoMigrator.diffAll();
		expect(local.result).toBeStruct();
	});

});
```

- [ ] **Step 2: Run test to verify it fails**

```bash
bash tools/test-local.sh migrator
```
Expected: failures for options param not accepted.

- [ ] **Step 3: Modify `diffAll()`**

Replace signature and body of existing `public struct function diffAll()`:

```cfm
public struct function diffAll(struct options = {}) {
	local.results = {};
	local.appKey = $appKey();

	local.perModelHints = StructKeyExists(arguments.options, "hints") ? arguments.options.hints : {};
	local.threshold = StructKeyExists(arguments.options, "heuristicThreshold")
		? arguments.options.heuristicThreshold
		: 0.7;

	if (StructKeyExists(application[local.appKey], "models")) {
		for (local.modelName in application[local.appKey].models) {
			try {
				local.modelObj = model(local.modelName);

				local.tName = local.modelObj.tableName();
				if (IsBoolean(local.tName) && !local.tName) {
					continue;
				}

				// Build this model's options: {renames, heuristicThreshold}
				local.modelOptions = {heuristicThreshold: local.threshold};
				if (StructKeyExists(local.perModelHints, local.modelName)
					&& StructKeyExists(local.perModelHints[local.modelName], "renames")) {
					local.modelOptions.renames = local.perModelHints[local.modelName].renames;
				}

				local.diffResult = diff(local.modelName, local.modelOptions);

				if (
					ArrayLen(local.diffResult.addColumns)
					|| ArrayLen(local.diffResult.removeColumns)
					|| ArrayLen(local.diffResult.changeColumns)
					|| ArrayLen(local.diffResult.renameColumns)
					|| ArrayLen(local.diffResult.suggestedRenames)
				) {
					local.results[local.modelName] = local.diffResult;
				}
			} catch (any e) {
				continue;
			}
		}
	}

	return local.results;
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
bash tools/test-local.sh migrator
```
Expected: all 3 new specs pass.

- [ ] **Step 5: Commit**

```bash
git add vendor/wheels/migrator/AutoMigrator.cfc vendor/wheels/tests/specs/migrator/autoMigratorSpec.cfc
git commit -m "feat(migration): thread options through AutoMigrator.diffAll()"
```

---

## Task 10: `generateMigrationCFC()` — emit `renameColumn` in up/down

**Files:**
- Modify: `vendor/wheels/migrator/AutoMigrator.cfc`
- Modify: `vendor/wheels/tests/specs/migrator/autoMigratorSpec.cfc`

- [ ] **Step 1: Add failing tests**

Add inside `autoMigratorSpec.cfc` `describe("generateMigrationCFC()")`:

```cfm
it("emits renameColumn in up() for each renameColumns entry", () => {
	local.diffResult = {
		modelName: "TestModel",
		tableName: "test_models",
		addColumns: [],
		removeColumns: [],
		changeColumns: [],
		renameColumns: [
			{from: "full_name", to: "fullName", type: "string", source: "hint"}
		],
		suggestedRenames: []
	};
	local.cfc = autoMigrator.generateMigrationCFC(local.diffResult, "rename_name_field");
	expect(local.cfc).toInclude('renameColumn(table="test_models", columnName="full_name", newColumnName="fullName")');
});

it("emits reversed renameColumn in down() for each renameColumns entry", () => {
	local.diffResult = {
		modelName: "TestModel",
		tableName: "test_models",
		addColumns: [],
		removeColumns: [],
		changeColumns: [],
		renameColumns: [
			{from: "full_name", to: "fullName", type: "string", source: "hint"}
		],
		suggestedRenames: []
	};
	local.cfc = autoMigrator.generateMigrationCFC(local.diffResult, "rename_name_field");
	// down() reverses: fullName → full_name
	expect(local.cfc).toInclude('renameColumn(table="test_models", columnName="fullName", newColumnName="full_name")');
});

it("handles diff results without renameColumns key (backward compat)", () => {
	local.diffResult = {
		modelName: "TestModel",
		tableName: "test_models",
		addColumns: [{name: "bio", type: "text", nullable: true, "default": ""}],
		removeColumns: [],
		changeColumns: []
		// Note: no renameColumns key — simulate legacy callers
	};
	local.cfc = autoMigrator.generateMigrationCFC(local.diffResult, "add_bio");
	expect(local.cfc).toInclude('addColumn(table="test_models"');
});

it("orders up() body as renames then adds then removes then changes", () => {
	local.diffResult = {
		modelName: "TestModel",
		tableName: "test_models",
		addColumns: [{name: "bio", type: "text", nullable: true, "default": ""}],
		removeColumns: [{name: "legacy"}],
		changeColumns: [{name: "status", from: {type: "string"}, to: {type: "integer"}}],
		renameColumns: [{from: "full_name", to: "fullName", type: "string", source: "hint"}],
		suggestedRenames: []
	};
	local.cfc = autoMigrator.generateMigrationCFC(local.diffResult, "mixed");
	local.renameAt = Find("renameColumn(", local.cfc);
	local.addAt = Find("addColumn(", local.cfc);
	local.removeAt = Find('removeColumn(table="test_models", columnName="legacy"', local.cfc);
	local.changeAt = Find("changeColumn(", local.cfc);
	expect(local.renameAt).toBeGT(0);
	expect(local.renameAt).toBeLT(local.addAt);
	expect(local.addAt).toBeLT(local.removeAt);
	expect(local.removeAt).toBeLT(local.changeAt);
});
```

- [ ] **Step 2: Run test to verify it fails**

```bash
bash tools/test-local.sh migrator
```
Expected: 4 failures (renameColumn not emitted).

- [ ] **Step 3: Modify `generateMigrationCFC()`**

Edit `vendor/wheels/migrator/AutoMigrator.cfc`. At the top of the function body, after `local.downBody = "";` and **before** the existing `iEnd = ArrayLen(arguments.diffResult.addColumns);` loop, insert:

```cfm
// Emit renameColumns first in up(); reversed renames go last in down()
local.renameColumns = StructKeyExists(arguments.diffResult, "renameColumns")
	? arguments.diffResult.renameColumns
	: [];
local.iEnd = ArrayLen(local.renameColumns);
for (local.i = 1; local.i <= local.iEnd; local.i++) {
	local.r = local.renameColumns[local.i];
	local.upBody &= local.tab & local.tab
		& 'renameColumn(table="' & arguments.diffResult.tableName
		& '", columnName="' & local.r.from
		& '", newColumnName="' & local.r.to & '");' & local.nl;
}
```

Then, at the **end** of the function body just before the `if (!Len(Trim(local.upBody)))` no-op guards, append rename reversals to `downBody`:

```cfm
// Append reversed renames to down() (after other reversals)
for (local.i = 1; local.i <= ArrayLen(local.renameColumns); local.i++) {
	local.r = local.renameColumns[local.i];
	local.downBody &= local.tab & local.tab
		& 'renameColumn(table="' & arguments.diffResult.tableName
		& '", columnName="' & local.r.to
		& '", newColumnName="' & local.r.from & '");' & local.nl;
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
bash tools/test-local.sh migrator
```
Expected: all 4 new specs pass. Existing specs still pass.

- [ ] **Step 5: Commit**

```bash
git add vendor/wheels/migrator/AutoMigrator.cfc vendor/wheels/tests/specs/migrator/autoMigratorSpec.cfc
git commit -m "feat(migration): emit renameColumn in generated migrations"
```

---

## Task 11: Server-side CLI bridge — `command=diff`

**Files:**
- Modify: `vendor/wheels/public/views/cli.cfm`

The bridge view dispatches `command=*` to server-side logic and returns JSON. This task wires up `command=diff` before the CLI command can call it.

- [ ] **Step 1: Read the existing bridge pattern**

Open `vendor/wheels/public/views/cli.cfm` and find a simple `case` block as a pattern (e.g., `case "info":` around line 56). Note how it sets `local.data` and how the response JSON is built (look for `SerializeJSON` at the bottom of the file).

- [ ] **Step 2: Add a `case "diff":` block**

Insert after the existing `case "migrateToLatest":` block (around line 48):

```cfm
case "diff":
	try {
		local.autoMigrator = CreateObject("component", "wheels.migrator.AutoMigrator");
		local.options = {};

		// Parse hints from URL: hints={"renames":{"old":"new"}} as JSON-encoded string
		if (StructKeyExists(url, "hints") && Len(url.hints)) {
			local.decodedHints = DeserializeJSON(url.hints);
			if (IsStruct(local.decodedHints)) {
				StructAppend(local.options, local.decodedHints, true);
			}
		}
		if (StructKeyExists(url, "threshold") && Len(url.threshold) && IsNumeric(url.threshold)) {
			local.options.heuristicThreshold = url.threshold;
		}

		if (StructKeyExists(url, "modelName") && Len(url.modelName)) {
			local.diffResult = local.autoMigrator.diff(url.modelName, local.options);

			// Optionally write the migration file
			local.migrationWritten = "";
			if (StructKeyExists(url, "write") && url.write == "true") {
				local.migName = StructKeyExists(url, "name") && Len(url.name) ? url.name : "";
				local.autoMigrator.writeMigration(local.diffResult, local.migName);
				local.migrationWritten = "written";
			}

			local.data = {
				success: true,
				model: local.diffResult,
				migrationWritten: local.migrationWritten
			};
		} else {
			// diffAll path
			local.diffAllResult = local.autoMigrator.diffAll(local.options);

			local.written = [];
			if (StructKeyExists(url, "write") && url.write == "true") {
				for (local.m in local.diffAllResult) {
					local.autoMigrator.writeMigration(local.diffAllResult[local.m], "");
					ArrayAppend(local.written, local.m);
				}
			}

			local.data = {
				success: true,
				models: local.diffAllResult,
				migrationsWritten: local.written
			};
		}
	} catch (any e) {
		local.data = {
			success: false,
			error: e.type,
			message: e.message
		};
	}
break;
```

Check the end of `cli.cfm` to see how `local.data` is serialized into the response — typically `WriteOutput(SerializeJSON(local.data))`. If so, the new case will participate automatically.

- [ ] **Step 3: Verify bridge endpoint manually**

Start the local LuCLI server:
```bash
lucli server run --port=8080
```

In another terminal, hit the bridge with curl:
```bash
curl -s "http://localhost:8080/?controller=wheels&action=wheels&view=cli&command=diff&modelName=Author" | python3 -m json.tool
```

Expected: JSON response with `success: true` and `model: {...}`. If you see `success: false`, inspect `message` for clues.

- [ ] **Step 4: Commit**

```bash
git add vendor/wheels/public/views/cli.cfm
git commit -m "feat(migration): add diff command to CLI bridge"
```

---

## Task 12: CLI command — `wheels dbmigrate diff` (preview mode, single model)

**Files:**
- Create: `cli/src/commands/wheels/dbmigrate/diff.cfc`

- [ ] **Step 1: Create the command file**

Write `cli/src/commands/wheels/dbmigrate/diff.cfc` following the pattern from `info.cfc` and `latest.cfc`:

```cfm
/**
 * Diff
 * Generates auto-migration from model↔DB schema differences.
 **/
component aliases='wheels db diff' extends="../base" {

	property name="detailOutput" inject="DetailOutputService@wheels-cli";

	/**
	 * @modelName Optional. If omitted, runs diffAll() across all models.
	 * @rename Rename hint in the form OLD:NEW (repeatable).
	 *         For diffAll, prefix with model: User.old_col:newCol
	 * @threshold Heuristic confidence threshold (default 0.7).
	 * @write Write the migration file(s). Default: preview only.
	 * @name Migration name (single-model only).
	 * @help Generate a migration from model/DB schema differences.
	 **/
	function run(
		string modelName = "",
		string rename = "",
		numeric threshold = 0.7,
		boolean write = false,
		string name = ""
	) {
		try {
			arguments = reconstructArgs(arguments);

			// Build hints struct from --rename flags
			local.hints = $parseRenameFlags(arguments.rename, arguments.modelName);

			// Build query string
			local.qs = "&command=diff";
			if (Len(arguments.modelName)) {
				local.qs &= "&modelName=" & URLEncodedFormat(arguments.modelName);
			}
			if (!StructIsEmpty(local.hints)) {
				local.qs &= "&hints=" & URLEncodedFormat(SerializeJSON(local.hints));
			}
			local.qs &= "&threshold=" & arguments.threshold;
			if (arguments.write) {
				local.qs &= "&write=true";
				if (Len(arguments.name)) {
					local.qs &= "&name=" & URLEncodedFormat(arguments.name);
				}
			}

			local.results = $sendToCliCommand(local.qs);
			if (!local.results.success) {
				detailOutput.error(local.results.message);
				return;
			}

			if (StructKeyExists(local.results, "model")) {
				$renderSingleModelDiff(local.results.model, local.results.migrationWritten);
			} else {
				$renderDiffAll(local.results.models, local.results.migrationsWritten);
			}
		} catch (any e) {
			detailOutput.error("Failed to run diff: " & e.message);
		}
	}

	/**
	 * Parses --rename flags into a hints struct.
	 * Single-model: returns {renames: {"old": "new"}}
	 * diffAll: returns {hints: {"Model": {renames: {"old": "new"}}}}
	 */
	private struct function $parseRenameFlags(required string rename, required string modelName) {
		if (!Len(arguments.rename)) {
			return {};
		}

		local.isDiffAll = !Len(arguments.modelName);
		local.pairs = ListToArray(arguments.rename, ",");
		local.result = local.isDiffAll ? {hints: {}} : {renames: {}};

		for (local.p in local.pairs) {
			local.parts = ListToArray(local.p, ":");
			if (ArrayLen(local.parts) != 2) {
				Throw(message="invalid --rename format: '#local.p#'. Expected OLD:NEW or Model.OLD:NEW");
			}
			local.lhs = Trim(local.parts[1]);
			local.rhs = Trim(local.parts[2]);

			if (local.isDiffAll) {
				if (!Find(".", local.lhs)) {
					Throw(message="--rename for diffAll requires Model.col format, got '#local.lhs#'");
				}
				local.dot = Find(".", local.lhs);
				local.m = Left(local.lhs, local.dot - 1);
				local.col = Mid(local.lhs, local.dot + 1, Len(local.lhs));
				if (!StructKeyExists(local.result.hints, local.m)) {
					local.result.hints[local.m] = {renames: {}};
				}
				if (StructKeyExists(local.result.hints[local.m].renames, local.col)) {
					Throw(message="duplicate --rename for #local.m#.#local.col#");
				}
				local.result.hints[local.m].renames[local.col] = local.rhs;
			} else {
				if (StructKeyExists(local.result.renames, local.lhs)) {
					Throw(message="duplicate --rename for #local.lhs#");
				}
				local.result.renames[local.lhs] = local.rhs;
			}
		}

		return local.result;
	}

	private void function $renderSingleModelDiff(required struct model, string migrationWritten = "") {
		detailOutput.header("Diff for " & arguments.model.modelName & " (" & arguments.model.tableName & ")");

		if (ArrayLen(arguments.model.renameColumns)) {
			detailOutput.subHeader("Renames (will apply)");
			for (local.r in arguments.model.renameColumns) {
				print.line("  " & local.r.from & " -> " & local.r.to
					& "    [" & local.r.type & "]  (source: " & local.r.source & ")").toConsole();
			}
		}

		if (ArrayLen(arguments.model.suggestedRenames)) {
			detailOutput.subHeader("Suggested renames (pass --rename to confirm)");
			for (local.s in arguments.model.suggestedRenames) {
				local.flag = local.s.ambiguous ? " [AMBIGUOUS]" : "";
				print.line("  " & local.s.from & " -> " & local.s.to
					& "    [" & local.s.type & "]  confidence: "
					& NumberFormat(local.s.confidence, "0.00") & local.flag).toConsole();
				print.line("    wheels dbmigrate diff " & arguments.model.modelName
					& " --rename=" & local.s.from & ":" & local.s.to).toConsole();
			}
		}

		if (ArrayLen(arguments.model.addColumns)) {
			detailOutput.subHeader("Adds");
			for (local.a in arguments.model.addColumns) {
				print.line("  + " & local.a.name & "    [" & local.a.type & "]").toConsole();
			}
		}

		if (ArrayLen(arguments.model.removeColumns)) {
			// Build a set of column names that appear as "from" in suggestedRenames
			// so we can add a pointer hint to the remove line.
			local.suggestedFroms = {};
			for (local.s in arguments.model.suggestedRenames) {
				local.suggestedFroms[LCase(local.s.from)] = true;
			}

			detailOutput.subHeader("Removes");
			for (local.rm in arguments.model.removeColumns) {
				local.suffix = StructKeyExists(local.suggestedFroms, LCase(local.rm.name))
					? "    (will DROP - use --rename if this is actually a rename)"
					: "    (will DROP)";
				print.line("  - " & local.rm.name & local.suffix).toConsole();
			}
		}

		if (ArrayLen(arguments.model.changeColumns)) {
			detailOutput.subHeader("Changes");
			for (local.c in arguments.model.changeColumns) {
				print.line("  ~ " & local.c.name & "    " & local.c.from.type & " -> " & local.c.to.type).toConsole();
			}
		}

		print.line("").toConsole();
		if (Len(arguments.migrationWritten)) {
			detailOutput.statusSuccess("Migration file written. Run 'wheels dbmigrate latest' to apply.");
		} else {
			print.yellowLine("Preview only - no migration file written. Pass --write to commit.").toConsole();
		}
	}

	private void function $renderDiffAll(required struct models, required array migrationsWritten) {
		local.count = StructCount(arguments.models);
		if (local.count == 0) {
			print.greenLine("No changes detected across all models.").toConsole();
			return;
		}
		detailOutput.header("Diff across " & local.count & " model(s) with changes");
		for (local.name in arguments.models) {
			print.line("").toConsole();
			$renderSingleModelDiff(arguments.models[local.name], "");
		}
		print.line("").toConsole();
		if (ArrayLen(arguments.migrationsWritten)) {
			detailOutput.statusSuccess("Wrote migrations for: " & ArrayToList(arguments.migrationsWritten, ", "));
		} else {
			print.yellowLine("Preview only - no migration files written. Pass --write to commit.").toConsole();
		}
	}

}
```

- [ ] **Step 2: Reload CommandBox to pick up the new command**

```bash
box reload
```

- [ ] **Step 3: Manual smoke test — preview mode, single model**

With a running app server:

```bash
wheels dbmigrate diff Author
```

Expected: preview output showing the structure. Either "No changes detected" or a diff summary depending on DB state. No errors.

- [ ] **Step 4: Manual smoke test — with --rename**

```bash
wheels dbmigrate diff Author --rename=nonexistent:column
```

Expected: error message from bridge (InvalidRenameHint). Exit code non-zero.

- [ ] **Step 5: Commit**

```bash
git add cli/src/commands/wheels/dbmigrate/diff.cfc
git commit -m "feat(cli): add wheels dbmigrate diff command"
```

---

## Task 13: CLI `--write` + `--name` — commit the migration file

**Files:** (none — all functionality wired in Task 12)

This task is a validation checkpoint that ensures `--write` generates a file.

- [ ] **Step 1: Manual smoke test — --write flag**

With a model that has a real pending change (e.g., add a property `t.string("bio")` to a test model backed by a table missing that column):

```bash
wheels dbmigrate diff Author --write --name=test_write
```

Expected:
- Preview output same as Task 12.
- "Migration file written" status line.
- New file `app/migrator/migrations/<timestamp>_test_write.cfc` exists.

- [ ] **Step 2: Verify file contents**

```bash
cat app/migrator/migrations/*test_write.cfc
```

Expected: valid migration CFC with `up()` and `down()`, extends `wheels.migrator.Migration`.

- [ ] **Step 3: Cleanup**

```bash
rm app/migrator/migrations/*test_write.cfc
```

- [ ] **Step 4: Commit (if any fixes needed)**

If smoke tests pass without changes, no commit. Otherwise fix issues in `diff.cfc` and commit:

```bash
git add cli/src/commands/wheels/dbmigrate/diff.cfc
git commit -m "fix(cli): diff --write flag edge cases"
```

---

## Task 14: CLI diffAll mode (no modelName) — model.col prefix for hints

**Files:** (none — already wired in Task 12)

This task is a validation checkpoint.

- [ ] **Step 1: Manual smoke test — no modelName**

```bash
wheels dbmigrate diff
```

Expected: either "No changes detected" or a multi-model diff summary.

- [ ] **Step 2: Manual smoke test — Model.col prefix**

```bash
wheels dbmigrate diff --rename=Author.old_col:newCol
```

Expected: either error "column not in removed-columns set" or, with a real mismatch, a confirmed rename in the preview.

- [ ] **Step 3: Manual smoke test — diffAll with invalid plain hint**

```bash
wheels dbmigrate diff --rename=plain_col:newCol
```

Expected: error "--rename for diffAll requires Model.col format".

- [ ] **Step 4: Commit (if any fixes needed)**

```bash
git add cli/src/commands/wheels/dbmigrate/diff.cfc
git commit -m "fix(cli): diff --rename Model.col parsing"
```

---

## Task 15: MCP `action="diff"` handler

**Files:**
- Modify: `vendor/wheels/public/mcp/McpServer.cfc`

- [ ] **Step 1: Identify the insertion point**

Open `vendor/wheels/public/mcp/McpServer.cfc`. Find `executeWheelsMigrate()` (around line 1202). Note the switch statement on `arguments.args.action`.

- [ ] **Step 2: Update the action validation list**

In `executeWheelsMigrate()`, find the description string around line 747 and the error message at line 1227. Update "info, latest, up, down, reset" to "info, latest, up, down, reset, diff".

- [ ] **Step 3: Add `case "diff":` to the switch**

Insert before the `default:` case:

```cfm
case "diff":
	return $executeMigrationDiff(arguments.args);
```

- [ ] **Step 4: Implement `$executeMigrationDiff` helper**

Add the helper method inside the component (near `executeMigrationUp`/`executeMigrationDown`):

```cfm
private string function $executeMigrationDiff(required struct args) {
	try {
		local.qs = "&command=diff";
		if (StructKeyExists(arguments.args, "modelName") && Len(arguments.args.modelName)) {
			if (!$isValidType(arguments.args.modelName)) {
				return SerializeJSON({success: false, error: "InvalidInput", message: "Invalid modelName"});
			}
			local.qs &= "&modelName=" & URLEncodedFormat(arguments.args.modelName);
		}
		if (StructKeyExists(arguments.args, "hints") && IsStruct(arguments.args.hints)) {
			local.qs &= "&hints=" & URLEncodedFormat(SerializeJSON(arguments.args.hints));
		}
		if (StructKeyExists(arguments.args, "heuristicThreshold") && IsNumeric(arguments.args.heuristicThreshold)) {
			local.qs &= "&threshold=" & arguments.args.heuristicThreshold;
		}
		if (StructKeyExists(arguments.args, "write") && IsBoolean(arguments.args.write) && arguments.args.write) {
			local.qs &= "&write=true";
		}

		local.currentPort = $getLocalPort();
		local.baseUrl = "http://localhost:" & local.currentPort
			& "/?controller=wheels&action=wheels&view=cli" & local.qs;

		local.http = new Http(url=local.baseUrl).send().getPrefix();
		if (!IsJSON(local.http.filecontent)) {
			return SerializeJSON({success: false, error: "BridgeError", message: "Non-JSON response from bridge"});
		}
		// Passthrough — bridge already returns the envelope we want.
		return local.http.filecontent;

	} catch (any e) {
		return SerializeJSON({success: false, error: e.type, message: e.message});
	}
}
```

- [ ] **Step 5: Test via MCP endpoint**

With the server running:

```bash
curl -sX POST http://localhost:8080/wheels/mcp \
	-H "Content-Type: application/json" \
	-d '{"tool":"wheels_migrate","args":{"action":"diff","modelName":"Author"}}' \
	| python3 -m json.tool
```

Expected: JSON with `success: true`. Either `model: {...}` or an error envelope if DB state implies it.

- [ ] **Step 6: Commit**

```bash
git add vendor/wheels/public/mcp/McpServer.cfc
git commit -m "feat(migration): expose auto-migration diff through MCP"
```

---

## Task 16: Update `docs/wheels-vs-frameworks.md`

**Files:**
- Modify: `docs/wheels-vs-frameworks.md`

- [ ] **Step 1: Move item 6 from Trails to Leads**

In `docs/wheels-vs-frameworks.md`, locate the "Where Wheels Trails" section (around line 264). Delete item 6 ("Migration rename detection — ...").

Renumber the remaining items in that list (items after 6 shift up by one).

In the "Where Wheels Leads" section (around line 246), append as item 16:

```markdown
16. **Auto-migration rename detection** — `AutoMigrator.diff()` accepts
    explicit rename hints AND runs heuristic similarity analysis
    (normalized-token + Levenshtein) to suggest likely renames. Rails
    requires manual `rename_column`; Django uses interactive CLI only.
    Wheels offers both programmatic hints and automatic suggestions in
    the diff engine.
```

- [ ] **Step 2: Update the Migrations table**

Find the row in section 2's table (around line 52):

```
| Auto-generation | Via CLI generators + `AutoMigrator` (model→DB schema diff) | Via CLI generators | Via CLI generators | `makemigrations` (auto from models) |
```

Change to:

```
| Auto-generation | Via CLI generators + `AutoMigrator` (model→DB schema diff + rename detection) | Via CLI generators | Via CLI generators | `makemigrations` (auto from models) |
```

- [ ] **Step 3: Update the "Wheels auto-migrations" callout**

Find the callout around line 56:

```markdown
**Wheels auto-migrations:** `AutoMigrator.diff(modelName)` compares model property definitions against the current DB schema and returns add/remove/change column lists. `generateMigrationCFC()` produces a migration CFC with both up() and down() methods. Limitations: cannot detect column renames (always generates remove+add), calculated properties excluded.
```

Replace with:

```markdown
**Wheels auto-migrations:** `AutoMigrator.diff(modelName, options)` compares model property definitions against the current DB schema and returns add/remove/change/rename column lists. Renames are detected via explicit hints (`options.renames={"old":"new"}`) plus heuristic suggestions (normalized-token + Levenshtein, configurable threshold). `generateMigrationCFC()` produces a migration CFC with both up() and down() methods, emitting `renameColumn` calls for confirmed renames. Calculated properties excluded from diff.
```

- [ ] **Step 4: Add to "Recently Closed Gaps"**

Find the "Recently Closed Gaps (April 2026)" section (around line 273) and append:

```markdown
- **Auto-migration rename detection** ([#XXXX](https://github.com/wheels-dev/wheels/pull/XXXX)) — explicit hints + heuristic suggestions via `AutoMigrator`, new `wheels dbmigrate diff` CLI command, MCP `wheels_migrate(action="diff")`
```

Replace `#XXXX` with the actual PR number when the PR is opened.

- [ ] **Step 5: Commit**

```bash
git add docs/wheels-vs-frameworks.md
git commit -m "docs: move rename detection from Trails to Leads"
```

---

## Task 17: Create `dbmigrate-diff.md` reference page

**Files:**
- Create: `docs/src/command-line-tools/commands/database/dbmigrate-diff.md`

- [ ] **Step 1: Read a template reference page**

Read `docs/src/command-line-tools/commands/database/dbmigrate-latest.md` to note the structure: heading, Synopsis, Description, Parameters, How It Works, Example Output, See Also sections.

- [ ] **Step 2: Write the new reference page**

Create `docs/src/command-line-tools/commands/database/dbmigrate-diff.md`:

````markdown
# wheels dbmigrate diff

Generate an auto-migration from model/DB schema differences with rename detection.

## Synopsis

```bash
wheels dbmigrate diff [modelName] [--rename=OLD:NEW] [--threshold=0.7] [--write] [--name=NAME]
```

Alias: `wheels db diff`

## Description

`wheels dbmigrate diff` compares a model's property definitions against the current database schema and generates a migration CFC describing the differences. Unlike simple schema diffs, it detects **column renames** via two mechanisms:

1. **Explicit hints** (`--rename=OLD:NEW`) — you assert which removed column maps to which added column. Always authoritative.
2. **Heuristic suggestions** — the detector pairs unclaimed removes with unclaimed adds using normalized-token match + Levenshtein scoring. Unambiguous exact matches (score 1.0) auto-confirm; lower scores appear as suggestions requiring `--rename` to commit.

By default the command runs in **preview mode** — it prints what would change and does not touch the filesystem. Pass `--write` to emit a migration CFC to `app/migrator/migrations/`.

## Parameters

| Parameter | Description |
|---|---|
| `modelName` | Optional. Model to diff. Omit to run `diffAll()` across all models. |
| `--rename=OLD:NEW` | Rename hint. Repeatable. For `diffAll`, prefix with the model name: `--rename=User.old_col:newCol`. |
| `--threshold=0.7` | Heuristic confidence cutoff. Range [0.0, 1.0]. |
| `--write` | Write the migration file(s). Default: preview only. |
| `--name=NAME` | Migration filename suffix. Single-model only. Default: `auto_<model>_changes`. |

## How It Works

1. The command sends a request to the running Wheels server.
2. The server calls `AutoMigrator.diff(modelName, options)` or `diffAll(options)`.
3. The diff engine:
   - Computes raw adds/removes/changes by comparing model properties to DB columns.
   - Applies explicit hints: each hint pair is validated (columns exist, types match) and moved into `renameColumns`.
   - Runs heuristic similarity on remaining adds/removes.
   - Pre-counts ambiguity across the candidate pool; greedy-assigns pairs by confidence.
   - Score 1.0 unambiguous pairs auto-confirm; everything else is a suggestion.
4. CLI renders a human-readable preview. If `--write`, the generated CFC is saved.

## Example Output

### Preview with a hint

```
$ wheels dbmigrate diff User --rename=full_name:fullName

Diff for User (users)

  Renames (will apply)
    full_name -> fullName    [string]  (source: hint)
    user_name -> username    [string]  (source: heuristic)

  Suggested renames (pass --rename to confirm)
    email_addr -> emailAddress    [string]  confidence: 0.75
      wheels dbmigrate diff User --rename=email_addr:emailAddress

  Adds
    + bio    [text]

  Removes
    - legacy_flag    (will DROP)

Preview only - no migration file written. Pass --write to commit.
```

### Ambiguous suggestion

```
  Suggested renames (pass --rename to confirm)
    full_name -> fullName       [string]  confidence: 1.00 [AMBIGUOUS]
      wheels dbmigrate diff User --rename=full_name:fullName
    full_name -> displayName    [string]  confidence: 0.73 [AMBIGUOUS]
      wheels dbmigrate diff User --rename=full_name:displayName
```

Even a score-1.0 match is demoted to a suggestion when it's part of an ambiguous set. Supply an explicit `--rename` to disambiguate.

### Write mode

```
$ wheels dbmigrate diff User --rename=full_name:fullName --write

[preview output]

Migration file written. Run 'wheels dbmigrate latest' to apply.
```

### diffAll (no modelName)

```
$ wheels dbmigrate diff

Diff across 3 model(s) with changes

Diff for User (users)
  Renames (will apply): full_name -> fullName
  Adds: bio
  Removes: legacy_flag

Diff for Post (posts)
  Suggested renames: body_text -> body (confidence 0.88)
  pass --rename=Post.body_text:body to confirm

Preview only - no migration files written. Pass --write to commit.
```

## Limitations

- **Primary keys are never renamed.** PKs are excluded from the detector's input.
- **Rename + type change requires separate migrations.** If a hint's pair has mismatched types, the command errors with `Wheels.RenameHintTypeMismatch`.
- **Calculated properties** (defined via `property(sql="...")`) are excluded from the diff entirely.
- **Column rename detection is name-based.** Content-based detection (comparing data) is not performed.

## Errors

| Error | Cause |
|---|---|
| `Wheels.InvalidRenameHint` | Hint references a column not in the removed-columns or added-columns set. |
| `Wheels.RenameHintTypeMismatch` | Hint pair has different migration types. |
| `Wheels.DuplicateRenameHint` | Two hints point to the same destination column. |
| `Wheels.InvalidThreshold` | `--threshold` outside [0, 1]. |

## See Also

- [wheels dbmigrate latest](dbmigrate-latest.md) — apply pending migrations
- [wheels dbmigrate info](dbmigrate-info.md) — migration status
- [wheels dbmigrate create column](dbmigrate-create-column.md) — manually scaffold a column-change migration
````

- [ ] **Step 3: Commit**

```bash
git add docs/src/command-line-tools/commands/database/dbmigrate-diff.md
git commit -m "docs: add dbmigrate diff command reference"
```

---

## Task 18: Update `migrations.md` CLI guide

**Files:**
- Modify: `docs/src/command-line-tools/cli-guides/migrations.md`

- [ ] **Step 1: Find the insertion point**

Open `docs/src/command-line-tools/cli-guides/migrations.md`. Locate the "Creating Migrations" section and the section that follows it ("Migration Best Practices" or similar). Insert the new section between them.

- [ ] **Step 2: Insert the auto-migration section**

Add this section after "Creating Migrations":

````markdown
## Auto-Generating Migrations from Models

When you're evolving a model — adding properties, renaming columns, changing types — you can let `wheels dbmigrate diff` generate the migration for you instead of writing it by hand. It compares your model's property definitions against the live database schema and emits the appropriate `addColumn`, `removeColumn`, `changeColumn`, and `renameColumn` calls.

### Basic Workflow

1. Edit your model (add/rename properties, change types).
2. Run `wheels dbmigrate diff ModelName` to preview the migration.
3. If the preview looks right, run with `--write` to commit the CFC.
4. Run `wheels dbmigrate latest` to apply.

```bash
wheels dbmigrate diff User              # preview
wheels dbmigrate diff User --write      # write migration file
wheels dbmigrate latest                 # apply
```

### Rename Detection

The diff engine detects column renames in two ways:

**Explicit hints** — tell it which old column maps to which new column:

```bash
wheels dbmigrate diff User --rename=full_name:fullName
```

**Heuristic suggestions** — the engine analyzes unclaimed removes and adds, scoring them by normalized-token match + Levenshtein edit distance. Unambiguous exact matches (e.g., `full_name` ↔ `fullName`) auto-confirm. Lower-confidence or ambiguous candidates are emitted as suggestions that require `--rename` to commit.

Example output:

```
Suggested renames (pass --rename to confirm)
  email_addr -> emailAddress    [string]  confidence: 0.75
    wheels dbmigrate diff User --rename=email_addr:emailAddress
```

### Ambiguity

When multiple renames are plausible, the engine flags them as `AMBIGUOUS` and never auto-confirms:

```
Suggested renames (pass --rename to confirm)
  full_name -> fullName       [string]  confidence: 1.00 [AMBIGUOUS]
  full_name -> displayName    [string]  confidence: 0.73 [AMBIGUOUS]
```

Resolve by specifying the intended pair explicitly.

### All-Models Mode

Omit the model name to diff every model:

```bash
wheels dbmigrate diff                            # preview all changes
wheels dbmigrate diff --write                    # one migration per changed model
wheels dbmigrate diff --rename=User.full_name:fullName    # scoped hint
```

### Tuning the Heuristic

The default threshold is `0.7`. Lower it to see more speculative suggestions; raise it for stricter matching:

```bash
wheels dbmigrate diff User --threshold=0.85    # strict: only close matches suggested
wheels dbmigrate diff User --threshold=0.5     # permissive: more suggestions
```

### Limitations

- Primary key renames are not detected (PKs are excluded from the input).
- Rename + type change in a single step is refused. Rename first, then change the type in a separate migration.
- Calculated properties (`property(sql="...")`) are excluded from the diff entirely.
- Detection is name-based; the engine does not compare row data.
````

- [ ] **Step 3: Commit**

```bash
git add docs/src/command-line-tools/cli-guides/migrations.md
git commit -m "docs: add auto-migration guide to migrations CLI doc"
```

---

## Task 19: Update database-migrations/README.md

**Files:**
- Modify: `docs/src/database-interaction-through-models/database-migrations/README.md`

- [ ] **Step 1: Find the insertion point**

Open `docs/src/database-interaction-through-models/database-migrations/README.md` and navigate to the end of the file (around line 190+). Insert a new section at the bottom.

- [ ] **Step 2: Append the auto-migration tutorial section**

```markdown
## Auto-Migration: Generate from Model Changes

Wheels can generate migrations for you from your model changes. Instead of writing `addColumn`/`removeColumn` calls by hand, edit the model, run `wheels dbmigrate diff`, and let the framework produce the CFC.

### Walk-Through

Suppose you have a `User` model and decide to:
- Rename the `full_name` column to `fullName`
- Add a `bio` column
- Remove the legacy `legacy_flag` column

Edit `app/models/User.cfc` to reflect the new shape (via property definitions, associations, etc.), then run:

```bash
wheels dbmigrate diff User
```

You'll see a preview:

```
Diff for User (users)

  Renames (will apply)
    full_name -> fullName    [string]  (source: heuristic)

  Adds
    + bio    [text]

  Removes
    - legacy_flag    (will DROP)

Preview only - no migration file written. Pass --write to commit.
```

Because `full_name` and `fullName` normalize to the same token, the detector auto-confirmed the rename. If you'd instead renamed `email_addr` to `emailAddress`, the engine would ask you to confirm with `--rename`:

```
Suggested renames (pass --rename to confirm)
  email_addr -> emailAddress    [string]  confidence: 0.75
    wheels dbmigrate diff User --rename=email_addr:emailAddress
```

When the preview looks right, commit:

```bash
wheels dbmigrate diff User --write
```

This writes a file like `app/migrator/migrations/20260415093052123_auto_user_changes.cfc` with both `up()` and `down()` methods. Apply it the usual way:

```bash
wheels dbmigrate latest
```

### When to Use

Auto-migration is best when:
- You've made straightforward property changes to a model.
- You want a starting point for a migration (you can still hand-edit the generated CFC before applying).
- You're running in development and want fast iteration.

For production migrations involving complex data transformations, hand-written migrations remain the right tool.

### Programmatic API

The CLI wraps `AutoMigrator`, which you can also call directly:

```cfm
var autoMigrator = CreateObject("component", "wheels.migrator.AutoMigrator");
var diffResult = autoMigrator.diff("User", {renames: {"full_name": "fullName"}});
autoMigrator.writeMigration(diffResult, "rename_name_field");
```

See the [wheels dbmigrate diff](../../command-line-tools/commands/database/dbmigrate-diff.md) reference for all options.
```

- [ ] **Step 3: Commit**

```bash
git add docs/src/database-interaction-through-models/database-migrations/README.md
git commit -m "docs: add auto-migration tutorial to migrations guide"
```

---

## Task 20: Update `CLAUDE.md`

**Files:**
- Modify: `CLAUDE.md` (root project file)

- [ ] **Step 1: Find the Migrations reference area**

Open `CLAUDE.md` in the repo root. There is no dedicated "Migrations Quick Reference" section currently. Find the "Database Seeding Quick Reference" section and add a new "Auto-Migration Quick Reference" section immediately above it.

- [ ] **Step 2: Insert the section**

````markdown
## Auto-Migration Quick Reference

Generate migrations from model/DB schema diffs. Rename detection via explicit hints (authoritative) + heuristic suggestions (normalized-token + Levenshtein).

```cfm
// Programmatic
var am = CreateObject("component", "wheels.migrator.AutoMigrator");

// Single model
var d = am.diff("User");
var d = am.diff("User", {renames: {"full_name": "fullName"}});
var d = am.diff("User", {heuristicThreshold: 0.85});

// All models (per-model hints keyed by model name)
var all = am.diffAll({
    hints: {"User": {renames: {"full_name": "fullName"}}},
    heuristicThreshold: 0.7
});

// Write migration CFC from diff result
am.writeMigration(d, "rename_name_field");
```

```bash
# CLI
wheels dbmigrate diff User                                    # preview
wheels dbmigrate diff User --rename=full_name:fullName        # with hint
wheels dbmigrate diff User --write --name=rename_name         # commit file
wheels dbmigrate diff --threshold=0.85                        # all models, stricter
wheels dbmigrate diff --rename=User.full_name:fullName        # diffAll hint
```

**Diff result struct:**
```
{modelName, tableName,
 addColumns, removeColumns, changeColumns,        // pruned of rename pairs
 renameColumns,       // confirmed renames (emitted into up/down)
 suggestedRenames}    // heuristic candidates for display
```

**Limits:** PK renames not detected; rename + type change requires separate migrations; calculated properties excluded from diff.
````

- [ ] **Step 3: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: add auto-migration quick reference to CLAUDE.md"
```

---

## Task 21: Cross-engine verification

**Files:** (none — verification task)

- [ ] **Step 1: Run the full migrator suite on Lucee 7 + SQLite**

```bash
bash tools/test-local.sh migrator
```

Expected: all specs pass (existing + new). If any fail, fix before proceeding.

Expected spec count increase: ~45 new RenameDetector specs + ~10 AutoMigrator additions = ~55 new passing specs beyond the pre-existing count.

- [ ] **Step 2: Run the full core test suite on Lucee 7**

```bash
bash tools/test-local.sh
```

Expected: no regressions. Pre-feature baseline pass count should remain unchanged modulo the ~55 additions.

- [ ] **Step 3: Run on Adobe CF 2025 via Docker**

```bash
cd rig
docker compose up -d adobe2025
# Wait ~60 seconds for startup
curl -s -o /tmp/adobe2025-results.json "http://localhost:62025/wheels/core/tests?db=sqlite&format=json"
python3 -c "
import json
d = json.load(open('/tmp/adobe2025-results.json'))
print(f'adobe2025: {d[\"totalPass\"]} pass, {d[\"totalFail\"]} fail, {d[\"totalError\"]} error')
for b in d.get('bundleStats',[]):
  for s in b.get('suiteStats',[]):
    for sp in s.get('specStats',[]):
      if sp.get('status') in ('Failed','Error') and 'migrator' in b.get('bundlePath','').lower():
        print(f'  {sp[\"status\"]}: {sp[\"name\"]}: {sp.get(\"failMessage\",\"\")[:120]}')
"
```

Expected: 0 failures in migrator specs. The Levenshtein pure-CFML implementation is the primary cross-engine risk — watch for string-handling differences in `Mid()`, `Left()`, array indexing.

- [ ] **Step 4: Manual CLI verification on Lucee 7**

With LuCLI server running:

```bash
wheels dbmigrate diff                                   # all models preview
wheels dbmigrate diff Author                            # single model preview
wheels dbmigrate diff Author --rename=foo:bar           # invalid hint → error
```

Expected: first two commands print preview; third returns a clear `InvalidRenameHint` error.

- [ ] **Step 5: Manual MCP verification**

```bash
curl -sX POST http://localhost:8080/wheels/mcp \
	-H "Content-Type: application/json" \
	-d '{"tool":"wheels_migrate","args":{"action":"diff","modelName":"Author"}}' \
	| python3 -m json.tool
```

Expected: JSON envelope with `success: true` and `model: {...}`.

- [ ] **Step 6: Cleanup**

```bash
cd rig && docker compose down
```

- [ ] **Step 7: Commit release-note-ready summary (optional)**

If this PR is going to trigger release notes automatically, ensure commit messages across tasks use the correct scopes:
- `feat(migration):` for AutoMigrator / RenameDetector / cli.cfm changes
- `feat(cli):` for `cli/src/commands/wheels/dbmigrate/diff.cfc`
- `docs:` for all documentation
- `test(migration):` for pure test additions

No additional commit needed for this step — all commits already landed.

---

## Summary

**21 tasks:**
- Tasks 1-7: `RenameDetector.cfc` with full TDD coverage (pure logic, ~45 specs)
- Tasks 8-10: `AutoMigrator` integration (diff, diffAll, generateMigrationCFC)
- Tasks 11-15: CLI + MCP + server bridge
- Tasks 16-20: Documentation (comparison doc, user docs, CLAUDE.md)
- Task 21: Cross-engine + CLI + MCP verification

**Commit discipline:** one commit per task. Commit scopes follow commitlint rules (`migration`, `cli`, `docs`, `test`). All subjects lowercase.

**Breaking change scope:** none. All new parameters optional. Previously drop+add-producing model rename scenarios will now produce `renameColumn` when heuristic confirms at confidence 1.0 — documented in release notes as an intentional behavior improvement.
