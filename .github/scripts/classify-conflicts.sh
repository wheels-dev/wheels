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
    web/sites/*/src/content/*)  return 0 ;;  # content trees (any file; today md/mdx) — NOT web code
  esac
  return 1
}

files=()
if [ "$#" -gt 0 ]; then
  files=("$@")
else
  while IFS= read -r line || [ -n "$line" ]; do [ -n "$line" ] && files+=("$line"); done
fi

if [ "${#files[@]}" -eq 0 ]; then echo "escalate"; exit 0; fi

for f in "${files[@]}"; do
  if ! is_low_risk "$f"; then echo "escalate"; exit 0; fi
done
echo "resolve"
