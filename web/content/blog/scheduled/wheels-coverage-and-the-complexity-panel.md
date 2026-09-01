---
title: 'Find your riskiest code: the 900-line controller and the tool that caught it'
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
  There was a controller with nine hundred lines and one bug that only fired
  in September. Three developers touched it that week. When we pointed the
  complexity panel at it, the score said everything — and the coverage run
  said the test suite had never touched it. 4.1 ships the two tools that make
  that obvious before the September bug goes out.
coverImage: '/blog-images/4-1/wheels-coverage-and-the-complexity-panel.png'
---

The controller was nine hundred lines. It did billing, refunds, invoicing, a CSV export, and it was the only place in the app that reached into the payment provider. Nobody was comfortable with it, but it worked, and nobody had the time to be uncomfortable *and* finish a sprint.

Then the September bug happened. A date rollover in the invoice logic. Three developers touched that file in the same week, each changing one if, each assuming the other two were on top of it. It wasn't anyone's fault. It was a nine-hundred-line file with no tests and a cyclomatic complexity score that, if anyone had known it, would have been a red flag painted in neon.

Two numbers predict where your next bug lives better than any code-review checklist: **how complex a file is, and how little of it your tests touch.** Wheels 4.1 ships one tool for each, and they share a score.

## The Complexity panel: always on, always obvious

In development, the debug bar has a *Code Complexity* panel. It walks `app/`, scores every file's cyclomatic complexity statically — one point per decision point (`if`, `loop`, `catch`, boolean operator) — and lists the offenders with their scores.

Two design choices matter, and they're what make the panel catch the September bug rather than just making a nice chart:

- **It's static.** No instrumentation, no test run, no state. The scan runs once per reload and is cached for the application lifetime, so the panel costs one scan, not one per request.
- **It's always visible.** You don't have to remember to run anything — it's in the debug bar every time you open it in dev. That means you *notice* the 900-line controller the day you write it, not three sprints later when it's too big to comfortably refactor.

## `wheels coverage`: the test half

Complexity alone is half the story. A 30-point file with thorough tests is fine; a 10-point file with zero tests is where a September bug lives. That's what the `wheels coverage` command is for:

```sh
wheels coverage            # top 5 by default
wheels coverage --top 10
```

What it does, in order:

1. Instruments `app/` with function-level coverage counters.
2. Runs your app test suite against the running server.
3. Reports a **CRAP ranking** — *Change Risk Analysis and Predictions*: cyclomatic complexity weighted by test coverage, the same score Jenkins' Crap4J made famous. High complexity + low coverage = high CRAP; well-tested = low.
4. **Reverts the instrumentation automatically.** Nothing to clean up, nothing to accidentally commit.

Point it at the 900-line controller and you get the number that was always true: high complexity, no coverage, top of the list. That's not a judgment on the developer — it's a measurement of the *code*, which is the whole point.

## The workflow

The intended loop is boring, in the best way:

1. Debug bar shows you complexity while you work.
2. Before a change, run `wheels coverage --top 10`. The files near the top are your change-risky set.
3. Add tests for the risky paths, watch the ranking move.
4. Enforce the floor in CI if you want — the same complexity engine that powers the panel runs as a maintainer-side gate, so the numbers locally are the numbers CI sees.

The pairing is deliberate: complexity is static and always visible; coverage is the part that takes a test run, so it's on demand. Together they turn "this file feels fragile" into "this file scores 62 CRAP, here's the list."

## Where it comes from

The complexity engine isn't a port of a generic linter — it's the static analyzer the Wheels maintainers run against *the framework itself*. The 4.0 series added it as a CI gate on `vendor/wheels/`, and 4.1 exposes it to your app. It has been chewing on the framework's own ten-thousand-file codebase for months before being aimed at yours, which is a roundabout way of saying: the tool has already found the things you're worried about in the thing we ship. It's CFML-aware where it matters, comment stripping included.

If your suite is slow, pair it with the batch finders from the 4.0 series — coverage runs the whole app suite, and `findEach`/`findInBatches` don't hurt to have around. But start with the command. The list it prints is the most honest risk assessment your codebase has ever had.

The September bug, for what it's worth, is fixed. The controller is not nine hundred lines anymore. Nobody set out to refactor it — the complexity panel just made it impossible to unsee.

Next up: Wheels 4.1.0 is out, published last so every link in this series is live by then. (See the [series index](https://blog.wheels.dev/posts/wheels-4-1-coming/).)
