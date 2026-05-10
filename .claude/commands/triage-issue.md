# /triage-issue

Classify a freshly-opened GitHub issue, identify the affected layer if it's
a bug, and post a routing comment for downstream stages. Reproduction and
spec authoring happen in propose-fix, not here.

## Rails

Read `.claude/commands/_shared-rails.md` first — they apply to every step
below. Highlights for this command:

- Use `gh` for GitHub state and read-only `git`. No writes outside your
  scratch worktree.
- **Do not write specs or run tests** — triage classifies and routes only.
  Reproduction and spec authoring happen in propose-fix.
- Output is **one comment** on the issue with a stage-appropriate marker.

## Args

- `<issue-number>` — the issue to triage

## Steps

1. **Idempotency check.** Read existing comments via
   `gh issue view <issue-number> --json comments,labels,title,body`. If any
   comment body contains `<!-- wheels-bot:triage:<issue-number> -->` or
   `<!-- wheels-bot:triage-class:` (any class), exit silently.

2. **Read the issue.** Capture: title, body, any code blocks, error messages,
   stack traces, environment info (CFML engine, Wheels version, OS, DB).

3. **Classify.** Pick exactly one of:

   - **`bug`** — the report describes observable wrong behavior, an error,
     a crash, output that doesn't match documented behavior, or a regression.
     Bugs usually have: a "what happened" + a "what I expected" + (often)
     reproduction steps or a code sample.
   - **`framework-design`** — feature request, API design question, "how
     should Wheels do X," "Rails does it like Y, can Wheels do that," anything
     that requires picking among reasonable approaches before code can be
     written. The answer is a design decision, not a defect fix.
   - **`other`** — docs request, support question ("how do I…"), discussion
     thread without an actionable ask, broad product feedback.

   When the report mixes a bug with a feature request, classify as `bug` if
   the bug is reproducible in isolation; otherwise `framework-design`.

4. **Branch by classification.**

   ### If `other`

   Post a brief acknowledgment comment, no automation downstream. Use this
   format:

   ```
   ## Wheels Bot — Triage

   Classified as **other** (general discussion / support / docs request).
   No further bot action will be taken on this issue.

   <!-- wheels-bot:triage:<issue-number> -->
   <!-- wheels-bot:triage-class:other -->
   ```

   Then exit.

   ### If `framework-design`

   Post the classification comment with the trigger marker for the research
   workflow. **Do not attempt to reproduce.** **Do not propose a design
   opinion.** That is the research workflow's job.

   ```
   ## Wheels Bot — Triage

   Classified as **framework-design** (API/feature design question).
   Cross-framework research will follow shortly — Rails, Laravel, Django,
   and other modern frameworks will be consulted before any path forward
   is proposed.

   <!-- wheels-bot:triage:<issue-number> -->
   <!-- wheels-bot:triage-class:framework-design -->
   ```

   Then exit.

   ### If `bug`

   Continue to step 5.

5. **Identify the layer (bug path only).** Pick one of: model / controller /
   view / router / middleware / migrator / cli / di / job / mailer / sse /
   seed / config. Read the corresponding `.ai/wheels/<layer>/` doc to ground
   your reasoning. **Do not write specs and do not run tests** — that work
   belongs in propose-fix. Triage's job here is to tell propose-fix which
   doc to read and roughly where the fix lives.

6. **Self-rate confidence (bug path only).** Rate based on the clarity of the
   issue and the obviousness of the fix shape — not on test reproduction
   (you didn't run any).

   - **`high`**: the report has a clear "what happened / what I expected"
     description; the suspected layer is unambiguous; the fix sketch is
     mechanical (one file, no design decisions). High-confidence bugs
     trigger the auto-fire fix-PR workflow.
   - **`medium`**: the report is clear but the fix has design trade-offs,
     OR cross-engine concerns may exist, OR more than one layer is
     plausibly involved.
   - **`low`**: the report is ambiguous; reproduction steps are vague;
     environment-specific symptoms are suspected; the fix shape isn't
     obvious from the issue body alone.

   **Auto-downgrade rules** (force at least one level lower):
   - The fix would touch `vendor/wheels/security/**`, auth flows, or any
     `vendor/wheels/middleware/**` → at most `medium`
   - Cross-engine concern detected (Lucee vs Adobe vs BoxLang behavior
     differs) → at most `medium`
   - Migration files, deploy subsystem, or DI container involved → at most
     `medium`

7. **Post the triage comment (bug path).** Format:

   ```
   ## Wheels Bot — Triage

   Classified as **bug**.

   ### Suspected layer

   `<layer>` — see `.ai/wheels/<layer>/` for canonical patterns.

   ### Fix sketch

   <one paragraph: what file(s) likely change, what the fix shape looks like>

   ### Confidence: `<low|medium|high>`

   <one sentence: why this confidence level (cite any auto-downgrade rule
   that fired)>

   <!-- wheels-bot:triage:<issue-number> -->
   <!-- wheels-bot:triage-class:bug -->
   <CONFIDENCE_MARKER>
   ```

   Where `<CONFIDENCE_MARKER>` is:
   - `<!-- wheels-bot:triage-confidence:high -->` if confidence is high
   - omitted otherwise (medium/low confidence does not auto-trigger fix-PR)

8. **Self-check before posting.**
   - Is the classification justified by quoted text from the issue?
   - For `bug` path: is the suspected layer one of the documented layers,
     and does the fix sketch identify a plausible target file?
   - For `bug` path: is the confidence consistent with the auto-downgrade
     rules?
   - Are all required markers present?

   If any check fails, fix and re-post (do not post twice).
