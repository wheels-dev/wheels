# Wheels 4.0 — Pre-announce & GA Social Posts

**Status:** Copy-paste ready. Ten posts, four channels each. Runs as a drumbeat from first pre-announce to GA day.

**Campaign start:** 2026-04-21 (Post 1 posted). **GA target:** 2026-05-09.

**Posting schedule (every 2 days, 2026-04-21 → 2026-05-09):**

| # | Date | Post | Angle |
|---|---|---|---|
| 1 | 2026-04-21 | Parity story | Broadest audience. Posted. |
| 2 | 2026-04-23 | The full audit | Spec-and-receipts crowd. |
| 3 | 2026-04-25 | 3.0 → 4.0 delta | Existing users planning the upgrade. |
| 4 | 2026-04-27 | `wheels deploy` | Marquee-feature spotlight; wholly new CLI surface. |
| 5 | 2026-04-29 | Security hardening | 40+ hardening PRs, "secure by default" story. |
| 6 | 2026-05-01 | Data layer modernization | "Rails parity made concrete" for ORM-curious devs. |
| 7 | 2026-05-03 | Testing | Browser testing + parallel runner + HTTP client + zero-Docker inner loop. |
| 8 | 2026-05-05 | Multi-tenancy + background jobs | The "what makes Wheels different" beat. |
| 9 | 2026-05-07 | LuCLI / zero-Docker DX | Inner-loop developer-experience closer. |
| 10 | **2026-05-09 (GA)** | Release announcement | Recaps the arc, swap all "coming" → present tense. |

**Companion long-form blog posts** (in [docs/releases/blog-skeletons/](.) — drop `NN-` prefix on move to `web/content/blog/posts/`):

| Blog post | Date | Paired with |
|---|---|---|
| 09 — `wheels deploy` (Kamal port) | 2026-04-27 | Social 4 |
| 03 — Security hardening | 2026-04-29 | Social 5 |
| 06 — Testing in 4.0 | 2026-05-03 | Social 7 |
| 04 — Background jobs without Redis | 2026-05-05 | Social 8 |
| 07 — Multi-tenancy built in | 2026-05-06 | Social 8 (day after) |
| 05 — LuCLI zero-Docker DX | 2026-05-07 | Social 9 |
| 01 — Closing the maturity gap (lead) | 2026-05-09 | Social 10 / GA |
| 02 — Upgrading from 3.x | 2026-05-09 | Social 10 / GA |
| 08 — WireBox → wheelsdi (contributor) | 2026-05-11 | Post-GA |

**Framing:** 4.0 is *in the works* — release candidate, not GA. Phrasing throughout uses "coming" / "on the way" / "preview" rather than "shipped." Swap to present tense on GA day.

**X thread numbering convention:** hero tweet is unnumbered and stands alone. Reply tweets in the thread are prefixed `1/`, `2/`, `3/` — no total denominator (threads can grow, and open-ended numbering is the prevailing convention). Keep the hero readable/quotable on its own even if you never post the replies.

**Links (use absolute URLs — these docs are not on GitBook):**
- Parity doc: https://github.com/wheels-dev/wheels/blob/develop/docs/wheels-vs-frameworks.md
- Full audit: https://github.com/wheels-dev/wheels/blob/develop/docs/releases/wheels-4.0-audit.md
- 3.0 → 4.0 comparison: https://github.com/wheels-dev/wheels/blob/develop/docs/releases/wheels-3.0-vs-4.0.md
- Deployment landing: https://github.com/wheels-dev/wheels/blob/develop/web/sites/guides/src/content/docs/v4-0-0-snapshot/deployment/index.mdx
- First deploy guide: https://github.com/wheels-dev/wheels/blob/develop/web/sites/guides/src/content/docs/v4-0-0-snapshot/deployment/first-deploy.mdx
- Migrating from Kamal: https://github.com/wheels-dev/wheels/blob/develop/web/sites/guides/src/content/docs/v4-0-0-snapshot/deployment/migrating-from-kamal.mdx

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

**Hero tweet (unnumbered):**
```
Wheels 4.0 is on the way.

Updated the parity doc vs Rails 8 / Laravel 12 / Django 5 — most of the rows that said "No" for CFWheels now say "Yes" for Wheels 4.0.

Bulk upsert, polymorphic assocs, advisory locks, middleware pipeline, browser testing, multi-tenancy…
```

**Reply 1:**
```
1/ Honest "where we still trail":

• Ecosystem size — smaller than Rails/Laravel/Django
• Bidirectional WebSocket — intentional non-goal; SSE is our cross-engine primitive
• Asset-pipeline maturity — Vite integration is newer than Rails'/Laravel's
```

**Reply 2:**
```
2/ Full comparison:
https://github.com/wheels-dev/wheels/blob/develop/docs/wheels-vs-frameworks.md

If you last evaluated Wheels and it didn't clear the bar, worth another look before 4.0 ships.
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

## Post 2 — "260+ PRs, 15 weeks — the full 4.0 inventory"

*Anchors on `docs/releases/wheels-4.0-audit.md`. The breadth/receipts story.*

### Slack (#wheels-dev)

```
Wheels 4.0 — feature audit is published.

260+ PRs merged to `develop` between 3.0.0 and now (~15 weeks). I bucketed every user-visible change and cross-linked with the CHANGELOG.

<https://github.com/wheels-dev/wheels/blob/develop/docs/releases/wheels-4.0-audit.md|docs/releases/wheels-4.0-audit.md>

By the numbers:
• ~70 distinct user-visible features/changes
• 40+ security-hardening PRs (SQL injection, path traversal, CORS/CSRF/HSTS, rate limiter, MCP)
• 7 breaking changes — all documented with detect/fix/opt-out in the upgrade guide
• Contributors: @bpamiri, @zainforbjs, @chapmandu, @mlibbe, @MukundaKatta, plus dependabot

If you want the "what's in 4.0" with receipts instead of marketing, this is the doc.
```

### LinkedIn

```
Wheels 4.0 is approaching GA. I published the full feature audit — every user-visible change merged to develop since the 3.0.0 release, organized by subsystem and cross-linked to the CHANGELOG.

By the numbers:

- 260+ merged PRs across approximately 15 weeks
- Roughly 70 distinct user-visible features and changes
- 40+ security-hardening PRs covering SQL injection, path traversal, CSRF/CORS/HSTS, rate limiter hardening, and MCP endpoint hardening
- 7 breaking changes, each documented in the upgrade guide with detect, fix, and opt-out guidance
- A long list of contributors from the community

The audit was also the source doc for the 3.0 → 4.0 comparison and the refreshed framework-parity doc. If you want to understand what 4.0 actually ships, with PR-level receipts rather than marketing copy, this is the place to start.

https://github.com/wheels-dev/wheels/blob/develop/docs/releases/wheels-4.0-audit.md

#CFML #Wheels #WebDevelopment #ReleaseNotes #OpenSource
```

### X / Twitter

**Hero tweet (unnumbered; stands alone or leads a thread):**
```
Wheels 4.0 by the numbers:

• 260+ merged PRs
• ~15 weeks
• ~70 distinct user-visible features
• 40+ security-hardening PRs
• 7 breaking changes (all with detect/fix/opt-out docs)

Full audit with PR-level receipts:
https://github.com/wheels-dev/wheels/blob/develop/docs/releases/wheels-4.0-audit.md
```

**Reply 1 (optional — extend into a thread):**
```
1/ Security-hardening breakdown:

• SQL injection — QueryBuilder + scope handlers + $quoteValue + index hints
• Path traversal — partials, guideImage, MCP docs, encoded-bypass
• Session/CSRF — SameSite, auto-gen key, session fixation, open-redirect
• CORS deny-all default
• Rate limiter
• MCP
• XSS
```

### GitHub Discussions

**Title:** `Wheels 4.0 feature audit — 260+ PRs catalogued by subsystem`

```markdown
As part of the 4.0 release prep I've compiled a full inventory of every user-visible change merged to `develop` since the 3.0.0 release. The goal is a single place to answer "what actually ships in 4.0" with PR-level receipts instead of marketing copy.

## Summary stats

- **260+ merged PRs** across roughly 15 weeks (3.0.0 → today)
- **~70 distinct user-visible features / changes** after deduplicating multi-PR features
- **40+ security-hardening PRs** — a full section in the audit
- **7 breaking changes** — each covered in the upgrade guide with a consistent detect / fix / opt-out structure
- **Contributors:** @bpamiri, @zainforbjs, @chapmandu, @mlibbe, @MukundaKatta, plus dependabot

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
• ~40 new capabilities (incl. `wheels deploy` — a first-class Kamal-style deploy tool)
• ~11 formalized (had partial precedent, now production-ready)
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

By the numbers: approximately 40 new capabilities (including `wheels deploy`, a first-class Kamal-style deploy tool added late in the cycle), 11 formalizations, 7 breaking defaults hardened (each with an opt-out), and 4 legacy surfaces removed.

The doc pairs with the upgrade guide, which walks each of the 7 breaking changes with detect, fix, and opt-out guidance.

https://github.com/wheels-dev/wheels/blob/develop/docs/releases/wheels-3.0-vs-4.0.md

#CFML #Wheels #Upgrade #ReleaseNotes #OpenSource
```

### X / Twitter

**Hero tweet (unnumbered; stands alone or leads a thread):**
```
On Wheels 3.x and weighing a 4.0 upgrade?

Published a row-by-row before/after comparison — only rows that actually changed, each tagged New / Formalized / Hardened / Fixed / Breaking / Removed with a PR link:

https://github.com/wheels-dev/wheels/blob/develop/docs/releases/wheels-3.0-vs-4.0.md
```

**Reply 1 (optional — extend into a thread):**
```
1/ Headline numbers:

• ~40 new capabilities (incl. `wheels deploy` — Kamal-style deploys)
• ~11 formalized (partial precedent → production-ready)
• 7 breaking defaults hardened — all with opt-outs
• 4 legacy surfaces removed

Pairs with the upgrade guide for the actual migration steps.
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
| New capabilities | ~40 |
| Formalized (tests + docs, now official) | ~11 |
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

