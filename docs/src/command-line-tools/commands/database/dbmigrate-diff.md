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
