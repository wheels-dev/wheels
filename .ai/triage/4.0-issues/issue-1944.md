# Issue #1944: LuCLI: stretch generators (api-resource, helper, snippets)

## Verdict
CLOSE — already implemented. Issue is stale; no PR reference linked it closed.

## Summary
All three stretch generators (`api-resource`, `helper`, `snippets`) are fully wired into `cli/lucli/Module.cfc` and shipped months ago. Tests exist in `GenerateCommandSpec.cfc` and `ScaffoldSpec.cfc`. The issue body is a self-analysis from @claude that was never closed after merge.

## Root cause
Not a bug — scope already delivered. Evidence:
- `cli/lucli/Module.cfc:142-147` — help text lists `api-resource`, `helper`, `snippets`.
- `cli/lucli/Module.cfc:190-205` — dispatcher branches for all three types (with `api` alias and `h` alias for helper).
- `cli/lucli/Module.cfc:2159-2211` — `generateApiResource()` delegates to `Scaffold.generateApiResource()` (a dedicated API path, not just `api=true` on scaffold).
- `cli/lucli/Module.cfc:2213-2261` — `generateHelper()` uses `CodeGen.generateHelper()`, writes to `app/helpers/<Name>.cfc`, supports `--force`.
- `cli/lucli/Module.cfc:2263-2312` — `generateSnippets()` implements a registry pattern (`getSnippetRegistry()`), supports `wheels generate snippets` (list), `wheels generate snippets <pattern>` (named snippet), and `wheels generate snippets templates` (raw copy), with `--force`.
- `cli/lucli/templates/snippets/` — 12 snippet templates present (auth-filter, crud-controller, soft-delete-mixin, etc.).
- Tests: `cli/lucli/tests/specs/commands/GenerateCommandSpec.cfc:173` (api-resource), `:232` (helper), plus snippets coverage; `cli/lucli/tests/specs/services/ScaffoldSpec.cfc` exercises the API path.
- Delivery commits: `6104b8b02 feat: add api-resource, helper, and snippets generators to LuCLI (wh-41w)` and follow-up `bbc6de4b0 feat: implement dedicated api-resource generator (wh-xqh)`.

## Files to change
None. Administrative only:
- GitHub issue #1944 — close with reference to commits above.

## Implementation steps
1. Verify the commits are on `develop`:
   ```
   git log --oneline develop -S"generateApiResource" -- cli/lucli/Module.cfc
   ```
2. Close the issue with a note:
   ```
   gh issue close 1944 --repo wheels-dev/wheels \
     --comment "Delivered in 6104b8b02 (wh-41w) and bbc6de4b0 (wh-xqh). \
     Dispatcher wired in cli/lucli/Module.cfc:190-205; handlers at 2159-2312. \
     Tests in cli/lucli/tests/specs/commands/GenerateCommandSpec.cfc and \
     cli/lucli/tests/specs/services/ScaffoldSpec.cfc."
   ```
3. Optional follow-up (separate issue, not required for close):
   - Root `CLAUDE.md` lists `app/global/` as the helper location while the generator writes to `app/helpers/`. Either update docs or add a compatibility note. The generator is correct for Wheels 4.0 conventions; CLAUDE.md should be reconciled.
   - `cli/CLAUDE.md` still documents the legacy CommandBox CLI (`box install wheels-cli`, `ModuleConfig.cfc`). Does not affect this issue but is stale.

## Testing
No code changes needed. To verify current behavior cold:
```
bash tools/test-local.sh   # full LuCLI + core suite
# Targeted (if harness supports):
lucli run cli/lucli/tests/runner.cfm
```
Or smoke-test each generator against a throwaway app:
```
wheels new tmpapp && cd tmpapp
wheels generate api-resource Product name price:decimal sku:string
wheels generate helper formatting truncateText
wheels generate snippets            # lists registry
wheels generate snippets auth       # runs named pattern
```

## Risk & dependencies
- None — close-only. No backwards-compat, cross-engine, or migration surface.
- Related: CLAUDE.md docs divergence re: `app/global/` vs `app/helpers/` (separate, low-priority doc cleanup).

## Effort estimate
S (<15 min — issue close + verification).
