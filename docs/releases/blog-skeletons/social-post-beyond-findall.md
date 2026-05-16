# Social Posts — "Beyond findAll: Scopes, Enums, and the Chainable Query Builder"

**Status:** Copy-paste ready. Fourth post in the post-GA series.
**Pairs with:** [docs/releases/blog-drafts/beyond-findall-scopes-enums-query-builder.md](../blog-drafts/beyond-findall-scopes-enums-query-builder.md)
**Post date:** 2026-05-21 (same day as the article)
**Tone:** Post-GA, present tense, "three features, one design" angle.

**Canonical URL** (use everywhere):
- `https://blog.wheels.dev/posts/beyond-findall-scopes-enums-query-builder`

---

## Slack (#wheels-dev)

```
New on the blog: Beyond findAll — Scopes, Enums, and the Chainable Query Builder.

<https://blog.wheels.dev/posts/beyond-findall-scopes-enums-query-builder|Full post>

What it covers:
• Scopes — named, reusable query fragments. Static (literal where/order) and dynamic (handler returns a spec struct with whereParams).
• Enums — one `enum(property="status", values="draft,published,archived")` registers a validation, three boolean checkers (isDraft, isPublished, isArchived), and three scopes (.draft(), .published(), .archived()). All parameterised.
• The chainable query builder — .where("col", value), .whereIn, .whereBetween, .orderBy, .limit, .get(). Auto-quoting + type validation on the way to SQL, so integer/float/boolean payloads can't sneak past the binding layer.
• Three features, one design — they all return deferred-query proxies that materialise into the same finder-argument struct on a terminal call. The chain reads top-to-bottom in the order you'd describe the query out loud.

Side effect of writing the post: framework fix (#2736) — whereIn / whereNotIn with empty arrays no longer emit malformed `IN ()` SQL. whereIn(empty) now sets a flag the terminals honour (count → 0, exists → false, findAll → empty query, etc.); whereNotIn(empty) is a no-op (exclude-none = match-all). Same user-facing behaviour as Rails / Sequel / Django / Eloquent. Fourteen regression specs locked in.
```

---

## LinkedIn

```
New on the Wheels blog: Beyond findAll — Scopes, Enums, and the Chainable Query Builder.

The first thing you learn about Wheels' ORM is findAll(where="..."). The first thing you stop learning, six months later, is anything else. Raw WHERE strings work for the four-line query you wrote on Monday. By Thursday you're concatenating user input into them; by next month you're copy-pasting the same fragment into eight controllers. Wheels 4.0 ships three features on the model side that, taken together, are the answer to that drift.

— Scopes name reusable query fragments and compose by chaining. Static scopes are literal WHERE strings; dynamic scopes take parameters via a handler that returns a spec struct, with whereParams for safe parameterisation.

— Enums collapse the "property whose values are a closed set" pattern into a single declaration. enum(property="status", values="draft,published,archived") auto-registers a validatesInclusionOf check, three boolean checkers (isDraft, isPublished, isArchived) on every instance, and three scopes (.draft(), .published(), .archived()) on the model class — all with parameterised WHERE clauses, not string-interpolated ones.

— The chainable query builder replaces raw WHERE strings with where("col", value), whereIn, whereBetween, orderBy, limit. Values are auto-quoted through the database adapter, and the column's declared type validates the value's shape before any SQL is built — so the classic injection vector where "0 OR 1=1" slips through the unquoted numeric path is closed at the type check.

Three features, but one design. They all return deferred-query objects that flow into the same finder-argument struct on a terminal call (.get / .findAll / .first / .count). You can chain a scope onto an enum onto a builder onto a .get() without thinking about which is which.

A side note in the post: writing it surfaced a real framework bug. whereIn / whereNotIn with empty arrays produced literal SQL "property IN ()" — malformed in every supported engine, surfacing as a generic JDBC error with no pointer back to the call site that built the empty collection. Fixed in the same week the article landed. whereIn(empty) now sets a flag the terminal methods honour (count returns 0, exists returns false, findAll returns an empty query, and so on); whereNotIn(empty) is a no-op so the chain proceeds normally. The user-facing behaviour matches what Rails, Sequel, Django, and Laravel Eloquent all converged on. Fourteen regression specs lock the behaviour in.

Read: https://blog.wheels.dev/posts/beyond-findall-scopes-enums-query-builder

#CFML #Wheels #ORM #ActiveRecord #QueryBuilder #DeveloperExperience
```

