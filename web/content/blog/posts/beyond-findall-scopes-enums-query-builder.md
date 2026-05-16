---
title: 'Beyond findAll: Scopes, Enums, and the Chainable Query Builder'
slug: beyond-findall-scopes-enums-query-builder
publishedAt: '2026-06-05T14:00:00.000Z'
updatedAt: '2026-06-05T14:00:00.000Z'
author: Peter Amiri
tags:
  - wheels-4
  - models
  - query-builder
  - scopes
  - enums
categories: []
excerpt: >-
  Wheels 4.0 ships three model-side features that compose into one design:
  scopes name reusable query fragments, enums turn property values into
  auto-generated checkers and scopes, and the chainable query builder swaps
  raw WHERE strings for fluent, type-aware composition. This post walks all
  three through one worked example and surfaces the bug I hit while writing it.
coverImage: null
---

The first thing you learn about Wheels' ORM is `findAll(where="status = 'published'")`. The first thing you stop learning, six months later, is *anything else*. Raw WHERE strings work for the four-line query you wrote on Monday. By Thursday you're concatenating user input into them, by next month you're copy-pasting the same `status = 'published' AND publishedAt <= NOW()` fragment into eight different controllers, and by the time you go to add a filter for "published OR scheduled-but-the-author-is-an-admin" you've forgotten which file the last similar query lives in.

Wheels 4.0 ships three features on the model side that, taken together, are the answer to that drift. *Scopes* name reusable query fragments and compose by chaining. *Enums* take a property whose values are a closed set ("draft, published, archived") and auto-generate the checkers, validators, and scopes for it. The *chainable query builder* replaces raw WHERE strings with `where("column", "value")` calls that auto-quote and type-check on the way to the SQL.

They're three features, but they're one design — every one of them returns the same kind of deferred-query object, and they all flow into the same materialise-on-terminal-method path. You can chain a scope onto an enum onto a builder onto a `.get()` without thinking about which is which. This post walks all three through one worked model and shows where they touch.

## A reusable query fragment is a scope

Let's start with a `Post` model that has the kind of query state most blogs end up with: a status (draft / published / archived), an author, a publish date, view count.

```cfm title="app/models/Post.cfc"
component extends="Model" {
    function config() {
        belongsTo("author");
        scope(name="published", where="status = 'published'", order="publishedAt DESC");
        scope(name="recent", order="publishedAt DESC", maxRows=10);
    }
}
```

The two `scope()` calls register named query fragments. Each is a struct of finder arguments — `where`, `order`, `select`, `include`, `maxRows` — that you'd otherwise hand to `findAll()` directly. From your controller:

```cfm
posts = model("Post").published().findAll();
```

`published()` isn't a real method on `Post.cfc`. The model's `onMissingMethod()` hook recognises it as a scope name, looks up the registered struct, and returns a `ScopeChain` proxy carrying that scope's specs. The proxy has its own `onMissingMethod()` for the next link in the chain. Nothing executes yet — `published()` returned a chainable, not a query.

`.findAll()` is the terminal call. The proxy materialises its accumulated specs into a single finder-argument struct and hands it to the real `findAll()`. The same finder Wheels has had since 1.0; the same SQL it would generate from `findAll(where="status = 'published'", order="publishedAt DESC")`. Scopes are a layer over the finder, not a replacement for it.

The interesting property is composition. Stack two scopes and they merge:

```cfm
posts = model("Post").published().recent().findAll();
```

`recent` only declared `order` and `maxRows`. `published` only declared `where` and `order`. The chain merges WHERE clauses with `AND`, takes the *last* `order` declared (so `recent` wins — its `order` is also `publishedAt DESC` here, but the rule is "later overrides"), and takes the most restrictive `maxRows`. There's no separate "scope merger" object — `ScopeChain.$mergeSpecs()` walks the accumulated specs in order and rolls them up before handing to the finder. You can read the implementation in a few minutes; there's no magic.

### Dynamic scopes take parameters

Static scopes — fixed WHERE strings — are fine for `published` and `recent`. When the filter is parameterised, use the handler form:

