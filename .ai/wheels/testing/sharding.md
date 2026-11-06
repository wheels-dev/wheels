# Sharding the test suite (maintainer note)

The core runner accepts deterministic shard parameters, so CI can split the
suite across jobs without precomputing bundle lists:

```text
GET /wheels/core/tests?format=json&db=sqlite&shards=8&shard=3&shardWeights=<url-encoded JSON>
```

- `shards` — number of shards, integer >= 1.
- `shard` — 1-based shard index, 1..shards (default 1).
- `shardWeights` — optional URL-encoded JSON object: bundle name (as returned
  in `bundlesDiscovered`) to measured seconds. Missing bundles weigh 1.
  Non-numeric/negative weights are rejected.

Absent shard parameters, the runner behaves exactly as before (full
alphabetically sorted scope). Invalid parameters return HTTP 400 with
`{"success":false,"error":"Invalid shard parameters","detail":"..."}` — the
runner never silently falls back to the full suite.

The payload adds `bundlesSelected`, `shardCount` and `shardIndex` alongside the
existing `bundlesDiscovered`/scope metadata, so a union guard can verify that
every bundle ran exactly once across shards (compare the union of each shard's
`bundleStats[].name` with the unsharded `bundlesDiscovered`).

## Planner

`wheels.wheelstest.ShardPlanner` (unit specs:
`vendor/wheels/tests/specs/internal/shardPlannerSpec.cfc`) uses LPT (longest
processing time first): sort bundles by weight descending, tie-break bundle name
ascending, assign each to the lightest shard (lowest index wins ties).
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
3. A union job (or the aggregate) asserts the union of shard bundle names equals
   the unsharded `bundlesDiscovered` and that no bundle appears twice; run the
   unsharded suite or a discovery-only request to get the expected list.

Sharding only partitions work — it does not reduce per-job setup/DB cost, which
dominates at high shard counts.
