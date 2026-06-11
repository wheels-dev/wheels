# /address-review

Implementer for reviewer findings. This is an **opt-in** stage: a human
either applied the `bot-address-review` label to the PR or dispatched the
workflow manually. Read the most recent wheels-bot review on the PR's
current head SHA, apply the actionable findings, and push commits to the
PR's existing branch. The new commit triggers a fresh Reviewer run on the
new SHA; the human decides whether to opt in again.

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

- `<pr-number>` — the PR whose reviewer findings to address
- `<head-sha>` — the PR head SHA at the start of this run, captured once by
  the workflow and passed here. Use it verbatim as the marker SHA — it is the
  `<sha>` / `<sha-before>` every marker below writes (the head *before* your
  own commit), AND the SHA whose wheels-bot review you consume. Don't compute
  the SHA yourself — re-deriving it mid-session is the #2848 race. This
  governs only the marker SHA; you still use `gh pr view` normally to read
  reviews, comments, and the head ref name.

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

     Five address-review rounds have run on this PR. Handing back to
     humans — the PR's scope is larger than the bot can resolve
     iteratively. Remove and re-apply the `bot-address-review` label
     only after a human has reshaped the PR.

     <!-- wheels-bot:address-review:<pr>:<head-sha>:terminal -->
     ```

     and exit.
   - Otherwise: round number = (count of address-review comments) + 1.

2. **Read the reviewer's findings.** Fetch the PR's reviews via
   `gh pr view <pr-number> --json reviews`. Find the **most recent**
   `wheels-bot[bot]` review whose `commit_id` equals `<head-sha>` and whose
   state is `CHANGES_REQUESTED`, or `COMMENTED` with concrete findings in
   the body. That review's findings are your work list.

   - If no wheels-bot review exists on `<head-sha>`, exit silently with a
     brief log line — there is nothing to address at this SHA (the label
     was applied before the Reviewer ran, or only a stale-SHA review
     exists; a fresh Reviewer run will produce one).
   - If the review on `<head-sha>` is `APPROVED`, exit silently — there
     are no changes to make.

   The **actionable findings** = the review's findings that:
   - cite a concrete file/line (or are otherwise precisely actionable), and
   - assert a correctness, convention, cross-engine, test, docs-metadata,
     commit, or security problem (the sections of the review body).

   Skip (do not act on):
   - purely stylistic preferences with no cited convention,
   - findings you cannot verify against the actual code after reading the
     cited lines (note them as skipped in your comment instead),
   - findings explicitly framed as optional/nit by the reviewer.

3. **Auto-downgrade safety net.** Before writing anything, if any
   actionable finding would touch:
   - `vendor/wheels/security/**`, auth flows, password / token code
   - `vendor/wheels/middleware/**` auth-related middleware
   - Migration files under
     `vendor/wheels/migrator/**` or `app/migrator/migrations/**`
   - `cli/lucli/services/deploy/**` or anything under `wheels deploy`
   - `vendor/wheels/di/**` or DI container internals

   **Stop**. Post:

   ```
   ## Wheels Bot — Address Review held for human review

   The reviewer's findings touch a sensitive area (`<area>`) and the
   bot's safety net requires a human in the loop before any code
   change. The review is preserved above for context.

   <!-- wheels-bot:address-held:<pr>:<head-sha> -->
   ```

   and exit.

4. **Branch-aware scope check.** Read the PR's head ref via
   `gh pr view <pr-number> --json headRefName -q '.headRefName'`:
   - `docs/bot-*` (or any `docs/*` branch) → doc paths only. If a finding
     requires touching code, post `address-held` and exit (the PR's scope
     is wrong for that finding).
   - any other branch (`fix/bot-*`, human branches — the label is
     maintainer-applied, so human PRs may opt in too) → may modify code,
     tests, changelog fragments (`changelog.d/<slug>.<type>.md` — never
     `CHANGELOG.md` directly).

5. **Apply the findings.** For each actionable finding:
   - Read the cited file
   - Make the smallest change that addresses the finding
   - When a finding asserts a behavioral bug with no covering spec, extend
     or add a spec alongside the fix (TDD discipline: see the failing
     assertion before the fix where practical)
   - After the changes, re-run any affected spec via
     `bash tools/test-local.sh <layer>` to confirm nothing regressed.
     Capture the output. (Doc-only changes skip the test run.)

6. **Stage and commit.** Single conventional commit on the existing
   branch. Don't open a new branch — push back to the same branch
   the PR is on.

   - Type: `fix` (code changes) or `docs` (doc-only changes)
   - Subject (≤ 100 chars):
     `address reviewer findings (round <N>)`
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

   Applied the Reviewer's findings from its review of <head-sha>:

   <bulleted list — what was addressed, file:line references>

   <if any findings were intentionally skipped — unverifiable, stylistic,
   or explicitly optional — list them with "skipped: <reason>">

   The new commit will trigger a fresh Reviewer run on the updated
   SHA. This stage is opt-in: re-apply the `bot-address-review` label
   (or dispatch the workflow) to address that review too.

   <!-- wheels-bot:address-review:<pr>:<head-sha>:<N> -->
   ```

8. **Self-check before posting.**
   - [ ] Branch-aware scope check passed — no files modified outside
     allowed paths
   - [ ] For code changes: tests re-run, output cited in the comment
   - [ ] Commit message is conventional, subject ≤ 100 chars
   - [ ] PR comment includes the marker built from the `<head-sha>`
     argument (the head SHA at the start of this run, before your
     commit — never a value you re-derived; issue #2848)
   - [ ] Outer-loop count is correctly reflected in the round number

   If any check fails, do not post; investigate and exit non-zero.
