# AGENTS.md

Cross-tool guidance for AI coding assistants working on the **Wheels
framework repository itself** (maintainers). Claude Code also auto-loads
the more detailed `CLAUDE.md` next to this file.

## What this repo is

The `wheels` repo IS the Wheels CFML framework: `vendor/wheels/` is the
framework source (not a dependency), `vendor/wheels/tests/specs/` is the
suite CI runs across every engine × database, `cli/lucli/` is the `wheels`
CLI, and `app/` is a demo app for hand-testing.

## Rules that change how you work

1. **Read `CLAUDE.md` first** — the Cross-Engine Invariants and
   Anti-Patterns there cause more failures than anything else. Every change
   to `vendor/wheels/**` must keep the framework green on Lucee, Adobe CF,
   BoxLang (and best-effort RustCFML).
2. **Two-tier docs.** AI docs for APPLICATION developers live in
   `docs/consumer-ai/` and ship in every distribution (ForgeBox core,
   starter app, `wheels new` scaffolds). Maintainer docs (this file,
   `CLAUDE.md`, `.ai/`) never ship. If you change a
   user-facing quick reference, update the consumer copy too —
   `tools/build/scripts/ship-consumer-docs.sh check` enforces the split in
   CI.
3. **Test before reporting done** — `bash tools/test-local.sh [area]` for
   framework changes; see the "Before Reporting a Change Complete" table
   in `CLAUDE.md`.
4. **Commit conventions** — conventional commits with DCO sign-off
   (`git commit -s`); user-facing changes add a `changelog.d/` fragment.

## Where things live

- `CLAUDE.md` — invariants, anti-patterns, test/verification workflow (read first)
- `.ai/` — deep reference docs (maintainer runbooks and Wheels internals), searched on demand
- `docs/releases/wheels-5-roadmap.md` — the committed 5.0 direction
- `docs/releases/wheels-4.x-backlog.md` — candidate items for the current 4.x line
- `.claude/commands/` — wheels-bot prompts run by the bot-*.yml workflows
- `docs/consumer-ai/` — the consumer AI doc tier (ships in artifacts)
