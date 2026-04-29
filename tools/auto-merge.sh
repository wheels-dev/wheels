#!/usr/bin/env bash
#
# tools/auto-merge.sh
#
# Mechanical encoding of a project-author's standing PR-merge authorization,
# meant to be runnable from a cron / scheduled-task loop without further
# human review.  The rules below are derived from a workstation-private
# CLAUDE.local.md; this script is the source of truth for any agent doing
# auto-merge on the author's behalf.
#
# TIERS
# -----
#
#   trivia tier  — every changed file matches a trivia pattern (top-level
#                  *.md, .gitignore, .gitattributes, .editorconfig).
#                  Merge action: `gh pr merge --auto --squash --delete-branch`
#                  (--auto fires the moment required checks pass; safe
#                  because the change cannot affect runtime behaviour).
#
#   code tier    — anything else. Merge action: `gh pr merge --squash
#                  --delete-branch` (NO --auto — caller must already have
#                  confirmed the FULL check suite is green, not just the
#                  required-checks subset). When in doubt, treat as code.
#
# UNIVERSAL GATES (must be satisfied by BOTH tiers)
# -------------------------------------------------
#
#   1. PR is OPEN (not closed/merged)
#   2. PR author == current `gh api user .login` (refuse to merge others')
#   3. baseRefName == "develop" (NEVER main / master / feature branches)
#   4. mergeable == "MERGEABLE" (no merge conflicts)
#   5. mergeStateStatus == "CLEAN" (branch up-to-date with base; full
#      check suite green; no required reviews outstanding)
#   6. reviewRequests is empty (no reviewer waiting to weigh in)
#   7. reviewDecision is "" or "APPROVED" (NOT "CHANGES_REQUESTED")
#   8. Every check in statusCheckRollup has conclusion=="SUCCESS" — no
#      FAILURE, IN_PROGRESS, PENDING, QUEUED, CANCELLED, or SKIPPED
#      that would block.
#
# When a gate fails, the script prints a one-line diagnosis identifying
# which gate blocked the merge.
#
# EXIT CODES
# ----------
#
#   0   At least one PR was merged (or is eligible, in --check mode).
#   1   No PRs were eligible. Expected exit code for a quiet cron tick.
#   2   Usage error, missing dependency, or fatal API failure.
#
# USAGE
# -----
#
#   tools/auto-merge.sh <pr-number>             Evaluate + merge one PR.
#   tools/auto-merge.sh --check <pr-number>     Evaluate one PR; never merge.
#   tools/auto-merge.sh --all                   Evaluate + merge every open PR
#                                               authored by current gh user.
#   tools/auto-merge.sh --all --check           Dry-run over every PR.
#                                               Recommended for cron preview.

set -u
set -o pipefail
# Deliberately NOT using `set -e`: --all mode must continue evaluating
# remaining PRs after any single PR turns out ineligible. Return codes
# are checked explicitly at every branch.

readonly SCRIPT_NAME="$(basename "$0")"

# ----------------------------------------------------------------------
# Output helpers (TTY-aware colours)
# ----------------------------------------------------------------------

if [[ -t 1 ]]; then
    readonly C_RED=$'\033[31m' C_GREEN=$'\033[32m' C_YELLOW=$'\033[33m'
    readonly C_BLUE=$'\033[34m' C_RESET=$'\033[0m'
else
    readonly C_RED='' C_GREEN='' C_YELLOW='' C_BLUE='' C_RESET=''
fi

ok()    { echo "${C_GREEN}✓${C_RESET} $*"; }
no()    { echo "${C_RED}✗${C_RESET} $*"; }
info()  { echo "${C_BLUE}·${C_RESET} $*"; }
warn()  { echo "${C_YELLOW}!${C_RESET} $*" >&2; }
fatal() { echo "${C_RED}fatal:${C_RESET} $*" >&2; exit 2; }

# ----------------------------------------------------------------------
# Argument parsing
# ----------------------------------------------------------------------

usage() {
    cat <<EOF
${SCRIPT_NAME} — apply standing merge authorization to gh PRs

USAGE
  ${SCRIPT_NAME} <pr>                 Evaluate + merge if eligible.
  ${SCRIPT_NAME} --check <pr>         Evaluate only, no merge.
  ${SCRIPT_NAME} --all                Evaluate + merge all your open PRs.
  ${SCRIPT_NAME} --all --check        Dry-run over all your open PRs.

EXIT CODES
  0  At least one PR was merged (or eligible, in --check).
  1  No PRs eligible — normal for a quiet cron tick.
  2  Usage error or fatal.

See the script header for the full gate definitions.
EOF
}

CHECK_ONLY=0
ALL=0
TARGET_PR=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --check)   CHECK_ONLY=1; shift ;;
        --all)     ALL=1;        shift ;;
        --help|-h) usage; exit 0 ;;
        --)        shift; break ;;
        -*)        warn "unknown flag: $1"; usage; exit 2 ;;
        *)         if [[ -n "$TARGET_PR" ]]; then
                       warn "multiple PR numbers given; expected one"
                       usage; exit 2
                   fi
                   TARGET_PR="$1"; shift ;;
    esac
