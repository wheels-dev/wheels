# Test-suite wall time: PMX and CounterPro

**Maintainer note.** This is an analysis of measured CI wall time for the two
application suites that exercise Wheels most heavily. It is not a spec, a
guarantee, or a rollout plan for either application repository.

## Purpose and method

The goal is to identify the durable levers for shortening the PMX and
CounterPro test jobs, and to separate measured facts from useful guesses.

The numbers come from:

- GitHub Actions job timings (`gh run view <id> --json jobs`) and the
  per-bundle `bundleStats[].totalDuration` values in TestBox JSON reports.
- PMX's scope-sharded `scripts/testbox_ci.py` runs and the `pmx-test-env`
  action; CounterPro's duration-weighted `tools/ci-shard-plan.py` and its
  per-shard `wheels-test-*.json` reports.
- The Wheels core suite locally, including the RustCFML comparison.

Baseline runs: PMX [42267248350](https://github.com/paiindustries/pmx/actions/runs/42267248350);
CounterPro [41878593531](https://github.com/bpamiri/counterpro/actions/runs/41878593531).
Refresh runs: PMX [43603988403](https://github.com/paiindustries/pmx/actions/runs/43603988403)
on main `8e532f2f` after #661 (`fa61811e`); CounterPro
[43603607294](https://github.com/bpamiri/counterpro/actions/runs/43603607294)
on main `53319a3a`.

## Where the time goes

### PMX — baseline (2026-11-06)

| measurement | value |
|---|---:|
| test job | 38m31s |
| test step | 25m52s |
| fixed per job (setup 4m14 + fresh migrate 3m10) | ~7m24s |
| serial compute | ~22m45s |
| controllers | 8m55s (2,455 specs, 16 serial batches) |
| services | 7m53s |
| models | 4m32s |
| functional + data | ~1m26s |

Three scope jobs remove controllers from the main critical path, but each pays
the full ~7m24s setup. The earlier prediction was ~16m20s for the test step
(`7m24 + 8m55`).

### PMX — refresh (2026-11-14)

The scope-sharded branch merged as #661 (`fa61811e`). The latest green main run
`43603988403` took **25m47s** end to end; the shard test-step times are:

| shard / stage | time |
|---|---:|
| controllers | 11m51s |
| services | 10m20s |
| models + small scopes | 7m56s |
| gates (session, surfaces, fresh migrate) | 13m11s |
| union / aggregate | 2m |

The **gates job (13m11s) is now the longest stage**, ahead of every shard, and
the run still carries queue/setup overhead between the first job and the union.
Adding a fourth test shard does not address that; the gates and per-job setup
are the actionable costs. The shard numbers above are test-step times; each
shard job also pays its own environment setup.

### CounterPro — baseline (2026-11-06)

| measurement | value |
|---|---:|
| 8-shard main wall | 27m39s (slowest shard 27m28s) |
| checked-in weights | 4,858s total (80m58s), 607s (10m07s) per shard |
| derived fixed cost | ~17m21s per job |

Eight parallel matrix jobs already split the compute; fixed setup dominates.
The first shard job started at 17:34:04 and the last finished at 18:01:32; the
aggregate finished at 18:01:43.

### CounterPro — refresh (2026-11-14)

Main `53319a3a`, run `43603607294`, uses **9 shards** and took **26m26s** end to
end. Shard runtimes:

| shard | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| time | **20m41s** | 11m32s | 13m49s | 13m51s | 17m53s | 12m42s | 17m52s | 12m49s | 11m40s |

Shard 0 is the long pole. Fixed per-shard setup is material: YugabyteDB start
**69–74s**, migrate **141–193s**, app start **19–27s** — roughly **3–5 minutes
per shard** before a spec runs, or ~27–45 minutes of aggregate setup across
nine jobs. The weighted planner is working, but the weight map and shard count
need to reflect the current suite; shard 0's bundle set is not balanced with the
rest.

## Options

| option | effort | expected wall-time impact | main risk |
|---|---|---|---|
| **More/weighted shards** | S–M | PMX already has three scope shards; a sixth/finer split only helps after gates and setup are cut. CounterPro is at nine; rebalancing shard 0 and splitting its hot bundle set is higher-value than adding shards blindly. | Each shard needs its own app instance and DB; adding jobs increases setup and queue time. Coverage guards do not catch order-dependent failures. |
| **Cut fixed cost** | M | Pre-migrated DB snapshot/template, cached CLI/engine/vendor, and fewer per-job setup steps. CounterPro's measured setup is 3–5m/shard; PMX's baseline fixed cost is 7m24s/job. | Snapshot/template must be versioned by migration level and test-data contract; cache invalidation must be explicit. |
| **In-run parallel workers** | M–L | N app instances/ports/DBs on one host, one setup, workers dispatch bundles. Avoids the CI matrix's per-job setup but requires isolation and a dispatch/merge layer. Best for local or single-host runs. | Shared app/DB state, order-dependent specs, and engine concurrency; not a substitute for per-shard isolation. |
| **RustCFML as the engine** | XL | No app-suite win today. PMX/CounterPro use JVM/Lucee APIs in roughly 180 files each (`CreateObject("java")`, `cfadmin`, JDBC datasource registration; e.g. PMX `app/global/dbpool.cfm`, `app/services/PdfRenderer.cfc`; CounterPro `app/lib/TenantDatasourceRegistrar.cfc`, `app/lib/BoundedQuery.cfc`). Core-suite evidence shows no advantage: **105s RustCFML vs 83.7s Lucee** (2026-11-06); the earlier 52.6 vs 60.9 result did not reproduce. | Port is XL and changes test fidelity; the measured speed delta does not justify it. |
| **Native Rust orchestrator** | M | Spawn N existing engine/app processes, weighted partition, merge JUnit/JSON. The orchestrator does not remove per-process engine boot, DB migration, or TestBox's serial bundle execution. | Another runner to maintain; process/port/DB lifecycle; only worth it after fixed-cost work. |
| **Port specs to Rust** | XXL | No-go for these suites. The specs assert CFML framework behavior, engine quirks, and database semantics; a Rust rewrite tests a different product and loses engine coverage. | Permanent duplicate suite and fidelity loss. |

**RustCFML conclusion:** no-go for an engine port or a Rust spec rewrite. The
app suites are JVM/Lucee applications, and the measured core-suite result is not
faster once the run is representative. A native **orchestrator** is a
conditional go only after fixed-cost work and only if local/CI orchestration is
the remaining bottleneck; Rust is optional for that tool.

## Recommendation

1. **Cut fixed cost first.** In PMX, target the 7m24s per-job setup (pre-migrated
   test DB/snapshot, cached CLI/Lucee/vendor, fewer repeated steps). In
   CounterPro, the measured 3–5m setup per shard is the clearest recurring cost;
   a reusable migrated snapshot/image and cached runtime are higher-value than
   another shard. Version any snapshot by migration level and test-data
   contract.
2. **Then improve shard composition.** PMX: the gates job at 13m11s and the
   queue/overhead around the shards are now the long pole; optimize the gates
   and runner scheduling before adding shards. CounterPro: rebalance **shard 0
   (20m41s)** and split its hot bundle set; refresh the weight map from current
   green runs, then decide whether a tenth shard is worth its setup.
3. **Then hot-bundle work.** PMX's `VentasSpec` and CounterPro's
   provisioning/restore bundles are the largest single-bundle costs; reducing
   per-example seeding and repeated provisioning is app-side work owned by those
   repositories.
4. **Keep the Wheels support layer.** The framework now provides:
   - `wheels.wheelstest.ShardPlanner` (LPT weighted partitioning);
   - shard parameters on both the core and app runners, including
     `shardWeightsFile=1` for a full-suite `tests/shard-weights.json`;
   - `wheels test --shards N --shard K --shard-weights`;
   - the shard-safety caveats in
     [sharding.md](sharding.md).

   That layer partitions work; it does not reduce setup/DB cost, and it does not
   isolate application state.

## Open risks / not done

- **Per-shard isolation is mandatory.** Each parallel shard needs its own app
  instance and database. A shared datasource/port is a correctness bug, not a
  speed optimization.
- **Order-dependent specs.** The Wheels sharding note records three
  pre-existing order-dependent core-suite failures under weighted shards
  (`setCorsHeadersSpec`, `polymorphicAssociationsSpec`,
  `debugBarComplexityPanelSpec`). Sharding can expose the same class of issue in
  an app; compare each shard with the unsharded baseline and fix/reset the spec
  state rather than treating it as a planner defect.
- **State and weights are per run.** Application-scope counters, in-memory
  caches, and weight maps reset or drift; multi-server deployments do not share
  them. Treat exact cross-node caps as an external/provider concern.
- **App-side rollout.** PMX and CounterPro own their environment, migration,
  weight-refresh, and shard-safety changes. This note does not choose their
  rollout order or make commitments for those repositories.
