---
title: 'Find your riskiest code with wheels coverage and the complexity panel'
slug: wheels-coverage-and-the-complexity-panel
publishedAt: '2026-09-09T14:00:00.000Z'
updatedAt: null
author: Peter Amiri
tags:
  - wheels-4
  - CLI
  - testing
categories:
  - Releases
excerpt: >-
  4.1 adds two ways to see where your app's risk lives: a Code Complexity
  panel in the debug bar that scores every file in app/ statically, and a
  wheels coverage command that instruments the app, runs your test suite, and
  reports a CRAP ranking of your most change-risky files.
coverImage: null
---

Two numbers predict where your next bug will come from better than any code review checklist: **how complex a file is, and how little of it your tests touch.** Wheels 4.1 ships one tool for each, and they share a score.

## The Code Complexity debug panel

In development, the debug bar now has a *Code Complexity* panel. It walks `app/`, scores every file's cyclomatic complexity statically — one point per decision point (`if`, `loop`, `catch`, boolean operator) — and lists your worst offenders with their scores.

Two design choices matter:

- **It's static.** No instrumentation, no test run, no state. The scan runs once per reload and is cached for the application lifetime, so the panel costs you one scan, not one per request.
- **It's always visible.** You don't have to remember to run anything — the panel is there every time you open the debug bar in dev, which means you *notice* the 40-decision-point controller you wrote last sprint instead of discovering it in review.

## `wheels coverage` — the test half

Complexity alone is half the story. A 30-point file with thorough tests is fine; a 10-point file with no tests is where regressions live. The command:

```sh
wheels coverage            # top 5 by default
wheels coverage --top 10
```

What it does:

1. Instruments `app/` with function-level coverage counters.
2. Runs your app test suite against the running server.
3. Reports a **CRAP ranking** — *Change Risk Analysis and Predictions*: cyclomatic complexity weighted by test coverage, the same metric Jenkins' Crap4J made famous. A file with high complexity and low coverage scores high; a well-tested file scores low.
4. **Reverts the instrumentation automatically**, so there's nothing to clean up or accidentally commit.

The pairing is deliberate: complexity is static and always visible; `wheels coverage` adds the coverage half on demand, when you want the number rather than the intuition.

## The workflow

The intended loop is simple:

1. Debug bar shows you the complexity rankings while you work.
2. Before a change, run `wheels coverage --top 10` — files near the top of *that* list are your change-risky set.
3. Add tests for the risky paths, watch the ranking move.
4. Enforce the floor in CI if you want to — the same complexity engine that powers the panel runs as a maintainer-side gate, so the numbers you see locally are the numbers CI would see.

## Where it comes from

The complexity engine is the same static analyzer the Wheels maintainers run against the framework itself — the 4.0 series added it as a CI gate on `vendor/wheels/`, and 4.1 exposes it to your app. Which means the tool has been chewing on the framework's own 10,000-file codebase for months before being pointed at yours. It's not a port of a generic linter; it's CFML-aware where it matters (comment stripping included).

If your suite is slow, pair it with the batch finders from the 4.0 series — coverage runs the whole app suite, and `findEach`/`findInBatches` don't hurt to have around. But start with the command. The list it prints is the most honest risk assessment your codebase has ever had.
