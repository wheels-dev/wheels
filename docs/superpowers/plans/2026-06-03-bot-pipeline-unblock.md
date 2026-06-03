# Bot Release Pipeline Unblock — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Stop two recurring stalls in the wheels-bot release pipeline — commit-message CI failures on throwaway commits, and merge conflicts from in-flight work — by linting the PR title instead of every commit, auto-freshening stale branches, and tiered (resolve-or-escalate) conflict handling.

**Architecture:** Three config-only changes fix the commit-message class (lint the squash subject = PR title; squash-only; correct the bot's header rail). Two new GitHub Actions workflows handle conflicts: `bot-freshen.yml` keeps stale-but-clean branches current via non-destructive `update-branch`, and `bot-resolve-conflicts.yml` runs a **deterministic** risk gate — auto-resolving content/docs conflicts via a `/resolve-conflicts` Claude command and re-verifying through existing CI, while escalating any code conflict to a human. No auto-merge, no force-push, no code-conflict auto-resolution.

**Tech Stack:** GitHub Actions (YAML), `gh` CLI, `actions/create-github-app-token`, `anthropics/claude-code-action@v1`, commitlint, bash. Decision logic lives in tested `.github/scripts/*.sh`; the two workflows are thin wrappers cloning the proven [`bot-address-review.yml`](../../../.github/workflows/bot-address-review.yml) pattern.

**Verification note:** CI YAML and Claude command prompts are not unit-testable in the classic red-green sense. The two pieces of *risky custom logic* (conflict classification, freshen decision) are extracted into standalone bash scripts with real TDD loops. Workflows are verified by YAML lint + a documented live-PR smoke test. This is called out per-task.

---

## File Structure

**Modify:**
- `.github/workflows/pr.yml` — lint PR title; add `edited` trigger; guard `fast-test` against title-only edits.
- `.claude/commands/_shared-rails.md` — correct the header-length rail (header, not subject) + PR-title guidance.
- `.ai/wheels/wheels-bot.md` — document the two new workflows + the title-lint change.

**Create:**
- `tools/test-commit-title.sh` — local regression guard for the title-lint behavior.
- `.github/scripts/classify-conflicts.sh` — decide resolve vs. escalate from a conflicted-file list (deterministic risk gate).
- `tools/test-classify-conflicts.sh` — unit tests for the classifier.
- `.github/scripts/freshen-decide.sh` — map a PR's `mergeStateStatus` to an action (update / dispatch-resolver / skip).
- `tools/test-freshen-decide.sh` — unit tests for the decider.
- `.claude/commands/resolve-conflicts.md` — Claude command that reconciles content/docs conflict markers (low-risk only).
- `.github/workflows/bot-resolve-conflicts.yml` — tiered conflict-resolution workflow.
- `.github/workflows/bot-freshen.yml` — stale-branch freshen sweep.

**Config action (no commit):**
- Set `allow_merge_commit=false` on the repo (squash-only).

**Decisions carried from spec open-questions (defaults applied):**
- Freshen scope: **bot-authored PRs only** (`author.login == "app/wheels-bot"` in `gh` JSON).
- Low-risk allowlist (conservative v1): `*.md`, `*.mdx`, `CHANGELOG*`, anything under `.ai/` or `docs/`, and `web/sites/*/src/content/**`. **Everything else escalates** — including `web/**` code, `*.lock`, and version manifests (deliberately conservative; widen later).
- Freshen cadence: `push:[develop]` + a 30-min scheduled backstop.
- Resolver attempt cap: idempotency marker keyed on PR (one attempt per surfaced conflict state).
- Low-risk resolution re-verification: rely on the existing `docs-verify` PR check post-push (don't duplicate the build inside the resolver).

---

## Task 1: Lint the PR title instead of every commit

**Files:**
- Create: `tools/test-commit-title.sh`
- Modify: `.github/workflows/pr.yml` (lines 3-6 trigger; 13-28 commitlint job; 30-32 fast-test guard)

- [ ] **Step 1: Write the local verification script** (documents + locks the exact CI behavior)

Create `tools/test-commit-title.sh`:

```bash
#!/usr/bin/env bash
# Verifies the exact command pr.yml uses to lint a PR title.
# Good titles pass; bad titles (no type, >100 chars, ALL-CAPS) fail.
set -uo pipefail
cd "$(dirname "$0")/.."

run() { echo "$1" | npx --no-install commitlint --verbose >/dev/null 2>&1; }

fail=0
assert_pass() { if run "$1"; then echo "ok  (pass): $1"; else echo "FAIL (should pass): $1"; fail=1; fi; }
assert_fail() { if run "$1"; then echo "FAIL (should fail): $1"; fail=1; else echo "ok  (fail): $1"; fi; }

assert_pass "fix(model): correct association eager loading"
assert_pass "docs(web/guides): document reserved CFML scope names"
assert_pass "feat: add route model binding"
assert_fail "just a plain sentence with no type"
assert_fail "FIX(model): THIS IS ALL CAPS SUBJECT"
assert_fail "docs(web/guides): note that framework helpers are automatically excluded from the routable action surface"

exit $fail
```

- [ ] **Step 2: Make it executable and run it to confirm it reflects current rules**

Run:
```bash
chmod +x tools/test-commit-title.sh && npm ci && bash tools/test-commit-title.sh
```
Expected: all six lines print `ok` (the last `assert_fail` is the 105-char header from #2845). If any line says `FAIL`, the test fixtures or `commitlint.config.js` disagree — stop and reconcile before wiring CI.

- [ ] **Step 3: Update the `pr.yml` trigger to include `edited`**

In `.github/workflows/pr.yml`, replace the `on:` block (lines 3-6):

```yaml
on:
  pull_request:
    branches:
      - develop
```

with:

```yaml
on:
  pull_request:
    branches:
      - develop
    types: [opened, edited, synchronize, reopened]
```

(`synchronize` does NOT fire on a title-only edit — without `edited`, a corrected title never re-runs the check.)

- [ ] **Step 4: Replace the commitlint job body to lint the title**

In `.github/workflows/pr.yml`, replace the `commitlint` job (lines 13-28):

```yaml
  commitlint:
    name: Validate Commit Messages
    runs-on: ubuntu-latest
    env:
      BASE_SHA: ${{ github.event.pull_request.base.sha }}
      HEAD_SHA: ${{ github.event.pull_request.head.sha }}
    steps:
      - uses: actions/checkout@v6
        with:
          fetch-depth: 0
      - uses: actions/setup-node@v6
        with:
          node-version: '20'
      - run: npm ci
      - name: Validate commits
        run: npx commitlint --from "$BASE_SHA" --to "$HEAD_SHA" --verbose
```

with:

```yaml
  commitlint:
    name: Validate Commit Messages
    runs-on: ubuntu-latest
    env:
      PR_TITLE: ${{ github.event.pull_request.title }}
    steps:
      - uses: actions/checkout@v6
      - uses: actions/setup-node@v6
        with:
          node-version: '20'
      - run: npm ci
      - name: Validate PR title
        run: echo "$PR_TITLE" | npx commitlint --verbose
```

(Keep the job name `Validate Commit Messages` so any process reference to that check still resolves. Squash-merge makes the PR title the landing subject for multi-commit PRs.)

- [ ] **Step 5: Guard `fast-test` against title-only edits**

In `.github/workflows/pr.yml`, the `fast-test` job (line 30) currently reads:

```yaml
  fast-test:
    name: "Lucee 7 + SQLite (LuCLI)"
    runs-on: ubuntu-latest
```

Insert the guard:

```yaml
  fast-test:
    name: "Lucee 7 + SQLite (LuCLI)"
    if: github.event.action != 'edited'
    runs-on: ubuntu-latest
```

(An `edited` event = title/body/base change; no code changed, so the full suite must not re-run.)

- [ ] **Step 6: Commit**

```bash
git add tools/test-commit-title.sh .github/workflows/pr.yml
git commit -s -m "ci(pr): lint PR title instead of every commit

Squash-merge makes the PR title the landing subject, so per-commit
linting failed on throwaway intermediate commits (e.g. #2845's 105-char
bot commit) while the valid title was ignored. Lint the title; add the
edited trigger so corrections re-run; guard fast-test against title edits.

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 2: Make the repo squash-only

**Files:** none (repo setting). This is a maintainer config action — execute only with the maintainer's go-ahead (it's reversible).

- [ ] **Step 1: Disable merge commits**

Run:
```bash
gh api -X PATCH repos/wheels-dev/wheels -F allow_merge_commit=false >/dev/null
```

- [ ] **Step 2: Verify**

Run:
```bash
gh api repos/wheels-dev/wheels --jq '{squash: .allow_squash_merge, merge: .allow_merge_commit, rebase: .allow_rebase_merge}'
```
Expected: `{"squash":true,"merge":false,"rebase":false}`. This guarantees the PR title is what lands (no merge-commit path that would carry unlinted intermediate headers verbatim).

---

## Task 3: Fix the commit-header rail (header, not subject)

**Files:**
- Modify: `.claude/commands/_shared-rails.md:44`

- [ ] **Step 1: Correct the length rail**

In `.claude/commands/_shared-rails.md`, line 44 currently reads:

```markdown
- **Subject ≤ 100 chars, not ALL-CAPS.** Sentence-case is fine.
```

Replace it with:

```markdown
- **Header ≤ 100 chars, not ALL-CAPS.** commitlint measures the WHOLE header — `type(scope): subject` including the `type(scope): ` prefix — not just the subject. A 90-char subject under a `docs(web/guides): ` prefix is a 108-char header and FAILS. Count the prefix. Sentence-case is fine.
- **The PR title is the linted gate.** Because the repo squash-merges, the PR title becomes the landing commit subject and is what CI validates — make the PR title itself a valid conventional-commit header ≤ 100 chars.
```

- [ ] **Step 2: Verify the rail is present and propagates**

Run:
```bash
grep -n "WHOLE header" .claude/commands/_shared-rails.md && \
  grep -rl "_shared-rails" .claude/commands/ | sed 's,.*/,,'
```
Expected: the matched line, plus the list of commands that include the rails (the rule reaches `propose-fix`, `address-review`, `update-docs`, `write-docs`). (Inclusion is by the prompts pasting the rails verbatim; confirm the four commit-authoring commands reference `_shared-rails`.)

- [ ] **Step 3: Commit**

```bash
git add .claude/commands/_shared-rails.md
git commit -s -m "chore(bot): cap generated commit HEADER (not subject) at 100 chars

The rail told the bot to cap the subject, but commitlint limits the full
type(scope): subject header. That mismatch produced >100-char headers
(#2845). Also state that the PR title is the linted gate under squash-merge.

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 4: Conflict classifier script (deterministic risk gate)

**Files:**
- Create: `.github/scripts/classify-conflicts.sh`
- Test: `tools/test-classify-conflicts.sh`

This is the riskiest logic — it decides whether a real conflict is auto-resolved. It is deterministic and tested so the model never gets to misclassify a code conflict as safe.

- [ ] **Step 1: Write the failing test**

Create `tools/test-classify-conflicts.sh`:

```bash
#!/usr/bin/env bash
# Tests classify-conflicts.sh: all-content -> resolve; any code -> escalate.
set -uo pipefail
SCRIPT="$(dirname "$0")/../.github/scripts/classify-conflicts.sh"

fail=0
check() {
  local expected="$1"; shift
  local got
  got="$(printf '%s\n' "$@" | bash "$SCRIPT")"
  if [ "$got" = "$expected" ]; then echo "ok:   $expected <- $*"
  else echo "FAIL: expected=$expected got=$got for: $*"; fail=1; fi
}

check resolve  "web/sites/guides/src/content/docs/v4-0-0/x.mdx"
check resolve  "CHANGELOG.md"
check resolve  ".ai/wheels/foo.md"
check resolve  "docs/superpowers/specs/x.md"
check resolve  "vendor/wheels/migrator/CLAUDE.md"
check escalate "vendor/wheels/model/Finders.cfc"
check escalate "web/sites/blog/src/lib/feed.ts"
check escalate "package-lock.json"
check escalate "config/routes.cfm"
check escalate "CHANGELOG.md" "vendor/wheels/model/Finders.cfc"

# Empty input must be safe (escalate), never resolve.
got="$(printf '' | bash "$SCRIPT")"
if [ "$got" = "escalate" ]; then echo "ok:   escalate <- (empty)"
else echo "FAIL: empty input gave $got"; fail=1; fi

exit $fail
```

- [ ] **Step 2: Run it to verify it fails**

Run:
```bash
bash tools/test-classify-conflicts.sh
```
Expected: FAIL — `.github/scripts/classify-conflicts.sh` does not exist yet (bash reports "No such file").

- [ ] **Step 3: Write the classifier**

Create `.github/scripts/classify-conflicts.sh`:

```bash
#!/usr/bin/env bash
# Reads conflicted file paths (stdin or args, one per line) and prints
# "resolve" iff EVERY path is pure documentation/content, else "escalate".
# Conservative by design: unknown or empty input -> escalate.
set -euo pipefail

is_low_risk() {
  case "$1" in
    *.md|*.mdx)                 return 0 ;;  # markdown/MDX anywhere is non-executable
    CHANGELOG|CHANGELOG.*)      return 0 ;;
    .ai/*|*/.ai/*)              return 0 ;;
    docs/*|*/docs/*)            return 0 ;;
    web/sites/*/src/content/*)  return 0 ;;  # MDX content trees only (NOT web code)
  esac
  return 1
}

files=()
if [ "$#" -gt 0 ]; then
  files=("$@")
else
  while IFS= read -r line; do [ -n "$line" ] && files+=("$line"); done
fi

if [ "${#files[@]}" -eq 0 ]; then echo "escalate"; exit 0; fi

for f in "${files[@]}"; do
  if ! is_low_risk "$f"; then echo "escalate"; exit 0; fi
done
echo "resolve"
```

- [ ] **Step 4: Run the test to verify it passes**

Run:
```bash
chmod +x .github/scripts/classify-conflicts.sh && bash tools/test-classify-conflicts.sh
```
Expected: every line prints `ok`, exit 0.

- [ ] **Step 5: Commit**

```bash
git add .github/scripts/classify-conflicts.sh tools/test-classify-conflicts.sh
git commit -s -m "feat(ci): add deterministic conflict risk classifier

All-content conflicts (md/mdx, CHANGELOG, .ai, docs, web content trees)
are safe to auto-resolve; anything touching code escalates. Empty/unknown
input escalates. Keeps risk classification out of model judgement.

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 5: Freshen decision script

**Files:**
- Create: `.github/scripts/freshen-decide.sh`
- Test: `tools/test-freshen-decide.sh`

- [ ] **Step 1: Write the failing test**

Create `tools/test-freshen-decide.sh`:

```bash
#!/usr/bin/env bash
# Tests freshen-decide.sh: BEHIND -> update; DIRTY -> dispatch-resolver; else skip.
set -uo pipefail
SCRIPT="$(dirname "$0")/../.github/scripts/freshen-decide.sh"

fail=0
check() {
  local expected="$1" status="$2"
  local got; got="$(bash "$SCRIPT" "$status")"
  if [ "$got" = "$expected" ]; then echo "ok:   $status -> $expected"
  else echo "FAIL: $status -> $got (expected $expected)"; fail=1; fi
}

check update            BEHIND
check dispatch-resolver DIRTY
check skip              CLEAN
check skip              UNSTABLE
check skip              BLOCKED
check skip              UNKNOWN
check skip              ""

exit $fail
```

- [ ] **Step 2: Run it to verify it fails**

Run:
```bash
bash tools/test-freshen-decide.sh
```
Expected: FAIL — script does not exist yet.

- [ ] **Step 3: Write the decider**

Create `.github/scripts/freshen-decide.sh`:

```bash
#!/usr/bin/env bash
# Maps a PR's GitHub mergeStateStatus to a freshen action.
#   BEHIND -> update (merge develop in, non-destructive)
#   DIRTY  -> dispatch-resolver (real conflict)
#   *      -> skip (CLEAN/UNSTABLE/BLOCKED/UNKNOWN are not our job)
set -euo pipefail
case "${1:-}" in
  BEHIND) echo "update" ;;
  DIRTY)  echo "dispatch-resolver" ;;
  *)      echo "skip" ;;
esac
```

- [ ] **Step 4: Run the test to verify it passes**

Run:
```bash
chmod +x .github/scripts/freshen-decide.sh && bash tools/test-freshen-decide.sh
```
Expected: every line `ok`, exit 0.

- [ ] **Step 5: Commit**

```bash
git add .github/scripts/freshen-decide.sh tools/test-freshen-decide.sh
git commit -s -m "feat(ci): add PR freshen decision mapping

Maps mergeStateStatus to update / dispatch-resolver / skip so the freshen
sweep workflow stays a thin, tested wrapper.

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 6: `/resolve-conflicts` Claude command

**Files:**
- Create: `.claude/commands/resolve-conflicts.md`

The deterministic gate (Task 4) guarantees this command only runs when ALL conflicts are content/docs. The command reconciles markers and completes the merge; it does NOT push (the workflow does, after verification).

- [ ] **Step 1: Write the command prompt**

Create `.claude/commands/resolve-conflicts.md`:

````markdown
---
description: Reconcile content/docs merge-conflict markers on a bot PR branch (low-risk paths only). Invoked by bot-resolve-conflicts.yml after a deterministic risk gate.
---

@.claude/commands/_shared-rails.md

# Resolve content conflicts — PR #$ARGUMENTS

You are running inside `bot-resolve-conflicts.yml`. The workflow has already
merged `origin/develop` into the PR branch and a **deterministic classifier
has confirmed every conflicted file is pure documentation/content** (markdown,
MDX, CHANGELOG, `.ai/`, `docs/`, or `web/sites/*/src/content/`).

## Hard safety rule

Run this first:

```bash
git diff --name-only --diff-filter=U
```

If ANY listed file is a code file (`.cfc`, `.cfm`, `.js`, `.ts`, `.py`, `.sh`,
`.json`, `.yml`, `.yaml`, or anything under `vendor/`, `cli/`, `app/`,
`config/`, `tests/` that is not under a `content/` tree), DO NOT resolve it.
Instead run `git merge --abort`, post a comment saying the gate and the
command disagreed (a bug), and stop. This should never happen, but never
resolve a code conflict.

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
````

- [ ] **Step 2: Verify structure**

Run:
```bash
grep -q "_shared-rails" .claude/commands/resolve-conflicts.md \
  && grep -q "diff-filter=U" .claude/commands/resolve-conflicts.md \
  && grep -q "never resolve a code conflict" .claude/commands/resolve-conflicts.md \
  && echo "structure ok"
```
Expected: `structure ok`. (Confirms it includes the shared rails, the hard safety gate, and the no-code rule.)

- [ ] **Step 3: Commit**

```bash
git add .claude/commands/resolve-conflicts.md
git commit -s -m "feat(bot): add /resolve-conflicts command for content conflicts

Reconciles content/docs conflict markers on a bot PR branch after a
deterministic gate confirms no code is involved. Integrates both sides,
completes the merge, never pushes (the workflow does), never touches code.

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 7: `bot-resolve-conflicts.yml` workflow

**Files:**
- Create: `.github/workflows/bot-resolve-conflicts.yml`

Clones the `bot-address-review.yml` scaffold: App-token auth, checkout PR head, skip-check idempotency, then merge → classify → (escalate | resolve+verify+push).

- [ ] **Step 1: Write the workflow**

Create `.github/workflows/bot-resolve-conflicts.yml`:

```yaml
name: Wheels Bot — Resolve Conflicts

# Dispatched by bot-freshen.yml for an open bot PR whose mergeStateStatus is
# DIRTY. A deterministic classifier decides: auto-resolve content/docs
# conflicts (via /resolve-conflicts), or escalate anything touching code.
on:
  workflow_dispatch:
    inputs:
      pr-number:
        description: 'PR number to attempt conflict resolution on'
        required: true
        type: string

permissions:
  contents: read
  pull-requests: write
  issues: write

concurrency:
  group: wheels-bot-resolve-${{ inputs.pr-number }}
  cancel-in-progress: false

jobs:
  resolve:
    name: Resolve conflicts (tiered)
    if: vars.WHEELS_BOT_ENABLED == 'true'
    runs-on: ubuntu-latest
    timeout-minutes: 60
    env:
      PR_NUMBER: ${{ inputs.pr-number }}
      REPO: wheels-dev/wheels
    steps:
      - name: Generate App token
        id: app-token
        uses: actions/create-github-app-token@v2
        with:
          app-id: ${{ secrets.WHEELS_BOT_APP_ID }}
          private-key: ${{ secrets.WHEELS_BOT_PRIVATE_KEY }}

      - name: Resolve PR head ref
        id: pr
        env:
          GH_TOKEN: ${{ steps.app-token.outputs.token }}
        run: |
          set -euo pipefail
          if ! [[ "$PR_NUMBER" =~ ^[0-9]+$ ]]; then
            echo "::error::pr-number must be numeric, got: $PR_NUMBER"; exit 1
          fi
          ref=$(gh pr view "$PR_NUMBER" --repo "$REPO" --json headRefName -q '.headRefName')
          if [ -z "$ref" ]; then echo "::error::no head ref for #$PR_NUMBER"; exit 1; fi
          echo "head=$ref" >> "$GITHUB_OUTPUT"

      - name: Checkout PR branch
        uses: actions/checkout@v6
        with:
          ref: ${{ steps.pr.outputs.head }}
          fetch-depth: 0
          token: ${{ steps.app-token.outputs.token }}

      - name: Skip check
        id: gate
        uses: ./.github/actions/wheels-bot-skip-check
        with:
          target-type: pr
          target-number: ${{ env.PR_NUMBER }}
          marker-pattern: 'wheels-bot:conflict-attempted:${{ env.PR_NUMBER }}'
          github-token: ${{ steps.app-token.outputs.token }}

      - name: Configure git
        if: steps.gate.outputs.skip == 'false'
        run: |
          git config user.name "wheels-bot[bot]"
          git config user.email "wheels-bot[bot]@users.noreply.github.com"

      - name: Merge develop to surface conflicts
        id: merge
        if: steps.gate.outputs.skip == 'false'
        run: |
          set -euo pipefail
          git fetch origin develop
          if git merge --no-edit origin/develop; then
            echo "result=clean" >> "$GITHUB_OUTPUT"
          else
            echo "result=conflict" >> "$GITHUB_OUTPUT"
          fi

      - name: Classify conflicts
        id: classify
        if: steps.gate.outputs.skip == 'false' && steps.merge.outputs.result == 'conflict'
        run: |
          set -euo pipefail
          files=$(git diff --name-only --diff-filter=U)
          echo "Conflicted files:"; printf '%s\n' "$files"
          decision=$(printf '%s\n' "$files" | bash .github/scripts/classify-conflicts.sh)
          echo "decision=$decision" >> "$GITHUB_OUTPUT"
          { echo 'CONFLICT_FILES<<EOF'; printf '%s\n' "$files"; echo 'EOF'; } >> "$GITHUB_ENV"

      - name: Escalate (code conflict)
        if: steps.gate.outputs.skip == 'false' && steps.classify.outputs.decision == 'escalate'
        env:
          GH_TOKEN: ${{ steps.app-token.outputs.token }}
        run: |
          set -euo pipefail
          git merge --abort || true
          gh label create conflict:needs-human --repo "$REPO" --color B60205 \
            --description "Merge conflict touches code; needs manual resolution" 2>/dev/null || true
          gh pr edit "$PR_NUMBER" --repo "$REPO" --add-label conflict:needs-human
          gh pr comment "$PR_NUMBER" --repo "$REPO" --body "$(printf '%s\n' \
            "🛑 **Merge conflict needs a human.** The conflict touches code paths, which the bot will not auto-resolve." \
            "" \
            "Conflicted files:" '```' "$CONFLICT_FILES" '```' \
            "" \
            "Please merge \`develop\` and resolve manually. (Labelled \`conflict:needs-human\`; marker: wheels-bot:conflict-attempted:$PR_NUMBER)")"

      - name: Set up Wheels test environment
        if: steps.gate.outputs.skip == 'false' && steps.classify.outputs.decision == 'resolve'
        uses: ./.github/actions/setup-wheels-test-env
        with:
          port: '60007'
          install-playwright: 'false'

      - name: Resolve (content/docs only) via Claude
        if: steps.gate.outputs.skip == 'false' && steps.classify.outputs.decision == 'resolve'
        uses: anthropics/claude-code-action@v1
        with:
          allowed_bots: 'wheels-bot[bot],github-actions[bot]'
          anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
          github_token: ${{ steps.app-token.outputs.token }}
          prompt: |
            /resolve-conflicts ${{ env.PR_NUMBER }}
          claude_args: |
            --model claude-opus-4-7
            --max-turns 400
            --allowedTools "Bash(gh:*),Bash(git:*),Read,Edit,Write,Grep,Glob"

      - name: Verify no markers remain and push
        if: steps.gate.outputs.skip == 'false' && steps.classify.outputs.decision == 'resolve'
        env:
          GH_TOKEN: ${{ steps.app-token.outputs.token }}
        run: |
          set -euo pipefail
          if git diff --name-only --diff-filter=U | grep -q .; then
            echo "::error::conflict markers remain after /resolve-conflicts"
            git merge --abort || true
            gh pr comment "$PR_NUMBER" --repo "$REPO" --body \
              "⚠️ Automated content-conflict resolution left unresolved markers; aborting and leaving for a human."
            exit 1
          fi
          if [ -f .git/MERGE_HEAD ]; then git commit --no-edit; fi
          git push origin HEAD
          # The push triggers pr.yml / docs-verify, which validate the result.
```

- [ ] **Step 2: Lint the workflow YAML**

Run (uses actionlint if available; otherwise a YAML parse):
```bash
command -v actionlint >/dev/null && actionlint .github/workflows/bot-resolve-conflicts.yml \
  || python3 -c "import sys,yaml; yaml.safe_load(open('.github/workflows/bot-resolve-conflicts.yml'))" 2>/dev/null \
  || echo "install actionlint or pyyaml to validate; otherwise review by eye"
```
Expected: no errors (or the install hint if neither tool is present — then review structure against `bot-address-review.yml`).

- [ ] **Step 3: Commit**

```bash
git add .github/workflows/bot-resolve-conflicts.yml
git commit -s -m "feat(bot): add tiered conflict-resolution workflow

Merges develop into a DIRTY bot PR, runs the deterministic classifier, then
either escalates code conflicts (label + comment, no push) or resolves
content/docs conflicts via /resolve-conflicts and pushes after verifying no
markers remain. Existing PR checks validate the pushed result.

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

> **Live smoke test (after this is merged to `develop`):** create a throwaway bot-authored test PR, force a docs-only conflict (edit a `.md` both on the branch and on develop), then `gh workflow run bot-resolve-conflicts.yml -f pr-number=<n>` and confirm it resolves + pushes. Repeat with a `.cfc` conflict and confirm it escalates (label + comment, no push). `workflow_dispatch` only targets workflows on the default branch, so this test requires the workflow on `develop` first.

---

## Task 8: `bot-freshen.yml` sweep

**Files:**
- Create: `.github/workflows/bot-freshen.yml`

Depends on Task 7 being on `develop` (it dispatches `bot-resolve-conflicts.yml`).

- [ ] **Step 1: Write the workflow**

Create `.github/workflows/bot-freshen.yml`:

```yaml
name: Wheels Bot — Freshen PRs

# Keeps open bot PRs current with develop. On each push to develop (plus a
# 30-min backstop), behind-but-clean branches are updated non-destructively
# (merge develop in); DIRTY branches are handed to bot-resolve-conflicts.yml.
on:
  push:
    branches: [develop]
  schedule:
    - cron: '*/30 * * * *'
  workflow_dispatch:

permissions:
  contents: read
  pull-requests: write
  actions: write

concurrency:
  group: wheels-bot-freshen
  cancel-in-progress: false

jobs:
  freshen:
    name: Freshen open bot PRs
    if: vars.WHEELS_BOT_ENABLED == 'true'
    runs-on: ubuntu-latest
    timeout-minutes: 20
    env:
      REPO: wheels-dev/wheels
    steps:
      - name: Generate App token
        id: app-token
        uses: actions/create-github-app-token@v2
        with:
          app-id: ${{ secrets.WHEELS_BOT_APP_ID }}
          private-key: ${{ secrets.WHEELS_BOT_PRIVATE_KEY }}

      - uses: actions/checkout@v6
        with:
          fetch-depth: 1

      - name: Sweep
        env:
          GH_TOKEN: ${{ steps.app-token.outputs.token }}
        run: |
          set -euo pipefail
          decide=.github/scripts/freshen-decide.sh
          prs=$(gh pr list --repo "$REPO" --state open --base develop \
                  --json number,isDraft,author \
                  --jq '.[] | select(.isDraft==false) | select(.author.login=="app/wheels-bot") | .number')
          if [ -z "$prs" ]; then echo "No open bot PRs."; exit 0; fi
          for n in $prs; do
            status=UNKNOWN
            for _ in $(seq 1 9); do            # mergeStateStatus is async; poll ~45s
              status=$(gh pr view "$n" --repo "$REPO" --json mergeStateStatus --jq '.mergeStateStatus')
              [ "$status" != "UNKNOWN" ] && break
              sleep 5
            done
            action=$(bash "$decide" "$status")
            echo "PR #$n: status=$status -> $action"
            case "$action" in
              update)
                gh api -X PUT "repos/$REPO/pulls/$n/update-branch" \
                  && echo "  updated #$n" \
                  || echo "  update-branch no-op/failed for #$n (already current or raced to DIRTY)";;
              dispatch-resolver)
                gh workflow run bot-resolve-conflicts.yml --repo "$REPO" -f pr-number="$n" \
                  && echo "  dispatched resolver for #$n" \
                  || echo "  failed to dispatch resolver for #$n";;
              skip) echo "  nothing to do for #$n";;
            esac
          done
