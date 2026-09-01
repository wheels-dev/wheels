---
title: 'Pretty URLs with route bindBy='
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
  Wheels 4.1 routes can bind their :key segment to a non-primary-key column:
  bindBy="slug" turns /posts/my-first-post into Post.findBySlug("my-first-post")
  without hand-writing a finder route. Here's how binding works, when to use
  it, and what to do when the bound column isn't unique.
coverImage: null
---

Resource routes in Wheels have always bound their `:key` segment to the model's primary key — `/posts/42` means `Post.findByKey(42)`. That's the right default for internal IDs, but it's the wrong URL for humans. `/posts/42` tells your users nothing; `/posts/wheels-4-1-released` tells them everything, and it's what gets shared, bookmarked, and pasted into chat.

Wheels 4.1 adds the missing piece:

```cfm
mapper()
    .resources(name = "posts", bindBy = "slug")
    .end();
```

With that one option, every `:key` in the generated routes resolves through the parameterized dynamic finder `findOneBySlug()` instead of `findByKey()`. `/posts/wheels-4-1-released` runs `Post.findOneBySlug("wheels-4-1-released")`, and `linkTo(post)` generates the pretty URL instead of the numeric one.

## What `bindBy` is not

Two terms that are easy to conflate:

- **`binding=`** (existing) maps *extra* route parameters to a model lookup used by `renderPage`-style page binding.
- **`bindBy=`** (new) changes *which column the key segment binds through*.

They're orthogonal, and they compose. A route can bind its key to a slug and still declare additional bindings for secondary parameters.

## How the lookup happens

Under the hood, binding resolves through the same parameterized finder convention the rest of the model layer uses. `bindBy="slug"` looks for a `findOneBySlug` method on the model — either the one Wheels generates automatically from your column set, or your own:

```cfm
// app/models/Post.cfc
component extends="Model" {
    function findOneBySlug(required string slug) {
        // case-insensitive, or tenant-scoped, or include-soft-deletes:
        return this.findOne(where = "slug = '#arguments.slug#'", includeSoftDeletes = true);
    }
}
```

Because it's a normal finder, everything a finder can do is available: scoping, ordering, returning `false` for not-found so the framework 404s correctly. If the finder doesn't exist, you get a clear error at request time — which beats the silent numeric-lookup fallback every day of the week.

## When to reach for it

- **Content models with slugs** — posts, pages, docs. The classic case.
- **Usernames** — `/users/ada` instead of `/users/4821` for public profiles.
- **Anything with a natural, stable key** — SKUs, handles, codes.

And when *not* to:

- **Non-unique columns.** If two rows can share the bound value, the finder returns the first match and you've built a confusion generator. `bindBy` is for unique columns — the uniqueness is on you, not the router.
- **Mutable keys.** If the bound value can change (display names, titles edited in place), your URLs rot. Slugs and usernames are usually stable in a way titles aren't.
- **Admin surfaces.** Internal CRUD with numeric IDs is fine staying numeric; pretty URLs buy nothing behind the login wall.

## One thing to plan for

Pretty keys interact with pagination, nested resources, and route precedence exactly like numeric keys — the binding is resolved after the route matches, so nothing about matching changes. But your `linkTo` calls change their output, which means one place to check after flipping a resource to `bindBy`: anything that hard-coded `/posts/#id#` as a string instead of using the helpers. Those were always fragile; `bindBy` just makes them visible.

If you want the full tour of the routing layer before adding `bindBy` to your routes file, the [routing deep dive](https://blog.wheels.dev/posts/associations-deep-dive-wheels-4/) and the route-precedence behavior in the guides are the place to start.
