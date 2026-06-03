# Wheels Bot

`wheels-bot[bot]` is a custom GitHub App that runs Claude-powered automation on issues and PRs in `wheels-dev/wheels`. Five stages, all opt-out via the `[skip-claude]` label or repo variable `WHEELS_BOT_ENABLED=false`. Slash-command prompts live in `.claude/commands/`; workflows in `.github/workflows/bot-*.yml`. Full user-facing docs: [`docs/contributing/wheels-bot.md`](../../docs/contributing/wheels-bot.md).

## Stages

| Stage | Trigger | Model | Output |
|---|---|---|---|
| Triage | issue opened/reopened | Opus | Comment classifying as `bug` / `framework-design` / `other` (+ confidence on `bug` path). Reads code with the allowlisted tools to resolve uncertainty before rating. |
| Research | bot triage emits `framework-design` marker | Opus | Comment comparing Rails / Laravel / Django / Phoenix / Spring Boot / +1 and recommending a Wheels-idiomatic path (+ confidence). |
| Propose Fix | bot triage emits `triage-confidence:high\|medium` OR research emits `research-confidence:high\|medium` (or `workflow_dispatch`) | Opus | TDD-mandatory draft PR on branch `fix/bot-<issue>-<slug>`. Spec-then-implementation, both required by `bot-tdd-gate.yml`. |
| Reviewer A | PR opened / synchronized / ready_for_review | Sonnet | Single PR review with line comments, verdict, and `wheels-bot:review-a:<pr>:<sha>` marker. |
| Reviewer B | Reviewer A submits a review | Sonnet | PR comment critiquing A for sycophancy, false positives, and missed issues. Loop cap = 3 rounds. |

## Marker conventions (HTML comments, used for idempotency)

- `<!-- wheels-bot:triage:<issue> -->` + `<!-- wheels-bot:triage-class:<bug|framework-design|other> -->` (+ optional `<!-- wheels-bot:triage-confidence:high|medium -->` — either fires propose-fix; low omitted)
- `<!-- wheels-bot:research:<issue> -->` (+ optional `<!-- wheels-bot:research-confidence:high|medium -->` — either fires propose-fix; low omitted)
- `<!-- wheels-bot:fix:<issue> -->` / `<!-- wheels-bot:fix-held:<issue> -->`
- `<!-- wheels-bot:review-a:<pr>:<sha> -->`
- `<!-- wheels-bot:review-b:<pr>:<sha>:<round> -->`
- `<!-- wheels-bot:auto-close:<issue> -->`

## Allow-listed scopes per stage

Every bot-authored commit must conform to the `commitlint.config.js` allowlist (see CLAUDE.md § Commit Message Conventions). The bot's prompt (`.claude/commands/_shared-rails.md`) re-states the allowlist verbatim.

## Kill switch

Flip the repo variable `WHEELS_BOT_ENABLED` to `false` to halt every bot workflow without code changes. Add the `[skip-claude]` label (or `[skip-claude]` in the title) to halt activity on a single issue/PR.

## Auto-fire safety net

The bot is permitted to chain stages (triage → research → propose-fix), and handoff fires on `*-confidence:high` OR `*-confidence:medium`. Low stays manual. Sensitive areas (security, middleware, migrations, deploy, DI, cross-engine) are caught by the propose-fix prompt's own step-4 safety net, which posts a `fix-held` marker instead of opening a PR. Reviewer A and B then critique whatever propose-fix produces, escalating to the Senior Advisor on deadlock. All bot PRs land as `--draft` and require a human approving review on `develop`.

## PR-prep automation (release unblocking)

- **Commit-message gate.** `pr.yml`'s `Validate Commit Messages` lints the
  **PR title** (the squash subject), not every commit — because PRs are
  squash-merged, intermediate commit headers don't land in `develop`; only the
  PR title does. Edit the title to fix a failure; the `edited` trigger re-runs
  the check (and `fast-test` is skipped on title-only edits). Local guard:
  `tools/test-commit-title.sh`.
- **Freshen (`bot-freshen.yml`).** On push to develop + a 30-min backstop:
  behind-but-clean bot PRs are updated via non-destructive `update-branch`;
  DIRTY ones are dispatched to the resolver. Decision logic:
  `.github/scripts/freshen-decide.sh`.
- **Conflict resolution (`bot-resolve-conflicts.yml` + `/resolve-conflicts`).**
  A deterministic classifier (`.github/scripts/classify-conflicts.sh`)
  auto-resolves content/docs conflicts (md/mdx, CHANGELOG, `.ai/`, `docs/`,
  `web/sites/*/src/content/`) and pushes; any code conflict is escalated with
  the `conflict:needs-human` label and a comment — never auto-resolved.
- **Not automated:** merging. PRs are brought to a green, conflict-free,
  ready state; the maintainer performs the final squash-merge.
