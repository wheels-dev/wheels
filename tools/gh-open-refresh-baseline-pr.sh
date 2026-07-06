#!/usr/bin/env bash
# Deliver a refreshed visual-regression baseline to the dispatched branch:
# push it directly when the branch allows that, and fall back to opening a
# `chore/refresh-baseline-*` PR when the branch ruleset rejects direct pushes.
#
# Extracted from .github/workflows/refresh-visual-baselines.yml for issue #3283:
# that workflow's final step pushed the refreshed PNG(s) straight to the
# dispatched branch, which the `develop` branch ruleset now rejects:
#
#   remote: error: GH013: Repository rule violations found for refs/heads/develop.
#   remote: - Changes must be made through a pull request.
#
# Delivery strategy:
#   1. Commit the refreshed PNG(s), then try the direct push. On an
#      unprotected branch (the header's documented flow — dispatching on a
#      PR's source branch) this succeeds and behaves exactly like the
#      pre-#3283 workflow: the commit lands immediately and retriggers CI.
#   2. If the push is rejected (GH013 on `develop`, or any other rejection),
#      move the commit to a throwaway `chore/refresh-baseline-*` branch and
#      open a PR against the target branch instead — mirroring
#      .github/workflows/refresh-packages-baseline.yml.
#
# The fallback PR is NOT auto-merged, on purpose. It is opened with the
# workflow's GITHUB_TOKEN, and GitHub's recursive-trigger guard means
# GITHUB_TOKEN-authored PRs never fire `pull_request` workflows — the target
# branch's required checks would sit "Expected" forever, so enabling
# auto-merge would just wedge silently. (The sibling
# refresh-packages-baseline.yml documents the same gotcha and also leaves its
# PR for a human.) A maintainer must eyeball the PNG diff and merge; closing
# and reopening the PR as a human retriggers CI if the required checks are
# wanted first.
#
# Contract:
#   - CWD is the repository root.
#   - The working tree already holds the refreshed, UNSTAGED baseline file(s).
#   - Writes `delivery=push|pr` (and `pr_url=...` for the PR path) to
#     $GITHUB_OUTPUT when set, so the workflow's step summary can report what
#     actually happened.
#
# Inputs (all via env, never spliced into an eval'd string — this preserves the
# workflow's Actions-injection-safe posture; see the workflow's security note):
#   SITES         which baseline(s) were refreshed (used in the title/body/branch)
#   TARGET_BRANCH branch the refresh lands on (github.ref_name)
#   RUN_ID        github.run_id — makes the throwaway branch name unique
#   RUN_ATTEMPT   github.run_attempt — keeps re-runs of a failed job unique too
#                 (a bare RUN_ID collides with the branch left by attempt 1)
#   ADD_PATHS     git pathspec(s) to stage (default: web/tests/visual-baselines/)
#   GH_TOKEN      token with BOTH contents:write and pull-requests:write
#
# SITES is constrained to the workflow's `choice` input list and RUN_ID /
# RUN_ATTEMPT are numeric, so all are safe to interpolate into the branch name
# and the --title/--body arguments (each reaches git/gh as a single argv
# element, never a shell-expanded command string).

set -euo pipefail

: "${SITES:?SITES is required}"
: "${TARGET_BRANCH:?TARGET_BRANCH is required}"
: "${RUN_ID:?RUN_ID is required}"
RUN_ATTEMPT="${RUN_ATTEMPT:-1}"
ADD_PATHS="${ADD_PATHS:-web/tests/visual-baselines/}"
GITHUB_OUTPUT="${GITHUB_OUTPUT:-/dev/null}"

git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
# Word-split ADD_PATHS on purpose so callers can pass multiple pathspecs; the
# value is workflow-controlled, never user input.
# shellcheck disable=SC2086
git add -- $ADD_PATHS

# Build the commit message in a temp file so the heredoc body stays readable and
# no value is spliced into a shell-expanded string. The subject stays a valid
# conventional commit <=100 chars, which the "Validate Commit Messages"
# required check lints against the PR title in the fallback path. The branch
# name lives on its own body line so a long TARGET_BRANCH can't push a body
# line past commitlint's 100-char body-max-line-length.
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

# Fast path: branches without a "changes must arrive via PR" rule (typically a
# PR's source branch, the flow the workflow header documents) still take the
# pre-#3283 direct push. The guard means a ruleset rejection (GH013) no longer
# fails the job — it falls through to the PR flow below.
if git push origin "HEAD:${TARGET_BRANCH}"; then
  echo "Pushed refreshed baseline(s) directly to ${TARGET_BRANCH} (branch accepts direct pushes)."
  echo "delivery=push" >> "$GITHUB_OUTPUT"
  exit 0
fi

echo "Direct push to ${TARGET_BRANCH} was rejected (ruleset requires a PR?) — opening a refresh PR instead."

branch="chore/refresh-baseline-${SITES}-${RUN_ID}-${RUN_ATTEMPT}"
git checkout -b "$branch"
git push -u origin "$branch"

pr_body_file="$(mktemp)"
{
  printf '%s\n\n' "## Summary"
  printf '%s\n\n' "Refreshes the visual-regression baseline(s) for \`$SITES\` so the \`visual-regression\` check reflects the intended rendering."
  printf '%s\n\n' "Opened automatically by \`.github/workflows/refresh-visual-baselines.yml\` (run \`$RUN_ID\`, attempt \`$RUN_ATTEMPT\`): the direct push was rejected because the \`$TARGET_BRANCH\` branch ruleset requires changes to arrive via a pull request."
  printf '%s\n\n' "> **Maintainer note:** this PR was opened with the workflow's \`GITHUB_TOKEN\`, so required checks will NOT start on their own (GitHub suppresses workflow triggers on GITHUB_TOKEN-authored PRs). Either close and reopen the PR to trigger CI, or eyeball the PNG diff below and merge."
  printf '%s\n' "## Test plan"
  printf '%s\n' "- [ ] The baseline diff contains only the intended content/layout change (not font/rendering drift)"
  printf '%s\n' "- [ ] After merge, \`visual-regression\` passes on the target branch's next run"
} > "$pr_body_file"

# gh prints the new PR's URL on stdout; capture it for the log + step summary.
pr_url="$(gh pr create \
  --base "$TARGET_BRANCH" \
  --head "$branch" \
  --title "chore(web): refresh visual baseline(s) ($SITES)" \
  --body-file "$pr_body_file")"

rm -f "$pr_body_file"

echo "Opened refresh PR: $pr_url"
echo "NOTE: required checks do not auto-run on GITHUB_TOKEN-authored PRs; a maintainer must"
echo "review the PNG diff and merge (or close/reopen the PR to trigger CI first)."
echo "delivery=pr" >> "$GITHUB_OUTPUT"
echo "pr_url=$pr_url" >> "$GITHUB_OUTPUT"
