# Issue #2173: CHANGELOG references `wheels code` but the command ships as `wheels generate snippets`

## Verdict
FIX NOW

## Summary
`CHANGELOG.md` line 111 claims `wheels snippets` was renamed to `wheels code`, but the shipped 4.0 command is actually `wheels generate snippets` (a subcommand of the `generate` dispatcher in `cli/lucli/Module.cfc`). `wheels code` does not exist. The same incorrect rename has propagated into the upgrade guide and several release/audit docs. Pure documentation drift — correct the strings.

## Root cause
PR #1852 renamed the top-level `wheels snippets` command, but the final implementation landed it as a subcommand under `wheels generate` (see `cli/lucli/Module.cfc` lines 127, 147, 161, 204–205, 2272–2402 — all references use `wheels generate snippets`). The CHANGELOG entry and downstream docs were never updated to match the final command surface. Confirmed: there is no `code` case in the Module.cfc dispatch and no `wheels code` invocation anywhere in `cli/`.

Stale/incorrect references (all say "wheels code"):
- `CHANGELOG.md:111` — **primary source of drift, the issue target**
- `web/sites/guides/src/content/docs/v4-0-0-snapshot/upgrading/3x-to-4x.mdx:113` (heading) and `:115` (body citation of CHANGELOG)
- `docs/releases/blog-skeletons/02-upgrading-from-3x.md:37`
- `docs/releases/wheels-4.0-audit.md:125, 232`
- `docs/releases/wheels-3.0-vs-4.0.md:136`
- `docs/superpowers/specs/2026-04-16-wheels-4.0-upgrade-guide-design.md:13, 88`
- `docs/superpowers/plans/2026-04-16-wheels-4.0-upgrade-guide.md:108, 361, 367, 385, 386, 731, 792`

The actual command (verified): `wheels generate snippets [pattern] [--force]`.

## Files to change

Authoritative (must fix for issue #2173 closure):
1. `CHANGELOG.md` line 111

User-facing guide shipped on the docs site (high priority — readers hit this):
2. `web/sites/guides/src/content/docs/v4-0-0-snapshot/upgrading/3x-to-4x.mdx` lines 113, 115

Release collateral (update so drafts stay accurate; low reader traffic but should not spread the error):
3. `docs/releases/blog-skeletons/02-upgrading-from-3x.md` line 37
4. `docs/releases/wheels-4.0-audit.md` lines 125, 232
5. `docs/releases/wheels-3.0-vs-4.0.md` line 136

Internal planning docs (optional, out-of-date by design, but easy to sweep while the grep is hot):
6. `docs/superpowers/specs/2026-04-16-wheels-4.0-upgrade-guide-design.md` lines 13, 88
7. `docs/superpowers/plans/2026-04-16-wheels-4.0-upgrade-guide.md` lines 108, 361, 367, 385, 386, 731, 792

Recommend fixing 1–5 in the PR that closes #2173; 6–7 can be a follow-up or the same PR.

## Implementation steps

1. `CHANGELOG.md:111` — change
   `- **Breaking:** \`wheels snippets\` CLI command renamed to \`wheels code\` (#1852)`
   to
   `- **Breaking:** \`wheels snippets\` CLI command renamed to \`wheels generate snippets\` (#1852)`

2. `web/sites/guides/src/content/docs/v4-0-0-snapshot/upgrading/3x-to-4x.mdx`:
   - Line 113 heading: `### 7. \`wheels snippets\` renamed to \`wheels generate snippets\``
   - Line 115 CHANGELOG citation: `**CHANGELOG:** \`Breaking: wheels snippets CLI command renamed to wheels generate snippets\` (#1852).`
   - Scan the section body (around lines 113–140) for any `wheels code` usage examples and rewrite to `wheels generate snippets` — match what §2.8 of `upgrading-to-4-0.mdx` (the correct doc referenced by the reporter) shows.

3. `docs/releases/blog-skeletons/02-upgrading-from-3x.md:37` — replace `wheels code` with `wheels generate snippets`.

4. `docs/releases/wheels-4.0-audit.md` — same rename on lines 125 and 232.

5. `docs/releases/wheels-3.0-vs-4.0.md:136` — same rename in the comparison table cell.

6. (Optional) Superpowers specs/plans — same replacement on all flagged lines. The plan file has usage snippets (`wheels code list`, `wheels code add MyTemplate`) that need matching subcommand rewrites — confirm the real subcommands by running `wheels generate snippets` and inspecting `listSnippets()` in `cli/lucli/Module.cfc` before rewriting.

7. Final verification (see Testing). Commit with scope `docs` per CLAUDE.md: e.g. `docs(docs): correct wheels snippets rename to wheels generate snippets`.

## Testing

Doc-only change; no runtime tests. Verify with:

```bash
grep -rn "wheels code" . --include="*.md" --include="*.mdx"
```

Expected: zero hits after fix (or only hits inside quoted historical context that is explicitly labeled as pre-fix). Also confirm the corrected command actually runs:

```bash
wheels generate snippets        # should list available patterns
wheels generate snippets auth   # should generate auth snippet files
```

Cross-check against the already-correct doc the reporter cited: `web/sites/guides/src/content/docs/v4-0-0-snapshot/upgrading/upgrading-to-4-0.mdx` §2.8 — the rewritten 3x-to-4x.mdx section should match its command surface.

## Risk & dependencies

Very low risk. Documentation string replacement only; no code, no tests, no runtime behavior affected. No dependencies on other issues. Self-contained.

## Effort estimate

S — roughly 15 minutes. One authoritative line fix (CHANGELOG), one user-facing guide section, three release docs, and an optional sweep of internal planning docs. All changes are mechanical find-and-replace with a final grep verification.
