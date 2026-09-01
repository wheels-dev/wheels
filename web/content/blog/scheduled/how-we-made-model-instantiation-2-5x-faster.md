---
title: '2.5x faster, the long way: a performance story with a villain'
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
  @chapmandu reported his ported app's test suite running nearly six times
  slower on Wheels 4 than on 2.5. We didn't believe it, so we built a
  benchmark rig to prove him wrong. He was right. Here's the three-month
  investigation, two unrelated bugs it surfaced, and the lesson about
  trusting micro-benchmarks.
coverImage: '/blog-images/4-1/how-we-made-model-instantiation-2-5x-faster.png'
announcement:
  title: '2.5x faster model instantiation'
  body: |
    New post: **[2.5x faster, the long way](https://blog.wheels.dev/blog/how-we-made-model-instantiation-2-5x-faster)** — how model materialization got 2.5x faster, the long way.
---

The issue was polite, which is usually how bad news arrives. [@chapmandu](https://github.com/chapmandu) had ported a real app from Wheels 2.5 to 4.0.3, and his RocketUnit suite went from **274 seconds to 1,599** — nearly six times slower. He asked whether we'd ever done a performance comparison.

We hadn't — not like that. And honestly, we didn't believe him. Not because he was wrong, but because we *knew* the framework was getting faster. There were PRs titled `perf` with charts in them. The 4.0.6 release notes said so. Somebody must have been measuring something.

Here's the part we don't usually tell: we spent weeks optimizing against that assumption, and every improvement moved the 2.5 comparison by a rounding error. Because the thing we were speed-testing wasn't the thing that was slow.

## Building the rig we should have built first

Eventually we did the obvious thing. We built a *real* benchmark: identical `wheels new` scaffold, same models, same RocketUnit-style workload. Only `vendor/wheels` swapped — Wheels 2.5.0 on one server, current develop on the other, same Lucee 7 engine.

The result was not flattering. **2.5 materialized model instances ~4.9× faster than develop on the same engine.** Same hardware, same workload, same request count. [@chapmandu](https://github.com/chapmandu) had been right the whole time, by a wide margin, and it wasn't a Lucee 5 artifact or a quirk of his app. It was a real regression that had been sitting in the framework since the 3.x rewrite.

## The villain wasn't the code we'd been staring at

Reading 2.5's source made it obvious where the time went. In 2.5, `wheels/Model.cfc` *compile-time includes* the model API (`include "model/functions.cfm"`). Every method is part of the class, and every instance **inherits** it for free. Zero per-object cost.

The 3.x/4.x rewrite replaced that with *runtime per-instance mixin integration* — a deliberate design, since it's what powers the plugin/package mixin system. But it ran on every object creation even when nothing dynamic was registered. Each instance copied ~270 function references into its `variables` and `this` scopes, with per-method collision checks. That's the per-object cost that 2.5 never paid.

Once we saw it, three changes in 4.1 put the static surface back where it belonged:

1. **Request-scope plan cache.** The integration plan was re-read from the synchronized application scope ~6 times per instance. Serving it from the request scope after first use cut that lookup from ~61µs to ~1µs per instantiation.
2. **Compile-time inheritance.** The model mixin files became compile-time includes again — instances inherit the API, no per-instance copy. The hard part was preserving the `super<name>` override convention: when an app overrides a model method, the framework original still has to be reachable. It is, via aliases resolved from a shared prototype, and the override specs still pass.
3. **Direct construction.** `$createObjectFromRoot` constructs model instances with a direct `CreateObject` + structured call instead of routing every one through the DI container's resolve/auto-wire path plus a reflective `Invoke()`. Models explicitly mapped in the container keep the full path.

## The numbers

Same rig, warmed, 3,000 × `model().new()`:

| version | time |
|---|---|
| 4.0.3 | ~1,290 ms |
| develop after the 4.1 work | **~508 ms** |

The gap to 2.5 on this workload went from ~4.9× to ~1.9×. The rest is per-instance setup — `$initModelClass`, property handling, callback dispatch — which is a follow-up, not a mystery.

## The two bugs the rabbit hole surfaced

Benchmarking this hard turned up two real bugs that had nothing to do with speed, and they're the kind you only find when you're watching crashes *while* timing them:

- A **flaky bare `NullPointerException`** in model instantiation on Lucee 7 — the cached mixin plan could carry null function references, which got copied into instances. Fixed by validating the plan once per request and rebuilding it when poisoned.
- The **RocketUnit runner crash** — on Lucee 7, *any* failing test 500'd the entire suite ("variable [MESSAGE] doesn't exist") instead of recording the error. Fixed, with specs.

If you're still on an older 4.0.x and a test failure looks like it's taking the whole run down with it, one of those may be why.

## The lesson

The framework had been getting faster in ways that didn't move [@chapmandu](https://github.com/chapmandu)'s number, and we'd have kept optimizing the wrong thing if we'd trusted our own micro-benchmarks instead of building a head-to-head rig against the version users actually compare us to.

So here's the public resolution to that first polite issue: you were right, and we owe you the benchmark. If you run a Wheels app and your suite got slower across an upgrade, file it. The next rig is already built, and it's recording before it argues.

Next up in the series: read the next post — the security hardening pass, where fail-closed stopped being a slogan. (See the [series index](https://blog.wheels.dev/posts/wheels-4-1-coming/).)
