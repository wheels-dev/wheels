# Partial Caching

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
