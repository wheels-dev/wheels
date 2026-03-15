# RustCFML Feasibility Assessment for Wheels Framework

**Date:** 2026-03-15
**Project:** [pixl8/RustCFML](https://github.com/pixl8/RustCFML)
**Version Evaluated:** 0.4.0 (released March 14, 2026)

## Executive Summary

RustCFML is a **complete CFML interpreter written in Rust** — not a library or extension for existing CFML engines. It aims to replace Lucee/ACF as a runtime, compiling CFML to bytecode executed on a stack-based VM with no JVM dependency.

**Verdict: Not feasible today. Worth monitoring for future potential.**

RustCFML is too early-stage to run Wheels in production, but its architecture and performance characteristics make it a compelling long-term target. The project would need to mature significantly in areas Wheels depends on (ORM-like dynamic method dispatch, complex component inheritance, Java interop) before Wheels could realistically target it.

## What RustCFML Actually Is

It is important to clarify: RustCFML is **not** a Rust extension library that adds functions to Lucee/ACF (like a ForgeBox package). It is a standalone CFML runtime that:

- Parses CFML/CFScript source code
- Compiles it to custom bytecode
- Executes it on a Rust-based VM
- Includes a built-in web server (Axum-based)
- Ships as a single native binary (~8 MB memory footprint)

This means the feasibility question is: **"Can Wheels run on RustCFML as an alternative to Lucee?"** — not "Can we add RustCFML to our Lucee stack?"

## Performance Profile

RustCFML's benchmarks are impressive for a Hello World page:

| Metric | RustCFML | Lucee 7.0.1 | BoxLang 1.10 |
|--------|----------|-------------|--------------|
| Memory (RSS) | ~8 MB | ~350 MB | ~305 MB |
| Requests/sec | 1,949 | 635 | 293 |
| Avg response | 0.5 ms | 1.6 ms | 3.4 ms |
| Startup | Instant | ~15s | ~15s |

These numbers are for trivial workloads. Real-world Wheels applications involve ORM queries, component inheritance chains, dynamic method resolution, and session management — none of which are benchmarked.

## Wheels Dependencies vs RustCFML Capabilities

### Supported (would work today)

| Wheels Feature | RustCFML Support |
|---------------|-----------------|
| CFScript syntax | Full support, 50+ tags converted |
| Component inheritance (`extends`) | Supported with interfaces |
| Closures and arrow functions | Supported with scope capture |
| Built-in string/array/struct functions | 400+ functions implemented |
| `queryExecute` with params | MySQL, PostgreSQL, SQLite, MSSQL |
| `cfhttp` for external calls | GET/POST/PUT/DELETE/PATCH |
| Session/cookie management | Supported |
| `Hash()`, `Encrypt()`, `Decrypt()` | Supported (including bcrypt/scrypt/argon2) |
| `SerializeJSON`/`DeserializeJSON` | Supported |
| URL rewriting | Tuckey-compatible XML config |
| Application.cfc lifecycle | onApplicationStart, onRequestStart, etc. |
| File I/O operations | Supported |

### Critical Gaps (blockers for Wheels)

| Wheels Requirement | RustCFML Status | Impact |
|-------------------|----------------|--------|
| **Dynamic method dispatch** (`onMissingMethod`) | Unknown/unlikely | Wheels ORM relies heavily on dynamic finders like `findAllByEmail()` via `onMissingMethod`. This is fundamental to the ActiveRecord pattern. |
| **Complex `CreateObject("java", ...)`** | Not supported | Wheels uses `ConcurrentHashMap` in RateLimiter, and Lucee/ACF-specific Java objects throughout. No JVM = no Java interop. |
| **Query-of-Queries** | Explicitly unsupported | Wheels doesn't heavily use QoQ, but some internal operations may depend on it. |
| **`cflock` tag** | Unknown | Wheels uses `cflock` extensively for thread-safe rate limiting, caching, and initialization. |
| **Metadata introspection** (`GetMetadata`, `GetComponentMetaData`) | Unknown | Wheels inspects component metadata for model configuration, routing, and test discovery. |
| **`Evaluate()` / dynamic evaluation** | Unknown | Some Wheels internals use dynamic evaluation for scope resolution. |
| **ORM/Hibernate** | Not supported | Wheels has its own ActiveRecord ORM (not Hibernate), but it relies on deep CFML engine features for dynamic method resolution. |
| **Custom tag paths / mappings** | Partial (component mappings exist) | Wheels uses custom mappings for `vendor/`, `app/`, etc. |
| **`cfthread` (true concurrency)** | Sequential only | Background job processing (`wheels.Job`) needs real async. |
| **Transaction management** | Supported (`cftransaction`) | Wheels uses this — would need verification of rollback/savepoint behavior. |

### Partially Supported (would need testing)

| Feature | Notes |
|---------|-------|
| `CsrfGenerateToken()` / `CsrfVerifyToken()` | Wheels CSRF uses these Lucee/ACF built-ins. RustCFML has security functions but these specific ones are unconfirmed. |
| `cfheader` / `cfcookie` in middleware | RustCFML's web server handles these differently than servlet-based engines. |
| Application scope persistence | Wheels stores extensive config in `application.$wheels`. Behavior under RustCFML's Application.cfc lifecycle needs validation. |
| Error handling (`cftry`/`cfcatch`/`cfthrow`) | Basic support likely exists, but Wheels uses typed exceptions (`type="Wheels.InvalidAuthenticityToken"`) that need precise matching. |

## Wheels-Specific Code Analysis

### Crypto/Security Usage
Wheels uses these crypto operations that RustCFML would need to support identically:
- `GenerateSecretKey("AES")` — CSRF cookie encryption key generation
- `Encrypt()`/`Decrypt()` with AES algorithm — CSRF cookie values
- `Hash()` — Cache keys, asset fingerprinting, model IDs, transaction hashing
- `CsrfGenerateToken()`/`CsrfVerifyToken()` — Session-based CSRF (Lucee built-in)

RustCFML claims bcrypt/scrypt/argon2 support, which is actually **better** than stock Lucee for password hashing, but the standard `Encrypt()`/`Decrypt()` output format must be byte-compatible with existing cookies.

### Java Interop Dependencies
Found in Wheels core:
- `CreateObject("java", "java.util.concurrent.ConcurrentHashMap")` — RateLimiter middleware
- Various Lucee/ACF-specific internal APIs used implicitly

### Dynamic Method Resolution
Wheels' ActiveRecord pattern is built on dynamic method dispatch:
```cfm
model("User").findAllByEmail("test@example.com")  // via onMissingMethod
model("User").findOneByUsernameAndPassword(...)    // compound dynamic finders
user.hasOrders()                                   // dynamic association checker
```
This is the single biggest compatibility concern.

## Project Maturity Assessment

| Indicator | Value | Assessment |
|-----------|-------|------------|
| Version | 0.4.0 | Pre-1.0, expect breaking changes |
| Stars | 3 | Minimal community adoption |
| Forks | 0 | No community contributions |
| Commits | 39 | Early development |
| Contributors | ~1 (Pixl8) | Single-maintainer risk |
| Test coverage | 1,181 assertions / 89 suites | Reasonable for scope |
| License | MIT | No licensing concerns |
| Last activity | March 2026 | Actively developed |

## Recommendations

### Short-term (Now): No action needed
- RustCFML cannot run Wheels today due to missing dynamic method dispatch, Java interop, and unverified CFML engine built-ins
- Do not invest engineering time in compatibility work

### Medium-term (6-12 months): Monitor and engage
1. **Watch the repo** for releases that add `onMissingMethod`, metadata introspection, and `cflock` support
2. **Open a dialog** with the Pixl8 team about framework compatibility goals — if they want RustCFML to run real-world apps, Wheels is a good benchmark
3. **Create a compatibility test suite** — a minimal Wheels app that exercises core ORM, routing, CSRF, and middleware features, runnable against any CFML engine

### Long-term (12+ months): Evaluate as a deployment target
If RustCFML reaches 1.0 with:
- Full `onMissingMethod` support
- Component metadata introspection
- Robust `cflock` implementation
- Compatible `Encrypt()`/`Decrypt()` output

Then Wheels could potentially offer RustCFML as a **lightweight deployment target** — attractive for:
- Containerized/serverless deployments (8 MB vs 350 MB)
- Edge computing scenarios
- High-throughput API-only Wheels apps (no view layer)
- Development/CI environments (instant startup)

### What Wheels could do to prepare
1. **Reduce Java interop dependence** — Replace `ConcurrentHashMap` in RateLimiter with pure CFML struct + cflock (already partially done)
2. **Abstract engine-specific built-ins** — Wrap `CsrfGenerateToken()` so alternative implementations can be swapped
3. **Document dynamic method contracts** — Clearly specify what `onMissingMethod` patterns Wheels requires, so runtime implementors know the target

## Conclusion

RustCFML represents an exciting direction for the CFML ecosystem — a modern, high-performance runtime with minimal resource requirements. However, it is a pre-1.0 single-maintainer project that lacks several features fundamental to how Wheels operates. The performance benefits are compelling but academic until the compatibility gap closes.

**The right move is to watch, not adopt.** If the project gains momentum and addresses dynamic method dispatch and metadata introspection, it could become a viable lightweight runtime for Wheels applications within 12-18 months.
