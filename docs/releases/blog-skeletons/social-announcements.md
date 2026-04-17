# Wheels 4.0 — Pre-announce Social Posts

**Status:** Copy-paste ready. Three posts, four channels each. Use in the order below or mix and match over a week.

**Posting cadence suggestion:**
- **Day 1:** Post 1 (parity story) — broadest audience.
- **Day 3:** Post 2 (the full audit) — for the spec-and-receipts crowd.
- **Day 5:** Post 3 (3.0 → 4.0 delta) — for existing users planning the upgrade.

**Framing:** 4.0 is *in the works* — release candidate, not GA. Phrasing throughout uses "coming" / "on the way" / "preview" rather than "shipped." Swap to present tense on GA day.

**Links (use absolute URLs — these docs are not on GitBook):**
- Parity doc: https://github.com/wheels-dev/wheels/blob/develop/docs/wheels-vs-frameworks.md
- Full audit: https://github.com/wheels-dev/wheels/blob/develop/docs/releases/wheels-4.0-audit.md
- 3.0 → 4.0 comparison: https://github.com/wheels-dev/wheels/blob/develop/docs/releases/wheels-3.0-vs-4.0.md

---

## Post 1 — "Where Wheels lands on the framework comparison grid"

*Anchors on `docs/wheels-vs-frameworks.md`. The parity story.*

### Slack (#wheels-dev)

```
Wheels 4.0 is coming — and it changes how the framework-comparison table looks.

Published the 4.0 parity doc against Rails 8, Laravel 12, and Django 5:
<https://github.com/wheels-dev/wheels/blob/develop/docs/wheels-vs-frameworks.md|wheels-vs-frameworks.md>

Highlights where the gap closed:
• Bulk insert/upsert (was: no → now: per-adapter native UPSERT)
• Polymorphic associations, advisory locks, pessimistic locking
• First-class middleware pipeline + rate limiting + security headers
• Browser testing (Playwright Java), parallel runner, HTTP test client
• Multi-tenancy in-core (was: external package)

Honest "where we still trail": ecosystem size, bidirectional WebSocket (intentional non-goal — SSE is our cross-engine primitive), asset-pipeline maturity (Vite integration is newer than Rails'/Laravel's).

Worth skimming if you've been waiting for "is Wheels ready for $my-project" clarity.
```

### LinkedIn

```
Wheels 4.0 is on the way, and I've been updating the framework-comparison doc to show where it lands against Rails 8, Laravel 12, and Django 5.

The short version: most of the rows that said "No" for CFWheels over the last five years now say "Yes" for Wheels 4.0.

Bulk insert and upsert operations. Polymorphic associations. Advisory locks and pessimistic locking. A first-class middleware pipeline with built-in rate limiting and security headers. Browser testing via Playwright Java. Parallel test runner. HTTP integration test client. Multi-tenancy in-core rather than as a third-party package.

The doc is honest about where Wheels still trails: ecosystem size is smaller, bidirectional WebSocket is deliberately not a goal (SSE is the cross-engine-uniform real-time primitive), and Vite asset-pipeline tooling is newer than Rails' or Laravel's equivalents.

Worth a read if the last time you evaluated Wheels it did not meet the bar for what you needed.

https://github.com/wheels-dev/wheels/blob/develop/docs/wheels-vs-frameworks.md

#CFML #Wheels #WebDevelopment #OpenSource
```

### X / Twitter

**Hero tweet (280 chars):**
```
Wheels 4.0 is on the way.

Updated the parity doc vs Rails 8 / Laravel 12 / Django 5 — most of the rows that said "No" for CFWheels now say "Yes" for Wheels 4.0.

Bulk upsert, polymorphic assocs, advisory locks, middleware pipeline, browser testing, multi-tenancy…

(1/3)
```

**Tweet 2:**
```
Honest "where we still trail":

• Ecosystem size — smaller than Rails/Laravel/Django
• Bidirectional WebSocket — intentional non-goal; SSE is our cross-engine primitive
• Asset-pipeline maturity — Vite integration is newer than Rails'/Laravel's

(2/3)
```

**Tweet 3:**
```
Full comparison:
https://github.com/wheels-dev/wheels/blob/develop/docs/wheels-vs-frameworks.md

If you last evaluated Wheels and it didn't clear the bar, worth another look before 4.0 ships.

(3/3)
```

### GitHub Discussions

