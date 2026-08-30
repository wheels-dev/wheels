# AGENTS.md

Guidance for AI coding assistants working on a **Wheels application**.
Loaded by all agentic tools (Claude Code, Cursor, Copilot, Codex, …) —
Claude Code also reads the more detailed `CLAUDE.md` next to this file.

## Workflow

1. **Prefer the Wheels MCP server when `.mcp.json` is configured.**
   `wheels` MCP tools (`generate`, `migrate`, `routes`, `test`, `seed`,
   `doctor`, `validate`, …) run against THIS project with correct
   conventions — prefer them over raw `wheels` CLI invocations and over
   hand-writing framework plumbing.
2. **Load context on demand.** Read the relevant section of `CLAUDE.md`
   (models, routing, views, middleware, migrations, jobs) for the task at
   hand instead of guessing at conventions.
3. **Follow the conventions table** — `config()` for associations and
   filters, singular PascalCase models, plural controllers/tables,
   `params.key` accessors, migrations for schema changes.
4. **Verify with tests.** After changes, run the affected specs:
   `wheels test tests/specs/<area>`.

## Conventions (summary)

- Models extend `"Model"`, controllers extend `"Controller"`, specs extend `"wheels.WheelsTest"`.
- Associations/validations/callbacks and controller filters go in `config()`.
- Never mix positional and named arguments in framework calls.
- Migrations use direct SQL via `execute()` for seed data; `CURRENT_TIMESTAMP` for portable dates.
- `timestamps()` adds `createdAt`, `updatedAt`, AND `deletedAt` — don't add duplicates.
- Controller filters must be `private` (public = routable action).
- `cfparam` every variable a view reads.

## Where to look for more

- `CLAUDE.md` — the full application-developer quick reference shipped with the framework.
- `.ai/README.md` — index of the bundled reference subset.
- https://guides.wheels.dev — the human documentation site (start-here, core-concepts, testing, deployment).
- `/wheels/ai` — JSON documentation endpoints on a running app (see `docs/AI_INTEGRATION_GUIDE.md`).
