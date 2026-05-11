#!/usr/bin/env python3
"""
Build wheels-be.json and wheels.json Scoop manifests.

The CMD wrapper has so many escape characters (CMD's `^`, JSON's `\`, PowerShell's
single-quote escaping) that hand-editing is error-prone. This generator emits
both manifests from a single source of truth.

Output is the sibling wheels.json and wheels-be.json files. Run after bumping
any pinned version constant (LuCLI, sqlite-jdbc, snapshot pin) - the diff
should be small and focused.

Usage:
    python3 build-manifests.py            # rewrite both manifests in place
    python3 build-manifests.py --check    # exit non-zero if regen would change files (CI)
"""

import json
import sys
from pathlib import Path

HERE = Path(__file__).parent
OUT = HERE

# Pinned hashes computed against actual published artifacts.
# These two are stable forever (Maven Central immutable + tagged LuCLI release).
LUCLI_VERSION = "0.3.7"
LUCLI_SHA512 = "75c948319b333d2e9d653d4986e766463f3f29062f62c364ccde2288e5f295bf65a857d54eda2e888cd5a80c2bd9fb727e016f4fca05fc42e56ee219225dd71b"

SQLITE_JDBC_VERSION = "3.49.1.0"
SQLITE_JDBC_SHA512 = "90b3f6aed150f611fcb9454dfda5fbb9d7faad369937fa8718ac8813c45eb6f0430e6014b7b4c94b4b63e404ade68e83126571f94216de7bf6d2947f1c642803"

# Verified current snapshot — autoupdate will rewrite these on each new snapshot tag
SNAPSHOT_VERSION = "4.0.0-snapshot.1789"
SNAPSHOT_MODULE_SHA512 = "73b37b01a82ef5abe36c4f02f1aa8870531ac2d6a867ff6482895b6d01dacb068a07af19ec51434ca2caf0b1f8de1437ed5919183f6f0077ef3cd5da7e074be9"
SNAPSHOT_CORE_SHA512 = "fa492a87fdf5ba4153ce24aa216fdda442c2bc39ed256a3348029cfeb74950e7bf8fbc533d7497869287bb9f843c191a9e3cf8703aa4a2fb50bde0db771141b7"

# Stable not yet published — fill at GA cut. Use the placeholder so manifest is valid.
STABLE_VERSION_PLACEHOLDER = "4.0.0"
STABLE_HASH_PLACEHOLDER = "0" * 128  # 128 zeros = sha512 placeholder