**Title:** `Wheels 4.0 — framework parity preview (Rails 8 / Laravel 12 / Django 5)`

```markdown
Wheels 4.0 is approaching GA. As part of the release prep I've refreshed `docs/wheels-vs-frameworks.md` to reflect what 4.0 actually ships, and the picture is substantially different from the 3.x version of the same doc.

## What closed between 3.x and 4.0

Categories where 4.0 brings Wheels to parity with the peer frameworks:

- **Data layer** — bulk insert/upsert (`insertAll` / `upsertAll` with per-adapter native UPSERT), polymorphic associations, advisory locks (`withAdvisoryLock`), pessimistic locking (`.forUpdate()`).
- **Middleware** — first-class pipeline, built-in rate limiting, CSP/HSTS/Permissions-Policy via `SecurityHeaders`.
- **Testing** — HTTP `TestClient`, parallel runner, browser testing via Playwright Java.
- **Infrastructure** — multi-tenancy in-core (per-request datasource switching, no external package required), route model binding, expanded DI with request-scoped services.

## What Wheels still trails

The doc is explicit about three remaining gaps:

1. **Ecosystem size.** The community is smaller than Rails/Laravel/Django; not a short-term fix.
2. **Bidirectional WebSocket.** Intentional non-goal — SSE with pub/sub channels is the cross-engine-uniform primitive.
3. **Asset-pipeline maturity.** Vite integration is newer than Rails' / Laravel's. Active follow-up work underway.

## Links

- [docs/wheels-vs-frameworks.md](https://github.com/wheels-dev/wheels/blob/develop/docs/wheels-vs-frameworks.md)
- [Full 4.0 feature audit](https://github.com/wheels-dev/wheels/blob/develop/docs/releases/wheels-4.0-audit.md)
- [3.0 → 4.0 comparison](https://github.com/wheels-dev/wheels/blob/develop/docs/releases/wheels-3.0-vs-4.0.md)

## Question for the thread

If you evaluated Wheels in the 3.x era and walked away, which row on the comparison grid was the deal-breaker? Knowing what nearly-closed the deal for people helps prioritize the remaining gaps.
```

---

## Post 2 — "185 PRs, 14 weeks — the full 4.0 inventory"

*Anchors on `docs/releases/wheels-4.0-audit.md`. The breadth/receipts story.*

### Slack (#wheels-dev)

```
Wheels 4.0 — feature audit is published.

185 PRs merged to `develop` between 3.0.0 and now (~14 weeks). I bucketed every user-visible change and cross-linked with the CHANGELOG.

<https://github.com/wheels-dev/wheels/blob/develop/docs/releases/wheels-4.0-audit.md|docs/releases/wheels-4.0-audit.md>

By the numbers:
• ~70 distinct user-visible features/changes
• 40+ security-hardening PRs (SQL injection, path traversal, CORS/CSRF/HSTS, rate limiter, MCP)
• 7 breaking changes — all documented with detect/fix/opt-out in the upgrade guide
• Contributors: @bpamiri, @zainforbjs, @chapmandu, @mlibbe, plus dependabot

If you want the "what's in 4.0" with receipts instead of marketing, this is the doc.
```

### LinkedIn

```
Wheels 4.0 is approaching GA. I published the full feature audit — every user-visible change merged to develop since the 3.0.0 release, organized by subsystem and cross-linked to the CHANGELOG.

By the numbers:

- 185 merged PRs across approximately 14 weeks
- Roughly 70 distinct user-visible features and changes
- 40+ security-hardening PRs covering SQL injection, path traversal, CSRF/CORS/HSTS, rate limiter hardening, and MCP endpoint hardening
- 7 breaking changes, each documented in the upgrade guide with detect, fix, and opt-out guidance
- A long list of contributors from the community

The audit was also the source doc for the 3.0 → 4.0 comparison and the refreshed framework-parity doc. If you want to understand what 4.0 actually ships, with PR-level receipts rather than marketing copy, this is the place to start.

https://github.com/wheels-dev/wheels/blob/develop/docs/releases/wheels-4.0-audit.md

#CFML #Wheels #WebDevelopment #ReleaseNotes #OpenSource
```

### X / Twitter

**Hero tweet (280 chars):**
```
Wheels 4.0 by the numbers:

• 185 merged PRs
• ~14 weeks
• ~70 distinct user-visible features
• 40+ security-hardening PRs
• 7 breaking changes (all with detect/fix/opt-out docs)

Full audit with PR-level receipts:
https://github.com/wheels-dev/wheels/blob/develop/docs/releases/wheels-4.0-audit.md
```

