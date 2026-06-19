#!/usr/bin/env bash
# Tests tools/changelog-promote.sh in a hermetic fixture (never reads or
# mutates the real CHANGELOG.md or changelog.d/). Covers the SIGPIPE fix
# (#2958): `--preview | head` must exit silently like `cat | head` instead of
# spraying a BrokenPipeError traceback, plus preview/promote regressions.
#
# Dev-run only (like the sibling tools/test-*.sh scripts — not wired into CI):
#   bash tools/test-changelog-promote.sh
set -uo pipefail

TOOLS_DIR="$(cd "$(dirname "$0")" && pwd)"
fail=0
tmpdirs=()
cleanup() { for d in "${tmpdirs[@]:-}"; do [ -n "$d" ] && rm -rf "$d"; done; }
trap cleanup EXIT

ok()  { echo "ok:   $1"; }
bad() { echo "FAIL: $1"; fail=1; }

# Builds a throwaway project root in $tmp. The script under test derives
# PROJECT_ROOT from its own dirname/.., so the copy operates entirely in $tmp.
make_fixture() {
  tmp="$(mktemp -d)"
  tmpdirs+=("$tmp")
  mkdir -p "$tmp/tools" "$tmp/changelog.d"
  cp "$TOOLS_DIR/changelog-promote.sh" "$tmp/tools/"
  cat >"$tmp/CHANGELOG.md" <<'EOF'
# Changelog

## [Unreleased]

## [0.0.1] - 2020-01-01

### Fixed

- baseline bullet (#0)
EOF
  # One big fragment: >64KB of preview output guarantees the pipe buffer
  # overflows after `head -1` exits, so SIGPIPE deterministically fires.
  local pad i
  pad="$(printf 'x%.0s' {1..400})"
  : >"$tmp/changelog.d/big.fixed.md"
  for i in $(seq 1 300); do
    printf -- '- padding entry %03d %s (#1)\n' "$i" "$pad" >>"$tmp/changelog.d/big.fixed.md"
  done
}

# Test 1: --preview piped into head must not spray a traceback (#2958).
make_fixture
"$tmp/tools/changelog-promote.sh" --preview 2>"$tmp/err" | head -1 >"$tmp/out"
if grep -q "BrokenPipeError" "$tmp/err" || grep -q "Traceback" "$tmp/err"; then
  bad "--preview | head sprayed a traceback on stderr:"
  sed 's/^/      /' "$tmp/err"
else
  ok "--preview | head leaves stderr clean"
fi
if [ "$(head -1 "$tmp/out")" = "### Fixed" ]; then
  ok "--preview | head -1 prints '### Fixed'"
else
  bad "--preview | head -1 printed '$(head -1 "$tmp/out")' (expected '### Fixed')"
fi

# Test 2: unpiped --preview still exits 0 with empty stderr.
make_fixture
"$tmp/tools/changelog-promote.sh" --preview >/dev/null 2>"$tmp/err"
rc=$?
if [ "$rc" -eq 0 ]; then
  ok "--preview (unpiped) exits 0"
else
  bad "--preview (unpiped) exited $rc"
fi
if [ ! -s "$tmp/err" ]; then
  ok "--preview (unpiped) stderr is empty"
else
  bad "--preview (unpiped) wrote to stderr:"
  sed 's/^/      /' "$tmp/err"
fi

# Test 3: promote path regression — restoring default SIGPIPE must not change
# behavior when stdout stays open (all file mutations precede stdout writes).
make_fixture
"$tmp/tools/changelog-promote.sh" 1.2.3 2026-01-01 >"$tmp/pout" 2>"$tmp/perr"
rc=$?
if [ "$rc" -eq 0 ]; then
  ok "promote exits 0"
else
  bad "promote exited $rc:"
  sed 's/^/      /' "$tmp/perr"
fi
if grep -qE '^# \[1\.2\.3\]\(https://github.com/wheels-dev/wheels/releases/tag/v1\.2\.3\) => 2026-01-01$' "$tmp/CHANGELOG.md"; then
  ok "promote wrote the '# [1.2.3](tag) => 2026-01-01' section"
else
  bad "CHANGELOG.md is missing the promoted version section (expected single-hash, tag-linked, '=>' header)"
fi
if [ ! -e "$tmp/changelog.d/big.fixed.md" ]; then
  ok "promote deleted the fragment"
else
  bad "promote left the fragment behind"
fi
if grep -q 'Removed 1 fragment' "$tmp/pout"; then
  ok "promote summary reports the removed fragment"
else
  bad "promote summary missing 'Removed 1 fragment'"
fi

# Test 5: consolidation — a heading that appears twice in [Unreleased] plus a
# matching fragment must collapse into ONE section in canonical order, with no
# duplicated bullets. Regression for the double-append bug merged_sections
# fixes (the 4.0.4 cut promoted two '### Performance' blocks with the
# performance fragments double-counted across both).
tmp5="$(mktemp -d)"; tmpdirs+=("$tmp5")
mkdir -p "$tmp5/tools" "$tmp5/changelog.d"
cp "$TOOLS_DIR/changelog-promote.sh" "$tmp5/tools/"
cat >"$tmp5/CHANGELOG.md" <<'EOF'
# Changelog

## [Unreleased]

### Performance

- perf block one (#2)

### Added

- an added entry (#1)

### Performance

- perf block two (#3)

# [0.0.1](https://github.com/wheels-dev/wheels/releases/tag/v0.0.1) => 2020-01-01

### Fixed

- baseline (#0)
EOF
printf -- '- perf from fragment (#4)\n' >"$tmp5/changelog.d/speed.performance.md"
( cd "$tmp5" && bash tools/changelog-promote.sh 2.0.0 2026-02-02 ) >/dev/null 2>"$tmp5/err"
# Isolate the promoted [2.0.0] section (up to the next version heading).
sec="$(awk '/^# \[2\.0\.0\]/{f=1;next} f && /^#{1,2} \[[0-9]/{exit} f' "$tmp5/CHANGELOG.md")"
nperf="$(printf '%s\n' "$sec" | grep -cE '^### Performance$')"
if [ "$nperf" -eq 1 ]; then
  ok "consolidation: two [Unreleased] '### Performance' blocks collapse to one heading"
else
  bad "consolidation: expected 1 '### Performance' heading, found $nperf"
fi
dupes=0
for b in 'perf block one (#2)' 'perf block two (#3)' 'perf from fragment (#4)' 'an added entry (#1)'; do
  c="$(printf '%s\n' "$sec" | grep -Fc "$b")"
  [ "$c" -eq 1 ] || { dupes=1; bad "consolidation: '$b' appears $c times in the section (expected exactly 1)"; }
done
[ "$dupes" -eq 0 ] && ok "consolidation: existing + fragment bullets each appear exactly once (no double-count)"
if printf '%s\n' "$sec" | awk '/^### Added$/{a=NR} /^### Performance$/{p=NR} END{exit !(a && p && a < p)}'; then
  ok "consolidation: canonical order (Added before Performance)"
else
  bad "consolidation: sections not in canonical order (Added must precede Performance)"
fi

exit $fail