def cmd_wrapper(channel: str) -> list[str]:
    """The wheels.cmd wrapper. Lines are written verbatim into the .cmd file.

    Mirrors the brew wrapper:
    - intercepts --version / -v / --help / -h before LuCLI sees them
    - self-heals sqlite-jdbc into LuCLI's express/<lucee>/lib/ext on every run
    - sets LUCLI_HOME and execs lucli-0.3.7.bat
    """
    # ASCII art banner — `^` escapes CMD's pipe character
    banner = [
        r" __        ___               _ ",
        r" \ \      / / ^|__   ___  ___^| ^|___",
        r"  \ \ /\ / /^| '_ \ / _ \/ _ \ / __^|",
        r"   \ V  V / ^| ^| ^| ^|  __/  __/ \__ \ ",
        r"    \_/\_/  ^|_^| ^|_^|\___\___^|_^|___/",
    ]
    return [
        "@echo off",
        "setlocal enabledelayedexpansion",
        r'set "LUCLI_HOME=%USERPROFILE%\.wheels"',
        r'set "MOD_VER_SRC=%~dp0share\module\.module-version"',
        r'set "MOD_VER_DST=%LUCLI_HOME%\modules\wheels\.module-version"',
        f'set "SQLITE_SRC=%~dp0sqlite-jdbc-{SQLITE_JDBC_VERSION}.jar"',
        "",
        'if "%~1"=="--version" goto :show_version',
        'if "%~1"=="-v" goto :show_version',
        'if "%~1"=="--help" goto :show_help',
        'if "%~1"=="-h" goto :show_help',
        "",
        ":: First-time module sync -- copies module + framework into ~/.wheels if missing or version-mismatched.",
        ':: Mirrors the brew wrapper\'s SRC->DST sync; needed because `wheels new` etc. mutate ~/.wheels but',
        ":: scoop's install dir must stay pristine for `scoop uninstall` to work cleanly.",
        r'set "WHEELS_MOD_DST=%LUCLI_HOME%\modules\wheels"',
        r'set "WHEELS_FRAMEWORK_DST=%WHEELS_MOD_DST%\vendor\wheels"',
        r'set "WHEELS_MOD_SRC=%~dp0share\module"',
        r'set "WHEELS_FRAMEWORK_SRC=%~dp0share\framework\wheels"',
        'set "src_ver="',
        'set "dst_ver="',
        'if exist "%MOD_VER_SRC%" for /f "usebackq delims=" %%V in ("%MOD_VER_SRC%") do set "src_ver=%%V"',
        'if exist "%MOD_VER_DST%" for /f "usebackq delims=" %%V in ("%MOD_VER_DST%") do set "dst_ver=%%V"',
        'if not "!src_ver!"=="!dst_ver!" (',
        '  if exist "%WHEELS_MOD_DST%" rmdir /S /Q "%WHEELS_MOD_DST%" >nul 2>&1',
        '  mkdir "%WHEELS_FRAMEWORK_DST%" >nul 2>&1',
        '  xcopy /E /I /Y /Q "%WHEELS_MOD_SRC%" "%WHEELS_MOD_DST%" >nul 2>&1',
        '  xcopy /E /I /Y /Q "%WHEELS_FRAMEWORK_SRC%" "%WHEELS_FRAMEWORK_DST%" >nul 2>&1',
        ")",
        "",
        ":: Drop sqlite-jdbc into LuCLI's extracted express lib/ext on every run (self-heal).",
        ':: The express dir only exists after the first LuCLI run, so this is a no-op on the very',
        ":: first invocation and self-heals on every run after.",
        'if exist "%SQLITE_SRC%" (',
        r'  for /d %%D in ("%LUCLI_HOME%\express\*") do (',
        r'    if exist "%%D\lib\ext" if not exist "%%D\lib\ext\sqlite-jdbc-' + SQLITE_JDBC_VERSION + '.jar" copy /Y "%SQLITE_SRC%" "%%D\\lib\\ext\\" >nul 2>&1',
        "  )",
        ")",
        "",
        f'call "%~dp0lucli-{LUCLI_VERSION}.bat" %*',
        "exit /b %ERRORLEVEL%",
        "",
        ":show_version",
        'set "ver=unknown"',
        'if exist "%MOD_VER_DST%" for /f "usebackq delims=" %%V in ("%MOD_VER_DST%") do set "ver=%%V"',
        'if "!ver!"=="unknown" if exist "%MOD_VER_SRC%" for /f "usebackq delims=" %%V in ("%MOD_VER_SRC%") do set "ver=%%V"',
        f"echo Wheels Version: !ver! ({channel})",
        "echo.",
        *(f"echo {line}" for line in banner),
        "echo.",
        "echo https://wheels.dev",
        "exit /b 0",
        "",
        ":show_help",
        'set "ver=unknown"',
        'if exist "%MOD_VER_DST%" for /f "usebackq delims=" %%V in ("%MOD_VER_DST%") do set "ver=%%V"',
        'if "!ver!"=="unknown" if exist "%MOD_VER_SRC%" for /f "usebackq delims=" %%V in ("%MOD_VER_SRC%") do set "ver=%%V"',
        f"echo Wheels CLI !ver! ({channel})",
        "echo   CFML MVC framework - code generation, migrations, testing, server management",
        "echo.",
        "echo Usage:",
        "echo   wheels ^<command^> [options]",
        "echo.",
        "echo For full command reference: wheels ^<command^> --help",
        "echo More info: https://guides.wheels.dev",
        "exit /b 0",
    ]


def ps_quote_for_addcontent(line: str) -> str:
    """Convert a literal CMD line into a PowerShell statement that appends it to wheels.cmd.

    Wraps the line in PowerShell single-quotes (doubling any embedded `'`).
    """
    return "$lines.Add('" + line.replace("'", "''") + "')"


