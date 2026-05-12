# Wheels 4.0 Guides — Phase 2b-Advanced Implementation Plan (Digging Deeper)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the Digging Deeper section — 14 task-oriented how-to pages covering the advanced features Wheels ships beyond core MVC. Consolidate the corresponding `.ai/wheels/` subdirectories into user docs as each section lands.

**Architecture:** Same rhythm as Phase 2a — each page authored directly in Starlight-native MDX, `{test:compile}` for CFML fragments, subagent-driven content writing with harness-passing as the review gate. Each page's `.ai/` source(s) get deleted in the same commit. For sections that touch framework behavior surfaced during Phase 2a subagent drift audits, apply those known corrections up front.

**Tech Stack:** Astro 5 + Starlight 0.34 + MDX. Node 22+ ESM harness. `wheels` CLI v0.3.5-SNAPSHOT+ (framework v4.0.0). Existing verify-docs harness with three drivers (cli, compile, tutorial).

**Base:** Branch `claude/lucid-thompson-b8c121` at Phase 2a head `0882d169c`. All commits land on this same branch (single final merge to develop happens at end of Phase 2c, per original spec).

**Review model (pragmatic split unchanged from Phase 2a):**
- Content pages — subagent-driven; harness + build + visual review via Cloudflare preview
- Integration tasks (sidebar audit, cross-link pass, `.ai/` cleanup) — inline
- End-of-phase final review — single `pr-review-toolkit:code-reviewer` subagent across the full Phase 2b-Advanced diff

**Prologue — policy decisions carried from Phase 2a:**

1. **Kamal is the committed deploy path.** Authentication Patterns (Task 1) and any page that references deploy-time secrets name Kamal explicitly, not "your deploy tool."
2. **`.ai/` folder consolidates into user docs.** Same rule as Phase 2a: each new page's commit deletes its `.ai/` equivalent. Phase 2c's final audit handles any stragglers.
3. **Known API drift from Phase 2a to apply:** Any page that references service resolution should prefer `service("authenticator")` (short form) over `application.wo.service("authenticator")` where both work. Tutorial Part 6b uses the long form; Phase 2b-Advanced Auth page should document the short form as canonical and note the long form is equivalent.
4. **Known framework gap: bcrypt.** Auth Patterns (Task 1) documents salted SHA-256 as a stopgap with a loud caveat that bcrypt isn't shipped. Cross-link to the framework gap tracker. When gap #4 ships, revisit.
5. **Known framework gap: package install.** Packages (Task 10) documents the current manual `cp -r packages/<name> vendor/<name>` pattern and explicitly notes no `wheels package install` exists yet. When framework gap #2 ships, revisit.
6. **Turbo loaded via CDN, not Hotwire package.** Tutorial Part 4 showed CDN-loading; confirm Packages page treats the `wheels-hotwire` package as aspirational until the package-install gap closes.

---

## File Structure

### New files — Digging Deeper (13 new + 1 rewrite)

All under `web/sites/guides/src/content/docs/v4-0-0-snapshot/digging-deeper/`:

| Path | Responsibility |
|------|----------------|
| `authentication-patterns.mdx` | Session auth hand-rolled + built-in `SessionStrategy`; JWT/token strategies overview |
| `authorization-and-filters.mdx` | Ownership checks, role-based filters, `verifies` checks, policy patterns |
| `background-jobs.mdx` | Job queue, worker process, retries/backoff, priority, monitoring |
| `caching.mdx` | Action caching, fragment caching, page caching, cache stores, invalidation |
| `sending-email.mdx` | **Rewrite** of Phase 0 sample — add background-job enqueuing, multi-part HTML/text, attachments |
| `file-uploads-and-downloads.mdx` | Multipart uploads, storage backends, validation, streaming downloads, `fileField` |
| `server-sent-events.mdx` | `renderSSE`, `initSSEStream` / `sendSSEEvent` / `closeSSEStream`, browser EventSource |
| `internationalization.mdx` | Locale detection, translation files, view helpers (`t()`), pluralization, date/number formatting |
| `multi-tenancy.mdx` | Tenant resolver middleware, per-request tenant scope, shared models, schema-per-tenant vs row-scoping |
| `packages.mdx` | Activating first-party packages, `package.json` manifest, writing your own package, publishing |
| `route-model-binding.mdx` | Per-resource vs global binding, the dev-mode warning, custom binding sources |
| `cors.mdx` | Cors middleware, allowed origins, credentials mode, preflight caching |
| `rate-limiting.mdx` | Three strategies (fixed-window / sliding-window / token-bucket), memory vs database storage, per-IP vs per-API-key keying |
| `dependency-injection-usage.mdx` | Practical DI patterns — strategy swapping in tests, per-request resolvers, factory registration |

### Modified files

| Path | Change |
|------|--------|
| `web/sites/guides/src/content/docs/v4-0-0-snapshot/digging-deeper/index.mdx` | Replace the Phase 0 placeholder with a section landing page enumerating all 14 topics |
| `web/sites/guides/src/sidebars/v4-0-0-snapshot.json` | Add all 14 new page entries under Digging Deeper (currently just `sending-email`) |

### Deleted files — `.ai/` consolidation

| Deleted as part of | What gets removed |
|---------------------|-------------------|
| Task 1 (Authentication Patterns) | `.ai/wheels/patterns/authentication.md`, `.ai/wheels/models/user-authentication.md` |
| Task 2 (Authorization & Filters) | `.ai/wheels/patterns/crud.md` (filter patterns sit here; evaluate at task time) |
| Task 3 (Background Jobs) | `.ai/wheels/jobs/overview.md` |
| Task 4 (Caching) | (no direct `.ai/` source — if a caching doc exists in `.ai/`, delete it then; otherwise skip) |
| Task 5 (Sending Email rewrite) | No `.ai/` delete — already removed in Phase 2a Task 22 |
| Task 6 (File Uploads & Downloads) | `.ai/wheels/files/downloads.md` |
| Task 7 (Server-Sent Events) | `.ai/wheels/controllers/sse.md` |
| Task 8 (Internationalization) | (no direct `.ai/` source — handle at task time) |
| Task 9 (Multi-tenancy) | `.ai/wheels/configuration/multi-tenancy.md`, `.ai/wheels/models/shared-models.md` |
| Task 10 (Packages) | `.ai/wheels/packages/overview.md`, `.ai/wheels/integration/modern-frontend-stack.md` (if on-topic) |
| Task 11 (Route Model Binding) | (no direct `.ai/` source — handle inline) |
| Task 12 (CORS) | (no direct `.ai/` source — pull from `vendor/wheels/middleware/Cors.cfc`) |
| Task 13 (Rate Limiting) | (no direct `.ai/` source — pull from `vendor/wheels/middleware/RateLimiter.cfc`) |
| Task 14 (Dependency Injection Usage) | (no direct `.ai/` source — builds on Task 5 concept page from Phase 2a) |
| Task 15 (Security Hardening — NOT A DIGGING DEEPER PAGE per spec, but covers CSRF/HTTPS content) | `.ai/wheels/security/csrf-protection.md`, `.ai/wheels/security/https-detection.md`, `.ai/wheels/configuration/security.md` — these consolidate INTO existing Phase 2a validation/controllers content + a dedicated security how-to. **See Task 15 below.** |

