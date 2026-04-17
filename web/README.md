# wheels.dev Static Sites

Monorepo for the four static sites served under the `wheels.dev` apex and subdomains:

| Site    | Path             | Domain              |
| ------- | ---------------- | ------------------- |
| Landing | `sites/landing/` | `wheels.dev`        |
| Guides  | `sites/guides/`  | `guides.wheels.dev` |
| API     | `sites/api/`     | `api.wheels.dev`    |
| Blog    | `sites/blog/`    | `blog.wheels.dev`   |

Shared UI lives in `packages/ui/` (imported as `@wheels-dev/ui`).

## Local development

```bash
pnpm install
pnpm dev:blog       # or dev:landing, dev:guides, dev:api
```

## Build

```bash
pnpm build          # builds all four sites
```

## Deploy

Deploys are driven by `.github/workflows/web-deploy.yml`, a matrix job that
runs on push to `develop` (production) and on pull requests (preview). Each
site uploads to its own Cloudflare Pages project via `wrangler pages deploy`.
Path filters ensure the workflow only runs when `web/**` or the workflow
file itself changes.

## Deployed environments

| Site    | Custom domain       | Cloudflare Pages project | Canonical Pages URL        |
| ------- | ------------------- | ------------------------ | -------------------------- |
| Landing | _(Phase 4 cutover)_ | `wheels-landing`         | `wheels-landing.pages.dev` |
| Blog    | `blog.wheels.dev`   | `wheels-blog`            | `wheels-blog.pages.dev`    |
| Guides  | `guides.wheels.dev` | `wheels-guides`          | `wheels-guides.pages.dev`  |
| API     | `api.wheels.dev`    | `wheels-api`             | `wheels-api.pages.dev`     |

Production deploys (on push to `develop`) update each site's canonical URL
and corresponding custom domain. PR preview deploys get a unique
`<hash>.<project>.pages.dev` URL and a persistent branch alias of the form
`<slugified-branch>.<project>.pages.dev`.

The apex domain (`wheels.dev`) continues to serve the CFWheels wheels.dev
app until Phase 4 of the static-site migration. The `wheels-landing`
project exists and deploys on every push, but no custom domain is attached
yet — preview via the `*.pages.dev` URL.

## CI secrets required

The deploy workflow needs two repo secrets (see
`.github/workflows/web-deploy.yml`):

- `CLOUDFLARE_API_TOKEN` — Pages:Edit on the wheels.dev CF account
- `CLOUDFLARE_ACCOUNT_ID` — `511d04f367103ec276d875ab41a24dea`
