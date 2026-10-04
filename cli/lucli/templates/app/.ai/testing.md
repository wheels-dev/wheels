# Testing: changing settings in specs

Part of the Wheels application guide; start with `../CLAUDE.md`.

## Changing a setting in a spec

Read and write `application.wheels.<setting>` and restore it afterwards. Never write `application.$wheels.<setting>`: `$wheels` only exists while `onApplicationStart` runs, and because the framework reads from `$wheels` whenever that key exists, the write creates a one-key struct that every later request reads (errors like `key [MIXINS] doesn't exist`) until the test application is restarted.

```cfm
var original = application.wheels.cachePartials;
application.wheels.cachePartials = true;
try { /* exercise it */ } finally { application.wheels.cachePartials = original; }
```

To test partial caching, turn `cachePartials` on this way and call `application.wo.$clearCache("partial")` before and after, so cached output doesn't leak between specs.

## Reading fresh rows past the per-request query cache

Finders cache their results for the rest of the request (the `cacheQueriesDuringRequest` setting, on by default), and a spec runs in a single request. A save **through a model** (`create`, `update`, `updateAll`, `delete`, `deleteAll`, `insertAll`) clears that model's cached queries, so re-reading the **same** model after its own save returns fresh rows — no extra step needed.

The cache stays stale only when data changes *without* the cached model's own save clearing it:

- **raw SQL** (`queryExecute`, or a migration's `execute`) — it bypasses the model, so nothing clears the cache;
- a write through a **different** model than the one you re-query — e.g. creating a `Comment` does not refresh a cached `model("Post").findAll(include = "comments")`;
- data changed in a **separate request** — an HTTP request through the test client runs in its own request, so the spec's own cached reads are unaffected.

Two ways to read fresh rows in those cases:

- Pass `reload=true` to the finder for a single call:

```cfm
// data changed outside this model's own save (raw SQL, another model, or a
// separate test-client request); reload=true re-runs the query
expect(model("Post").findAll(reload = true).recordCount).toBe(3);
```

- Clear the whole request cache when several later reads must not see anything cached earlier:

```cfm
StructDelete(request.wheels, "$queryCache");
```

`$queryCache` is a reserved key under `request.wheels`; deleting it drops every model's cached finder results for the current request.
