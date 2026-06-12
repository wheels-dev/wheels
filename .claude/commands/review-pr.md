# /review-pr

The Reviewer. Review the given pull request as a senior Wheels maintainer
would. This is the pipeline's single quality gate: there is no second
reviewer critiquing this review afterwards, so the adversarial self-review
in step 4 is load-bearing — it replaces the retired Reviewer B pass.

## Rails

Read `.claude/commands/_shared-rails.md` first — they apply to every step
below. Highlights for this command:

- Use `gh` for GitHub state and **read-only** `git` (`git diff`, `git log`,
  `git show`, `git grep`). No writes, no pushes, no MCP servers.
- Never edit files. This is a review-only command.
- Output is a **single PR review** (line comments + summary), not a comment.

## Args

- `<pr-number>` — the PR to review
- `<head-sha>` — the commit SHA this review runs against; the workflow
  captures it once at checkout and passes it here. Use it verbatim as the
  marker SHA, and don't compute the SHA any other way — re-deriving it
  mid-session is the #2848 race. This governs only where the *marker SHA*
  comes from: you still use `gh pr view` / `gh pr diff` normally to read the
  PR's title, diff, files, and existing reviews.

## Steps

1. **Idempotency check.** Read existing reviews on the PR with
   `gh pr view <pr-number> --json reviews --jq '.'`. If any review body
   contains the marker `<!-- wheels-bot:review-a:<pr>:<head-sha> -->` for the
   `<head-sha>` you were passed, exit silently — there is nothing to do.
   Always take the marker SHA from the `<head-sha>` argument; don't compute
   it yourself (issue #2848). (The marker keeps the legacy `review-a` name
   for continuity with reviews posted before the single-reviewer
   consolidation — the skip-check gate and the workflow guard both grep for
   it.)

   While you have this JSON, also note whether any wheels-bot review
   (`author.login` is `wheels-bot` — `gh pr view` output drops the `[bot]`
   suffix) has state `CHANGES_REQUESTED`. Step 5's supersede-to-approve
   rule keys off this. A review a human already dismissed reports
   `DISMISSED`, not `CHANGES_REQUESTED`, so matching the latter finds only
   a still-active merge block. (Such a review is necessarily on an earlier
   commit — a wheels-bot review on the current head would have carried the
   marker and ended this session above.)

2. **Gather context.** Read in this order, then build a mental model:
   - `gh pr view <pr-number>` — title, body, author, base, head, labels
   - `gh pr diff <pr-number>` — the full diff
   - `gh pr view <pr-number> --json files` — file list
   - `git log --oneline origin/develop..<head-sha>` — commit list (for
     commit-message review)
   - `CLAUDE.md` § "Critical Anti-Patterns" + § "Wheels Conventions" + §
     "Commit Message Conventions"
   - `.ai/wheels/cross-engine-compatibility.md` — Lucee/Adobe/BoxLang gotchas
   - For any layer touched, the corresponding `.ai/wheels/<layer>/` doc
     (e.g. if `app/models/**` is touched, read `.ai/wheels/models/`)

