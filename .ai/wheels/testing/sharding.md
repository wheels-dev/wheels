# Sharding the test suite (maintainer note)

> **Prototype status.** Sharding is exposed **only** as runner query
> parameters. The Wheels CLI has no `--shards`/`--shard` flags yet; do not
> document or script CLI flags for it.

The core runner accepts deterministic shard inputs, so CI can split the suite
across jobs without precomputing bundle lists. Weights arrive in one of two ways:

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
   parallel shards at one database. Then run:
   `...&shards=$SHARD_COUNT&shard=$SHARD_INDEX&shardWeights=$(jq -rn --argjson w "$WEIGHTS" '$w|@uri')`
3. A union job (or the aggregate) collects `bundleStats[].name` from every
   shard, asserts the union has no duplicates, and asserts `union.length` equals
   the unsharded run's `bundlesDiscovered` count.

Sharding only partitions work — it does not reduce per-job setup/DB cost, which
dominates at high shard counts.
