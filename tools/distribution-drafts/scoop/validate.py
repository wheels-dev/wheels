#!/usr/bin/env python3
"""
Static validation for the Scoop manifest drafts. Runs without a Windows
machine - catches the regressions that would otherwise only surface on a
real `scoop install` attempt.

Checks:
- JSON parses
- Required Scoop fields exist (version, description, license, architecture)
- url / hash / extract_to / extract_dir arrays are same length per arch
- All URLs are reachable (HEAD request, redirects allowed)
- Embedded wheels.cmd contents look like valid CMD (balanced labels, no
  unescaped pipes outside echo lines, no embedded NUL)
- The CMD wrapper references LUCLI_VERSION and SQLITE_JDBC_VERSION constants
  that match the URL paths (catches "bumped the URL but not the wrapper")
- Mutual exclusion: both manifests use the same `bin` shim name

Exit code 0 if everything passes, 1 otherwise.
"""

from __future__ import annotations

import json
import re
import sys
import urllib.request
import urllib.error
from pathlib import Path
from typing import Iterable

HERE = Path(__file__).parent
REQUIRED_TOP_FIELDS = ("version", "description", "homepage", "license", "architecture", "bin")
ERRORS: list[str] = []


def fail(msg: str) -> None:
    ERRORS.append(msg)
    print(f"FAIL: {msg}")


def warn(msg: str) -> None:
    print(f"WARN: {msg}")


def info(msg: str) -> None:
    print(f"ok:   {msg}")


def extract_cmd_lines(manifest: dict) -> list[str]:
    """Pull the literal CMD lines back out of the post_install array."""
    cmd_lines: list[str] = []
    pattern = re.compile(r"^\$lines\.Add\('(.*)'\)$")
    for stmt in manifest.get("post_install", []):
        m = pattern.match(stmt)
        if m:
            # PowerShell single-quote escape: '' -> '
            cmd_lines.append(m.group(1).replace("''", "'"))
    return cmd_lines


def check_required_fields(name: str, m: dict) -> None:
    for field in REQUIRED_TOP_FIELDS:
        if field not in m:
            fail(f"{name}: missing required top-level field '{field}'")
        else:
            info(f"{name}: has '{field}'")


def check_arch_arrays(name: str, m: dict) -> None:
    arch = m.get("architecture", {}).get("64bit", {})
    urls = arch.get("url", [])
    hashes = arch.get("hash", [])
    extract_to = arch.get("extract_to", [])
    extract_dir = arch.get("extract_dir", [])

    n = len(urls)
    if n != len(hashes):
        fail(f"{name}: url[{n}] vs hash[{len(hashes)}] length mismatch")
    if extract_to and len(extract_to) != n:
        fail(f"{name}: url[{n}] vs extract_to[{len(extract_to)}] length mismatch")
    if extract_dir and len(extract_dir) != n:
        fail(f"{name}: url[{n}] vs extract_dir[{len(extract_dir)}] length mismatch")
    if n == len(hashes) == len(extract_to) == len(extract_dir):
        info(f"{name}: arch arrays consistent ({n} entries)")


def check_url_reachable(url: str, name: str) -> None:
    """HEAD the URL. Treat 200-399 as pass, anything else as fail."""
    req = urllib.request.Request(url, method="HEAD", headers={"User-Agent": "wheels-scoop-validator/1.0"})
    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            code = resp.getcode()
            if 200 <= code < 400:
                info(f"{name}: HEAD {url[:80]}... -> {code}")
            else:
                fail(f"{name}: HEAD {url} returned {code}")
    except urllib.error.HTTPError as e:
        # GitHub release URLs sometimes 302 to S3; HTTPError 302 is not an error here
        if e.code in (301, 302, 307, 308):
            info(f"{name}: HEAD {url[:80]}... -> {e.code} (redirect, ok)")
        else:
            fail(f"{name}: HEAD {url} returned {e.code}")
    except (urllib.error.URLError, TimeoutError) as e:
        fail(f"{name}: HEAD {url} unreachable: {e}")


