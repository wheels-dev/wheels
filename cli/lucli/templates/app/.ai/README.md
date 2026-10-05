# Wheels Application Reference (AI)

Bundled subset of the framework's AI reference docs, shipped with every
distribution (`box install wheels`, ForgeBox starter app, `wheels new`
scaffolds). It covers what an AI assistant needs while building an
APPLICATION on Wheels — nothing about framework internals.

- `../CLAUDE.md` — application-developer quick reference (models, routing,
  views, middleware, DI, packages, CLI, testing, migrations, jobs, mail, SSE).
- `../AGENTS.md` — cross-tool workflow guidance (MCP-first, conventions).
- `models.md` — models: finders, associations, validations, callbacks, scopes.
- `routing.md` — routing and route model binding.
- `api.md` — JSON APIs: the api-resource generator, renderWith, status codes, pagination, UTC timestamps.
- `views.md` — pagination helpers and the development error page.
- `caching.md` — partial caching.
- `middleware.md` — middleware and rate limiting.
- `di.md` — the DI container.
- `auth.md` — authentication and authorization.
- `storage.md` — storage disks, deleting files, files that belong to records.
- `packages.md` — the package system.
- `migrations.md` — migrations and seeding.
- `jobs.md` — background jobs.
- `mailers.md` — sending email: mailers, SMTP settings, testing a mailer.
- `sse.md` — server-sent events and channels (publish/subscribe, authorising subscribers).
- `testing.md` — changing framework settings inside a spec, and testing partial caching.
- `upgrading.md` — `wheels upgrade check` and the APIs that changed in 4.x.

## Deeper content

The full maintainer reference set (cross-engine compatibility, test
infrastructure, release engineering) intentionally does NOT ship here.
For deeper application-side material use:

- https://guides.wheels.dev — human guides (mirrored sections: basics,
  core-concepts, testing, deployment, upgrading).
- `/wheels/ai` on a running app — JSON docs optimized for AI consumption:
  `GET /wheels/ai?mode=manifest`, `?mode=chunk&id=<models|controllers|views|
  migrations|routing|testing|cli|patterns>`, `?context=<area>`.

## Where to go deeper

- Human guides: https://guides.wheels.dev (start-here, core-concepts, testing, deployment)
- Framework API reference: `/wheels/ai` endpoints on any running app
  — JSON docs optimized for AI consumption.
- Offline API and guides lookup, no server needed: `wheels lookup findAll`,
  `wheels lookup "nested resources"` (MCP tool: `lookup`).
- MCP: `wheels new` writes `.mcp.json` and `.opencode.json` (skip with `--no-agents`); in an
  existing app, run `wheels setup agents` to write them (or add `{"mcpServers":{"wheels":{"command":"wheels","args":["mcp","wheels"]}}}` by hand)
  and prefer `mcp__wheels__*` tools over CLI commands.
