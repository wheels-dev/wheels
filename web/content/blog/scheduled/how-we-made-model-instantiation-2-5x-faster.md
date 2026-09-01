---
title: 'How we made model instantiation 2.5x faster'
slug: how-we-made-model-instantiation-2-5x-faster
publishedAt: '2026-09-07T14:00:00.000Z'
updatedAt: null
author: Peter Amiri
tags:
  - wheels-4
  - performance
  - behind-the-scenes
categories:
  - Releases
excerpt: >-
  A 2.5-era app reported its RocketUnit suite running 6x slower on Wheels 4.
  That report sent us down a two-month rabbit hole: benchmark rigs, a
  mixin-architecture refactor, and three targeted hot-path cuts. The result:
  model instantiation is ~2.5x faster than 4.0.3, and the report was right
  the whole time.
coverImage: null
---

This is the story of [issue #3213](https://github.com/wheels-dev/wheels/issues/3213), which began with a forum post and ended with the model layer's architecture changing shape.

Adam had ported his app from Wheels 2.5 to 4.0.3. Same RocketUnit suite: **274 seconds on 2.5, 1,599 seconds on 4.0.3.** Nearly six times slower. He asked whether we'd done any performance comparisons. We hadn't — not like that.

## The first fix was real but small

The first root cause we found was per-object overhead: every `model().new()` and every finder row re-scanned `vendor/wheels/model/`, re-created each of the ~18 mixin components, and re-resolved ~270 method references — on *every instance*. That became the mixin-plan cache in 4.0.6. It helped: roughly 12% on our loop. But it didn't close six times, and Adam's measurement kept bothering us.

So we did the thing we should have done first: **built an actual benchmark rig.** Identical `wheels new` scaffold, same models, same RocketUnit-style workload. Only `vendor/wheels` swapped. Wheels 2.5.0 on one server, current develop on the other, same Lucee 7 engine.

The result: **Adam was right.** 2.5 materialized model instances ~4.9× faster than develop on the same engine. Not an environment artifact, not Lucee 5, not his app. A real regression hiding in plain sight since the 3.x rewrite.

## The architectural difference

Reading 2.5's source made the cause obvious. In 2.5, `wheels/Model.cfc` *compile-time includes* the model API (`include "model/functions.cfm"`). Every method is part of the class, and every instance **inherits** it for free.

The 3.x/4.x rewrite replaced that with *runtime per-instance mixin integration* — a deliberate feature (it powers the plugin/package mixin system), but one that runs on every object creation even when nothing dynamic is registered. Each instance copied ~270 function references into its `variables` and `this` scopes, with per-method collision checks.

Three targeted changes in 4.1 put the static surface back where it belongs:

1. **Request-scope plan cache.** The integration plan was re-read from the synchronized application scope ~6 times per instance. Serving it from the request scope after first use cut that lookup from ~61µs to ~1µs per instantiation.
2. **Compile-time inheritance.** The model mixin files became compile-time includes again — instances inherit the API, no per-instance copy. The hard part was preserving the `super<name>` override convention: when an app overrides a model method, the framework original still has to be reachable. It is, via aliases resolved from a shared prototype, and the override specs still pass.
3. **Direct construction.** `$createObjectFromRoot` now constructs model instances with a direct `CreateObject` + structured call instead of routing every one through the DI container's resolve/auto-wire path plus a reflective `Invoke()`. Models explicitly mapped in the container keep the full path.

## The numbers

Same rig, warmed, 3,000 × `model().new()`:

| version | time |
|---|---|
| 4.0.3 | ~1,290 ms |
| 4.0.6 (+ plan cache) | ~1,290 ms |
| develop after the 4.1 work | **~508 ms** |

The gap to 2.5 on this workload went from ~4.9× to ~1.9×, and the remaining difference is per-instance setup (`$initModelClass`, property handling, callback dispatch) rather than anything structural. We're treating that as a follow-up, not a mystery.

## What the rabbit hole also produced

Benchmarking this hard surfaced two real bugs that had nothing to do with speed:

- A **flaky bare `NullPointerException`** in model instantiation on Lucee 7 — the cached integration plan could carry null function references, which got copied into instances. Fixed by validating the plan once per request and rebuilding it when poisoned.
- The **RocketUnit runner crash** — on Lucee 7, *any* failing test 500'd the entire suite ("variable [MESSAGE] doesn't exist") instead of recording the error. Fixed, with specs.

Both are the kind of thing that makes "slow" look like "broken" in the field — worth knowing if you're still on an older 4.0.x.

## The lesson

The framework had been getting faster in ways that didn't move Adam's number, and we'd have kept optimizing the wrong thing if we'd trusted our own micro-benchmarks instead of building a head-to-head rig against the version users actually compare us to. If you run a Wheels app and your test suite got slower across an upgrade: you were probably right. File it. We'll believe you faster next time.
