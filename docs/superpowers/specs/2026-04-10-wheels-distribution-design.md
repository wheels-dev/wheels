# Wheels CLI Distribution via Homebrew and Chocolatey

**Date:** 2026-04-10
**Status:** Approved
**Author:** Peter Amiri + Claude

## Problem

The `wheels` CLI is a LuCLI binary with a Wheels module installed. Today, getting this working requires: installing LuCLI from source, symlinking as `wheels`, manually installing the wheels module, and copying `BaseModule.cfc`. The existing Homebrew/Chocolatey packages (v1.0.6) install a CommandBox wrapper — they need to be rewritten for the LuCLI-based architecture.

## Solution

Rewrite both package formulae to install the stock LuCLI binary (renamed to `wheels`) plus the Wheels module, with an auto-update mechanism that tracks upstream LuCLI releases.

## Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Formula ownership | `wheels-dev/homebrew-wheels` owns the formula | No dependency on Mark's CI pipeline |
| Update mechanism | Scheduled GitHub Action polls for new releases | Self-contained, no cross-repo webhooks needed |
| Module distribution | Release artifact from `wheels-dev/wheels` | Version-pinned, reproducible, independently versioned |
| Module placement | Install to prefix, copy to `~/.wheels/` on first run | Homebrew-idiomatic, no `~` writes during install |
| Auto-update PRs | Auto-merge after CI passes | No manual bottleneck for routine version bumps |
| Upgrade behavior | Re-copy module if prefix version is newer | `brew upgrade wheels` updates both binary and module |

## Architecture

### What `brew install wheels` Does

1. Downloads LuCLI self-executing binary from `cybersonic/LuCLI` releases
2. Downloads `wheels-module.tar.gz` from `wheels-dev/wheels` releases
3. Installs LuCLI binary to `libexec/wheels`
4. Extracts module to `share/wheels/module/`
5. Writes a version marker to `share/wheels/.module-version`
6. Installs a wrapper script to `bin/wheels`
7. Depends on `openjdk@21`

### Wrapper Script (`bin/wheels`)

```bash
#!/bin/bash
BREW_PREFIX="$(brew --prefix)/opt/wheels"
WHEELS_MODULE_SRC="$BREW_PREFIX/share/wheels/module"
WHEELS_MODULE_DST="$HOME/.wheels/modules/wheels"
WHEELS_VERSION_SRC="$BREW_PREFIX/share/wheels/.module-version"
WHEELS_VERSION_DST="$HOME/.wheels/modules/wheels/.module-version"

# Copy module on first run, or re-copy if prefix version is newer
if [ -f "$WHEELS_VERSION_SRC" ]; then
  src_ver=$(cat "$WHEELS_VERSION_SRC")
  dst_ver=""
  [ -f "$WHEELS_VERSION_DST" ] && dst_ver=$(cat "$WHEELS_VERSION_DST")
  if [ "$src_ver" != "$dst_ver" ]; then
    mkdir -p "$WHEELS_MODULE_DST"
    cp -R "$WHEELS_MODULE_SRC/"* "$WHEELS_MODULE_DST/"
    cp "$WHEELS_VERSION_SRC" "$WHEELS_VERSION_DST"
  fi
fi

exec "$BREW_PREFIX/libexec/wheels" "$@"
```

### Formula Skeleton (`Formula/wheels.rb`)

```ruby
class Wheels < Formula
  desc "CLI for the Wheels MVC framework — powered by LuCLI"
  homepage "https://wheels.dev"
  license "Apache-2.0"

  # LuCLI binary
  if OS.mac? && Hardware::CPU.arm?
    url "https://github.com/cybersonic/LuCLI/releases/download/v#{LUCLI_VERSION}/lucli-#{LUCLI_VERSION}-macos"
    sha256 "MACOS_ARM_SHA"
  elsif OS.mac?
    url "https://github.com/cybersonic/LuCLI/releases/download/v#{LUCLI_VERSION}/lucli-#{LUCLI_VERSION}-macos"
    sha256 "MACOS_X86_SHA"
  elsif OS.linux?
    url "https://github.com/cybersonic/LuCLI/releases/download/v#{LUCLI_VERSION}/lucli-#{LUCLI_VERSION}-linux"
    sha256 "LINUX_SHA"
  end

  # Wheels module
  resource "wheels-module" do
    url "https://github.com/wheels-dev/wheels/releases/download/v#{MODULE_VERSION}/wheels-module.tar.gz"
    sha256 "MODULE_SHA"
  end

  depends_on "openjdk@21"

  def install
    # Binary
    libexec.install "lucli-#{version}-#{os_suffix}" => "wheels"
    chmod 0755, libexec/"wheels"

    # Module
    resource("wheels-module").stage do
      (share/"wheels/module").install Dir["*"]
    end

    # Version marker
    (share/"wheels/.module-version").write MODULE_VERSION

    # Wrapper script
    (bin/"wheels").write <<~EOS
      #!/bin/bash
      # ... wrapper script ...
    EOS
  end

  test do
    assert_match "Wheels Version", shell_output("#{bin}/wheels --version")
  end
end
```

