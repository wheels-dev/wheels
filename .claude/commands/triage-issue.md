# /triage-issue

Classify a freshly-opened GitHub issue and, if it's a bug, attempt to reproduce
it against the local Wheels test stack.

## Rails

Read `.claude/commands/_shared-rails.md` first — they apply to every step
below. Highlights for this command:

- Use `gh` for GitHub state and read-only `git`. No writes outside your
  scratch worktree.
- Test runs go through `bash tools/test-local.sh`. Do not invoke `lucli`
  directly or hit other test endpoints.
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

5. **Reproduce (bug path only).** This is the heavy step. The caller workflow
   has already brought up Lucee + SQLite via the `setup-wheels-test-env`
   composite action and the test endpoint at `http://localhost:60007/` is
   ready.

   a. **Identify the layer**: model / controller / view / router / middleware /
      migrator / cli / di / job / mailer / sse / seed / config. Read the
      corresponding `.ai/wheels/<layer>/` doc to ground your reasoning.

   b. **Write a minimal failing spec** under
      `vendor/wheels/tests/specs/<layer>/` (or `tests/specs/<layer>/` for
      app-level repros). Use `wheels.WheelsTest` BDD syntax (never RocketUnit).
      The spec should be the smallest thing that demonstrates the bug.

   c. **Run it**: `bash tools/test-local.sh <layer>` (e.g. `model`).
      Capture the failure: which assertion fired, what the diff between
      expected and actual is.

   d. **Do NOT commit the spec.** Triage is read-only as far as the
      repository is concerned. Store the spec content + run output in
      memory for the comment body.

   e. If the spec passes (no reproduction): the bug is either invalid, was
      already fixed, or you wrote the wrong spec. Note this in the comment
      and downgrade confidence.

6. **Self-rate confidence (bug path only).**

   - **`high`**: you reproduced the bug; the failure is unambiguous; the
     suspected layer is clear; a fix is mechanical (one file, no design
     decisions). High-confidence bugs trigger the auto-fire fix-PR
     workflow.
   - **`medium`**: you reproduced the bug but the fix has design
     trade-offs OR you couldn't write a clean spec but the bug is real
     and obvious from the report.
   - **`low`**: you couldn't reproduce; the report is ambiguous; multiple
     layers could be involved; you suspect environment-specific behavior.

   **Auto-downgrade rules** (force at least one level lower):
   - The diff would touch `vendor/wheels/security/**`, auth flows, or any
     `vendor/wheels/middleware/**` → at most `medium`
   - Cross-engine concern detected (Lucee vs Adobe vs BoxLang behavior
     differs) → at most `medium`
   - The spec passes (no reproduction) → at most `low`
   - Migration files, deploy subsystem, or DI container involved → at most
     `medium`

7. **Post the triage comment (bug path).** Format:

   ```
   ## Wheels Bot — Triage

   Classified as **bug**.

   ### Reproduction

   <one paragraph: did you reproduce, what did you see, what spec did you write>

   <fenced code block: the failing spec you wrote>

   <fenced code block: the run output / failure summary>

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
   - For `bug` path: is the spec short and self-contained?
   - For `bug` path: is the confidence consistent with the auto-downgrade
     rules?
   - Are all required markers present?

   If any check fails, fix and re-post (do not post twice).