```

- [ ] **Step 2: Lint the workflow YAML**

Run:
```bash
command -v actionlint >/dev/null && actionlint .github/workflows/bot-freshen.yml \
  || python3 -c "import sys,yaml; yaml.safe_load(open('.github/workflows/bot-freshen.yml'))" 2>/dev/null \
  || echo "install actionlint or pyyaml to validate; otherwise review by eye"
```
Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add .github/workflows/bot-freshen.yml
git commit -s -m "feat(bot): add stale-branch freshen sweep

On push to develop (+30-min backstop), updates behind-but-clean bot PR
branches via non-destructive update-branch and dispatches the conflict
resolver for DIRTY ones. Bot-authored, non-draft PRs only.

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

> **Live smoke test (after merge to `develop`):** land a change on develop that touches a file an open bot PR also touched (cleanly) and confirm the PR auto-updates; confirm a DIRTY PR triggers a `bot-resolve-conflicts` run.

---

## Task 9: Document the new pipeline pieces

**Files:**
- Modify: `.ai/wheels/wheels-bot.md`

- [ ] **Step 1: Read the current doc and append a section**

Read `.ai/wheels/wheels-bot.md`, then append:

```markdown
## PR-prep automation (release unblocking)

- **Commit-message gate.** `pr.yml`'s `Validate Commit Messages` lints the
  **PR title** (the squash subject), not every commit — the repo is
  squash-only, so intermediate commit headers never land. Edit the title to
  fix a failure; the `edited` trigger re-runs the check (and `fast-test` is
  skipped on title-only edits). Local guard: `tools/test-commit-title.sh`.
