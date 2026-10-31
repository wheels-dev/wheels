---
title: We ran a dozen AI coding agents at real Wheels features. Here's what happened.
slug: ai-coding-agents-on-wheels
publishedAt: '2026-10-12T01:05:00.000Z'
updatedAt: '2026-10-12T01:04:43.000Z'
author: Peter Amiri
tags:
  - wheels-4
  - ai
categories: []
excerpt: >-
  We ran a set of AI coding agents at real feature work in a Wheels app,
  scored by hidden acceptance checks, and published every number: across 790
  scored trials the agents passed 88.6% (83.5% raw). Here's what we measured,
  and what we fixed in Wheels as a result.
coverImage: null
announcement:
  discussionUrl: 'https://github.com/wheels-dev/wheels/discussions/4571'
  title: "We ran a dozen AI coding agents at real Wheels features. Here's what happened."
  body: |
    New post: **[We ran a dozen AI coding agents at real Wheels features. Here's what happened.](https://blog.wheels.dev/posts/ai-coding-agents-on-wheels/)** — we ran a set of AI coding agents at real feature work in a Wheels app, scored by hidden acceptance checks, and published every number: across 790 scored trials the agents passed 88.6% (83.5% raw). Here's what we measured, and what we fixed in Wheels as a result.
---

We wanted an honest answer to a simple question: **can today's AI coding agents
build real features in a Wheels app?** So we ran them — a dozen models, at ten
real feature tasks, in a Wheels application, scored by hidden acceptance checks —
and we're publishing every number.

The short version: **across 790 scored attempts, the agents passed 88.6%**
(83.5% before we corrected two over-strict checks — more on that below). Several
strong models finished every task. The [full results page](https://wheels.dev/ai) has every cell,
every task, every correction, and the raw data.

## Like-for-like with Rails

We built this to be comparable to how Ruby on Rails' own
[ai-evals](https://github.com/rails/ai-evals) measures agents, not as a
home-field demo. Same harness (`lemans`), same agent (`miniswen`), a
Writebook-style sample app like theirs, and the same style of task: a plain
feature request, with a hidden spec that decides pass or fail. Seven of our ten
tasks mirror a Rails task; three are Wheels-native. Tasks were frozen and
reviewed before any model ran, and never changed after we saw the results.

Alongside those like-for-like rows we also ran
[Claude Code](https://www.anthropic.com/claude-code) against the same tasks, and
report it separately.

## Does the AI context Wheels ships actually help?

Wheels 4.2 ships AI context for your app — `.ai/` docs and a prebuilt
`.mcp.json` from `wheels new`. We ran every model twice where we could: once with
that context, once without.

Honestly? **The difference was within noise.** The strong models already build a
good Wheels app from the stock conventions; the shipped context mostly helps at
the margins and with newer APIs. We'd rather tell you that than inflate it — and
we're still improving that context, because the ceiling isn't the point, the
floor is.

## What it changed in Wheels

Watching real agents hit real tasks turned out to be one of the best ways we've
found to spot rough edges — and we fixed them for **everyone**, not just the
test. Several 4.2 features exist because an agent needed them and we agreed every
Wheels developer would too:

- [`savedChanges()`](https://github.com/wheels-dev/wheels/pull/4349), so an
  `afterCommit` knows what the commit actually wrote;
- an application data cache,
  [`appCacheFetch()`](https://github.com/wheels-dev/wheels/pull/4388);
- [query assertions](https://github.com/wheels-dev/wheels/pull/4357) for specs;
- a [clock seam](https://github.com/wheels-dev/wheels/pull/4387),
  `travelTo()`, for deterministic time in tests;

plus dozens of smaller docs, CLI, and upgrade-path fixes.

## We corrected two checks, and we're telling you

After the runs, two hidden checks turned out to be stricter than the task
actually asked. We relaxed exactly those two assertions (nothing else), kept both
the before and after numbers, and made the corrected figures primary. The
[results page](https://wheels.dev/ai#5-corrections-and-deviations-in-full) walks through both, plus
the provider refusals, the infrastructure re-runs, and the one agent-native web
fetch — everything.

That transparency is the point. The case isn't that Wheels is magic for agents;
it's that Wheels belongs in this conversation, and that we did the work to help
agents build on it, out in the open.

**Read the full results:** [wheels.dev/ai](https://wheels.dev/ai).

