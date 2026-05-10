# Wheels Bot

`wheels-bot[bot]` is a custom GitHub App that automates issue triage,
cross-framework design research, fix-PR generation, and PR review on
`wheels-dev/wheels`. It runs as six stages, each backed by a slash-command
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

## The six stages

### 1. Triage (`bot-triage.yml`)

Fires on `issues: opened` and `issues: reopened`. Reads the issue body and
posts a comment classifying it as one of:

- **`bug`** — observable wrong behavior. The bot identifies the affected
  layer (model / controller / view / etc.) and emits a fix sketch with a
  confidence rating. Reproduction and spec authoring happen in the
  propose-fix stage, not here.
- **`framework-design`** — feature request or API design question. The bot
  hands off to the research stage; it does not opine yet.
- **`other`** — docs, support, or general discussion. No further automation.

For high-confidence `bug` triages the bot emits an additional marker
(`<!-- wheels-bot:triage-confidence:high -->`) which is the trigger for
the propose-fix stage.

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
implementation change. The gate is a no-op for human-authored PRs.

### 4. Update Docs (`bot-update-docs.yml`)

Adds doc commits to a freshly-opened bot PR. Runs as a separate stage so
propose-fix's budget can stay focused on TDD work (failing spec →
implementation → passing spec → CHANGELOG → PR), with documentation
following as a sibling stage rather than competing for the same turn
budget. Sonnet, 30-turn budget — doc edits are pattern-recognition work,
not reasoning-heavy.

Currently `workflow_dispatch` only — invoke with the PR number once
propose-fix has opened the PR:

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
`vendor/wheels/` or `app/` writes) keeps this stage fast and cheap. A
future PR can re-add an auto-fire trigger so this stage runs immediately
after propose-fix opens the PR; for now the manual gate matches the
phased-rollout philosophy from PR #2519.

### 5. Reviewer A (`bot-review-a.yml`)

Fires on `pull_request: opened/synchronize/ready_for_review` against
`develop`. Skips bot-authored PRs (Reviewer A is for human PRs); the bot's
own PRs get reviewed by humans.

Posts a single PR review with line comments grouped under: Correctness,
Conventions, Cross-engine, Tests, Docs, Commits, Security. Verdict is
`approve` / `request-changes` / `comment`. Verdict and findings must be
consistent — Reviewer B will catch sycophancy if they aren't.

### 6. Reviewer B (`bot-review-b.yml`)

Fires when Reviewer A submits a review (filtered on
`review.user.login == 'wheels-bot[bot]'`). Reviewer B critiques A's review,
not the PR — looking for sycophancy ("LGTM" without evidence), false
positives (claims that don't match the actual code), and missed issues.

Posts as a PR comment (not a review) so it doesn't re-trigger itself.
Loop is capped at 3 rounds. Round 4 emits a terminal "no further
iterations" message.

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
| `wheels-bot:triage-class:<bug\|framework-design\|other>` | Triage classification. |
| `wheels-bot:triage-confidence:high` | Triggers propose-fix on the bug path. |
| `wheels-bot:research:<issue>` | Research stage processed this issue. |
| `wheels-bot:research-confidence:high` | Triggers propose-fix on the framework-design path. |
| `wheels-bot:fix:<issue>` | Fix PR has been opened for this issue. |
| `wheels-bot:fix-held:<issue>` | Fix would have been proposed but the safety net held it for a human. |
| `wheels-bot:update-docs:<pr>` | Update Docs stage processed this PR (with or without doc edits). |
| `wheels-bot:review-a:<pr>:<sha>` | Reviewer A reviewed this PR at this SHA. |
| `wheels-bot:review-b:<pr>:<sha>:<round>` | Reviewer B critiqued round N. |
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

   **Approval requirement is org-size-dependent.** Multi-maintainer
   teams should require ≥1 approving review from `wheels-dev/maintainers`.
   Solo-maintainer setups may set `required_approving_review_count: 0`,
   relying on the bot's `--draft` PR posture and the maintainer's manual
   review-then-merge workflow as the human-eye gate. The `Bot PR TDD Gate`
   required check still enforces test discipline regardless of approval count.

### Day-to-day

- **Watch the bot's first runs.** Phase 1 (Reviewer A only) is the safe
  starting cut. Promote subsequent phases (triage, Reviewer B, propose-fix)
  one at a time.
- **Promote propose-fix from manual to auto-fire** only after at least 5
  supervised runs are clean. The shipped default is `workflow_dispatch` only
  (gated in `bot-propose-fix.yml`'s `if:`); to lift the gate, restore the
  `triage-confidence:high` branch (Phase 4a) and the `research-confidence:high`
  branch (Phase 4b). Same pattern applies to `bot-research.yml`.
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



