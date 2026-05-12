# Phase 2c Implementation Report

**Plan:** `2026-04-21-guides-rewrite-phase-2c.md`
**Branch:** `claude/upbeat-napier-7ccf97`
**PR:** (to be opened)
**Completion date:** 2026-04-21

---

## Summary

14 content pages + sidebar wiring + scoped `.ai/` audit. Closes the gap flagged in the post-merge correction on PR #2169, where the PR body described Phase 2c content that had shipped as placeholder stubs only. All 14 pages source-verified against framework CFCs, middleware, CHANGELOG, and commitlint config. 16 total commits on this phase.

**Deliverables:**
- 6 Deployment & Operations pages: index (rewrite), production-config, docker-deployment, vm-deployment, security-hardening, observability-and-logging
- 4 Contributing & Project pages: index (rewrite), pull-requests, coding-standards, writing-docs
- 3 Upgrading pages: index (rewrite), 3x-to-4x, 2x-to-3x
- 1 Glossary rewrite (45 alphabetized entries)
- 1 sidebar update wiring all 13 new pages into three previously-empty groups
- 2 `.ai/` files deleted (`.ai/wheels/configuration/security.md`, `.ai/wheels/security/csrf-protection.md`)

**Final build:** 340 pages. `pnpm build` green. `pnpm verify:docs` on the Phase 2c diff: 43 tagged blocks across 14 files, all passing.