## Post 4 — "`wheels deploy` — Kamal-style deploys, native CFML"

*Anchors on the deployment landing page and the migrating-from-kamal doc. The marquee-feature story. Stands alone from the release-arc posts because `wheels deploy` is a wholly new CLI surface.*

### Slack (#wheels-dev)

```
Wheels 4.0 brings a new command: `wheels deploy`.

It's a port of Basecamp's Kamal into the Wheels CLI — zero-downtime Dockerized deploys to Linux servers over plain SSH. No Ruby runtime, no gem install, no second tool to learn.

<https://github.com/wheels-dev/wheels/blob/develop/web/sites/guides/src/content/docs/v4-0-0-snapshot/deployment/index.mdx|Deployment guide>

What you get:
• One command from laptop to production: `wheels deploy`
• Full Kamal subcommand surface (~25 verbs): app, proxy, accessory, build, registry, secrets, server, prune, lock, rollback, audit
• Zero-downtime rollover via kamal-proxy (the same Go binary Kamal uses)
• Secret adapters out of the box: 1Password, Bitwarden, AWS Secrets Manager, LastPass, Doppler
• `--dry-run` on every verb

Byte-compatible with Ruby Kamal on the server side — container names, labels, Docker network, lock paths, `.kamal/secrets`, `.kamal/hooks/*` all match exactly. A host managed by Ruby Kamal can be taken over by `wheels deploy` without cleanup.

One deliberate divergence: `deploy.yml` uses Mustache (`{{env.APP_NAME}}`) instead of ERB. We can't render Ruby from a CFML CLI.
```

### LinkedIn

```
Wheels 4.0 is on the way, and one of the bigger additions is a new built-in command: `wheels deploy`.

It's a port of Basecamp's Kamal — the Ruby-world container deployer — into the Wheels CLI. Same zero-downtime rolling-deploy model, same on-server conventions, same `kamal-proxy` Go binary doing the actual traffic cutover. What's different is that you run it from the Wheels CLI you already have. No Ruby runtime, no `gem install kamal`, no second tool alongside the framework CLI.

The design goal was byte-compatibility with Ruby Kamal on the server side. Container names (`<service>-<role>-<version>`), labels, Docker network name (`kamal`), proxy config directory, lock file path, `.kamal/secrets`, `.kamal/hooks/*` — all match the Kamal 2.4.0 contract exactly. A host that has been managed by Ruby Kamal can be taken over by `wheels deploy` without any cleanup, and vice versa. Teams evaluating the switch can sit on both tools simultaneously.

There is exactly one deliberate divergence: `config/deploy.yml` does not support ERB. ERB is Ruby template code, and rendering it would require embedding a Ruby runtime — which is the thing we were trying to avoid. Wheels uses a restricted Mustache context instead: `{{env.APP_NAME}}`, `{{destination}}`, `{{hostname}}`. The migration from ERB is mechanical for most `deploy.yml` files.

The subcommand surface mirrors Kamal's top-level verbs: `init`, `setup`, `rollback`, `config`, `app`, `proxy`, `accessory`, `build`, `registry`, `secrets`, `server`, `prune`, `lock`, `audit`, `details`, `remove`. Secret management ships with adapters for 1Password, Bitwarden, AWS Secrets Manager, LastPass, and Doppler.

What `wheels deploy` is not: it is not a Kubernetes integration, not a systemd-native deployer, not a bare-metal deploy tool. It's Docker on Linux servers, orchestrated from your laptop or CI runner over SSH. For Kubernetes or VM-based paths, the deployment docs cover the alternatives.

If you're shipping a Dockerized Wheels app to one or more Linux hosts and you want zero-downtime rollover out of the box, this is the shortest path in 4.0.

Guide: https://github.com/wheels-dev/wheels/blob/develop/web/sites/guides/src/content/docs/v4-0-0-snapshot/deployment/index.mdx
Migrating from Kamal: https://github.com/wheels-dev/wheels/blob/develop/web/sites/guides/src/content/docs/v4-0-0-snapshot/deployment/migrating-from-kamal.mdx

#CFML #Wheels #Kamal #DevOps #Deployment #OpenSource
```

### X / Twitter

**Hero tweet (unnumbered):**
```
Wheels 4.0 ships a new command: `wheels deploy`.

It's a port of Basecamp's Kamal into the Wheels CLI. Zero-downtime Dockerized deploys to Linux servers over SSH. No Ruby runtime, no gem install.

One command, laptop to production.
```

**Reply 1:**
```
1/ Byte-compatible with Ruby Kamal on the server side:

• Container names `<service>-<role>-<version>`
• Labels, Docker network (`kamal`), lock paths
• `.kamal/secrets`, `.kamal/hooks/*`

A Kamal-managed host can be taken over by `wheels deploy` without cleanup. Sit on both tools during evaluation.
```

**Reply 2:**
```
2/ One deliberate divergence: `deploy.yml` uses Mustache, not ERB.

```yaml
# Kamal
service: <%= ENV["APP_NAME"] %>

# wheels deploy
service: {{env.APP_NAME}}
```

We can't render Ruby from a CFML CLI without embedding a Ruby runtime — which defeats the point.
```

**Reply 3:**
```
3/ Full subcommand surface: app, proxy, accessory, build, registry, secrets, server, prune, lock, rollback, audit.

Secret adapters: 1Password, Bitwarden, AWS, LastPass, Doppler.

Guide:
https://github.com/wheels-dev/wheels/blob/develop/web/sites/guides/src/content/docs/v4-0-0-snapshot/deployment/index.mdx
```

### GitHub Discussions

**Title:** `Wheels 4.0 ships wheels deploy — a Kamal port, no Ruby required`

```markdown
Wheels 4.0 introduces a new built-in command: `wheels deploy`. It is a port of [Basecamp's Kamal](https://kamal-deploy.org/) — the container-based deployer — into the Wheels CLI. This post is for anyone currently running ad-hoc deploy scripts (or running Ruby Kamal alongside Wheels) who wants to understand what's shipping and what the contract is.

## Why a port, not a plugin

Wheels ships as a LuCLI binary (CFML + Java). Asking users to `gem install kamal` adds a Ruby runtime dependency and a second CLI to learn. Kamal's proxy component ([kamal-proxy](https://github.com/basecamp/kamal-proxy)) is already a standalone Go binary — what's Ruby-specific is only the developer-side orchestrator that opens SSH connections, uploads config, and runs `docker` commands. So we ported the orchestrator, left `kamal-proxy` untouched, and kept the on-server state byte-compatible.

## What's byte-compatible

Everything in this list matches the Kamal 2.4.0 contract exactly:

| Concern | Value |
|---|---|
| Container name | `<service>-<role>-<version>` |
| Container labels | `service=`, `role=`, `destination=`, `version=` |
| Docker network | `kamal` |
| Proxy image | `basecamp/kamal-proxy:v0.8.6` |
| Proxy config dir | `/home/<user>/.config/kamal-proxy/` |
| Lock file path | `/tmp/kamal_deploy_lock_<service>` |
| Audit log | `/tmp/kamal-audit.log` |
| Hook directory | `.kamal/hooks/` |
| Hook env prefix | `KAMAL_*` (not `WHEELS_*` — so existing Kamal hook scripts work unchanged) |
| Secret file | `.kamal/secrets`, `.kamal/secrets.<destination>` |

A server managed by Ruby Kamal can be taken over by `wheels deploy` during evaluation, and vice versa. You can run both tools against the same host while you decide.

## The one divergence

`config/deploy.yml` does not support ERB. ERB is Ruby template code; rendering it from a CFML CLI would require embedding a Ruby runtime, which defeats the purpose of the port. Wheels uses a restricted Mustache context instead:

```yaml
service: {{env.APP_NAME}}
image: {{env.REGISTRY}}/{{env.APP_NAME}}
```

Available context: `{{env.FOO}}`, `{{destination}}`, `{{hostname}}`. For most `deploy.yml` files the conversion is mechanical.

## Subcommand surface

Mirrors Kamal's top-level verb structure:

- **Top-level:** `init`, `setup`, `rollback`, `config`, `version`, `details`, `audit`, `remove`, `docs`
- **App:** `app boot | start | stop | details | containers | images | logs | live | maintenance | remove`
- **Proxy:** `proxy boot | reboot | start | stop | restart | details | logs | remove`
- **Accessory:** `accessory boot | reboot | start | stop | restart | details | logs | remove` — for sidecars (database, cache, search)
- **Build:** `build deliver | push | pull | create | remove | details | dev`
- **Registry:** `registry setup | login | logout | remove`
- **Server:** `server exec | bootstrap`
- **Prune:** `prune all | images | containers`
- **Lock:** `lock acquire | release | status` (normal deploys auto-lock)
- **Secrets:** `secrets fetch | extract | print` with adapters for 1Password, Bitwarden, AWS Secrets Manager, LastPass, Doppler

Every verb supports `--dry-run` — prints the exact shell commands that would run remotely without opening an SSH connection. The commands-layer test suite runs offline, no Docker, no sshd.

## What `wheels deploy` is not

- **Not Kubernetes.** It drives `docker` remotely over SSH. For k8s, use your normal pipeline.
- **Not systemd-native.** For VM or bare-metal non-container deploys, see the VM deployment guide.
- **Not Compose-only.** Single-host Compose is covered by a different doc; `wheels deploy` adds value at two or more servers.
- **Not for Windows servers.** Linux targets only. Windows developer workstations are best-effort.
- **Not a Wheels reload mechanism.** Ships the container; the in-process `?reload=true` story is separate.
- **Not Ruby-Kamal-plugin-compatible.** Shell-script hooks in `.kamal/hooks/` work unchanged; the Ruby-plugin extension API is Ruby-specific.

## Docs

- [Deployment landing page](https://github.com/wheels-dev/wheels/blob/develop/web/sites/guides/src/content/docs/v4-0-0-snapshot/deployment/index.mdx) — start here for context and when-to-use guidance
- [Your first deploy](https://github.com/wheels-dev/wheels/blob/develop/web/sites/guides/src/content/docs/v4-0-0-snapshot/deployment/first-deploy.mdx) — hands-on walkthrough
- [Migrating from Kamal](https://github.com/wheels-dev/wheels/blob/develop/web/sites/guides/src/content/docs/v4-0-0-snapshot/deployment/migrating-from-kamal.mdx) — the full compatibility contract and switch-over checklist
- [Config reference](https://github.com/wheels-dev/wheels/blob/develop/web/sites/guides/src/content/docs/v4-0-0-snapshot/deployment/config-reference.mdx), [secrets](https://github.com/wheels-dev/wheels/blob/develop/web/sites/guides/src/content/docs/v4-0-0-snapshot/deployment/secrets.mdx), [hooks](https://github.com/wheels-dev/wheels/blob/develop/web/sites/guides/src/content/docs/v4-0-0-snapshot/deployment/hooks.mdx), [accessories](https://github.com/wheels-dev/wheels/blob/develop/web/sites/guides/src/content/docs/v4-0-0-snapshot/deployment/accessories.mdx)

## Question for the thread

If you're currently deploying a Wheels app to production, what does your setup look like today — and what would stop you from trying `wheels deploy`? The design space is still open for 4.0.x polish.
```

---

## Post 5 — "Secure-by-default — 40+ hardening PRs in 4.0"

*Anchors on §19 of the audit. The security story told with receipts.*

### Slack (#wheels-dev)

```
Wheels 4.0 lands with 40+ security-hardening PRs — a big reason the release took the time it did.

<https://github.com/wheels-dev/wheels/blob/develop/docs/releases/wheels-4.0-audit.md|Full audit §19>

Themes covered:
• SQL injection — QueryBuilder property + operator validation, ORDER BY clause, `$quoteValue` escaping, scope-handler sanitization, enum WHERE clauses, `include` in UPDATE, index hints
• Path traversal — partials, guideImage, MCP docs, encoded-bypass
• Console / reload endpoint — POST-only `consoleeval`, constant-time comparison, rate-limiting, hash-based password
• Defaults hardened — CORS wildcard → deny-all, CSRF SameSite, HSTS default-on in prod, RateLimiter `trustProxy=false`
• MCP — auth gate, path-traversal guards, CSRNG session tokens, structural allowlist

7 of these are breaking. All documented with detect/fix/opt-out in the upgrade guide.
```

### LinkedIn

```
Wheels 4.0 is approaching GA, and one theme deserves its own post: the security work.

Over the release cycle, 40+ PRs tightened the framework's security surface — across SQL generation, path handling, the console and reload endpoints, the CORS/CSRF/HSTS defaults, the rate limiter, and the MCP integration used by AI coding assistants. The result is a framework that ships secure-by-default rather than one that relies on every application to remember every setting.

A short tour of what changed:

SQL injection — QueryBuilder now validates property names and operators before interpolating; ORDER BY clauses go through the same parser that handles WHERE; `$quoteValue` properly escapes single quotes; scope-handler arguments are sanitized in a half-dozen places they previously weren't; enum WHERE clauses, the `include` parameter in UPDATE, and index-hint values are all tightened.

Path traversal — partial template rendering, the `guideImage` endpoint, the MCP documentation reader, and encoded-bypass attempts are all blocked.

Console and reload — `consoleeval` is now POST-only with Content-Type checks, reload password comparison is constant-time, and rate-limiting sits in front of the endpoint.

Defaults — the CORS default changed from wildcard to deny-all. HSTS defaults on in production. CSRF cookies set SameSite. RateLimiter trusts proxy-forwarded IPs only when explicitly configured. `allowEnvironmentSwitchViaUrl` defaults to false in production.

MCP — authentication gate in front of tools, path-traversal guards on document reads, cryptographically-secure session tokens, structural allowlist for commands.

Seven of these are breaking-change-level. Each is documented in the upgrade guide with a detect / fix / opt-out pattern, and the Legacy Compatibility Adapter provides a soft-landing path for apps that need it.

Audit with per-PR receipts: https://github.com/wheels-dev/wheels/blob/develop/docs/releases/wheels-4.0-audit.md

#CFML #Wheels #Security #WebDevelopment #OpenSource
```

### X / Twitter

**Hero tweet (unnumbered):**
```
Wheels 4.0 lands with 40+ security-hardening PRs.

SQL injection closed across QueryBuilder, ORDER BY, scope handlers, enums, UPDATE.
Path traversal closed in partials, guideImage, MCP, encoded-bypass.
Reload endpoint: constant-time + rate-limited + hash-based.

Secure by default.
```

**Reply 1:**
```
1/ Hardened defaults (7 are breaking — all with opt-outs + upgrade-guide entries):

• CORS: wildcard → deny-all
• HSTS: on in production
• CSRF cookie SameSite: set
• RateLimiter `trustProxy`: false
• RateLimiter proxy strategy: `last`
• `allowEnvironmentSwitchViaUrl`: false in prod
• Non-empty reload password required in prod
```

**Reply 2:**
```
2/ MCP endpoint hardening (used by AI coding assistants):

• Auth gate + input validation
• Path-traversal guards on doc reads
• CSRNG session tokens
• Structural allowlist for commands
• Error suppression to prevent info leak
• Port validation
```

**Reply 3:**
```
3/ Full audit §19 with PR-level receipts:
https://github.com/wheels-dev/wheels/blob/develop/docs/releases/wheels-4.0-audit.md

If you're auditing a Wheels 3.x app for security posture, the breaking-changes list is the shortlist of things to check before the 4.0 upgrade.
```

### GitHub Discussions

**Title:** `Wheels 4.0 — 40+ security-hardening PRs, bucketed and linked`

```markdown
Security was one of the largest investments in the 4.0 cycle. This post summarizes what changed, grouped by theme. Every claim links to a merged PR in the full audit.

## Themes

### SQL injection

Every interpolation path into generated SQL was audited. The fixes:

- **QueryBuilder** — property + operator validation before substitution ([#2025](https://github.com/wheels-dev/wheels/pull/2025)).
- **ORDER BY** — same parser as WHERE, rejects untrusted identifiers ([#2026](https://github.com/wheels-dev/wheels/pull/2026)).
- **`$quoteValue`** — proper single-quote escaping ([#2033](https://github.com/wheels-dev/wheels/pull/2033)).
- **Scope handlers** — argument sanitization ([#2043](https://github.com/wheels-dev/wheels/pull/2043), [#2045](https://github.com/wheels-dev/wheels/pull/2045), [#2056](https://github.com/wheels-dev/wheels/pull/2056), [#2061](https://github.com/wheels-dev/wheels/pull/2061), [#2070](https://github.com/wheels-dev/wheels/pull/2070), [#2090](https://github.com/wheels-dev/wheels/pull/2090)).
- **Enum WHERE clauses** — proper value binding ([#2023](https://github.com/wheels-dev/wheels/pull/2023), [#2056](https://github.com/wheels-dev/wheels/pull/2056), [#2070](https://github.com/wheels-dev/wheels/pull/2070)).
- **`include` in UPDATE** — identifier validation ([#2047](https://github.com/wheels-dev/wheels/pull/2047)).
- **Index hints** — `$indexHint` now validates ([#2058](https://github.com/wheels-dev/wheels/pull/2058)).
- **Geography and WKT** — SRID and WKT handling tightened ([#2044](https://github.com/wheels-dev/wheels/pull/2044), [#2055](https://github.com/wheels-dev/wheels/pull/2055)).

### Path traversal

- **Partial rendering** — `includePartial("../...")` blocked ([#2071](https://github.com/wheels-dev/wheels/pull/2071)).
- **`guideImage` endpoint** ([#2037](https://github.com/wheels-dev/wheels/pull/2037)).
- **MCP documentation reader** ([#2049](https://github.com/wheels-dev/wheels/pull/2049)).
- **Encoded-bypass attempts** ([#2089](https://github.com/wheels-dev/wheels/pull/2089)).

### Console / reload

- **`consoleeval` hardened** — POST-only, robust IPv6, Content-Type checks ([#2059](https://github.com/wheels-dev/wheels/pull/2059)).
- **Reload password comparison** — constant-time + rate-limiting ([#2077](https://github.com/wheels-dev/wheels/pull/2077)), hash-based ([#2022](https://github.com/wheels-dev/wheels/pull/2022)).

### Defaults hardened (7 breaking changes)

- CORS default: wildcard → deny-all ([#2039](https://github.com/wheels-dev/wheels/pull/2039)).
- HSTS default-on in production ([#2081](https://github.com/wheels-dev/wheels/pull/2081)) with explicit off-switch in 4.0.x ([#2195](https://github.com/wheels-dev/wheels/pull/2195)).
- CSRF cookie SameSite default ([#2035](https://github.com/wheels-dev/wheels/pull/2035)).
- RateLimiter `trustProxy=false` ([#2024](https://github.com/wheels-dev/wheels/pull/2024)).
- RateLimiter proxy strategy `last` ([#2088](https://github.com/wheels-dev/wheels/pull/2088)).
- `allowEnvironmentSwitchViaUrl` false in production ([#2076](https://github.com/wheels-dev/wheels/pull/2076)).
- Non-empty reload password required for env switching in production ([#2082](https://github.com/wheels-dev/wheels/pull/2082)).

Additionally, RateLimiter now fails closed on lock timeout rather than open ([#2069](https://github.com/wheels-dev/wheels/pull/2069)).

### MCP endpoint

Used by AI coding assistants; tightened end-to-end:

- Auth gate + input validation ([#2050](https://github.com/wheels-dev/wheels/pull/2050)).
- Path-traversal guards ([#2049](https://github.com/wheels-dev/wheels/pull/2049), [#2062](https://github.com/wheels-dev/wheels/pull/2062)).
- Error suppression ([#2072](https://github.com/wheels-dev/wheels/pull/2072)).
- Port validation ([#2075](https://github.com/wheels-dev/wheels/pull/2075)).
- Structural allowlist for commands ([#2083](https://github.com/wheels-dev/wheels/pull/2083)).
- CSRNG session tokens ([#2087](https://github.com/wheels-dev/wheels/pull/2087)).
- Shell-argument sanitization in `db shell` + `deploy` ([#2040](https://github.com/wheels-dev/wheels/pull/2040), [#2068](https://github.com/wheels-dev/wheels/pull/2068), [#2073](https://github.com/wheels-dev/wheels/pull/2073)).

## Upgrade guidance

Each breaking change is covered in the [upgrade guide](https://github.com/wheels-dev/wheels/blob/develop/docs/src/introduction/upgrading-to-4.0.md) with a consistent detect / fix / opt-out structure. The [Legacy Compatibility Adapter](https://github.com/wheels-dev/wheels/blob/develop/docs/releases/wheels-4.0-audit.md) provides a soft-landing path for staged migrations.

## Question for the thread

If you run security audits of your stack, which of these categories would you most want to see expanded in 4.0.x point releases? The framework side is tightened; the gap is in documentation and in patterns for application-level security (auth, session storage, MFA).
```

---

## Post 6 — "The ORM that closes the Rails gap"

*Anchors on the 3.0 → 4.0 comparison §1. The data-layer modernization story.*

### Slack (#wheels-dev)

```
If you last wrote a Wheels model two years ago and walked away muttering "I wish this had [thing Rails has]" — the list in 4.0 got a lot shorter.

<https://github.com/wheels-dev/wheels/blob/develop/docs/releases/wheels-3.0-vs-4.0.md|3.0 → 4.0 data-layer delta>

What's new in the ORM:
• Chainable query builder — `where().orderBy().limit().get()` with `whereNull`, `whereBetween`, `whereIn`, `orWhere` (injection-safe)
• Named scopes — `scope(name="active", where="...")`, composable and chainable
• Enums — `enum(property="status", values="draft,published,archived")` auto-generates `isDraft()`/`isPublished()` checkers, `draft()`/`published()` scopes, inclusion validation
• Batch processing — `findEach(batchSize, callback)` / `findInBatches`
• Bulk insert/upsert — `insertAll()` / `upsertAll()` with per-adapter native UPSERT (MySQL, Postgres, SQL Server, SQLite, H2, CockroachDB, Oracle)
• Polymorphic associations — `belongsTo(polymorphic=true)` + `hasMany(as=...)`
• Advisory locks — `withAdvisoryLock(name, callback)` with try/finally release
• Pessimistic locking — `.forUpdate()` on QueryBuilder
• CockroachDB — full adapter with `unique_rowid()` PK + `RETURNING` identity select

Plus auto-migrations from model diffs with rename detection.
```

### LinkedIn

```
One of the largest themes in Wheels 4.0 is the ORM. If you last evaluated Wheels and the data-layer feature list felt like it was frozen in 2015, the list in 4.0 is substantially different.

What's new:

Chainable query builder — `model("User").where("status", "active").where("age", ">", 18).whereNotNull("emailVerifiedAt").orderBy("name").limit(25).get()`. Injection-safe, values auto-quoted. Composes with scopes.

Named scopes — `scope(name="active", where="status='active'")`, plus dynamic scope handlers that receive arguments. Chain them: `model("User").active().byRole("admin").recent().findAll()`.

Enums — `enum(property="status", values="draft,published,archived")` auto-generates `isDraft()` / `isPublished()` / `isArchived()` checkers, auto-generates `draft()` / `published()` / `archived()` scopes, and adds inclusion validation. Supports ordered lists and value maps.

Batch processing — `findEach(batchSize=1000, callback=function(user) {...})` loads records in batches internally while your callback sees them one at a time. Memory-efficient for large tables. Works with scopes and conditions.

Bulk insert / upsert — `insertAll(records)` and `upsertAll(records, uniqueBy="email")` emit per-adapter native UPSERT syntax. Seven databases supported: MySQL, PostgreSQL, SQL Server, SQLite, H2, CockroachDB, Oracle.

Polymorphic associations — `belongsTo(polymorphic=true)` stores a type-discriminator column alongside the foreign key; `hasMany(as=...)` reads it.

Advisory locks — `withAdvisoryLock(name="export", callback=function(){ ... })` acquires a database advisory lock and guarantees release via try/finally. Use for coordinating work that shouldn't run concurrently across app instances.

Pessimistic locking — `.forUpdate()` on QueryBuilder emits `SELECT ... FOR UPDATE`.

CockroachDB adapter — the seventh supported database. Full SQL generation, `RETURNING` clause for identity select, `unique_rowid()` PK convention, full test-matrix coverage.

And auto-migrations — `wheels dbmigrate diff User` compares model property definitions against the current DB schema and generates a migration CFC with `up()` and `down()`. Rename detection via explicit hints (authoritative) plus heuristic suggestions (normalized-token + Levenshtein).

Row-by-row before/after: https://github.com/wheels-dev/wheels/blob/develop/docs/releases/wheels-3.0-vs-4.0.md

#CFML #Wheels #ORM #ActiveRecord #WebDevelopment
```

### X / Twitter

**Hero tweet (unnumbered):**
```
The Wheels 4.0 ORM, in one tweet:

• Chainable query builder (`where().orderBy().limit().get()`)
• Named scopes + dynamic scope handlers
• Enums with auto-checkers + auto-scopes
• `findEach` / `findInBatches`
• `insertAll` / `upsertAll` (7 DBs)
• Polymorphic assocs
• Advisory locks + `.forUpdate()`
• Auto-migrations with rename detection
```

**Reply 1:**
```
1/ Injection-safe chainable queries:

  model("User")
      .where("status", "active")
      .where("age", ">", 18)
      .whereNotNull("emailVerifiedAt")
      .whereIn("role", ["admin", "editor"])
      .orderBy("name", "ASC")
      .limit(25)
      .get();

Values auto-quoted. Composes with scopes: `.active().recent().get()`.
```

**Reply 2:**
```
2/ Enums auto-generate the boilerplate:

  enum(property="status", values="draft,published,archived");

Auto-adds:
• `user.isDraft()`, `user.isPublished()`, `user.isArchived()`
• `model("User").draft()`, `.published()`, `.archived()` scopes
• Inclusion validation on save
```

**Reply 3:**
```
3/ Auto-migrations from model diffs:

  wheels dbmigrate diff User
  wheels dbmigrate diff User --rename=full_name:fullName
  wheels dbmigrate diff --write --name=rename_name

Rename detection: explicit hints (authoritative) + heuristic suggestions (normalized-token + Levenshtein).
```

**Reply 4:**
```
4/ Full row-by-row ORM delta:
https://github.com/wheels-dev/wheels/blob/develop/docs/releases/wheels-3.0-vs-4.0.md

Seven databases supported (MySQL, Postgres, SQL Server, SQLite, H2, CockroachDB, Oracle). Native UPSERT on all of them.
```

### GitHub Discussions

**Title:** `Wheels 4.0 ORM — what changed between 3.0 and 4.0`

```markdown
The data layer got more attention in 4.0 than any other subsystem. This post summarizes what's new and how each piece composes with the rest.

## Query layer

**Chainable query builder** ([#1922](https://github.com/wheels-dev/wheels/pull/1922)) — the fluent alternative to raw WHERE strings. Values are auto-quoted, which closes the largest SQL-injection foot-gun in 3.x code.

```cfm
model("User")
    .where("status", "active")
    .where("age", ">", 18)
    .whereNotNull("emailVerifiedAt")
    .whereIn("role", ["admin", "editor"])
    .orderBy("name", "ASC")
    .limit(25)
    .get();
```

Full builder surface: `where`, `orWhere`, `whereNull`, `whereNotNull`, `whereBetween`, `whereIn`, `whereNotIn`, `orderBy`, `limit`, `offset`, `get`.

**Named scopes** ([#1920](https://github.com/wheels-dev/wheels/pull/1920)) — compose query fragments:

```cfm
function config() {
    scope(name="active", where="status = 'active'");
    scope(name="recent", order="createdAt DESC");
    scope(name="byRole", handler="scopeByRole");
}

private struct function scopeByRole(required string role) {
    return {where: "role = '#arguments.role#'"};
}

// Usage
model("User").active().byRole("admin").recent().findAll();
```

**Enums** ([#1921](https://github.com/wheels-dev/wheels/pull/1921)) — named property values with auto-generated checkers, auto-generated scopes, and inclusion validation:

```cfm
enum(property="status", values="draft,published,archived");

// Auto-generated
user.isDraft();              // true/false
user.isPublished();          // true/false
model("User").draft().findAll();
model("User").published().findAll();
```

Also supports value maps: `enum(property="priority", values={low: 0, medium: 1, high: 2})`.

## Persistence layer

**Bulk insert / upsert** ([#2101](https://github.com/wheels-dev/wheels/pull/2101)) — per-adapter native UPSERT:

```cfm
model("User").insertAll([
    {email: "a@example.com", name: "A"},
    {email: "b@example.com", name: "B"}
]);

model("User").upsertAll(
    records=[...],
    uniqueBy="email"
);
```

Supported: MySQL (`ON DUPLICATE KEY UPDATE`), PostgreSQL / CockroachDB / SQLite (`ON CONFLICT`), SQL Server (`MERGE`), H2, Oracle.

**Batch processing** ([#1919](https://github.com/wheels-dev/wheels/pull/1919)) — memory-efficient iteration:

```cfm
model("User").findEach(batchSize=1000, callback=function(user) {
    user.sendReminderEmail();
});

model("User").active().findEach(batchSize=500, callback=function(user) { /* ... */ });
```

## Association layer

**Polymorphic associations** ([#2104](https://github.com/wheels-dev/wheels/pull/2104)):

```cfm
// Comment.cfc
belongsTo(name="commentable", polymorphic=true);

