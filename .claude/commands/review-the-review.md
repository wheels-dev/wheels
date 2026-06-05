# /review-the-review

Reviewer B. Critique Reviewer A's review of a PR. The goal is to catch
sycophancy, false positives, and missed issues — NOT to re-review the PR
from scratch.

## Rails

Read `.claude/commands/_shared-rails.md` first. Highlights for this command:

- Use `gh` for GitHub state and read-only `git`. No writes, no edits.
- **Output is a PR comment, not a review.** Reviews would re-trigger the
  caller workflow into an infinite loop.
- Loop cap: 10 rounds per SHA. Check the existing comment count before
  posting. Convergence happens when you and A agree on a recommendation;
  non-converged rounds keep the loop going via Reviewer A's response.

## Convergence — what this stage decides

After your critique, you choose one of three outcomes:

1. **Aligned, no changes needed** → emit `converged-approve` marker.
   The PR is review-clean for this SHA. The human can mark ready and
   merge.
2. **Aligned, changes needed** → emit `converged-changes` marker. This
   triggers `bot-address-review.yml` to apply the consensus. New
   commits → fresh Reviewer A on the new SHA → loop restarts.
3. **Not aligned** → emit only the round marker (no convergence
   marker). This triggers Reviewer A to respond to your critique in
   the next round, continuing the back-and-forth until alignment.

## Args

- `<pr-number>` — the PR being reviewed
- `<review-id>` — the Reviewer A review to critique
- `<head-sha>` — the commit Reviewer A's review was attached to (the
  workflow passes `github.event.review.commit_id`). Use it everywhere this
  prompt writes `<sha>` — the round marker AND the convergence markers.
  Don't compute the SHA yourself — re-deriving it is the #2848 race;
  `gh pr view` / `gh pr diff` remain how you read the PR and A's review.

## Steps

1. **Idempotency + round counting.** Throughout this command, `<sha>` means
   the `<head-sha>` argument you were passed; don't compute it yourself
   (issue #2848). Read the PR comments via
   `gh pr view <pr-number> --json comments`. Count comments whose body
   matches `wheels-bot:review-b:<pr-number>:<head-sha>:` (any round).

   - If the most recent matching comment has the passed `<head-sha>`
     **AND** the comment count on that SHA already equals the
     review-id you're processing (a precise dedup), exit silently.
   - Round number for `<head-sha>` =
     (count of B comments on this exact SHA) + 1.
   - **If round > 10**: post the terminal comment and exit. The cap
     exists so the loop terminates when A and B can't align — humans
     take over from there.

     ```
     ## Wheels Bot — Reviewer B (round cap reached)

     Round cap (10) reached on this SHA. A and B did not converge —
     the senior advisor (`bot-advisor.yml`, Opus) will engage to
     break the deadlock and issue a tie-breaking verdict.

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

5. **Convergence decision.** After completing the critique, decide
   whether you and A are now aligned on a recommendation. Aligned means
   ALL of:

   - You have no remaining unaddressed missed-issues findings (either
     A flagged them in their initial review, or A conceded them in a
     prior response, or B itself raised them and now considers them
     addressed in A's most recent response).
   - You have no remaining false-positive disputes (every claim A made
     has either been verified by you or successfully retracted by A in
     a response).
   - A's current verdict (approve / request-changes / comment) is one
     you would also recommend after seeing the diff yourself.

   Three possible outcomes:

   - **Aligned + verdict is `approve`** → set the convergence marker
     to `wheels-bot:converged-approve:<pr>:<sha>`. The PR is
     review-clean for this SHA.
   - **Aligned + verdict is `request-changes`** (or `comment` with
     concrete actionable findings) → set the convergence marker to
     `wheels-bot:converged-changes:<pr>:<sha>`. This triggers
     `bot-address-review.yml`.
   - **Not aligned** → no convergence marker (only the round marker).
     This triggers A's response on the next round.

6. **Post the comment.** Format:

   ```
   ## Wheels Bot — Reviewer B (round <N>)

   <one-paragraph TL;DR of your assessment of A's review/response and
   your convergence decision>

   ### Sycophancy
   <bullets, or "none detected">

   ### False positives
   <bullets — quote A's claim, cite the actual code, explain why A is
   wrong, or "none detected">

   ### Missed issues
   <bullets — file + line + the issue A should have flagged, or "none
   detected">

   ### Verdict alignment
   <one sentence: is A's approve/request-changes/comment consistent
   with their findings?>

   ### Convergence
   <one paragraph: are you and A now aligned? what's the joint
   recommendation? if not aligned, what specifically does A need to
   address in their next response?>

   <!-- wheels-bot:review-b:<pr>:<sha>:<round> -->
   <CONVERGENCE_MARKER>
   ```

   Where `<CONVERGENCE_MARKER>` is:
   - `<!-- wheels-bot:converged-approve:<pr>:<sha> -->` for aligned-no-
     changes
   - `<!-- wheels-bot:converged-changes:<pr>:<sha> -->` for aligned-
     changes-needed (triggers `bot-address-review.yml`)
   - omitted entirely if not aligned (triggers A's response in the
     next round)

   Use `gh pr comment <pr-number> --body "<...>"` — do **not** use
   `gh pr review`.

7. **Self-check before posting.**
   - Have you actually read the cited diff lines for each false-positive
     claim? (Do not handwave.)
   - Are your missed-issue findings concrete enough that A could act on
     them in a response?
   - Is the round number correct in the marker?
   - Have you avoided re-reviewing the PR from scratch? (Stay focused
     on critiquing A.)
   - Is your convergence decision consistent with the body of your
     critique? (Don't say "aligned, approve" while listing missed
     issues; don't say "not aligned" while marking everything
     resolved.)
   - If you emitted `converged-changes`, are the changes concrete and
     actionable? (Address-review will read your prior comments to
     synthesize the consensus — make sure it has enough detail.)

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
