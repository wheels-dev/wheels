# Caching

Part of the Wheels application guide; start with `../CLAUDE.md`.

`includePartial(partial="sidebar", cache=60)` caches the rendered output for 60 minutes. The cache key is a hash of **every argument passed to the partial call** plus the request host, nothing else. The hash includes the **full contents of a `query` argument** (all of its rows), so editing a row produces a new cache key automatically — you do not clear the partial cache by hand to pick up changed data. What the key does **not** include is anything the partial reads that is not an argument (the current user, their permissions, session data), so one viewer's cached output would be served to the next. Partition the key by passing that viewer-dependent state as an argument: `includePartial(partial="sidebar", cache=60, userId=currentUser.id, editable=currentUser.canEdit)` caches a separate copy per distinct argument set.

`cachePartials` (like `cacheActions`, `cachePages` and `cacheQueries`) is **off in development and testing**, so a partial's caching only shows up in production unless a spec turns it on: see `.ai/testing.md` for changing settings in specs and testing partial caching.

## Forms inside a cached fragment

A form rendered with `startFormTag()` or `buttonTo()` carries the current session's authenticity token in a hidden field. **Never cache that markup where other visitors receive it** — every visitor would get the token of the session that warmed the cache, which leaks it and makes everyone else's submit fail with `Wheels.InvalidAuthenticityToken` (a 403). In any cached markup that more than one visitor sees:

1. Leave the token out of the form with `authenticityToken=false` (on `startFormTag()` or `buttonTo()`).
2. Keep `csrfMetaTags()` in the **uncached** layout, not in the cached content.
3. Supply the token at request time from that meta tag.

From Wheels 4.2 the request passes if **either** the form field **or** the `X-CSRF-Token` header carries a valid token, and the header counts on any non-GET request (not only with `X-Requested-With`). Turbo sends the `csrf-token` meta tag's value in `X-CSRF-Token` on every non-GET submit automatically, so a Turbo-submitted form needs only step 1. Your own `fetch()` must set the header explicitly:

```js
fetch(url, {
    method: "POST",
    headers: { "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content },
    body: new FormData(form)
});
```

A plain HTML form post cannot set a header, so fill the hidden field from the meta tag on submit (a small `submit` listener in the uncached layout). Caching per user (a per-user key argument) also avoids the problem, but gives up the shared fragment.

## Caching your own data

`appCacheFetch(key, callback, time)` returns the value cached under `key`; on a miss it calls `callback`, caches the result for `time` (in `cacheDatePart` units, minutes by default; `defaultCacheTime` when left out) and returns it:

```cfm
stats = appCacheFetch("dashboard-stats", function() {
    return {orders = model("Order").count(), revenue = model("Order").sum("total")};
}, 10);
```

The rest: `appCacheRead(key, defaultValue="")`, `appCacheWrite(key, value, time)` (returns `false` when the cache is full), `appCacheExists(key)`, `appCacheDelete(key)` (returns `true` if there was an entry) and `appCacheClear()`. Available in controllers, models, views, jobs and specs.

- Works in **every environment**, including development and testing, unlike `caches()` / `cache=` / `findAll(cache=N)`.
- A cached `false`, `0` or `""` is a hit: `appCacheFetch()` won't recompute it. Never infer a miss from the value; use `appCacheExists()`.
- Keys are case-sensitive strings, or a struct/array of values (struct key order ignored), e.g. `["user", userId, "orders"]`.
- Keys are **shared by every user, session, tenant and host**. Nothing about the request is added. For per-user, per-role or per-tenant data, put that identity in the key (`"digest-" & userId`, `["orders", tenantId, userId]`), or one user's value is served to the next.
- Values are copied in and out. A callback that returns nothing caches nothing (returns `""`); one that throws caches nothing and the error propagates.
- No stampede guard: concurrent misses may each run the callback; the later write wins.
- Entries live in their own `data` category: `appCacheClear()` never touches action/page/partial/query caches. They share `maximumItemsToCache` (when full, `appCacheWrite()` returns `false` and `appCacheFetch()` returns its value uncached, so it recomputes next time), are per server and in memory, and empty on reload/restart.
- These names, like every public framework helper, can't be used as controller action names.
- Invalidate with `appCacheDelete(key)` when the underlying data changes (e.g. from a model `afterSave`).