```cfm title="app/models/Post.cfc"
function config() {
    belongsTo("author");
    scope(name="published", where="status = 'published'", order="publishedAt DESC");
    scope(name="byAuthor", handler="scopeByAuthor");
}

private struct function scopeByAuthor(required numeric authorId) {
    return {
        where: "authorId = ?",
        whereParams: [{value: arguments.authorId, type: "CF_SQL_INTEGER"}]
    };
}
```

`byAuthor(42)` invokes the handler with the argument, the handler returns a spec struct, and the chain absorbs it the same way it absorbs a static scope. The `whereParams` array is the safe path for user input: the ScopeChain resolves the `?` placeholder with a quoted, type-checked value rather than string-interpolating it. The codebase also runs a sanitisation pass on handler arguments — strips null bytes, SQL comments, `UNION`/`EXEC`/`SLEEP` keywords — but that's defence in depth, not a substitute for proper parameterisation. If your handler still does `where: "role = '#arguments.role#'"`, you're a `'; DROP TABLE` away from a bad day even with the sanitiser in front. Use `whereParams`.

The defaults are reasonable: `whereParams` is treated as positional, and the type strings are the standard `CF_SQL_*` constants. Inside the handler, you can run any logic you want — branch on the argument, look up another model — as long as you return a struct with the finder-argument shape.

## An enum is a property-shaped scope generator

A `status` field with three valid values — draft, published, archived — has the same shape as a thousand other Wheels models. The pattern in plain Wheels is:

```cfm
function config() {
    validatesInclusionOf(properties="status", list="draft,published,archived");
    scope(name="draft", where="status = 'draft'");
    scope(name="published", where="status = 'published'");
    scope(name="archived", where="status = 'archived'");
}
```

Four lines of bookkeeping per enum-shaped property, repeated wherever you have one. Wheels 4.0 collapses it to:

```cfm
function config() {
    enum(property="status", values="draft,published,archived");
}
```

That single call registers:

- A `validatesInclusionOf` check on the property, so `status = "wat"` fails validation cleanly.
- One scope per value (`draft()`, `published()`, `archived()`) so `model("Post").published().findAll()` works without a separate `scope()` call.
- One boolean checker per value on the instance: `post.isDraft()`, `post.isPublished()`, `post.isArchived()`.

The scopes are parameterised — `where: "status = ?"` with `whereParams = [{value: "published", type: "CF_SQL_VARCHAR"}]` — not string-interpolated. Auto-generated code is the place the framework can afford to do the safe thing without you remembering.

Two value forms work:

```cfm
// Names map to themselves — stored value matches the name.
enum(property="status", values="draft,published,archived");

// Names map to explicit stored values — useful when the DB column is
// an integer or you need the names to differ from what's persisted.
enum(property="priority", values={low: 0, medium: 1, high: 2});
```

The struct form coerces every stored value to a string before the underlying scope is built (so `0` becomes `"0"`). That's usually fine, but if you have a numeric column and a literal `0` is meaningful, double-check the comparison in your SQL log.

A few sharp edges worth knowing:

- **Value-name collisions.** An enum value named `name` or `update` will register a scope called `name()` or `update()` on the model. There's no guard against collisions with method names you've defined. If you write `enum(property="action", values="create,update,delete")`, you've shadowed `update()` and `delete()` on every query chain rooted at the model. Pick value names that don't double as verbs the framework uses.
- **Invalid characters in stored values.** The framework rejects single quotes, semicolons, comment markers, and other SQL-injection-shaped characters in enum stored values at registration time, throwing `Wheels.InvalidEnumValue`. The values you provide are baked into auto-generated scope SQL, so this is a registration-time check, not a runtime one. It only fires if you write something like `values={oops: "it's fine"}`.
- **Validation fires on save, not on assignment.** `post.status = "wat"` doesn't throw — it sets the property. `post.valid()` is what surfaces the inclusion failure (`errorsOn("status")` returns a validation error). If you want to fail on assignment, you'd add your own setter; the enum machinery doesn't intercept the write.

## The chainable query builder

Scopes handle the named, reusable case. The query builder handles the ad-hoc, runtime-composed case — the place where you used to reach for a raw WHERE string and concatenate variables into it.

```cfm
posts = model("Post")
    .where("authorId", session.authorId)
    .where("views", ">", 100)
    .whereNotNull("publishedAt")
    .orderBy("publishedAt", "DESC")
    .limit(25)
    .get();
```

