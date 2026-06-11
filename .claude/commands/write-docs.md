# /write-docs

Create a new documentation PR from a docs-request triaged issue. Writes
MDX guide pages, `.ai/wheels/` references, or `CLAUDE.md` updates as
appropriate, then opens a draft PR against `develop`. This stage is the
docs-path counterpart to propose-fix — it bypasses the TDD invariant
since docs-only PRs have nothing to spec.

## Rails

Read `.claude/commands/_shared-rails.md` first. Highlights for this command:

- Use `gh` for GitHub state, full `git` for **your branch only** (the
  caller workflow has created `docs/bot-<issue>-<slug>` for you and you
  are checked out on it).
- **Filesystem writes are scoped to doc paths only**:
  `web/sites/guides/**`, `.ai/wheels/**`, `CLAUDE.md`, `CHANGELOG.md`.
  **Do NOT modify any file under `vendor/wheels/**`, `app/**`,
  `tests/**`, `vendor/wheels/tests/**`, `.github/**`, `cli/**`, or
  `config/**`** — this is a docs-only stage. The TDD gate skips this
  branch class precisely because docs PRs don't need specs.
- Output is **one draft PR** against `develop` plus one comment on the
  issue.

## Args

- `<issue-number>` — the docs-request issue to write docs for

## Steps

1. **Idempotency check.** Read existing comments on the issue via
   `gh issue view <issue-number> --json comments`. If any comment
   contains `<!-- wheels-bot:write-docs:<issue-number> -->` or
   `<!-- wheels-bot:docs-held:<issue-number> -->`, exit silently — docs
   have already been written or the safety net already held them.

2. **Read the authoritative context.**
   - The triage comment (marker `wheels-bot:triage:<issue-number>`) —
     gives you the docs scope and confidence assessment.
   - The issue body — original wording on what's needed.
   - Any human follow-up comments — they may refine the scope.

   If no triage comment exists, exit with a comment explaining no triage
   was found.

3. **Read the supporting context.**
   - `CLAUDE.md` § "Commit Message Conventions" — type `docs`, allowed
     scopes (`docs`, `web/guides`, `web/landing`, `web/blog`, etc.).
   - `web/sites/guides/src/content/docs/v4-0-0-snapshot/` — browse the
     existing structure to find the right place for the new content.
   - One or two existing pages in the same area for style/depth
     reference. Match existing tone (no emoji unless the surrounding
     pages use them).

4. **Auto-downgrade safety net.** Before writing anything, check whether
   the work would:
   - Touch more than ~5 files (signals over-broad scope)
   - Require creating a new top-level section (vs. extending existing)
   - Demand significant code-reading to write accurately (signals the
     issue is really `framework-design`, not `docs-request`)
   - Need real screenshots that the bot cannot produce (these become
     placeholders; see step 6)

   If the scope feels too big to write cleanly, **stop**. Post a comment
   on the issue:

   ```
   ## Wheels Bot — Docs work on hold for human review

   The proposed docs scope is larger than this stage handles cleanly
   (<one-line reason>). A human should plan the structure before the
   bot writes content.

   <!-- wheels-bot:docs-held:<issue-number> -->
   ```

   Then exit.

5. **Decide what to write.** Based on the triage scope and the issue body,
   pick targets:

   - **MDX guide page(s)** under
     `web/sites/guides/src/content/docs/v4-0-0-snapshot/`. If the issue
     is about a feature or subsystem, look for the right `<area>/`
     (e.g. `working-with-wheels/`, `digging-deeper/`,
     `command-line-tools/`). Add to an existing page where possible;
     create a new page only when no existing page covers the area.
   - **`.ai/wheels/<layer>/`** — only if the docs change documents a
     pattern or convention an AI agent should know about. Most user-
     facing docs do NOT need a corresponding `.ai/` update.
   - **`CLAUDE.md`** — only if the change is about a top-level convention
     or critical anti-pattern. Most docs PRs do NOT touch `CLAUDE.md`.

6. **Write conservatively.**
   - Read the existing page (if extending) before editing.
   - Match the existing style: heading depth, code-fence language tags,
     prose tone.
   - **For features that benefit from screenshots:** insert a placeholder
     comment in the MDX where the screenshot belongs:

     ```mdx
     {/* screenshot: short description of what to capture, e.g.
         "Debug Panel — Packages tab showing both installed and
         available-from-registry tables" */}
     ```

     The bot cannot capture screenshots itself (no headless browser
     available in the runner). The PR description (step 8) will list
     these placeholders so a human can capture and replace them.
   - Add a `CHANGELOG.md` `[Unreleased]` entry. One line, present
     tense, no PR number.

7. **Stage and commit.**

   Conventional commit. Type `docs`. Scope from the allowlist:
   - `web/guides` for changes under `web/sites/guides/src/content/docs/`
   - `docs` for `.ai/wheels/` changes
   - no scope for `CLAUDE.md` or mixed paths
   Subject ≤ 100 chars, sentence-case.

   Examples:
   - `docs(web/guides): add Debug Panel guide outlining each feature`
   - `docs(web/guides): document scope on findOne nested includes`

   ```bash
   git add <files>
   git commit -s -m "<message>"
   ```

   The `-s` flag is required — every commit must carry a `Signed-off-by:`
   trailer matching the configured git author (DCO enforcement; see
   `_shared-rails.md`). The caller workflow handles the actual `git push`
   — just commit cleanly. Do **not** use `--amend` or `--force`.

8. **Open the draft PR.** Use `gh pr create --draft --base develop`. The
   PR body must:

   - Open with one paragraph naming what was added/changed and why.
   - Include `Fixes #<issue-number>`.
   - **List screenshot placeholders** if any were inserted. Format:

     ```markdown
     ## Screenshots needed

     This docs PR includes screenshot-placeholder markers that a human
     reviewer can replace with captured images:

     - `<file>:line` — `<description from the placeholder>`
     - ...

     The bot cannot run the app or capture images — these are
     intentional gaps for a human follow-up.
     ```

   - End with the marker `<!-- wheels-bot:write-docs:<issue-number> -->`.

9. **Self-check before opening.** Do NOT open the PR if any check fails:
   - [ ] No files changed outside doc paths (`web/sites/guides/`,
     `.ai/wheels/`, `CLAUDE.md`, `CHANGELOG.md`)
   - [ ] At least one doc file changed (don't open empty PRs)
   - [ ] Commit message is conventional and ≤ 100 chars
   - [ ] PR body includes `Fixes #<issue-number>`
   - [ ] PR body includes any screenshot-placeholder list
   - [ ] PR is created with `--draft`
   - [ ] Marker is present in PR body

   If any check fails: do not open the PR. Comment "no docs proposed"
   on the issue and exit non-zero.

10. **Comment back on the issue** with a link to the PR:

    ```
    ## Wheels Bot — Docs proposed

    Draft PR: <link>

    Pages updated: <list>
    Screenshots needed: <count, or "none">

    A human review is required before merge. The Reviewer
    will weigh in shortly.

    <!-- wheels-bot:write-docs:<issue-number> -->
    ```

    Then exit.
