#!/usr/bin/env bash
# generate-changelog.sh - Generate changelog entries from merged PRs
#
# Usage:
#   ./tools/build/scripts/generate-changelog.sh [version] [since-tag] [--write]
#
# Examples:
#   ./tools/build/scripts/generate-changelog.sh 3.1.0 v3.0.0+44
#   ./tools/build/scripts/generate-changelog.sh 3.1.0 v3.0.0+44 --write
#   ./tools/build/scripts/generate-changelog.sh            # auto-detect version and last tag
#
# Requires: gh CLI (authenticated), jq
#
# Categorizes merged PRs by their GitHub labels into the Wheels changelog format.
# PRs without labels are categorized by title keywords or go into "Miscellaneous".

set -euo pipefail

REPO="wheels-dev/wheels"

# Auto-detect version from box.json if not provided
VERSION="${1:-}"
if [ -z "$VERSION" ]; then
  if [ -f "templates/base/src/box.json" ]; then
    VERSION=$(jq -r '.version' templates/base/src/box.json)
    VERSION="${VERSION%-SNAPSHOT}"
  else
    echo "ERROR: Cannot detect version. Provide it as first argument or run from repo root."
    exit 1
  fi
fi

# Auto-detect the last release tag if not provided
SINCE_TAG="${2:-}"
if [ -z "$SINCE_TAG" ]; then
  SINCE_TAG=$(git tag --list 'v*' --sort=-version:refname | head -1)
  if [ -z "$SINCE_TAG" ]; then
    echo "ERROR: No release tags found. Provide a tag as second argument."
    exit 1
  fi
fi

echo "Generating changelog for version $VERSION since $SINCE_TAG"
echo "Repository: $REPO"
echo ""

# Get the date of the since-tag
SINCE_DATE=$(git log -1 --format=%aI "$SINCE_TAG" 2>/dev/null || echo "2024-01-01T00:00:00Z")

# Fetch all merged PRs since the tag date
PRS_JSON=$(gh pr list \
  --repo "$REPO" \
  --state merged \
  --base develop \
  --limit 500 \
  --json number,title,labels,mergedAt,author,url \
  --jq "[.[] | select(.mergedAt > \"$SINCE_DATE\")]")

PRS_MAIN=$(gh pr list \
  --repo "$REPO" \
  --state merged \
  --base main \
  --limit 500 \
  --json number,title,labels,mergedAt,author,url \
  --jq "[.[] | select(.mergedAt > \"$SINCE_DATE\")]")

# Merge both lists and deduplicate by PR number
PRS_JSON=$(echo "$PRS_JSON $PRS_MAIN" | jq -s 'add | unique_by(.number) | sort_by(.number)')

PR_COUNT=$(echo "$PRS_JSON" | jq length)
echo "Found $PR_COUNT merged PRs since $SINCE_TAG"
echo ""

# Use temp files for categories (bash 3 compatible - no associative arrays)
TMPDIR_CATS=$(mktemp -d)
for cat in controller model view bug cli misc docs breaking enhancement; do
  touch "$TMPDIR_CATS/$cat"
done

# Categorize a PR by its labels and title
categorize_pr() {
  local labels="$1"
  local title="$2"
  local lower_title
  lower_title=$(echo "$title" | tr '[:upper:]' '[:lower:]')

  # Check labels first
  if echo "$labels" | jq -e 'any(.[]; .name == "breaking")' > /dev/null 2>&1; then
    echo "breaking"; return
  fi
  if echo "$labels" | jq -e 'any(.[]; .name == "bug")' > /dev/null 2>&1; then
    echo "bug"; return
  fi
  if echo "$labels" | jq -e 'any(.[]; .name == "docs")' > /dev/null 2>&1; then
    echo "docs"; return
  fi
  if echo "$labels" | jq -e 'any(.[]; .name == "enhancement")' > /dev/null 2>&1; then
    if echo "$lower_title" | grep -qiE '(model|orm|association|validation|callback|findall|findone|hasone|hasmany|belongsto)'; then
      echo "model"; return
    fi
    if echo "$lower_title" | grep -qiE '(controller|filter|action|redirect|render|verify|verifies|provides)'; then
      echo "controller"; return
    fi
    if echo "$lower_title" | grep -qiE '(view|template|partial|layout|form|link|helper|css|javascript|asset|pagination)'; then
      echo "view"; return
    fi
    echo "enhancement"; return
  fi

  # No recognized label - categorize by title keywords
  if echo "$lower_title" | grep -qiE '(fix|bug|patch|hotfix|issue|error|crash|broken)'; then
    echo "bug"; return
  fi
  if echo "$lower_title" | grep -qiE '(doc|guide|readme|changelog|typo|spelling)'; then
    echo "docs"; return
  fi
  if echo "$lower_title" | grep -qiE '(cli|command|generate|scaffold|dbmigrate|server)'; then
    echo "cli"; return
  fi

  echo "misc"
}

