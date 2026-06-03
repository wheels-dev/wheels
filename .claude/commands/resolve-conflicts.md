# /resolve-conflicts

Reconcile content/docs merge-conflict markers on a bot PR branch (low-risk paths only). Invoked by bot-resolve-conflicts.yml after a deterministic risk gate.

## Rails

Read `.claude/commands/_shared-rails.md` first — they apply to every step
below. Highlights for this command:

- Use `gh` for GitHub state, `git` for the PR branch only.
- **Filesystem writes are limited to the conflicted content/docs files only.**
  Never touch code.
- Output is **a completed merge commit** — the workflow pushes after this
  prompt completes.

## Args

- `<pr-number>` — the PR branch with content/docs conflict markers to resolve

# Resolve content conflicts — PR #<pr-number>

You are running inside `bot-resolve-conflicts.yml`. The workflow has already
merged `origin/develop` into the PR branch and a **deterministic classifier
has confirmed every conflicted file is pure documentation/content**
(markdown/MDX at any path, CHANGELOG, or under `.ai/` or `docs/`).

## Hard safety rule

Run this first:

```bash
git diff --name-only --diff-filter=U
```

Confirm EVERY listed file is in the low-risk set the upstream classifier
admits — i.e. each file is a `*.md` or `*.mdx` (any path), a `CHANGELOG`
file, or under `.ai/` or `docs/`. If ANY listed file falls OUTSIDE that set
(any code file — `.cfc`, `.cfm`, `.js`, `.ts`, `.py`, `.sh`, `.json`, `.yml`,
`.yaml` — or any other non-doc file), DO NOT resolve it. Run
`git merge --abort`, post a comment saying the gate and the command disagreed
(a bug), and stop. This should never happen, but never resolve a code conflict.

## Resolve

For each conflicted content file:
1. Open it and read the full conflict region(s).
2. Reconcile the `<<<<<<<` / `=======` / `>>>>>>>` markers by **integrating
   both sides' intent** — these are docs, so prose from both branches almost
   always belongs in the result; merge them coherently rather than picking one
   side and discarding the other. Remove all conflict markers.
3. `git add <file>`.

After all files are resolved:

```bash
git diff --name-only --diff-filter=U   # must print nothing
git commit --no-edit                    # completes the merge commit
```

Do NOT `git push` — the workflow pushes after verifying no markers remain.
Do NOT edit any file that was not in the conflicted set. Do NOT touch code.