Three calling conventions for `where`:

- **`.where("clause")`** — passes the string through verbatim. You're back to manual quoting territory; don't put user input here.
- **`.where("column", value)`** — equality, auto-quoted: `column = '<quoted>'`.
- **`.where("column", operator, value)`** — operator in the middle: `column > <quoted>`, `column LIKE <quoted>`, and so on.

Auto-quoting goes through the database adapter's `$quoteValue()` and is preceded by a *type check* against the property's declared type. If the column is declared `integer` and the value isn't a valid integer literal, the builder throws before any SQL is built. That closes the classic injection vector where `"0 OR 1=1"` slipped through the unquoted numeric path. The same goes for `float`, `boolean`, and `date` — payloads get rejected at the type check, not at the SQL parser.

The full method surface, in addition to `where`:

| Method | SQL |
|---|---|
| `orWhere(...)` | Same conventions as `where`, OR-combined |
| `whereNull(column)` | `column IS NULL` |
| `whereNotNull(column)` | `column IS NOT NULL` |
| `whereBetween(column, low, high)` | `column BETWEEN low AND high` |
| `whereIn(column, list)` | `column IN (...)` |
| `whereNotIn(column, list)` | `column NOT IN (...)` |
| `orderBy(column, direction)` | `ORDER BY column direction` |
| `limit(n)`, `offset(n)` | `LIMIT n` / `OFFSET n` |
| `select(columns)` | column projection |
| `include(associations)` | eager-load associations |
| `group(columns)`, `distinct()` | `GROUP BY` / `SELECT DISTINCT` |
| `forUpdate()` | pessimistic row lock (DB-dependent) |

Terminal methods materialise the chain:

- **`.get()` / `.findAll()`** — returns a query of all matching rows.
- **`.first()` / `.findOne()`** — returns the first row as a model instance, or null.
- **`.count()`** — returns the integer count.
- **`.exists()`** — returns true/false.
- **`.updateAll(...)`** — bulk update, returns rows affected.
- **`.deleteAll()`** — bulk delete, returns rows deleted.
- **`.findEach(callback)`** / **`.findInBatches(callback)`** — stream rows for large result sets without holding them all in memory.

Like scopes, nothing happens until a terminal method fires. You can build a query object, branch on it, layer more conditions, and only `.get()` it once at the end:

```cfm
query = model("Post").where("status", "published");

if (params.authorId != "") {
    query = query.where("authorId", params.authorId);
}
if (params.sort == "popular") {
    query = query.orderBy("views", "DESC");
} else {
    query = query.orderBy("publishedAt", "DESC");
}

posts = query.limit(25).get();
```

That kind of conditional composition is what raw WHERE strings make ugly. The builder makes it the natural shape.

## Composing all three

The three features compose with no special integration code — they all return objects that implement `onMissingMethod()` and accumulate state into the same finder-argument struct on the way to the terminal call. Here's a query that uses all three:

```cfm
// Post.cfc
function config() {
    belongsTo("author");
    enum(property="status", values="draft,published,archived");
    scope(name="recent", order="publishedAt DESC", maxRows=10);
    scope(name="byAuthor", handler="scopeByAuthor");
}

private struct function scopeByAuthor(required numeric authorId) {
    return {
        where: "authorId = ?",
        whereParams: [{value: arguments.authorId, type: "CF_SQL_INTEGER"}]
    };
}
```

```cfm
// PostsController.cfc
posts = model("Post")
    .published()                              // enum-generated scope
    .byAuthor(session.authorId)               // dynamic scope
    .where("views", ">", 100)                 // builder where
    .whereNotNull("featuredImage")            // builder whereNotNull
    .orderBy("publishedAt", "DESC")           // builder orderBy
    .limit(20)
    .get();
```

The chain reads top-to-bottom in the order you'd describe the query out loud: "published posts by this author with more than 100 views and a featured image, newest first, top 20." The SQL Wheels generates looks roughly like:

```sql
SELECT * FROM posts
WHERE (status = 'published')
  AND (authorId = 42)
  AND (views > 100)
  AND (featuredImage IS NOT NULL)
ORDER BY publishedAt DESC
LIMIT 20
```

