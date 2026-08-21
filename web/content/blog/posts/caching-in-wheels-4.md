---
title: 'Caching in Wheels 4.0: Actions, Queries, Partials, and Invalidation'
slug: caching-in-wheels-4
publishedAt: '2026-07-06T14:00:00.000Z'
updatedAt: '2026-06-19T15:10:00.000Z'
author: Peter Amiri
tags:
  - wheels-4
  - caching
  - performance
categories: []
excerpt: >-
  A practical, source-grounded tour of every cache Wheels 4.0 actually ships —
  action caching, query caching, partial and page caching — plus the honest
  truth about invalidation: there's no clearCache(key), so you live on short
  expiry times and full reloads.
coverImage: null
---

Your blog's home page runs eight queries. One of them — the "most popular posts this month" sidebar — is a `GROUP BY` over the entire `views` table that takes 400ms on a good day. It hasn't changed in three weeks. Every single visitor pays for it again.

That's the caching problem in one sentence: the same expensive work, recomputed for requests that would have happily taken a stale answer. Wheels 4.0 has four different tools for it, and the first thing you need to know is that they're four *different* tools, not one cache with four front doors. Action caching, query caching, partial caching, and page caching each store different things, in different places, keyed differently, and — this is the part that bites everyone — invalidated differently.

This post walks all four through one worked blog model, shows exactly which setting turns each on, and then tells you the uncomfortable truth about invalidation that the Rails-shaped part of your brain is going to resist.

## The one thing that breaks everyone first: caching is off in development

Before you write a single `cache=` argument, internalize this, because it's the number-one reason people think Wheels caching is broken:

> `cacheActions`, `cachePages`, `cachePartials`, `cacheQueries`, and `cacheImages` **all default to `false` in development** and `true` in every other environment.

So `caches(...)`, `includePartial(cache=...)`, `renderView(cache=...)`, and `findAll(cache=...)` silently do *nothing* on your laptop. No error, no warning — they just render fresh every time, and then you ship to production and the behavior changes. If you want to test caching locally, you flip it on explicitly in `config/settings.cfm`:

```cfm
// config/settings.cfm — only inside the development environment block
set(cacheActions=true);
set(cacheQueries=true);
set(cachePartials=true);
set(cachePages=true);
```

There's exactly one exception. `cacheQueriesDuringRequest` defaults to `true` *even in development*, because it's request-scoped — it dedupes identical queries within a single request and dies when the request ends. More on that one later; it's the cache you didn't ask for and probably want.

## Action caching: cache the whole controller response

Action caching stores the rendered output of a controller action so the next request for the same action skips the work entirely. You register it in the controller's `config()` with `caches()`:

```cfm
// app/controllers/Articles.cfc
component extends="Controller" {
    function config() {
        // Cache the rendered response of index + show for 30 minutes.
        caches(actions="index,show", time=30);
    }

    function index() {
        articles = model("Article").findAll(order="publishedAt DESC");
    }

    function show() {
        article = model("Article").findByKey(params.key);
    }
}
```

`caches()` is a config-time registration, not a runtime call — it lives in `config()` alongside your filters and verifies. A few rules from the signature:

