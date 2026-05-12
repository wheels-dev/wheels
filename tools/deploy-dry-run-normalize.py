#!/usr/bin/env python3
"""
Normalize Kamal-style dry-run command output for semantic diffing.

Reads command-plan text on stdin, writes a normalized, sorted stream on stdout
so that two dry-runs whose only differences are cosmetic (flag order,
ANSI color, host prefixes, blank lines) collapse to byte-identical output.

Normalization pipeline (per line):
  1. Strip ANSI CSI escapes.
  2. Strip leading "[host]" host prefix if present (Kamal + our Output sink).
  3. Drop blank lines and comment-only lines (starting with '#').
  4. Tokenize on whitespace; keep positional tokens in their original order,
     sort *flag* tokens (anything starting with '-') alphabetically; rejoin.
  5. After all lines are processed, sort the final line list alphabetically
     for stable set-style diffing.

This is deliberately lossy — it's a *semantic* diff, not a fidelity tool.
Anything order-sensitive (e.g. pipeline chains "a | b") inside a single
line is preserved within the line; only *top-level* command ordering is
normalized away. That matches the Phase 1 exit-gate intent: "do the two
tools plan the same set of commands?" not "in the same order?".

Usage:
    cat dryrun.txt | tools/deploy-dry-run-normalize.py > dryrun.norm
    diff <(... kamal ... | normalize) <(... wheels ... | normalize)
"""
from __future__ import annotations

import re
import sys

ANSI_RE = re.compile(r"\x1b\[[0-9;]*[A-Za-z]")
HOST_PREFIX_RE = re.compile(r"^\s*\[[^\]]+\]\s*")


def normalize_line(raw: str) -> str | None:
    line = ANSI_RE.sub("", raw).rstrip("\r\n")
    line = HOST_PREFIX_RE.sub("", line)
    stripped = line.strip()
    if not stripped:
        return None
    if stripped.startswith("#"):
        return None
    tokens = stripped.split()
    positional: list[str] = []
    flags: list[str] = []
    for tok in tokens:
        if tok.startswith("-"):
            flags.append(tok)
        else:
            positional.append(tok)
    flags.sort()
    return " ".join(positional + flags)


def main() -> int:
    out: list[str] = []
    for raw in sys.stdin:
        norm = normalize_line(raw)
        if norm is not None:
            out.append(norm)
    out.sort()
    sys.stdout.write("\n".join(out))
    if out:
        sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
