# Fresh-VM Batch A — Doc-only sweep

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Land the lowest-risk doc fixes from the [Fresh-VM Onboarding Findings](./2026-04-29-fresh-vm-onboarding-findings.md) triage in a single PR against `web/sites/guides`. After this batch, a fresh-VM run of chapters 1, 6, and the install page should not surface the three issues addressed here.

**Architecture:** Three independent edits to `web/sites/guides/src/content/docs/v4-0-0-snapshot/start-here/` MDX files. No code changes, no schema changes. Each edit is verifiable by reading the rendered output. Two of the three items also require a verify-against-reality step before editing — one (the `tests/specs/*` subfolder claim) might already be correct in the source if the user's pre-existing `~/.wheels/` cache was stale.

**Tech Stack:** Astro Starlight (the guides site builder). Runs locally via `pnpm` workspace at `web/sites/guides/`. MDX with custom components (`<FileTree>`, `<Aside>`, `<Steps>`).

**Source findings:** [#1 doc portion](./2026-04-29-fresh-vm-onboarding-findings.md) (install page), [#5](./2026-04-29-fresh-vm-onboarding-findings.md) (chapter 1 file tree), [#6](./2026-04-29-fresh-vm-onboarding-findings.md) (chapter 6 cold-reload terminology).

---

## Task 0: Verify the chapter 1 file-tree finding before editing

The fresh-VM run claimed `tests/specs/{controllers,functional,models}` aren't created by `wheels new`. The scaffold templates at `cli/lucli/templates/app/tests/specs/{controllers,functional,models}/.gitkeep` say otherwise. We need to determine reality before deciding whether the doc or the CLI is wrong.

**Files:**
- Read: `cli/lucli/templates/app/tests/specs/`
- Inspect: output of `wheels new <tmpname>` in a temporary directory

- [ ] **Step 1: Confirm scaffold templates contain the subdirectories**

```bash
find cli/lucli/templates/app/tests/specs -type f
```

Expected output:
```
cli/lucli/templates/app/tests/specs/controllers/.gitkeep
cli/lucli/templates/app/tests/specs/functional/.gitkeep
cli/lucli/templates/app/tests/specs/models/.gitkeep
```

- [ ] **Step 2: Run a fresh `wheels new` in a tempdir and check what actually lands**

```bash
TMP=$(mktemp -d)
cd "$TMP"
wheels new probe-fresh-vm-batch-a --no-open-browser 2>&1 | tail -20
ls -la probe-fresh-vm-batch-a/tests/specs/ 2>&1
```

Expected output: directories `controllers/`, `functional/`, `models/` exist as siblings of any other `tests/specs/` content.

- [ ] **Step 3: Decide which way the finding goes**

  - **If subdirectories DO appear in the fresh app:** the doc is correct — the original fresh-VM finding was a false positive (likely from a stale `~/.wheels/` cache). Skip Task 1's tree edit and move on to Task 2. Document the resolution in the commit message for Task 5.
  - **If subdirectories DO NOT appear:** the scaffolder is dropping `.gitkeep` files. That's a CLI bug, not a doc bug — file it as a separate finding in the triage doc and **still skip Task 1's tree edit** (the doc is describing the intent; fixing the CLI is the real fix and belongs in batch B).
  - Either way: verify the chapter 1 file tree's *rendered HTML* shows `events/global/jobs/` as siblings of `controllers/`, not children. Open the rendered guide page and inspect the indentation visually — see Task 1 Step 1.

```bash
rm -rf "$TMP"
cd -
```

- [ ] **Step 4: Commit nothing yet (this task is read-only verification)**

No commit. Move on to Task 1.

---

## Task 1: Chapter 1 file tree — verify rendering, fix only if rendering is wrong

The source MDX nests `events/global/jobs/` correctly as siblings of `controllers/`. The fresh-VM finding may have been about how `<FileTree>` *renders* the tree. We boot the guides dev server, look at the rendered page, and only edit if the visual hierarchy is misleading.

**Files:**
- Inspect: `web/sites/guides/src/content/docs/v4-0-0-snapshot/start-here/tutorial/01-hello-wheels.mdx:71-120`
- Possibly modify: same file, lines 71-120

- [ ] **Step 1: Boot the guides dev server**

```bash
cd web/sites/guides
pnpm install   # only if you haven't already
pnpm dev
```

Expected: server prints a localhost URL (typically `http://localhost:4321`).

Open `http://localhost:4321/v4-0-0-snapshot/start-here/tutorial/01-hello-wheels/` in a browser. Scroll to the "What got created" section.

- [ ] **Step 2: Visually verify the rendered tree**

Check two specific things:

1. **Are `events/`, `global/`, `jobs/`, `lib/`, `mailers/`, etc. drawn at the same indentation level as `controllers/` and `views/`?** They should appear as siblings under `app/`, not nested under `controllers/`.
2. **Are `controllers/`, `functional/`, `models/` shown as children of `tests/specs/`?** They should be — and per Task 0 they're real on disk.

If both render correctly, this task is done — skip to the commit step. If item 1 renders incorrectly (siblings drawn as children), proceed to Step 3. If item 2 was determined wrong by Task 0 Step 3, proceed to Step 3.

- [ ] **Step 3: (Conditional) Fix the rendering**

If `<FileTree>` is collapsing siblings into children, the fix is usually inserting an explicit empty line or restructuring the indentation. Read the [Starlight FileTree docs](https://starlight.astro.build/components/file-tree/) and apply the smallest fix.

If the `tests/specs/` subfolders are wrong (Task 0 found they're not real), remove them from the tree:

```diff
- tests
-   - specs
-     - controllers
-     - functional
-     - models
+ tests
+   - specs
```

- [ ] **Step 4: Re-verify the rendered page after the edit**

Refresh the dev-server tab. Confirm the rendered tree matches reality.

- [ ] **Step 5: Commit (only if you edited)**

```bash
git add web/sites/guides/src/content/docs/v4-0-0-snapshot/start-here/tutorial/01-hello-wheels.mdx
git commit -m "docs(start-here): correct chapter 1 file-tree rendering for fresh apps"
```

If no edit was needed, skip the commit.

---

## Task 2: Chapter 6 — define "cold reload" the first time the term appears

Line 530 of `06-authentication.mdx` says *"On a cold reload this registers the strategy exactly once"* with no definition. A new user reasonably reads "cold reload" as "what `wheels reload` does." It isn't.

**Files:**
- Modify: `web/sites/guides/src/content/docs/v4-0-0-snapshot/start-here/tutorial/06-authentication.mdx:530`

- [ ] **Step 1: Read lines 520–545 of the chapter to confirm context**

```bash
sed -n '520,545p' web/sites/guides/src/content/docs/v4-0-0-snapshot/start-here/tutorial/06-authentication.mdx
```

Confirm the cold-reload sentence is in the section that registers strategies in `onApplicationStart`.

- [ ] **Step 2: Replace the bare phrase with a definition + a `wheels reload` warning**

Edit `web/sites/guides/src/content/docs/v4-0-0-snapshot/start-here/tutorial/06-authentication.mdx`:

```diff
-On a cold reload this registers the strategy exactly once. The `hasStrategy` check keeps a second reload from stacking duplicates.
+On a *cold* reload — meaning `wheels stop` followed by `wheels start`, which re-fires `onApplicationStart` — this registers the strategy exactly once. (Plain `wheels reload` does **not** re-run `onApplicationStart`; if you edit init code, restart the server.) The `hasStrategy` check keeps a second cold reload from stacking duplicates.
```

- [ ] **Step 3: Verify the rendered page**

Refresh the dev-server tab on `http://localhost:4321/v4-0-0-snapshot/start-here/tutorial/06-authentication/`. Confirm the new sentence reads naturally and the bold `does not` is emphasized.

- [ ] **Step 4: Commit**

```bash
git add web/sites/guides/src/content/docs/v4-0-0-snapshot/start-here/tutorial/06-authentication.mdx
git commit -m "docs(start-here): define cold reload in chapter 6 auth section"
```

---

## Task 3: Install page — add a "what if my versions disagree" callout

Three surfaces report three different versions today (brew formula, `wheels --version`, in-page debug bar). The framework-side fix is in batch F, but the install page should currently set expectations so users don't think their install is broken.

**Files:**
- Modify: `web/sites/guides/src/content/docs/v4-0-0-snapshot/start-here/installing.mdx:51` (and the two parallel lines at 87 and 119, which are duplicates of the same verification text on Linux/Windows paths)

- [ ] **Step 1: Confirm the three duplicate paragraphs**

```bash
grep -n "non-empty version output means the CLI is wired up correctly" web/sites/guides/src/content/docs/v4-0-0-snapshot/start-here/installing.mdx
```

Expected: three line numbers (one for macOS, one for Linux, one for Windows). All three lines should be the same paragraph.

- [ ] **Step 2: Edit all three paragraphs to add a single shared `<Aside>` after each**

The cleanest minimal-edit version: append the same `<Aside type="note">` after each of the three paragraphs. Use `replace_all` if the surrounding context is identical, or do three separate Edit operations if it isn't.

```diff
 You should see a `Wheels Version: <version>` line followed by ASCII art. A `Lucee Version: <version>` line may also appear once Lucee Express has been downloaded (typically on first `wheels start`). Any non-empty version output means the CLI is wired up correctly.
+
+<Aside type="note" title="Multiple version surfaces during 4.0-SNAPSHOT">
+During the 4.0 pre-release, three places report a version: `brew info wheels` (formula), `wheels --version` (CLI runtime), and the dev-mode debug bar shown on every rendered page (framework). They may currently disagree — the framework still reports `0.0.0-dev` even when the CLI reports a real version. This is tracked and will converge before 4.0 GA. If your CLI version output is non-empty and roughly matches the brew formula, your install is fine.
+</Aside>
```

- [ ] **Step 3: Verify rendered output on all three OS-specific install paths**

Refresh `http://localhost:4321/v4-0-0-snapshot/start-here/installing/`. Toggle through any tabs/sections that switch between macOS/Linux/Windows. Confirm the callout appears once after each verification paragraph.

- [ ] **Step 4: Commit**

```bash
git add web/sites/guides/src/content/docs/v4-0-0-snapshot/start-here/installing.mdx
git commit -m "docs(start-here): note version-surface discrepancy on install page"
```

---

## Task 4: Whole-batch verification

Run the full guides build to make sure no MDX syntax errors slipped in.

- [ ] **Step 1: Stop the dev server, run a production build**

```bash
cd web/sites/guides
# Ctrl-C the dev server first
pnpm build
```

Expected: build succeeds, no errors. If the build fails on the edited files, fix the MDX and re-run.

- [ ] **Step 2: Sanity-check the three changed pages were emitted**

```bash
ls -la dist/v4-0-0-snapshot/start-here/installing/index.html \
       dist/v4-0-0-snapshot/start-here/tutorial/01-hello-wheels/index.html \
       dist/v4-0-0-snapshot/start-here/tutorial/06-authentication/index.html
```

Expected: all three files present, recent mtimes.

```bash
cd ../../..
```

- [ ] **Step 3: No commit needed (build artifacts aren't tracked)**

The build is a verification step only.

---

## Task 5: Update the triage doc + open the PR

- [ ] **Step 1: Mark the resolved findings as shipped in the triage doc**

Edit `docs/superpowers/plans/2026-04-29-fresh-vm-onboarding-findings.md`. For each item that was actually shipped in this batch, update its checkbox and add a note:

```diff
-### [ ] 5. Tutorial chapter 1 file tree disagrees with reality
+### [x] 5. Tutorial chapter 1 file tree disagrees with reality — **resolved in batch A** (commit SHA after merge)
```

Apply the same to #6 (cold reload terminology) and the doc portion of #1 (version surface).

If Task 0 determined a finding was a false positive, note that explicitly:

```diff
-### [ ] 5. Tutorial chapter 1 file tree disagrees with reality
+### [~] 5. Tutorial chapter 1 file tree — **verified accurate** during batch A (Task 0); was a stale-cache false positive in the original fresh-VM report
```

- [ ] **Step 2: Add a "Shipped (batch A)" table at the top of the triage doc**

Mirror the format of the April 19 doc's "Shipped" table:

```markdown
## Shipped

### Batch A — Doc-only sweep (2026-04-29)

| # | Item | Commit | Repo |
|---|------|--------|------|
| 5 | Chapter 1 file tree | `<sha>` | wheels |
| 6 | Cold reload terminology | `<sha>` | wheels |
| 1 (doc) | Install page version-surface note | `<sha>` | wheels |
```

Fill in commit SHAs after the squash-merge.

- [ ] **Step 3: Commit the triage update**

```bash
git add docs/superpowers/plans/2026-04-29-fresh-vm-onboarding-findings.md
git commit -m "docs(superpowers): mark batch A items shipped"
```

- [ ] **Step 4: Push the branch and open the PR**

```bash
git push -u origin HEAD
gh pr create --base develop --title "docs(start-here): batch A — fresh-VM onboarding doc sweep" --body "$(cat <<'EOF'
## Summary
- Define "cold reload" the first time it appears in the chapter 6 auth section.
- Add a 4.0-SNAPSHOT note to the install page about the three (currently-disagreeing) version surfaces.
- Verify chapter 1 file tree against `wheels new` reality and either fix rendering or confirm accuracy.

Closes findings #1 (doc portion), #5, and #6 from `docs/superpowers/plans/2026-04-29-fresh-vm-onboarding-findings.md`.

## Test plan
- [ ] `pnpm build` in `web/sites/guides` succeeds
- [ ] Rendered chapter 1 file tree shows `events`, `global`, `jobs` as siblings of `controllers`
- [ ] Rendered chapter 6 auth section defines "cold reload" inline
- [ ] Rendered install page shows the version-surface `<Aside>` on macOS/Linux/Windows tabs
EOF
)"
```

- [ ] **Step 5: Report the PR URL and the commit SHAs**

Print the PR URL and the squash-merge SHA after merge so the triage doc's "Shipped" table can be filled in.

---

## Out of scope for this batch

These items appear in the triage doc as part of the original "Batch A" grouping but were pulled out during reconnaissance:

- **#7 (`wheels destroy` argument-order callout)**: the tutorial already handles it. The proposed work is purely a CLI enhancement (detect-and-suggest) and belongs in batch B.
- **#8 (`wheels reload` doesn't re-fire `onApplicationStart`)**: pure CLI output enhancement. Belongs in batch B.
- **#1 framework portion (three-surface version disagreement)**: the actual fix lives in build/release tooling and `vendor/wheels/` version stamping. Tracked as batch F. This batch only adds the doc note.