### Task 15 note — Security Hardening is out-of-scope here but the `.ai/` stragglers are in-scope

The original spec doesn't list a "Security Hardening" page under Digging Deeper (spec § 4). It's implied by controller rendering / form helpers / validation pages already covering CSRF and escaping. Three `.ai/` security files remain after Phase 2a; they need homes:

- `.ai/wheels/security/csrf-protection.md` → content largely covered in `basics/controllers-and-actions.mdx` (Phase 2a) + Cors page (Task 12); delete after confirming coverage
- `.ai/wheels/security/https-detection.md` → content belongs in `core-concepts/environments-and-configuration.mdx` (Phase 2a already has env-config); delete after confirming coverage
- `.ai/wheels/configuration/security.md` → mixed content; some goes to env-config, some to auth-patterns, some deletes

Task 15 is the `.ai/` audit specifically for these three files. It runs before the final report.

### Separate out-of-scope notes

- `.ai/wheels/controllers/api.md` — the spec's Digging Deeper list doesn't explicitly include an "API Controllers" page, but Task 10 (Packages) or a separate API doc may want this content. Defer to Phase 2c audit.
- `.ai/wheels/channels/channels.md` — no spec target; likely Phase 2c or delete.
- `.ai/wheels/patterns/validation-templates.md` — probably already covered by Phase 2a Task 13 (Validation and Error Display). Delete in Task 15's sweep.

---

## Phase Layout

| Task | Page / Action | `.ai/` delete | Review mode |
|------|---------------|---------------|-------------|
| 1. Authentication Patterns | Content | patterns/authentication, models/user-authentication | Subagent + harness |
| 2. Authorization & Filters | Content | patterns/crud (if on-topic) | Subagent + harness |
| 3. Background Jobs | Content | jobs/overview | Subagent + harness |
| 4. Caching | Content | (none) | Subagent + harness |
| 5. Sending Email (rewrite) | Content | (none — Task 22 already did) | Subagent + harness |
| 6. File Uploads & Downloads | Content | files/downloads | Subagent + harness |
| 7. Server-Sent Events | Content | controllers/sse | Subagent + harness |
| 8. Internationalization | Content | (none) | Subagent + harness |
| 9. Multi-tenancy | Content | configuration/multi-tenancy, models/shared-models | Subagent + harness |
| 10. Packages | Content | packages/overview, integration/modern-frontend-stack | Subagent + harness |
| 11. Route Model Binding | Content | (none) | Subagent + harness |
| 12. CORS | Content | (none) | Subagent + harness |
| 13. Rate Limiting | Content | (none) | Subagent + harness |
| 14. Dependency Injection Usage | Content | (none) | Subagent + harness |
| 15. Security `.ai/` audit | Cleanup | security/csrf-protection, security/https-detection, configuration/security, patterns/validation-templates (if redundant) | Inline |
| 16. Digging Deeper index rewrite + sidebar audit | Integration | (none) | Inline |
| 17. Full harness + build + report | Integration | (none) | Inline |
| 18. Final code review | Review | (none) | Subagent (pr-review-toolkit:code-reviewer) |

18 tasks. Expected wall time: 3-5 sessions at the cadence Phase 2a established.

---

## Shared conventions for every content task

Unchanged from Phase 2a. Reproduced here for the plan to be self-contained.

### Frontmatter template

```yaml
---
title: <Human Title>
description: <one-sentence description, 80-140 chars, no trailing period>
type: howto
sidebar:
  order: N
---
```

All Digging Deeper pages are `type: howto`. Sidebar order is task number within the section (1-14).

### Opening section

- Starlight component imports line (whatever you use, at minimum `Aside`)
- One-sentence summary
- **"You'll learn"** bullet block (3-5 items)
- Optional `<Aside type="note">` declaring audience assumptions

### Closing section

- **"Related guides"** CardGrid with 2-4 LinkCards
- Forward links to Phase 2b/2c pages are fine (same pattern as Phase 2a)

### Code block tagging rules

- **CFML fragments**: `{test:compile}`, bracket-balanced
- **CLI commands**: `{test:cli cmd="wheels --version" asserts-stdout="Wheels"}` as smoke test — real commands that need a running server can't be tested in isolated fixture mode
- **HTML / illustrative**: `title="path/to/file"` (no harness tag)
- **Output blocks**: `title="expected output"` or no meta

### Voice + prose rules (from STYLE.md)

- Second person, active voice
- No marketing copy
- No headings deeper than `###`
- Real names (Post, user.email), not foo/bar
- Function names in code voice; concepts in prose voice

### Verification template

```bash
export JAVA_HOME=/opt/homebrew/Cellar/openjdk@21/21.0.8/libexec/openjdk.jdk/Contents/Home
cd /Users/peter/GitHub/wheels-dev/wheels/.claude/worktrees/lucid-thompson-b8c121/web/sites/guides
pnpm verify:docs src/content/docs/v4-0-0-snapshot/digging-deeper/<page>.mdx
pnpm build 2>&1 | tail -5
```

### Sidebar update pattern

Each new page gets added to the Digging Deeper `items` array in `web/sites/guides/src/sidebars/v4-0-0-snapshot.json`. Order matches sidebar.order in frontmatter.

### `.ai/` deletion pattern

1. Before writing: read the `.ai/` source(s) to extract user-facing material
2. Before committing: verify the user doc covers everything user-facing
3. In the same commit: `git rm` the `.ai/` file(s)

### Commit messages

`docs(docs): digging-deeper/<page> — <imperative phrase>`

Examples:
- `docs(docs): digging-deeper/authentication-patterns — add session + jwt + token strategies + drop .ai patterns`
- `docs(docs): digging-deeper/sending-email — expand phase 0 sample with background jobs + attachments`

---

## Task 1: Authentication Patterns

**Page:** `web/sites/guides/src/content/docs/v4-0-0-snapshot/digging-deeper/authentication-patterns.mdx`

**Type:** `howto`. **Sidebar order:** 1 within Digging Deeper.

**`.ai/` to delete:** `.ai/wheels/patterns/authentication.md`, `.ai/wheels/models/user-authentication.md`

**Reference material:**
- The two `.ai/` files above
- `vendor/wheels/auth/` — especially `Authenticator.cfc`, `SessionStrategy.cfc`, `JwtStrategy.cfc`, `TokenStrategy.cfc` (whichever exist)
- Phase 1 Tutorial Part 6 — hand-rolled auth (6a) + built-in (6b)
- Phase 2a `core-concepts/dependency-injection.mdx` — explains the DI container the auth strategies register through

