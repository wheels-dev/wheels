# /update-docs

Read a PR's implementation diff and add follow-up doc commits (MDX user
guides, `.ai/wheels/<layer>/`, `CLAUDE.md`) to the PR branch. The bot's
implementation is already in the PR; your job is documentation only.

## Rails

Read `.claude/commands/_shared-rails.md` first. Highlights for this command:

- Use `gh` for GitHub state. Use `git add` and `git commit` to land doc
  commits on the PR branch (the caller workflow handles the actual push).
- **Filesystem writes are scoped to doc paths only**:
  `web/sites/guides/**`, `.ai/wheels/**`, `CLAUDE.md`, `CHANGELOG.md`.
  **Do NOT modify any file under `vendor/wheels/**`, `app/**`, `tests/**`,
  `vendor/wheels/tests/**`, `.github/**`, `cli/**`, or `config/**`** —
  the implementation is already in the PR; touching it would create a
  merge conflict and trigger Reviewer A re-runs.
- Output is at most one doc-update commit + one comment on the PR.

## Args

- `<pr-number>` — the PR to add doc commits to

## Steps

1. **Idempotency check.** Read existing PR comments via
   `gh pr view <pr-number> --repo wheels-dev/wheels --json comments`. If
   any comment contains `<!-- wheels-bot:update-docs:<pr-number> -->`,
   exit silently — docs have already been processed for this PR.

2. **Read the PR context.**
   - Title and body via `gh pr view <pr-number> --json title,body`. The
     body should contain `Fixes #<issue-number>`; capture that issue
     number.
   - The implementation diff via
     `gh pr diff <pr-number> --repo wheels-dev/wheels`. Use this to
     understand what changed and roughly which layer was affected.
   - The triage comment on the linked issue (marker
     `wheels-bot:triage:<issue-number>`) — gives you the canonical layer
     name (model / controller / view / etc.).

3. **Decide doc scope.** Walk through these in order; each is independent:

   - **MDX user guide?** If user-visible behavior changed (UI, framework
     feature surface, CLI command, public API, error message text), find
     the relevant page under
     `web/sites/guides/src/content/docs/v4-0-0-snapshot/<area>/`. If no
     obvious page exists, **skip** — note in step 6 that a new doc page
     may be warranted as a follow-up. Do not create new pages.
   - **`.ai/wheels/<layer>/`?** Update only if a documented pattern, a
     conventions table, or a canonical example actually changed in the
     PR diff. Do not edit prose unrelated to the change.
   - **`CLAUDE.md`?** Update only if model/controller/view conventions
     changed (the "Critical Anti-Patterns" or "Wheels Conventions"
     sections in `CLAUDE.md`), or if a new top-level subsystem surfaced.

   **If none of the above apply** (purely internal refactor, test-only
   change, or doc-only PR already shipping the docs), skip to step 6
   with no edits — that is a valid outcome and should be reported as
   such.

4. **Make conservative edits.** For each location identified in step 3:

   - Read the existing file before editing.
   - Limit edits to a few sentences or one short table change. Do **not**
     rewrite whole pages.
   - Match the existing style (tone, heading depth, code-fence language).
   - Do **not** introduce emoji unless the surrounding doc already uses
     them.

5. **Stage and commit (only if there are doc changes).**

   Conventional commit. Type `docs`. Scope from the allowlist if the file
   path matches: `docs` for `.ai/wheels/` updates, `web/guides` for MDX
   under `web/sites/guides/`, no scope for `CLAUDE.md`. Subject ≤ 100
   chars, sentence-case.

   Examples:
   - `docs(web/guides): note registry-package list in debug-panel guide`
   - `docs: update view layer patterns table for debug-panel registry`
   - `docs: clarify findOne nested-association behavior in CLAUDE.md`

   ```bash
   git add <files>
   git commit -m "<message>"
   ```

   The caller workflow handles `git push` — just commit cleanly. Do
   **not** use `--amend` or `--force`.

6. **Comment on the PR.** Use one of these two formats — whichever
   matches what you actually did.

   ### If you made doc edits:

   ```
   ## Wheels Bot — Docs updated

   Added a doc commit to this PR:

   - `<file>` — `<one-line summary>`
   - ...

   <!-- wheels-bot:update-docs:<pr-number> -->
   ```

   ### If no doc edits were needed:

   ```
   ## Wheels Bot — No doc updates

   Reviewed this PR's diff and found no docs that need updating
   (<one short sentence on why — e.g. "purely internal refactor",
   "test-only change", "behavior is not user-visible">).

   <!-- wheels-bot:update-docs:<pr-number> -->
   ```

7. **Self-check before posting.**
   - [ ] No files changed outside doc paths (`web/sites/guides/`,
     `.ai/wheels/`, `CLAUDE.md`, `CHANGELOG.md`)
   - [ ] If a commit was made, message is conventional and ≤ 100 chars
   - [ ] PR comment with `wheels-bot:update-docs:<pr-number>` marker is
     posted
   - [ ] No file under `vendor/wheels/`, `app/`, `tests/`, `.github/`,
     `cli/`, or `config/` was touched
   - [ ] No new MDX page was created (additions to existing pages only)

   If any check fails: do not post the comment. Investigate the diff and
   exit non-zero so a human can clean up.
