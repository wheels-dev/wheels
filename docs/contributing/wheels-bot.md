# Wheels Bot

`wheels-bot[bot]` is a custom GitHub App that automates issue triage,
cross-framework design research, fix-PR generation, and PR review on
`wheels-dev/wheels`. It runs as nine stages, each backed by a slash-command
prompt in `.claude/commands/` and a workflow in `.github/workflows/bot-*.yml`.

This page is for humans interacting with the bot. For the design rationale,
see the plan at `/root/.claude/plans/i-just-watched-a-polymorphic-plum.md` (or
its archived copy in the repo when published). For the framework's general
contribution rules, see [`CONTRIBUTING.md`](../../CONTRIBUTING.md).

## TL;DR

- The bot reads issues and PRs and posts comments / reviews / draft PRs.
- It always opens PRs as `--draft` and never merges them. Humans merge.
- It never pushes to `develop`, `main`, or `release/*`. Only to its own
  `bot/**` and `fix/bot-*/**` branches.
- Add the `[skip-claude]` label (or include `[skip-claude]` in the title)
  to halt bot activity on a single issue/PR.
- Flip the repo variable `WHEELS_BOT_ENABLED` to `false` to halt the bot
  entirely without code changes.

## The nine stages

### 1. Triage (`bot-triage.yml`)

Fires on `issues: opened` and `issues: reopened`. Reads the issue body and
posts a comment classifying it as one of:

- **`bug`** — observable wrong behavior. The bot identifies the affected
  layer (model / controller / view / etc.) and emits a fix sketch with a
  confidence rating. Reproduction and spec authoring happen in the
  propose-fix stage, not here.
- **`framework-design`** — feature request or API design question. The bot
  hands off to the research stage; it does not opine yet.
- **`docs-request`** — actionable docs work needed (a specific page or
  section that should exist or be updated). The bot identifies the docs
  scope and emits a confidence rating. High-confidence docs-requests
  hand off to the write-docs stage.
- **`other`** — non-actionable docs feedback, support, or general
  discussion. No further automation.

For high-confidence `bug` triages the bot emits an additional marker
(`<!-- wheels-bot:triage-confidence:high -->`) which is the trigger for
the propose-fix stage. For high-confidence `docs-request` triages the
bot emits `<!-- wheels-bot:docs-confidence:high -->`, which is the
trigger for the write-docs stage.

### 2. Cross-framework research (`bot-research.yml`)

Fires when triage classifies as `framework-design`. The bot:

1. Re-reads the issue and any human follow-up comments.
2. Launches parallel sub-agents to look up how each of Rails, Laravel,
   Django, Phoenix, Spring Boot, and one other relevant framework handles
   the topic. Agents fetch official docs (rubyonrails.org, laravel.com,
   docs.djangoproject.com, hexdocs.pm, spring.io).
3. Synthesizes a comparison table, identifies the dominant pattern,
   cross-references existing Wheels conventions and `.ai/wheels/`, and
   proposes a Wheels-idiomatic API sketch in CFML.
4. Self-rates confidence (high / medium / low) with explicit auto-downgrade
   rules: any conflict with a CLAUDE.md anti-pattern caps at `medium`;
   material framework disagreement caps at `low`.

For high-confidence research the bot emits
`<!-- wheels-bot:research-confidence:high -->`, which is the trigger for
the propose-fix stage on the framework-design path.

### 3. Propose Fix (`bot-propose-fix.yml`)

Fires on the high-confidence triage marker (bug path) or the high-confidence
research marker (framework-design path). Also runnable manually via
`workflow_dispatch`.

The bot:

1. Reads the triage comment and (if present) the research comment.
2. Auto-downgrades and stops if the proposed fix touches sensitive areas
   (security, migrations, deploy, DI). Posts `wheels-bot:fix-held:<issue>`
   instead of opening a PR.
3. Writes a failing WheelsTest spec.
4. Confirms the spec fails by running `bash tools/test-local.sh <layer>`.
5. Implements the fix in `vendor/wheels/**` or `app/**`.
6. Re-runs and confirms the spec passes.
7. Updates `CHANGELOG.md`. Other doc updates (`.ai/wheels/`, MDX guides,
   `CLAUDE.md`) happen in the next stage, not here — propose-fix's budget
   stays focused on TDD work.