def build_post_install(channel: str) -> list[str]:
    """Generate the post_install PowerShell array for the given channel."""
    lines = cmd_wrapper(channel)
    return [
        # Use the .NET List to avoid PowerShell's slow array-realloc pattern
        "$lines = New-Object System.Collections.Generic.List[string]",
        *[ps_quote_for_addcontent(l) for l in lines],
        # ASCII encoding to keep CMD happy on non-UTF8 codepages
        'Set-Content -Path "$dir\\wheels.cmd" -Value $lines -Encoding ASCII',
    ]


def manifest_be() -> dict:
    """Bleeding-edge channel — tracks wheels-dev/wheels-snapshots."""
    base_release = f"https://github.com/wheels-dev/wheels-snapshots/releases/download/v{SNAPSHOT_VERSION}"
    lucli_url = f"https://github.com/cybersonic/LuCLI/releases/download/v{LUCLI_VERSION}/lucli-{LUCLI_VERSION}.bat"
    sqlite_url = f"https://repo1.maven.org/maven2/org/xerial/sqlite-jdbc/{SQLITE_JDBC_VERSION}/sqlite-jdbc-{SQLITE_JDBC_VERSION}.jar"

    return {
        "version": SNAPSHOT_VERSION,
        "description": "Wheels CFML MVC framework - bleeding-edge channel (develop snapshots).",
        "homepage": "https://wheels.dev",
        "license": "Apache-2.0",
        "depends": "java/openjdk21",
        "notes": [
            "Bleeding-edge channel: tracks every merge to develop on wheels-dev/wheels.",
            "Conflicts with the stable 'wheels' package - install only one channel at a time.",
            "Switch channels with: scoop uninstall wheels-be ; scoop install wheels",
            "First run will sync the module and framework into ~/.wheels."
        ],
        "architecture": {
            "64bit": {
                "url": [
                    f"{base_release}/wheels-module-{SNAPSHOT_VERSION}.zip",
                    f"{base_release}/wheels-core-{SNAPSHOT_VERSION}.zip",
                    lucli_url,
                    sqlite_url,
                ],
                "hash": [
                    f"sha512:{SNAPSHOT_MODULE_SHA512}",
                    f"sha512:{SNAPSHOT_CORE_SHA512}",
                    f"sha512:{LUCLI_SHA512}",
                    f"sha512:{SQLITE_JDBC_SHA512}",
                ],
                "extract_dir": ["", "wheels", "", ""],
                "extract_to": ["share/module", "share/framework/wheels", "", ""],
            }
        },
        "bin": [["wheels.cmd", "wheels"]],
        "post_install": build_post_install("bleeding-edge"),
        "checkver": {
            "url": "https://api.github.com/repos/wheels-dev/wheels-snapshots/releases?per_page=1",
            "jsonpath": "$[0].tag_name",
            "regex": "v([\\d.]+-snapshot\\.\\d+)",
        },
        "autoupdate": {
            "architecture": {
                "64bit": {
                    "url": [
                        "https://github.com/wheels-dev/wheels-snapshots/releases/download/v$version/wheels-module-$version.zip",
                        "https://github.com/wheels-dev/wheels-snapshots/releases/download/v$version/wheels-core-$version.zip",
                        lucli_url,
                        sqlite_url,
                    ],
                    "hash": [
                        {"url": "$url.sha512"},
                        {"url": "$url.sha512"},
                        f"sha512:{LUCLI_SHA512}",
                        f"sha512:{SQLITE_JDBC_SHA512}",
                    ],
                }
            }
        },
    }