// Post.cfc and Photo.cfc
hasMany(name="comments", as="commentable");
```

Stores a type discriminator alongside the foreign key; reads resolve to the right model.

## Locking

**Advisory locks** ([#2103](https://github.com/wheels-dev/wheels/pull/2103)) — coordinate work that shouldn't run concurrently across app instances:

```cfm
withAdvisoryLock(name="nightly-export", callback=function() {
    // Only one app instance runs this at a time
    runExport();
});
```

try/finally guarantees release even on exception.

**Pessimistic locking** — `.forUpdate()` on QueryBuilder:

```cfm
model("Account").where("id", accountId).forUpdate().first();
```

Emits `SELECT ... FOR UPDATE`. Wrap in a transaction to hold the lock.

## CockroachDB

[#1876](https://github.com/wheels-dev/wheels/pull/1876), [#1986](https://github.com/wheels-dev/wheels/pull/1986), [#1993](https://github.com/wheels-dev/wheels/pull/1993), [#1999](https://github.com/wheels-dev/wheels/pull/1999) — full adapter with `RETURNING` clause identity select, `unique_rowid()` PK convention, and full test-matrix coverage.

## Auto-migrations

[#2102](https://github.com/wheels-dev/wheels/pull/2102), [#2112](https://github.com/wheels-dev/wheels/pull/2112) — generate migration CFCs from model/schema diffs:

```bash
wheels dbmigrate diff User                                    # preview
wheels dbmigrate diff User --rename=full_name:fullName        # explicit rename
wheels dbmigrate diff --write --name=rename_name              # commit to file
wheels dbmigrate diff --threshold=0.85                        # all models
```

Rename detection uses explicit hints (authoritative) and heuristic suggestions (normalized-token + Levenshtein distance, configurable threshold).

## Links

- [Row-by-row 3.0 → 4.0 comparison](https://github.com/wheels-dev/wheels/blob/develop/docs/releases/wheels-3.0-vs-4.0.md)
- [Full audit §1 — ORM & Data Layer](https://github.com/wheels-dev/wheels/blob/develop/docs/releases/wheels-4.0-audit.md)
- [Framework comparison (Rails / Laravel / Django)](https://github.com/wheels-dev/wheels/blob/develop/docs/wheels-vs-frameworks.md)

## Question for the thread

If you've held off adopting Wheels because the ORM felt thin compared to ActiveRecord or Eloquent, which of these would most move the needle for you? And what's still missing?
```