---

## X / Twitter

**Hero tweet (unnumbered):**
```
New on the Wheels blog — Beyond findAll: Scopes, Enums, and the Chainable Query Builder.

Three features on the model side that compose into one design. Scopes name fragments. Enums generate checkers + scopes from a value list. The builder swaps raw WHERE strings for type-checked composition.

https://blog.wheels.dev/posts/beyond-findall-scopes-enums-query-builder
```

**Reply 1:** (outer fence is `~~~~` so the inner ```` ```cfm ```` block renders correctly in the Markdown preview)

~~~~
1/ One enum() call =

```cfm
enum(property="status", values="draft,published,archived");
```

→ validatesInclusionOf on the property
→ post.isDraft() / isPublished() / isArchived() on every instance
→ Post.draft() / .published() / .archived() scopes on the class

All parameterised, not string-interpolated.
~~~~

**Reply 2:** (outer fence is `~~~~` so the inner ```` ```cfm ```` block renders correctly)

~~~~
2/ The chain reads top-to-bottom:

```cfm
model("Post")
    .published()                     // enum scope
    .byAuthor(session.authorId)      // dynamic scope
    .where("views", ">", 100)        // builder
    .whereNotNull("featuredImage")
    .orderBy("publishedAt", "DESC")
    .limit(20)
    .get();
```

Three different layers, one materialised query.
~~~~

**Reply 3:**
```
3/ Type validation in the builder closes the classic injection vector:

.where("age", ">", "0 OR 1=1") fails at the type check (column is `integer`, value isn't a valid integer literal) before any SQL is built.

Auto-quoting alone doesn't fix that — type validation does.
```

**Reply 4:**
```
4/ Side effect of writing the post: framework fix (#2736).

whereIn("id", []) used to emit literal "id IN ()" — malformed SQL. Now sets a flag the terminals honour, returning the zero-row sentinel before reaching the finder. Same user-facing behaviour as Rails / Sequel / Django / Laravel Eloquent.

Fourteen regression specs. Behaviour documented in the guide.
```

---

## GitHub Discussions

**Title:** `Post-GA blog: Beyond findAll — Scopes, Enums, and the Chainable Query Builder`

