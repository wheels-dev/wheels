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

## Counting the queries a call sends (4.2+)

`assertQueries(count, callback)`, `assertNoQueries(callback)`, `assertQueriesMatch(pattern, callback, count = "")`, `assertNoQueriesMatch(pattern, callback)` and `recordQueries(callback)` (returns `[{sql, dataSource}]`) count the SQL statements the model layer sends while `callback` runs. They're in every `wheels.WheelsTest` spec. They return the callback's result, take an optional `dataSource` filter, nest, and list the statements on failure with each bound value as `?` (a value written into the SQL with `parameterize = false` appears as written).

```cfm
var post = assertQueries(1, () => model("Post").findByKey(1));
assertNoQueries(() => post.title);
assertNoQueriesMatch("comments", () => model("Post").findAll(include = "author"));
```

What isn't counted: a finder answered from the per-request query cache above (no SQL is sent; pass `reload = true`), raw `queryExecute` (including advisory locks, the migration lock, the job store and SQL Server's probes), transaction control, and test-client requests (a request of their own).

## Which environment app specs run in

`wheels test` runs your specs in the environment `.env` sets (`WHEELS_ENV=development` in a new app), not `testing`, so `config/testing/settings.cfm` doesn't apply to them. Put spec-wide defaults in `config/development/settings.cfm`. For example, to keep every spec from sending mail:

```cfm
// config/development/settings.cfm (this also stops your development server from sending mail)
set(functionName = "sendEmail", deliver = false);
```

To turn delivery off for a single spec instead, see `.ai/mailers.md`.

## POSTs through the test client and CSRF

Controllers extending the app's `Controller` call `protectsFromForgery()`, so a POST, PUT, PATCH or DELETE needs the session's authenticity token. `$testClient()` handles it like a browser: fetch a page that has the token (a form, or `csrfMetaTags()` in the layout) and the client sends it on the next unsafe requests, as the `X-CSRF-Token` header and the `authenticityToken` form field:

```cfm
var testClient = $testClient();
testClient.get("/posts/new");
testClient.post("/posts", {"post[title]": "T", "post[body]": "B"})
    .assertRedirect();  // redirectTo() answers a POST with 303
```

After a login, the session (and its token) changes: GET a page again before the next form post. Also `fetchCsrfToken(path)`, `csrfToken()`, `withCsrfToken(token)`, and `withoutCsrfToken()` to test the 403.

## Setting the client address

`fromAddress(ip)` makes a request appear to come from a given client address, so per-client behaviour (rate limiting, IP allow/deny rules) is testable:

```cfm
$testClient().fromAddress("203.0.113.9").get("/api/search");   // RateLimiter / IP rules see 203.0.113.9
```

The address reaches middleware through the request context; it never changes `cgi.remote_addr`, so app code reading that directly is unaffected, and it is ignored outside the isolated test application.

## Saving and restoring route state in specs

A spec that redefines the route table leaks stale routes into every spec that runs after it (wrong `linkTo`/`urlFor` output, phantom named routes). `wheels.WheelsTest` provides three helpers so a route-manipulating spec cleans up after itself: `$snapshotRoutes()` captures the full route state, `$restoreRoutes(snapshot)` puts it back, and `$clearRoutes()` empties it so you can define a fresh table. Snapshot in `beforeEach`, restore in `afterEach`:

```cfm
beforeEach(() => {
    var g = application.wo;
    variables._routes = $snapshotRoutes();
    $clearRoutes();
    g.mapper().resources("widgets").end();
    g.$setNamedRoutePositions();
});
afterEach(() => $restoreRoutes(variables._routes));
```

`$snapshotRoutes()` captures everything a redefinition touches — the route list, the static-route index, named-route positions, the `urlFor` caches, and the dynamic route index and route-table generation — so `$restoreRoutes()` leaves the table byte-for-byte as it was, with no leakage into later specs.
