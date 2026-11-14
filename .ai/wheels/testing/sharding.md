# Sharding the test suite (maintainer note)

> **Status.** Sharding is available from both test runners and from the Wheels
> CLI. The runners accept query parameters directly; the CLI wraps them as
> `wheels test --shards N --shard K [--shard-weights]`.

Both the **core** runner (`/wheels/core/tests`) and the **app** runner
(`/wheels/app/tests`, used by PMX/CounterPro) accept the same deterministic
shard inputs, so CI can split either suite across jobs without precomputing
bundle lists. The validation/selection contract lives in
`wheels.wheelstest.ShardRequest` (used by both runners), so the two cannot
drift. Weights arrive in one of two ways:

```text
# Inline — small scopes only. The URL-ENCODED shardWeights is capped at 6000
# chars; the runner re-encodes the decoded value before checking.
GET /wheels/core/tests?format=json&db=sqlite&shards=8&shard=3&shardWeights=<url-encoded JSON>

# File — full suite. The runner reads tests/shard-weights.json from the app root.
# The flag accepts only the literal values 1 or true.
GET /wheels/core/tests?format=json&db=sqlite&shards=8&shard=3&shardWeightsFile=1
```

A full-suite weights map (~611 bundles here) is ~36 KB of JSON / ~43 KB
URL-encoded, past Adobe's ~8 KB request-line limit — use the file form for it. The inline
cap is deliberately measured **after URL-encoding** (~2000 characters of JSON)
so the path and the other query params still fit; that is a margin below the
~8 KB limit, not the decoded length of the value.
The file path is fixed (`tests/shard-weights.json` under the app root); callers
cannot point it at an arbitrary path. The file is capped at 131072 bytes, must
exist, and must parse as a JSON object of bundle name -> seconds. The
`shardWeightsFile` flag accepts only `1` or `true`; any other value is a 400
(it is never silently treated as absent). Do not pass `shardWeights` and
`shardWeightsFile` together.

(A POST JSON body was prototyped first and rejected: routing the suite request
as POST changes redirect semantics and request-method-sensitive specs, and
`setCorsHeadersSpec`/redirect specs failed only in that mode. The file transport
keeps the normal GET execution path.)

- `shards` — number of shards, integer 1..64 (a cap keeps a typo like
  `shards=1000000000` from allocating that many partitions).
- `shard` — 1-based shard index, 1..shards (default 1).
- `shardWeights` / `shardWeightsFile` — optional JSON object: bundle name (as
  reported in `bundleStats[].name`; `bundlesDiscovered` is a count) to measured
  seconds. Missing bundles weigh 1. Weights require `shards > 1`;
  non-numeric/negative weights are rejected.

Each shard input must be a single value: a duplicated query parameter (arriving
as an array) returns 400, not 500. The runner re-encodes the decoded inline
`shardWeights` value and returns 400 when its encoded form exceeds 6000
characters (including the measured length in the error), pointing at
`shardWeightsFile=1`. Absent shard inputs, the runner behaves exactly as
before (full alphabetically sorted scope). Invalid inputs return
HTTP 400 with `{"success":false,"error":"Invalid shard parameters","detail":"..."}`
— the runner never silently falls back to the full suite.

The payload adds `bundlesSelected`, `shardCount` and `shardIndex` alongside the
existing `bundlesDiscovered`/scope metadata. A union guard compares the union of
each shard's `bundleStats[].name` values with the unsharded run: the union's
**length** must equal the unsharded `bundlesDiscovered` count, and the union
must contain no duplicates (there is no bundle-name list in the payload).

## App runner and CLI

The app runner uses the same parameters against `/wheels/app/tests`:

```text
GET /wheels/app/tests?format=json&shards=8&shard=3
GET /wheels/app/tests?format=json&shards=8&shard=3&shardWeightsFile=1
```

`shardWeightsFile=1` reads `tests/shard-weights.json` from the app root (the
same fixed path the core runner uses). The JSON payload reports
`bundlesDiscovered` (full count), `bundlesSelected`, `shardCount` and
`shardIndex` for either runner.

The CLI exposes the same contract (app suite by default; add `--core` for the
framework suite):

```bash
wheels test --shards 8 --shard 3 --shard-weights
wheels test --core --shards 8 --shard 3 --shard-weights
```

`--shards` is 1..64, `--shard` is 1..shards, and `--shard-weights` requires
`--shards > 1` (it sends `shardWeightsFile=1`). Invalid combinations fail
before the HTTP request. Weights are only consulted when the file transport is
requested; generate it from a full run's `bundleStats.totalDuration`.

