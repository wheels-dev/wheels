#!/usr/bin/env bash
# Publish scheduled blog posts whose publishedAt date is today or earlier (UTC).
#
# Moves each web/content/blog/scheduled/*.md that is due into
# web/content/blog/posts/, commits as wheels-bot[bot] on a
# docs/bot-blog-publish-<YYYYMMDD> branch, and opens a PR against develop.
#
# develop's branch protection rejects direct pushes (GH013), so the publish
# lands through a PR. Merging that PR pushes the new posts to develop, which
# triggers (a) the blog deploy (web-deploy.yml) and (b) the announcement
# workflow (blog-announce-on-publish.yml). The announcement is intentionally
# NOT done here — only after the publish is durable on develop.
#
# Idempotent: the branch is day-scoped, so a second run the same day is the
# same publish. If the branch already exists on origin, the publish is already
# queued and this run exits 0. Posts whose day was missed (failed or skipped
# run) publish on the next successful run — catch-up, never stranded.
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

SOURCE_DIR="web/content/blog/scheduled"
TARGET_DIR="web/content/blog/posts"
REPO="${GITHUB_REPOSITORY:-wheels-dev/wheels}"

if [ ! -d "$SOURCE_DIR" ]; then
  echo "No scheduled directory at $SOURCE_DIR — nothing to do."
  exit 0
fi

TODAY="$(date -u +%Y-%m-%d)"
BRANCH="docs/bot-blog-publish-$(date -u +%Y%m%d)"
echo "Publishing scheduled posts due on or before $TODAY (UTC)..."

# Idempotency: if this day's branch already exists on origin, its publish PR
# is already open (or was closed) — do not recreate the branch or push again.
if git ls-remote --exit-code --heads origin "$BRANCH" >/dev/null 2>&1; then
  echo "Branch $BRANCH already exists on origin — this day's publish is already queued. Nothing to do."
  exit 0
fi

published=()
for file in "$SOURCE_DIR"/*.md; do
  # Skip the README (it has no publishedAt).
  [ -e "$file" ] || continue
  [ "$(basename "$file")" = "README.md" ] && continue

  # publishedAt looks like: publishedAt: '2026-09-02T14:00:00.000Z'
  due_date="$(sed -nE "s/^publishedAt: *'([0-9]{4}-[0-9]{2}-[0-9]{2}).*/\1/p" "$file" | head -n 1)"

  if [ -z "$due_date" ]; then
    echo "WARNING: $(basename "$file") has no parseable publishedAt — skipping."
    continue
  fi

  # ISO dates compare lexicographically.
  if [[ "$due_date" > "$TODAY" ]]; then
    echo "  future: $(basename "$file") (due $due_date)"
    continue
  fi

  echo "  publishing: $(basename "$file") (due $due_date)"
  git mv "$file" "$TARGET_DIR/$(basename "$file")"
  published+=("$(basename "$file" .md)")
done

if [ ${#published[@]} -eq 0 ]; then
  echo "Nothing due today. Done."
  exit 0
fi

git config user.name "wheels-bot[bot]"
git config user.email "wheels-bot[bot]@users.noreply.github.com"

git checkout -b "$BRANCH"

count=${#published[@]}
slug_list="$(printf ', %s' "${published[@]}")"
slug_list="${slug_list:2}"

git add "$TARGET_DIR"
git commit -m "docs(blog): publish $count scheduled post(s)" -m "Published by the scheduled blog publisher.

Slugs: $slug_list" || {
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
  echo "Automated scheduled publish: moved $count due post(s) from \`web/content/blog/scheduled/\` into \`web/content/blog/posts/\`."
  echo ""
  echo "Merging this PR pushes the posts to develop, which triggers the blog deploy and the announcement workflow (\`blog-announce-on-publish.yml\`). No Discussions are created here."
  echo ""
  echo "Slugs: $slug_list"
  echo ""
  echo "🤖 Opened automatically by \`.github/workflows/blog-publish-scheduled.yml\`."
} > "$pr_body_file"

pr_url="$(gh pr create \
  --repo "$REPO" \
  --base develop \
  --head "$BRANCH" \
  --title "docs(blog): publish $count scheduled post(s)" \
  --body-file "$pr_body_file")"
rm -f "$pr_body_file"

echo "Opened $pr_url for $count post(s): $slug_list"
