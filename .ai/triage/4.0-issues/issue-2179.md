# Issue #2179: v4 guides: add 301 redirects for pre-cutover URLs (cli-reference → command-line-tools)

## Verdict
FIX NOW

Low-risk, ~10 minutes of work, should land before 4.0 GA so the snapshot URL surface is stable once external links start accumulating. The issue self-assesses as "Low — safe to land post-merge" but the cost to do it now is trivial and it closes out a known gap from the PR #2169 design doc. No discussion needed.

## Summary
The v4 guides rewrite (PR #2169) cutover design promised 301 redirects from legacy URLs to their Starlight equivalents, but `web/sites/guides/astro.config.mjs` ships no `redirects` config. The one confirmed live restructure — Phase 0 preview at `/v4-0-0-snapshot/cli-reference/` retired in favor of `/v4-0-0-snapshot/command-line-tools/` — currently 404s for any bookmark or backlink.

## Root cause
During the Phase 0 → Phase 2b guides rewrite, a small preview directory at `/v4-0-0-snapshot/cli-reference/` (containing `index.mdx` and `info.mdx`) was removed and superseded by a 103-page tree at `/v4-0-0-snapshot/command-line-tools/`. The new path ships in `develop`; the old path returns 404 on guides.wheels.dev. The v4 design doc (`docs/superpowers/specs/2026-04-18-guides-rewrite-v4-design.md` §"Cutover") explicitly called for 301s from legacy URLs to new Starlight equivalents, but no redirect configuration was ever added to the site. Confirmed in-tree: grep finds zero `redirects` references in `web/sites/guides/**`, and only `/v4-0-0-snapshot/command-line-tools/` exists today.

## Files to change
- `web/sites/guides/astro.config.mjs` — add `redirects` map to the `defineConfig({ ... })` object. Astro's built-in redirects map emits static HTML redirect pages at build time (works with Cloudflare Pages static hosting; no `_redirects` file needed). This matches the approach explicitly suggested in the issue body.

No sidebar changes needed — `src/sidebars/v4-0-0-snapshot.json` already points at `/v4-0-0-snapshot/command-line-tools/*` (confirmed by directory listing of current v4 docs tree).

## Implementation steps

1. **Confirm the old URL surface.** From the issue: two files existed in Phase 0 preview, `cli-reference/index.mdx` and `cli-reference/info.mdx`. They are gone from `develop` (verified). Also sanity-check the v4 sidebar JSON:
   ```bash
   grep -r 'cli-reference' web/sites/guides/
   ```
   Should return zero hits inside `web/sites/guides/` (only v2/v3 content mentioning the word "redirect" unrelated to routing). If any v4 sidebar or MDX still references `/v4-0-0-snapshot/cli-reference/*`, those links need fixing separately (out of scope for this issue).

2. **Add the redirect map to `astro.config.mjs`.** Inside the `defineConfig({...})` object, alongside `site` and `integrations`, add:
   ```js
   redirects: {
     '/v4-0-0-snapshot/cli-reference': '/v4-0-0-snapshot/command-line-tools/',
     '/v4-0-0-snapshot/cli-reference/info': '/v4-0-0-snapshot/command-line-tools/',
     '/v4-0-0-snapshot/cli-reference/[...slug]': '/v4-0-0-snapshot/command-line-tools/[...slug]',
   },
   ```
   - Entry 1: root `/cli-reference` → new root (trailing-slash consistency: match Starlight's default — the new tree's `index.mdx` resolves at `/command-line-tools/`).
   - Entry 2: `info` was one of two Phase 0 sample files; point it at the new section root (there is no 1:1 successor page).
   - Entry 3: wildcard `[...slug]` catches any other remembered deep link (e.g. cached crawler URLs) and attempts a same-slug lookup under the new tree. If no target file exists, Astro still emits a 301; Cloudflare then serves Starlight's 404 page at the new path — acceptable since the new tree is the authoritative location.

3. **Confirm Astro redirects syntax against local Astro version.** `package.json` pins `astro: ^5.1.0`. Astro 5 supports the top-level `redirects` option (docs: <https://docs.astro.build/en/reference/configuration-reference/#redirects>). Default status is 301 (permanent) for string-valued entries — which is what we want. No extra config needed.

4. **Build locally and verify the redirect HTML pages exist.**
   ```bash
   pnpm --filter @wheels-dev/site-guides build
   ls web/sites/guides/dist/v4-0-0-snapshot/cli-reference/
   # expect: index.html containing <meta http-equiv="refresh" ...> and canonical redirect
   ```
   Astro generates a static HTML page per redirect with a meta-refresh + `<link rel="canonical">` + a 301 `http-equiv` header hint. Cloudflare Pages serves these as 200-with-redirect-HTML by default; if true 301 status is required, see Risk section.

5. **Smoke test with dev server.**
   ```bash
   pnpm --filter @wheels-dev/site-guides dev
   # in another terminal:
   curl -sI 'http://localhost:4323/v4-0-0-snapshot/cli-reference' | head -20
   curl -sI 'http://localhost:4323/v4-0-0-snapshot/cli-reference/info' | head -20
   curl -sI 'http://localhost:4323/v4-0-0-snapshot/cli-reference/commands/generate' | head -20
   ```
   Astro dev server returns a real 301 for redirect entries. Confirm `Location:` header points at the expected `/command-line-tools/*` target.

6. **Commit, push, let `web-deploy.yml` deploy to Cloudflare Pages preview**, then re-run curl against the preview URL to confirm production behavior. Cloudflare Pages with Astro's static-redirect output returns HTTP 200 with meta-refresh HTML; if 3xx status on the wire is required (e.g. strict SEO), add a matching `public/_redirects` file (Cloudflare-native, wire-level 301) — see Risk section below.

7. **Commit message**: `docs(docs): add 301 redirects for retired /v4-0-0-snapshot/cli-reference paths`. Scope is `docs` per CLAUDE.md (web-side docs changes). Reference issue in body: `Closes #2179`.

## Testing

Local (post step 5):
```bash
# Expect 301 with Location header pointing at command-line-tools
curl -sI 'http://localhost:4323/v4-0-0-snapshot/cli-reference'      | grep -iE 'HTTP|Location'
curl -sI 'http://localhost:4323/v4-0-0-snapshot/cli-reference/info' | grep -iE 'HTTP|Location'

# Wildcard: any cli-reference deep path should redirect to the same slug under command-line-tools
curl -sI 'http://localhost:4323/v4-0-0-snapshot/cli-reference/foo/bar' | grep -iE 'HTTP|Location'

# New paths still render (regression check)
curl -sI 'http://localhost:4323/v4-0-0-snapshot/command-line-tools/' | grep -iE 'HTTP'
```

Cloudflare preview (post step 6): same three curls against `https://<preview>.guides-wheels-dev.pages.dev`. If meta-refresh HTML is returned (200 status with refresh tag), that's the expected Astro-static behavior and search engines honor it. Document this in the PR description so reviewers don't flag it as "not a real 301."

## Risk & dependencies
- **No visual regression** — redirects don't render UI; sidebar, layouts, custom components all untouched.
- **Astro static redirect vs. wire-level 301.** Astro's default static adapter emits HTML redirect pages (200 + meta-refresh + canonical), not 3xx wire responses. This is fine for SEO (Google honors meta-refresh with canonical as a soft 301) and for humans (browser follows immediately). If a true wire-level 301 is required, add a parallel `web/sites/guides/public/_redirects` file with Cloudflare Pages syntax:
  ```
  /v4-0-0-snapshot/cli-reference         /v4-0-0-snapshot/command-line-tools/   301
  /v4-0-0-snapshot/cli-reference/info    /v4-0-0-snapshot/command-line-tools/   301
  /v4-0-0-snapshot/cli-reference/*       /v4-0-0-snapshot/command-line-tools/:splat   301
  ```
  Recommend shipping *only* the Astro `redirects` config first — it's declarative, version-controlled, and visible in the Astro config. Escalate to `_redirects` only if a subsequent SEO audit shows the meta-refresh pages hurting.
- **Related PRs**: #2169 (the cutover that removed cli-reference), #2190 (`39a7cbbe8` — added command-line-tools/commands/deploy/* after cutover; no URL renames, only additions, so no further redirect pairs required from that PR).
- **No dependencies on other open issues.** Fix is self-contained to `astro.config.mjs`.
- **CI check**: `docs-verify.yml` runs `verify:docs` — that script walks MDX content, not built HTML, so it won't regress from adding redirect entries. `web-deploy.yml` matrix builds guides site normally; a successful build confirms Astro accepted the `redirects` map.

## Effort estimate
S (≤30 min including local build + curl verification + PR).

## Open questions
- None blocking. If someone wants to belt-and-suspenders the SEO story, add `public/_redirects` alongside; otherwise ship Astro-only.
