# Wheels 4.0 — Blog Post Skeletons

Skeletons (outlines, not publication-ready prose) for the Wheels 4.0 launch blog series. Each file is a hand-off brief for a writer or a follow-on AI pass to expand into a full post.

**Status:** skeletons only. Headlines, section outlines, target audiences, lead paragraph intent, example code to include, suggested visuals, and citations. No finished prose.

**Scope:** marketing / release-comms artifact. Lives outside the published doc site (`docs/src/`) — GitBook does not index this folder.

## The series (priority order)

1. **[Wheels 4.0 — Closing the Maturity Gap](01-closing-the-maturity-gap.md)** (lead post). Frames 4.0 as the release where Wheels caught up with Rails 8 / Laravel 12 / Django 5 on framework-comparison gaps.
2. **[Upgrading from Wheels 3.x](02-upgrading-from-3x.md)**. Practical migration guide around the 10 breaking changes, with the Legacy Compatibility Adapter as the soft-landing story.
3. **[Security Hardening in 4.0](03-security-hardening.md)**. 40+ security PRs told as one narrative — SQL injection, path traversal, CSRF/CORS/HSTS, MCP hardening, rate limiter.
4. **[Background Jobs Without Redis](04-background-jobs.md)**. DB-backed job worker daemon + CLI + multi-tenancy. Genuinely differentiated vs Rails/Laravel/Django equivalents.
5. **[LuCLI and the Zero-Docker Dev Experience](05-lucli-zero-docker.md)**. 60s test runs, the Phase 1 → Phase 4 arc, CI migration story.
6. **[Testing in Wheels 4.0](06-testing.md)**. HTTP TestClient + parallel runner + browser testing (Playwright Java) + WheelsTest BDD-only posture.
7. **[Multi-Tenancy Built In](07-multi-tenancy.md)**. Per-request datasource switching in-core; tenant-aware background jobs.
8. **[From WireBox to wheelsdi](08-wirebox-to-wheelsdi.md)**. The rim-modernization arc — decomposed init, in-house DI, engine adapter modules, leaner core.

## Source material

Each skeleton cites specific PRs and cross-links back to the three canonical sources:

- [Feature audit](../wheels-4.0-audit.md) — 185 merged PRs, ~70 distinct features, the source of truth.
- [3.0 → 4.0 ground-made-up](../wheels-3.0-vs-4.0.md) — row-by-row before/after.
- [Upgrade guide](../../src/introduction/upgrading-to-4.0.md) — Breaking items + Legacy Compatibility Adapter.
- [Wheels vs. peer frameworks](../../wheels-vs-frameworks.md) — current 4.0 parity comparison, including "Where Wheels Trails."

## Writing-pass instructions

When a writer (human or AI) expands a skeleton:

1. Keep the headline as-is unless there's a compelling reason to change it.
2. The subhead / dek is a hard one-sentence limit.
3. Lead with a scenario or a specific before/after — not a feature list.
4. Every PR cited in the skeleton should be linked in the final post (absolute `https://github.com/wheels-dev/wheels/pull/N` URLs).
5. Where a skeleton links to a doc in `docs/releases/` (audit, comparison), those files are NOT published on GitBook — link to the GitHub blob URL (`https://github.com/wheels-dev/wheels/blob/develop/docs/releases/...`).
6. Where a skeleton links to `docs/src/` (upgrade guide, wheels-vs-frameworks), those ARE on GitBook — use the canonical docs URL once known.

## Out of scope for these skeletons

- Final tag / release-date language. Use placeholders like "Wheels 4.0" without dates; the GA date is tracked in [#2131](https://github.com/wheels-dev/wheels/issues/2131).
- Diagrams / charts. Skeletons describe the *intent* of a visual (radar chart, timeline, architecture box diagram); actual visuals are produced during the writing pass.