**Frontmatter:**

```yaml
---
title: Authentication Patterns
description: Session auth, JWT tokens, API tokens — rolling your own vs using Wheels' built-in strategies.
type: howto
sidebar:
  order: 1
---
```

**Required sections:**

1. Opening + "You'll learn" (session vs token auth, the built-in `SessionStrategy`, JWT and API token alternatives, combining strategies).

2. Prereq aside: "You should already know how filters work. See [Controllers and Actions](/v4-0-0-snapshot/basics/controllers-and-actions/). The [tutorial Part 6](/v4-0-0-snapshot/start-here/tutorial/06-authentication/) walks through session auth end-to-end."

3. **Session auth with `SessionStrategy`** — the built-in. 2 paragraphs + `{test:compile}` block showing `config/services.cfm` registration + controller usage. Reference back to Tutorial Part 6b. Use the short form `service("authenticator")`; note `application.wo.service(...)` is equivalent.

4. **Password hashing** — **loud caveat that bcrypt isn't shipped**. Document the current salted SHA-256 pattern (see Tutorial Part 6), note it's a stopgap, cross-link to the framework gap tracker (`docs/superpowers/plans/2026-04-19-framework-gaps-from-guides-phase-1.md` — see gap #4 if still open).

5. **Token auth (`TokenStrategy`)** — short paragraph + `{test:compile}` block. When a client sends `Authorization: Bearer <token>`, the strategy looks the token up. Use case: server-to-server API calls. Registration pattern identical to Session.

6. **JWT auth (`JwtStrategy`)** — short paragraph + `{test:compile}` block. Signed tokens with claims (userId, expires, scopes). Use case: stateless API, multi-device clients. Secret comes from `application.wo.env("JWT_SECRET")`; config-time setup in `config/services.cfm`.

7. **Combining strategies** — short paragraph. One app, multiple strategies registered. Use middleware to pick: session for HTML requests, JWT for `/api/*`. `{test:compile}` block showing the pattern.

8. **"I don't want to use the DI container"** — short paragraph. Fine. The strategies are regular CFCs; you can instantiate them manually. You lose request-scoped caching but gain simpler call sites.

9. **Security pitfalls** — bulleted list:
   - Regenerate session ID on login (prevents fixation)
   - Timing-safe comparison for token lookup (don't short-circuit on first mismatched char)
   - Rotate JWT signing secrets via env var — don't hardcode
   - Token revocation means a session-ID-lookup table even for "stateless" JWT

10. **Related guides** CardGrid: Authorization & Filters (Task 2), Tutorial Part 6, Dependency Injection (concept), CORS (Task 12).

**Constraints:**
- 4-6 `{test:compile}` blocks
- Length: ~250-350 lines (this is a broad topic)
- Voice: second person, no marketing
- Every strategy name and method signature verified against `vendor/wheels/auth/`

**Workflow:**
1. Read references + confirm strategy class names against `vendor/wheels/auth/`
2. Write the page
3. Verify harness + build (expected: N passed, 0 failed; page count + 1)
4. Delete `.ai/` files:
   ```bash
   git rm .ai/wheels/patterns/authentication.md .ai/wheels/models/user-authentication.md
   ```
5. Add sidebar entry (order 1 in Digging Deeper)
6. Commit:
   ```
   docs(docs): digging-deeper/authentication-patterns — add session/jwt/token strategies + drop .ai patterns + user-auth
   ```

---

## Task 2: Authorization & Filters

**Page:** `web/sites/guides/src/content/docs/v4-0-0-snapshot/digging-deeper/authorization-and-filters.mdx`

**Type:** `howto`. **Sidebar order:** 2.

**`.ai/` to audit/delete:** `.ai/wheels/patterns/crud.md` (evaluate — CRUD is broader than auth; may belong elsewhere or delete as superseded)

**Reference material:**
- Phase 2a `basics/controllers-and-actions.mdx` — filters basics
- Tutorial Part 6 — `authenticate` filter + `ownershipCheck`
- `vendor/wheels/Controller.cfc` — filter API
- The route model binding warning from framework-gaps-batch-1 (commit `875639f59` merged to develop)

**Frontmatter:**

```yaml
---
title: Authorization & Filters
description: Filters for access control — authentication gates, ownership checks, role-based rules, and policy patterns.
type: howto
sidebar:
  order: 2
---
```

**Required sections:**

1. Opening + "You'll learn".

2. Prereq aside pointing at Controllers and Actions + Auth Patterns (Task 1).

3. **The filter API — recap** — short section referencing Phase 2a. `filters(through=, only=, except=)` in `config()`. Filters are private methods. Call `redirectTo()` to short-circuit.

4. **Authentication gate** — `{test:compile}` block. The canonical `authenticate` filter from Tutorial Part 6.

5. **Ownership checks** — `{test:compile}` block:
   ```cfm
   filters(through="ownershipCheck", only="edit,update,delete");
   private function ownershipCheck() {
       if (params.post.userId != session.userId) { redirectTo(route="posts"); }
   }
   ```

6. **Role-based rules** — `{test:compile}` block showing filter that checks a `role` field on the user. Cross-link to Query Builder and Scopes for `.where("role", "admin")` patterns.

7. **`verifies()` — type + presence guards** — short paragraph + `{test:compile}` block. `verifies(params="id", paramsTypes="integer", handler="invalidRequest")` rejects requests with missing or wrong-type params before the action runs. Different from filters (runs earlier, checks param shape).

8. **Policy objects** — short paragraph + `{test:compile}` block. When authorization logic grows beyond "does this user own this record," extract a `PostPolicy` into `app/lib/` with methods like `canEdit(user, post)`. The controller filter calls the policy. Cross-link to DI Usage (Task 14) for registering policy objects.

9. **Filter order** — short paragraph. `before` filters run in registration order. `after` filters run in reverse. Put authentication first, then authorization, then data loading.

10. **Testing filters** — short paragraph. Filter methods are `private`. Test them by calling the controller action and asserting response (redirect vs render). Cross-link to Phase 2b-Testing Controller Tests (target).

11. **Related guides** CardGrid: Authentication Patterns, Controllers and Actions, Route Model Binding (Task 11), Tutorial Part 6.

**Constraints:**
- 4-6 `{test:compile}` blocks
- Length: ~200-300 lines
- Cross-reference heavily with Phase 2a + Task 1

**Workflow:** same pattern as Task 1.

---

## Task 3: Background Jobs

**Page:** `web/sites/guides/src/content/docs/v4-0-0-snapshot/digging-deeper/background-jobs.mdx`

**Type:** `howto`. **Sidebar order:** 3.

**`.ai/` to delete:** `.ai/wheels/jobs/overview.md`

**Reference material:**
- `.ai/wheels/jobs/overview.md`
- `vendor/wheels/Job.cfc` — the Job base class
- `cli/lucli/Module.cfc` — the `wheels jobs` CLI commands (look for `jobs work`, `jobs status`, `jobs retry`, `jobs purge`, `jobs monitor`)
- `CLAUDE.md` Background Jobs Quick Reference section

**Frontmatter:**

```yaml
---
title: Background Jobs
description: Queue work for asynchronous processing — retries, priorities, and the worker process.
type: howto
sidebar:
  order: 3
---
```

**Required sections:**

1. Opening + "You'll learn".

2. Prereq aside about models (the jobs table is a model).

3. **Define a job** — `{test:compile}` block extending `wheels.Job`. Override `perform(struct data)`. Set `this.queue` and `this.maxRetries` in `config()`.

4. **Enqueue** — `{test:compile}` block showing `job.enqueue(data={...})`, `job.enqueueIn(seconds=300, data={...})`, `job.enqueueAt(runAt=date, data={...})`.

5. **Running the worker** — CLI commands prose + `{test:cli}` smoke (real `wheels jobs work` needs DB):
   ```bash
   wheels jobs work                      # process all queues
   wheels jobs work --queue=mailers --interval=3
   wheels jobs status
   ```

6. **Retries and backoff** — short paragraph. `maxRetries`, `baseDelay`, `maxDelay` in `config()`. Formula: `Min(baseDelay * 2^attempt, maxDelay)`. Default exponential backoff.

7. **Priority queues** — short paragraph. Different queue names run at different priorities. `wheels jobs work --queue=high,default,low` runs them in order.

8. **Monitoring** — short prose + `wheels jobs monitor` smoke. CLI dashboard showing pending/processing/completed/failed per queue. In production, the same info is available via `model("wheelsJob").findAll(...)` — they're just rows.

9. **The jobs table** — short paragraph. Requires migration: `20260221000001_createwheels_jobs_table.cfc` (check exact name in `vendor/wheels/migrator/templates/`). Run `wheels migrate latest` to install.

10. **Testing jobs** — short paragraph. Test the `perform()` method directly with sample data. Don't hit the queue in tests.

11. **Common patterns** — bulleted list:
    - Enqueue from `afterCreate` callbacks to keep controllers fast
    - Use `enqueueIn` for rate-limited outbound calls
    - Split one-off work into multiple jobs for parallelism

12. **Related guides** CardGrid: Sending Email (Task 5 — jobs pair well with email), Models and the ORM, Testing (landing).

**Constraints:**
- 4-6 `{test:compile}` blocks
- Length: ~250-350 lines
- Verify every `wheels jobs` subcommand against `cli/lucli/Module.cfc`

---

## Task 4: Caching

**Page:** `web/sites/guides/src/content/docs/v4-0-0-snapshot/digging-deeper/caching.mdx`

**Type:** `howto`. **Sidebar order:** 4.

**`.ai/` to delete:** None (check at task time — there may be a `.ai/wheels/caching/` subdir that wasn't in the Phase 2a inventory).

**Reference material:**
- `vendor/wheels/controller/caching.cfc` or equivalent — `caches()` declarations, `cache()` helper
- `vendor/wheels/model/caching.cfc` or equivalent — model-level caching hooks
- Lucee cache config in `lucee.json`

**Required sections:**

1. Opening + "You'll learn" (action caching, fragment caching, cache stores, invalidation).

2. **Action caching** — `{test:compile}` block. Cache an entire action's rendered output:
   ```cfm
   component extends="Controller" {
       function config() {
           caches(actions="index", time=10);  // minutes
       }
   }
   ```

3. **Fragment caching** — `{test:compile}` block. `cache(key="header", time=60) { ... }` in a view.

4. **Page caching** — short paragraph. Full static HTML cached at the web server layer. Needs Kamal / reverse-proxy config; out of scope for this page.

5. **Cache stores** — short prose + table. In-memory (default, per-node), disk, Redis (production recommended), Memcached.

6. **Invalidation** — short paragraph. `cacheRemove(key="...")` programmatic clear. Model callback pattern: `afterSave("clearPostListCache")` → `private function clearPostListCache() { cacheRemove(key="post-list"); }`.

7. **When NOT to cache** — short paragraph. Per-user data, freshly-required-from-DB workflows, cross-tenant responses.

8. **Related guides** CardGrid: Multi-tenancy (Task 9 — per-tenant cache keys), Models and the ORM, Views/Layouts/Partials.

**Constraints:**
- 3-5 `{test:compile}` blocks
- Length: ~180-260 lines
- **Verify framework ships the caching API claimed.** If `caches()` doesn't exist, document only what's real. If ALL of this is "use Lucee's cache API directly + layer it in yourself," document THAT honestly.

---

## Task 5: Sending Email (rewrite)

**Page:** `web/sites/guides/src/content/docs/v4-0-0-snapshot/digging-deeper/sending-email.mdx`

**Type:** `howto`. **Sidebar order:** 5.

**`.ai/` to delete:** None (handled in Phase 2a Task 22).

**Action:** REWRITE the Phase 0 sample page. Preserve its SMTP config / mailer / view content (which is good) but add:
- Sending in a background job (cross-link Task 3)
- Multi-part HTML + plain text
- Attachments
- Per-environment SMTP (dev catches mail to a file; prod hits real SMTP)
- Postmark / SendGrid / SES integration notes

**Reference material:**
- Existing `digging-deeper/sending-email.mdx` (Phase 0)
- `vendor/wheels/mailer/` or `vendor/wheels/Mailer.cfc`
- `app/mailers/` convention from scaffold

**Required sections (merging existing + new):**

1. Opening + "You'll learn" (SMTP config, writing a mailer, sending from a controller, background-job enqueuing, multi-part, attachments).

2. **Configure SMTP** — existing Phase 0 content, keep.

3. **Generate a mailer** — existing content, keep. Verify `wheels generate mailer` works after framework gap #1 landed.

4. **Write the mailer** — existing content, extend to show setting `this.from`, `this.to`, `this.cc`, `this.bcc`, `this.subject`, `this.contentType="text/html"`.

5. **Write the template** — existing content, keep.

6. **Send from a controller** — existing content, keep. Add a sentence that the default is synchronous (see next section for async).

7. **Send in a background job** — NEW. `{test:compile}` block:
   ```cfm
   component extends="wheels.Job" {
       function config() { this.queue = "mailers"; }
       public void function perform(struct data) {
           sendMail(mailer="WelcomeMailer", method="welcome", user=model("User").findByKey(data.userId));
       }
   }
   ```
   Controller enqueues instead of sending inline: `new app.jobs.SendWelcomeEmailJob().enqueue(data={userId: user.id})`.

8. **Multi-part HTML + plain text** — NEW. Two views: `welcome.cfm` (HTML) + `welcome.txt.cfm` (plain text). Mailer lookups both if `contentType="multipart"` (verify exact API).

9. **Attachments** — NEW. `this.attachments = [{file: "/path/to/invoice.pdf", type: "application/pdf"}]`. Verify API against source.

10. **Per-environment SMTP** — NEW. Dev: log to file or use Mailtrap. Prod: real SMTP via `application.wo.env("SMTP_*")`.

11. **Third-party services** — NEW. Postmark, SendGrid, SES all expose SMTP endpoints — configure like any other SMTP. Link to their docs for domain setup.

12. **Related guides** CardGrid: Background Jobs (Task 3), Authentication Patterns (welcome emails follow signup).

**Constraints:**
- 5-7 `{test:compile}` blocks (more than usual given the topic breadth)
- Length: ~250-350 lines
- Don't regress the Phase 0 content that already works

---

## Task 6: File Uploads & Downloads

**Page:** `web/sites/guides/src/content/docs/v4-0-0-snapshot/digging-deeper/file-uploads-and-downloads.mdx`

**Type:** `howto`. **Sidebar order:** 6.

**`.ai/` to delete:** `.ai/wheels/files/downloads.md`

**Reference material:**
- `.ai/wheels/files/downloads.md`
- `vendor/wheels/` for `sendFile()`, upload handling, multipart parsing
- Phase 2a `basics/forms-and-form-helpers.mdx` — `fileField` helper

**Required sections:**

1. Opening + "You'll learn" (upload form, saving uploads, validation, serving downloads, streaming).

2. **The upload form** — `{test:compile}` block. `startFormTag(route="...", enctype="multipart/form-data")` + `fileField(objectName="user", property="avatar")`.

3. **Receiving the upload** — `{test:compile}` block. `params.user.avatar` is a struct with `tempFile`, `clientFile`, `fileSize`, `contentType`.

4. **Saving** — short paragraph + `{test:compile}` block. `FileMove(params.user.avatar.tempFile, "/var/uploads/#params.user.avatar.clientFile#")`. Cross-tenant users can clash — namespace by user ID.

5. **Validating** — short paragraph + `{test:compile}` block. Size limits, content-type allowlist, extension check, virus scan integration point.

6. **Storage backends** — short paragraph. Local disk (dev), S3-compatible (prod). Don't ship S3 client code in the framework; use Lucee's HTTP + `awssign`.

7. **Serving downloads** — `{test:compile}` block. Controller action returns `sendFile(path="/var/uploads/...", name="...", attachment=true)`.

8. **Streaming large files** — short paragraph. For files > 100MB, stream instead of reading to memory. Use CFML's binary stream helpers.

9. **Security** — bulleted list. Sanitize filenames (strip `..`), validate content type server-side (don't trust `params.user.avatar.contentType` — check magic bytes), serve uploads from a separate subdomain to prevent XSS.

10. **Related guides** CardGrid: Forms and Form Helpers, Controllers and Actions, Security (if a security page exists yet).

**Constraints:**
- 4-6 `{test:compile}` blocks
- Length: ~220-320 lines
- Verify `sendFile()` against `vendor/wheels/`

---

## Task 7: Server-Sent Events

**Page:** `web/sites/guides/src/content/docs/v4-0-0-snapshot/digging-deeper/server-sent-events.mdx`

**Type:** `howto`. **Sidebar order:** 7.

**`.ai/` to delete:** `.ai/wheels/controllers/sse.md`

**Reference material:**
- `.ai/wheels/controllers/sse.md`
- `vendor/wheels/controller/sse.cfc` or equivalent
- CLAUDE.md SSE Quick Reference section

**Required sections:**

1. Opening + "You'll learn" (SSE vs WebSockets, one-shot vs streaming, browser EventSource).

2. **SSE vs WebSockets** — short paragraph. SSE: server → client only, plain HTTP, auto-reconnect. WebSockets: bidirectional, separate protocol. Use SSE when the client only needs to listen.

3. **One-shot response** — `{test:compile}` block:
   ```cfm
   function notifications() {
       data = model("Notification").findAll(where="userId=#params.userId#");
       renderSSE(data=SerializeJSON(data), event="notifications", id=params.lastId);
   }
   ```

4. **Streaming multiple events** — `{test:compile}` block:
   ```cfm
   function stream() {
       writer = initSSEStream();
       for (item in items) {
           sendSSEEvent(writer=writer, data=SerializeJSON(item), event="update");
       }
       closeSSEStream(writer=writer);
   }
   ```

5. **`isSSERequest()` detection** — short paragraph. Check before deciding render format.

6. **Client-side** — short paragraph + code block (plain JS, not CFML):
   ```javascript title="app/views/posts/show.cfm — client script"
   const es = new EventSource('/posts/notifications');
   es.addEventListener('notifications', (e) => {
       const data = JSON.parse(e.data);
       // update UI
   });
   ```

7. **Auto-reconnect** — short paragraph. The browser reconnects on drop automatically; use `id=` on events so the client can resume from the last seen.

8. **Long-lived connections and timeouts** — short paragraph. Tomcat/Lucee default request timeouts can kill long streams. Tune in `lucee.json` for the SSE endpoint specifically.

9. **Authentication on SSE** — short paragraph. EventSource can't send custom headers; use session cookies or URL query params (the latter with care).

10. **Related guides** CardGrid: Controllers and Actions, CORS (Task 12 — SSE across origins), Rate Limiting (Task 13).

**Constraints:**
- 3-4 `{test:compile}` blocks + 1 JS block (illustrative)
- Length: ~200-280 lines

---

## Task 8: Internationalization

**Page:** `web/sites/guides/src/content/docs/v4-0-0-snapshot/digging-deeper/internationalization.mdx`

**Type:** `howto`. **Sidebar order:** 8.

**`.ai/` to delete:** None (check at task time)

**Reference material:**
- `vendor/wheels/i18n/` if it exists
- `vendor/wheels/view/helpers/` for view-helper `t()` or similar

**Required sections (tentative — VERIFY the framework actually ships i18n before committing to this scope):**

1. Opening + "You'll learn" — **or, if i18n is NOT shipped,** open with "Wheels 4.0 doesn't ship first-class i18n. This page describes the pattern." Be honest — the spec lists the page; content matches reality.

2. **Locale detection** — `Accept-Language` header, URL param, session-stored, user-profile-stored.

3. **Translation files** — `config/locales/en.json` + `config/locales/fr.json` pattern. Simple key/value.

4. **View helper** — `{test:compile}` block showing a custom `t("welcome.title")` helper in `app/views/helpers.cfm` that reads the active locale struct.

5. **Pluralization** — short paragraph. Simple count + variant pattern ("1 post" / "N posts"). Real pluralization rules for CJK languages are beyond CFML defaults.

6. **Date and number formatting** — short paragraph. `DateFormat(date, "long", locale)` + `LSNumberFormat(number, format, locale)`.

7. **Route localization** — short paragraph. `/fr/posts` vs `/en/posts` using `.scope(path="/:locale")` + a filter that reads `params.locale` and sets `request.locale`.

8. **Related guides** CardGrid: Views/Layouts/Partials, Controllers and Actions, Middleware Pipeline.

**Constraints:**
- Length: ~180-260 lines
- **If framework doesn't ship this: scope-check with Peter before implementing.** A page that documents "here's the manual pattern" is still useful; one that invents nonexistent framework APIs isn't.

---

## Task 9: Multi-tenancy

**Page:** `web/sites/guides/src/content/docs/v4-0-0-snapshot/digging-deeper/multi-tenancy.mdx`

**Type:** `howto`. **Sidebar order:** 9.

**`.ai/` to delete:** `.ai/wheels/configuration/multi-tenancy.md`, `.ai/wheels/models/shared-models.md`

**Reference material:**
- Both `.ai/` files
- `vendor/wheels/middleware/TenantResolver.cfc` if it exists
- CLAUDE.md Multi-tenancy references

**Required sections:**

1. Opening + "You'll learn" (scoping strategies, tenant resolver, per-request tenant, shared vs per-tenant data).

2. **Three tenancy strategies** — table:
   - **Row scoping** — single DB, `tenantId` column on every table, every query filters by it
   - **Schema per tenant** — single DB, schema per tenant, app switches active schema per request
   - **Database per tenant** — isolated DB per tenant, app switches datasource per request

3. **Tenant resolver middleware** — `{test:compile}` block. Middleware reads subdomain / header / JWT claim → sets `request.tenantId`. Every downstream model scopes by it.

4. **Per-model tenant scope** — `{test:compile}` block. Base model with `afterInitialization("applyTenantScope")` + default scope by `request.tenantId`.

5. **Shared models** — short paragraph + `{test:compile}` block. Some models (e.g., `Currency`, `TimeZone`) are cross-tenant. Override the tenant filter per-model.

6. **Per-datasource tenancy** — short paragraph + `{test:compile}` block showing `dataSource("tenant_" & request.tenantId)` via model callback.

7. **Testing multi-tenancy** — short paragraph. Tests should exercise tenant isolation — create a tenant, create data as that tenant, switch tenant, verify no leakage.

8. **Related guides** CardGrid: Middleware Pipeline, Database and Multiple Datasources, Caching (Task 4 — tenant-scoped keys).

**Constraints:**
- 4-6 `{test:compile}` blocks
- Length: ~280-380 lines (broad topic)
- **If framework doesn't ship TenantResolver: document the manual middleware pattern, don't invent.**

---

## Task 10: Packages

**Page:** `web/sites/guides/src/content/docs/v4-0-0-snapshot/digging-deeper/packages.mdx`

**Type:** `howto`. **Sidebar order:** 10.

**`.ai/` to delete:** `.ai/wheels/packages/overview.md`, `.ai/wheels/integration/modern-frontend-stack.md` (check relevance)

**Reference material:**
- Both `.ai/` files
- `packages/` directory in the repo — first-party packages (hotwire, basecoat, sentry, legacyadapter)
- `vendor/wheels/PackageLoader.cfc`
- `CLAUDE.md` Package System section

**Required sections:**

1. Opening + "You'll learn" (activating first-party packages, writing your own, publishing).

2. **The activation model** — short paragraph. Framework auto-discovers `vendor/<package>/package.json` on startup. Activation = copy from `packages/` to `vendor/`. No separate registration step.

   **Loud caveat (framework gap #2):** currently no `wheels package install` command exists. Manual activation:
   ```bash
   cp -r packages/hotwire vendor/hotwire
   wheels reload
   ```

3. **First-party packages** — bulleted list:
   - `wheels-hotwire` — Turbo + Stimulus
   - `wheels-basecoat` — UI components
   - `wheels-sentry` — error tracking
   - (any others in `packages/`)

4. **`package.json` manifest** — `{test:compile}` or illustrative block:
   ```json
   {
       "name": "wheels-sentry",
       "version": "1.0.0",
       "wheelsVersion": ">=3.0",
       "provides": {
           "mixins": "controller",
           "services": [],
           "middleware": []
       }
   }
   ```
   Explain `provides.mixins` — which framework surfaces the package extends (controller, view, model, global, none). Default `none` = explicit opt-in.

5. **Writing your own package** — `{test:compile}` block. Create `packages/my-package/{package.json, init.cfm, ...}`. Activate by copying to `vendor/`. Extend `CFCBase` or plain CFCs.

6. **Error isolation** — short paragraph. A broken package logs + skips; other packages and the app continue. PackageLoader wraps each package's init in try/catch.

7. **Testing a package** — short paragraph. `curl "http://localhost:60007/wheels/core/tests?db=sqlite&format=json&directory=vendor.sentry.tests"` pattern. Detailed in Phase 2b-Testing (future).

8. **Publishing** — short paragraph. Current process: GitHub repo + install script or manual clone. NPM / registry publishing is aspirational (no package registry yet).

9. **Related guides** CardGrid: Middleware Pipeline, Dependency Injection, Contributing (Phase 2c).

**Constraints:**
- 3-5 `{test:compile}` blocks (mostly illustrative given the topic)
- Length: ~220-320 lines

---

## Task 11: Route Model Binding

**Page:** `web/sites/guides/src/content/docs/v4-0-0-snapshot/digging-deeper/route-model-binding.mdx`

**Type:** `howto`. **Sidebar order:** 11.

**`.ai/` to delete:** None

**Reference material:**
- Phase 2a `core-concepts/how-routing-works.mdx` — the concept
- Phase 2a `basics/routing.mdx` — hands-on resource declaration
- The framework gap #5 fix (commit `875639f59` merged) — dev warning

**Required sections:**

1. Opening + "You'll learn" (per-resource binding, global binding, custom binding source).

2. **Per-resource opt-in** — existing pattern from Tutorial and basics:
   ```cfm {test:compile}
   .resources(name="posts", binding=true)
   ```

3. **Global default** — `{test:compile}` block:
   ```cfm
   // config/settings.cfm
   set(routeModelBinding=true);
   ```

4. **Explicit model name** — `{test:compile}` block:
   ```cfm
   .resources(name="articles", binding="BlogPost")  // resolves BlogPost class, stores in params.blogPost
   ```

5. **Scope-level binding** — `{test:compile}` block:
   ```cfm
   .scope(path="/api", binding=true)
       .resources("users")  // params.user
       .resources("posts")  // params.post
   .end()
   ```

6. **The 404 behavior** — short paragraph. If `params.key` is set but the record doesn't exist, Wheels raises `Wheels.RecordNotFound` BEFORE your action runs. Handle in `config/events/onerror.cfm` or let it 404 naturally.

7. **The dev-mode warning** — short paragraph. When binding is OFF and your action uses `params.<singular>`, a dev warning fires. Fix by enabling binding or by suppressing via `set(suppressRouteBindingWarnings=true)`.

8. **Custom binding source** — short paragraph. When the URL uses slug instead of ID:
   ```cfm {test:compile}
   .resources(name="posts", binding=true, bindBy="slug")
   ```
   Requires the model to have a `findBySlug` or equivalent finder. Verify exact `bindBy=` syntax against `vendor/wheels/mapper/`.

9. **Related guides** CardGrid: How Routing Works, Routing (basics), Controllers and Actions.

**Constraints:**
- 5-7 `{test:compile}` blocks
- Length: ~200-280 lines
- **Verify every binding option against `vendor/wheels/mapper/resources.cfc`.**

---

## Task 12: CORS

**Page:** `web/sites/guides/src/content/docs/v4-0-0-snapshot/digging-deeper/cors.mdx`

**Type:** `howto`. **Sidebar order:** 12.

**`.ai/` to delete:** None

**Reference material:**
- `vendor/wheels/middleware/Cors.cfc`
- Phase 2a `core-concepts/middleware-pipeline.mdx` — middleware basics
- **Important: Task 6's flag that `Cors.allowOrigins` defaults to `""` (fails closed), NOT `"*"`.**

**Required sections:**

1. Opening + "You'll learn" (CORS basics, configuring Wheels' built-in, preflight, credentials).

2. **Enable Cors** — `{test:compile}` block:
   ```cfm
   set(middleware = [
       new wheels.middleware.Cors(
           allowOrigins="https://myapp.com,https://admin.myapp.com",
           allowCredentials=true,
           maxAge=3600
       )
   ]);
   ```
   **Important:** default `allowOrigins` is `""` (empty, fails closed). Configure explicitly.

3. **Options** — table:
   - `allowOrigins` — comma-separated. Default `""`.
   - `allowCredentials` — boolean. Pairs with `allowOrigins=*` raises `Wheels.Cors.InvalidConfiguration`.
   - `allowMethods` — `"GET,POST,PUT,DELETE,OPTIONS"` default
   - `allowHeaders` — `"Content-Type,Authorization"` default
   - `exposeHeaders` — comma-separated
   - `maxAge` — preflight cache lifetime in seconds

4. **Preflight (OPTIONS)** — short paragraph. Browser sends OPTIONS before any non-simple request. Middleware handles automatically when origins match.

5. **Per-route Cors** — `{test:compile}` block showing scope-level middleware:
   ```cfm
   .scope(path="/api", middleware=[new wheels.middleware.Cors(allowOrigins="https://client.com")])
       .resources("posts")
   .end()
   ```

6. **Credentials mode** — short paragraph. With `allowCredentials=true`, `Access-Control-Allow-Origin` can't be `*`. The middleware rejects this combination at init.

7. **Debugging** — short paragraph. Browser console shows CORS rejections. Curl with `-H "Origin: https://client.com" -v` shows the response headers.

8. **Related guides** CardGrid: Middleware Pipeline, Rate Limiting (Task 13), Authentication Patterns (cross-origin auth).

**Constraints:**
- 2-4 `{test:compile}` blocks (narrow feature)
- Length: ~150-220 lines

---

## Task 13: Rate Limiting

**Page:** `web/sites/guides/src/content/docs/v4-0-0-snapshot/digging-deeper/rate-limiting.mdx`

**Type:** `howto`. **Sidebar order:** 13.

**`.ai/` to delete:** None

**Reference material:**
- `vendor/wheels/middleware/RateLimiter.cfc`
- CLAUDE.md Rate Limiting section

**Required sections:**

1. Opening + "You'll learn" (three strategies, storage, keying, headers).

2. **Three strategies** — bullet list with when-to-use:
   - **Fixed window** (default) — simplest. Count per N-second window, reset at boundary. Susceptible to bursts at the boundary.
   - **Sliding window** — smoother. Weighted average of current + previous window.
   - **Token bucket** — allows bursts up to capacity, refills steadily. Best for APIs.

3. **Basic config** — `{test:compile}` block:
   ```cfm
   new wheels.middleware.RateLimiter(maxRequests=100, windowSeconds=60, strategy="fixedWindow")
   ```

4. **Token bucket** — `{test:compile}` block:
   ```cfm
   new wheels.middleware.RateLimiter(maxRequests=50, windowSeconds=60, strategy="tokenBucket")
   ```

5. **Storage backends** — short paragraph. `memory` (default, per-node) vs `database` (auto-creates `wheels_rate_limits` table, cluster-safe).

6. **Custom keying** — `{test:compile}` block. Per-IP is default; per-API-key example:
   ```cfm
   new wheels.middleware.RateLimiter(keyFunction=function(req) {
       return req.cgi.http_x_api_key ?: "anonymous";
   })
   ```

7. **Response headers** — short paragraph. `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset` added automatically. 429 response with `Retry-After` on rejection.

8. **Per-route rate limiting** — `{test:compile}` block showing scope middleware.

9. **Related guides** CardGrid: Middleware Pipeline, CORS (Task 12 — paired), Authentication Patterns (auth endpoints need strict limiting).

**Constraints:**
- 3-5 `{test:compile}` blocks
- Length: ~180-260 lines

---

## Task 14: Dependency Injection (Usage)

**Page:** `web/sites/guides/src/content/docs/v4-0-0-snapshot/digging-deeper/dependency-injection-usage.mdx`

**Type:** `howto`. **Sidebar order:** 14.

**`.ai/` to delete:** None (DI concept file was deleted in Phase 2a Task 5)

**Reference material:**
- Phase 2a `core-concepts/dependency-injection.mdx` — the concept
- Tutorial Part 6b — real usage
- `vendor/wheels/Injector.cfc`

**Required sections:**

1. Opening + "You'll learn" (strategy swapping in tests, per-request resolvers, factory registration, advanced scopes).

2. **Recap** — one paragraph + link to [the concept page](/v4-0-0-snapshot/core-concepts/dependency-injection/). This page is hands-on; the concept explains why.

3. **Strategy swapping in tests** — `{test:compile}` block. Registering a test double in `tests/populate.cfm` or per-spec setup:
   ```cfm
   injector().map("emailService").to("tests._assets.FakeEmailService").asSingleton();
   ```
   All code that resolves `service("emailService")` gets the fake instead.

4. **Per-request resolvers** — short paragraph + `{test:compile}` block. `currentUser` resolver pattern:
   ```cfm
   di.map("currentUser").to("app.lib.CurrentUserResolver").asRequestScoped();
   ```
   The resolver's `init()` or method reads `session.userId` and returns the user. Every call in the same request gets the same instance.

5. **Factory registration** — short paragraph + `{test:compile}` block. When construction needs custom logic (e.g., read from env var):
   ```cfm
   di.map("jwtStrategy").toFactory(function() {
       return new wheels.auth.JwtStrategy(secret=application.wo.env("JWT_SECRET"));
   });
   ```
   Verify `toFactory()` API against `vendor/wheels/Injector.cfc`.

6. **Auto-wiring** — short paragraph. Constructor params matching registered names resolve automatically. No explicit `initArguments`.

7. **Service locator anti-pattern** — short paragraph. Resolving `service("x")` deep inside business logic hides dependencies. Prefer injecting at the controller/service boundary.

8. **Advanced: named scopes** — short paragraph. Custom scopes beyond the built-in three via `injector().registerScope(...)`. Rare; defer to Contributing.

9. **Related guides** CardGrid: Dependency Injection (concept), Authentication Patterns (Task 1 uses DI), Testing (DI swaps enable test doubles).

**Constraints:**
- 4-6 `{test:compile}` blocks
- Length: ~200-280 lines

---

## Task 15: Security `.ai/` audit

**Inline task — no subagent.**

Three `.ai/` files remain from the "security" namespace that need homes:
- `.ai/wheels/security/csrf-protection.md`
- `.ai/wheels/security/https-detection.md`
- `.ai/wheels/configuration/security.md`
- `.ai/wheels/patterns/validation-templates.md` (likely redundant with Phase 2a Task 13)

Steps:

- [ ] Read each file
- [ ] For each, determine: (a) covered by existing Phase 2a/2b page → delete, (b) needs its own page in Phase 2b/2c → keep, (c) agent-operational only → leave for Phase 2c agent-context decision
- [ ] Execute the deletions
- [ ] Commit

```bash
cd /Users/peter/GitHub/wheels-dev/wheels/.claude/worktrees/lucid-thompson-b8c121
# per-file audit then:
git rm <files marked for delete>
git commit -m "docs(docs): task 15 security .ai/ audit — delete N files covered by phase 2a/2b"
```

---

## Task 16: Digging Deeper index rewrite + sidebar audit

**Inline task — no subagent.**

Current `digging-deeper/index.mdx`:
```
Placeholder — content lands in Phase 2.
```

Replace with a proper section landing that enumerates all 14 Digging Deeper pages in a `<CardGrid>`. Pattern after the Testing index landing Peter already approved.

Sidebar audit: confirm all 14 pages appear under Digging Deeper in the correct order. The section was `items: [{sending-email}]` before this phase; by end of Task 14 commit it should have all 14. If any page was missed during its task's sidebar step, add it here.

Steps:

- [ ] Rewrite `digging-deeper/index.mdx` with section landing content (title, one-sentence summary, "You'll learn", CardGrid of 14 LinkCards to the section pages)
- [ ] Audit sidebar: confirm 14 items present in `items` array
- [ ] Build + verify
- [ ] Commit

---

## Task 17: Full harness + build + Phase 2b-Advanced report

**Files:**
- Create: `docs/superpowers/plans/2026-04-20-guides-rewrite-phase-2b-digging-deeper-report.md`

Steps:

- [ ] Run full harness:
  ```bash
  export JAVA_HOME=/opt/homebrew/Cellar/openjdk@21/21.0.8/libexec/openjdk.jdk/Contents/Home
  cd web/sites/guides
  pnpm verify:docs 2>&1 | tee /tmp/phase2b-dd-harness.log
  ```

- [ ] Run unit tests:
  ```bash
  pnpm test:docs-harness
  ```

- [ ] Full build:
  ```bash
  pnpm build 2>&1 | tee /tmp/phase2b-dd-build.log
  ```

- [ ] Push to origin:
  ```bash
  git push
  ```

- [ ] Write completion report following Phase 2a report template:
  - Table of Phase 2b-Advanced commits
  - Deliverables checklist (14 pages + index + audit)
  - Verification section (harness pass count, tests, build page count)
  - API drift caught by subagents
  - Known gaps for Phase 2b-Testing and 2b-CLI
  - Policy decisions still open

- [ ] Commit report:
  ```bash
  git add docs/superpowers/plans/2026-04-20-guides-rewrite-phase-2b-digging-deeper-report.md
  git commit -m "docs(docs): phase 2b-advanced completion report"
  git push
  ```

---

## Task 18: Final code review across Phase 2b-Advanced diff

Dispatch a `pr-review-toolkit:code-reviewer` subagent with:

- Diff range: `0882d169c..HEAD` (Phase 2a head → current)
- Review focus: voice consistency across 14 pages, Diátaxis (how-to, not tutorial or concept), internal link accuracy, `.ai/` audit completeness, bracket-balance on compile blocks, sidebar matches file tree, cross-refs to Phase 2a pages resolve
- Known items to skip flagging: compile driver in fallback mode, known framework gaps already tracked, forward links to Phase 2b-Testing / 2b-CLI / 2c targets

Same template as Phase 2a Task 24. Address blocking issues inline; file non-blocking items for Phase 2b-Testing.

---

## Self-review

**Spec coverage check:**

| Spec § 4 requirement | Task |
|----------------------|------|
| Authentication Patterns | 1 |
| Authorization & Filters | 2 |
| Background Jobs | 3 |
| Caching | 4 |
| Sending Email | 5 |
| File Uploads & Downloads | 6 |
| Server-Sent Events | 7 |
| Internationalization | 8 |
| Multi-tenancy | 9 |
| Packages | 10 |
| Route Model Binding | 11 |
| CORS | 12 |
| Rate Limiting | 13 |
| Dependency Injection (usage) | 14 |

14/14 — all spec items mapped to tasks.

**Placeholder scan:**
- "TBD" appears in Task 8 (Internationalization) — intentional caveat that the task must verify framework actually ships i18n before committing to scope. This is scope-check territory, not a placeholder in the "implement later" sense.
- Similar caveats in Task 4 (Caching) and Task 9 (Multi-tenancy) — all flagged as "verify framework ships this, document honestly if not."
- No "similar to Task N" references — each task has full spec.
- No "add appropriate error handling" stubs.

**Type / method consistency:**
- `filters(through=, only=, except=)` consistent across Tasks 1, 2
- `service("name")` short form used consistently (not `application.wo.service("name")`)
- `.resources(name="...", binding=true)` consistent with Phase 2a
- Strategy class names (`SessionStrategy`, `JwtStrategy`, `TokenStrategy`) need verification in Task 1 — added explicit "confirm against `vendor/wheels/auth/`" step
- Background job callbacks (`enqueue`, `enqueueIn`, `enqueueAt`) consistent

**Known friction point from Phase 2a carried forward:**
- Content tasks use structural outlines, not verbatim prose. Subagents compose at execution time.
- Length ranges are guidance, not floors. STYLE.md anti-padding rule wins.

---

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-04-20-guides-rewrite-phase-2b-digging-deeper.md`.

**Per Phase 2a's proven pragmatic split:**
- **Content tasks (1-14)** — subagent-driven. One content-writer subagent per page, I review + commit.
- **Integration (15-17)** — inline.
- **Final review (18)** — single `pr-review-toolkit:code-reviewer` subagent across the full diff.

**Two execution options:**

1. **Subagent-Driven (recommended)** — dispatch one content-writer subagent per page, 14 dispatches. Same proven rhythm as Phase 2a.

2. **Inline Execution** — I write each page myself. Shorter per-page latency, higher context consumption.

**Proceed with subagent-driven execution of Phase 2b-Advanced?**