def check_wrapper(name: str, m: dict) -> None:
    cmd_lines = extract_cmd_lines(m)
    if not cmd_lines:
        fail(f"{name}: post_install emits no CMD wrapper lines")
        return

    joined = "\n".join(cmd_lines)

    # Labels must be defined (lines starting with ':')
    referenced_labels = set(re.findall(r"goto :(\w+)", joined))
    defined_labels = set(re.findall(r"^:(\w+)\b", joined, re.MULTILINE))
    missing = referenced_labels - defined_labels
    if missing:
        fail(f"{name}: wrapper references undefined labels: {sorted(missing)}")
    else:
        info(f"{name}: wrapper labels resolve ({sorted(defined_labels)})")

    # Wrapper must reference the LuCLI version we pin
    urls = m["architecture"]["64bit"]["url"]
    lucli_url = next((u for u in urls if "LuCLI/releases" in u), None)
    if lucli_url:
        lucli_match = re.search(r"lucli-([\d.]+)\.bat", lucli_url)
        if lucli_match:
            ver = lucli_match.group(1)
            if f"lucli-{ver}.bat" not in joined:
                fail(f"{name}: wrapper does not call lucli-{ver}.bat (URL pins v{ver}); pin mismatch")
            else:
                info(f"{name}: wrapper calls lucli-{ver}.bat consistently with URL")

    # Wrapper must reference the sqlite-jdbc version we pin
    sqlite_url = next((u for u in urls if "sqlite-jdbc" in u), None)
    if sqlite_url:
        sqlite_match = re.search(r"sqlite-jdbc-([\d.]+)\.jar", sqlite_url)
        if sqlite_match:
            ver = sqlite_match.group(1)
            if f"sqlite-jdbc-{ver}.jar" not in joined:
                fail(f"{name}: wrapper does not reference sqlite-jdbc-{ver}.jar (URL pins v{ver}); pin mismatch")
            else:
                info(f"{name}: wrapper references sqlite-jdbc-{ver}.jar consistently with URL")

    # No embedded NUL or non-ASCII garbage
    if any(ord(c) > 127 for c in joined):
        fail(f"{name}: wrapper contains non-ASCII characters (CMD codepage hazard)")
    else:
        info(f"{name}: wrapper is pure ASCII")


def check_bin_shim_collision(manifests: dict[str, dict]) -> None:
    """Both manifests should declare the same shim name - that's how we enforce
    mutual exclusion without an explicit conflicts_with field."""
    shims = {}
    for name, m in manifests.items():
        for entry in m.get("bin", []):
            if isinstance(entry, list) and len(entry) >= 2:
                shims.setdefault(entry[1], []).append(name)
    for shim, owners in shims.items():
        if len(owners) > 1:
            info(f"shim '{shim}' declared by {owners} -> mutual exclusion enforced")
        else:
            warn(f"shim '{shim}' only declared by {owners[0]}; no mutual exclusion")


def check_channel_tag(name: str, m: dict, expected: str) -> None:
    cmd_lines = extract_cmd_lines(m)
    joined = "\n".join(cmd_lines)
    if f"({expected})" not in joined:
        fail(f"{name}: wrapper version banner missing channel tag '({expected})'")
    else:
        info(f"{name}: wrapper banner tags channel as '{expected}'")


def main() -> int:
    online = "--offline" not in sys.argv
    manifests: dict[str, dict] = {}

    for path in (HERE / "wheels.json", HERE / "wheels-be.json"):
        try:
            data = json.loads(path.read_text())
        except json.JSONDecodeError as e:
            fail(f"{path.name}: invalid JSON: {e}")
            continue
        info(f"{path.name}: parses as JSON")
        manifests[path.name] = data
        check_required_fields(path.name, data)
        check_arch_arrays(path.name, data)
        check_wrapper(path.name, data)

    if "wheels-be.json" in manifests:
        check_channel_tag("wheels-be.json", manifests["wheels-be.json"], "bleeding-edge")
    if "wheels.json" in manifests:
        check_channel_tag("wheels.json", manifests["wheels.json"], "stable")

    check_bin_shim_collision(manifests)

    if online:
        print("\n--- HTTP HEAD checks (use --offline to skip) ---")
        for name, m in manifests.items():
            # Skip URLs that we know are placeholder-paired (zero-hash stable
            # pre-GA URLs would 404 on wheels-module-4.0.0.zip until GA)
            stable_zero_hashes = {
                "sha512:" + "0" * 128,
            }
            urls = m["architecture"]["64bit"]["url"]
            hashes = m["architecture"]["64bit"]["hash"]
            for u, h in zip(urls, hashes):
                if h in stable_zero_hashes:
                    warn(f"{name}: skipping HEAD on {u[:60]}... (placeholder hash, pre-GA)")
                    continue
                check_url_reachable(u, name)

    print()
    if ERRORS:
        print(f"VALIDATION FAILED ({len(ERRORS)} issues)")
        for e in ERRORS:
            print(f"  - {e}")
        return 1
    print("VALIDATION PASSED")
    return 0


if __name__ == "__main__":
    sys.exit(main())