def manifest_stable() -> dict:
    """Stable channel - tracks wheels-dev/wheels GA tags."""
    base_release = f"https://github.com/wheels-dev/wheels/releases/download/v{STABLE_VERSION_PLACEHOLDER}"
    lucli_url = f"https://github.com/cybersonic/LuCLI/releases/download/v{LUCLI_VERSION}/lucli-{LUCLI_VERSION}.bat"
    sqlite_url = f"https://repo1.maven.org/maven2/org/xerial/sqlite-jdbc/{SQLITE_JDBC_VERSION}/sqlite-jdbc-{SQLITE_JDBC_VERSION}.jar"

    return {
        "##": "Stable channel - tracks wheels-dev/wheels GA tags. The two zero-filled hashes",
        "##2": "below will be populated by Scoop's autoupdate after the first GA tag is",
        "##3": "published. Pre-GA, the manifest is install-blocked by hash mismatch by design.",
        "version": STABLE_VERSION_PLACEHOLDER,
        "description": "Wheels CFML MVC framework - stable channel.",
        "homepage": "https://wheels.dev",
        "license": "Apache-2.0",
        "depends": "java/openjdk21",
        "notes": [
            "Stable channel: tracks GA releases of Wheels.",
            "Conflicts with 'wheels-be' (bleeding-edge) - install only one channel at a time.",
            "Switch channels with: scoop uninstall wheels ; scoop install wheels-be",
            "First run will sync the module and framework into ~/.wheels."
        ],
        "architecture": {
            "64bit": {
                "url": [
                    f"{base_release}/wheels-module-{STABLE_VERSION_PLACEHOLDER}.zip",
                    f"{base_release}/wheels-core-{STABLE_VERSION_PLACEHOLDER}.zip",
                    lucli_url,
                    sqlite_url,
                ],
                "hash": [
                    f"sha512:{STABLE_HASH_PLACEHOLDER}",
                    f"sha512:{STABLE_HASH_PLACEHOLDER}",
                    f"sha512:{LUCLI_SHA512}",
                    f"sha512:{SQLITE_JDBC_SHA512}",
                ],
                "extract_dir": ["", "wheels", "", ""],
                "extract_to": ["share/module", "share/framework/wheels", "", ""],
            }
        },
        "bin": [["wheels.cmd", "wheels"]],
        "post_install": build_post_install("stable"),
        "checkver": {"github": "https://github.com/wheels-dev/wheels"},
        "autoupdate": {
            "architecture": {
                "64bit": {
                    "url": [
                        "https://github.com/wheels-dev/wheels/releases/download/v$version/wheels-module-$version.zip",
                        "https://github.com/wheels-dev/wheels/releases/download/v$version/wheels-core-$version.zip",
                        lucli_url,
                        sqlite_url,
                    ],
                    "hash": [
                        {"url": "$url.sha512"},
                        {"url": "$url.sha512"},
                        f"sha512:{LUCLI_SHA512}",
                        f"sha512:{SQLITE_JDBC_SHA512}",
                    ],
                }
            }
        },
    }


def serialize(data: dict) -> str:
    return json.dumps(data, indent=4) + "\n"


def write_manifest(name: str, data: dict) -> bool:
    """Write manifest to disk. Returns True if file changed."""
    out = OUT / name
    new = serialize(data)
    old = out.read_text() if out.exists() else ""
    if old == new:
        print(f"unchanged: {out.name}")
        return False
    out.write_text(new)
    print(f"wrote: {out.name} ({out.stat().st_size} bytes)")
    return True


def check_manifest(name: str, data: dict) -> bool:
    """Return True if regen would change the file."""
    out = OUT / name
    new = serialize(data)
    old = out.read_text() if out.exists() else ""
    if old == new:
        return False
    print(f"DRIFT: {out.name} would change. Run build-manifests.py without --check.")
    return True


def main() -> None:
    check_mode = "--check" in sys.argv
    manifests = [
        ("wheels-be.json", manifest_be()),
        ("wheels.json", manifest_stable()),
    ]
    if check_mode:
        # Materialize the list before any() so every check_manifest() runs and emits
        # its DRIFT log line. any() short-circuits on generators, which would skip
        # the second manifest whenever the first one drifts. CI needs to see *all*
        # drifting manifests in one run. The named binding also sidesteps ruff
        # `any(comprehension)` warnings without obscuring intent.
        results = [check_manifest(n, d) for n, d in manifests]
        drift = any(results)
        sys.exit(1 if drift else 0)
    for n, d in manifests:
        write_manifest(n, d)


if __name__ == "__main__":
    main()
