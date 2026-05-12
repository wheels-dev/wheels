# /propose-fix

Propose a fix for a triaged issue, in a TDD-mandatory draft PR.

## Rails

Read `.claude/commands/_shared-rails.md` first. Highlights for this command:

- Use `gh` for GitHub state, full `git` for **your branch only** (the
  caller workflow has created `fix/bot-<issue>-<slug>` for you and you are
  checked out on it).
- Run tests via `bash tools/test-local.sh`. Do not invoke `lucli` directly.
- Output is **a single draft PR** against `develop`.

## Args

- `<issue-number>` — the triaged issue to fix

## TDD invariant

You MUST write a failing spec BEFORE writing the implementation, and you
MUST capture the failure output before proceeding to implement. The
`bot-tdd-gate.yml` CI check will reject the PR if the diff has no spec
changes or no implementation changes. The prompt-level discipline below
is enforced by code, so don't skip steps.

## Steps

1. **Idempotency check.** Read existing comments on the issue via
   `gh issue view <issue-number> --json comments`. If any comment contains
   `<!-- wheels-bot:fix:<issue-number> -->`, exit silently — a fix has
   already been proposed.

2. **Read the authoritative context.** Both must be read before doing
   anything else:
   - The triage comment (marker `wheels-bot:triage:<issue-number>`) — gives
     you the layer, fix sketch, and confidence assessment.
   - **If present**, the research comment (marker
     `wheels-bot:research:<issue-number>`) — gives you the recommended path
     forward for framework-design issues. **The research's recommended
     path IS the spec; do not deviate from it without justification.**

   If neither comment exists, exit with a comment explaining no triage
   was found.

3. **Read the supporting docs.**
   - `CLAUDE.md` § "Critical Anti-Patterns" + § "Wheels Conventions" + §
     "Commit Message Conventions"
   - `.ai/wheels/<layer>/` for the affected layer
   - `.ai/wheels/cross-engine-compatibility.md` always
   - `.github/pull_request_template.md` — you will fill this checklist

4. **Auto-downgrade safety net.** Before writing anything, check whether the
   intended fix touches any of:
   - `vendor/wheels/security/**`, `app/middleware/**` auth, password / token
     code
   - `vendor/wheels/migrator/**` or migration files under
     `app/migrator/migrations/**`
   - `cli/lucli/services/deploy/**` or anything under `wheels deploy`
   - `vendor/wheels/di/**` or DI container internals
   - Cross-engine concern (you will need different code paths for
     Lucee/Adobe/BoxLang)

   If yes: **stop**. Do not open a PR. Post a comment on the issue:

   ```
   ## Wheels Bot — Fix on hold for human review

   The proposed fix touches a sensitive area (`<area>`) and the bot's
   safety net requires a human in the loop before any code is written.

   <!-- wheels-bot:fix-held:<issue-number> -->
   ```

   Then exit.

5. **Write the failing spec.** Place under
   `vendor/wheels/tests/specs/<layer>/` (framework-level fix) or
   `tests/specs/<layer>/` (app-level fix). Use `wheels.WheelsTest` BDD
   syntax. The spec should:
   - Be the smallest thing that demonstrates the bug or exercises the
     proposed feature
   - Reproduce the bug as described in the issue body, aligned with the
     fix sketch from the triage comment
   - For `framework-design`: directly assert the API surface the research
     comment recommends

6. **Run the failing spec.**

   ```bash
   bash tools/test-local.sh <layer>
   ```

   Read the bash output directly to confirm the failure — note which
   assertion fired and the diff between expected and actual. **Do NOT
   write to `/tmp/` or anywhere outside the repository working tree.**
   The runtime sandboxes file operations to the working directory; `cp`
   to `/tmp` (or any out-of-tree path) will be blocked and burn turns on
   retries. If you need to persist test output for the next step, write
   to a working-tree path like `./.bot-test-output.txt` and clean it up
   before commit. **Confirm the spec actually fails.** A passing spec at
   this point means you wrote the wrong test — redo it.