- **Freshen (`bot-freshen.yml`).** On push to develop + a 30-min backstop:
  behind-but-clean bot PRs are updated via non-destructive `update-branch`;
  DIRTY ones are dispatched to the resolver. Decision logic:
  `.github/scripts/freshen-decide.sh`.
- **Conflict resolution (`bot-resolve-conflicts.yml` + `/resolve-conflicts`).**
  A deterministic classifier (`.github/scripts/classify-conflicts.sh`)
  auto-resolves content/docs conflicts (md/mdx, CHANGELOG, `.ai/`, `docs/`,
  `web/sites/*/src/content/`) and pushes; any code conflict is escalated with
  the `conflict:needs-human` label and a comment — never auto-resolved.
- **Not automated:** merging. PRs are brought to a green, conflict-free,
  ready state; the maintainer performs the final squash-merge.
```

- [ ] **Step 2: Verify**

Run:
```bash
grep -q "PR-prep automation" .ai/wheels/wheels-bot.md && echo "doc updated"
```
Expected: `doc updated`.

- [ ] **Step 3: Commit**

```bash
git add .ai/wheels/wheels-bot.md
git commit -s -m "docs(bot): document freshen + conflict-resolution + title-lint

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Self-Review

**Spec coverage:**
- WS1a (lint PR title) → Task 1. ✓
- WS1b (squash-only) → Task 2. ✓
- WS1c (header cap rail) → Task 3 (refined: fix header-vs-subject mismatch). ✓
- WS2a (auto-freshen stale-clean) → Tasks 5 + 8. ✓
- WS2b (tiered conflict resolution) → Tasks 4 + 6 + 7. ✓
- Non-goals (no auto-merge, no code auto-resolution, no force-push) → enforced in Tasks 4/6/7 (deterministic gate, escalate code, `update-branch`/merge-in only). ✓
- Docs → Task 9. ✓

**Placeholder scan:** No TBD/TODO; every code and YAML block is complete; every command has expected output.

**Type/name consistency:** `classify-conflicts.sh` emits exactly `resolve`/`escalate`, consumed verbatim in Task 7's `steps.classify.outputs.decision`. `freshen-decide.sh` emits `update`/`dispatch-resolver`/`skip`, consumed verbatim in Task 8's `case`. The dispatched workflow filename `bot-resolve-conflicts.yml` and input `pr-number` match between Task 7 (definition) and Task 8 (`gh workflow run`). Marker `wheels-bot:conflict-attempted:<pr>` is set in the escalate/skip path and read by the skip-check in Task 7. Bot author login `app/wheels-bot` matches the live `gh` JSON.

**Ordering / dependencies:** Tasks 1-5 independent. Task 7 depends on 4 + 6. Task 8 depends on 7 being on `develop` (dispatch target). Task 9 last. Tasks 1, 3, 4, 5 deliver value standalone; the commit-message class is fixed after Tasks 1-3 alone.