**(Optional follow-up tweet if going as a thread):**
```
Security-hardening breakdown:

• SQL injection — QueryBuilder + scope handlers + $quoteValue + index hints
• Path traversal — partials, guideImage, MCP docs, encoded-bypass
• Session/CSRF — SameSite, auto-gen key, session fixation, open-redirect
• CORS deny-all default
• Rate limiter
• MCP
• XSS

(2/2)
```

### GitHub Discussions

**Title:** `Wheels 4.0 feature audit — 185 PRs catalogued by subsystem`

```markdown
As part of the 4.0 release prep I've compiled a full inventory of every user-visible change merged to `develop` since the 3.0.0 release. The goal is a single place to answer "what actually ships in 4.0" with PR-level receipts instead of marketing copy.

## Summary stats

- **185 merged PRs** across roughly 14 weeks (3.0.0 → today)
- **~70 distinct user-visible features / changes** after deduplicating multi-PR features
- **40+ security-hardening PRs** — a full section in the audit
- **7 breaking changes** — each covered in the upgrade guide with a consistent detect / fix / opt-out structure
- **Contributors:** @bpamiri, @zainforbjs, @chapmandu, @mlibbe, plus dependabot

## Subsystems covered

The audit buckets every PR into 22 categories including ORM & data layer, migrations, routing, controllers, views, middleware pipeline, background jobs, SSE, multi-tenancy, DI container, packages, testing infrastructure, CLI + LuCLI, MCP, engine adapters, and security hardening. Each category lists every PR with a one-line description and link.

## How the doc was produced

1. `gh pr list --base develop --state merged --search "merged:>=2026-01-10"` for the raw PR set.
2. Cross-referenced against `git log --merges v3.0.0+33..origin/develop`.
3. Compared against the `[Unreleased]` section of CHANGELOG.md (which had ~60 gaps — addressed by a separate catch-up PR).
4. Grouped multi-PR features into single entries with all PR links.

## Links

- [Full audit (docs/releases/wheels-4.0-audit.md)](https://github.com/wheels-dev/wheels/blob/develop/docs/releases/wheels-4.0-audit.md)
- [3.0 → 4.0 comparison](https://github.com/wheels-dev/wheels/blob/develop/docs/releases/wheels-3.0-vs-4.0.md) (derived from the audit)
- [docs/wheels-vs-frameworks.md](https://github.com/wheels-dev/wheels/blob/develop/docs/wheels-vs-frameworks.md) (peer-framework parity)
- [Upgrade guide](https://github.com/wheels-dev/wheels/blob/develop/docs/src/introduction/upgrading-to-4.0.md)

## Question for the thread

If you spot a user-visible change that isn't in the audit or find a bucket where something is miscategorized, please comment or open an issue. The audit is meant to be the source of truth for release-comms, so corrections before GA are especially welcome.
```

---

## Post 3 — "What closed between 3.0 and 4.0"

*Anchors on `docs/releases/wheels-3.0-vs-4.0.md`. The existing-users-upgrade story.*

### Slack (#wheels-dev)

```
For anyone running Wheels 3.x and wondering "what does upgrading to 4.0 actually get me" — I wrote a row-by-row before/after comparison:

<https://github.com/wheels-dev/wheels/blob/develop/docs/releases/wheels-3.0-vs-4.0.md|wheels-3.0-vs-4.0.md>

Only includes *capabilities that changed* — unchanged rows are omitted for readability. Each row is tagged New / Formalized / Hardened / Fixed / Breaking / Removed with a direct PR link.

Short version:
• ~35 new capabilities
• ~10 formalized (had partial precedent, now production-ready)
• 7 breaking defaults hardened — all with opt-outs
• 4 legacy surfaces removed

Pairs with the upgrade guide for the actual migration steps.
```

### LinkedIn

