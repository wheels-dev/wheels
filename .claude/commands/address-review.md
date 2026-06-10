# /address-review

Implementer for the convergence loop. After Reviewer A and Reviewer B
have aligned on a "changes needed" verdict for a PR, read the consensus
and apply the changes. Push commits to the PR's existing branch — new
commits trigger a fresh Reviewer A on the new SHA, restarting the
convergence loop until reviewers converge on `approve`.

This is a *coding* stage like propose-fix — Opus, broad allowlist with
the test runner. Mirrors propose-fix's safety patterns.

## Rails

Read `.claude/commands/_shared-rails.md` first. Highlights:

- Use `gh` for GitHub state, full `git` for **the PR's existing branch
  only** (the workflow has checked you out on it).
- Run tests via `bash tools/test-local.sh` for `fix/bot-*` PRs after
  changes.
- For `docs/bot-*` PRs, restrict edits to doc paths only —
  `web/sites/guides/`, `.ai/wheels/`, `CLAUDE.md`, `changelog.d/`.
- Output is **commits to the PR branch** plus **one comment on the
  PR** summarizing what you addressed.

## Args

- `<pr-number>` — the PR with converged-changes markers to address
- `<head-sha>` — the PR head SHA at the start of this run, captured once by
  the workflow and passed here. Use it verbatim as the marker SHA — it is the
  `<sha>` / `<sha-before>` every marker below writes (the head *before* your
  own commit). Don't compute the SHA yourself — re-deriving it mid-session is
  the #2848 race. This governs only the marker SHA; you still use `gh pr view`
  normally to read comments, the consensus, and the head ref name.

## Steps

1. **Idempotency + outer-loop cap.** Throughout this command, the marker SHA
   — written `<sha>` and `<sha-before>` below — is the `<head-sha>` argument
   you were passed; don't compute it yourself (issue #2848). Read PR comments
   via `gh pr view <pr-number> --json comments`.
   - If any comment contains
     `wheels-bot:address-review:<pr>:<head-sha>:` for the `<head-sha>`
     you were passed, exit silently — already addressed at this SHA.
   - Count comments matching `wheels-bot:address-review:<pr>:` for
     ANY SHA on this PR. If count ≥ 5, post:

     ```
     ## Wheels Bot — Address Review (max iterations reached)

     Five address-review rounds have run on this PR without the
     reviewers converging on `approve`. Handing back to humans —
     either the PR's scope is larger than the bot can resolve, or
     the reviewers are deadlocked on a design call.

     <!-- wheels-bot:address-review:<pr>:<head-sha>:terminal -->
     ```

     and exit.
   - Otherwise: round number = (count of address-review comments) + 1.

2. **Read the consensus.**
   - Reviewer A's initial review (`wheels-bot:review-a:<pr>:<sha>:`)
   - All Reviewer A response reviews (`wheels-bot:review-a-response:`)
   - All Reviewer B comments
     (`wheels-bot:review-b:<pr>:<sha>:<round>`) — chronological order
   - The latest B comment carrying
     `wheels-bot:converged-changes:<pr>:<sha>` is the trigger; its
     body summarizes the alignment.

   The **consensus changes** = the union of:
   - A's findings B did **not** mark as false positives
   - B's missed-issues findings A did **not** successfully refute in
     a response
   - Findings both A and B explicitly agreed on in any round

   Skip (do not act on):
   - A's findings B successfully refuted as false positives
   - Findings A and B disagreed on across rounds (the
     converged-changes verdict means there's enough alignment on the
     above to act; isolated disputes are left for the next loop)

3. **Auto-downgrade safety net.** Before writing anything, if any
   consensus finding would touch:
   - `vendor/wheels/security/**`, auth flows, password / token code
   - `vendor/wheels/middleware/**` auth-related middleware
   - Migration files under
     `vendor/wheels/migrator/**` or `app/migrator/migrations/**`
   - `cli/lucli/services/deploy/**` or anything under `wheels deploy`
   - `vendor/wheels/di/**` or DI container internals

   **Stop**. Post:

   ```
   ## Wheels Bot — Address Review held for human review

   The consensus findings touch a sensitive area (`<area>`) and the
   bot's safety net requires a human in the loop before any code
   change. The PR's reviewer-feedback exchange is preserved above
   for context.

   <!-- wheels-bot:address-held:<pr>:<head-sha> -->
   ```

   and exit.

4. **Branch-aware scope check.** Read the PR's head ref via
   `gh pr view <pr-number> --json headRefName -q '.headRefName'`:
   - `fix/bot-*` → may modify code, tests, changelog fragments
     (`changelog.d/<slug>.<type>.md` — never `CHANGELOG.md` directly)
   - `docs/bot-*` → doc paths only. If a consensus finding requires
     touching code, post `address-held` and exit (the PR's scope is
     wrong for that finding).

5. **Apply the consensus changes.** For each consensus finding:
   - Read the cited file
   - Make the smallest change that addresses the finding
   - For `fix/bot-*` PRs: after the changes, re-run any affected spec
     via `bash tools/test-local.sh <layer>` to confirm nothing
     regressed. Capture the output.

6. **Stage and commit.** Single conventional commit on the existing
   branch. Don't open a new branch — push back to the same branch
   the PR is on.

   - Type: `fix` (for `fix/bot-*` PRs) or `docs` (for `docs/bot-*` PRs)
   - Subject (≤ 100 chars):
     `address Reviewer A/B consensus findings (round <N>)`
   - Body: bullet list of what was addressed, with file references.

   ```bash
   git add <files>
   git commit -s -m "<message>"
   ```

   The `-s` flag is required — every commit must carry a `Signed-off-by:`
   trailer matching the configured git author (DCO enforcement; see
   `_shared-rails.md`). The workflow's "Push branch" step pushes after
   this prompt completes.

7. **Post the address-review comment** on the PR:

   ```
   ## Wheels Bot — Address Review (round <N>)

   Applied consensus findings from Reviewer A and Reviewer B's
   convergence (round <round-of-convergence-loop>):

   <bulleted list — what was addressed, file:line references>

   <if any findings were intentionally skipped because they weren't in
   the consensus, list them with "skipped: <reason>">

   The new commit will trigger a fresh Reviewer A run on the updated
   SHA. Convergence loop continues until reviewers align on `approve`
   or the outer-loop cap (5 rounds) is reached.

   <!-- wheels-bot:address-review:<pr>:<head-sha>:<N> -->
   ```

8. **Self-check before posting.**
   - [ ] Branch-aware scope check passed — no files modified outside
     allowed paths
   - [ ] For `fix/bot-*`: tests re-run, output cited in the comment
   - [ ] Commit message is conventional, subject ≤ 100 chars
   - [ ] PR comment includes the marker built from the `<head-sha>`
     argument (the head SHA at the start of this run, before your
     commit — never a value you re-derived; issue #2848)
   - [ ] Outer-loop count is correctly reflected in the round number

   If any check fails, do not post; investigate and exit non-zero.