done

if [[ "$ALL" = 0 && -z "$TARGET_PR" ]]; then
    warn "must provide either --all or a PR number"
    usage; exit 2
fi
if [[ "$ALL" = 1 && -n "$TARGET_PR" ]]; then
    warn "cannot combine --all with a specific PR number"
    usage; exit 2
fi

command -v gh >/dev/null 2>&1 || fatal "gh CLI not found in PATH"
command -v jq >/dev/null 2>&1 || fatal "jq not found in PATH"

# ----------------------------------------------------------------------
# Tier classification
#
# Conservative: ANY file outside the trivia-pattern set forces code tier.
# Trivia patterns apply ONLY at the repo root (no slash in path), since
# CLAUDE.local.md classifies anything under docs/, tests/, etc. as code.
# ----------------------------------------------------------------------

classify_tier() {
    local files_json="$1"
    local n_total n_trivia
    n_total=$(echo "$files_json" | jq 'length')
    [[ "$n_total" -eq 0 ]] && { echo "code"; return; }

    n_trivia=$(echo "$files_json" | jq '[
        .[].path
        | select(contains("/") | not)
        | select(test("^(\\.gitignore|\\.gitattributes|\\.editorconfig)$") or test("\\.md$"))
    ] | length')

    if [[ "$n_total" -eq "$n_trivia" ]]; then
        echo "trivia"
    else
        echo "code"
    fi
}

# ----------------------------------------------------------------------
# PR evaluation
#
# Sets globals EVAL_TIER and EVAL_REASON; returns 0 if eligible, 1 otherwise.
# Prints per-gate diagnostics in order, stopping at the first failed gate.
# ----------------------------------------------------------------------

EVAL_TIER=""
EVAL_REASON=""

eval_pr() {
    local pr="$1"
    EVAL_TIER=""
    EVAL_REASON=""

    local data
    if ! data=$(gh pr view "$pr" --json \
        number,title,state,author,baseRefName,mergeable,mergeStateStatus,reviewDecision,reviewRequests,statusCheckRollup,files \
        2>/dev/null); then
        EVAL_REASON="failed to fetch PR (does it exist? are credentials valid?)"
        no "PR #$pr — $EVAL_REASON"
        return 1
    fi

    local title state author base mergeable merge_state review n_reviewers
    title=$(echo "$data"        | jq -r '.title')
    state=$(echo "$data"        | jq -r '.state')
    author=$(echo "$data"       | jq -r '.author.login')
    base=$(echo "$data"         | jq -r '.baseRefName')
    mergeable=$(echo "$data"    | jq -r '.mergeable')
    merge_state=$(echo "$data"  | jq -r '.mergeStateStatus')
    review=$(echo "$data"       | jq -r '.reviewDecision // ""')
    n_reviewers=$(echo "$data"  | jq    '.reviewRequests | length')

    info "PR #$pr — $title"

    # Gate 1: open
    if [[ "$state" != "OPEN" ]]; then
        EVAL_REASON="state=$state (need OPEN)"
        no "  $EVAL_REASON"; return 1
    fi
    ok "  state OPEN"

    # Gate 2: author == current gh user
    local me
    me=$(gh api user --jq .login 2>/dev/null) || me=""
    if [[ -n "$me" && "$author" != "$me" ]]; then
        EVAL_REASON="author=$author (current user is $me — refusing to merge another author's PR)"
        no "  $EVAL_REASON"; return 1
    fi
    ok "  author $author"

    # Gate 3: base branch
    if [[ "$base" != "develop" ]]; then
        EVAL_REASON="baseRefName=$base (must target develop)"
        no "  $EVAL_REASON"; return 1
    fi
    ok "  base $base"

    # Gate 4: no merge conflicts
    if [[ "$mergeable" != "MERGEABLE" ]]; then
        EVAL_REASON="mergeable=$mergeable (often transient just after a parent merge — retry shortly)"
        no "  $EVAL_REASON"; return 1
    fi
    ok "  mergeable"

    # Gate 5: clean merge state
    if [[ "$merge_state" != "CLEAN" ]]; then
        EVAL_REASON="mergeStateStatus=$merge_state (BEHIND = update branch first; UNSTABLE = a non-required check failed; UNKNOWN = recompute pending)"
        no "  $EVAL_REASON"; return 1
    fi
    ok "  mergeStateStatus CLEAN"

    # Gate 6: no requested reviewers pending
    if [[ "$n_reviewers" -gt 0 ]]; then
        EVAL_REASON="$n_reviewers reviewer(s) requested — wait for review"
        no "  $EVAL_REASON"; return 1
    fi
    ok "  no requested reviewers"

    # Gate 7: review decision not CHANGES_REQUESTED
    if [[ "$review" == "CHANGES_REQUESTED" ]]; then
        EVAL_REASON="reviewDecision=CHANGES_REQUESTED — address feedback first"
        no "  $EVAL_REASON"; return 1
    fi
    ok "  review decision: ${review:-none}"

    # Gate 8: every check SUCCESS
    local n_checks n_success non_success_summary
    n_checks=$(echo "$data" | jq '.statusCheckRollup | length')
    n_success=$(echo "$data" | jq '[.statusCheckRollup[]
        | select(.conclusion == "SUCCESS")] | length')
    non_success_summary=$(echo "$data" | jq -r '[.statusCheckRollup[]
        | select(.conclusion != "SUCCESS")
        | "\(.name) [\(.status // "?")/\(.conclusion // "—")]"]
        | join(", ")')

    if [[ "$n_checks" -eq 0 ]]; then
        EVAL_REASON="no checks attached to PR — refusing to merge unverified code"
        no "  $EVAL_REASON"; return 1
    fi
    if [[ "$n_success" -ne "$n_checks" ]]; then
        EVAL_REASON="$((n_checks - n_success))/$n_checks checks not SUCCESS: $non_success_summary"
        no "  $EVAL_REASON"; return 1
    fi
    ok "  $n_success/$n_checks checks SUCCESS"

    # Tier classification (gates passed; this is purely informational
    # but determines the merge command used downstream).
    EVAL_TIER=$(classify_tier "$(echo "$data" | jq '.files')")
    ok "  tier: $EVAL_TIER"

    return 0
}

