# /research-frameworks

Cross-framework research synthesis for a `framework-design` issue. Compare
how Rails, Laravel, Django, Phoenix, Spring Boot, and one other relevant
framework handle the topic, then propose a Wheels-idiomatic adaptation
with a self-rated confidence.

## Rails

Read `.claude/commands/_shared-rails.md` first. Highlights for this command:

- `WebFetch` and `WebSearch` are allowed. Other write-side network tools
  are not.
- `WebFetch` should target official documentation domains:
  - `rubyonrails.org`, `guides.rubyonrails.org`, `api.rubyonrails.org`
  - `laravel.com`, `laravel.com/docs`
  - `docs.djangoproject.com`
  - `hexdocs.pm/phoenix`
  - `spring.io/guides`, `docs.spring.io`
  - The framework's own GitHub repo for source-of-truth
- Use `WebSearch` to discover URLs first when you don't know the canonical
  page.
- Do NOT propose Lucee-only or Adobe-only APIs — see
  `.ai/wheels/cross-engine-compatibility.md`.

## Args

- `<issue-number>` — the framework-design issue to research

## Steps

1. **Idempotency check.** Read existing comments on the issue. If any
   contains `<!-- wheels-bot:research:<issue-number> -->`, exit silently.

2. **Re-read the issue.** Pull the title, body, and any human follow-up
   comments via `gh issue view <issue-number> --json title,body,comments`.
   Extract the actual question:
   - What problem is the requester trying to solve?
   - What API surface are they imagining (if any)?
   - What constraints have they named?
   - Have any humans weighed in with preferences?

3. **Parallel framework research.** Use the Agent tool to launch 6 parallel
   sub-agents (or fewer if fewer frameworks are relevant). Each agent gets:

   - **The exact question** (one paragraph extracted from step 2)
   - **A specific framework** to research
   - **An explicit return format**: `{ apiSurface, exampleUsage, ergonomicTradeoffs, edgeCases, idiomaticNaming, sourceUrls }`

   Frameworks to dispatch:
   - **Rails** (always) — search rubyonrails.org/guides + api.rubyonrails.org
   - **Laravel** (always) — search laravel.com/docs
   - **Django** (always) — search docs.djangoproject.com
   - **Phoenix** (when ORM / web-layer relevant) — hexdocs.pm/phoenix
   - **Spring Boot** (when validation / DI / middleware relevant) — docs.spring.io
   - **One other** — pick based on topic. Examples: Symfony for HTTP plumbing,
     Express/Koa for middleware, FastAPI for type-driven routing, Hanami for
     Rails-alternatives. Justify the pick in your synthesis.

   Each agent uses `WebFetch` against the canonical docs and returns its
   structured summary.

4. **Synthesize.** With all framework summaries in hand:

   a. **Build a comparison table**: rows are frameworks, columns are
      `Naming`, `Surface`, `Trade-offs`, `Edge cases`. Be terse —
      one phrase per cell.

   b. **Identify the dominant pattern.** Which approach do most frameworks
      converge on? Where do they meaningfully diverge? Is there a clear
      "modern consensus" or do the trade-offs split reasonable people?

   c. **Cross-reference Wheels constraints.** Read:
      - `CLAUDE.md` § "Critical Anti-Patterns"
      - `CLAUDE.md` § "Wheels Conventions"
      - `.ai/wheels/cross-engine-compatibility.md`
      - `.ai/wheels/<closest-layer>/`

      Flag any conflict between the dominant pattern and existing Wheels
      conventions. Specifically:
      - Does the proposed API use mixed positional+named arguments? (anti-pattern)
      - Does it depend on `struct.map()` / `obj["key"]()` / array-by-value? (cross-engine break)
      - Does it require Lucee-only or Adobe-only APIs?
      - Does it conflict with existing scope / enum / association naming?

   d. **Draft a Wheels-idiomatic API sketch in CFML.** This is what the
      `propose-fix` workflow will use as its spec target. Include:
      - Function signature(s)
      - Two or three usage examples
      - Where it lives (`vendor/wheels/<layer>/`, mixin or component)
      - How it composes with existing scopes / chainable query builder /
        enum / DI container

5. **Self-rate confidence.** Apply these rules in order:

   - Default = `high` if the dominant pattern is clear AND your CFML sketch
     respects all Wheels conventions AND no cross-engine concerns surfaced.
   - **Downgrade to `medium`** if:
     - The dominant pattern conflicts with a CLAUDE.md "Critical Anti-Pattern"
       and you had to adapt it
     - The dominant pattern conflicts with an existing Wheels convention
       (naming, association style, scope semantics) and you had to adapt it
     - The "+1 framework" you picked is doing it differently and the
       trade-off is non-trivial
   - **Downgrade to `low`** if:
     - Frameworks materially disagree (e.g., Rails and Django pick opposite
       sides of an ergonomic trade-off and there's no obvious right answer
       for Wheels)
     - The proposal would require new infrastructure (a new mixin, a new
       lifecycle hook, a new DI scope) — these warrant a human discussion
     - The issue is broad enough that "what should the API be" is itself
       a multi-week design conversation

6. **Post the comment.** Format:

   ```
   ## Wheels Bot — Cross-Framework Research

   ### Question
   <one-paragraph restatement of what the issue is asking>

   ### How other frameworks handle this

   | Framework | Naming | Surface | Trade-offs | Edge cases |
   |---|---|---|---|---|
   | Rails | … | … | … | … |
   | Laravel | … | … | … | … |
   | Django | … | … | … | … |
   | <Phoenix or Spring Boot> | … | … | … | … |
   | <+1 with justification> | … | … | … | … |

   ### Dominant pattern
   <one-paragraph synthesis: where do they converge, where do they diverge>

   ### Recommended path for Wheels

   <one-paragraph rationale>

   ```cfml
   <CFML API sketch — function signatures + usage examples>
   ```

   Lives in: `vendor/wheels/<layer>/<file>.cfc`.
   Composes with: <existing primitives, e.g. scopes / chainable builder>.

   ### Cross-engine notes
   <one paragraph: Lucee/Adobe/BoxLang concerns; "none" if clean>

   ### Open questions
   <bullets — anything a human should weigh in on>

   ### Confidence: `<low|medium|high>`

   <one sentence: why this confidence level (cite any auto-downgrade rule
   that fired)>

   ### Sources
   - <Rails URL>
   - <Laravel URL>
   - <Django URL>
   - <…>

   <!-- wheels-bot:research:<issue-number> -->
   <CONFIDENCE_MARKER>
   ```

   Where `<CONFIDENCE_MARKER>` is:
   - `<!-- wheels-bot:research-confidence:high -->` if confidence is high
   - `<!-- wheels-bot:research-confidence:medium -->` if confidence is medium
   - omitted if confidence is low

   Both `high` and `medium` markers trigger auto-fire of
   `bot-propose-fix.yml`. Low stays manual — material framework
   disagreement or new-infrastructure proposals warrant a human discussion
   before any code is written.

7. **Self-check before posting.**
   - Have you cited at least one URL per framework?
   - Is the comparison table populated (no placeholder dashes)?
   - Does the CFML sketch compile mentally — no obvious anti-patterns,
     mixed argument styles, or cross-engine traps?
   - Is the confidence level consistent with the auto-downgrade rules?
   - Are all required markers present?

   If any check fails, fix and re-post (do not double-post).
