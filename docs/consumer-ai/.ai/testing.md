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

## Clearing the per-request query cache

Finders cache their results for the rest of the request (the `cacheQueriesDuringRequest` setting, on by default). A spec runs in a single request, so a finder re-run **after a write** — an `update()` / `create()`, raw SQL, or an HTTP request through the test client — returns the rows cached *before* the write, not the new ones.

Two ways to read fresh rows in a spec:

- Pass `reload=true` to the finder for a single call:

```cfm
user.update(name = "new");
expect(model("User").findByKey(key = user.key(), reload = true).name).toBe("new");
```

- Clear the whole request cache when a later read must not see anything cached earlier (for example after raw SQL, or after a test-client request that changed data):

```cfm
StructDelete(request.wheels, "$queryCache");
```

`$queryCache` is a reserved key under `request.wheels`; deleting it drops every model's cached finder results for the current request.