- `action` (alias: `actions`) is a **comma-list**. Omit it entirely and *every* action on the controller is cached (it's stored internally as `"*"`).
- `time` is in **minutes** and defaults to `60`.
- It only does anything when `cacheActions=true` — so, not in development unless you flipped it on above.

By default this caches the action's *response string* into the application-scope `"action"` category. The controller still instantiates, filters still run — the framework just skips re-rendering and hands back the stored string.

One gate applies to *all* action caching, static or not: the action is only cached when the flash is empty and no form was posted (internally, `flashIsEmpty()` and `StructIsEmpty(form)`). So you never cache a "your comment was saved" banner — a freshly-posted or flash-bearing request renders live and skips the cache.

### Static caching skips the controller entirely

Pass `static=true` and the behavior changes meaningfully. Now the *whole rendered page* is stored via `cfcache` (the engine's server cache), and on a cache hit the request is **aborted before any controller filters run**. Only `onSessionStart` and `onRequestStart` still fire:

```cfm
function config() {
    // The whole page, via cfcache. On a hit, before/after filters are skipped.
    caches(action="sitemap", time=60, static=true);
}
```

This is the fastest option and the most dangerous one. Because static caching aborts before your filters, **do not use it for anything that depends on per-request auth or filter logic** — your "is this user logged in?" check never runs on a cache hit. It's perfect for a sitemap, an about page, or a public marketing route. It's a security hole on a dashboard.

One more static-caching fact worth knowing: on engines without `cfcache` it silently degrades to a no-op (covered in Sharp edges).

### Varying the cache key with appendToKey

A cached action returns the same bytes to everyone — which is wrong the moment the page depends on *who's looking*. `appendToKey` lets you fold runtime values into the cache key so each distinct value gets its own entry:

```cfm
function config() {
    // Each user gets their own cached dashboard for 10 minutes.
    caches(action="dashboard", time=10, appendToKey="session.userId");
}
```

`appendToKey` is a comma-list of `scope.var` references evaluated at request time and concatenated onto the key. It reads from `request`, `arguments`, `application`, `session`, and `variables` — and you **must** prefix with the scope name. A bare `userId` won't resolve. It only throws `Wheels.KeyNotFound` if you reference a scope Wheels doesn't support (anything other than `request`/`arguments`/`application`/`session`/`variables` — e.g. `url.`, `form.`, `cgi.`). A *missing* var in a supported scope — e.g. `session.userId` for a logged-out user — does **not** throw; it's silently skipped, which is arguably worse: every such request then shares one cache entry. Guard the value yourself before relying on it to vary the key.

There's also a cardinality cost: every distinct `appendToKey` value is a distinct cache entry, and the shared cache is bounded (Sharp edges, again). Vary by `session.userId` on a high-traffic page and you can blow the cache budget fast.

### Page caching from the controller

If you'd rather cache from inside the action than register it in `config()`, `renderView(cache=...)` caches the full page-plus-layout under the same `"action"` category — gated on `cachePages=true`:

```cfm
function show() {
    article = model("Article").findByKey(params.key);
    // cache = minutes; true => defaultCacheTime (60).
    renderView(cache=60);
}
```

Both `renderView` and the partial helper below use a **double-checked lock** internally, so when ten requests hit a cold cache at once, only one of them actually renders — the other nine wait and take the result. That's the difference between a cache miss and a thundering herd.

## Query caching: two completely different caches, don't confuse them

Query caching is where most of the confusion lives, because there are *two* unrelated query caches and they behave nothing alike.

### Cross-request: findAll(cache=N)

Pass `cache` (in **minutes**) to any finder and Wheels caches the SQL result across requests — but not in its own struct. It hands a native `cachedWithin` timespan to the database adapter, which means **real engine-level `cfquery`/`queryExecute` caching**:

```cfm
// Cross-request: cache this result set for 15 minutes at the engine level.
featured = model("Article").findAll(
    where = "featured = 1",
    order = "publishedAt DESC",
    cache = 15            // minutes; cache=true would use defaultCacheTime (60)
);
```

This is honored only when `cacheQueries=true`. The arg name is literally `cache`, the unit is minutes (governed by `cacheDatePart`, default `"n"`), and `cache=true` means `defaultCacheTime` — 60 minutes. Because it's the engine's cache keyed on the generated SQL, it is **not** in `application.wheels.cache`, so nothing you do to that struct touches it. It expires on its own time, or on an app reload.

### Request-level: the dedupe you already have

The second query cache is on by default and you've been using it without knowing. `cacheQueriesDuringRequest` (default `true`, even in dev) stores each unique `findAll` result in `request.wheels.$queryCache[ModelName]`, so an identical query within a single request runs exactly one SQL statement:

```cfm
// These two run only ONE SQL query within the same request —
// the second is served from request.wheels.$queryCache["Author"].
model("Author").findAll(where="lastName='Djurner'");
model("Author").findAll(where="lastName='Djurner'");

// Force a fresh DB hit, bypassing the request-level cache:
model("Author").findAll(where="lastName='Djurner'", reload=true);
```

Here's the table that untangles the two, because the difference is the whole point:

| | Request-level | Cross-request |
|---|---|---|
| Setting | `cacheQueriesDuringRequest` | `cacheQueries` |
| Default | `true` (even in dev) | `true` (off in dev) |
| Scope | one request | across requests |
| Where it lives | `request.wheels[ModelName]` | engine `cachedWithin` |
| Turned on by | always on | `findAll(cache=N)` |
| Bypass with | `reload=true` | n/a |
| Cleared by | end of request (automatic) | app reload / expiry |

The trap: `reload=true` defeats the **request-level** cache. It has nothing to do with `cache=N`, which is the cross-request engine cache. People reach for `reload=true` expecting it to bust their 15-minute `findAll(cache=15)` and it doesn't — different cache, different lifetime.

## Partial caching: cache an expensive fragment

Back to the popular-posts sidebar from the intro. It's a partial, it's expensive, it changes rarely — textbook partial caching. From a view, `includePartial(cache=...)` caches the rendered HTML:

```cfm
<!--- app/views/articles/index.cfm --->
<cfparam name="articles" default="">

<!--- Cache an expensive sidebar partial for 20 minutes --->
#includePartial(partial="/shared/popularSidebar", cache=20)#

<!--- Per-record partials cache the whole rendered block — pass an array of
     objects (fetch the query with returnAs="objects" in the controller) --->
#includePartial(partial="article", objects=articles, cache=10)#
```

The arg name is `cache`, the value is minutes (or `true` for `defaultCacheTime`), and it only takes effect when `cachePartials=true` — off in development. The rendered HTML lands in the application-scope `"partial"` category, keyed by a hash of all the call arguments.

You can also cache a partial from the controller side with `renderPartial(cache=...)`, which delegates to the same machinery (and the same double-checked lock as `renderView`):

```cfm
function show() {
    article = model("Article").findByKey(params.key);
    renderPartial(partial="articleBody", cache=30);
}
```

Note the keying detail: the partial cache key is a hash of *all* the call arguments (plus the host). If you pass a partial a `data=` struct that varies per request, every variation is a separate cache entry — same high-cardinality concern as `appendToKey`.

## Where the framework cache actually lives

Everything except `findAll(cache=N)` stores into one place: `application.wheels.cache`, partitioned into categories — `sql`, `image`, `main`, `action`, `page`, `partial`, `query` — initialized at app start. Items are stored as `{value, expiresAt}` and lazily evicted on read when they've expired.

Two properties of this store matter for how you design around it:

1. **Non-simple values are deep-copied (`Duplicate`) on both write and read.** Mutating an object you got back from a cached partial or action won't poison the cache — good. But it also means caching a large object graph costs a full duplication on *every hit* — so caching giant structures isn't free. (Simple values like rendered HTML strings are stored and returned directly, no copy.)

2. **It's bounded and lossy.** `maximumItemsToCache` is `5000` across *all categories combined*. When the cache is full, `$addToCache` culls only **expired** items — up to `cacheCullPercentage` (10%) of the total — and at most once every `cacheCullInterval` (5) minutes. If nothing is expired and the cache is full, **the new item is silently dropped.**

That second point is the one that surprises people in production. There is no LRU, no eviction of live entries. A flood of high-cardinality keys (a `appendToKey="session.userId"` on a popular page, or many distinct per-record partials) can fill the budget with unexpired entries and then quietly *refuse to cache anything new* until something expires. The cache doesn't error; it just stops helping.

These internals (`$addToCache`, `$getFromCache`, `$clearCache`, and friends) are all `$`-prefixed. **There is no public API to read or evict the action/partial/page cache by key.** Which brings us to the hard part.

## Invalidation: there is no clearCache(key)

Here's the truth the Rails-shaped part of your brain will resist: **Wheels 4.0 has no targeted public invalidation.** No `clearCache("articles/show/42")`, no `expire(key)`. The only public-ish lever, `clearCachableActions()`, doesn't even do what its name suggests:

```cfm
// In config(): unregister an action's cachability going forward.
// This does NOT evict content already stored in application.wheels.cache —
// it only stops *future* requests from caching that action.
clearCachableActions("show");
```

`clearCachableActions()` removes the *registration* — the metadata that says "this action is cacheable" — not the cached content. With no argument it clears all registrations on the current controller; with a comma-list it removes the named ones (case-insensitive). After you call it, already-cached responses keep getting served until they expire. It is not an eviction tool.

So what *is* invalidation in Wheels 4.0? Two things:

**1. Expiry.** Every cached entry has a `time`, and when it's up, it's gone (lazily, on next read). This is your primary tool. Choosing the right `time` is the design decision — short enough that stale content is tolerable, long enough that the cache earns its keep.

**2. A full app reload.** Hitting `?reload=true&password=...` re-initializes `application.wheels.cache` to empty structs. If `clearTemplateCacheOnReload` is `true`, it also fires `cfcache action=flush` to clear the static-page layer; if `clearQueryCacheOnReload` is `true`, it rotates `application.wheels.cacheKey`, which invalidates the engine-level query cache:

```bash
# Flush ALL caches — action, partial, page, and the engine query cache.
curl "http://localhost:60007/?reload=true&password=YOUR_RELOAD_PASSWORD"
```

That's it. The request-level query cache (`cacheQueriesDuringRequest`) is the easy one — it lives in the request scope and dies automatically when the request ends, and `reload=true` on a specific finder bypasses it for that call.

The practical pattern, then, is: **short cache times for anything that changes, plus a full reload as the nuclear option.** If your "popular posts" sidebar can be 20 minutes stale, cache it for 20 minutes and never think about invalidation. If you *publish* an article and need the home page fresh *now*, your choices are a short enough `time` that the wait is acceptable, or a reload. There's no surgical "evict just the home page" call. Design your `time` values like they're the only invalidation you have, because they nearly are.

## The full settings surface

Every toggle lives in `config/settings.cfm` via `set(...)`. The user-facing ones, with their defaults:

| Setting | Default | What it gates |
|---|---|---|
| `cacheActions` | `false` dev / `true` else | `caches()` action caching |
| `cachePages` | `false` dev / `true` else | `renderView(cache=...)` |
| `cachePartials` | `false` dev / `true` else | `includePartial(cache=...)` / `renderPartial(cache=...)` |
| `cacheQueries` | `false` dev / `true` else | `findAll(cache=N)` cross-request |
| `cacheImages` | `false` dev / `true` else | image caching |
| `cacheQueriesDuringRequest` | `true` (always) | request-level query dedupe |
| `defaultCacheTime` | `60` | minutes used when `cache=true` |
| `maximumItemsToCache` | `5000` | total items across all categories |
| `cacheCullPercentage` | `10` | % of total items culled (expired only) when full |
| `cacheCullInterval` | `5` | minutes between cull passes |
| `cacheDatePart` | `"n"` | cache-time unit (n=minutes) |
| `clearQueryCacheOnReload` | `true` | rotate cacheKey on reload |
| `clearTemplateCacheOnReload` | `true` | flush cfcache on reload |

There are also always-on internal caches Wheels manages for you — `cacheControllerConfig`, `cacheModelConfig`, `cacheDatabaseSchema`, `cachePlugins`, `cacheFileChecking`. You rarely touch these; they're how the framework avoids re-reading its own configuration on every request.

## A worked example: the blog home page

Pull it together. Our blog's home page has the slow popular-posts sidebar, a featured-articles block that changes a few times a day, and a per-user "your drafts" panel. Three different cache shapes, three different decisions.

```cfm
// app/controllers/Home.cfc
component extends="Controller" {
    function config() {
        // The whole index page is cheap to cache and changes slowly.
        // 5 minutes keeps it fresh enough without recomputing per-request.
        caches(action="index", time=5);
    }

    function index() {
        // Featured set changes a few times a day — cache the QUERY for an hour.
        featured = model("Article").findAll(
            where = "featured = 1",
            order = "publishedAt DESC",
            cache = 60
        );

        articles = model("Article").findAll(
            order = "publishedAt DESC",
            page  = params.page,
            perPage = 25
        );
    }
}
```

```cfm
<!--- app/views/home/index.cfm --->
<cfparam name="featured" default="">
<cfparam name="articles" default="">

<div class="articles">
    <cfloop query="articles">
        <h2>#articles.title#</h2>
        <p>#articles.summary#</p>
    </cfloop>
</div>

<!--- The 400ms GROUP BY sidebar — cache the rendered HTML for 20 min --->
#includePartial(partial="/shared/popularSidebar", cache=20)#
```

Note the finder returns a *query object*, so the view loops with `<cfloop query="articles">`, not an array loop. And every variable the controller hands the view gets a `cfparam` at the top.

Now reason about the layering. The `caches(action="index", time=5)` wraps the whole page for 5 minutes. *Inside* that 5-minute window the action's `index()` body never runs at all — so the `cache=60` on `featured` and the `cache=20` on the sidebar are only consulted on the once-every-5-minutes cold render. The inner caches outlive their enclosing action cache; they matter when the page cache misses. That's the mental model: action cache is the outer skin, query and partial caches are what speed up the cold render underneath it.

What about the per-user "your drafts" panel? It can't go in the action cache — that's shared across all users. Either pull it out of the cached action entirely (render it with a separate uncached request, or client-side), or, if it must be server-rendered inline, drop the action cache for this page and lean on `findAll(cache=...)` for the expensive shared parts only. Per-user content and shared action caching don't mix; `appendToKey="session.userId"` would technically work but at the cost of one cached page *per user*, which the 5000-item budget won't love.

## Sharp edges

Everything here is real, cited behavior — the parts that will cost you an afternoon if you don't know them going in.

- **Caching is off in development.** `cacheActions`, `cachePages`, `cachePartials`, `cacheQueries`, `cacheImages` all default to `false` when the environment is `development`. Your `cache=` arguments silently do nothing locally. Flip them on in `config/settings.cfm` to test. `cacheQueriesDuringRequest` is the lone exception — it's request-scoped, so it's on even in dev.

- **Cache times are minutes, not seconds.** Governed by `cacheDatePart`, default `"n"`. `cache=15` is fifteen *minutes*. `cache=true` is `defaultCacheTime` = 60 minutes. There's no per-call seconds option — to change the unit you change `cacheDatePart` globally.

- **`findAll(cache=N)` is NOT in Wheels' own cache struct.** It hands a native `cachedWithin` timespan to the DB adapter — engine-level `cfquery` caching keyed on the generated SQL. It's *not* cleared by `clearCachableActions()` and *not* affected by editing `application.wheels.cache`. It clears on app reload (cacheKey rotation) or on expiry.

- **Two query caches, easily confused.** Request-level (`cacheQueriesDuringRequest`, in `request.wheels.$queryCache[ModelName]` — it sat directly in `request.wheels[ModelName]` before [#3336](https://github.com/wheels-dev/wheels/issues/3336)) dedupes within one request and is always on — bypass it with `reload=true`. Cross-request (`findAll(cache=N)` + `cacheQueries`) is the engine cache. `reload=true` defeats the *request-level* one; it has nothing to do with `cache=N`.

- **No targeted invalidation API.** No public `clearCache(key)` / `expire(key)` for action/partial/page entries — only the `$`-prefixed internals (and `$clearCache` clears a whole category, not a single key). `clearCachableActions()` unregisters cachability; it does **not** evict already-cached content. Real invalidation = short `time` values + a full `?reload=true`, which re-inits the cache and flushes `cfcache`.

- **`static=true` is a hard abort on a hit.** It renders via `cfcache` and `abort`s the request *before* before/after filters run — only `onSessionStart`/`onRequestStart` still fire. Never use it for anything depending on per-request auth or filters.

- **All action caching skips a flash or just-posted request.** Action caching (static or not) only kicks in when the flash is empty and no form was posted — so a "your comment was saved" banner is never cached. The live request renders fresh and the cache is left untouched.

- **The shared cache is bounded and lossy.** `maximumItemsToCache=5000` across *all* categories combined. When full, `$addToCache` culls only expired items (≤10% of total, ≤ once per 5 min); if nothing is expired and the cache is full, the new item is **silently dropped**. High-cardinality `appendToKey` or many distinct partials can therefore evict or refuse caching unpredictably.

- **`appendToKey` silently skips missing vars (and throws on unsupported scopes).** It only reads `request`/`arguments`/`application`/`session`/`variables`, and you must prefix the scope (a bare var name won't resolve). A missing var in a supported scope is silently omitted from the key — so a logged-out `session.userId` quietly collapses everyone onto one shared cache entry rather than erroring. Referencing an unsupported scope whose var exists (e.g. `url.x`, `form.x`) is what raises `Wheels.KeyNotFound`.

- **Static page caching is a silent no-op on engines without `cfcache`.** On RustCFML, `$cache()` detects `supportsCfcache()==false` and just renders every time, no warning. Action (non-static), partial, and the request/engine query caches don't depend on `cfcache` and still work — only `static=true` and the reload-time template flush degrade.

- **Cached objects are deep-copied on every hit.** Non-simple values are `Duplicate()`'d on both write and read. Good for safety — mutating a cached result can't poison the cache. Bad for cost — caching a large object graph pays a full duplication on every read. Simple-value entries (like rendered HTML) are returned directly without a copy.

## The honest summary

Wheels 4.0's caching is more capable than its reputation — action caching, static page caching, partial caching, page caching, and *two* query caches all genuinely ship and all genuinely work. The arguments are consistent (`cache` everywhere, always minutes) and the on-switch is one `set()` per layer.

Where it's thinner than you'd hope is invalidation. The cross-request store is a single bounded, per-node, in-memory struct with crude expired-only culling, and there's no surgical eviction — you live on expiry times and full reloads. So design accordingly: pick `time` values you'd be comfortable serving stale, reach for `findAll(cache=N)` on the genuinely expensive shared queries, lean on the always-on request dedupe for free, and reserve `static=true` for pages that have no per-user state at all. Get those four decisions right and that 400ms sidebar runs twelve times an hour instead of twelve times a second.
