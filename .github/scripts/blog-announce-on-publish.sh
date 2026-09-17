#!/usr/bin/env bash
# Announce newly-published blog posts to the GitHub Discussions board.
#
# Runs from blog-announce-on-publish.yml after a push to develop touches
# web/content/blog/posts/** (the publish PR merged), or on workflow_dispatch.
#
# 1. Identify candidate posts:
#    - push: files added/modified under web/content/blog/posts/ by this push.
#    - workflow_dispatch (or a push with no resolvable base): every post whose
#      `announcement:` block still lacks a `discussionUrl` (backfill).
# 2. Run web/scripts/blog-announce-discussion.mjs over the candidates. The
#    dedupe already lives in that script: before creating a discussion it
#    searches existing Announcements by exact title and/or the post's blog URL,
#    and on a hit writes that URL back instead of creating a duplicate.
# 3. If the frontmatter gained a discussionUrl, commit it on
#    docs/bot-blog-announce-<shortsha> and open a tiny PR to develop (same
#    pattern as the publish workflow — never push to develop directly).
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

REPO="${REPO:-${GITHUB_REPOSITORY:-wheels-dev/wheels}}"
EVENT_NAME="${EVENT_NAME:-${GITHUB_EVENT_NAME:-}}"
POSTS_DIR="web/content/blog/posts"

# --- 1. Collect candidate posts -------------------------------------------

# A post still needs announcing when its frontmatter has an `announcement:`
# block without a `discussionUrl:` line. Scoped to the frontmatter (between
# the first and second `---` fences) so a `discussionUrl` mention in the body
# prose doesn't suppress a real announcement.
needs_announcement() {
  awk '
    /^---[ \t]*$/ { fences++; next }
    fences == 1 {
      if ($0 ~ /^announcement:[ \t]*$/) ann = 1
      if ($0 ~ /discussionUrl:/) url = 1
    }
    END { exit (ann && !url ? 0 : 1) }
  ' "$1"
}

candidates=()

if [ "$EVENT_NAME" = "push" ]; then
  before="${BEFORE_SHA:-}"
  after="${HEAD_SHA:-$GITHUB_SHA}"
  if [ -n "$before" ] && [ "$before" != "0000000000000000000000000000000000000000" ]; then
    mapfile -t candidates < <(git diff --name-only --diff-filter=AM "$before" "$after" -- "$POSTS_DIR" || true)
  fi
fi

if [ ${#candidates[@]} -eq 0 ]; then
  # workflow_dispatch, or a push with no resolvable base: scan every post.
  for f in "$POSTS_DIR"/*.md; do
    [ -e "$f" ] || continue
    if needs_announcement "$f"; then
      candidates+=("$f")
    fi
  done
fi

if [ ${#candidates[@]} -eq 0 ]; then
  echo "No posts need announcing. Done."
  exit 0
fi

echo "Candidate posts (${#candidates[@]}):"
printf '  %s\n' "${candidates[@]}"

# --- 2. Announce (dedupe lives inside the .mjs) ---------------------------
node web/scripts/blog-announce-discussion.mjs "${candidates[@]}"

# --- 3. Commit any discussionUrl writeback and open a PR -------------------
# The .mjs writes discussionUrl back into the post frontmatter when it posts
# (or links an existing) discussion. If nothing changed, there is nothing to
# commit — the writeback may already be on develop, or none of the candidates
# carried an announcement block.
if git diff --quiet -- "$POSTS_DIR" && git diff --cached --quiet -- "$POSTS_DIR"; then
  echo "No discussionUrl writeback produced — nothing to commit."
  exit 0
fi

git config user.name "wheels-bot[bot]"
git config user.email "wheels-bot[bot]@users.noreply.github.com"

shortsha="$(git rev-parse --short=7 HEAD)"
branch="docs/bot-blog-announce-${shortsha}"

# Idempotency: if this branch already exists on origin, the writeback for this
# develop HEAD is already queued — do not recreate it.
if git ls-remote --exit-code --heads origin "$branch" >/dev/null 2>&1; then
  echo "Branch $branch already exists on origin — announce writeback is already queued. Nothing to do."
  exit 0
fi

git checkout -b "$branch"

git add "$POSTS_DIR"
git commit -m "docs(blog): record discussion announcements" -m "Write back discussionUrl for newly-published posts.

Opened by blog-announce-on-publish.yml after a publish PR merged to develop." || {
  echo "Commit failed or nothing to commit — checking status."
  git status --short
  exit 1
}

git push -u origin HEAD

# Open the PR. The docs/bot-* branch prefix makes the required
# "Bot PR TDD Gate" a declared no-op (bot-tdd-gate.yml) for this
# docs-content-only PR.
pr_body_file="$(mktemp)"
{
  echo "## Summary"
  echo ""
  echo "Record the Discussion URLs created for newly-published blog posts by writing \`announcement.discussionUrl\` back into the post frontmatter (the idempotency marker that makes future announces a no-op)."
  echo ""
  echo "🤖 Opened automatically by \`.github/workflows/blog-announce-on-publish.yml\`."
} > "$pr_body_file"

pr_url="$(gh pr create \
  --repo "$REPO" \
  --base develop \
  --head "$branch" \
  --title "docs(blog): record discussion announcements" \
  --body-file "$pr_body_file")"
rm -f "$pr_body_file"

echo "Opened $pr_url"