---

## Post 7 — "Testing that matches modern teams"

*Anchors on `.ai/wheels/testing/browser-testing.md` + audit §12. The confidence-to-ship story.*

### Slack (#wheels-dev)

```
Wheels 4.0's testing story got a major upgrade. Three pieces:

• **Browser testing via Playwright Java** — `BrowserTest` base class, fluent DSL (visit, click, fill, assertSee, resize, screenshot, cookies, loginAs). Real Chromium under the hood. `wheels browser setup` to set up.
• **HTTP test client** — `TestClient.visit("/users").assertOk().assertSee("John")`. Assertions for status, body, JSON (`assertJsonPath` with dot notation), redirects, headers, cookies across requests.
• **Parallel test runner** — discovers bundles, partitions across N workers via round-robin, fires parallel HTTP requests, aggregates JSON results.

Plus the inner-loop win: `bash tools/test-local.sh` runs the full core suite on LuCLI + SQLite in ~60s. No Docker. CI matches.

WheelsTest BDD is the only style for new tests. RocketUnit is legacy-only.

<https://github.com/wheels-dev/wheels/blob/develop/docs/releases/wheels-4.0-audit.md|Full audit §12>
```

### LinkedIn

```
The testing surface in Wheels 4.0 is one of the least-discussed but most-impactful changes in the release. Three headline additions, plus a whole inner-loop overhaul.

Browser testing via Playwright Java — a new `BrowserTest` base class drives a real Chromium through a fluent DSL that looks like Laravel Dusk or Capybara if you've used those. Methods for navigation, interaction, keyboard, waiting, scoping, cookies, authentication, dialogs, viewport resize, arbitrary script evaluation, and a full assertion suite. `wheels browser setup` downloads the JARs plus Chromium. CI runs browser specs as part of the normal test suite.

HTTP test client — a new `TestClient` offers a fluent DSL for integration tests: `TestClient.visit("/users").assertOk().assertSee("John")`. Assertions for status codes, body content (`assertSee`, `assertDontSee`, `assertSeeInOrder`), JSON responses (`assertJson` and `assertJsonPath` with dot notation), redirects, headers, and cookies tracked across requests for session support.

Parallel test runner — discovers test bundles, partitions them across N workers via round-robin, fires parallel HTTP requests through `cfthread`, and aggregates JSON results. Configurable worker count and timeout. Speeds up large suites substantially on multi-core runners.

And the inner-loop: `bash tools/test-local.sh` runs the full core test suite on LuCLI + SQLite in about 60 seconds. No Docker. The CI pipeline runs the same stack (Lucee 7 + SQLite), so "works on my machine" and "passes in CI" mean the same thing. Cross-engine testing against Adobe CF, BoxLang, and additional databases is still available via Docker for pre-merge validation.

WheelsTest BDD syntax (`describe` / `it` / `expect`) is the only supported style for new tests in 4.0. Legacy RocketUnit specs continue to run but no new ones should be written.

Audit with per-PR receipts: https://github.com/wheels-dev/wheels/blob/develop/docs/releases/wheels-4.0-audit.md

#CFML #Wheels #Testing #Playwright #WebDevelopment
```

