#!/usr/bin/env bash
# Open a PR carrying a refreshed visual-regression baseline, then enable
# auto-merge — so the change lands WITHOUT a direct push to a ruleset-protected
# branch.
#
# Extracted from .github/workflows/refresh-visual-baselines.yml for issue #3283:
# that workflow's final step pushed the refreshed PNG(s) straight to the
# dispatched branch, which the `develop` branch ruleset now rejects:
#
#   remote: error: GH013: Repository rule violations found for refs/heads/develop.
#   remote: - Changes must be made through a pull request.
#
# This mirrors the PR flow already used by
# .github/workflows/refresh-packages-baseline.yml, and additionally enables
# GitHub auto-merge so the refresh lands unattended once the required checks pass.
#
# Contract:
#   - CWD is the repository root.
#   - The working tree already holds the refreshed, UNSTAGED baseline file(s).
#
# Inputs (all via env, never spliced into an eval'd string — this preserves the
# workflow's Actions-injection-safe posture; see the workflow's security note):
#   SITES         which baseline(s) were refreshed (used in the title/body/branch)
#   TARGET_BRANCH branch the PR merges into (github.ref_name)
#   RUN_ID        github.run_id — makes the throwaway branch name unique
#   ADD_PATHS     git pathspec(s) to stage (default: web/tests/visual-baselines/)
#   GH_TOKEN      token with BOTH contents:write and pull-requests:write
#
# SITES is constrained to the workflow's `choice` input list and RUN_ID is a
# numeric run id, so both are safe to interpolate into the branch name and the
# --title/--body arguments (each reaches git/gh as a single argv element, never
# a shell-expanded command string).

set -euo pipefail

: "${SITES:?SITES is required}"
: "${TARGET_BRANCH:?TARGET_BRANCH is required}"
: "${RUN_ID:?RUN_ID is required}"
ADD_PATHS="${ADD_PATHS:-web/tests/visual-baselines/}"

branch="chore/refresh-baseline-${SITES}-${RUN_ID}"

git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
git checkout -b "$branch"
# Word-split ADD_PATHS on purpose so callers can pass multiple pathspecs; the
# value is workflow-controlled, never user input.
# shellcheck disable=SC2086
git add -- $ADD_PATHS

# Build the commit message in a temp file so the heredoc body stays readable and
# no value is spliced into a shell-expanded string. The subject matches the old
# direct-push commit and stays a valid conventional commit <=100 chars, which the
# "Validate Commit Messages" required check lints against the PR title. The
# branch name lives on its own body line so a long TARGET_BRANCH can't push a
# body line past commitlint's 100-char body-max-line-length.
commit_msg_file="$(mktemp)"
{
  printf '%s\n\n' "chore(web): refresh visual baseline(s) ($SITES)"
  printf '%s\n' "Manually triggered baseline refresh via"
  printf '%s\n' ".github/workflows/refresh-visual-baselines.yml"
  printf '%s\n\n' "targeting branch $TARGET_BRANCH."
  printf '%s\n' "Run when an intentional content/layout change makes the visual-regression"
  printf '%s\n' "check fail. The new PNG(s) under web/tests/visual-baselines/ are now the"
  printf '%s\n' "expected rendering."
} > "$commit_msg_file"

git commit -F "$commit_msg_file"
rm -f "$commit_msg_file"

git push -u origin "$branch"

pr_body_file="$(mktemp)"
{
  printf '%s\n\n' "## Summary"
  printf '%s\n\n' "Refreshes the visual-regression baseline(s) for \`$SITES\` so the \`visual-regression\` check reflects the intended rendering."
  printf '%s\n\n' "Opened automatically by \`.github/workflows/refresh-visual-baselines.yml\` (run \`$RUN_ID\`), which routes the refreshed PNG(s) through a PR instead of a direct push — the \`$TARGET_BRANCH\` branch ruleset requires changes to arrive via a pull request."
  printf '%s\n' "## Test plan"
  printf '%s\n' "- [ ] \`visual-regression\` job passes on this PR"
  printf '%s\n' "- [ ] The baseline diff contains only the intended content/layout change (not font/rendering drift)"
} > "$pr_body_file"

# gh prints the new PR's URL on stdout; capture it so the auto-merge call
# targets exactly this PR.
pr_url="$(gh pr create \
  --base "$TARGET_BRANCH" \
  --head "$branch" \
  --title "chore(web): refresh visual baseline(s) ($SITES)" \
  --body-file "$pr_body_file")"

rm -f "$pr_body_file"

echo "Opened refresh PR: $pr_url"

# Enable auto-merge so the PR lands once the required checks pass — no human
# round-trip. If the repository has auto-merge disabled, don't fail the whole
# refresh job: the PR is already open for a human to merge manually.
if gh pr merge "$pr_url" --auto --squash --delete-branch; then
  echo "Auto-merge enabled — the PR will land once required checks pass."
else
  echo "Could not enable auto-merge (is it disabled on this repo?); PR left open for manual merge: $pr_url"
fi
