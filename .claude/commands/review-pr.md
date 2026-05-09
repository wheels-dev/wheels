# /review-pr

Reviewer A. Review the given pull request as a senior Wheels maintainer would.

## Rails

Read `.claude/commands/_shared-rails.md` first — they apply to every step
below. Highlights for this command:

- Use `gh` for GitHub state and **read-only** `git` (`git diff`, `git log`,
  `git show`, `git grep`). No writes, no pushes, no MCP servers.
- Never edit files. This is a review-only command.
- Output is a **single PR review** (line comments + summary), not a comment.

## Args

- `<pr-number>` — the PR to review

## Steps

1. **Idempotency check.** Read existing reviews on the PR with
   `gh pr view <pr-number> --json reviews,headRefOid --jq '.'`. If any review
   body contains the marker `<!-- wheels-bot:review-a:<pr>:<sha> -->` for the
   current head SHA, exit silently — there is nothing to do.

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
   - `CHANGELOG.md` `[Unreleased]` entry
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

4. **Write the review.** Use `gh pr review <pr-number> --comment` for the
   summary plus `gh api` to attach line comments — or use a single
   `gh pr review` invocation with `--body` containing line-anchored Markdown
   if line comments are not feasible.

   The review body must:
   - Open with `## Wheels Bot — Reviewer A`
   - Have a one-paragraph **TL;DR** that names the PR's purpose and your
     overall verdict (`approve` / `request changes` / `comment`)
   - Group findings under `### Correctness`, `### Conventions`,
     `### Cross-engine`, `### Tests`, `### Docs`, `### Commits`,
     `### Security` — omit empty sections
   - For each finding, cite the file + line, quote the offending snippet,
     and propose a concrete fix
   - End with the marker `<!-- wheels-bot:review-a:<pr>:<sha> -->` where
     `<sha>` is the head SHA you saw at step 2

   Submit verdict:
   - `--request-changes` if any **Correctness**, **Cross-engine**, or
     **Security** finding fires, OR if commitlint / TDD violations are
     present
   - `--comment` if only minor convention / docs nits
   - `--approve` only when the diff is genuinely clean — bias toward
     `--comment` if uncertain. Do not approve as a courtesy.

5. **Self-check before submitting.**
   - Have you cited specific files + lines for every finding? (No vague
     handwaving.)
   - Is your TL;DR consistent with your findings? (Don't say "looks good"
     above a list of correctness issues.)
   - Did you cite at least one piece of evidence (a quoted line, a
     `.ai/wheels/` reference) for each non-trivial claim?
   - Is the marker present?

   If any check fails, redo the review body before submitting.