Each clause comes from a different layer, but the layers don't know about each other. The scope returns a spec; the dynamic scope returns a spec with whereParams; the builder appends WHERE conditions to an array. `$buildFinderArgs()` walks both lists in order, merges the WHERE strings with `AND`, takes the latest `orderBy`, and hands the result struct to `findAll()`. It's the same finder you'd call directly — the chainable surface is sugar around the existing implementation, not a parallel one.

## What changed while writing this post

While testing edge cases for the builder section, I tried `model("Post").whereIn("id", [])` to see what the framework did with an empty array. The answer was: nothing good. It produced literal SQL `id IN ()`, which is malformed in every database Wheels supports — Postgres, MySQL, SQL Server, SQLite, H2 — and surfaces as a generic syntax error from the JDBC driver. No framework-shaped error, no pointer to the line in your code that built the empty array.

Empty inputs to `WHERE IN` aren't an exotic edge case. They're what you get whenever the values come from another query, a form filter, or any computation that might return zero results. The Rails community converged on this pattern in 2016, Sequel matches it, Django matches it, Laravel Eloquent matches it: an empty `IN` matches no rows, and an empty `NOT IN` matches every row. It's what the SQL spec implies and what every other framework's users expect.

Wheels now does the same. `whereIn("id", [])` sets an `$alwaysEmpty` flag on the builder; every terminal — `.count()`, `.first()`, `.findAll()`, `.exists()`, `.updateAll()`, `.deleteAll()`, `.findEach()`, `.findInBatches()` — short-circuits before going through the finder, returning the appropriate zero-row sentinel (`0`, `false`, an empty query). `whereNotIn("id", [])` is a no-op: it appends no clause, so the chain proceeds normally and every other row matches. The chains compose cleanly — `.where("status", "active").whereIn("id", []).count()` still returns `0` because the terminal sees the flag first; `.where("status", "active").whereNotIn("id", []).count()` returns the count of active rows because `whereNotIn` of nothing excludes nothing. Six new specs in `queryBuilderSpec.cfc` lock the behaviour in (empty array, empty list, composition with `where`, and the `whereNotIn` mirrors). The reference table in the query-builder guide notes the short-circuit so you don't have to read the source to confirm it.

The first cut of this fix tried the more obvious approach: append `1 = 0` and `1 = 1` as raw SQL clauses, the way Rails docs describe it. That broke immediately. Wheels' WHERE-clause parser in `vendor/wheels/model/sql.cfc` runs a property-extraction regex over every clause it sees — even ones like `1 = 0` that don't have a property — and threw `Wheels.ColumnNotFound` on the literal `1`. The fix that shipped is the one that works alongside the parser instead of around it: short-circuit at the terminal so the parser never sees a column-less clause. Either approach is correct on the SQL side; only one composes with the rest of the framework.

This is the same shape as the rate-limiter `windowSeconds=0` fix from the first post in this series, and the OpenCode template drift from the third: the article ships alongside the framework change because finding the rough edge is most of the work, and the cost of fixing it once you've found it is almost nothing.

There are a few related rough edges I didn't fix in this PR but that are worth naming so the next person who hits them knows they exist:

- **No `.toSql()` method.** If you want to see the SQL the chain is about to generate, you have to enable the debug panel or step through `$buildFinderArgs()` yourself. A `.toSql()` that returns the would-be query string without executing it would be useful for debugging complex chains. Filed for follow-up.
- **No `defaultScope()` / `unscoped()`.** Rails lets you declare a model-wide default scope (e.g. "always filter out soft-deleted rows") with an escape hatch (`unscoped`). Wheels doesn't have either. Soft-delete is the obvious motivating case; if your model has a `deletedAt` and you want every query to filter on `WHERE deletedAt IS NULL`, you currently scatter `.whereNull("deletedAt")` through every call site or write a wrapper. Not a bug — just a missing affordance.
- **Enum value-name collisions are unchecked.** `enum(property="action", values="create,update,delete")` will silently shadow the model's own `update()` and `delete()` chain methods. The framework could refuse to register an enum value whose name matches an existing method; today it doesn't. Pick value names that aren't verbs.

The next post in the series is the last one: *From Empty Directory to Deployed SaaS — end-to-end with generators, multi-tenancy, jobs, browser tests, and `wheels deploy`*. That one's a longer post. Coming next week.
