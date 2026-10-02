# Partial Caching

Part of the Wheels application guide; start with `../CLAUDE.md`.

`includePartial(partial="sidebar", cache=60)` caches the rendered output for 60 minutes. The cache key is a hash of **the arguments passed to the partial call** plus the request host, nothing else. Anything the partial reads that isn't an argument (the current user, their permissions, session data) is not part of the key, so one user's cached output is served to the next. Pass viewer-dependent state as an argument (`includePartial(partial="sidebar", cache=60, userId=currentUser.id)`), or don't cache that partial.

`cachePartials` (like `cacheActions`, `cachePages` and `cacheQueries`) is **off in development and testing**, so a partial's caching only shows up in production unless a spec turns it on: see `.ai/testing.md` for changing settings in specs and testing partial caching.
