---
title: 'Pretty URLs with bindBy: the unshareable link'
slug: pretty-urls-with-route-bindby
publishedAt: '2026-09-04T14:00:00.000Z'
updatedAt: null
author: Peter Amiri
tags:
  - wheels-4
  - routing
categories:
  - Releases
excerpt: >-
  A support engineer pastes a link into a customer chat, and they get
  /posts/4821. Nobody shares /posts/4821. bindBy="slug" exists to make
  resource URLs say something — and it comes with one mistake you can make
  that quietly breaks your site.
coverImage: '/blog-images/4-1/pretty-urls-with-route-bindby.png'
---

The support conversation goes like this: *"the article about migrating to 4.1? sure — here's the link."* The customer opens it, and their browser shows `/posts/4821`.

That's the whole conversation. There is no article "about migrating" in a URL like that. There's a number. And numbers don't survive being pasted into a group chat, because nobody can read them back, nobody can tell if they're the *right* article, and everyone ends up sending `https://example.com/posts/4821` with a separate sentence saying "it's the one about migrations."

That link is why `bindBy` exists.

## The one option

Wheels resource routes have always bound their `:key` segment to the model's primary key: `/posts/4821` means `Post.findByKey(4821)`. Correct, predictable, and unreadable by humans.

4.1 adds one option that changes which column the key binds through:

```cfm
mapper()
    .resources(name = "posts", bindBy = "slug")
    .end();
```

With that, every key in the generated routes resolves through the parameterized dynamic finder `findOneBySlug()` instead of `findByKey()`. `/posts/wheels-4-1-released` runs `Post.findOneBySlug("wheels-4-1-released")`, and `linkTo(post)` starts generating the readable URL everywhere — posts index, show links, next/previous, RSS, you name it.

## The finder is yours

Binding resolves through the same convention the rest of the model layer uses: it looks for a `findOneBySlug` method on the model, and it will happily use the one you write:

```cfm
// app/models/Post.cfc
component extends="Model" {
    function findOneBySlug(required string slug) {
        // tenant-scoped, case-insensitive, or include soft-deletes:
        return this.findOne(where = "slug = '#arguments.slug#'", includeSoftDeletes = true);
    }
}
```

Because it's an ordinary finder, everything a finder can do is available — scoping, ordering, returning `false` for not-found so the framework 404s correctly. If the finder doesn't exist, you get a loud error at request time. That's a real improvement over a silent fallback, and it's the detail that makes `bindBy` trustworthy: it never guesses.

## Two ways to get it wrong

This is the story part. There are two mistakes that make `bindBy` bite, and the first one is the one that'll come up in code review.

**Non-unique columns.** The natural instinct is to bind to whatever the human-readable field is. If that field isn't unique, `bindBy` returns the *first* record that matches. Two posts with the same title, and your pretty URL silently serves the wrong one. There's no router-side validation to save you — uniqueness is on you, and it's the thing to double-check before flipping the switch. Slugs and usernames are usually safe; display names and titles are the ones that drift.

**Mutable keys.** If the bound value can change, your URLs rot. A title edited in place changes the URL, and every bookmark and shared link quietly turns into a 404. Slugs are stable by design; "edited title" URLs are a support-desk generator.

The cheat sheet: bind to a column that's **unique and doesn't change**. That's it. Everything else is the framework doing exactly what you asked.

## What binding is and isn't

Two terms in Wheels routing that get conflated:

- **`binding=`** (existing) maps *extra* route parameters to a model lookup for page-style binding.
- **`bindBy=`** (new) changes *which column the key segment binds through*.

They're orthogonal and they compose — a route can bind its key to a slug and still declare additional bindings for secondary parameters.

And `bindBy` doesn't touch route precedence or matching. The binding is resolved *after* the route matches, so nothing about which route wins changes. The only behavioral shift you'll notice: `linkTo()` output, which means one thing to audit after flipping it — any place that hand-built `/posts/#id#` as a string instead of using the helper. Those were always fragile; `bindBy` just makes them visible.

## The un-anonymous link

The support conversation ends differently now. *"The article about migrating to 4.1? Here — /posts/migrating-to-wheels-4-1."* The customer knows it's the right one before they click. They can repeat it in a meeting. It survives being texted.

That's the real win, and it's why the option belongs in the router rather than in a thousand `linkTo` calls: readability isn't an accessory to a resource route — it's the whole reason the route exists.

Next up in the series: read the next post — DI factories, and the service that couldn't decide where its files lived. (See the [series index](https://blog.wheels.dev/posts/wheels-4-1-coming/).)
