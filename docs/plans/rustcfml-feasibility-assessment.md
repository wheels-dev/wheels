# RustCFML Feasibility Assessment for Wheels Framework

**Date:** 2026-05-18 (updated from initial 2026-03-15 evaluation)
**Project:** [pixl8/RustCFML](https://github.com/pixl8/RustCFML)
**Version Evaluated:** 0.9.1 (released May 3, 2026)
**Previous Version Evaluated:** 0.4.0 (March 14, 2026)

## Executive Summary

RustCFML is a **complete CFML interpreter written in Rust** — not a library or extension. It replaces Lucee/ACF as a runtime, compiling CFML to bytecode executed on a stack-based VM with no JVM dependency.

**Updated Verdict: Feasibility has improved significantly. Several previous blockers are now resolved. A proof-of-concept trial is now reasonable.**

Since the initial evaluation two months ago, RustCFML has gone from v0.4.0 to v0.9.1 (14 releases, 108 commits), addressing three of the four critical blockers identified previously. The project has also grown from 3 to 20 stars and gained its first fork, indicating rising community awareness.

## Progress Since Initial Evaluation (March 2026)

### Previously Identified Blockers — Status Update

| Blocker | March Status | May Status | Impact |
|---------|-------------|------------|--------|
| **`onMissingMethod`** | Unknown/unlikely | **Implemented** | Wheels' dynamic finders (`findAllByEmail()`) may now work |
| **`cflock`** | Unknown | **Implemented** (RwLock-based) | Thread-safe rate limiting, caching, initialization possible |
| **`getMetadata`** | Unknown | **Implemented** | Model configuration, routing, test discovery possible |
| **`CreateObject`** | Not supported | **Implemented** (for components) | Component instantiation works |
| **Java interop (`CreateObject("java", ...)`)** | Not supported | **Still not supported** | Remains a blocker for `ConcurrentHashMap` usage |
| **`cfthread` (true concurrency)** | Sequential only | **Still sequential** | Background jobs would block |
| **Query-of-Queries** | Not supported | **Still not supported** | Low impact for Wheels |

### New Capabilities Since v0.4.0

- **`cflock`** with real named locks using RwLock-based concurrency
- **`onMissingMethod`** for dynamic method dispatch
- **`getMetadata`** for component introspection
- **`createObject`** for component instantiation
- **`cfinvoke`** tag support
- **Session lifecycle** (`onSessionStart`/`onSessionEnd`)
- **`cfthread`** tag (sequential model)
- **`cfzip`** operations
- **`cfexecute`** for OS command execution
- **`cfstoredproc`/`cfprocparam`** for stored procedures
- **Custom tags** with `cf_` prefix
- **`cfimport`** with `.tld` support
- **Bytecode caching** with modification-time tracking (no recompilation for unchanged files)
- **Performance tuning** across VM hot paths (v0.8.0-v0.9.0 focus)
- **CFMX_COMPAT** encryption algorithm support
- **Taffy framework** compatibility (claimed feature-complete)

### Project Growth Metrics

| Indicator | March 2026 | May 2026 | Change |
|-----------|-----------|----------|--------|
| Version | 0.4.0 | 0.9.1 | 14 releases in 2 months |
| Stars | 3 | 20 | 7x increase |
| Forks | 0 | 1 | First community fork |
| Commits | 39 | 108 | 69 new commits |
| Test assertions | 1,181 / 89 suites | 1,181+ / 89+ suites | Baseline maintained |
| Release cadence | ~weekly | ~weekly | Consistent |

## Revised Compatibility Analysis

### Now Supported (previously blocked or unknown)

| Wheels Feature | RustCFML Support | Notes |
|---------------|-----------------|-------|
| Dynamic finders (`findAllByEmail`) | `onMissingMethod` implemented | Needs behavioral verification |
| Thread-safe middleware | `cflock` with RwLock | Real concurrency, not just advisory |
| Component metadata inspection | `getMetadata` implemented | Model config, test discovery |
| Component instantiation | `createObject` for components | CFC creation works |
| CSRF tokens | `csrfGenerateToken`/`csrfVerifyToken` | Behavioral compat with Lucee TBD |
| Encrypt/Decrypt | AES, DES, DESEDE, Blowfish, CFMX_COMPAT | Cookie compat needs testing |
| Session management | Full lifecycle with CFID cookie | `onSessionStart`/`onSessionEnd` |
| Transaction management | `cftransaction` | Rollback/savepoint needs testing |
| Named locks | `cflock` (read/write) | RwLock-based, real concurrency |
| Password hashing | bcrypt, scrypt, argon2, PBKDF2 | Better than stock Lucee |
| Stored procedures | `cfstoredproc`/`cfprocparam` | Database-dependent |
| File operations | 23+ file I/O functions | Upload, read, write, directory ops |
| Caching | 8 cache functions | `cachePut`, `cacheGet`, etc. |
| Error context | `cfcatch.tagContext` with stack traces | Line/column/template info |

### Remaining Blockers

| Wheels Requirement | Status | Severity | Workaround |
|-------------------|--------|----------|------------|
| **`CreateObject("java", ...)`** | Not supported | **Medium** | Replace `ConcurrentHashMap` with CFML struct + `cflock`. Replace `StringBuilder` with string concatenation or array join. Only 2-3 call sites in Wheels core. |
| **`cfthread` true concurrency** | Sequential only | **Low** | Background jobs (`wheels.Job`) would block, but most Wheels apps don't use in-request threading. Worker processes are typically separate. |
| **Query-of-Queries** | Not supported | **Low** | Wheels rarely uses QoQ. Any instances could be rewritten as database queries. |
| **`GetComponentMetaData`** (as distinct from `getMetadata`) | Unconfirmed | **Low** | `getMetadata` is confirmed; `GetComponentMetaData` may work as an alias or may not be needed. |

### Critical Behavioral Questions (need testing)

These features are nominally supported but Wheels depends on specific behavioral contracts:

1. **`onMissingMethod` argument passing**: Wheels passes `missingMethodName` and `missingMethodArguments` — does RustCFML match this signature exactly?
2. **`getMetadata` depth**: Wheels inspects `functions`, `extends`, `name`, `fullname`, `path` from metadata. How complete is the returned struct?
3. **`Encrypt`/`Decrypt` output format**: CSRF cookies encrypted on Lucee must be decryptable on RustCFML if migrating a running app (probably not a concern for fresh deploys).
4. **Application scope persistence**: Wheels stores extensive config in `application.$wheels`. Does `application` scope persist correctly across requests with the same semantics?
5. **`cflock` timeout behavior**: Wheels uses `timeout=1` on rate limiter locks. Does RustCFML respect lock timeout and fail gracefully?
6. **Scope resolution order**: Wheels depends on specific scope precedence (`local` > `arguments` > `variables`). CFML engines vary subtly here.
7. **`isInstanceOf` behavior**: Wheels uses this for type checking in DI and model resolution.
8. **Interface `implements` enforcement**: Wheels middleware uses `implements="wheels.middleware.MiddlewareInterface"`.

## Wheels Code Changes Needed

### Minimal changes (to eliminate remaining blockers)

```
vendor/wheels/middleware/RateLimiter.cfc (line 55):
  - CreateObject("java", "java.util.concurrent.ConcurrentHashMap").init()
  + StructNew()  // with cflock protection (already present)

vendor/wheels/Channel.cfc:
  - Same ConcurrentHashMap replacement

vendor/wheels/model/read.cfc (if StringBuilder used):
  - Replace java.lang.StringBuilder with array + ArrayToList
```

These are 2-3 small, isolated changes that would make the Wheels core Java-interop-free without affecting Lucee/ACF compatibility (struct + cflock works on all engines).

### No changes needed for

- CSRF protection (uses standard `Encrypt`/`Decrypt`/`GenerateSecretKey`/`CsrfGenerateToken`)
- Hash-based cache keys (uses standard `Hash()`)
- Model identification and transactions (uses standard `Hash()`)
- Route matching and dispatch (pure CFML)
- View rendering (pure CFML)
- Migration system (uses `queryExecute` which is supported)
- Validation framework (pure CFML)
- Association/relationship definitions (pure CFML, depends on `onMissingMethod`)

## Performance Implications for Wheels

| Scenario | Expected Benefit | Confidence |
|----------|-----------------|------------|
| Cold start (container/serverless) | **Massive** — instant vs ~15s JVM warmup | High |
| Memory per instance | **44x reduction** — 8 MB vs 350 MB | High (trivial workloads verified) |
| Simple page renders | **3x throughput** — 1,949 vs 635 req/s | High |
| ORM-heavy pages | **Unknown** — dynamic method dispatch overhead not benchmarked | Low |
| Complex model graphs | **Unknown** — component instantiation + metadata perf not tested | Low |
| Concurrent requests | **Uncertain** — Axum is async but cfthread is sequential | Medium |

## Recommendations (Updated)

### Immediate (now): Proof-of-concept trial

The resolution of `onMissingMethod`, `cflock`, and `getMetadata` makes a PoC reasonable:

1. **Build RustCFML from source** and attempt to boot the Wheels demo app (`app/`)
2. **Run the core test suite** against RustCFML to get a compatibility baseline
3. **Document failures** — categorize as (a) missing function, (b) behavioral difference, (c) Java interop dependency
4. **Estimate gap size** — if >80% of tests pass, active pursuit is justified

### Short-term (1-3 months): Eliminate Java interop in Wheels core

Regardless of RustCFML adoption, removing `CreateObject("java", ...)` from the framework core is good hygiene:

- Makes Wheels more portable across all CFML engines (including BoxLang)
- Only 2-3 call sites need changes
- The `cflock`-protected struct pattern already exists alongside the Java calls

### Medium-term (3-6 months): Engage with Pixl8

If the PoC shows >80% compatibility:

1. **File issues** for specific behavioral gaps discovered during testing
2. **Contribute test cases** from Wheels' test suite that exercise edge cases
3. **Explore adding Wheels/RustCFML to the CI compat matrix** as a soft-fail target (like Oracle)
4. **Document the "Wheels on RustCFML" story** for containerized/edge deployments

### Long-term (6-12 months): Lightweight deployment target

Position RustCFML as an optional deployment runtime for:
- **Docker/Kubernetes** — 8 MB image vs 350+ MB
- **Serverless/edge functions** — instant cold start
- **CI/test environments** — faster test cycles
- **API-only Wheels apps** — no view layer complexity

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Project abandoned (single maintainer) | Medium | High | MIT license allows forking; Pixl8 is an established CFML shop |
| Behavioral incompatibilities surface at scale | High | Medium | Incremental adoption starting with simple apps |
| Performance gains disappear with complex apps | Medium | Low | Still wins on memory/startup even if throughput is similar |
| Breaking changes in pre-1.0 releases | High | Low | Pin versions; don't depend on internals |
| Community doesn't grow | Medium | Medium | Wheels adoption would itself grow the community |

## Conclusion

RustCFML has made remarkable progress in two months. The three most critical Wheels blockers — `onMissingMethod`, `cflock`, and `getMetadata` — are now implemented. The remaining gap (Java interop) affects only 2-3 isolated call sites in Wheels core, and the fix is straightforward and engine-agnostic.

**The project has moved from "watch and wait" to "try it and see."** A proof-of-concept attempt to boot Wheels on RustCFML is now the right next step. The outcome will determine whether this becomes a real deployment option or needs another 6-12 months of runtime maturation.

The 44x memory reduction and instant cold start alone would make RustCFML a compelling option for containerized Wheels deployments — if the compatibility gap can be bridged.
