---
status: skeleton
slot: post 3 (week 2; pairs with GA announce for security-minded audiences)
target_length: 1600–2000 words
---

# Security Hardening in Wheels 4.0

**Subhead / dek:** *Forty-plus PRs, one narrative: how 4.0 becomes a secure-by-default framework.*

**Target audience:**
- Security engineers auditing Wheels for enterprise adoption
- Teams under compliance pressure (SOC2, HIPAA, PCI)
- Existing Wheels users who want to know which defaults to trust
- CFML community members who remember the era of "roll-your-own-CSRF"

**Lead paragraph intent:**
- 4.0 isn't a security release — it's a release that takes security seriously across 8 categories.
- 40+ PRs, not a checkbox. Each category has a coherent posture now.
- This post walks each attack surface: what 3.0 did, what attacker scenarios were in-scope, how 4.0 closes them.
- Known-limitations honesty at the end.

## Sections

### 1. "What changed posture-wise"
- 3.0 had per-issue security patches; 4.0 has secure-by-default opinions.
- Not a CVE round-up — a *category-by-category* tightening.

### 2. SQL injection — QueryBuilder + scope pipeline
- **Category frame:** user-provided input reaching SQL generation.
- **What hardened:**
  - QueryBuilder property + operator validation ([#2025](https://github.com/wheels-dev/wheels/pull/2025)).
  - ORDER BY clause ([#2026](https://github.com/wheels-dev/wheels/pull/2026)).
  - `$quoteValue` single-quote escaping ([#2033](https://github.com/wheels-dev/wheels/pull/2033)).
  - Scope handler argument sanitization ([#2043](https://github.com/wheels-dev/wheels/pull/2043), [#2045](https://github.com/wheels-dev/wheels/pull/2045), [#2056](https://github.com/wheels-dev/wheels/pull/2056), [#2061](https://github.com/wheels-dev/wheels/pull/2061), [#2070](https://github.com/wheels-dev/wheels/pull/2070), [#2090](https://github.com/wheels-dev/wheels/pull/2090)).
  - Geography property detection ([#2044](https://github.com/wheels-dev/wheels/pull/2044)); WKT handling ([#2055](https://github.com/wheels-dev/wheels/pull/2055)).
  - Index hints via `$indexHint` ([#2058](https://github.com/wheels-dev/wheels/pull/2058)).
- **Takeaway:** scope handlers and QueryBuilder chains are safe to use with user-provided values — the framework validates structurally.

### 3. Path traversal — multiple surfaces
- Partial template rendering ([#2071](https://github.com/wheels-dev/wheels/pull/2071)).
- `guideImage` endpoint ([#2037](https://github.com/wheels-dev/wheels/pull/2037)).
- MCP documentation reader ([#2049](https://github.com/wheels-dev/wheels/pull/2049)).
- Encoded-bypass attempts ([#2089](https://github.com/wheels-dev/wheels/pull/2089)).
- **Takeaway:** every path-accepting surface was audited; canonicalization catches encoded variants.

### 4. Session / CSRF / redirect integrity
- **SameSite CSRF cookie** ([#2035](https://github.com/wheels-dev/wheels/pull/2035)).
- **Auto-gen encryption key when empty** ([#2054](https://github.com/wheels-dev/wheels/pull/2054)).
- **CSRF key required in production** ([#2079](https://github.com/wheels-dev/wheels/pull/2079)).
- **Session fixation prevention on login** ([#2034](https://github.com/wheels-dev/wheels/pull/2034)).
- **Open-redirect blocked in `redirectTo()`** ([#2038](https://github.com/wheels-dev/wheels/pull/2038)).

### 5. CORS and security headers (the deny-by-default story)
- **CORS:** wildcard → deny-all ([#2039](https://github.com/wheels-dev/wheels/pull/2039)); rejects wildcard + credentials ([#2053](https://github.com/wheels-dev/wheels/pull/2053)).
- **SecurityHeaders middleware:** CSP, HSTS, Permissions-Policy ([#2036](https://github.com/wheels-dev/wheels/pull/2036)); HSTS default-on in prod ([#2081](https://github.com/wheels-dev/wheels/pull/2081)).
- Frame: "deny-by-default" is the policy; apps opt in to the behavior they actually need.

### 6. Rate limiter — hardening a hardening feature
- **Initial addition** ([#1931](https://github.com/wheels-dev/wheels/pull/1931)) was the easy part; production-hardening it was the interesting work.
- `trustProxy` default false ([#2024](https://github.com/wheels-dev/wheels/pull/2024)).
- Memory exhaustion + IP spoofing mitigations ([#2041](https://github.com/wheels-dev/wheels/pull/2041)).
- Per-key exhaustion ([#2048](https://github.com/wheels-dev/wheels/pull/2048)).
- Fail-closed on lock timeout ([#2069](https://github.com/wheels-dev/wheels/pull/2069)).
- Cleanup throttle + key length limit ([#2080](https://github.com/wheels-dev/wheels/pull/2080)).
- Proxy strategy default = `last` ([#2088](https://github.com/wheels-dev/wheels/pull/2088)).

### 7. JWT and console / reload — auth and dev surfaces
- **JWT algorithm claim validated** + constant-time signature ([#2079](https://github.com/wheels-dev/wheels/pull/2079), [#2086](https://github.com/wheels-dev/wheels/pull/2086)).
- **`consoleeval` hardened:** POST-only, robust IPv6, Content-Type checks ([#2059](https://github.com/wheels-dev/wheels/pull/2059)); constant-time + rate-limited reload ([#2077](https://github.com/wheels-dev/wheels/pull/2077)); hash-based reload password ([#2022](https://github.com/wheels-dev/wheels/pull/2022)).
- **`allowEnvironmentSwitchViaUrl`** default false in prod ([#2076](https://github.com/wheels-dev/wheels/pull/2076)); non-empty reload password required ([#2082](https://github.com/wheels-dev/wheels/pull/2082)).

### 8. CLI and MCP — AI-era attack surface
- **CLI shell sanitization:** deploy commands ([#2068](https://github.com/wheels-dev/wheels/pull/2068), [#2073](https://github.com/wheels-dev/wheels/pull/2073)); db shell injection ([#2040](https://github.com/wheels-dev/wheels/pull/2040)).
- **MCP hardening:** path traversal ([#2049](https://github.com/wheels-dev/wheels/pull/2049), [#2062](https://github.com/wheels-dev/wheels/pull/2062)); auth gate + input validation ([#2050](https://github.com/wheels-dev/wheels/pull/2050)); error suppression ([#2072](https://github.com/wheels-dev/wheels/pull/2072)); port validation ([#2075](https://github.com/wheels-dev/wheels/pull/2075)); structural allowlist ([#2083](https://github.com/wheels-dev/wheels/pull/2083)); CSRNG session tokens ([#2087](https://github.com/wheels-dev/wheels/pull/2087)).
- Frame: the MCP endpoint is the new untrusted-input boundary in an AI-integrated dev workflow. Treat it like a public API, because it is.

### 9. XSS and view helpers
- **Formalized `h()`, `hAttr()`, `stripTags()`, `stripLinks()`** ([#2097](https://github.com/wheels-dev/wheels/pull/2097)).
- **Pagination XSS hardening** ([#2042](https://github.com/wheels-dev/wheels/pull/2042), [#2057](https://github.com/wheels-dev/wheels/pull/2057), [#2060](https://github.com/wheels-dev/wheels/pull/2060)) — `prependToPage`, `anchorDivider`, `appendToPage` sanitized; HTML-entity bypass closed.
- **SSE newline injection** closed ([#2051](https://github.com/wheels-dev/wheels/pull/2051)).

### 10. Known limitations — honesty section
- Link to [#2078](https://github.com/wheels-dev/wheels/pull/2078) (documented limitations).
- Be explicit about what the framework does NOT claim to solve: app-level authorization, tenant-isolation decisions, post-auth IDOR.
- Point at OWASP checklist mapping (aspirational — call it out as a follow-on if not shipped by publish date).

## Code / config snippets to include (pick 3)

```cfm
// Deny-by-default CORS — opt in to the origins you want
set(middleware = [
    new wheels.middleware.Cors(
        allowOrigins="https://app.example.com",
        allowMethods="GET,POST",
        allowCredentials=true
    )
]);
```

```cfm
// Rate limiter — production-ready defaults
new wheels.middleware.RateLimiter(
    maxRequests=100,
    windowSeconds=60,
    strategy="slidingWindow",
    storage="database",
    trustProxy=true,           // must be set intentionally when behind LB
    proxyStrategy="last"        // last proxy in chain is authoritative
)
```

```cfm
// SecurityHeaders — CSP + HSTS + Permissions-Policy
new wheels.middleware.SecurityHeaders(
    contentSecurityPolicy="default-src 'self'; script-src 'self' 'unsafe-inline'",
    hstsMaxAge=31536000,
    hstsIncludeSubDomains=true,
    permissionsPolicy="geolocation=(), microphone=()"
)
```

## Suggested visuals

- **Category tally bar chart:** 8 categories (SQL, path, session, CORS, rate-limiter, console, MCP, XSS) with PR counts. Shows the breadth.
- **Before / after defaults table:** 6 rows — CORS, HSTS, CSRF key, env-switch URL, reload password, RateLimiter `trustProxy` — showing 3.0 default vs 4.0 default. Screenshot-friendly.

## Outro / CTA

- "Secure-by-default is a posture, not a feature."
- Link to the known-limitations doc.
- Invite responsible disclosure per SECURITY.md.
- Tease post #4 (jobs) — because `RateLimiter` storage=database shares infrastructure with the job queue.

## Citations (must link in final post)

- All PRs linked inline (section 2–9).
- [Feature audit § Security hardening](https://github.com/wheels-dev/wheels/blob/develop/docs/releases/wheels-4.0-audit.md#19-security-hardening-cross-cutting)
- [3.0 → 4.0 comparison § Security posture](https://github.com/wheels-dev/wheels/blob/develop/docs/releases/wheels-3.0-vs-4.0.md#security-posture--40-hardening-prs-in-40)
- Known limitations doc ([#2078](https://github.com/wheels-dev/wheels/pull/2078))
- `docs/src/working-with-wheels/security.md` (if extant)