# Process each PR
i=0
while [ "$i" -lt "$PR_COUNT" ]; do
  PR=$(echo "$PRS_JSON" | jq ".[$i]")
  NUMBER=$(echo "$PR" | jq -r '.number')
  TITLE=$(echo "$PR" | jq -r '.title')
  LABELS=$(echo "$PR" | jq '.labels')

  # Clean up title - remove "commit: " prefix
  TITLE=$(echo "$TITLE" | sed 's/^commit: //' | sed 's/^Commit: //')
  # Capitalize first letter
  FIRST_CHAR=$(echo "$TITLE" | cut -c1 | tr '[:lower:]' '[:upper:]')
  REST=$(echo "$TITLE" | cut -c2-)
  TITLE="${FIRST_CHAR}${REST}"

  CATEGORY=$(categorize_pr "$LABELS" "$TITLE")
  ENTRY="- $TITLE ([#$NUMBER](https://github.com/$REPO/pull/$NUMBER))"

  echo "$ENTRY" >> "$TMPDIR_CATS/$CATEGORY"

  i=$((i + 1))
done

# Generate output
TODAY=$(date +%Y-%m-%d)
OUTPUT="# [$VERSION](https://github.com/$REPO/releases/tag/v$VERSION) => $TODAY"
OUTPUT="$OUTPUT

"

append_section() {
  local file="$1"
  local header="$2"
  if [ -s "$file" ]; then
    OUTPUT="$OUTPUT### $header

$(cat "$file")

"
  fi
}

append_section "$TMPDIR_CATS/controller" "Controller Enhancements"
append_section "$TMPDIR_CATS/model" "Model Enhancements"
append_section "$TMPDIR_CATS/view" "View Enhancements"
append_section "$TMPDIR_CATS/bug" "Bug Fixes"
append_section "$TMPDIR_CATS/cli" "CLI Enhancements"
append_section "$TMPDIR_CATS/enhancement" "Enhancements"
append_section "$TMPDIR_CATS/docs" "Guides"
append_section "$TMPDIR_CATS/misc" "Miscellaneous"
append_section "$TMPDIR_CATS/breaking" "Potentially Breaking Changes"

OUTPUT="$OUTPUT---"

# Clean up temp files
rm -rf "$TMPDIR_CATS"

echo "=========================================="
echo "Generated Changelog"
echo "=========================================="
echo ""
echo "$OUTPUT"

# If --write flag is passed, insert into CHANGELOG.md
if [ "${3:-}" = "--write" ]; then
  if [ ! -f "CHANGELOG.md" ]; then
    echo "ERROR: CHANGELOG.md not found in current directory"
    exit 1
  fi

  TEMP_FILE=$(mktemp)

  # Find the line number of the first version header
  FIRST_VERSION_LINE=$(grep -n '^# \[' CHANGELOG.md | head -1 | cut -d: -f1)

  if [ -z "$FIRST_VERSION_LINE" ]; then
    echo "ERROR: Cannot find existing version entry in CHANGELOG.md"
    exit 1
  fi

  # Check if this version already exists in the changelog
  if grep -q "^# \[$VERSION\]" CHANGELOG.md; then
    echo ""
    echo "WARNING: Version $VERSION already exists in CHANGELOG.md"
    echo "Replacing existing entry..."

    EXISTING_START=$(grep -n "^# \[$VERSION\]" CHANGELOG.md | head -1 | cut -d: -f1)
    EXISTING_END=$(awk "NR > $EXISTING_START && /^# \[/ { print NR; exit }" CHANGELOG.md)

    if [ -z "$EXISTING_END" ]; then
      EXISTING_END=$(awk "NR > $EXISTING_START && /^---\$/ { print NR; exit }" CHANGELOG.md)
      EXISTING_END=$((EXISTING_END + 1))
    fi

    head -n $((EXISTING_START - 1)) CHANGELOG.md > "$TEMP_FILE"
    echo "" >> "$TEMP_FILE"
    echo "$OUTPUT" >> "$TEMP_FILE"
    echo "" >> "$TEMP_FILE"
    tail -n +"$EXISTING_END" CHANGELOG.md >> "$TEMP_FILE"
  else
    # Insert new version before the first existing version
    head -n $((FIRST_VERSION_LINE - 1)) CHANGELOG.md > "$TEMP_FILE"
    echo "$OUTPUT" >> "$TEMP_FILE"
    echo "" >> "$TEMP_FILE"
    tail -n +"$FIRST_VERSION_LINE" CHANGELOG.md >> "$TEMP_FILE"
  fi

  mv "$TEMP_FILE" CHANGELOG.md
  echo ""
  echo "CHANGELOG.md updated successfully!"
fi