3. **Review the diff.** Score the change against this checklist. For each
   issue you find, prepare a line comment with file path + line number +
   actionable suggestion.

   **Correctness**
   - Does the change do what the PR title / body claims?
   - Are all code paths covered? Branches, error paths, edge cases?
   - Are there off-by-ones, null derefs, race conditions?

   **Wheels conventions** (CLAUDE.md anti-patterns)
   - Mixed positional + named arguments in Wheels functions
   - Query vs array confusion in views (`<cfloop array=` on a query)
   - Nested resource routes use callback syntax, not Rails inline blocks
   - HTML5 form helpers used (`emailField`, not manual `type="email"`)
   - Migration seed data uses inline SQL (not parameter binding)
   - Route order: MCP → resources → custom → root → wildcard last
   - `t.timestamps()` includes deletedAt — no separate datetime columns
   - Database-agnostic dates (`NOW()`, not `CURRENT_TIMESTAMP`)
   - Controller filters declared `private`
   - View variables `cfparam`-ed at top of view file

   **Cross-engine compatibility** (.ai/wheels/cross-engine-compatibility.md)
   - `struct.map()` member functions on CFC objects (Lucee/Adobe collide)
   - `application` scope function members (Adobe-broken)
   - `client` reserved scope inside closures (Lucee throws)
   - `obj["key"]()` bracket-notation calls (Adobe parser crash)
   - Array by-value in struct literals (Adobe copies)
   - `private` mixin functions in `vendor/wheels/model/*.cfc` etc. — must use
     `public` access with `$` prefix
   - `Left(str, 0)` on Lucee 7

   **Test coverage**
   - Are there tests under `tests/specs/` or `vendor/wheels/tests/specs/`?
   - Are happy path AND error paths covered?
   - For new features, is there a BDD spec extending `wheels.WheelsTest`?
     (Never RocketUnit / `wheels.Test` — that is legacy only.)

   **Docs & metadata**
   - PR template feature-completeness checklist filled honestly
   - `.ai/wheels/<layer>/` updated if behavior changed
   - `web/sites/guides/src/content/docs/v4-0-0-snapshot/` page updated for
     user-facing features
   - Changelog fragment under `changelog.d/` (`<slug>.<type>.md`; a direct
     `CHANGELOG.md` `[Unreleased]` edit is a finding — it recreates the
     merge-conflict anchor the fragment system removes)
   - `CLAUDE.md` updated if model/controller/view conventions changed

   **Commits**
   - Each commit conforms to `commitlint.config.js` (type from allowlist,
     scope from allowlist or empty, subject ≤ 100 chars, not ALL-CAPS)
   - Commit messages reflect the "why," not the "what"

   **Security**
   - SQL injection (raw `where=` strings with user input vs query builder)
   - XSS in views (`#unsafeUserInput#` without `EncodeForHTML`)
   - CSRF on state-changing actions
   - Secret leakage (.env, credentials in fixtures)

4. **Adversarial self-review.** Before writing the review body, switch
   sides: treat your own draft findings the way a hostile second reviewer
   would. This step inherits the retired Reviewer B's anti-sycophancy and
   false-positive mandate — there is no downstream critique pass to catch
   what you let through here.

   For **each** finding from step 3, actively attempt to refute it against
   the actual code:
   - Re-read the cited lines (`Read` the file at the cited location — not
     just the diff hunk). Is the claim accurate as written? E.g. "this
     could SQL inject" is refuted if the code uses parameter binding or the
     query builder.
   - Is the flagged idiom actually a documented pattern in `.ai/wheels/` or
     `CLAUDE.md`? If so, the finding is a false positive — drop it.
   - Does the convention you're insisting on actually exist in this repo?
     `git grep` for prior art. If you can't find it, drop the finding.
   - Can you cite concrete evidence (a quoted line, a doc path) for the
     claim? **Drop any finding you cannot evidence.**

   Then audit the other direction:
   - Re-scan the diff once for anything obvious you skipped — cross-engine
     compat issues, tests that exist but don't exercise the change,
     commitlint violations, security issues you glossed over.
   - Sycophancy check: are you approving without citing evidence, or
     softening a real correctness issue into a "nit"? Don't.
   - Verify the verdict is consistent with the surviving findings'
     severity: a correctness/security/cross-engine finding is incompatible
     with `approve`; a clean diff is incompatible with `request changes`.

