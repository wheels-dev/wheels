# Issue #2174: Add an HSTS off-switch to `SecurityHeaders` middleware

## Verdict
FIX NOW

## Summary
`SecurityHeaders` middleware has no clean way to disable its production HSTS auto-default, forcing apps behind TLS-terminating proxies to either duplicate the proxy's header or set `max-age=0` (which clears browser HSTS memory). Add an explicit `hsts` constructor argument so HSTS emission can be turned off outright.

## Root cause
Feature gap. `vendor/wheels/middleware/SecurityHeaders.cfc` (lines 48-51) auto-assigns `max-age=31536000; includeSubDomains` whenever `strictTransportSecurity` is empty *and* the resolved environment is `production`. The only inputs are string-valued, so there is no non-dangerous sentinel for "do not emit this header." Every other header in the component follows the same `Len(value)` gate pattern — empty string disables — but HSTS has a second code path (the production auto-default) that overrides that convention.

The v4 upgrade guide (`web/sites/guides/src/content/docs/v4-0-0-snapshot/upgrading/3x-to-4x.mdx` §2) and security hardening page (`deployment/security-hardening.mdx`) both explicitly document this as a known gap linking back to this issue; the hardening page even has an `<Aside type="caution">` explaining the footgun.

## Files to change
- `vendor/wheels/middleware/SecurityHeaders.cfc` — add new `hsts` constructor argument and gate
- `vendor/wheels/tests/specs/middleware/SecurityHeadersSpec.cfc` — new specs under the `Strict-Transport-Security` describe block
- `web/sites/guides/src/content/docs/v4-0-0-snapshot/deployment/security-hardening.mdx` — update the `<Aside type="caution">` (lines ~94-96) to document the new arg and remove the "no off-switch yet" note; add a row to the constructor arg table (lines ~44-53)
- `web/sites/guides/src/content/docs/v4-0-0-snapshot/upgrading/3x-to-4x.mdx` — update §2 (lines 64-68) to note that `hsts=false` is the supported off-switch
- `CHANGELOG.md` — add entry under `[Unreleased]` → `### Added` (or a new `### Changed` subsection for middleware)

## Implementation steps

1. **Add the argument.** In `SecurityHeaders.cfc::init()`, add a new argument between `strictTransportSecurity` and `permissionsPolicy`:
   ```
   boolean hsts = true
   ```
   Document it in the header comment: `@hsts Set to false to suppress the Strict-Transport-Security header entirely, regardless of environment or strictTransportSecurity value.`

2. **Gate the HSTS emission on it.** Replace the existing HSTS resolution block (lines 48-51 and 68-70) with equivalent logic that short-circuits when `arguments.hsts` is `false`:
   - If `arguments.hsts` is `false`, skip both the auto-default computation and the `variables.headers["Strict-Transport-Security"]` assignment.
   - Otherwise preserve the exact current behavior (explicit value wins; empty + production auto-defaults; empty + non-production omits). No other argument semantics change.

3. **Do not touch the other headers' logic or argument order.** Appending `hsts` at the end of the signature (after `environment`) is also acceptable and avoids perturbing any positional callers, but since all existing middleware call-sites in this repo use named args (verified in `SecurityHeadersSpec.cfc` and `docs/.../security-hardening.mdx`), placing it near `strictTransportSecurity` reads better. Choose one and stay consistent.

4. **Add test coverage.** In `SecurityHeadersSpec.cfc` under `describe("Strict-Transport-Security", ...)` add three new `it()` blocks:
   - `it("omits HSTS header when hsts=false even in production")` — pass `environment="production"` and `hsts=false`; expect `notToHaveKey("Strict-Transport-Security")`.
   - `it("omits HSTS header when hsts=false and explicit strictTransportSecurity provided")` — pass both `strictTransportSecurity="max-age=86400"` and `hsts=false`; expect header absent (explicit off-switch wins over explicit value).
   - `it("defaults hsts=true to preserve legacy production behavior")` — `environment="production"` with no `hsts` arg; expect the auto-default string (redundant with existing test but locks in backcompat intent).

5. **Update the security-hardening guide.**
   - In the constructor-arg table (around line 44-53), add a row for `hsts` with header column `—`, default `true`, source `new`.
   - Rewrite the `<Aside type="caution">` around line 94-96 from "no off-switch yet" into a positive note: "To suppress HSTS entirely (for example, when the reverse proxy already emits it), pass `hsts=false`." Remove the `#2174` reference.
   - Optionally add a short code block showing the off-switch pattern next to the existing preload example.

6. **Update the upgrade guide.** In `3x-to-4x.mdx` §2 (line 68), replace the "there is currently no clean off-switch — see #2174. The workaround until that lands is to strip `Strict-Transport-Security` at your reverse proxy." sentence with: "To suppress HSTS emission from the app (e.g., when your load balancer already sets it), pass `hsts=false` to the middleware constructor."

7. **CHANGELOG.** Under `## [Unreleased]` → `### Added` append (wording to match surrounding entries):
   ```
   - `hsts` argument on `SecurityHeaders` middleware to suppress the `Strict-Transport-Security` header entirely, for apps behind TLS-terminating proxies that emit HSTS themselves (#2174)
   ```

8. **Commit message:** scope is `middleware` per repo convention (not `security`).
   ```
   feat(middleware): add hsts off-switch to SecurityHeaders
   ```

## Testing

Unit — extend `SecurityHeadersSpec.cfc` as above. Run locally:
```
bash tools/test-local.sh middleware
```
Confirm 3 new specs pass, no regressions in the existing `Strict-Transport-Security` describe block, and all `disabling headers` / `default headers` specs still pass. Then run the full core suite once:
```
bash tools/test-local.sh
```

Manual — in a dev app, register the middleware with `hsts=false`, hit an endpoint with `curl -I`, confirm `Strict-Transport-Security` is absent. Repeat with default args in production mode, confirm header present.

Cross-engine — nothing engine-specific is added (plain boolean arg, `Len()` + conditional assignment), but still verify against the Adobe 2025 and Lucee 7 containers before merge since this is a security-surface middleware.

## Risk & dependencies

- **Backwards compatibility.** `hsts=true` is the default, so all existing callers (including the `MiddlewarePipelineSpec.cfc` integration test and every doc example) keep current behavior byte-for-byte. No migration required.
- **Docs drift.** Three doc surfaces currently link to #2174 as an open gap. All three must be updated in the same PR to avoid stale references.
- **Alternative considered: sentinel string.** The issue author suggests `strictTransportSecurity="none"` as an alternative. Reject: sentinels in a free-form string argument are error-prone (typos silently enable the auto-default) and the argument is supposed to pass through verbatim to the HTTP header. A dedicated boolean is clearer and discoverable via argument introspection.
- **Struct-shaped `hsts` (issue author's secondary suggestion).** Not worth it. The existing `strictTransportSecurity` string already lets callers compose any valid directive (`max-age=…; includeSubDomains; preload`), and adding a parallel struct form doubles the surface area with no new capability. Stick with boolean-only.
- **No new dependencies. No cross-engine concerns.** Pure CFC change.

## Effort estimate
S
