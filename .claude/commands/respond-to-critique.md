# /respond-to-critique

Reviewer A — response mode. Engage with Reviewer B's critique on a PR
that you previously reviewed. The goal of this exchange is to converge
on an aligned recommendation between A and B; this prompt is the A
side of that loop.

## Rails

Read `.claude/commands/_shared-rails.md` first. Highlights:

- Use `gh` for GitHub state and read-only `git`. **No file writes.**
- Output is a **single PR review** (state `COMMENT`) with your response,
  not a comment-comment. Reviews keep the loop wired correctly:
  `bot-review-b.yml` fires on `pull_request_review: submitted`, so your
  response triggers B's next round automatically.
- Loop cap is enforced by Reviewer B (10 rounds max per SHA). Don't
  worry about it here.

## Args

- `<pr-number>` — the PR you're discussing with B
- `<head-sha>` — the commit SHA this response runs against (the workflow
  captures it at checkout and passes it here). Use it everywhere this prompt
  writes `<sha>`. Don't compute the SHA yourself — re-deriving it is the
  #2848 race; `gh pr view` / `gh pr diff` remain how you read the exchange.

## Steps

1. **Idempotency check.** Throughout this command, `<sha>` means the
   `<head-sha>` argument you were passed; don't compute it yourself
   (issue #2848). Read PR comments + reviews via
   `gh pr view <pr-number> --json reviews,comments -q '.'`.
   - Find the most recent `wheels-bot[bot]` PR comment whose body
     contains `wheels-bot:review-b:<pr>:<head-sha>:<N>`. That's B's
     latest round number.
   - Find your most recent review on this SHA (initial or prior
     response). If its body contains
     `wheels-bot:review-a-response:<pr>:<head-sha>:<N>` and N matches B's
     latest round, exit silently — you've already responded to that
     critique.
   - Your response round number = B's latest round number.

2. **Read the exchange.**
   - The PR diff via `gh pr diff <pr-number>`.
   - Your most recent review on this SHA (initial or prior response).
   - All `wheels-bot:review-b:<pr>:<sha>:` comments on this SHA, in
     chronological order. The most recent one is what you're
     responding to.

3. **Engage with B's latest critique.** For each finding B raised:

   - **B's missed-issues findings** — re-scan the diff at the cited
     lines. Either:
     - **Concede**: B was correct, add the finding to your updated
       position.
     - **Reject**: explain why B is wrong with concrete evidence (the
       line B cited isn't actually problematic; the convention B
       claims doesn't exist; etc.).
   - **B's false-positive claims about your review** — re-read your
     own finding and B's rebuttal. Either:
     - **Concede**: B caught you flagging a non-issue, retract that
       part of your position.
     - **Reject**: defend your finding with additional evidence (cite
       `.ai/wheels/<layer>/`, `CLAUDE.md`, the actual code semantics).
   - **B's verdict-alignment concerns** — if B flagged your verdict
     (approve/request-changes/comment) as inconsistent with findings,
     decide: are you updating your verdict, or defending the original
     with reasoning?

4. **Submit your response review.** Use
   `gh pr review <pr-number> --comment --body "<...>"`. State must be
   `COMMENT` (not approve, not request-changes — those are reserved
   for the initial review's verdict; responses use COMMENT so the
   verdict tracking stays consistent across rounds).

   **Submit exactly one `gh pr review` call per session.** Never probe
   the command with a placeholder body before issuing the real response —
   every invocation is publicly visible. The post-submission guard in
   `bot-review-a.yml` auto-dismisses wheels-bot reviews missing the
   canonical marker or shorter than 200 characters (issue #2558); do not
   rely on it as a safety net.

   Format:

   ```
   ## Wheels Bot — Reviewer A response (round <N>)

   <one-paragraph TL;DR: which points did you concede, which did you
   defend, and what is your updated position on the verdict>

   ### Conceded points

   <bullets — points where B was right and you've updated your
   position, or "none">

   ### Defended points

   <bullets — points where you maintain your original position, with
   evidence (file/line citations, `.ai/wheels/` references), or
   "none">

   ### Updated verdict

   <one sentence: your current recommendation
   (approve/request-changes/comment), and why this differs from your
   initial review if it does>

   <!-- wheels-bot:review-a-response:<pr>:<sha>:<N> -->
   ```

5. **Self-check before submitting.**
   - [ ] Have you ACTUALLY read the lines B cited in their
     false-positive claims? (Don't concede or reject without
     checking.)
   - [ ] Are your defended points backed by concrete citations
     (file/line/`.ai/wheels/`)?
   - [ ] Is your "Updated verdict" line actionable for B's next round?
     (Either "still request-changes for X, Y" or "now I agree it's
     approve.")
   - [ ] Round number in the marker matches B's latest round?

   If any check fails, fix before submitting. Do not double-submit.
