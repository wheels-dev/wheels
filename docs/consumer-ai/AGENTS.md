# AGENTS.md

Guidance for AI coding assistants working on a **Wheels application**.
Loaded by all agentic tools (Claude Code, Cursor, Copilot, Codex, …) —
Claude Code also reads the more detailed `CLAUDE.md` next to this file.

## Workflow

1. **Prefer the Wheels MCP tools when your client exposes them.**
   `wheels` MCP tools (`generate`, `migrate`, `routes`, `test`, `seed`,
   `doctor`, `validate`, …) run against THIS project with correct
   conventions — prefer them over raw `wheels` CLI invocations and over
   hand-writing framework plumbing. A new app has no MCP config yet: run
   `wheels setup agents` to write `.mcp.json` and `.opencode.json`, or add
   `{"mcpServers":{"wheels":{"command":"wheels","args":["mcp","wheels"]}}}`
   to your client's config yourself. Until then, use the `wheels` CLI.
2. **Load context on demand.** `CLAUDE.md` is short: conventions, common
   mistakes, testing, and a topic index. When the task reaches a topic
   (models, routing, views, middleware, migrations, jobs, …), open its file
   from the index, e.g. `cat .ai/models.md`, instead of guessing at
   conventions. Don't read every topic file up front.
3. **Follow the conventions table** — `config()` for associations and
   filters, singular PascalCase models, plural controllers/tables,
   `params.key` accessors, migrations for schema changes.
4. **Verify with tests.** After changes, run the affected specs:
   `wheels test tests.specs.<area>` (a folder) or
   `wheels test --filter=<SpecName>` (one spec file).

## Conventions (summary)

- Models extend `"Model"`, controllers extend `"Controller"`, specs extend `"wheels.WheelsTest"`.
- Associations/validations/callbacks and controller filters go in `config()`.
- Never mix positional and named arguments in framework calls.
- Migrations use direct SQL via `execute()` for seed data; `CURRENT_TIMESTAMP` for portable dates.
- `timestamps()` adds `createdAt`, `updatedAt`, AND `deletedAt` — don't add duplicates.
- Controller filters must be `private` (public = routable action).
- `cfparam` every variable a view reads.

## Where to look for more

- `CLAUDE.md` — conventions, common mistakes, testing, and the topic index.
- `.ai/<topic>.md` — the per-topic quick references; `.ai/README.md` lists them.
- https://guides.wheels.dev — the human documentation site (start-here, core-concepts, testing, deployment).
- `/wheels/ai` — JSON documentation endpoints on a running app.