**Kamal posture (user-confirmed 2026-04-21):** Deployment docs teach user-authored Dockerfiles + nginx/systemd — no fabricated `wheels docker`/`wheels deploy` commands. A single paragraph in `deployment/index.mdx` notes the Kamal port is in active development and links [kamal-deploy.org](https://kamal-deploy.org/) with a grep-able `TODO(phase-2c)` JSX comment for the future swap to a PR/issue URL.

---

## Commit log (16 commits)

| # | SHA | Task | Page / action |
|---|-----|------|---------------|
| 1 | d84abb424 | 0 | Phase 2c plan + scope decisions |
| 2 | 6ba558485 | 1 | deployment/index |
| 3 | fb2ae57ed | 2 | deployment/production-config |
| 4 | 27ec07009 | 3 | deployment/docker-deployment |
| 5 | 79d99dfd8 | 4 | deployment/vm-deployment |
| 6 | 51a13eb42 | 5 | deployment/security-hardening |
| 7 | 4f5a2236d | 6 | deployment/observability-and-logging |
| 8 | 6f0379677 | 7 | contributing/index |
| 9 | 335c0203a | 8 | contributing/pull-requests |
| 10 | a10d603be | 9 | contributing/coding-standards |
| 11 | edc8fad60 | 10 | contributing/writing-docs |
| 12 | da002e4b3 | 11 | upgrading/index |
| 13 | 041e5d045 | 12 | upgrading/3x-to-4x |
| 14 | 1c6716b17 | 13 | upgrading/2x-to-3x |
| 15 | ac502c495 | 14 | glossary |
| 16 | 395bcfaa7 | 16 | sidebar wiring |
| 17 | 4d1b104aa | 15 | .ai/ audit |

---

## Drift caught during source verification

Per-page drift caught by subagents comparing claims against authoritative source. Each entry = a claim that was *almost* shipped before source-verification caught it.

| Page | Drift caught |
|------|-------------|
| `deployment/index.mdx` | Kamal implementation plan path `docs/superpowers/plans/2026-04-20-wheels-deploy-kamal-port.md` is on an unmerged worktree branch, not `develop`. Link replaced with [kamal-deploy.org](https://kamal-deploy.org/) + grep-able TODO comment. |
| `deployment/docker-deployment.mdx` | Confirmed via grep that `wheels docker *` commands do NOT exist in `cli/lucli/Module.cfc`. Page explicitly tells readers to use plain `docker` / `docker compose` CLI. |
| `deployment/docker-deployment.mdx` | `tools/docker/lucee7/Dockerfile` uses CommandBox-based `ortussolutions/commandbox:latest` — wrong for production users. Page authored a user-app Dockerfile from scratch using `lucee/lucee:7-tomcat10-jre21`. |
| `deployment/production-config.mdx` | `application.wo.env()` env-var resolution order (`.env` → JVM `System.getenv`) confirmed at `vendor/wheels/Global.cfc:410-422`. Production auto-flips (`showErrorInformation=false`, `caching`, `autoMigrateDatabase=false`) anchored to specific framework init files. |
| `deployment/security-hardening.mdx` | Every `SecurityHeaders` default + config option cited to exact line in `vendor/wheels/middleware/SecurityHeaders.cfc`. HSTS off-switch flagged as missing (issue #2174) rather than fabricating a non-existent parameter. |
| `deployment/observability-and-logging.mdx` | Sentry package `packages/sentry/Sentry.cfc:36–45` catches controller exceptions via `sentryCapture` mixin but does NOT catch job failures (`vendor/wheels/Job.cfc:345, 368` only writes to `wheels_jobs` log). Gap documented in-page rather than assumed covered. |
| `contributing/pull-requests.mdx` | Commitlint config (`commitlint.config.js`) sourced directly. Scope enum is 23 entries. Subject rule only rejects `upper-case` — CLAUDE.md's "lowercase subject" convention is documented as project convention rather than a hard commitlint gate. |
| `contributing/coding-standards.mdx` | All 7 cross-engine rules cited to specific lines in `.ai/wheels/cross-engine-compatibility.md`. Mixin `private` → `$` pattern cited to lines 128-138. |
| `contributing/writing-docs.mdx` | `{test:*}` directives sourced from `scripts/verify-docs/VALIDATION.md` line anchors. No invented directive syntax. |
| `upgrading/index.mdx` | Framework version `4.0.0` sourced from `vendor/wheels/events/onapplicationstart.cfc:85`. Noted `vendor/wheels/Wheels.cfc` does not exist (the plan assumed it did) — subagent found the real location. |
| `upgrading/3x-to-4x.mdx` | Every breaking change cites a CHANGELOG + PR number. Subagent flagged three unverified claims from the blog skeleton (`legacyCompatibilityAdapter` settings flag, `wheels browser install` upgrade step, `wheels doctor` existence). I grep-verified `wheels doctor` exists at `cli/lucli/Module.cfc:1212`; the other two were dropped or softened before commit. |
| `upgrading/2x-to-3x.mdx` | v3.0 guides path `/v3-0-0/upgrading/3-0-0-config-migration/` verified against the Starlight slugifier (dots→dashes default) before linking. |
| `glossary.mdx` | 3 terms flagged (Verify/verifies(), Strong params, Composite key) appeared in Phase 2a/2b pages but lacked a conceptual definition anchor. Excluded from glossary rather than invented. |

---

## Source-verification wins

- **Eliminated fabricated `wheels docker`/`wheels deploy` commands** that legacy GitBook docs had documented — neither exists in v4.
- **Every `SecurityHeaders` default** now cites the exact line of `SecurityHeaders.cfc` that sets it, so future drift is catchable.
- **HSTS off-switch gap** (#2174) surfaced as a documented limitation rather than a fabricated parameter — matches the pattern Phase 2b-advanced established for known carryover.
- **Sentry job-error coverage gap** documented in-page, preventing readers from assuming full job-failure instrumentation.
- **Commitlint config** sourced directly, not via CLAUDE.md paraphrase.
- **Cross-engine rules** cited to `.ai/wheels/cross-engine-compatibility.md` line anchors — this was the authoritative source all along.

---

## Carryover (non-blocking)

1. **Kamal plan merge.** The `wheels deploy` implementation plan + design spec are on `claude/interesting-cartwright-ed6357`, not merged to develop. Once merged (or once a tracking issue/PR exists), swap the `deployment/index.mdx` TODO comment for a concrete link.
2. **CODEOWNERS / MAINTAINERS file.** Core team is inferred from git log (Peter Amiri, Zain Ul Abideen). A MAINTAINERS.md or CODEOWNERS file would make `contributing/index.mdx` self-verifying. Recommend separate small PR.
3. **HSTS off-switch (#2174).** `security-hardening.mdx` documents the gap; closing the framework issue lets us remove the caution note.
4. **Auto-glossary linker.** `glossary.mdx` is hand-curated. A later polish task could auto-link glossary terms from other guides on first mention.
5. **`.ai/` full sweep.** Scoped audit completed. Full `.ai/wheels/**` sweep is on the design spec's end-of-Phase-2 list (open question #3).
6. **Upgrading from 3x → 4x blog skeleton reconciliation.** Subagent flagged two items that couldn't be verified against current source (`legacyCompatibilityAdapter` as a settings flag, parallel-runner as must-do). The blog skeleton may need updating to match the shipped 3x-to-4x page.

---

## Exit criteria check

- [x] 14 content pages (6 Deployment + 4 Contributing + 3 Upgrading + 1 Glossary)
- [x] `pnpm verify:docs` passes on the Phase 2c diff (43/43 tagged blocks)
- [x] `pnpm build` — 340 pages, no broken-link warnings
- [x] Sidebar JSON has no empty `items: []` under v4-0-0-snapshot
- [x] Phase 2c report committed (this file)
- [x] `.ai/` audit committed
- [ ] Final review via `pr-review-toolkit:code-reviewer` (Task 18 — next)
- [ ] PR opened to `develop` with accurate description

---

## Next

- Task 18: Final code review via `pr-review-toolkit:code-reviewer` across the Phase 2c diff
- Open PR to `develop` once review findings are resolved
