#!/usr/bin/env python3
"""
Static validation for the WinGet manifest drafts. Catches schema-level
mistakes (missing required fields, identifier/version mismatches across the
3-file triplet) without needing the Windows `winget validate` tool.

The official validator is Windows-only; this is the macOS/linux fallback.
Run before pushing changes to the manifest content.

Checks:
- Each version dir contains exactly the 3 files: <Id>.yaml, <Id>.locale.en-US.yaml, <Id>.installer.yaml
- PackageIdentifier in all three files matches the package directory name (e.g. Wheels.Wheels)
- PackageVersion matches the parent dir name
- DefaultLocale (in top manifest) matches the locale file's PackageLocale
- Installer URLs use https
- License is in SPDX form
- Placeholder hashes are flagged (loud — these are submit-blockers)
"""

from __future__ import annotations

import sys
from pathlib import Path

HERE = Path(__file__).parent
ERRORS: list[str] = []
WARNINGS: list[str] = []


def fail(msg: str) -> None:
    ERRORS.append(msg)
    print(f"FAIL: {msg}")


def warn(msg: str) -> None:
    WARNINGS.append(msg)
    print(f"WARN: {msg}")


def info(msg: str) -> None:
    print(f"ok:   {msg}")


def parse_yaml_lite(path: Path) -> dict[str, str]:
    """Tiny YAML reader — only handles top-level `key: value` pairs.

    WinGet manifests have some nested structure (Installers, Documentations)
    but for validation we only need the top-level scalars. PyYAML isn't in
    the default Python install, so we stay dependency-free.
    """
    out: dict[str, str] = {}
    for line in path.read_text().splitlines():
        # Skip comments + empty lines + nested entries
        if not line or line.startswith("#") or line.startswith(" ") or line.startswith("-"):
            continue
        if ":" not in line:
            continue
        key, _, val = line.partition(":")
        out[key.strip()] = val.strip()
    return out


def validate_package(pkg_dir: Path, expected_id: str) -> None:
    """Validate all version dirs under a package dir."""
    for version_dir in sorted(p for p in pkg_dir.iterdir() if p.is_dir()):
        validate_version(version_dir, expected_id)


def validate_version(version_dir: Path, expected_id: str) -> None:
    version = version_dir.name
    info(f"validating {expected_id} {version}")

    top = version_dir / f"{expected_id}.yaml"
    locale = version_dir / f"{expected_id}.locale.en-US.yaml"
    installer = version_dir / f"{expected_id}.installer.yaml"

    for f in (top, locale, installer):
        if not f.exists():
            fail(f"{version_dir}: missing {f.name}")
            return

    top_m = parse_yaml_lite(top)
    locale_m = parse_yaml_lite(locale)
    installer_m = parse_yaml_lite(installer)

    # Identifier consistency
    for name, m in (("top", top_m), ("locale", locale_m), ("installer", installer_m)):
        if m.get("PackageIdentifier") != expected_id:
            fail(f"{version_dir}: {name} PackageIdentifier '{m.get('PackageIdentifier')}' != expected '{expected_id}'")

    # Version consistency
    for name, m in (("top", top_m), ("locale", locale_m), ("installer", installer_m)):
        if m.get("PackageVersion") != version:
            fail(f"{version_dir}: {name} PackageVersion '{m.get('PackageVersion')}' != dir '{version}'")

    # Manifest type tags
    if top_m.get("ManifestType") != "version":
        fail(f"{top}: ManifestType must be 'version'")
    if locale_m.get("ManifestType") != "defaultLocale":
        fail(f"{locale}: ManifestType must be 'defaultLocale'")
    if installer_m.get("ManifestType") != "installer":
        fail(f"{installer}: ManifestType must be 'installer'")

    # Locale match
    if top_m.get("DefaultLocale") != locale_m.get("PackageLocale"):
        fail(f"{version_dir}: top DefaultLocale '{top_m.get('DefaultLocale')}' != locale PackageLocale '{locale_m.get('PackageLocale')}'")

    # License is SPDX
    license = locale_m.get("License", "")
    if license and license not in {"Apache-2.0", "MIT", "BSD-3-Clause", "GPL-2.0", "GPL-3.0", "LGPL-2.1", "LGPL-3.0", "MPL-2.0", "ISC"}:
        warn(f"{locale}: License '{license}' is not a common SPDX ID — double-check before submitting")

    # Installer URL must be https
    # (parse_yaml_lite skips list entries so we have to grep raw text for InstallerUrl/Sha256)
    installer_text = installer.read_text()
    for line in installer_text.splitlines():
        s = line.strip()
        if s.startswith("InstallerUrl:"):
            url = s.split(":", 1)[1].strip().split("#")[0].strip()
            if not url.startswith("https://"):
                fail(f"{installer}: InstallerUrl must use https: {url}")
            if "PLACEHOLDER" in line:
                warn(f"{installer}: InstallerUrl is a PLACEHOLDER (real artifact does not yet exist)")
        if s.startswith("InstallerSha256:"):
            h = s.split(":", 1)[1].strip().split("#")[0].strip()
            if h == "0" * 64:
                warn(f"{installer}: InstallerSha256 is a zero-placeholder — must be filled before submitting")
            elif len(h) != 64:
                fail(f"{installer}: InstallerSha256 must be 64 hex chars, got {len(h)}")


def main() -> int:
    print("Validating WinGet manifest drafts in", HERE)
    print()

    pkgs = [
        (HERE / "Wheels.Wheels", "Wheels.Wheels"),
        (HERE / "Wheels.WheelsBE", "Wheels.WheelsBE"),
    ]
    for pkg_dir, expected_id in pkgs:
        if not pkg_dir.exists():
            warn(f"{pkg_dir.name} does not exist — skipping")
            continue
        validate_package(pkg_dir, expected_id)

    print()
    print(f"Warnings: {len(WARNINGS)}, Errors: {len(ERRORS)}")
    if ERRORS:
        return 1
    if WARNINGS:
        print("(warnings are expected pre-build; errors are real schema problems)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
