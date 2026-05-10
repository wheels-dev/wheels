# /advise-on-deadlock

Senior advisor for the wheels-bot review chain. Fires only when
Reviewer A and Reviewer B fail to converge on a recommendation after
the inner loop's 10-round cap (B emits a `:terminal` marker). Read
the full exchange, identify the specific disputed points, and issue a
tie-breaking verdict using deeper reasoning than the analytical
reviewers brought.

This is the only stage in the pipeline that runs **Opus on a
non-coding task**. The reasoning depth is justified because the
advisor's verdict overrides the analytical reviewers' deadlock and
drops back into the existing convergence flow — the advisor either
ends the loop (`converged-approve`) or triggers `bot-address-review.yml`
(`converged-changes`).

## Rails

Read `.claude/commands/_shared-rails.md` first. Highlights:

- Use `gh` for GitHub state and **read-only** `git`. No file writes,
  no edits, no commits.
- Output is **one PR comment** with the verdict + a convergence
  marker. No PR reviews, no code modifications.
- One-shot stage — fires once per terminal marker per SHA and exits.
  No iteration.

## Args

- `<pr-number>` — the PR with deadlocked A↔B exchange

## Steps

1. **Idempotency check.** Read PR comments via
   `gh pr view <pr-number> --json comments,headRefOid`. If any
   comment contains `wheels-bot:advisor:<pr>:<sha>` for the current
   head SHA, exit silently — already advised at this SHA.

2. **Confirm the deadlock.** Look for a comment containing
   `wheels-bot:review-b:<pr>:<sha>:terminal` for the current head
   SHA. That's the trigger marker. If no terminal marker is present
   for the current SHA, exit silently (this command shouldn't have
   fired).

3. **Read the full exchange.**
   - The PR diff via `gh pr diff <pr-number>`.
   - The PR title/body via `gh pr view <pr-number>` for original
     context (and the `Fixes #<issue>` link, if any — the original
     issue's framing matters).
   - All `wheels-bot[bot]` PR reviews on the current SHA: A's initial
     review and any response reviews
     (`wheels-bot:review-a-response:`).
   - All `wheels-bot[bot]` PR comments on the current SHA matching
     `wheels-bot:review-b:<pr>:<sha>:` — the full B critique chain in
     chronological order.

4. **Identify the deadlock.** Make a precise list of the SPECIFIC
   points where A and B disagreed and never resolved across rounds:
   - Findings A flagged but B persistently called false positives
     (and A defended).
   - Issues B raised but A persistently refuted (and B re-raised).
   - Verdict disagreements (A says `approve`, B says
     `request-changes`, or vice versa).

   For each disputed point, capture: A's position, B's position, and
   why neither yielded.

5. **Read the disputed code.** For each disputed point, `Read` the
   actual file at the cited line. Don't rely solely on quoted
   snippets in the exchange — the source of truth is the code on the
   PR's branch (you're checked out on its head SHA).

6. **Consult canonical references.** Before each ruling:
   - `.ai/wheels/<layer>/` for the layer in dispute (model, view,
     controller, etc.).
   - `CLAUDE.md` § "Critical Anti-Patterns" + § "Wheels Conventions"
     + § "Commit Message Conventions" — these are authoritative.
   - `.ai/wheels/cross-engine-compatibility.md` if the dispute
     touches Lucee/Adobe/BoxLang behavior.
   - Existing precedent: `Grep`/`Glob` for similar code elsewhere in
     the repo to see how this convention is handled when it's not
     contested.

7. **Rule on each disputed point.** For each, decide:
   - **A was right** (cite the evidence)
   - **B was right** (cite the evidence)
   - **Both partially right** (synthesize the actually-correct
     position)
   - **Neither was right** (the dispute itself was misframed; here's
     the real concern)

   Cite a concrete reference for each ruling — file:line, doc path,
   or both.

8. **Synthesize the verdict.** Roll up the per-point rulings into one
   final recommendation:

   - **`approve`** — disputed points were minor, or A and B were
     debating preferences rather than correctness. PR is fine to
     merge as-is. Use this when the per-point rulings are dominated
     by "both partially right" or "neither was right" outcomes.
   - **`changes`** — at least one disputed point clearly required a
     change (you ruled on a real correctness issue, anti-pattern, or
     security concern). Specify which findings address-review should
     act on (the ones you ruled in favor of the side requesting the
     change) and which to drop.

9. **Post the advisor comment** on the PR. Use
   `gh pr comment <pr-number> --body "<...>"`:

   ```
   ## Wheels Bot — Senior Advisor (deadlock resolution)

   Reviewer A and Reviewer B reached the 10-round inner-loop cap
   without converging. After re-reading the full exchange and the
   disputed code, here are the rulings on each contested point:

   ### Disputed points

   1. **<short title>** — A claimed `<A's position>`; B claimed
      `<B's position>`. **Ruling:** `<A right | B right | both
      partially | neither>`. **Evidence:** `<file:line | doc path |
      both>`. `<one-sentence reasoning>`.
   2. ...

   ### Verdict: `<approve | changes>`

   <one paragraph: synthesizing the rulings into the recommendation>

   <if verdict is `changes`, list the specific findings address-review
   should act on:>

   ### Findings for address-review to apply
   - **<finding>** at `<file:line>` — `<concrete action>`
   - ...

   <if verdict is `approve`, note that the disputed findings should be
   dropped and the PR is fine to merge as-is.>

   <!-- wheels-bot:advisor:<pr>:<sha> -->
   <CONVERGENCE_MARKER>
   ```

   Where `<CONVERGENCE_MARKER>` is:
   - `<!-- wheels-bot:converged-approve:<pr>:<sha> -->` if verdict is
     `approve`
   - `<!-- wheels-bot:converged-changes:<pr>:<sha> -->` if verdict is
     `changes` (triggers `bot-address-review.yml`)

10. **Self-check before posting.**
    - [ ] Each ruling cites a concrete file:line, doc path, or both —
      no vague handwaves.
    - [ ] Read the actual disputed code (not just exchange quotes).
    - [ ] Consulted `CLAUDE.md` and `.ai/wheels/` where applicable.
    - [ ] Verdict is one of `approve` or `changes` — not "kinda
      mostly", not equivocal.
    - [ ] Convergence marker is consistent with the verdict.
    - [ ] Advisor marker present.

    If any check fails, fix before posting. The advisor's verdict is
    authoritative within the convergence loop — get it right.