### What `choco install wheels` Does

Same pattern, Windows artifacts:

1. Downloads `lucli-VERSION.bat` from `cybersonic/LuCLI` releases
2. Downloads `wheels-module.zip` from `wheels-dev/wheels` releases
3. Installs `wheels.cmd` wrapper to tools directory (Chocolatey adds to PATH)
4. Extracts module to `$env:USERPROFILE\.wheels\modules\wheels\`
5. Depends on Java 21 (declared in .nuspec)

### `wheels.cmd` Wrapper

```cmd
@echo off
set WHEELS_MODULE_SRC=%~dp0module
set WHEELS_MODULE_DST=%USERPROFILE%\.wheels\modules\wheels

if not exist "%WHEELS_MODULE_DST%\Module.cfc" (
    xcopy /E /I /Y "%WHEELS_MODULE_SRC%" "%WHEELS_MODULE_DST%" >nul 2>&1
)

"%~dp0lucli.bat" %*
```

## Auto-Update Workflow

### `homebrew-wheels/.github/workflows/auto-update.yml`

**Trigger:** Daily schedule (cron) + manual dispatch

**Steps:**

1. **Check LuCLI releases**
   - `gh release view --repo cybersonic/LuCLI --json tagName,assets`
   - Compare tag against version in formula
   - If newer: download artifacts, compute SHA256 for each platform

2. **Check Wheels module releases**
   - `gh release view --repo wheels-dev/wheels --json tagName,assets`
   - Look for `wheels-module.tar.gz` asset
   - Compare version against formula's `MODULE_VERSION`
   - If newer: download, compute SHA256

3. **If either changed:**
   - Update `Formula/wheels.rb` with new URLs and SHA256 hashes
   - Update version constants
   - Create branch `auto-update/lucli-X.Y.Z-module-A.B.C`
   - Open PR with changelog
   - Auto-merge after CI (formula audit + test) passes

4. **CI on the PR:**
   - `brew audit --strict Formula/wheels.rb`
   - `brew install --build-from-source Formula/wheels.rb`
   - `brew test Formula/wheels.rb`

### `chocolatey-wheels/.github/workflows/auto-update.yml`

Same polling logic, but:
- Updates `wheels.nuspec` version
- Updates download URLs in `chocolateyinstall.ps1`
- Rebuilds `.nupkg`
- Optionally auto-pushes to Chocolatey Community Repository

## Module Release Artifact

### Addition to `wheels-dev/wheels` Release Workflow

**Integrated into existing workflows** (develop → snapshot, main → release):

```yaml
# Added step in existing release job
- name: Package wheels module
  run: |
    tar czf wheels-module.tar.gz -C cli/lucli .
    # Windows variant
    cd cli/lucli && zip -r ../../wheels-module.zip . && cd ../..

- name: Upload module artifacts
  uses: softprops/action-gh-release@v2
  with:
    files: |
      wheels-module.tar.gz
      wheels-module.zip
```

This adds two assets (~30KB each) to every wheels release. Snapshot releases produce snapshot module artifacts; tagged releases produce stable ones.

## Version Tracking

The formula pins two independent versions:

```ruby
# Formula/wheels.rb
LUCLI_VERSION = "0.3.3"
MODULE_VERSION = "3.1.0"
```

- LuCLI updates when `cybersonic/LuCLI` releases a new version
- Module updates when `wheels-dev/wheels` releases a new version
- Either one bumping triggers an auto-update PR
- Both can bump in the same PR if they release simultaneously

## User Experience

### macOS

```bash
brew tap wheels-dev/wheels
brew install wheels

# Immediately works:
wheels --version    # "Wheels Version: 0.3.3"
wheels info         # detects project, server, config
wheels test         # runs test suite
```

### Windows

```powershell
choco install wheels

# Immediately works:
wheels --version
wheels info
wheels test
```

### Upgrade

```bash
brew upgrade wheels
# Next run auto-copies updated module to ~/.wheels/
wheels info
```

## Files Changed

### `wheels-dev/homebrew-wheels`
- `Formula/wheels.rb` — complete rewrite
- `.github/workflows/auto-update.yml` — new
- `.github/workflows/ci.yml` — new (audit + test on PR)
- `README.md` — updated for LuCLI

### `wheels-dev/chocolatey-wheels`
- `wheels.nuspec` — rewrite (remove CommandBox dep, add Java dep)
- `tools/chocolateyinstall.ps1` — rewrite
- `tools/chocolateyuninstall.ps1` — update
- `tools/wheels.cmd` — rewrite
- `.github/workflows/auto-update.yml` — new
- `README.md` — updated

### `wheels-dev/wheels`
- `.github/workflows/release.yml` (or equivalent) — add module tarball/zip step