### X / Twitter

**Hero tweet (unnumbered):**
```
Wheels 4.0 testing stack:

• Browser testing via Playwright Java (real Chromium, fluent DSL)
• HTTP test client with JSON / session assertions
• Parallel test runner
• Full core suite on LuCLI + SQLite in ~60s. No Docker.

WheelsTest BDD is the only style for new tests.
```

**Reply 1:**
```
1/ Browser testing DSL:

  this.browser
      .visit("/login")
      .fill("##email", "a@example.com")
      .fill("##password", "secret")
      .click("button[type=submit]")
      .assertUrlContains("/dashboard")
      .assertSee("Welcome");

`wheels browser setup` grabs JARs + Chromium (~370MB).
```

**Reply 2:**
```
2/ HTTP test client:

  TestClient
      .visit("/api/users")
      .assertOk()
      .assertJsonPath("data.0.name", "Alice")
      .assertHeader("Content-Type", "application/json");

Cookies tracked across requests → full session tests without a browser.
```

**Reply 3:**
```
3/ Inner loop:

  bash tools/test-local.sh             # full core suite, ~60s
  bash tools/test-local.sh model       # just model tests
  bash tools/test-local.sh security    # just security tests

Uses LuCLI + SQLite. CI matches. No Docker needed for day-to-day.
```

### GitHub Discussions

**Title:** `Wheels 4.0 testing — Playwright Java, HTTP test client, parallel runner, zero-Docker inner loop`

```markdown
Testing got a major upgrade in 4.0. The list:

## 1. Browser testing (Playwright Java)

[#2113](https://github.com/wheels-dev/wheels/pull/2113), [#2115](https://github.com/wheels-dev/wheels/pull/2115), [#2116](https://github.com/wheels-dev/wheels/pull/2116), [#2121](https://github.com/wheels-dev/wheels/pull/2121), [#2122](https://github.com/wheels-dev/wheels/pull/2122) — new `BrowserTest` base class drives a real Chromium through a fluent DSL wrapping Playwright Java.

```cfm
component extends="wheels.wheelstest.BrowserTest" {
    function run() {
        browserDescribe("Login flow", () => {
            it("logs in and lands on dashboard", () => {
                if (this.browserTestSkipped) return;
                this.browser
                    .visit("/login")
                    .fill("##email", "a@example.com")
                    .fill("##password", "secret")
                    .click("button[type=submit]")
                    .assertUrlContains("/dashboard")
                    .assertSee("Welcome");
            });
        });
    }
}
```

DSL surface: navigation, interaction, keyboard, waiting, scoping (`within`), cookies, auth (`loginAs` / `logout`), dialogs, viewport (`resizeToMobile` / `resizeToTablet` / `resizeToDesktop`), arbitrary `script` evaluation, screenshots, and a full assertion suite (text, visibility, URL, title, query string, form values).

Install: `wheels browser setup` (~370MB — Playwright JARs + Chromium). CI installs and runs browser specs automatically; specs gracefully skip when JARs are missing so local runs without Playwright stay green.

## 2. HTTP test client

[#2099](https://github.com/wheels-dev/wheels/pull/2099) — fluent integration testing without a browser:

```cfm
TestClient
    .visit("/api/users")
    .assertOk()
    .assertJsonPath("data.0.name", "Alice")
    .assertHeader("Content-Type", "application/json");

TestClient
    .followRedirects(false)
    .post("/login", {email: "...", password: "..."})
    .assertRedirect("/dashboard");
```

Full assertion set: status (`assertOk`, `assertStatus`), body (`assertSee`, `assertDontSee`, `assertSeeInOrder`), JSON (`assertJson`, `assertJsonPath` with dot notation), redirects, headers, cookies. Cookies are tracked across requests for session tests.

## 3. Parallel test runner

[#2100](https://github.com/wheels-dev/wheels/pull/2100) — partition test bundles across workers, aggregate results:

- Discovers bundles in the target directory.
- Partitions across N workers via round-robin.
- Fires parallel HTTP requests through `cfthread`.
- Aggregates JSON results into a single report.
- Configurable worker count and timeout.

## 4. Zero-Docker inner loop

`bash tools/test-local.sh` runs the full core test suite on LuCLI + SQLite in ~60s. The CI pipeline runs the same stack ([#2032](https://github.com/wheels-dev/wheels/pull/2032)), so "passes locally" and "passes CI" are the same claim.

```bash
bash tools/test-local.sh              # all core tests
bash tools/test-local.sh model        # model tests only
bash tools/test-local.sh security     # security tests only
bash tools/test-local.sh controller   # controller tests only
```

Cross-engine validation (Adobe CF, BoxLang, MySQL, Postgres, SQL Server, CockroachDB) is still available via Docker for pre-merge. Engine-grouped testing ([#1939](https://github.com/wheels-dev/wheels/pull/1939)) cut the matrix from 42 jobs to 8.

## 5. BDD-only posture

- `testbox` → `wheelstest` namespace rename ([#1889](https://github.com/wheels-dev/wheels/pull/1889)) — new tests extend `wheels.WheelsTest`.
- Legacy RocketUnit removed from core ([#1925](https://github.com/wheels-dev/wheels/pull/1925)) — existing RocketUnit specs continue to work; no new ones.
- `tests/specs/functions/` → `tests/specs/functional/` ([#1872](https://github.com/wheels-dev/wheels/pull/1872)).

## Links

- [Browser testing reference](https://github.com/wheels-dev/wheels/blob/develop/.ai/wheels/testing/browser-testing.md)
- [Full audit §12 — Testing infrastructure](https://github.com/wheels-dev/wheels/blob/develop/docs/releases/wheels-4.0-audit.md)

## Question for the thread

Browser testing is new-for-CFML territory. If you've adopted Playwright / Capybara / Dusk in another stack, what's the single feature from that toolkit that would most make you trust `BrowserTest` for the hairier specs? Good input for 4.0.x point releases.
```

