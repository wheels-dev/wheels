# Wheels Bot

`wheels-bot[bot]` is a custom GitHub App that automates issue triage,
cross-framework design research, fix-PR generation, and PR review on
`wheels-dev/wheels`. It runs as eight stages, each backed by a slash-command
prompt in `.claude/commands/` and a workflow in `.github/workflows/bot-*.yml`.

> **2026-06-11 consolidation:** the former Reviewer A / Reviewer B critique
> loop was collapsed into a single-pass Reviewer, and the Address Review
> stage became opt-in (label-gated) instead of auto-firing on convergence
> markers. The loop was expensive and flaky, B's marginal catch rate no
> longer justified a second model pass, and the auto-fire push chain had
> landed a broken spec on a PR (#3005).

This page is for humans interacting with the bot. For the design rationale,
see the plan at `/root/.claude/plans/i-just-watched-a-polymorphic-plum.md` (or
its archived copy in the repo when published). For the framework's general
contribution rules, see [`CONTRIBUTING.md`](../../CONTRIBUTING.md).

## TL;DR

- The bot reads issues and PRs and posts comments / reviews / draft PRs.
- It always opens PRs as `--draft` and never merges them. Humans merge.
- It never pushes to `develop`, `main`, or `release/*`. Only to its own
  `bot/**` and `fix/bot-*/**` branches — plus PR branches a maintainer
  explicitly opts into the Address Review stage (subject to the repo
  ruleset's push allowlist).
- Add the `[skip-claude]` label (or include `[skip-claude]` in the title)
  to halt bot activity on a single issue/PR.
- Flip the repo variable `WHEELS_BOT_ENABLED` to `false` to halt the bot
  entirely without code changes.

## The eight stages

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

For `bug` triages rated `high` or `medium` the bot emits an additional
marker (`<!-- wheels-bot:triage-confidence:high -->` or
`<!-- wheels-bot:triage-confidence:medium -->`) which is the trigger for
the propose-fix stage. For `docs-request` triages rated `high` or `medium`
the bot emits `<!-- wheels-bot:docs-confidence:high -->` or
`<!-- wheels-bot:docs-confidence:medium -->`, which is the trigger for
the write-docs stage. Low-confidence triages emit no trigger marker and
stay manual — the downstream stages can still be invoked via
`workflow_dispatch` once a human reviews the triage.

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

For research rated `high` or `medium` the bot emits
`<!-- wheels-bot:research-confidence:high -->` or
`<!-- wheels-bot:research-confidence:medium -->`, either of which is the
trigger for the propose-fix stage on the framework-design path. Low
confidence (material framework disagreement, or proposals that require
new infrastructure) emits no marker — those warrant a human discussion
before code is written.

### 3. Propose Fix (`bot-propose-fix.yml`)

Fires on the triage marker (bug path) or the research marker
(framework-design path) when rated `high` or `medium`. Low-confidence
triages and research stay manual. Sensitive-area fixes (security,
middleware, migrations, deploy, DI, cross-engine) are caught by
propose-fix's own step-4 safety net before any PR is opened — see the
auto-downgrade list in `.claude/commands/propose-fix.md`. Also runnable
manually via `workflow_dispatch`.

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
`wheels-bot:docs-confidence:high` or `wheels-bot:docs-confidence:medium`
marker on issues classified as `docs-request`. Low-confidence
docs-requests stay manual. Sonnet, 30-turn budget — doc work is
pattern-recognition, not reasoning-heavy. Also runnable manually via
`workflow_dispatch`.

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
check to skip — docs-only PRs have no spec/impl invariant. The Reviewer
still covers the PR, so the human merge decision has the same analytical
context as for fix PRs.

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

### 6. Reviewer (`bot-review.yml` / `bot-review-fork.yml`)

The pipeline's single quality gate. Fires on
**`pull_request: opened/synchronize/ready_for_review`** and submits one
substantive review (`/review-pr`) per SHA. Reviews:

- Human PRs that are ready-for-review (drafts are skipped — they're
  work-in-progress and reviewing them would churn).
- The bot's own PRs **even while draft**, so the human merge decision
  is informed by the Reviewer's analysis rather than blind.
- Fork PRs via the separate `bot-review-fork.yml`
  (`pull_request_target`, hardened: base-branch checkout only,
  maintainer-applied `bot-review` label required).

The review posts as a `gh pr review` with verdict
`approve` / `request-changes` / `comment` and findings grouped under
Correctness, Conventions, Cross-engine, Tests, Docs, Commits, Security.

**Verdict supersession (issue #3048).** A reviewer's `CHANGES_REQUESTED`
stays active on GitHub until the same reviewer approves or the review is
dismissed — a later comment-state review does not clear it. The prompt
therefore mandates: when a still-active wheels-bot `CHANGES_REQUESTED`
exists on the PR and the re-review finds zero blocking issues
(Correctness / Cross-engine / Security / commitlint / TDD), the review
is submitted as **approve**, with each previously-blocking finding and
its resolution enumerated in the body — never as comment, which would
wedge the PR behind the stale block until manual dismissal. A re-review
that still has blocking findings keeps using request-changes, and
first-pass verdict policy is unchanged (bias toward comment). Fork PRs
are exempt: the bot never approves a fork PR — an approval could satisfy
a required-approving-review branch rule for code no maintainer has
accepted — so the fork path keeps comment-state verdicts and the
maintainer who applied the `bot-review` label dismisses the stale review
by hand. The approval gate on the bot's *own* PRs is also unaffected:
GitHub forbids authors approving their own pull requests, so a bot
approval can never satisfy `required_approving_review_count` on a
wheels-bot-authored PR (the prompt carries a 422 comment-fallback for
that case). The post-submission review guard needs no change either — an
approval is a review on the SHA, carries the same `wheels-bot:review-a`
marker, and `APPROVED` is one of the two states the guard already
validates and can dismiss.

Because no second reviewer critiques this review afterwards, the prompt
includes an explicit **adversarial self-review** before posting: for each
finding the model attempts to refute it against the actual code (the
retired Reviewer B's anti-sycophancy / false-positive mandate), drops
findings it cannot evidence, and verifies the verdict is consistent with
the surviving findings' severity.

The review's idempotency marker keeps the legacy name
`wheels-bot:review-a:<pr>:<sha>` so reviews posted before the
single-reviewer consolidation still satisfy the skip-check gate.

### 7. Address Review (`bot-address-review.yml`) — opt-in

**This stage never auto-fires.** A human opts a PR in by either applying
the `bot-address-review` label (labeling requires triage access or
higher — this stage pushes commits, so keep the triage role restricted)
or dispatching the workflow manually with the PR number. The previous
auto-fire on Reviewer B's `converged-changes` marker was removed along
with the loop — an unsupervised push chain had landed a broken spec on a
PR (#3005).

This is a *coding* stage — Opus model, 60-minute timeout, broad
allowlist with the test runner (mirrors propose-fix's setup). Different
from the Reviewer, which is analytical.

The bot:

1. Reads the most recent wheels-bot review on the PR's **current head
   SHA** (state `CHANGES_REQUESTED`, or `COMMENTED` with concrete
   findings). Exits silently when no review exists on that SHA.
2. Auto-downgrades and stops if the findings touch sensitive areas
   (security, migrations, deploy, DI). Posts
   `wheels-bot:address-held:<pr>:<sha>` instead of making changes.
3. Branch-aware scope: `docs/bot-*` PRs are doc-paths-only (refuses to
   touch code if a finding requires it — escalates to held); all other
   branches allow code/test/changelog-fragment edits.
4. Applies the actionable findings and re-runs affected specs.
5. Commits (signed, conventional) + pushes back to the PR's existing
   branch.
6. Posts a comment summarizing what was addressed and what was skipped.

**Outer-loop cap: 5 implementation rounds per PR.** After 5 rounds, the
prompt refuses to fire and posts a "max iterations reached" comment.

The Reviewer covers the PR again after each implementation cycle — the
address-review's commit triggers `pull_request: synchronize` → a fresh
review on the new SHA. Whether to address *that* review is again a human
opt-in (re-apply the label or dispatch).

### 8. Senior Advisor (`bot-advisor.yml`) — legacy

The deadlock-breaker for the retired Reviewer A / Reviewer B
convergence loop. Its trigger (Reviewer B's `:terminal` marker at the
old 10-round cap) is no longer produced by any stage, so the workflow
is inert — retained only so historical PRs that already carry a
terminal marker can be advised via a manual rerun. Its `converged-*`
output markers no longer trigger anything (Address Review is label-gated
opt-in). A follow-up may repurpose or remove this stage.

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
| `wheels-bot:triage-confidence:medium` | Triggers propose-fix on the bug path. Sensitive areas are caught by propose-fix's step-4 safety net. |
| `wheels-bot:docs-confidence:high` | Triggers write-docs on the docs-request path. |
| `wheels-bot:docs-confidence:medium` | Triggers write-docs on the docs-request path. Structural docs decisions are caught by write-docs's step-4 safety net. |
| `wheels-bot:research:<issue>` | Research stage processed this issue. |
| `wheels-bot:research-confidence:high` | Triggers propose-fix on the framework-design path. |
| `wheels-bot:research-confidence:medium` | Triggers propose-fix on the framework-design path. |
| `wheels-bot:fix:<issue>` | Fix PR has been opened for this issue. |
| `wheels-bot:fix-held:<issue>` | Fix would have been proposed but the safety net held it for a human. |
| `wheels-bot:write-docs:<issue>` | Write Docs stage opened a docs PR for this issue. |
| `wheels-bot:docs-held:<issue>` | Docs would have been written but the safety net held it for a human. |
| `wheels-bot:update-docs:<pr>` | Update Docs stage processed this PR (with or without doc edits). |
| `wheels-bot:review-a:<pr>:<sha>` | The Reviewer submitted its review at this SHA (legacy `review-a` name retained from before the single-reviewer consolidation). |
| `wheels-bot:address-review:<pr>:<sha>:<round>` | Address-review applied reviewer findings at SHA, round N (outer loop). |
| `wheels-bot:address-held:<pr>:<sha>` | Address-review would have made changes but the safety net held it for a human. |
| `wheels-bot:advisor:<pr>:<sha>` | Senior Advisor verdict (legacy — only on PRs from the retired A/B loop era). |
| `wheels-bot:auto-close:<issue>` | Auto-close cron closed this issue. |

Markers from the retired A/B loop (`wheels-bot:review-a-response:`,
`wheels-bot:review-b:`, `wheels-bot:converged-approve:`,
`wheels-bot:converged-changes:`) still appear on historical PRs but are
no longer produced or consumed.

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
6. Create the labels `skip-claude`, `cannot-reproduce`, `bot-review` (fork-PR
   review opt-in), and `bot-address-review` (address-review opt-in) in the
   GitHub UI.
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
  and Reviewer verdicts; flip `WHEELS_BOT_ENABLED=false` if anything
  looks off.
- **Auto-fire (Phase 4) is on for the issue pipeline.** propose-fix runs
  from `wheels-bot:triage-confidence:high|medium` and
  `wheels-bot:research-confidence:high|medium` markers (subject to the
  campaign guard — it skips when a `peter/issue-<N>-*` branch or an open
  non-bot PR already targets the issue); research runs from
  `wheels-bot:triage-class:framework-design`; write-docs runs from
  `wheels-bot:docs-confidence:high|medium`; bot-update-docs runs on
  `pull_request: opened` for `wheels-bot[bot]` PRs (excluding
  `docs/bot-*` branches). **Address-review never auto-fires** — opt a PR
  in with the `bot-address-review` label or a manual dispatch. To halt
  auto-fire without code changes, flip `WHEELS_BOT_ENABLED=false`. To
  halt permanently, revert the `if:` blocks in the workflows back to
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



