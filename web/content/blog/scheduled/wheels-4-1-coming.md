---
title: 'Wheels 4.1 is coming — and this release has a story'
slug: wheels-4-1-coming
publishedAt: '2026-09-01T14:00:00.000Z'
updatedAt: null
author: Peter Amiri
tags:
  - wheels-4
  - release-notes
categories:
  - Releases
excerpt: >-
  Wheels 4.1 isn't another "we added features and fixed bugs" release. It's
  the release where a single bug report sent us back to the drawing board,
  where a security pass made the things you always assumed were safe actually
  be safe, and where the framework got meaningfully faster. Here's what's
  coming, and the story behind it.
coverImage: '/blog-images/4-1/wheels-4-1-coming.svg'
---

Most release previews are a list. This one has a plot, so let me set the scene.

A few months ago, someone filed an issue that started with a simple question: *"has anyone done a performance comparison between Wheels 2.x and 4.x?"* They'd ported a real app and their test suite went from roughly five minutes to nearly half an hour. It was phrased politely, the way most people phrase "you broke something" when they're trying not to be rude about it.

We'd all been told the framework was getting faster. There were PRs titled "perf" with charts. And yet this person's number kept nagging at us. So we did the thing we should have done at the start: we built an actual benchmark, ran Wheels 2.5 head-to-head against current develop on the same engine, and let the numbers speak.

They didn't flatter us. He'd been right, and by a lot.

That report is the spine of this whole release. It's why 4.1 has a story, and why the content below isn't the usual changelog-walk.

## What's shipping

Over the next two weeks, the blog will walk through each thread, one post at a time:

- **bcrypt for your passwords** — pure-CFML bcrypt helpers, and the migration dance you'll actually have to do to use them.
- **Session auth in one line** — the `enableSession()` facade, and the three subtle bugs it saves you from.
- **Pretty URLs with `bindBy`** — human URLs for resource routes, and the mistake it invites if you're not careful.
- **Factories for your container** — DI `toFactory()`, for when `to()` can't express *how* something is built.
- **CLI workflows that never guess** — `migrate diff`, `generate --dry-run`, offline mode, and the phantom-green-build problems they prevent.
- **2.5× faster, the long way** — the full performance investigation, including the two unrelated bugs it surfaced.
- **Fail closed, everywhere** — the security hardening pass, area by area.
- **Find your riskiest code** — the complexity panel and the `wheels coverage` CRAP ranking.

The **4.1.0 release post** lands after all of them, tying the threads together with the full changelog.

## What to do while you wait

If you want the technical detail right now, the [4.1.0 changelog](https://github.com/wheels-dev/wheels/blob/main/CHANGELOG.md) is already on `develop` — everything below is ships-today, not vaporware. Or run `wheels upgrade check` on a branch and see what you're on.

But the blog series is worth the wait, because the features are only half of it. The other half is *why we built them that way* — and a couple of those decisions are stories you'll want before you upgrade, not after.

See you on the first one. It's about passwords, and it starts with a pentest report.
