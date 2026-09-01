#!/usr/bin/env bash
# Publish scheduled blog posts whose publishedAt date is today or earlier (UTC).
#
# Moves each web/content/blog/scheduled/*.md that is due into
# web/content/blog/posts/, commits as wheels-bot[bot], and pushes. The push
# triggers the blog deploy workflow (blog_content_changed).
#
# Idempotent: after a successful run there is nothing left to move, so
# re-running the same day is a no-op. Posts whose day was missed (failed or
# skipped run) publish on the next successful run — catch-up, never stranded.
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

SOURCE_DIR="web/content/blog/scheduled"
TARGET_DIR="web/content/blog/posts"

if [ ! -d "$SOURCE_DIR" ]; then
  echo "No scheduled directory at $SOURCE_DIR — nothing to do."
  exit 0
fi

TODAY="$(date -u +%Y-%m-%d)"
echo "Publishing scheduled posts due on or before $TODAY (UTC)..."

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

git push origin HEAD

echo "Published $count post(s): $slug_list"
