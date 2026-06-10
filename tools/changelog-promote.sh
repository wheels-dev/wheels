#!/usr/bin/env bash
# Assemble changelog.d/ fragments into CHANGELOG.md (see changelog.d/README.md).
#
# Usage:
#   tools/changelog-promote.sh --preview            # print assembled sections, change nothing
#   tools/changelog-promote.sh <version> [date]     # promote: merge fragments + current
#                                                   # [Unreleased] body into a new
#                                                   # "## [<version>] - <date>" section,
#                                                   # reset [Unreleased], delete fragments
#
# Promotion only edits files — review the diff and commit yourself. The
# script refuses to promote when there is nothing to promote, and fails
# loudly on malformed fragment names/content so a bad file can't silently
# vanish from the release notes.
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"

python3 - "$@" <<'PYEOF'
import datetime
import pathlib
import re
import sys

FRAG_DIR = pathlib.Path("changelog.d")
CHANGELOG = pathlib.Path("CHANGELOG.md")
# Section order for newly-created headings. Existing headings under
# [Unreleased] keep their file order; missing ones are appended in this order.
CANONICAL = ["Added", "Changed", "Deprecated", "Removed", "Performance", "Fixed", "Security"]
TYPES = {t.lower(): t for t in CANONICAL}
# Marker comment kept at the top of the empty [Unreleased] section.
MARKER = (
    "<!-- Do not add entries here. Write a fragment file under changelog.d/\n"
    "     (see changelog.d/README.md); fragments are assembled into this file\n"
    "     at release promotion via tools/changelog-promote.sh. -->"
)


def fail(msg):
    print(f"changelog-promote: {msg}", file=sys.stderr)
    sys.exit(1)


def read_fragments():
    """Returns {SectionName: [bullet lines]} preserving per-section filename order."""
    sections = {}
    if not FRAG_DIR.is_dir():
        return sections
    for path in sorted(FRAG_DIR.glob("*.md")):
        if path.name == "README.md":
            continue
        parts = path.name.rsplit(".", 2)
        if len(parts) != 3 or parts[1].lower() not in TYPES:
            fail(
                f"{path}: fragment files must be named <slug>.<type>.md with type one of "
                f"{', '.join(sorted(TYPES))}"
            )
        section = TYPES[parts[1].lower()]
        body = path.read_text(encoding="utf-8").strip()
        if not body:
            fail(f"{path}: fragment is empty")
        lines = body.splitlines()
        if not lines[0].startswith("- "):
            fail(f"{path}: fragment content must start with a markdown bullet ('- ')")
        for line in lines:
            if line.startswith("#"):
                fail(f"{path}: fragments may not contain headings")
        sections.setdefault(section, []).extend(lines)
    return sections


def parse_unreleased(text):
    """Returns (head, body_sections, tail, had_unreleased).

    head  = everything through the '## [Unreleased]' line
    body_sections = ordered list of (heading-or-None, [lines]) inside Unreleased
    tail  = everything from the next '## ' heading onward
    """
    match = re.search(r"(?m)^## \[Unreleased\][^\n]*\n", text)
    if not match:
        fail("CHANGELOG.md has no '## [Unreleased]' section")
    head = text[: match.end()]
    rest = text[match.end():]
    next_heading = re.search(r"(?m)^## ", rest)
    body = rest[: next_heading.start()] if next_heading else rest
    tail = rest[next_heading.start():] if next_heading else ""

    # Strip the do-not-edit marker from the body so it never gets promoted.
    body = body.replace(MARKER, "")

    sections = []
    current = (None, [])
    for line in body.splitlines():
        if line.startswith("### "):
            if current[0] is not None or any(l.strip() for l in current[1]):
                sections.append(current)
            current = (line[4:].strip(), [])
        else:
            current[1].append(line)
    if current[0] is not None or any(l.strip() for l in current[1]):
        sections.append(current)
    return head, sections, tail


def merged_sections(existing, fragments):
    """Merge fragment bullets into the existing Unreleased sections."""
    out = []
    seen = set()
    for heading, lines in existing:
        if heading is None:
            # Prose before the first ### heading (rare) — keep as-is.
            out.append((heading, [l for l in lines if l.strip()]))
            continue
        bullets = [l for l in lines if l.strip()]
        if heading in fragments:
            bullets.extend(fragments[heading])
        out.append((heading, bullets))
        seen.add(heading)
    for heading in CANONICAL:
        if heading in fragments and heading not in seen:
            out.append((heading, list(fragments[heading])))
    # Drop empty sections.
    return [(h, b) for h, b in out if b]


def render(sections):
    chunks = []
    for heading, bullets in sections:
        if heading is not None:
            chunks.append(f"### {heading}\n")
        chunks.append("\n".join(bullets) + "\n")
    return "\n".join(chunks)


args = sys.argv[1:]
if not args:
    fail("usage: tools/changelog-promote.sh --preview | <version> [date]")

fragments = read_fragments()

if args[0] == "--preview":
    if CHANGELOG.exists():
        text = CHANGELOG.read_text(encoding="utf-8")
        _, existing, _ = parse_unreleased(text)
    else:
        existing = []
    merged = merged_sections(existing, fragments)
    if not merged:
        print("Nothing to promote: no fragments and [Unreleased] is empty.")
        sys.exit(0)
    for heading, bullets in merged:
        if heading is not None:
            print(f"### {heading}\n")
        print("\n".join(bullets))
        print()
    sys.exit(0)

version = args[0]
if not re.fullmatch(r"\d+\.\d+\.\d+(-[A-Za-z0-9.]+)?", version):
    fail(f"'{version}' does not look like a semver version")
date = args[1] if len(args) > 1 else datetime.date.today().isoformat()
if not re.fullmatch(r"\d{4}-\d{2}-\d{2}", date):
    fail(f"'{date}' is not a YYYY-MM-DD date")

text = CHANGELOG.read_text(encoding="utf-8")
head, existing, tail = parse_unreleased(text)
merged = merged_sections(existing, fragments)
if not merged:
    fail("nothing to promote: no fragments and [Unreleased] is empty")

new_unreleased = f"\n{MARKER}\n\n"
version_section = f"## [{version}] - {date}\n\n{render(merged)}\n"
CHANGELOG.write_text(head + new_unreleased + version_section + tail, encoding="utf-8")

removed = []
for path in sorted(FRAG_DIR.glob("*.md")):
    if path.name != "README.md":
        path.unlink()
        removed.append(path.name)

print(f"[{version}] - {date} now carries {sum(len(b) for _, b in merged)} entries (fragments + prior [Unreleased] content).")
print(f"Removed {len(removed)} fragment(s): {', '.join(removed) if removed else '(none)'}")
print("Review the CHANGELOG.md diff, then commit.")
PYEOF