---

## Post 8 — "Differentiators — multi-tenancy and background jobs"

*Anchors on the multi-tenancy + jobs sections. The "what makes Wheels different from Rails 8" beat.*

### Slack (#wheels-dev)

```
Two features in Wheels 4.0 that don't have straight equivalents in Rails / Laravel / Django:

**Multi-tenancy — in-core.** (#1951)
Per-request datasource switching is built into the framework, not a third-party gem/package. Tenant-aware background jobs work natively. No middleware hack required.

**Background jobs — zero Redis.** (#1934)
DB-backed job queue. `wheels jobs work/status/retry/purge/monitor` CLI commands. Persistent daemon with optimistic locking, timeout recovery, live dashboard. Configurable exponential backoff. Auto-creates the `wheels_jobs` table on first use — no migration needed.

Comparable articles in Rails/Laravel/Django presuppose Redis (Sidekiq, Horizon) or Celery. Wheels ships the queue as a first-class capability using the database you already have.

Bonus: SSE pub/sub channels (#1940) — `subscribeToChannel()`, `publish()`, `poll()` with DB-backed event persistence.

<https://github.com/wheels-dev/wheels/blob/develop/docs/releases/wheels-4.0-audit.md|Full audit §7 and §9>
```

### LinkedIn

```
Most framework release posts lead with parity — "here's the feature Rails has, now we have it too." This post is about the opposite: two Wheels 4.0 features that don't have clean equivalents in the peer frameworks.

First: multi-tenancy is in-core. Per-request datasource switching is a built-in framework capability, not a third-party gem or package you add on. That means tenant-aware background jobs, tenant-aware connection pooling, and tenant-aware middleware all compose naturally — they aren't layered over a monkey-patched ORM. For SaaS apps with schema-per-tenant or database-per-tenant models, this is a material DX improvement over the Rails `apartment` / Laravel tenancy-package route.

Second: the background-job queue is database-backed, zero Redis. A new job worker daemon — `wheels jobs work` — runs as a persistent process and pulls from the `wheels_jobs` table with optimistic locking and timeout recovery. Configurable exponential backoff per job class. A live dashboard via `wheels jobs monitor`. Retry-failed and purge-completed CLI commands. The `wheels_jobs` table is auto-created on first enqueue — no migration step.

Why does that matter? Comparable articles on background jobs in Rails, Laravel, or Django presuppose Redis (Sidekiq, Horizon, or RQ) or Celery with RabbitMQ. For small-to-mid apps, that's a piece of shared infrastructure you now need to run, monitor, and back up. Wheels 4.0 ships the queue using the database you already have.

And as a bonus: SSE pub/sub channels (not websockets — SSE stays cross-engine-uniform) now support a channel subscription model with DB-backed event persistence, so you get real-time fan-out without Redis in the middle either.

This is the "what makes Wheels different" beat. Neither feature is going to unseat Rails. But if you're picking a framework for a multi-tenant SaaS without wanting to run a separate cache/queue tier, Wheels 4.0 just became a much more serious option.

https://github.com/wheels-dev/wheels/blob/develop/docs/releases/wheels-4.0-audit.md

#CFML #Wheels #Multitenancy #BackgroundJobs #SaaS #WebDevelopment
```

### X / Twitter

**Hero tweet (unnumbered):**
```
Two Wheels 4.0 features that don't have clean equivalents in Rails/Laravel/Django:

• Multi-tenancy in-core — per-request datasource switching, tenant-aware background jobs natively
• Background jobs with zero Redis — DB-backed queue, persistent daemon, live dashboard

Ship the queue with the database you already have.
```

**Reply 1:**
```
1/ Multi-tenancy:

Per-request datasource switching is built in. Tenant resolver middleware picks the datasource, the whole request stack (models, jobs, SSE) uses it.

No third-party package. No `apartment`-style monkey-patching. Works with schema-per-tenant and database-per-tenant.
```

**Reply 2:**
```
2/ Background jobs:

  wheels jobs work                      # persistent daemon
  wheels jobs status                    # per-queue breakdown
  wheels jobs monitor                   # live dashboard
  wheels jobs retry --queue=mailers
  wheels jobs purge --completed --older-than=30

DB-backed. `wheels_jobs` table auto-created. No Redis, no Sidekiq, no Celery.
```

**Reply 3:**
```
3/ Configurable backoff per job:

  component extends="wheels.Job" {
      function config() {
          this.queue = "mailers";
          this.maxRetries = 5;
          this.baseDelay = 2;    // seconds
          this.maxDelay = 3600;  // seconds
      }
  }

Formula: `Min(baseDelay * 2^attempt, maxDelay)`.
```

**Reply 4:**
```
4/ Plus SSE pub/sub channels (not websockets — SSE stays cross-engine):

  subscribeToChannel("notifications")
  publish(channel="notifications", data=...)

DB-backed event persistence. Channel fan-out without Redis in the middle.

Full audit:
https://github.com/wheels-dev/wheels/blob/develop/docs/releases/wheels-4.0-audit.md
```

### GitHub Discussions

**Title:** `Wheels 4.0 — multi-tenancy and background jobs without external services`

```markdown
Two capabilities in 4.0 that are differentiators rather than parity additions. Both hit the same design theme: ship production-grade features using the database you already have, rather than requiring Redis / Sidekiq / Celery as a separate tier.

## 1. Multi-tenancy in-core

[#1951](https://github.com/wheels-dev/wheels/pull/1951) — per-request datasource switching built into the framework. Not a third-party package, not a middleware hack, not an ORM monkey-patch.

How it works: a tenant resolver (middleware or controller filter) picks the datasource for the current request. Models, background jobs, SSE subscriptions, and DI-container request-scoped services all use the resolved datasource. Schema-per-tenant and database-per-tenant are both supported.

```cfm
// Middleware resolves tenant from subdomain
component {
    public void function handle(req, next) {
        var tenant = findTenantForSubdomain(req.cgi.http_host);
        req.wheelsTenant = tenant;
        // Framework picks up req.wheelsTenant from here
        next(req);
    }
}

// Models and jobs automatically use the tenant datasource
model("Invoice").findAll();  // reads from tenant DB
var job = new ExportJob();
job.enqueue(data={...});     // writes to tenant's wheels_jobs table
```

Background jobs are tenant-aware without extra configuration — the job row stores the tenant, the worker reconstructs the tenant context when running it.

## 2. Background jobs — zero Redis

[#1934](https://github.com/wheels-dev/wheels/pull/1934) — DB-backed job queue with a persistent worker daemon.

**Define a job:**

```cfm
// app/jobs/SendWelcomeEmailJob.cfc
component extends="wheels.Job" {
    function config() {
        super.config();
        this.queue = "mailers";
        this.maxRetries = 5;
        this.baseDelay = 2;
        this.maxDelay = 3600;
    }

    public void function perform(struct data = {}) {
        sendEmail(to=data.email, subject="Welcome!");
    }
}
```

**Enqueue from anywhere:**

```cfm
var job = new app.jobs.SendWelcomeEmailJob();
job.enqueue(data={email: user.email});
job.enqueueIn(seconds=300, data={...});   // delayed
job.enqueueAt(runAt=scheduledDate, data={...});
```

**Run the worker daemon:**

```bash
wheels jobs work                           # all queues
wheels jobs work --queue=mailers --interval=3
wheels jobs status                         # per-queue breakdown
wheels jobs status --format=json           # JSON output
wheels jobs retry --queue=mailers          # retry failed jobs
wheels jobs purge --completed --failed --older-than=30
wheels jobs monitor                        # live TUI dashboard
```

**Features:**

- Optimistic locking so multiple workers can run against the same queue without duplicate processing.
- Timeout recovery — abandoned jobs are re-queued.
- Configurable exponential backoff per job class: `Min(baseDelay * 2^attempt, maxDelay)`.
- Live dashboard via `wheels jobs monitor`.
- Auto-creates `wheels_jobs` table on first enqueue or worker start — no migration.

## 3. SSE with pub/sub channels

[#1940](https://github.com/wheels-dev/wheels/pull/1940) — bonus. SSE (not websockets — SSE stays cross-engine-uniform) now supports channel subscriptions with DB-backed event persistence.

```cfm
subscribeToChannel(name="notifications", userId=currentUser.id);
publish(channel="notifications", data={type: "post", postId: 42});
```

Channel fan-out without Redis in the middle. `wheels_events` table backs the persistence. Dual implementation: `DatabaseAdapter` for durability, in-memory for low-latency single-instance deployments.

## Why this matters

The default framework stack for production Wheels 4.0 apps looks like this:

- CFML engine (Lucee or Adobe CF) running the app.
- A database (any supported — CockroachDB, Postgres, MySQL, SQL Server, SQLite, H2, Oracle).
- That's it.

No Redis, no Sidekiq, no Celery, no separate queue tier. For small-to-mid apps, that's a materially simpler production footprint than the default Rails / Laravel / Django stack that most framework articles presuppose.

## Links

- [Full audit §7 — Background jobs](https://github.com/wheels-dev/wheels/blob/develop/docs/releases/wheels-4.0-audit.md)
- [Full audit §9 — Multi-tenancy](https://github.com/wheels-dev/wheels/blob/develop/docs/releases/wheels-4.0-audit.md)
- [Framework comparison — where Wheels now stands vs peers](https://github.com/wheels-dev/wheels/blob/develop/docs/wheels-vs-frameworks.md)

## Question for the thread

Multi-tenancy and the DB-backed job queue both trade raw performance ceiling for operational simplicity. Are there specific scale points where you'd reach for Redis-backed queuing over the built-in daemon? Useful input for 4.0.x tuning priorities.
```

