# Wheels Framework Reference Docs

Deep reference for maintainers and contributors. Claude Code searches this
tree on demand — see the root `CLAUDE.md` for the always-loaded invariants
and the "Reference Docs" index at its end.

> The APPLICATION-developer doc tier (shipped in every distribution) lives
> in `docs/consumer-ai/` — keep the two tiers separate.

## Wheels Framework (`wheels/`)

Directories:

- `channels/` — WebSocket-style channels and the Channel component
- `controllers/` — controller patterns (API controllers)
- `security/` — security topics (HTTPS detection)
- `snippets/` — model/controller snippet libraries
- `testing/` — browser testing, onboarding harness
- `troubleshooting/` — common errors, form helper errors, shared-dev DBs
- `views/` — view-layer patterns (query/association loops)

Files:

- `cross-engine-compatibility.md` — engine gotchas (Lucee/Adobe/BoxLang differences)
- `deploy.md` — `wheels deploy` (Kamal port)
- `wheels-bot.md` — wheels-bot architecture

## CFML Language (`cfml/`)

Subdirectories: advanced, best-practices, components, control-flow, data-types, database, syntax.

The `.ai/cfml/README.md` lists each area in detail.

## Conventions

- Every file is a focused topic page; add links from `CLAUDE.md`'s
  "Reference Docs" section when you add one.
- Don't duplicate the auto-loaded `CLAUDE.md` invariants here — link them
  instead (`cross-engine-compatibility.md` is the deep version).