# ----------------------------------------------------------------------
# Merge driver
# ----------------------------------------------------------------------

merge_pr() {
    local pr="$1"
    local tier="$2"
    local merge_args=("--squash" "--delete-branch")
    [[ "$tier" = "trivia" ]] && merge_args+=("--auto")

    if [[ "$CHECK_ONLY" = 1 ]]; then
        ok "PR #$pr would merge ($tier tier — \`gh pr merge $pr ${merge_args[*]}\`)"
        return 0
    fi

    info "merging PR #$pr ($tier tier)..."
    local merge_output
    merge_output=$(gh pr merge "$pr" "${merge_args[@]}" 2>&1)
    local merge_rc=$?

    # `gh pr merge` can exit non-zero even when the server-side merge AND
    # branch deletion both succeeded. The most common cause: gh's
    # post-merge step that fast-forwards the local default branch fails
    # because that branch is checked out in a sibling git worktree
    # ("fatal: 'develop' is already used by worktree at..."). Treating
    # that exit code as failure would break every cron-driven merge in
    # any setup that uses worktrees. Disambiguate by re-querying state.
    local actual_state
    actual_state=$(gh pr view "$pr" --json state --jq .state 2>/dev/null)

    if [[ "$actual_state" == "MERGED" ]]; then
        local sha
        sha=$(gh pr view "$pr" --json mergeCommit --jq '.mergeCommit.oid // ""' 2>/dev/null)
        ok "PR #$pr merged${sha:+ — $sha}"
        if [[ "$merge_rc" -ne 0 ]]; then
            # Surface the cosmetic error so the operator can see it, but
            # don't treat the merge itself as failed.
            warn "  gh exited $merge_rc (cosmetic local-git error; remote merge + branch delete succeeded):"
            echo "$merge_output" | sed 's/^/    /' >&2
        fi
        return 0
    else
        warn "PR #$pr merge command failed (state=$actual_state, gh exit=$merge_rc):"
        echo "$merge_output" | sed 's/^/    /' >&2
        return 1
    fi
}

# ----------------------------------------------------------------------
# Main
# ----------------------------------------------------------------------

declare -i ELIGIBLE=0
declare -i MERGED=0
declare -i SKIPPED=0
declare -i FAILED=0

process_pr() {
    local pr="$1"
    if eval_pr "$pr"; then
        ELIGIBLE+=1
        if merge_pr "$pr" "$EVAL_TIER"; then
            MERGED+=1
        else
            FAILED+=1
        fi
    else
        SKIPPED+=1
    fi
    echo
}

if [[ "$ALL" = 1 ]]; then
    info "listing your open PRs..."
    prs=$(gh pr list --author @me --state open --json number --jq '.[].number' 2>/dev/null) \
        || fatal "gh pr list failed"
    if [[ -z "$prs" ]]; then
        info "no open PRs"
        exit 1
    fi
    for pr in $prs; do
        process_pr "$pr"
    done
    info "summary: $ELIGIBLE eligible / $MERGED merged / $SKIPPED skipped / $FAILED failed"
else
    process_pr "$TARGET_PR"
fi

if [[ "$CHECK_ONLY" = 1 ]]; then
    [[ "$ELIGIBLE" -gt 0 ]] && exit 0 || exit 1
else
    [[ "$MERGED" -gt 0 ]] && exit 0 || exit 1
fi
