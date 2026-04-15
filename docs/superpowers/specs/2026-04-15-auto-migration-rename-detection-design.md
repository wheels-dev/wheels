# Auto-Migration Rename Detection — Design

**Status:** Approved
**Date:** 2026-04-15
**Target release:** Wheels v4.0
**Closes:** Item 6 in `docs/wheels-vs-frameworks.md` "Where Wheels Trails"

## 1. Problem

`AutoMigrator.diff()` compares model property definitions against the current
database schema and emits `addColumns` / `removeColumns` / `changeColumns`.
Column renames are indistinguishable from drop+add at the schema level, so
renaming `full_name` to `fullName` in a model produces a migration that drops
the original column and recreates a new one — losing data.

Rails solves this by requiring hand-written `rename_column` calls. Django
solves it with an interactive CLI prompt. Wheels has no rename story at all.

This design adds rename detection to Wheels that is stronger than Rails
(explicit hints + heuristic suggestions), works programmatically (unlike
Django's interactive-only flow), and integrates with CLI + MCP so AI-driven
workflows can use it end-to-end.

## 2. Goals

1. Detect column renames in `AutoMigrator.diff()` and emit
   `renameColumn()` calls in generated migration CFCs.
2. Support two detection modes, both active simultaneously:
   - **Explicit hints** — user asserts `{renames: {"oldCol": "newCol"}}`.
     Always wins; raises on invalid hints.
   - **Heuristic suggestions** — AutoMigrator proposes likely renames based
     on normalized-token + Levenshtein similarity of unclaimed adds/removes.
     Auto-confirms only for unambiguous exact-normalized-token matches
     (confidence 1.0); all lower-confidence or ambiguous candidates are
     emitted as informational `suggestedRenames` and require explicit
     hints to commit.
3. Expose the capability through the new `wheels dbmigrate diff` CLI command
   and extend the MCP `wheels_migrate` tool with `action="diff"`.
4. Backward-compatible API — all new parameters optional; existing
   `diff()` / `diffAll()` / `generateMigrationCFC()` callers continue to
   work unchanged. **Intentional behavioral change**: a model rename that
   previously produced drop+add will now produce `renameColumn` when the
   heuristic confirms it (score 1.0, unambiguous). Documented in release
   notes.

## 3. Non-goals

- **Auto-apply heuristic renames below confidence 1.0.** User must confirm
  via hints. False positives destroy data.
- **Rename + type change in one migration.** If hint pair has mismatched
  types, raise. User must perform rename and retype as separate migrations.
- **Primary key renames.** `diff()` already excludes PKs from removes.
- **Column-statistics-based detection** (comparing row data, hashes, etc.).
  Out of scope; future work.
- **Interactive CLI prompt (Django-style).** Out of scope; the hints + write
  model handles the confirmation loop without blocking stdin.

## 4. File layout

```
vendor/wheels/migrator/
  AutoMigrator.cfc              [MODIFIED]  Adds options param, emits renameColumns
  RenameDetector.cfc            [NEW]       Pure-logic detection engine
  Migration.cfc                 [unchanged] renameColumn() already exists (line 234)

cli/src/commands/wheels/dbmigrate/
  diff.cfc                      [NEW]       wheels dbmigrate diff command

vendor/wheels/public/mcp/
  McpServer.cfc                 [MODIFIED]  Extends wheels_migrate with action=diff

vendor/wheels/tests/specs/migrator/
  renameDetectorSpec.cfc        [NEW]       Pure-logic unit tests
  autoMigratorSpec.cfc          [MODIFIED]  Rename integration tests

docs/
  wheels-vs-frameworks.md       [MODIFIED]  Move item 6 from Trails to Leads
  src/command-line-tools/
    commands/database/dbmigrate-diff.md           [NEW]
    cli-guides/migrations.md                      [MODIFIED]
  src/database-interaction-through-models/
    database-migrations/README.md                 [MODIFIED]
CLAUDE.md                       [MODIFIED]  Auto-migration quick reference
```

## 5. Responsibility split

| Component | Responsibility |
|---|---|
| `RenameDetector` | Similarity scoring, pair resolution, hint validation, ambiguity flagging. Pure functions; no DB/model dependencies. Fully unit-testable in isolation. |
| `AutoMigrator` | Schema introspection, diff orchestration, migration CFC generation. Delegates rename logic to `RenameDetector` after computing raw adds/removes. |
| `dbmigrate diff.cfc` | Argument parsing, hint flag interpretation (`--rename=OLD:NEW`), preview-vs-write flow, human-readable output. |
| `McpServer` | JSON in/out wrapper for `AutoMigrator.diff()` and `diffAll()` via new `action="diff"`. |

## 6. Public API

### 6.1 `RenameDetector.cfc`

```cfm
component {
    /**
     * Pairs added columns with removed columns based on explicit hints
     * and heuristic similarity. Pure function.
     *
     * @addColumns    Array of {name, type, nullable, default} from AutoMigrator.
     * @removeColumns Array of {name} from AutoMigrator.
     * @addTypes      Struct keyed by add column name -> migration type.
     * @removeTypes   Struct keyed by remove column name -> migration type.
     * @hints         Struct: {renames: {"oldCol": "newCol", ...}}
     * @threshold     Heuristic confidence cutoff (default 0.7).
     * @return Struct {confirmedRenames, suggestedRenames, remainingAdds, remainingRemoves}.
     */
    public struct function detect(
        required array addColumns,
        required array removeColumns,
        required struct addTypes,
        required struct removeTypes,
        struct hints = {},
        numeric threshold = 0.7
    );

    public numeric function $score(required string nameA, required string nameB);
    public string function $normalizeToken(required string name);
    public numeric function $levenshtein(required string a, required string b);
}
```

Return struct:

```cfm
{
    confirmedRenames: [
        {from: "full_name", to: "fullName", type: "string", source: "hint" | "heuristic"}
    ],
    suggestedRenames: [
        {from: "email_addr", to: "emailAddress", type: "string",
         confidence: 0.75, ambiguous: false}
    ],
    remainingAdds:    [...],  // subset of addColumns not consumed
    remainingRemoves: [...]   // subset of removeColumns not consumed
}
```

### 6.2 `AutoMigrator.cfc` (modifications)

```cfm
// Existing signatures gain optional options arg
public struct function diff(
    required string modelName,
    struct options = {}   // {renames: {...}, heuristicThreshold: 0.7}
);

public struct function diffAll(
    struct options = {}   // {hints: {"User": {renames: {...}}}, heuristicThreshold: 0.7}
);
```

`generateMigrationCFC(diffResult, migrationName)` signature unchanged; internally
emits `renameColumn(...)` from `renameColumns` before adds/removes.

Diff result struct (existing keys preserved, two keys added):

```cfm
{
    modelName, tableName,
    addColumns, removeColumns, changeColumns,   // existing (pruned of rename pairs)
    renameColumns,        // NEW - confirmed renames (emitted into up/down)
    suggestedRenames      // NEW - heuristic candidates for caller display
}
```

## 7. Data flow

### 7.1 `diff("User", {renames: {"full_name": "fullName"}})`

1. Build `expectedColumns` from model props (existing).
2. Build `actualColumns` from `$dbinfo` (existing).
3. Compute raw `addColumns`, `removeColumns`, `changeColumns` (existing).
4. Build `addTypes{}` and `removeTypes{}` lookup structs (new).
5. Call `RenameDetector.detect(adds, removes, addTypes, removeTypes, hints, threshold)`.
6. `RenameDetector` returns `{confirmedRenames, suggestedRenames, remainingAdds, remainingRemoves}`.
7. AutoMigrator returns enriched result:
   - `addColumns` = `remainingAdds`
   - `removeColumns` = `remainingRemoves`
   - `renameColumns` = `confirmedRenames`
   - `suggestedRenames` = `suggestedRenames`
   - `changeColumns` = unchanged (renames operate on identity, not type)

### 7.2 `generateMigrationCFC(diffResult, name)`

`up()` body order:

1. `renameColumns` -> `renameColumn(table, columnName, newColumnName)`
2. `addColumns` -> `addColumn(...)` (existing)
3. `removeColumns` -> `removeColumn(...)` (existing)
4. `changeColumns` -> `changeColumn(...)` (existing)

`down()` body (reverse order, reverse op):

1. `changeColumns` -> reverse changeColumn (existing)
2. `removeColumns` -> `// TODO` comment (existing)
3. `addColumns` -> `removeColumn(...)` (existing)
4. `renameColumns` -> `renameColumn(table, newColumnName, columnName)` (reversed)

### 7.3 `wheels dbmigrate diff User --rename=full_name:fullName --write`

1. CLI parses `--rename` flags into `hints.renames` struct.
2. CLI parses `--threshold`, `--name`, `--write`.
3. CLI invokes AutoMigrator via HTTP ping to running server (existing CLI pattern).
4. Server: `AutoMigrator.diff(modelName, options)`.
5. CLI prints formatted preview: renames, suggestions, adds, removes, changes.
6. If `--write`: call `writeMigration(result, name)`; print filename.
7. Exit 0 on success; 1 on hint validation errors.

### 7.4 MCP `wheels_migrate(action="diff", ...)`

1. McpServer dispatches to new `$handleDiff(params)` method.
2. If `modelName` present: `AutoMigrator.diff(modelName, options)`.
   Else: `AutoMigrator.diffAll(options)`.
3. Returns JSON of full diff struct.
4. `write=true` triggers `writeMigration`; path returned in `migrationWritten`.

## 8. Detection algorithm

### 8.1 Normalization

```
$normalizeToken(name):
  1. Lowercase
  2. Replace all [_-] with ""
```

Examples:
- `full_name` -> `fullname`
- `fullName` -> `fullname`
- `FULL-NAME` -> `fullname`

### 8.2 Explicit-hint pass

```
For each hint (oldName -> newName):
  removeMatch = find removeColumns where LCase(name) == LCase(oldName)
  addMatch    = find addColumns    where LCase(name) == LCase(newName)

  if not both found:
    raise Wheels.InvalidRenameHint
  if removeTypes[oldName] != addTypes[newName]:
    raise Wheels.RenameHintTypeMismatch
  confirmedRenames << {from, to, type, source: "hint"}
  remove oldName from removeColumns
  remove newName from addColumns
```

Pre-loop invariants (also raise):
- Two hints with same `from` -> `Wheels.DuplicateRenameHint`.
- Two hints with same `to` -> `Wheels.DuplicateRenameHint`.

Hints are authoritative. Silent hint-skip is a bug class — user believes the
migration has a rename that it doesn't.

### 8.3 Heuristic pass

Run on `remainingAdds` / `remainingRemoves` (post-hint).

```
scores = []
For each rCol in remainingRemoves:
  For each aCol in remainingAdds:
    if removeTypes[rCol.name] != addTypes[aCol.name]:
      continue  // strict type match required
    s = $score(rCol.name, aCol.name)
    if s >= threshold:
      scores << {from: rCol.name, to: aCol.name, confidence: s, type: addTypes[aCol.name]}

Sort scores by confidence DESC.

// Pre-count ambiguity across the full above-threshold candidate set
fromCount = {}, toCount = {}
For each candidate in scores:
  fromCount[candidate.from]++
  toCount[candidate.to]++

// Greedy assignment: highest confidence claims its reservations first
usedFroms = {}, usedTos = {}
For each candidate in sorted scores:
  if candidate.from in usedFroms or candidate.to in usedTos:
    skip
  reserve: usedFroms << candidate.from, usedTos << candidate.to
  isAmbiguous = fromCount[candidate.from] > 1 or toCount[candidate.to] > 1
  if candidate.confidence == 1.0 and NOT isAmbiguous:
    confirmedRenames << {...candidate, source: "heuristic"}
  else:
    suggestedRenames << {...candidate, ambiguous: isAmbiguous}
```

Ambiguity is determined from the *full* above-threshold candidate set (not
just the ones that won greedy assignment), so an ambiguous 1.0-score pair is
correctly demoted to `suggestedRenames` rather than auto-confirmed. The user
must supply an explicit hint to disambiguate and commit the rename.

### 8.4 Scoring

```
$score(nameA, nameB):
  a = $normalizeToken(nameA)
  b = $normalizeToken(nameB)
  if a == b: return 1.0
  dist = $levenshtein(a, b)
  maxLen = Max(Len(a), Len(b))
  if maxLen == 0: return 0
  return 1.0 - (dist / maxLen)
```

Calibration with default threshold 0.7:

| Pair | Normalized | Distance | Score | Result |
|---|---|---|---|---|
| `full_name` vs `fullName` | `fullname`/`fullname` | 0 | 1.00 | Auto-confirm |
| `FIRST_NAME` vs `firstName` | `firstname`/`firstname` | 0 | 1.00 | Auto-confirm |
| `user_name` vs `username` | `username`/`username` | 0 | 1.00 | Auto-confirm |
| `email_addr` vs `emailAddress` | `emailaddr`/`emailaddress` | 3 | 0.75 | Suggest |
| `status` vs `statusCode` | `status`/`statuscode` | 4 | 0.60 | No suggestion |
| `bio` vs `description` | `bio`/`description` | 10 | 0.09 | No suggestion |

Auto-confirm band (score 1.0) is conservative: only case/underscore variants
of the same tokens. Suggestion band catches near-synonyms; semantic renames
stay below threshold and require explicit hints.

### 8.5 Levenshtein implementation

Pure-CFML implementation in `RenameDetector.cfc` (~30 lines, standard dynamic
programming). No JVM library dependency to avoid cross-engine risk.

## 9. CLI UX

### 9.1 Command

```
wheels dbmigrate diff [modelName]

Arguments:
  modelName              Optional. If omitted, runs diffAll().

Options:
  --rename=OLD:NEW       Rename hint. Repeatable. For diffAll, prefix
                         with "Model.": --rename=User.full_name:fullName
  --threshold=0.7        Heuristic confidence threshold (0.0-1.0).
  --write                Write the migration file(s). Default: preview only.
  --name=NAME            Migration name (single-model only).
                         Default: "auto_<model>_changes".
  --help                 Show usage.
```

### 9.2 Preview output

```
$ wheels dbmigrate diff User --rename=full_name:fullName

Diff for User (users):

  Renames (will apply):
    full_name -> fullName               [string]  (source: hint)
    user_name -> username               [string]  (source: heuristic, normalized match)

  Suggested renames (pass --rename to confirm):
    email_addr -> emailAddress          [string]  confidence: 0.75
      wheels dbmigrate diff User --rename=email_addr:emailAddress

  Adds:
    + bio                               [text]

  Removes:
    - legacy_flag                       (will DROP - use --rename if this is actually a rename)

  Changes:
    ~ status                            string -> integer

Preview only - no migration file written. Pass --write to commit.
```

### 9.3 Ambiguous suggestion output

```
  Suggested renames (ambiguous - explicit --rename required):
    WARN full_name -> fullName          confidence: 1.00  (ambiguous)
    WARN full_name -> displayName       confidence: 0.73  (ambiguous)
      Remove "full_name" matches multiple candidates. Pick one:
      wheels dbmigrate diff User --rename=full_name:fullName
      wheels dbmigrate diff User --rename=full_name:displayName
```

Even a 1.0 score is demoted to a suggestion when it's part of an ambiguous
pair — the user must disambiguate.

### 9.4 Write output

```
$ wheels dbmigrate diff User --rename=full_name:fullName --write

[preview output above]

Migration written:
  app/migrator/migrations/20260415093052123_auto_user_changes.cfc

Run 'wheels dbmigrate latest' to apply.
```

### 9.5 diffAll output

```
$ wheels dbmigrate diff

Diff across 14 models. Changes detected in:

  User (users):
    Renames: 1 (full_name -> fullName)
    Adds: 1, Removes: 0, Changes: 0

  Post (posts):
    Adds: 2, Removes: 1, Changes: 0
    Suggested renames: 1 (pass --rename=Post.body_text:body to confirm)

11 models clean.

Preview only - no migration files written. Pass --write to commit.
```

`--write` with `diffAll` produces one migration file per changed model.

### 9.6 Error output

```
$ wheels dbmigrate diff User --rename=nonexistent_col:fullName

Error: rename hint references column "nonexistent_col" which is not
       in the removed-columns set for model User.

       Current removed columns: full_name, legacy_flag
```

Exit code 1.

## 10. MCP integration

Extend existing `wheels_migrate` tool with `action="diff"`.

### 10.1 Input schema

Single model:

```json
{
  "action": "diff",
  "modelName": "User",
  "hints": {"renames": {"full_name": "fullName"}},
  "heuristicThreshold": 0.7,
  "write": false
}
```

All models (omit `modelName`):

```json
{
  "action": "diff",
  "hints": {
    "User": {"renames": {"full_name": "fullName"}},
    "Post": {"renames": {"body_text": "body"}}
  },
  "heuristicThreshold": 0.7,
  "write": false
}
```

### 10.2 Output schema

Success (single model):

```json
{
  "success": true,
  "modelName": "User",
  "tableName": "users",
  "renameColumns": [
    {"from": "full_name", "to": "fullName", "type": "string", "source": "hint"}
  ],
  "suggestedRenames": [
    {"from": "email_addr", "to": "emailAddress", "type": "string",
     "confidence": 0.75, "ambiguous": false}
  ],
  "addColumns":    [{"name": "bio", "type": "text", "nullable": true, "default": ""}],
  "removeColumns": [{"name": "legacy_flag"}],
  "changeColumns": [{"name": "status", "from": {"type": "string"}, "to": {"type": "integer"}}],
  "migrationWritten": null
}
```

`migrationWritten` contains the file path when `write=true`.

`diffAll` returns the same envelope with a `models` key mapping model name to
per-model diff struct (empty struct if no models have changes).

### 10.3 Error output

```json
{
  "success": false,
  "error": "Wheels.InvalidRenameHint",
  "message": "rename hint references column 'nonexistent_col' which is not in the removed-columns set for model User",
  "modelName": "User",
  "availableRemoves": ["full_name", "legacy_flag"]
}
```

HTTP 200 with `success: false` — matches existing McpServer error convention.

## 11. Error handling

### 11.1 Raised exceptions

All raised in `RenameDetector.detect()`. `AutoMigrator.diff()` lets them propagate.

| Exception type | When |
|---|---|
| `Wheels.InvalidRenameHint` | Hint references column not in removes or adds |
| `Wheels.RenameHintTypeMismatch` | Hint pair has mismatched migration types |
| `Wheels.DuplicateRenameHint` | Two hints share from-col or to-col |
| `Wheels.InvalidThreshold` | threshold outside [0, 1] |

- CLI converts to exit-1 + formatted stderr message.
- MCP converts to `{success: false, error, message}` envelope.

### 11.2 Silent fallbacks (not errors)

| Condition | Behavior |
|---|---|
| Zero above-threshold heuristic pairs | Empty `suggestedRenames`. |
| No hints, no adds, no removes | All result arrays empty. |
| Threshold 1.0 | Only exact normalized-token matches confirmed. |
| Threshold 0.0 | Every type-compatible pair becomes a candidate. |

### 11.3 Edge cases

1. **Empty model name** — existing `model()` call throws. No new handling.
2. **Rename hints with no diff** — hints fail validation (InvalidRenameHint).
   User error, not silent no-op.
3. **Rename + type change on same column** — raises `RenameHintTypeMismatch`.
   Rename must be a separate migration from the type change.
4. **Primary key renames** — impossible. `diff()` already excludes PKs from
   `removeColumns` (existing line 92-94). PKs never reach the detector.
5. **Case-only renames** (`fullname` -> `fullName`) — normalized match -> 1.0 ->
   auto-confirmed. Emits `renameColumn`. Adapter/DB handles case-collation
   semantics at migration-run time.
6. **Adapter without renameColumn support** — fails at migration-run time,
   not generation time. Matches existing Wheels behavior.
7. **Empty hints struct** (`{renames: {}}`) — heuristic pass runs normally.

### 11.4 Backward compatibility

Zero breaking changes:

- `diff(modelName)` — unchanged behavior when `options` omitted. Heuristic
  pass populates `suggestedRenames` (informational); existing callers that
  ignore new keys see no behavioral difference in adds/removes if there are
  no score-1.0 matches. If there are score-1.0 matches (which would have
  been emitted as drop+add previously), they now become renames. **This is
  the desired fix** and is documented in release notes.
- `diffAll()` — same as above.
- `generateMigrationCFC(diffResult, name)` — handles old-shape and new-shape
  diffResults via `StructKeyExists()` guard on `renameColumns`.

Existing tests in `autoMigratorSpec.cfc` remain passing.

## 12. Testing strategy

### 12.1 `renameDetectorSpec.cfc` (new, pure logic)

Approx 35 specs across:
- `$normalizeToken` — case, underscore, hyphen, empty string.
- `$score` — identical tokens, known distance cases, empty strings.
- `detect()` — hint path: present-on-both, missing-from-removes,
  missing-from-adds, type-mismatch, duplicate-from, duplicate-to,
  hint-consumes-columns.
- `detect()` — heuristic path: 1.0 auto-confirm, above-threshold suggest,
  below-threshold skip, type-mismatch skip, custom threshold.
- `detect()` — ambiguity: one-remove-many-adds, one-add-many-removes,
  greedy assignment by confidence, never-confirm-ambiguous,
  **ambiguous 1.0-score pair demoted to `suggestedRenames` rather than
  `confirmedRenames`**.
- `detect()` — edge cases: empty arrays, empty hints, hints-but-no-diff.

### 12.2 `autoMigratorSpec.cfc` (additions, ~10 specs)

- `diff()` with hints produces `renameColumns`.
- Hinted columns excluded from `addColumns` / `removeColumns`.
- `suggestedRenames` populated from heuristic.
- `options` arg optional (backward-compat).
- `heuristicThreshold` propagates.
- `diffAll()` per-model hints honored.
- `generateMigrationCFC()` emits `renameColumn` in `up()`.
- `generateMigrationCFC()` emits reversed `renameColumn` in `down()`.
- Ordering in `up()`: renames -> adds -> removes -> changes.
- Empty `renameColumns` produces no rename calls.

### 12.3 MCP specs (~6 specs)

- `wheels_migrate action=diff` with `modelName` calls `diff()`.
- Without `modelName` calls `diffAll()`.
- Hints struct passed through correctly.
- Invalid hint returns `success: false` envelope (no rethrow).
- `write=true` triggers `writeMigration` and populates `migrationWritten`.
- `write=false` (default) returns `migrationWritten: null`.

### 12.4 CLI tests

If existing CLI test infrastructure supports it, add a `diffSpec.cfc` that
verifies flag parsing (building the correct `hints` struct from `--rename`
args). Otherwise: manual verification + MCP tests (which exercise the same
code path server-side).

### 12.5 Cross-engine verification

Pre-merge requirement:
1. `bash tools/test-local.sh migrator` (Lucee 7 + SQLite).
2. Docker Adobe CF 2025 run on migrator suite.

Levenshtein is the only cross-engine risk — pure-CFML string ops (Left/Mid/Len)
behave consistently, but confirm empirically.

## 13. Documentation updates

### 13.1 Framework comparison (`docs/wheels-vs-frameworks.md`)

- Move current "Where Wheels Trails" item 6 to "Where Wheels Leads" as item 16.
- New Leads item text:
  > **16. Auto-migration rename detection** — `AutoMigrator.diff()` accepts
  > explicit rename hints AND runs heuristic similarity analysis
  > (normalized-token + Levenshtein) to suggest likely renames. Rails requires
  > manual `rename_column`; Django uses interactive CLI only. Wheels is the
  > only framework offering both programmatic hints and automatic suggestions
  > in the diff engine.
- Update section 2 "Migrations" table row for Auto-generation: augment Wheels
  column to mention rename detection.
- Update "Wheels auto-migrations" callout: replace "cannot detect column
  renames" text with hints-and-heuristics summary.
- Append to "Recently Closed Gaps": Auto-migration rename detection PR link.

### 13.2 User-facing docs (`docs/src/`)

**NEW: `docs/src/command-line-tools/commands/database/dbmigrate-diff.md`**

Per-command reference following existing template (Synopsis, Description,
Parameters, How It Works, Example Output, See Also). Covers preview, `--write`,
`--rename`, `--threshold`, ambiguity, and both single-model + `diffAll` modes.

**MODIFY: `docs/src/command-line-tools/cli-guides/migrations.md`**

Add new section "Auto-Generating Migrations from Models" covering model-first
workflow, `wheels dbmigrate diff [modelName]`, rename hints, heuristic
suggestions, ambiguity, and limits. Placed after "Creating Migrations".

**MODIFY: `docs/src/database-interaction-through-models/database-migrations/README.md`**

Add tutorial-flavored section "Auto-Migration: Generate from Model Changes"
near the end: walk through editing a model, running diff, reading output,
confirming a rename, committing with `--write`.

### 13.3 Framework-internal docs

- **`CLAUDE.md`** — Auto-Migration Quick Reference block (CFC + CLI examples).
- **`.ai/wheels/database/`** — add rename detection subsection IF an
  AutoMigrator file exists there; otherwise no-op.
- **`docs/api/`** — API reference appears generated. Confirm during
  implementation; if it includes AutoMigrator, the new params/keys should
  regenerate cleanly.

## 14. Implementation order (suggested)

1. `RenameDetector.cfc` + `renameDetectorSpec.cfc` — pure logic, isolated.
2. Wire into `AutoMigrator.diff()` + `diffAll()` + `generateMigrationCFC()`;
   update `autoMigratorSpec.cfc`.
3. CLI command (`dbmigrate diff.cfc`).
4. MCP `action="diff"` handler in `McpServer.cfc`.
5. User-facing docs.
6. Framework comparison + CLAUDE.md updates.
7. Cross-engine verification (Lucee 7 + Adobe CF 2025).

## 15. Open questions

None after brainstorming. All decisions locked:

- Detection strategy: A+B (hints + heuristics).
- API shape: struct-of-struct, model-keyed for `diffAll`.
- Scope: core + CLI + MCP.
- Heuristic: normalized-token match + strict type + 0.7 default threshold.
- Implementation: separate `RenameDetector.cfc` component.
- Hint-validation: raise on invalid hints (no silent skip).
- Rename+retype: raise (separate migrations required).
- Levenshtein: pure-CFML implementation.