```
For developers running Wheels 3.x and weighing a 4.0 upgrade, I've published a row-by-row before/after comparison. The doc only covers capabilities that actually changed between the 3.0.0 release and 4.0 — unchanged rows are omitted so the scope of the upgrade is legible at a glance.

Every row carries a tag that indicates what kind of change it is:

- New — capability did not exist in 3.0
- Formalized — had partial or undocumented precedent; now production-ready with tests and official docs
- Hardened — existed; security-tightened in 4.0
- Fixed — bug that made the 3.0 capability unreliable; resolved in 4.0
- Breaking — default behavior changed in a way that requires user action when upgrading
- Removed — 3.0 surface removed entirely

By the numbers: approximately 35 new capabilities, 10 formalizations, 7 breaking defaults hardened (each with an opt-out), and 4 legacy surfaces removed.

The doc pairs with the upgrade guide, which walks each of the 7 breaking changes with detect, fix, and opt-out guidance.

https://github.com/wheels-dev/wheels/blob/develop/docs/releases/wheels-3.0-vs-4.0.md

#CFML #Wheels #Upgrade #ReleaseNotes #OpenSource
```

### X / Twitter

**Hero tweet (280 chars):**
```
On Wheels 3.x and weighing a 4.0 upgrade?

Published a row-by-row before/after comparison — only rows that actually changed, each tagged New / Formalized / Hardened / Fixed / Breaking / Removed with a PR link:

https://github.com/wheels-dev/wheels/blob/develop/docs/releases/wheels-3.0-vs-4.0.md
```

**(Optional follow-up as a thread):**
```
Headline numbers:

• ~35 new capabilities
• ~10 formalized (partial precedent → production-ready)
• 7 breaking defaults hardened — all with opt-outs
• 4 legacy surfaces removed

Pairs with the upgrade guide for the actual migration steps.

(2/2)
```

### GitHub Discussions

**Title:** `Wheels 3.0 → 4.0 — row-by-row before/after for existing apps`

```markdown
If you're running Wheels 3.x and weighing a 4.0 upgrade, this doc is designed for you.

`docs/releases/wheels-3.0-vs-4.0.md` is a row-by-row before/after comparison. Only capabilities that actually *changed* between the 3.0.0 release and 4.0 are included — unchanged rows are omitted so the scope of the upgrade is legible at a glance.

## How the rows are tagged

Every row carries one of:

- **New** — capability did not exist in 3.0.
- **Formalized** — had partial or undocumented precedent; became production-ready with tests + docs in 4.0.
- **Hardened** — capability existed; security-tightened in 4.0.
- **Fixed** — bug that made the 3.0 capability unreliable; resolved in 4.0.
- **Breaking** — default behavior changed in a way that requires user action when upgrading.
- **Deprecated / Removed** — 3.0 surface retained-but-warned, or removed entirely.

## Scale

At a glance:

| | Count |
|---|---|
| New capabilities | ~35 |
| Formalized (tests + docs, now official) | ~10 |
| Breaking defaults hardened | 7 |
| Security-hardening PRs grouped by theme | 40+ |
| Legacy surfaces removed | 4 |

## What to read next

- **Upgrading a 3.x app?** Start with the [upgrade guide](https://github.com/wheels-dev/wheels/blob/develop/docs/src/introduction/upgrading-to-4.0.md) — each of the 7 breaking changes is covered with a consistent detect / fix / opt-out structure. The Legacy Compatibility Adapter is documented as the soft-landing option if you want a staged migration.
- **Want the full inventory?** The [feature audit](https://github.com/wheels-dev/wheels/blob/develop/docs/releases/wheels-4.0-audit.md) lists every PR merged since 3.0.0, bucketed into 22 categories.
- **Evaluating Wheels vs other frameworks?** The [parity comparison](https://github.com/wheels-dev/wheels/blob/develop/docs/wheels-vs-frameworks.md) shows where 4.0 lands against Rails 8 / Laravel 12 / Django 5.

## Question for the thread

If you've started a 3.x → 4.0 upgrade on any size of app — or deliberately chosen not to — what's the single biggest signal you needed to see before committing (or deferring)? Useful feedback for where to put effort in 4.0.x releases.
```

---

## Pre-post checklist

Before pasting to any channel:

- [ ] GA date is decided and not contradicted by "coming" phrasing.
- [ ] Links resolve (not behind branch protection or 404 for signed-out users).
- [ ] PR numbers referenced in the audit match current state (audit re-run if develop has moved significantly).
- [ ] Contributors listed in Post 2 are current — cross-check `git log --format='%an' v3.0.0+33..origin/develop | sort -u`.
- [ ] `#CFML` / `#Wheels` hashtag choices match the project's normal voice on each platform.
- [ ] No emojis — matches the Wheels rebrand's understated voice.
