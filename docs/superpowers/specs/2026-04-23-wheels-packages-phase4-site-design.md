# `packages.wheels.dev` Static Site — Design

**Status:** draft
**Date:** 2026-04-23
**Issue:** [#2271](https://github.com/wheels-dev/wheels/issues/2271) (Phase 4 of [#2243](https://github.com/wheels-dev/wheels/issues/2243))
**Supersedes:** the wheels.dev-path components in [`2026-04-23-wheels-packages-phase4-ui-design.md`](./2026-04-23-wheels-packages-phase4-ui-design.md) (deferred there)

## Summary

Ship `packages.wheels.dev` as the fifth sibling to the existing `wheels.dev` / `blog.wheels.dev` / `guides.wheels.dev` / `api.wheels.dev` subdomains. Astro static site at `web/sites/packages/`, deployed to Cloudflare Pages project `wheels-packages`, rebuilt automatically when `wheels-dev/wheels-packages` changes via `repository_dispatch`. Pages:

- `/` — card grid of all packages with client-side text filter
- `/[name]` — package detail with version history + rendered README

Closes the wheels.dev half of #2271. (The in-app `/wheels/packages` half shipped in [#2277](https://github.com/wheels-dev/wheels/pull/2277).)

## Why a subdomain (not a path on apex)

Four of the five wheels.dev surfaces already live on subdomains (`blog`, `guides`, `api`, plus the apex `landing`). A new top-level surface should match the pattern:

- Independent deploy cycle. Registry merges rebuild only this site; landing-page edits don't touch it.
- Independent CF Pages project (`wheels-packages`), own preview URLs, own custom domain.
- Cleaner `repository_dispatch` trigger — lands on one CF project, not a multi-site rebuild.
- Room to grow (per-package stats, author pages) without landing-site coupling.

## Current state

| Piece | Status |
|---|---|
| `wheels-dev/wheels-packages` registry | ✅ Live. 4 packages + manifests + mirrored tarballs. |
| In-app `/wheels/packages` "Browse registry" | ✅ Shipped in #2277. |
| `web/sites/packages/` Astro site | ❌ Does not exist. |
| `wheels-packages` → `wheels` rebuild trigger | ❌ Does not exist. |
| CF Pages project `wheels-packages` + DNS | ❌ Needs one-time manual setup before first deploy. |

## Design decisions

### D1. Rebuild trigger — `repository_dispatch` (Option A)

Chosen over periodic schedule or both. Fires within seconds of a registry merge; no polling lag; the plumbing is ~20 lines of YAML + one fine-grained PAT secret.

### D2. Markdown rendering — `unified` + `remark` + `rehype` (Option B)

Matches Astro's internal toolchain so READMEs render with the same typography and code highlighting as the rest of the wheels.dev ecosystem. `rehype-sanitize` with `defaultSchema` is correct-by-default; `rehype-shiki` gives us code blocks for free. Rejected `marked` (needs manual sanitization setup) and `markdown-it` (middle ground with no specific advantage).

### D3. Listing layout — card grid (Option B)

Matches conventions of public package registries (npm, crates.io, rubygems, pkg.go.dev). Better for a public discovery surface where visitors are browsing rather than comparing — contrast with the in-app table view, which is a developer tool. Scales fine to the realistic ceiling (~40 packages).

### D4. Build-time fetching, no runtime cache

Everything is baked at `astro build`. No runtime cache to invalidate; no stale-fallback UI to design. If GitHub fails during build, the build fails, and Cloudflare serves the prior deploy. Failure mode is "momentarily stale data," not "500 to users."

## Architecture

```
wheels-dev/wheels-packages (registry)
  │ push to main (paths: packages/** | schema/**)
  ▼
wheels-packages/.github/workflows/notify-site.yml
  │ repository_dispatch: event_type=registry-updated
  ▼
wheels-dev/wheels/.github/workflows/web-deploy.yml
  │ matrix slot: packages only (guarded by github.event_name check)
  ▼
Astro build of web/sites/packages/
  │ frontmatter: await fetch(GH contents API) → list package dirs
  │              await fetch(raw manifests) → get each manifest
  │              await fetch(raw READMEs) → render via unified pipeline
  │                (remark-parse → remark-gfm → remark-rehype
  │                 → rehype-sanitize → rehype-shiki → rehype-stringify)
  ▼
dist/ → wrangler pages deploy → packages.wheels.dev
```

## Components

### 1. Site skeleton — `web/sites/packages/`

Modeled after `web/sites/blog/`.

| File | Purpose |
|---|---|
| `package.json` | `@wheels-dev/site-packages`, dev port `4325` (next after api at 4324), deps: `astro`, `@wheels-dev/ui: workspace:*`, `unified`, `remark-parse`, `remark-gfm`, `remark-rehype`, `rehype-sanitize`, `@shikijs/rehype`, `rehype-stringify`, `@astrojs/sitemap` |
| `astro.config.mjs` | `site: 'https://packages.wheels.dev'`, sitemap integration |
| `tsconfig.json` | Copy from blog |
| `public/` | Minimal — favicon, robots.txt |
| `src/layouts/BaseLayout.astro` | Reuses `@wheels-dev/ui` Header/Footer/Logo, same typography tokens as blog |
| `src/lib/registry.ts` | Build-time registry fetcher |
| `src/lib/markdown.ts` | Unified pipeline for README rendering |
| `src/components/PackageCard.astro` | Card grid item |
| `src/pages/index.astro` | Listing page (card grid) |
| `src/pages/[name].astro` | Detail page (dynamic route via `getStaticPaths()`) |

### 2. Data layer — `src/lib/registry.ts`

Sibling of the CLI's `Registry.cfc`. Fetch only — no cache, builds are one-shot.

```ts
export interface Manifest {
  name: string;
  description: string;
  homepage?: string;
  tags?: string[];
  versions: Array<{
    version: string;
    publishedAt: string;
    wheelsVersion: string;
    sourceTag: string;
    tarball: string;
    sha256: string;
  }>;
}

export interface PackageSummary {
  name: string;
  description: string;
  homepage: string;
  tags: string[];
  latestVersion: string;
  publishedAt: string;
}

const REPO = process.env.WHEELS_PACKAGES_REGISTRY ?? 'wheels-dev/wheels-packages';
const BRANCH = 'main';

export async function listPackageNames(): Promise<string[]> {
  // GET https://api.github.com/repos/${REPO}/contents/packages?ref=${BRANCH}
  // Filter entries where type === 'dir'. Sort ascending.
}

export async function fetchManifest(name: string): Promise<Manifest> {
  // GET https://raw.githubusercontent.com/${REPO}/${BRANCH}/packages/${name}/manifest.json
  // Throw on non-200. Throw if result lacks required keys.
}

export async function fetchReadme(name: string): Promise<string> {
  // GET https://raw.githubusercontent.com/${REPO}/${BRANCH}/packages/${name}/README.md
  // Throw on non-200.
}

export async function listAll(): Promise<PackageSummary[]> {
  const names = await listPackageNames();
  const manifests = await Promise.all(names.map(fetchManifest));
  return manifests.map(m => ({
    name: m.name,
    description: m.description ?? '',
    homepage: m.homepage ?? '',
    tags: m.tags ?? [],
    latestVersion: m.versions.at(-1)!.version,
    publishedAt: m.versions.at(-1)!.publishedAt,
  }));
}
```

**Fail-loud:** any non-200 throws. Build fails → Cloudflare keeps prior deploy.

### 3. Markdown rendering — `src/lib/markdown.ts`

```ts
import { unified } from 'unified';
import remarkParse from 'remark-parse';
import remarkGfm from 'remark-gfm';
import remarkRehype from 'remark-rehype';
import rehypeSanitize, { defaultSchema } from 'rehype-sanitize';
import rehypeShiki from '@shikijs/rehype';
import rehypeStringify from 'rehype-stringify';

export async function renderMarkdown(src: string): Promise<string> {
  const file = await unified()
    .use(remarkParse)
    .use(remarkGfm)
    .use(remarkRehype)
    .use(rehypeSanitize, defaultSchema)
    .use(rehypeShiki, { themes: { light: 'github-light', dark: 'github-dark' } })
    .use(rehypeStringify)
    .process(src);
  return String(file);
}
```

`rehype-sanitize` with `defaultSchema` strips `<script>`, `on*=` attributes, and `javascript:`/`data:` URL schemes in links.

### 4. Listing page — `src/pages/index.astro`

Responsive grid (1 col mobile / 2 col tablet / 3 col desktop). Each `PackageCard` shows:
- Package name (headline, links to detail)
- Latest version pill
- Description
- Tag chips
- Install snippet `wheels packages install <name>` + Copy button with 2-second "Copied!" feedback

Above the grid: page title "Wheels packages", one-sentence subhead, client-side text filter `<input>` that toggles `[data-match]` on cards. No server-side search.

### 5. Detail page — `src/pages/[name].astro`

`getStaticPaths()` enumerates packages from registry at build time, fetching manifest + rendered README per path.

Layout:
- Breadcrumb "Packages / &lt;name&gt;"
- H1 name, latest version badge, tag chips, homepage link (filtered `^https?://`)
- Install snippets (latest + `@<version>` pinned) with Copy buttons
- Version history table: version / published date / wheelsVersion constraint / sha256 (first 12 chars, tooltip showing full hash)
- Rendered README under `<article class="prose">` — inherits typography from `@wheels-dev/ui`

### 6. Deploy workflow — edits to `.github/workflows/web-deploy.yml`

Add trigger:
```yaml
on:
  push:
    branches: [develop]
    paths: ['web/**', '.github/workflows/web-deploy.yml']
  pull_request:
    branches: [develop]
    paths: ['web/**', '.github/workflows/web-deploy.yml']
  repository_dispatch:
    types: [registry-updated]
```

Add `packages` to matrix; gate registry-triggered runs to only rebuild `packages`:
```yaml
strategy:
  fail-fast: false
  matrix:
    site: ${{ github.event_name == 'repository_dispatch' && fromJSON('["packages"]') || fromJSON('["landing", "blog", "guides", "api", "packages"]') }}
```

(If the ternary-via-`fromJSON` expression is awkward under YAML parsing, fall back to a separate job with `if: github.event_name == 'repository_dispatch'` invoking the same build steps.)

### 7. Notify workflow — new file in `wheels-dev/wheels-packages`

`.github/workflows/notify-site.yml`:
```yaml
name: Notify wheels.dev site

on:
  push:
    branches: [main]
    paths: ['packages/**', 'schema/**']

jobs:
  notify:
    runs-on: ubuntu-latest
    steps:
      - name: Fire repository_dispatch at wheels-dev/wheels
        env:
          GH_TOKEN: ${{ secrets.NOTIFY_WHEELS_TOKEN }}
        run: |
          gh api repos/wheels-dev/wheels/dispatches \
            --method POST \
            --field event_type=registry-updated \
            --field "client_payload[source_commit]=${GITHUB_SHA}"
```

`NOTIFY_WHEELS_TOKEN`: fine-grained PAT scoped to `wheels-dev/wheels` with `contents:write` (required for `repository_dispatch`). One-time setup — create PAT, store as repo secret in `wheels-dev/wheels-packages`. Document in registry's `CONTRIBUTING.md`.

## Error handling

| Condition | Build behavior | User behavior |
|---|---|---|
| GitHub 200 on everything | Build succeeds | Fresh site deployed |
| GitHub 403 (rate-limit) / 5xx | Build fails loudly | Cloudflare keeps prior deploy; Actions log shows reason |
| Single malformed manifest | `fetchManifest()` throws → build fails | Same as above. **No silent-skip** at the site layer — broken manifests are registry defects that should block a deploy. (Contrasts with the in-app page, which degrades gracefully because it's dev-only and must not 500.) |
| README contains malicious HTML | `rehype-sanitize` strips | Rendered safely |
| Homepage URL present but unreachable | N/A — we just emit the anchor | Browser 404s when clicked |
| `repository_dispatch` fails to deliver (e.g. token expired) | Registry merge still succeeds | Site stays at prior version; failure visible in `wheels-packages` Actions log |

## Testing

- **Unit** — `web/tests/packages/registry.test.ts` + `markdown.test.ts`. Match the test runner the `web/` workspace already uses (vitest or node:test — confirm during impl). Fake `fetch` via `undici` `MockAgent` or a simple function stub. Coverage: list success, manifest success, README success, non-200 throws, env-var override (`WHEELS_PACKAGES_REGISTRY`), sanitizer strips `<script>` / `javascript:` URLs.
- **Visual regression** — add baselines for `/` (listing) and `/wheels-sentry` (one detail page) under `web/tests/visual-baselines/`. Existing `pnpm visual:test` harness picks up new baselines; first PR run fails the visual job, download the diffs artifact, commit the `.actual.png` files as baselines per the workflow's documented recovery.
- **No live-network tests.**

## Security

- Only the hardcoded registry repo is contacted by `fetch`. Env-var override (`WHEELS_PACKAGES_REGISTRY`) allows forks/mirrors but the value is a repo slug, never a full URL.
- Rendered Markdown goes through `rehype-sanitize` with `defaultSchema` — blocks `<script>`, inline event handlers, `javascript:` / `data:` URL schemes.
- Homepage links filtered to `^https?://` before emitting an anchor.
- Copy-button JS uses `navigator.clipboard.writeText` with `JSON.stringify()`-escaped package names (constrained to `[a-z0-9-]` by registry schema — defense-in-depth).
- `NOTIFY_WHEELS_TOKEN` is fine-grained, scoped to one repo with minimum required permissions. Not shared across workflows.

## Build sequence

Two PRs, ordered:

1. **`wheels-dev/wheels` PR** — adds `web/sites/packages/`, edits `web-deploy.yml`, adds unit tests and visual baselines. **Does not merge** until CF Pages project `wheels-packages` exists in the wheels.dev CF account and `packages.wheels.dev` DNS is attached (otherwise the `wrangler pages deploy` step errors on first run).
2. **`wheels-dev/wheels-packages` PR** — adds `notify-site.yml` + `CONTRIBUTING.md` note for the token secret. Can merge any time after PR 1 goes live. Earlier is harmless — dispatch silently drops if the target workflow isn't set up yet.

**One-time manual prep** (call out in PR 1 description):
1. Create fine-grained PAT (`NOTIFY_WHEELS_TOKEN`) scoped to `wheels-dev/wheels` with `contents:write`
2. Add it as a repo secret in `wheels-dev/wheels-packages`
3. Create CF Pages project `wheels-packages`, attach `packages.wheels.dev` custom domain

## Out of scope (explicit YAGNI)

- RSS feed for new package versions
- "Recently updated" / "Most popular" rails
- User accounts, stars, download counts
- Search-as-you-type with Algolia — client-side filter is enough
- Per-version detail pages (`/[name]/[version]`) — version history table covers it
- Package author profiles (`/@username`)
- Publish-from-web flow — PRs to `wheels-packages` remain the contribution path
- i18n
- Dark-mode toggle beyond what `@wheels-dev/ui` already ships

## Open items (non-blocking, resolve during impl)

- Confirm `@wheels-dev/ui` `Header` supports a dynamic nav entry for the new subdomain, or whether cross-site links need to be added to the shared component in a follow-up PR.
- Confirm the `web/` workspace's test runner (vitest vs node:test) and match it for the new specs.
- Confirm whether the visual-regression harness auto-picks new sites or needs a config change.
