# Wheels 4.0 GA — Open Issue Triage

Fix plans for the 17 open issues on `wheels-dev/wheels` as of 2026-04-22. Each plan is implementation-ready: root cause, files to change, steps, tests, risks, effort estimate.

## Summary

| Verdict | Count | Issues |
|---|---|---|
| **FIX NOW** | 11 | #2011, #2106, #2110, #2131, #2135, #2136, #2138, #2173, #2174, #2178, #2179 |
| **DEFER** | 3 | #1942 (umbrella), #2176, #2177 (both upstream LuCLI) |
| **CLOSE** | 3 | #1944, #1945, #1946 (all already shipped) |

## GA-blocker path (prerequisite for #2131)

All six `phase:1-stabilize` issues must land first. Suggested order:

1. **#2110** (M) — fixes 3 categories incl. Flash harness bug affecting every engine
2. **#2106** (S) — CockroachDB bulk-op + advisory-lock skip-shim
3. **#2136** (S) — app-starter `populate.cfm` DB-dispatch
4. **#2138** (S) — move 9 misplaced framework fixture files out of `app/`
5. **#2135** (M) — move 6 browser-test routes under framework + gated include
6. **#2011** (M) — move 11 misplaced core specs from `tests/specs/` to `vendor/wheels/tests/specs/`

Then unblock release:

7. **#2131** (L) — 4.0 GA tag, distribution, announcements

## Quick wins (independent, any order)

- **#2173** (S) — rename `wheels code` → `wheels generate snippets` in CHANGELOG + 7 other files
- **#2174** (S) — add `hsts` boolean to `SecurityHeaders` middleware
- **#2178** (S) — pin `verify-docs` harness test step to Node 20 in CI
- **#2179** (S) — add 3 redirect pairs for old `cli-reference/*` URLs

## Close immediately (already shipped, just clean up)

- **#1944** — stretch generators (`api-resource`, `helper`, `snippets`) all shipped in `6104b8b02` + `bbc6de4b0`
- **#1945** — Homebrew formula rewritten in `wheels-dev/homebrew-wheels#2`; daily auto-update workflow in place
- **#1946** — Chocolatey package shipped in `wheels-dev/chocolatey-wheels#2`; one-line `LUCLI_HOME` tweak uncommitted locally

## Defer (upstream LuCLI — not 4.0-GA blocking)

- **#1942** — Phase 2-4 umbrella: 6/9 children closed; refresh checklist, let remaining close auto
- **#2176** — `lucee.json` parallel-spawn race: root-caused to `LuceeServerConfig.saveConfig:688-690`; Wheels-side workaround (4-way concurrency cap + retries + soft-fail) holds 266/290. Fix aligns with LuCLI 1.0.0 CFCamp target
- **#2177** — `-Dlucli.binary.name` auto-detect via `ProcessHandle`: cosmetic (banner/prompt), not functional. **Fast-track one-liner:** Windows `lucli.bat` never sets the flag — breaks Chocolatey aliasing silently; fix separately

## Cross-issue insights

- **CLAUDE.md drift:** Claims CockroachDB is soft-fail in CI, but `compat-matrix.yml` has `SOFT_FAIL_DBS=""` — already hard-gated. Fix as part of #2106.
- **Latent release workflow bugs:** `release.yml` unconditionally appends `+<run_number>` on `main` push (recreates the `v3.0.0+N`-only problem); CHANGELOG extractor regex uses `# \[` but file uses `## \[` — release body would ship empty. Fix as part of #2131.
- **Framework/app layering cleanup** is the real theme of #2011, #2135, #2138 — three angles on "fixture/framework code leaked into `app/`". They should probably land close together with a shared migration note in the 3.x→4.x upgrade guide.
- **Upstream LuCLI dependency** drives #2176, #2177, and partially #1945/#1946. Align the next LuCLI release (1.0.0) to unblock all four at once.

## How to use a plan

Each `issue-NNNN.md` is self-contained. Dispatch to a subagent with:

> Execute the fix plan at `.ai/triage/4.0-issues/issue-NNNN.md`. Create a `peter/fix-NNNN-short-desc` branch, implement, test, open PR against `develop`.

## Index

- [#1942](issue-1942.md) — DEFER — LuCLI tracking umbrella
- [#1944](issue-1944.md) — CLOSE — stretch generators already shipped
- [#1945](issue-1945.md) — CLOSE — Homebrew formula already updated
- [#1946](issue-1946.md) — CLOSE — Chocolatey package already updated
- [#2011](issue-2011.md) — FIX NOW (M) — core tests in wrong dir
- [#2106](issue-2106.md) — FIX NOW (S) — CockroachDB core-test failures
- [#2110](issue-2110.md) — FIX NOW (M) — core tests failing across DBs (3 categories)
- [#2131](issue-2131.md) — FIX NOW (L) — 4.0 GA tag & release orchestration
- [#2135](issue-2135.md) — FIX NOW (M) — internal routes in app-level routes.cfm
- [#2136](issue-2136.md) — FIX NOW (S) — app-starter populate.cfm DB-dispatch
- [#2138](issue-2138.md) — FIX NOW (S) — framework fixtures in `app/`
- [#2173](issue-2173.md) — FIX NOW (S) — rename `wheels code` references
- [#2174](issue-2174.md) — FIX NOW (S) — add HSTS off-switch to SecurityHeaders
- [#2176](issue-2176.md) — DEFER — upstream LuCLI lucee.json race
- [#2177](issue-2177.md) — DEFER — upstream LuCLI binary name auto-detect
- [#2178](issue-2178.md) — FIX NOW (S) — pin verify-docs harness to Node 20
- [#2179](issue-2179.md) — FIX NOW (S) — 3 redirect pairs for legacy cli-reference URLs