7. **Implement the fix.** Edit the relevant files under `vendor/wheels/**`
   or `app/**`. Do not touch:
   - `commitlint.config.js`, `package.json`, `package-lock.json`
   - `.github/workflows/pr.yml`
   - Any other developer's in-flight branch

   Honor every CLAUDE.md anti-pattern. Reference `.ai/wheels/<layer>/`
   patterns for the right shape.

8. **Re-run the spec.**

   ```bash
   bash tools/test-local.sh <layer>
   ```

   Confirm the spec now passes. Also confirm no other tests in the layer
   regressed. If something else broke, fix it before proceeding.

9. **Add a CHANGELOG entry.** Append one line to `CHANGELOG.md` under
   `[Unreleased]` (present tense, no PR number — humans add the link on
   merge). **Do not touch MDX guides, `.ai/wheels/`, or `CLAUDE.md`** —
   those are handled separately by the `bot-update-docs.yml` workflow,
   which runs after this PR opens. The bot's scope here is failing-spec →
   implementation → passing-spec → CHANGELOG → PR.

10. **Stage, commit, and prepare the PR.**

    Conventional commit. Type from `feat`/`fix`/`refactor`/`perf`/`test`/
    `docs`/`chore`. Scope from the allowlist (or no scope). Subject ≤ 100
    chars, sentence-case, not ALL-CAPS.

    Examples:
    - `fix(model): findOne(where=...) honours nested associations`
    - `feat(model): add findEach batch processor`
    - `docs: clarify migration seed pattern for cross-DB compatibility`

    The caller workflow handles the actual `git push` — your job is to
    `git add` the right files and `git commit -s` cleanly. The `-s` flag
    is required: every commit must carry a `Signed-off-by:` trailer
    matching the configured git author (DCO enforcement; see
    `_shared-rails.md`). Do **not** use `--amend` or `--force`.

11. **Open the draft PR.** Use `gh pr create --draft --base develop`. The
    PR body must:
    - Open with one paragraph naming what changed and why
    - Include `Fixes #<issue-number>`
    - **If a research comment was used**: include
      `Recommended path from research: <link to research comment>`
    - Fill the `.github/pull_request_template.md` checklist honestly:
      - [x] Tests — your failing-then-passing spec
      - [ ] Framework Docs — leave unchecked (`bot-update-docs.yml`
        will add MDX updates as a follow-up commit if needed)
      - [ ] AI Reference Docs — leave unchecked (handled by
        `bot-update-docs.yml`)
      - [ ] CLAUDE.md — leave unchecked (handled by
        `bot-update-docs.yml`)
      - [x] CHANGELOG.md
      - [x] Test runner passes (cite the local test-local.sh output)
    - End with the marker `<!-- wheels-bot:fix:<issue-number> -->`

12. **Self-check before opening.** Do NOT proceed unless every box is
    checked:
    - [ ] At least one file under `vendor/wheels/tests/specs/**` or
      `tests/specs/**` is new or modified in the diff
    - [ ] At least one file outside `tests/`, `vendor/wheels/tests/`,
      `.ai/`, `CHANGELOG.md`, `docs/` is new or modified (the
      implementation)
    - [ ] `bash tools/test-local.sh <layer>` exits 0 on the final run
    - [ ] Commit message passes a mental commitlint check
    - [ ] PR is created with `--draft`
    - [ ] PR body cites research comment URL if research was used
    - [ ] Marker is present in PR body

    If any check fails: do not open the PR. Comment "no fix proposed"
    on the issue and exit.

13. **Comment back on the issue** with a link to the PR:

    ```
    ## Wheels Bot — Fix proposed

    Draft PR: <link>

    Spec: `<path/to/spec.cfc>` — failing → passing
    Implementation: `<path(s)>`

    A human review is required before merge. Reviewer A and Reviewer B
    will weigh in shortly. Doc updates (MDX guides, `.ai/wheels/`,
    `CLAUDE.md`) are handled separately by `bot-update-docs.yml`.

    <!-- wheels-bot:fix:<issue-number> -->
    ```

    Then exit.