```markdown
Fourth in the post-GA series. The rate-limiter post took the middleware pipeline, the packages post took the extension model, the MCP post took the AI surface, and this one takes the model-side query story. Specifically: what to reach for instead of `findAll(where="...")` once the raw WHERE strings stop scaling.

**Read:** https://blog.wheels.dev/posts/beyond-findall-scopes-enums-query-builder

The post walks three features that look separate but compose into one design:

- **Scopes** — `scope(name="published", where="status = 'published'", order="publishedAt DESC")` registers a named query fragment. `model("Post").published().findAll()` returns a `ScopeChain` proxy, which `onMissingMethod()` hands the registered spec struct. Chain multiple scopes and `$mergeSpecs()` rolls them up before the terminal call. Dynamic scopes take parameters via a handler that returns a spec struct with `whereParams` — the safe path for user input, not string interpolation.
- **Enums** — `enum(property="status", values="draft,published,archived")` is one declaration that registers a `validatesInclusionOf`, three boolean checkers (`isDraft`, `isPublished`, `isArchived`) on every instance via `onMissingMethod()`, and three scopes (`.draft()`, `.published()`, `.archived()`) on the model class. The auto-generated scopes are *parameterised* — `where: "status = ?"` plus `whereParams = [{value: "published", type: "CF_SQL_VARCHAR"}]` — not string-interpolated. Two value forms: comma-list (names map to themselves) and struct (names map to explicit stored values).
- **The chainable query builder** — `where("col", value)` is auto-quoted *and* type-checked. Each property has a declared validation type (`integer`, `float`, `boolean`, `date`, `string`); values get regex-validated against that type before any SQL is built, so the classic `"0 OR 1=1"` payload fails the type check before the binding layer ever sees it. Full method surface: `where`, `orWhere`, `whereNull`, `whereNotNull`, `whereBetween`, `whereIn`, `whereNotIn`, `orderBy`, `limit`, `offset`, `select`, `include`, `group`, `distinct`, `forUpdate`. Terminals: `.get()`, `.first()`, `.count()`, `.exists()`, `.updateAll()`, `.deleteAll()`, `.findEach()`, `.findInBatches()`.
- **They compose because they share machinery** — all three return objects that implement `onMissingMethod()` and accumulate state into the same finder-argument struct. `$buildFinderArgs()` materialises the chain on a terminal call and hands the result to the existing `findAll()`. The chainable surface is sugar around the existing finder, not a parallel implementation.

## Side note: a framework bug surfaced while writing this

Drafting the post, I tried `model("Post").whereIn("id", [])` to see what the framework did with an empty array. The answer: it emitted literal SQL `id IN ()`, which is malformed in every supported engine — Postgres, MySQL, SQL Server, SQLite, H2 — and surfaced as a generic JDBC syntax error with no pointer back to the call site that built the empty array.

Empty inputs to `WHERE IN` aren't exotic. They're what you get whenever the values come from another query, a form filter, or any computation that might return zero results. Rails converged on this pattern in 2016, Sequel matches it, Django matches it, Laravel Eloquent matches it: an empty `IN` matches no rows, and an empty `NOT IN` matches every row.

That's [#2736](https://github.com/wheels-dev/wheels/pull/2736), fixed in the same week the article landed. `whereIn("id", [])` sets an `$alwaysEmpty` flag on the builder so every terminal (`.count()`, `.findAll()`, `.first()`, `.exists()`, `.updateAll()`, `.deleteAll()`, `.findEach()`, `.findInBatches()`) short-circuits to the appropriate zero-row sentinel before going through the finder. `whereNotIn("id", [])` is a no-op so the chain proceeds normally. The first cut tried the obvious raw-SQL approach (append `1 = 0` / `1 = 1` as clauses) but Wheels' WHERE-clause parser runs a property-extraction regex over every clause it sees and threw `Wheels.ColumnNotFound` on the literal `1`. The flag-based design works alongside the parser instead of around it. Fourteen new specs lock the behaviour in. The reference table in both copies of the query-builder guide was updated so a reader skimming the methods doesn't have to read the source to know what happens on empty input.

Three related rough edges are flagged in the post but not fixed in this PR:

- **No `.toSql()` debugging helper.** If you want to see the SQL the chain is about to generate, you have to enable the debug panel or step through `$buildFinderArgs()`. A `.toSql()` method that returns the would-be query string without executing it would be a useful affordance. Filed for follow-up.
- **No `defaultScope()` / `unscoped()`.** Rails has both; Wheels has neither. Soft-delete is the obvious motivating case — without a default scope, you scatter `.whereNull("deletedAt")` through every call site.
- **Enum value-name collisions are unchecked.** `enum(property="action", values="create,update,delete")` will silently shadow the model's own `update()` and `delete()` chain methods. A registration-time guard could reject this; today there isn't one.

## What's next in the post-GA series

The last title in the second batch:

1. *From Empty Directory to Deployed SaaS* — end-to-end with generators, multi-tenancy, jobs, browser tests, `wheels deploy`

Feedback on the query-side post — what's confusing, what's missing, what you'd want a future post to cover — welcome in this thread. The author-facing reference guide lives at https://guides.wheels.dev/v4-0-1-snapshot/basics/query-builder-and-scopes/ if you want the full field-by-field treatment.
```

---

## Posting checklist

- [ ] Article live at `https://blog.wheels.dev/posts/beyond-findall-scopes-enums-query-builder`
- [ ] PR #2736 merged (article + whereIn/whereNotIn empty-array fix + tests + guide doc fix + CHANGELOG entry)
- [ ] Slack post in `#wheels-dev`
- [ ] LinkedIn post from the Wheels org account
- [ ] X / Twitter hero + 4-reply thread from `@wheels_dev`
- [ ] GitHub Discussions thread under "Show and tell" or equivalent category
- [ ] Verify all four channels link to the same canonical URL
