# /review-the-review

Reviewer B. Critique Reviewer A's review of a PR. The goal is to catch
sycophancy, false positives, and missed issues — NOT to re-review the PR
from scratch.

## Rails

Read `.claude/commands/_shared-rails.md` first. Highlights for this command:

- Use `gh` for GitHub state and read-only `git`. No writes, no edits.
- **Output is a PR comment, not a review.** Reviews would re-trigger the
  caller workflow into an infinite loop.
- Loop cap: 3 rounds. Check the existing comment count before posting.

## Args

- `<pr-number>` — the PR being reviewed
- `<review-id>` — the Reviewer A review to critique

## Steps

1. **Idempotency + round counting.** Read the PR comments via
   `gh pr view <pr-number> --json comments,headRefOid`. Count comments
   whose body matches `wheels-bot:review-b:<pr-number>:<sha>:` (any round).

   - If the most recent matching comment has the **current head SHA**, exit
     silently (we already commented on this exact head).
   - Round number = (count of B comments for any SHA on this PR) + 1.
   - **If round > 3**: post the terminal comment and exit:

     ```
     ## Wheels Bot — Reviewer B (no further iterations)

     Round cap (3) reached. Handing back to humans.

     <!-- wheels-bot:review-b:<pr>:<sha>:terminal -->
     ```

2. **Read Reviewer A's review.** Use
   `gh api repos/{owner}/{repo}/pulls/<pr-number>/reviews/<review-id>` to get
   the full body and any line comments. Confirm the author is
   `wheels-bot[bot]` — if not, exit (this command only critiques the bot's
   own reviews).

3. **Read the PR diff.** `gh pr diff <pr-number>` and `gh pr view <pr-number>`.
   You need enough context to verify A's claims.

4. **Critique A's review.** For each section / finding A made, ask:

   **Sycophancy**
   - Did A say "looks good" / "LGTM" / "approve" without citing evidence?
   - Did A approve despite touching security, migration, deploy, or DI
     subsystems (which should always require a human)?

   **False positives**
   - Read the actual lines A cited. Is A's claim accurate? E.g., A says
     "this could SQL inject," but the code uses parameter binding — that
     is a false positive.
   - A flagged a CFML idiom as wrong, but it is a documented pattern in
     `.ai/wheels/` or `CLAUDE.md` — false positive.
   - A insisted on a convention that does not exist in this repo — false
     positive.

   **Missed issues**
   - Re-scan the diff for anything obvious A skipped, especially:
     - Cross-engine compat issues (`.ai/wheels/cross-engine-compatibility.md`)
     - Tests that exist but don't actually exercise the change
     - Commits that violate `commitlint.config.js` (scope, type, length)
     - Missing `.ai/wheels/` updates when behavior changes
     - Security issues A glossed over

   **Tone & actionability**
   - Are A's findings actionable? (file + line + suggestion)
   - Is A's verdict (`approve` / `request-changes` / `comment`) consistent
     with the findings?

5. **Post the comment.** Format:

   ```
   ## Wheels Bot — Reviewer B (round <N>)

   <one-paragraph TL;DR of your assessment of A's review>

   ### Sycophancy
   <bullets, or "none detected">

   ### False positives
   <bullets — quote A's claim, cite the actual code, explain why A is
   wrong, or "none detected">

   ### Missed issues
   <bullets — file + line + the issue A should have flagged, or "none
   detected">

   ### Verdict alignment
   <one sentence: is A's approve/request-changes/comment consistent with
   their findings?>

   <!-- wheels-bot:review-b:<pr>:<sha>:<round> -->
   ```

   Use `gh pr comment <pr-number> --body "<...>"` — do **not** use
   `gh pr review`.

6. **Self-check before posting.**
   - Have you actually read the cited diff lines for each false-positive
     claim? (Do not handwave.)
   - Are your missed-issue findings concrete enough that A could act on
     them in a follow-up review?
   - Is the round number correct in the marker?
   - Have you avoided re-reviewing the PR from scratch? (Stay focused on
     critiquing A.)

   If any check fails, fix and re-post (do not double-post).

## When to be terse

If A's review is genuinely clean — no sycophancy, no false positives, no
missed issues — say so concisely. A short comment like:

```
## Wheels Bot — Reviewer B (round 1)

A's review checks out. No sycophancy, no false positives, no missed issues
on the diff I re-scanned. Verdict alignment looks correct.

<!-- wheels-bot:review-b:<pr>:<sha>:1 -->
```

…is the right output. Don't pad.