5. **Write the review.** Use `gh pr review <pr-number>` (with the verdict
   flag chosen below — `--approve` / `--request-changes` / `--comment`) for
   the summary plus `gh api` to attach line comments — or use a single
   `gh pr review` invocation with `--body` containing line-anchored Markdown
   if line comments are not feasible.

   **Submit exactly one `gh pr review` call per session.** Never probe the
   command with a placeholder (`--body "test body"`, `--body ""`, etc.)
   before issuing the real review — every `gh pr review` invocation is
   visible to humans and counts as a public review. If you need to verify
   syntax or auth, use `gh auth status` or `gh pr view`; do not exercise
   `gh pr review` until you have the final body ready. A post-submission
   guard in `bot-review.yml` auto-dismisses any wheels-bot review missing
   the canonical marker or shorter than 200 characters (issue #2558) — do
   not rely on it as a safety net.

   The review body must:
   - Open with `## Wheels Bot — Reviewer`
   - Have a one-paragraph **TL;DR** that names the PR's purpose and your
     overall verdict (`approve` / `request changes` / `comment`)
   - Group findings under `### Correctness`, `### Conventions`,
     `### Cross-engine`, `### Tests`, `### Docs`, `### Commits`,
     `### Security` — omit empty sections
   - For each finding, cite the file + line, quote the offending snippet,
     and propose a concrete fix
   - End with the marker `<!-- wheels-bot:review-a:<pr>:<head-sha> -->` where
     `<head-sha>` is the SHA passed to this command — never a value re-derived
     from `gh pr view` during the session (issue #2848)

   Submit verdict:
   - `--request-changes` if any **Correctness**, **Cross-engine**, or
     **Security** finding fires, OR if commitlint / TDD violations are
     present. This rule wins on every pass: a re-review that still has a
     blocking finding uses `--request-changes` no matter what any earlier
     round said.
   - **Supersede-to-approve rule (issue #3048).** GitHub keeps a
     reviewer's `CHANGES_REQUESTED` active until the *same* reviewer
     approves or the review is dismissed — a comment-state re-review does
     NOT clear it. Posting `--comment` after an earlier wheels-bot
     `--request-changes` therefore leaves the PR merge-blocked until a
     human manually dismisses the stale review (this wedged #3043 and
     #3044). So when BOTH of these hold:
       (a) no blocking finding fires — nothing under Correctness /
           Cross-engine / Security and no commitlint / TDD violation
           (minor convention / docs nits are fine; keep them in the
           body), AND
       (b) step 1's review read found a wheels-bot review with state
           `CHANGES_REQUESTED` (still active — dismissed ones report
           `DISMISSED`),
     you MUST submit with `--approve`; `--comment` is not an option here.
     In the body, list each previously-blocking finding and the evidence
     it is resolved (file + line of the fix). That audit trail is
     mandatory — it is what a human reads to trust the upgrade, and it
     keeps the body comfortably above the guard's 200-character floor.
     Two exceptions:
       - **Fork PRs never get `--approve`.** Check
         `gh pr view <pr-number> --json isCrossRepository` — when `true`,
         submit `--comment` stating that all blocking findings are
         resolved and that a maintainer must dismiss the stale
         `CHANGES_REQUESTED` review to unblock the PR. Rationale: a bot
         approval can satisfy a required-approving-review branch rule,
         and an outside contribution must never become mergeable on the
         bot's say-so alone. A maintainer is already in the loop on fork
         PRs (the `bot-review` label that triggered this review is
         maintainer-applied), so the manual dismissal is an acceptable
         cost there.
       - **422 fallback.** If GitHub rejects the `--approve` submission
         (HTTP 422 — e.g. the PR author is wheels-bot itself; GitHub
         forbids authors approving their own PRs), resubmit the same
         body once with `--comment`. A rejected call creates no review,
         so the resubmission is still the session's single visible
         review and does not violate the one-review-per-session rule.
   - Otherwise (first pass, or no still-active wheels-bot
     `CHANGES_REQUESTED`): `--comment` if only minor convention / docs
     nits; `--approve` only when the diff is genuinely clean — bias
     toward `--comment` if uncertain. Do not approve as a courtesy. The
     conservative first-pass default is deliberate and unchanged: a
     first-pass `--comment` blocks nothing, so it costs nothing — the
     supersede rule above exists only because a comment cannot clear an
     active `CHANGES_REQUESTED`.

6. **Self-check before submitting.**
   - Have you cited specific files + lines for every finding? (No vague
     handwaving.)
   - Did every finding survive the step-4 refutation attempt? (Anything you
     couldn't evidence must already be gone.)
   - Is your TL;DR consistent with your findings? (Don't say "looks good"
     above a list of correctness issues.)
   - Did you cite at least one piece of evidence (a quoted line, a
     `.ai/wheels/` reference) for each non-trivial claim?
   - If step 1 found a still-active wheels-bot `CHANGES_REQUESTED` and you
     have zero blocking findings: is your event `--approve` (or the
     documented fork / 422 fallback)? A `--comment` here re-wedges the PR
     behind the stale block (issue #3048).
   - Is the marker present?

   If any check fails, redo the review body before submitting.