---

## Post 9 — "The zero-Docker developer experience"

*Anchors on LuCLI docs + `tools/test-local.sh`. The inner-loop DX closer.*

### Slack (#wheels-dev)

```
Wheels 4.0 ships with LuCLI — a Java-native CFML CLI that replaces the CommandBox-based inner loop. The practical upshot:

**First 60 seconds:**
```
wheels new myapp
cd myapp
wheels start
```
You're serving HTTP. No Docker, no CommandBox, no homebrew-of-homebrews.

**Running tests:**
```
bash tools/test-local.sh              # full core suite, ~60s
bash tools/test-local.sh model        # model tests only
```
Uses LuCLI + SQLite. CI runs the same stack — "passes locally" = "passes CI".

**Cross-engine testing** when you need it (pre-merge, matrix coverage):
```
docker compose up -d lucee6 adobe2025
curl http://localhost:60006/wheels/core/tests?db=sqlite&format=json
```

LuCLI is installed standalone (`brew install lucli`) or comes with the framework. CLI surface covers generate, migrate, test, seed, analyze, jobs, deploy, mcp.

Day-to-day: no Docker. Pre-merge: Docker for the matrix. That's the deal.
```

### LinkedIn

```
The developer experience in Wheels 4.0 is quietly one of the largest shifts in the release. The shift is: no Docker required for day-to-day work.

Pre-4.0, running the Wheels test suite locally meant bringing up a Docker Compose stack with CommandBox, an engine (Lucee 5/6 or Adobe CF), and a database. A 60-second turnaround on a test change was a 5-minute turnaround after Docker startup. For day-to-day development this created real friction — you'd write three tests and then go get coffee while Docker came up.

In 4.0 the inner loop is LuCLI-based. LuCLI is a Java-native CFML CLI that installs via Homebrew (`brew install lucli`) and runs Lucee 7 directly on the JVM, reading SQLite for persistence. The workflow:

- `wheels new myapp` — scaffold a new app.
- `cd myapp && wheels start` — serving HTTP in a few seconds.
- `bash tools/test-local.sh` — full core test suite in about 60 seconds. No Docker.
- `wheels generate model User email:string` — generators run in-process, no external CLI overhead.

The CI pipeline runs on the same LuCLI + SQLite stack — "passes locally" and "passes CI" are the same claim. Cross-engine validation (Adobe CF 2018-2025, BoxLang, MySQL/Postgres/SQL Server/CockroachDB) is still available via Docker Compose for pre-merge coverage, but it's opt-in rather than table stakes for every commit.

The CLI surface covers what you'd expect: `generate` / `migrate` / `test` / `seed` / `analyze` / `jobs` / `deploy` / `mcp`. The `mcp` command in particular wires Wheels tools into AI coding assistants via stdio MCP — configure your IDE with `{"mcpServers":{"wheels":{"command":"wheels","args":["mcp","wheels"]}}}` and your assistant can call `wheels_generate`, `wheels_migrate`, `wheels_test` directly.

If you last tried Wheels and bounced off the CommandBox-era setup, the 4.0 inner loop is a materially different experience.

https://github.com/wheels-dev/wheels/blob/develop/docs/releases/wheels-4.0-audit.md

#CFML #Wheels #DeveloperExperience #LuCLI #WebDevelopment
```

### X / Twitter

**Hero tweet (unnumbered):**
```
Wheels 4.0 day-to-day workflow, full list:

  wheels new myapp
  cd myapp
  wheels start
  bash tools/test-local.sh

No Docker. No CommandBox. Full test suite in ~60s. Same stack as CI.

Cross-engine matrix via Docker when you need it.
```

**Reply 1:**
```
1/ Inner loop:

  bash tools/test-local.sh              # full core suite ~60s
  bash tools/test-local.sh model        # model tests only
  bash tools/test-local.sh controller   # controller tests only
  bash tools/test-local.sh security     # security tests only

Uses LuCLI + SQLite. CI runs identical stack.
```

**Reply 2:**
```
2/ Install:

  brew install lucli    # or download from GitHub releases

Requires Java 21.

`wheels` binary ships with the framework. `generate`, `migrate`, `test`, `seed`, `analyze`, `jobs`, `deploy`, `mcp`.
```

**Reply 3:**
```
3/ MCP for AI coding assistants:

  wheels mcp setup      # generates .mcp.json + .opencode.json

Or configure manually:
  {"mcpServers":{"wheels":{"command":"wheels","args":["mcp","wheels"]}}}

Your IDE's assistant can now call `wheels_generate`, `wheels_migrate`, `wheels_test` directly.
```

### GitHub Discussions

**Title:** `Wheels 4.0 — the inner loop doesn't need Docker anymore`

```markdown
This post is about the least-advertised major change in 4.0: the developer experience overhaul. Short version — you no longer need Docker running to be productive against the Wheels codebase or against a Wheels app.

## The 60-second workflow

```bash
# One-time install
brew install lucli              # or download from GitHub releases
# Requires Java 21

# Scaffold
wheels new myapp
cd myapp
wheels start

# You're serving HTTP.

# Generate
wheels generate model User email:string firstName:string
wheels generate controller Users index create show
wheels generate scaffold Post title:string body:text

# Test
bash tools/test-local.sh              # full core suite, ~60s
bash tools/test-local.sh model        # model tests only
```

No Docker. No CommandBox. No external CLI alongside the framework CLI.

## Why

Pre-4.0, the test loop looked like this:

1. Bring up Docker Compose with an engine container + a database container (~60-120s cold).
2. Hit an HTTP endpoint to run the test suite.
3. Wait for results.

After a few rounds of "I have to wait for Docker" that friction hurts. [#2063](https://github.com/wheels-dev/wheels/pull/2063) moved local testing to LuCLI + SQLite — same stack CI uses ([#2032](https://github.com/wheels-dev/wheels/pull/2032)), so "passes locally" and "passes CI" became the same claim.

Cross-engine testing (Adobe CF, BoxLang, MySQL, Postgres, SQL Server, CockroachDB) is still available via Docker for pre-merge coverage. The matrix job count went from 42 to 8 ([#1939](https://github.com/wheels-dev/wheels/pull/1939)) via engine-grouped testing — substantial CI speedup.

## CLI surface

The `wheels` binary ships with the framework. Day-to-day commands:

| Task | Command |
|------|---------|
| Scaffold app | `wheels new myapp` |
| Start server | `wheels start` |
| Generate | `wheels generate model/controller/scaffold/admin/seed ...` |
| Migrate | `wheels migrate latest / up / down / info` |
| Test | `wheels test run` or `bash tools/test-local.sh` |
| Seed | `wheels seed` |
| Reload | `wheels reload` |
| Analyze | `wheels analyze` |
| Jobs daemon | `wheels jobs work / status / retry / purge / monitor` |
| Deploy | `wheels deploy` (see Post 4) |
| MCP | `wheels mcp wheels` (stdio MCP server) |

Auto-migration diff-from-model:
```bash
wheels dbmigrate diff User --rename=full_name:fullName --write --name=rename_name
```

## AI coding assistant integration

The `mcp` command wires Wheels tools into AI coding assistants via stdio MCP. Configure your IDE:

```json
{"mcpServers":{"wheels":{"command":"wheels","args":["mcp","wheels"]}}}
```

Or run `wheels mcp setup` and it generates `.mcp.json` + `.opencode.json` automatically. Your assistant can then call `wheels_generate`, `wheels_migrate`, `wheels_test`, `wheels_seed`, `wheels_routes`, `wheels_info` directly.

## Links

- [Full audit §13 — CLI & LuCLI](https://github.com/wheels-dev/wheels/blob/develop/docs/releases/wheels-4.0-audit.md)
- [`wheels deploy` deep dive (Post 4)](#) — for the deploy side
- [Browser testing reference](https://github.com/wheels-dev/wheels/blob/develop/.ai/wheels/testing/browser-testing.md)

## Question for the thread

If you last used the Wheels CLI on CommandBox and bounced off, which friction point was the one that made you stop? Ergonomics feedback on the new `wheels` binary is especially welcome before 4.0 GA.
```

---

## Post 10 — "Wheels 4.0 is here"

*The GA announcement. Swap all "coming" / "on the way" / "preview" → present tense. Ties the arc together.*

### Slack (#wheels-dev)

```
Wheels 4.0 is out.

260+ PRs over ~15 weeks since 3.0.0, ~75 user-visible features, 40+ security-hardening PRs, 7 breaking changes (all with detect/fix/opt-out docs).

Headlines:
• `wheels deploy` — Kamal-style zero-downtime deploys over SSH (no Ruby needed)
• Data layer — bulk insert/upsert, polymorphic assocs, advisory locks, CockroachDB adapter, chainable query builder, enums, scopes
• Testing — Playwright Java browser testing, HTTP test client, parallel runner
• Multi-tenancy — in-core, per-request datasource switching
• Background jobs — DB-backed, zero Redis, live dashboard
• Security — 40+ hardening PRs, secure-by-default
• DX — LuCLI zero-Docker inner loop, ~60s test suite, CI matches local

Upgrade guide: <https://github.com/wheels-dev/wheels/blob/develop/docs/src/introduction/upgrading-to-4.0.md|upgrading-to-4.0.md>
CHANGELOG: <https://github.com/wheels-dev/wheels/blob/develop/CHANGELOG.md|CHANGELOG.md>

Thanks to @bpamiri, @zainforbjs, @chapmandu, @mlibbe, @MukundaKatta, and dependabot for the work that landed this release.
```

### LinkedIn

