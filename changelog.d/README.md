# changelog.d — unreleased changelog fragments

One file per PR (or per logical change) instead of editing `CHANGELOG.md`
directly. Every campaign PR used to append its entry at the same
`[Unreleased]` anchor, so each merge conflicted with every other open PR.
Fragments live in separate files, so they never conflict; they are assembled
into `CHANGELOG.md` at release promotion and this folder is cleared, ready
for the next cycle.

## Adding an entry

Create `changelog.d/<slug>.<type>.md`:

- **`<slug>`** — short kebab-case description, unique enough to avoid
  collisions (the issue/PR number works too: `2971-ratelimiter.fixed.md`).
- **`<type>`** — one of `added`, `changed`, `deprecated`, `removed`,
  `fixed`, `security`, `performance`. This selects the `### Type` heading
  the entry lands under.

File content is one or more **complete markdown bullet lines**, exactly as
they should appear in `CHANGELOG.md`:

```markdown
- `Seeder.runSeeds()` no longer reports success when individual `seedOnce()` entries failed validation (#2973)
```

Rules:

- Start each entry with `- `. No headings, no frontmatter.
- Reference the issue or PR number in parentheses at the end, matching the
  existing CHANGELOG style.
- A PR with entries in multiple sections writes multiple fragment files
  (e.g. `my-feature.added.md` + `my-feature.fixed.md`).
- Do NOT edit `CHANGELOG.md`'s `[Unreleased]` section directly — that
  recreates the merge-conflict anchor this folder exists to remove.

## Releasing

At the release cut:

```bash
tools/changelog-promote.sh --preview        # see what would be assembled
tools/changelog-promote.sh 4.1.0            # promote (date defaults to today)
tools/changelog-promote.sh 4.1.0 2026-07-01 # explicit date
```

Promotion merges all fragments (plus anything already sitting under
`[Unreleased]`, e.g. entries that predate this system) into a new
`## [<version>] - <date>` section, resets `[Unreleased]` to empty, and
deletes the fragment files. Review the diff, then commit.
