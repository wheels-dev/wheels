# Wheels Framework Reference Docs

Maintainer-only deep reference. Claude Code searches this tree on demand —
see the root `CLAUDE.md` for the always-loaded invariants and the
"Reference Docs" index at its end.

The tree is deliberately small. The code is the source of truth, and the
former CFML-language reference (`.ai/cfml/`) plus generic pattern /
troubleshooting pages were removed — they drifted and modern models no
longer need them. What remains is runbook knowledge that is NOT
recoverable from reading the code.

> The APPLICATION-developer doc tier (shipped in every distribution) lives
> in `docs/consumer-ai/` — keep the two tiers separate.

## Files

- `wheels/cross-engine-compatibility.md` — engine gotchas (Lucee/Adobe/BoxLang differences), the deep version of CLAUDE.md's Cross-Engine Invariants
- `wheels/deploy.md` — `wheels deploy` Kamal port architecture
- `wheels/wheels-bot.md` — wheels-bot GitHub App architecture
- `wheels/testing/browser-testing.md` — Playwright browser-test DSL
- `wheels/testing/onboarding-harness.md` — fresh-install simulation harness (`tools/test-onboarding.sh`)
- `wheels/troubleshooting/shared-dev-databases.md` — orphan-version handling and `migrate doctor` / `forget` / `pretend` reconciliation (#2780)

## Conventions

- Every file is a focused runbook page; add links from `CLAUDE.md`'s
  "Reference Docs" section when you add one.
- Do not re-add generic CFML/framework reference material — the code and
  `docs/consumer-ai/` cover that. Add a file here only when it captures
  knowledge that cannot be recovered by reading the code.
- Don't duplicate the auto-loaded `CLAUDE.md` invariants here — link them
  instead (`cross-engine-compatibility.md` is the deep version).
