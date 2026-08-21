---
title: 'Calculated Properties: SQL-Defined Values Without the N+1 (or the Bloat)'
slug: calculated-properties-wheels-4
publishedAt: '2026-07-22T14:00:00.000Z'
updatedAt: '2026-07-06T05:23:50.000Z'
author: Peter Amiri
tags:
  - wheels-4
  - models
  - orm
  - performance
categories: []
excerpt: >-
  Declare fullName or commentCount once as SQL on the model and it behaves
  like a column everywhere — sortable, selectable, never stale. And Wheels 4's
  select=false + includeCalculated pair fixes the cost problem calculated
  properties always created: expensive expressions run only where they're
  asked for, additively.
coverImage: null
---

Every app has them: values that belong to a record but don't live in a column. A user's `fullName`. An order's `lineItemCount`. A post's `commentCount`, its `isRecent` flag, the `daysUntilRenewal` someone wants on the admin grid. The usual fates are all bad — duplicated string-concatenation in six views, an N+1 of `COUNT(*)` queries from a loop, or a denormalized column that drifts out of sync.

Wheels has a better fate, and 4.0 quietly made it production-grade: **calculated properties** — SQL expressions declared once on the model and returned as if they were columns — plus a new `select=false` / `includeCalculated` pair that solves the performance problem calculated properties always used to create. This post is the pattern, the new switch, and the boundaries.

## The declaration

One line in `config()` maps a property name to a SQL expression:

```cfm
// app/models/User.cfc
component extends="Model" {
    function config() {
        property(name="fullName", sql="firstName || ' ' || lastName");
    }
}
```

From then on, `fullName` behaves like a column everywhere it matters: it's selected with the record, present on objects and query results, usable in `order=` clauses. Views stop concatenating; the definition lives in exactly one place.

The expression is raw SQL, evaluated by your database — which is the feature's power and its fine print in one. Aggregates against related tables are the classic win:

```cfm
// app/models/Post.cfc
component extends="Model" {
    function config() {
        hasMany("comments");
        property(
            name = "commentCount",
            sql = "(SELECT COUNT(*) FROM comments WHERE comments.postId = posts.id)"
        );
    }
}
```

`model("Post").findAll(order="commentCount DESC")` now sorts by a value that never goes stale, computed in one query instead of one-per-row. (Two things to notice in passing: `column=` and `sql=` are mutually exclusive on `property()` — one renames a real column, the other defines a virtual one — and since the SQL is your responsibility, keep it portable across the databases you actually target. `||` concatenation is ANSI; MySQL wants `CONCAT()`. The same cross-engine discipline as [migrations](https://blog.wheels.dev/posts/migrations-that-survive-a-team).)

## The problem success creates

Here's the lifecycle every team discovers: calculated properties are so convenient that models accumulate them — and **every one of them runs on every default `SELECT`**. That correlated `commentCount` subquery? It executes for every row of every `findAll("Post")` in the entire app, including the dozens of call sites that never look at it. Your hottest list page is paying for the admin grid's convenience.

The old escape hatch was `select="id,title,createdAt"` — spell out exactly the columns you want. It works, but it's brittle in the annoying way: add a column to the table and every hand-written `select=` list in the app silently doesn't include it.

## The 4.0 answer: `select=false` + `includeCalculated`

Declare the expensive property as opt-in:

```cfm
property(
    name = "commentCount",
    sql = "(SELECT COUNT(*) FROM comments WHERE comments.postId = posts.id)",
    select = false
);
```

Now it's off the default `SELECT` — every existing finder in the app just got cheaper, no call sites touched. And the one place that actually wants it opts in *additively*:

```cfm
// the admin grid — the only caller that pays for the count
posts = model("Post").findAll(
    order = "commentCount DESC",
    includeCalculated = "commentCount"
);
```

`includeCalculated` is the crucial half of the design: unlike `select=`, it does **not replace** the default column list — the named calculated properties are merged *on top of* all default columns. You get the whole record plus the expensive extras you asked for, without maintaining a column inventory anywhere. It's accepted by `findAll`, `findOne`, and `findByKey` alike.

The mental model: `select=` is subtractive ("only these"), `includeCalculated=` is additive ("everything, plus these"). Hot paths get the lean default; the few screens that need the aggregate name it explicitly, which doubles as documentation of where your expensive SQL actually runs.

## The typo guard, and its environment split

What happens when you write `includeCalculated="comentCount"`? In `development` and `testing`: an immediate `Wheels.CalculatedPropertyNotFound` throw naming the unknown property — you find the typo before your first coffee. In `production`: unknown names are **ignored** — a typo'd opt-in degrades to a missing value rather than a 500 for your users.

That split is a deliberate pattern across Wheels 4 (you've seen it if you read the [configuration post](https://blog.wheels.dev/posts/how-wheels-reads-configuration)): loud where developers are looking, resilient where customers are. It does carry one implication worth respecting — an `includeCalculated` typo that sneaks past dev testing won't announce itself in production. Your dev-suite coverage of the screens that use opt-in properties is the guard; the framework already made it a throwing error there.

## Boundaries: what calculated properties are not

- **Not CFML.** The expression runs in the database. If the value needs application logic — formatting, branching on config, calling a service — that's an ordinary model method, not a calculated property. The dividing line: could a `WHERE` or `ORDER BY` reasonably use it? Then SQL. Is it presentation? Then a method.
- **Not writable.** They're read surfaces; there's nothing to `save()`. (They're also excluded from things that only make sense for real columns — you won't see them in [auto-migration](https://guides.wheels.dev/v4-0-0/basics/migrations/) diffs.)
- **Not free just because they're hidden.** `select=false` moves the cost to the callers that opt in; it doesn't shrink the cost. A subquery that's slow on the admin grid is still slow — it's just no longer slow everywhere else. For genuinely heavy aggregates on hot screens, the answer is still [caching](https://blog.wheels.dev/posts/caching-in-wheels-4) or a maintained counter column; calculated properties are for the (large) middle ground where correctness-by-construction beats micro-optimization.

## The adoption recipe

For an existing app, the order of operations that pays fastest:

1. Grep views and controllers for repeated inline SQL-ish derivations (concatenations, `COUNT` loops) — promote each to a `property()` on its model.
2. Any of them with a subquery or a function call: declare `select=false` immediately.
3. Add `includeCalculated=` at the call sites that render them — the dev-mode throw will find any you miss the moment you load the page.
4. Watch your query log shrink on the pages that never needed the math.

The full model-layer story around this — finders, `select=`, and the query semantics — lives in [Models and the ORM](https://guides.wheels.dev/v4-0-0/basics/models-and-the-orm/) in the guides.

