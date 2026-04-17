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

Cloudflare Pages watches this repo and builds each site when files under its
path change. See the project dashboard for per-site build settings.