8. Opens a draft PR on `fix/bot-<issue>-<slug>` against `develop`,
   referencing the research comment when applicable.

The PR must pass `bot-tdd-gate.yml` before any other check — that gate
hard-rejects bot PRs that don't include both a spec change and an
implementation change. The gate is a no-op for human-authored PRs and
for docs-only bot PRs (`docs/bot-*` branches from the write-docs stage).

### 4. Write Docs (`bot-write-docs.yml`)

The docs-path counterpart to propose-fix. Fires from triage's
`wheels-bot:docs-confidence:high` marker on issues classified as
`docs-request`. Sonnet, 30-turn budget — doc work is pattern-recognition,
not reasoning-heavy. Also runnable manually via `workflow_dispatch`.

The bot:

1. Reads the triage comment and the issue body for the docs scope.
2. Auto-downgrades and stops if the work signals a larger structural
   docs-architecture decision than this stage handles cleanly. Posts
   `wheels-bot:docs-held:<issue>` instead of opening a PR.
3. Writes MDX guide pages, `.ai/wheels/` references, or `CLAUDE.md`
   updates as appropriate. Filesystem writes are scoped to doc paths
   only — the workflow's allowlist forbids touching `vendor/`, `app/`,
   `tests/`, `.github/`, `cli/`, or `config/`.
4. For features that benefit from screenshots, inserts placeholder
   comments in the MDX (the bot has no headless browser available; the
   PR description lists the placeholders so a human can capture and
   replace them).
5. Adds a `CHANGELOG.md` entry.
6. Opens a draft PR on `docs/bot-<issue>-<slug>` against `develop`.

The `docs/bot-*` branch prefix is what causes the `bot-tdd-gate.yml`
check to skip — docs-only PRs have no spec/impl invariant. Reviewer A
and Reviewer B still cover the PR, so the human merge decision has the
same analytical context as for fix PRs.

### 5. Update Docs (`bot-update-docs.yml`)

Adds doc commits to a freshly-opened bot PR. Runs as a separate stage so
propose-fix's budget can stay focused on TDD work (failing spec →
implementation → passing spec → CHANGELOG → PR), with documentation
following as a sibling stage rather than competing for the same turn
budget. Sonnet, 30-turn budget — doc edits are pattern-recognition work,
not reasoning-heavy.

Auto-fires on `pull_request: opened` for PRs from the `wheels-bot[bot]`
identity (the draft PRs that propose-fix produces). Manual dispatch is
preserved as a fallback:

```bash
gh workflow run bot-update-docs.yml --repo wheels-dev/wheels -F pr-number=<N>
```

The bot:

1. Reads the PR's diff and the linked issue's triage comment to identify
   the affected layer.
2. Decides whether docs need updating: MDX guide page (only if user-visible
   behavior changed), `.ai/wheels/<layer>/` (only if a documented pattern
   actually changed), `CLAUDE.md` (only if conventions changed). Skips
   cleanly with a "no doc updates" comment when the diff is purely
   internal.
3. Makes conservative edits — limited to the touched paths only, no new
   page creation, no broad rewrites.
4. Lands a single `docs:` commit on the PR branch and posts an update
   comment with the marker `wheels-bot:update-docs:<pr>`.

The narrow allowlist (no test runs, no Lucee bootstrap, no
`vendor/wheels/` or `app/` writes) keeps this stage fast and cheap. The
bot-identity check on the `if:` block is load-bearing — it prevents human
PRs from triggering this stage and adding bot-authored doc commits to
in-flight branches.

### 6. Reviewer A (`bot-review-a.yml`)

Fires on two trigger paths:

1. **`pull_request: opened/synchronize/ready_for_review`** — initial
   review (`/review-pr`). Reviews:
   - Human PRs that are ready-for-review (drafts are skipped — they're
     work-in-progress and reviewing them would churn).
   - The bot's own PRs **even while draft**, so the human merge
     decision is informed by Reviewer A's analysis (and Reviewer B's
     critique) rather than blind.
2. **`issue_comment: created`** matching `wheels-bot:review-b:` (and
   NOT `:terminal`, NOT `wheels-bot:converged-`) — response mode
   (`/respond-to-critique`). Triggered by Reviewer B posting a
   not-yet-aligned critique. A reads B's critique, engages with each
   finding (concede or defend with evidence), and submits a response
   review (state `COMMENT`). The response triggers Reviewer B's next
   round, continuing the back-and-forth until alignment.