CI matrix example (each job must have its own app instance and database):

```yaml
strategy:
  fail-fast: false
  matrix:
    shard: [1, 2, 3, 4, 5, 6, 7, 8]
steps:
  - run: wheels start
  - run: wheels test --shards 8 --shard ${{ matrix.shard }} --shard-weights
  - run: wheels stop
```

For a raw runner call add
`&shards=$SHARD_COUNT&shard=$SHARD_INDEX&shardWeightsFile=1` to the suite URL.

## Planner

`wheels.wheelstest.ShardPlanner` (unit specs:
`vendor/wheels/tests/specs/internal/shardPlannerSpec.cfc`) uses LPT (longest
processing time first): sort bundles by weight descending, tie-break bundle name
ascending with case-sensitive `Compare` (a case-only difference is a total
order, not an input-order artifact), assign each to the lightest shard (lowest
index wins ties). The planner enforces the same 1..64 shard cap.
`plan(bundles, shardCount, weights)` returns
`{partitions, totals, total, shardCount}`; `partition(bundles, shardCount, shardIndex, weights)`
returns one shard's array. The planner is deterministic — input order does not
affect the result.

LPT beats round-robin on skewed suites. With the PMX 2026-11-06 artifact
weights (VentasSpec 101.6s, then 35.7/32.7/26.8/26.0/23.9/21.7/21.0s) over 3
shards, the slowest shard is 104.4s under LPT vs 150.1s round-robin (~30%
lower). The spec pins these numbers.

## CI composition

1. Generate/refresh the weights file from a full run's `bundleStats.totalDuration`
   (the current full-suite run is the source of truth; PMX and CounterPro keep
   these per repo).
2. Each shard job gets its **own app instance and database** — never point two
   parallel shards at one database. Then run either:
   `wheels test --shards $SHARD_COUNT --shard $SHARD_INDEX --shard-weights`
   (app suite) or add
   `...&shards=$SHARD_COUNT&shard=$SHARD_INDEX&shardWeightsFile=1` to the raw
   runner URL (core or app).
3. A union job (or the aggregate) collects `bundleStats[].name` from every
   shard, asserts the union has no duplicates, and asserts `union.length` equals
   the unsharded run's `bundlesDiscovered` count.

Sharding only partitions work — it does not reduce per-job setup/DB cost, which
dominates at high shard counts.

## Shard safety

Sharding partitions bundles; it does **not** isolate CFML application or request
state between shards. Each shard is a separate suite request, but a spec that
assumes another bundle ran first in the same request — or assumes no other
bundle ran — can pass unsharded and fail only in a shard.

Measured on the full core suite (Lucee 7 + SQLite, 611 bundles / 7,560 specs,
2026-11-06, as 8 weighted shards over the full-suite weights file): **5 shards
green, 3 deterministically failed** on pre-existing order-dependent specs that
pass unsharded:

| bundle | failure in a shard | pass unsharded |
|---|---|---|
| `wheels.tests.specs.dispatch.setCorsHeadersSpec` | `Access-Control-Allow-Origin` header leaked from an earlier bundle (expected `SENTINEL-UNSET`, got `https://myapp.example`) | yes |
| `wheels.tests.specs.model.polymorphicAssociationsSpec` | fixture rows missing (expected 2 comments, got 0) | yes |
| `wheels.tests.specs.events.debugBarComplexityPanelSpec` | DebugBar request state (key `METHODS` missing from the arguments scope) | yes |

Repeat runs reproduced the same three failures in the same shards, and the
`dispatch`, `model` and `events` directories are green unsharded (268 / 1,514 /
208 passing). These are suite shard-safety gaps, not partitioning bugs.

**The union/coverage guard does not catch this.** It verifies that every bundle
ran exactly once; a shard can have complete coverage and still fail because of
leaked state.

Before enabling full-suite sharding for an app:

1. Run the sharded suite and compare each shard's failures with the unsharded
   baseline. Treat any failure that is green unsharded as an order dependence to
   fix (reset the state in the spec) or quarantine — not as a shard/planner bug.
2. Start with scope or coarse-grained shards where cross-bundle dependencies are
   already known, rather than jumping to many weighted shards.
3. Each shard still needs its own app instance and database; sharding does not
   make parallel requests safe against one shared database.
4. Do not claim wall-clock wins until a green sharded run matches the unsharded
   result set.