```
Wheels 4.0 is out today.

This release took about 15 weeks between the 3.0.0 stable tag and GA. 260+ merged PRs, approximately 75 distinct user-visible features and changes, 40+ security-hardening PRs, and 7 breaking changes — each documented in the upgrade guide with a detect / fix / opt-out pattern.

What landed:

`wheels deploy` — a port of Basecamp's Kamal into the Wheels CLI. Zero-downtime Dockerized deploys to Linux servers over SSH. No Ruby runtime, no gem install. Byte-compatible with Kamal on the server side.

Data layer modernization — bulk insert and upsert with per-adapter native UPSERT across seven databases, polymorphic associations, advisory locks, pessimistic locking, a chainable injection-safe query builder, enums with auto-generated checkers and scopes, batch processing, and a CockroachDB adapter.

Testing — browser testing via Playwright Java with a fluent DSL, an HTTP test client for integration tests, a parallel test runner, and a zero-Docker inner loop where the full core suite runs in about 60 seconds on LuCLI + SQLite.

Multi-tenancy — per-request datasource switching, built into the framework rather than a third-party package. Tenant-aware background jobs work natively.

Background jobs — database-backed queue, persistent worker daemon, live dashboard, configurable exponential backoff. No Redis required.

Security — 40+ hardening PRs across SQL injection, path traversal, the console and reload endpoints, the CORS/CSRF/HSTS defaults, the rate limiter, and MCP. Secure by default.

Developer experience — LuCLI-native CLI, no Docker required for day-to-day work, CI runs the same stack as local. AI coding assistants integrate via stdio MCP.

And where Wheels now stands against the peer frameworks — most of the rows that said "No" for CFWheels against Rails, Laravel, and Django now say "Yes" for Wheels 4.0.

Upgrade guide: https://github.com/wheels-dev/wheels/blob/develop/docs/src/introduction/upgrading-to-4.0.md
CHANGELOG: https://github.com/wheels-dev/wheels/blob/develop/CHANGELOG.md
Full audit: https://github.com/wheels-dev/wheels/blob/develop/docs/releases/wheels-4.0-audit.md
Framework comparison: https://github.com/wheels-dev/wheels/blob/develop/docs/wheels-vs-frameworks.md
3.0 → 4.0 row-by-row: https://github.com/wheels-dev/wheels/blob/develop/docs/releases/wheels-3.0-vs-4.0.md

Thanks to everyone who contributed code, filed issues, tested release candidates, and pushed for corrections in the audit. The full contributor list is in the release notes.

#CFML #Wheels #WebDevelopment #OpenSource #ReleaseNotes
```

### X / Twitter

**Hero tweet (unnumbered):**
```
Wheels 4.0 is out.

260+ PRs, ~15 weeks, ~75 user-visible features, 40+ security-hardening PRs, 7 breaking changes (all with migration docs).

Upgrade guide:
https://github.com/wheels-dev/wheels/blob/develop/docs/src/introduction/upgrading-to-4.0.md
```

**Reply 1:**
```
1/ Headlines:

• `wheels deploy` — Kamal-style deploys, no Ruby
• Bulk upsert, polymorphic assocs, advisory locks, CockroachDB
• Browser testing (Playwright Java), parallel runner
• Multi-tenancy in-core
• Zero-Redis background jobs
• 40+ security PRs, secure-by-default
• Zero-Docker inner loop (~60s test suite)
```

**Reply 2:**
```
2/ Framework parity — where 4.0 lands against Rails 8 / Laravel 12 / Django 5:

https://github.com/wheels-dev/wheels/blob/develop/docs/wheels-vs-frameworks.md

Most of the rows that said "No" for CFWheels now say "Yes" for Wheels 4.0.
```

**Reply 3:**
```
3/ On Wheels 3.x? The row-by-row before/after:
https://github.com/wheels-dev/wheels/blob/develop/docs/releases/wheels-3.0-vs-4.0.md

Each row tagged New / Formalized / Hardened / Fixed / Breaking / Removed with PR links. Pairs with the upgrade guide.
```

**Reply 4:**
```
4/ Thanks to @bpamiri, @zainforbjs, @chapmandu, @mlibbe, @MukundaKatta, and dependabot for the work that landed this release.

If 4.0 unblocks a project you've been deferring, we'd love to hear about it.
```

### GitHub Discussions

**Title:** `Wheels 4.0.0 — GA release notes`

```markdown
Wheels 4.0.0 is released today.

## By the numbers

- **260+ merged PRs** across ~15 weeks since the 3.0.0 stable tag.
- **~75 distinct user-visible features and changes.**
- **40+ security-hardening PRs** — a full section in the audit.
- **7 breaking changes** — each covered in the upgrade guide with detect / fix / opt-out guidance.

## Headlines

- **`wheels deploy`** — port of Basecamp's Kamal into the Wheels CLI. Zero-downtime Dockerized deploys to Linux servers over SSH. No Ruby runtime. Byte-compatible with Kamal on the server side.
- **Data layer** — bulk insert/upsert with per-adapter native UPSERT (7 databases), polymorphic associations, advisory locks, pessimistic locking, chainable injection-safe query builder, enums, named scopes, batch processing, CockroachDB adapter, auto-migrations from model diffs with rename detection.
- **Testing** — browser testing via Playwright Java, HTTP test client, parallel test runner, WheelsTest BDD as the sole style for new tests.
- **Multi-tenancy** — per-request datasource switching in-core. Tenant-aware background jobs work natively.
- **Background jobs** — DB-backed queue with persistent worker daemon, optimistic locking, timeout recovery, configurable exponential backoff, live dashboard. No Redis.
- **Security** — 40+ hardening PRs across SQL injection, path traversal, console/reload endpoints, CORS/CSRF/HSTS defaults, rate limiter, MCP. Secure by default.
- **Middleware pipeline** — first-class middleware layer with built-in rate limiting, CORS, security headers, request ID.
- **Router modernization** — `group()`, typed constraints (`whereNumber`, `whereAlpha`, `whereUuid`, `whereSlug`, `whereIn`), API versioning, route model binding, indexed lookup.
- **DI container** — request-scoped services, declarative `inject()`, auto-wiring, interface binding.
- **Package system** — `packages/` → `vendor/` activation model with dependency graph, per-package error isolation.
- **Engine adapters** — dedicated modules for Lucee, Adobe CF, BoxLang. Railo dropped.
- **Developer experience** — LuCLI-native CLI, zero-Docker inner loop, ~60s full test suite on SQLite. CI runs the same stack.
- **AI integration** — stdio MCP (`wheels mcp wheels`) for IDE assistant integration. Auto-generates `.mcp.json` via `wheels mcp setup`.
- **Vite pipeline** — transitive `modulepreload` + CSS resolution for multi-entry Vite builds.

## Breaking changes (7)

Full detect / fix / opt-out guidance for each in the [upgrade guide](https://github.com/wheels-dev/wheels/blob/develop/docs/src/introduction/upgrading-to-4.0.md):

1. `wheels snippets` renamed to `wheels generate snippets`.
2. CFWheels → Wheels rebrand in active code namespaces.
3. `testbox` → `wheelstest` namespace (new tests extend `wheels.WheelsTest`).
4. `tests/specs/functions/` → `tests/specs/functional/`.
5. Legacy RocketUnit removed from core (existing specs still run).
6. CORS default: wildcard → deny-all.
7. `allowEnvironmentSwitchViaUrl` false in production; non-empty reload password required.

The [Legacy Compatibility Adapter](https://github.com/wheels-dev/wheels/blob/develop/docs/releases/wheels-4.0-audit.md) provides a soft-landing path for staged migrations.

## Where Wheels now stands

Against Rails 8, Laravel 12, and Django 5, most of the rows that said "No" for CFWheels now say "Yes" for Wheels 4.0. Honest remaining gaps:

- Ecosystem size — smaller than peer frameworks; not a short-term fix.
- Bidirectional WebSocket — intentional non-goal; SSE with pub/sub channels is the cross-engine-uniform primitive.
- Asset-pipeline maturity — Vite integration improved in 4.0 but newer than Rails' / Laravel's.

Full comparison: https://github.com/wheels-dev/wheels/blob/develop/docs/wheels-vs-frameworks.md

## Links

- [Upgrade guide](https://github.com/wheels-dev/wheels/blob/develop/docs/src/introduction/upgrading-to-4.0.md) — start here if you're on 3.x.
- [CHANGELOG](https://github.com/wheels-dev/wheels/blob/develop/CHANGELOG.md) — the canonical what-changed list.
- [Full feature audit](https://github.com/wheels-dev/wheels/blob/develop/docs/releases/wheels-4.0-audit.md) — PR-level receipts for every user-visible change.
- [3.0 → 4.0 row-by-row](https://github.com/wheels-dev/wheels/blob/develop/docs/releases/wheels-3.0-vs-4.0.md) — only rows that changed; each tagged and linked.
- [Framework comparison](https://github.com/wheels-dev/wheels/blob/develop/docs/wheels-vs-frameworks.md) — where 4.0 lands against peer frameworks.
- Deployment: [landing](https://github.com/wheels-dev/wheels/blob/develop/web/sites/guides/src/content/docs/v4-0-0-snapshot/deployment/index.mdx), [first deploy](https://github.com/wheels-dev/wheels/blob/develop/web/sites/guides/src/content/docs/v4-0-0-snapshot/deployment/first-deploy.mdx), [migrating from Kamal](https://github.com/wheels-dev/wheels/blob/develop/web/sites/guides/src/content/docs/v4-0-0-snapshot/deployment/migrating-from-kamal.mdx).

## Contributors

Thanks to @bpamiri (Peter Amiri), @zainforbjs, @chapmandu, @mlibbe, @MukundaKatta, plus Dependabot. And to everyone who filed issues, tested release candidates, and pushed for corrections in the audit.

## What's next

4.0.x point releases will focus on asset-pipeline maturity (the known remaining peer-framework gap), documentation polish, and ergonomics feedback from early adopters. The [follow-ups section of the audit](https://github.com/wheels-dev/wheels/blob/develop/docs/releases/wheels-4.0-audit.md) tracks specific candidates.

If Wheels 4.0 unblocks a project you've been deferring, we'd love to hear about it in this thread.
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