Initial review posts a `gh pr review` with verdict
`approve` / `request-changes` / `comment` and findings grouped under
Correctness, Conventions, Cross-engine, Tests, Docs, Commits, Security.
Response review posts as `COMMENT` state with engagement on each of B's
findings.

### 7. Reviewer B (`bot-review-b.yml`)

Fires when Reviewer A submits a review (filtered on
`review.user.login == 'wheels-bot[bot]'`). Reviewer B critiques A's
review, not the PR — looking for sycophancy ("LGTM" without evidence),
false positives (claims that don't match the actual code), and missed
issues. Runs on both human PRs (ready-for-review only) and the bot's
own PRs (even draft — same rationale as Reviewer A).

**Reviewer B is also the convergence arbiter.** Each round, after
critiquing A's review or response, B decides whether they and A are
now aligned on a recommendation. B emits one of three signals:

- `converged-approve` — aligned, no changes needed. PR is review-clean
  for this SHA. Loop terminates; the human can mark ready for merge.
- `converged-changes` — aligned on the need for changes. **Triggers
  `bot-address-review.yml`** (Stage 8) to apply the consensus.
- (no convergence marker) — not aligned. Triggers Reviewer A to respond
  to this critique in the next round, continuing the back-and-forth.

Posts as a PR comment (not a review) so it doesn't re-trigger itself.
Loop is capped at **10 rounds per SHA**. Round 11 emits a terminal
message that triggers Stage 9 (Senior Advisor) — A and B couldn't
align, so an Opus advisor breaks the deadlock and issues a
tie-breaking verdict that drops back into the convergence flow.

### 8. Address Review (`bot-address-review.yml`)

Fires when Reviewer B emits a `wheels-bot:converged-changes:<pr>:<sha>`
marker. Reads the consensus from the A↔B exchange, applies the agreed
changes to the PR's existing branch, and pushes the new commits. The
new SHA triggers a fresh Reviewer A run, restarting the convergence
loop on the updated PR state.

This is a *coding* stage — Opus model, 60-minute timeout, broad
allowlist with the test runner (mirrors propose-fix's setup). Different
from the analytical Sonnet stages above.

The bot:

1. Reads A's review/responses and B's critique chain to identify the
   consensus changes (intersection of A's findings B verified + B's
   missed-issues findings A didn't refute).
2. Auto-downgrades and stops if the consensus touches sensitive areas
   (security, migrations, deploy, DI). Posts
   `wheels-bot:address-held:<pr>:<sha>` instead of making changes.
3. Branch-aware scope: `fix/bot-*` PRs allow code/test edits; `docs/bot-*`
   PRs are doc-paths-only (refuses to touch code if a finding requires
   it — escalates to held).
4. Applies the consensus changes and re-runs affected specs for
   `fix/bot-*` PRs.
5. Commits + pushes back to the PR's existing branch.
6. Posts a comment summarizing what was addressed and what was skipped.

**Outer-loop cap: 5 implementation rounds per PR.** After 5 rounds, the
prompt refuses to fire and posts a "max iterations reached, human
attention required" comment. Combined with Reviewer B's 10-round inner
cap, the maximum bot effort per PR is bounded at 5 implementations × 10
A↔B rounds = 50 review rounds before a human takes over.

Reviewer A and Reviewer B continue to cover the PR after each
implementation cycle — the address-review's commit triggers `pull_request:
synchronize` → Reviewer A on the new SHA → loop continues.

### 9. Senior Advisor (`bot-advisor.yml`)

The deadlock-breaker. Fires when Reviewer A and Reviewer B fail to
converge after the inner-loop cap (B emits a `:terminal` marker at
round 11). The advisor reads the full A↔B exchange, the disputed
code, and the canonical references (`CLAUDE.md`, `.ai/wheels/`),
then issues a tie-breaking verdict.

**This is the only stage that runs Opus on a non-coding task.** The
reasoning depth is justified because the advisor's verdict overrides
the analytical reviewers' deadlock — it must be right. Address-
review uses Opus because it modifies code; advisor uses Opus because
it adjudicates code-related disputes Sonnet couldn't resolve.

The advisor:

1. Confirms the deadlock by finding B's terminal marker for the
   current SHA.
2. Reads A's reviews/responses + B's critiques chronologically.
3. Identifies the SPECIFIC points of disagreement (findings A flagged
   but B persistently rejected; issues B raised but A persistently
   refuted; verdict mismatches).
4. **Reads the actual disputed code at each cited line** — doesn't
   rely solely on the exchange's quoted snippets.
5. Consults canonical references for each ruling.
6. Rules on each disputed point with concrete evidence (file:line,
   doc path).
7. Synthesizes one verdict: `approve` (disputes wash out) or
   `changes` (at least one disputed finding required action).
8. Posts a comment with the rulings + verdict + a convergence marker
   that drops back into the existing flow:
   - `converged-approve` → loop ends, PR is review-clean for this SHA
   - `converged-changes` → triggers `bot-address-review.yml` (Stage 8)
     to apply the advisor's specified findings

The advisor fires once per SHA (idempotent on
`wheels-bot:advisor:<pr>:<sha>`). It does NOT iterate or re-debate
the rulings — its verdict is authoritative within the convergence
loop. If the resulting address-review introduces a new SHA, the
fresh A↔B loop on that SHA starts over from round 1.

**Cost:** Opus + 30-min timeout + read-only allowlist. Worst case
per advisor run: ~$3-5. Triggered only on deadlocks, so most PRs
never invoke it.

## Maintenance: auto-close stale triage (`bot-auto-close.yml`)

Runs on cron at 06:00 UTC daily. Closes issues that:

- Have a bot triage comment
- Have the `cannot-reproduce` label
- Have no human comment newer than the triage comment
- Are at least 14 days old

Mirrors Bun's `auto-close-duplicates.yml` pattern.

## Markers

Every bot comment, review, or PR ends with an HTML-comment marker. Markers
are how the bot detects whether it's already processed a given target —
they make every workflow safely retryable.

| Marker | Meaning |
|---|---|
| `wheels-bot:triage:<issue>` | Triage stage processed this issue. |
| `wheels-bot:triage-class:<bug\|framework-design\|docs-request\|other>` | Triage classification. |
| `wheels-bot:triage-confidence:high` | Triggers propose-fix on the bug path. |
| `wheels-bot:docs-confidence:high` | Triggers write-docs on the docs-request path. |
| `wheels-bot:research:<issue>` | Research stage processed this issue. |
| `wheels-bot:research-confidence:high` | Triggers propose-fix on the framework-design path. |
| `wheels-bot:fix:<issue>` | Fix PR has been opened for this issue. |
| `wheels-bot:fix-held:<issue>` | Fix would have been proposed but the safety net held it for a human. |
| `wheels-bot:write-docs:<issue>` | Write Docs stage opened a docs PR for this issue. |
| `wheels-bot:docs-held:<issue>` | Docs would have been written but the safety net held it for a human. |
| `wheels-bot:update-docs:<pr>` | Update Docs stage processed this PR (with or without doc edits). |
| `wheels-bot:review-a:<pr>:<sha>` | Reviewer A submitted its initial review at this SHA. |
| `wheels-bot:review-a-response:<pr>:<sha>:<round>` | Reviewer A responded to B's critique at round N (convergence loop). |
| `wheels-bot:review-b:<pr>:<sha>:<round>` | Reviewer B critiqued round N. |
| `wheels-bot:converged-approve:<pr>:<sha>` | A and B aligned on `approve` — PR is review-clean. |
| `wheels-bot:converged-changes:<pr>:<sha>` | A and B aligned on changes needed — triggers `bot-address-review.yml`. |
| `wheels-bot:address-review:<pr>:<sha>:<round>` | Address-review applied consensus at SHA, round N (outer loop). |
| `wheels-bot:address-held:<pr>:<sha>` | Address-review would have made changes but the safety net held it for a human. |
| `wheels-bot:advisor:<pr>:<sha>` | Senior Advisor (Opus) issued a tie-breaking verdict on a deadlocked A↔B exchange at this SHA. |
| `wheels-bot:auto-close:<issue>` | Auto-close cron closed this issue. |

## Operating the bot

### One-time setup (admins)

1. Create the GitHub App at `github.com/settings/apps/new` under the
   `wheels-dev` org. Permissions: Contents R/W, Issues R/W, Pull Requests
   R/W, Metadata R. No webhooks.
2. Install the App on `wheels-dev/wheels`.
3. Create a repo ruleset that allows the App's identity to push only to
   refs matching `bot/**` and `fix/bot-*/**`. Block force-push everywhere.
4. Add repo secrets: `WHEELS_BOT_APP_ID`, `WHEELS_BOT_PRIVATE_KEY`. Confirm
   `ANTHROPIC_API_KEY` is already present (used by `docs-validation.yml`).
5. Create the repo variable `WHEELS_BOT_ENABLED` and set it to `true`.
6. Create the labels `skip-claude` and `cannot-reproduce` in the GitHub UI.
7. Update branch protection on `develop` to require these checks:
   - `Validate Commit Messages` (existing)
   - `Lucee 7 + SQLite (LuCLI)` (existing)
   - `Bot PR TDD Gate` (new — only fails on bot PRs without a spec)

   **Approval requirement: `required_approving_review_count: 1`.** The
   bot opens PRs as `--draft`, but with auto-fire enabled (Phase 4) the
   approval gate is the load-bearing safety net that prevents a runaway
   chain from merging itself. Multi-maintainer teams may require reviews
   from a specific team (e.g. `wheels-dev/maintainers`); solo-maintainer
   setups can leave it at 1 with the maintainer as the reviewer. The
   `Bot PR TDD Gate` required check still enforces test discipline on
   every bot PR regardless of approval count.

### Day-to-day

- **Watch every bot run.** Even with auto-fire enabled, every bot PR is
  `--draft` and requires an approving review (`required_approving_review_count: 1`
  in develop's ruleset) before merge. Spot-check triage classifications
  and Reviewer A verdicts; flip `WHEELS_BOT_ENABLED=false` if anything
  looks off.
- **Auto-fire (Phase 4) is on.** propose-fix runs from
  `wheels-bot:triage-confidence:high` and
  `wheels-bot:research-confidence:high` markers; research runs from
  `wheels-bot:triage-class:framework-design`; write-docs runs from
  `wheels-bot:docs-confidence:high`; bot-update-docs runs on
  `pull_request: opened` for `wheels-bot[bot]` PRs (excluding
  `docs/bot-*` branches); **address-review runs on
  `wheels-bot:converged-changes:` markers from Reviewer B**;
  **Reviewer A's response mode runs on non-converged
  `wheels-bot:review-b:` markers**; **Senior Advisor runs on B's
  `:terminal` markers (deadlock resolution)**. To halt auto-fire
  without code changes, flip `WHEELS_BOT_ENABLED=false`. To halt
  permanently, revert the `if:` blocks in the workflows back to
  `workflow_dispatch`-only and keep the kill-switch flipped.
- **Review bot-authored PRs the same as human-authored PRs.** Don't
  rubber-stamp.
- **Watch costs.** API spend per fix-PR is non-trivial (Opus + many turns +
  test runner minutes). Phase 5 includes a budget-alerter cron — wire it in
  before going wider.

### Stopping the bot

- `[skip-claude]` label or title token → halts on a single issue/PR.
- Repo variable `WHEELS_BOT_ENABLED=false` → halts the entire bot suite.
- Suspending the App in GitHub Settings → halts everything and revokes
  push permissions.

The first option is the right tool for almost every "stop on this one"
case. Reach for the second only during an outage or runaway-cost incident.

## Reference patterns

The bot's structure is modelled on Bun's public Claude workflows
(`oven-sh/bun/.github/workflows/claude-*.yml` and
`oven-sh/bun/.claude/commands/*.md`):

- Slash commands as Markdown files with numbered steps and explicit rails.
- HTML-comment idempotency markers (Bun: `<!-- dedupe-bot:marker -->`,
  ours: `<!-- wheels-bot:<stage>:<key> -->`).
- Parallel sub-agent fan-out for multi-source research (Bun's `dedupe.md`
  fan-outs across 5 search strategies; our `research-frameworks.md`
  fan-outs across 6 frameworks).
- A dedicated bot user (Bun: `robobun`; ours: `wheels-bot[bot]`).
- Scheduled cleanup (Bun: `auto-close-duplicates.yml`; ours:
  `bot-auto-close.yml`).



