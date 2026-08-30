# Wheels Application Reference (AI)

Bundled subset of the framework's AI reference docs, shipped with every
distribution (`box install wheels`, ForgeBox starter app, `wheels new`
scaffolds). It covers what an AI assistant needs while building an
APPLICATION on Wheels — nothing about framework internals.

- `../CLAUDE.md` — application-developer quick reference (models, routing,
  views, middleware, DI, packages, CLI, testing, migrations, jobs, SSE).
- `../AGENTS.md` — cross-tool workflow guidance (MCP-first, conventions).

## Deeper content

The full maintainer reference set (cross-engine compatibility, test
infrastructure, release engineering) intentionally does NOT ship here.
For deeper application-side material use:

- https://guides.wheels.dev — human guides (mirrored sections: basics,
  core-concepts, testing, deployment, upgrading).
- `/wheels/ai` on a running app — JSON docs optimized for AI consumption:
  `GET /wheels/ai?mode=manifest`, `?mode=chunk&id=<models|controllers|views|
  migrations|routing|testing|cli|patterns>`, `?context=<area>`.
