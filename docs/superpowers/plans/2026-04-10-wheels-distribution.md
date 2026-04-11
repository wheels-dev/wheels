# Wheels CLI Distribution Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rewrite Homebrew and Chocolatey packages to install the LuCLI-based `wheels` binary with auto-updating from upstream releases.

**Architecture:** Three repos involved: `wheels-dev/wheels` (add module tarball to release), `wheels-dev/homebrew-wheels` (rewrite formula + auto-update workflow), `wheels-dev/chocolatey-wheels` (rewrite package + auto-update workflow). Each task targets a single repo.

**Tech Stack:** Homebrew Ruby DSL, Chocolatey NuSpec/PowerShell, GitHub Actions, GitHub CLI (`gh`)

---

### Task 1: Add Module Tarball to Wheels Release Workflow

**Repo:** `wheels-dev/wheels`

**Files:**
- Modify: `.github/workflows/release.yml` (lines 191-290)

- [ ] **Step 1: Add module tarball build step**

Insert after line 196 (after "Build All Wheels Artifacts") and before line 198 (before "Upload Wheels Base Template Artifact"):

```yaml
      - name: Build Wheels Module Tarball
        run: |
          mkdir -p artifacts/wheels/${{ env.WHEELS_VERSION }}
          tar czf artifacts/wheels/${{ env.WHEELS_VERSION }}/wheels-module-${{ env.WHEELS_VERSION }}.tar.gz -C cli/lucli .
          cd cli/lucli && zip -r ../../artifacts/wheels/${{ env.WHEELS_VERSION }}/wheels-module-${{ env.WHEELS_VERSION }}.zip . && cd ../..
          cd artifacts/wheels/${{ env.WHEELS_VERSION }}
          md5sum wheels-module-${{ env.WHEELS_VERSION }}.tar.gz > wheels-module-${{ env.WHEELS_VERSION }}.tar.gz.md5 || md5 -r wheels-module-${{ env.WHEELS_VERSION }}.tar.gz > wheels-module-${{ env.WHEELS_VERSION }}.tar.gz.md5
          sha512sum wheels-module-${{ env.WHEELS_VERSION }}.tar.gz > wheels-module-${{ env.WHEELS_VERSION }}.tar.gz.sha512 || shasum -a 512 wheels-module-${{ env.WHEELS_VERSION }}.tar.gz > wheels-module-${{ env.WHEELS_VERSION }}.tar.gz.sha512
          md5sum wheels-module-${{ env.WHEELS_VERSION }}.zip > wheels-module-${{ env.WHEELS_VERSION }}.zip.md5 || md5 -r wheels-module-${{ env.WHEELS_VERSION }}.zip > wheels-module-${{ env.WHEELS_VERSION }}.zip.md5
          sha512sum wheels-module-${{ env.WHEELS_VERSION }}.zip > wheels-module-${{ env.WHEELS_VERSION }}.zip.sha512 || shasum -a 512 wheels-module-${{ env.WHEELS_VERSION }}.zip > wheels-module-${{ env.WHEELS_VERSION }}.zip.sha512
```

- [ ] **Step 2: Add module upload step**

Insert after the "Upload Wheels Starter App Artifact" step (after line 236):

```yaml
      - name: Upload Wheels Module Artifact
        uses: actions/upload-artifact@v4
        with:
          name: build-artifacts-module
          path: |
            artifacts/wheels/${{ env.WHEELS_VERSION }}/wheels-module-*.tar.gz
            artifacts/wheels/${{ env.WHEELS_VERSION }}/wheels-module-*.zip
            artifacts/wheels/${{ env.WHEELS_VERSION }}/wheels-module-*.md5
            artifacts/wheels/${{ env.WHEELS_VERSION }}/wheels-module-*.sha512
```

- [ ] **Step 3: Add module to GitHub Release assets**

In the "Create GitHub Release" step (line 277), add to the `files:` list:

```yaml
            artifacts/wheels/${{ env.WHEELS_VERSION }}/wheels-module-*.tar.gz
            artifacts/wheels/${{ env.WHEELS_VERSION }}/wheels-module-*.tar.gz.md5
            artifacts/wheels/${{ env.WHEELS_VERSION }}/wheels-module-*.tar.gz.sha512
            artifacts/wheels/${{ env.WHEELS_VERSION }}/wheels-module-*.zip
            artifacts/wheels/${{ env.WHEELS_VERSION }}/wheels-module-*.zip.md5
            artifacts/wheels/${{ env.WHEELS_VERSION }}/wheels-module-*.zip.sha512
```

- [ ] **Step 4: Verify locally**

```bash
cd /Users/peter/GitHub/wheels-dev/wheels
mkdir -p /tmp/test-module-build
tar czf /tmp/test-module-build/wheels-module-test.tar.gz -C cli/lucli .
tar tzf /tmp/test-module-build/wheels-module-test.tar.gz | head -10
# Should show: Module.cfc, module.json, services/, templates/, etc.
ls -lh /tmp/test-module-build/wheels-module-test.tar.gz
# Should be ~20-40KB
```

- [ ] **Step 5: Commit**

```bash
cd /Users/peter/GitHub/wheels-dev/wheels
git add .github/workflows/release.yml
git commit -m "ci(cli): add wheels module tarball to release artifacts"
```

---

### Task 2: Rewrite Homebrew Formula

**Repo:** `wheels-dev/homebrew-wheels`

**Files:**
- Rewrite: `Formula/wheels.rb`
- Rewrite: `README.md`
- Rewrite: `CLAUDE.md`
- Delete: `server.json`

- [ ] **Step 1: Write the formula**

Replace `Formula/wheels.rb` with:

```ruby
class Wheels < Formula
  desc "CLI for the Wheels MVC framework — powered by LuCLI"
  homepage "https://wheels.dev"
  license "Apache-2.0"
  
  LUCLI_VERSION = "0.3.3"
  MODULE_VERSION = "4.0.0+50"

  if OS.mac?
    url "https://github.com/cybersonic/LuCLI/releases/download/v#{LUCLI_VERSION}/lucli-#{LUCLI_VERSION}-macos"
    sha256 "PLACEHOLDER_MACOS_SHA"
  elsif OS.linux?
    url "https://github.com/cybersonic/LuCLI/releases/download/v#{LUCLI_VERSION}/lucli-#{LUCLI_VERSION}-linux"
    sha256 "PLACEHOLDER_LINUX_SHA"
  end

  resource "wheels_module" do
    url "https://github.com/wheels-dev/wheels/releases/download/v#{MODULE_VERSION}/wheels-module-#{MODULE_VERSION}.tar.gz"
    sha256 "PLACEHOLDER_MODULE_SHA"
  end

  depends_on "openjdk@21"

  def install
    os_suffix = OS.mac? ? "macos" : "linux"
    binary_name = "lucli-#{LUCLI_VERSION}-#{os_suffix}"

    if File.exist?(binary_name)
      libexec.install binary_name => "wheels"
    else
      # Single-file download is named after the formula
      libexec.install Dir["*"].first => "wheels"
    end
    chmod 0755, libexec/"wheels"

    resource("wheels_module").stage do
      (share/"wheels/module").install Dir["*"]
    end

    (share/"wheels").mkpath
    (share/"wheels/.module-version").write MODULE_VERSION

    (bin/"wheels").write <<~EOS
      #!/bin/bash
      BREW_PREFIX="#{HOMEBREW_PREFIX}/opt/wheels"
      WHEELS_MODULE_SRC="$BREW_PREFIX/share/wheels/module"
      WHEELS_MODULE_DST="$HOME/.wheels/modules/wheels"
      WHEELS_VERSION_SRC="$BREW_PREFIX/share/wheels/.module-version"
      WHEELS_VERSION_DST="$HOME/.wheels/modules/wheels/.module-version"

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

      export JAVA_HOME="#{Formula["openjdk@21"].opt_libexec}/openjdk.jdk/Contents/Home"
      exec "$BREW_PREFIX/libexec/wheels" "$@"
    EOS
    chmod 0755, bin/"wheels"
  end

  def caveats
    <<~EOS
      Java 21 is required and has been installed as a dependency.

      The Wheels module is installed to:
        #{share}/wheels/module/

      On first run, it will be copied to:
        ~/.wheels/modules/wheels/
    EOS
  end

  test do
    assert_predicate bin/"wheels", :executable?
    assert_predicate libexec/"wheels", :executable?
    assert_predicate share/"wheels/module/Module.cfc", :exist?
  end
end
```

- [ ] **Step 2: Compute real SHA256 hashes**

```bash
# Download LuCLI artifacts and compute hashes
curl -sfL "https://github.com/cybersonic/LuCLI/releases/download/v0.3.3/lucli-0.3.3-macos" -o /tmp/lucli-macos
shasum -a 256 /tmp/lucli-macos

curl -sfL "https://github.com/cybersonic/LuCLI/releases/download/v0.3.3/lucli-0.3.3-linux" -o /tmp/lucli-linux
shasum -a 256 /tmp/lucli-linux
```

Update the `PLACEHOLDER_*_SHA` values in the formula. The module SHA can't be computed yet (tarball doesn't exist until Task 1 is released), so leave `PLACEHOLDER_MODULE_SHA` for now.

- [ ] **Step 3: Write README.md**

Replace `README.md` with:

```markdown
# Homebrew Wheels

Homebrew formula for the [Wheels](https://wheels.dev) CLI — the command-line tool for the Wheels MVC framework.

## Install

```bash
brew tap wheels-dev/wheels
brew install wheels
```

## Usage

```bash
wheels new myapp          # scaffold a new project
wheels server start       # start development server
wheels test               # run test suite
wheels generate model User  # generate a model
wheels --version          # show version info
```

## Requirements

- Java 21 (installed automatically as a dependency)
- macOS or Linux

## Update

```bash
brew upgrade wheels
```

## Uninstall

```bash
brew uninstall wheels
brew untap wheels-dev/wheels
```

## How It Works

This formula installs [LuCLI](https://github.com/cybersonic/LuCLI) (the Lucee CLI) as the `wheels` binary, along with the Wheels CLI module. LuCLI's binary-name detection automatically activates Wheels branding and routes commands to the Wheels module.

The formula auto-updates when new LuCLI or Wheels versions are released.
```

- [ ] **Step 4: Update CLAUDE.md**

Replace `CLAUDE.md` with:

```markdown
# CLAUDE.md

## What This Is

Homebrew tap for the Wheels CLI. Installs two things:
1. LuCLI binary (from cybersonic/LuCLI releases) as `wheels`
2. Wheels module (from wheels-dev/wheels releases) into share/wheels/module/

A wrapper script in bin/wheels copies the module to ~/.wheels/modules/wheels/ on first run.

## Formula Structure

- `Formula/wheels.rb` — the Homebrew formula
- Two version constants: `LUCLI_VERSION` and `MODULE_VERSION`
- `resource "wheels_module"` block for the module tarball

## Development Commands

```bash
brew install --build-from-source Formula/wheels.rb  # test install
brew test wheels                                      # run tests
brew audit --strict Formula/wheels.rb                 # lint
```

## Auto-Update

`.github/workflows/auto-update.yml` polls cybersonic/LuCLI and wheels-dev/wheels releases daily. If either has a new version, it updates the formula and auto-merges.
```

- [ ] **Step 5: Remove server.json**

```bash
cd /Users/peter/GitHub/wheels-dev/homebrew-wheels
rm server.json
```

- [ ] **Step 6: Test the formula locally**

```bash
cd /Users/peter/GitHub/wheels-dev/homebrew-wheels
brew install --build-from-source Formula/wheels.rb
brew test wheels
wheels --version
```

- [ ] **Step 7: Commit**

```bash
cd /Users/peter/GitHub/wheels-dev/homebrew-wheels
git add -A
git commit -m "feat: rewrite formula for LuCLI-based wheels CLI

Replace CommandBox wrapper with LuCLI binary + Wheels module.
- Downloads LuCLI binary from cybersonic/LuCLI releases
- Downloads Wheels module tarball from wheels-dev/wheels releases
- Wrapper script copies module to ~/.wheels/ on first run
- Depends on openjdk@21 instead of commandbox"
```

---

### Task 3: Add Auto-Update Workflow to Homebrew Repo

**Repo:** `wheels-dev/homebrew-wheels`

**Files:**
- Create: `.github/workflows/auto-update.yml`
- Create: `.github/workflows/ci.yml`

- [ ] **Step 1: Create CI workflow**

Create `.github/workflows/ci.yml`:

```yaml
name: CI

on:
  pull_request:
    paths:
      - 'Formula/**'

jobs:
  audit:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4

      - name: Audit formula
        run: brew audit --strict Formula/wheels.rb

      - name: Install formula
        run: brew install --build-from-source Formula/wheels.rb

      - name: Test formula
        run: brew test wheels
```

- [ ] **Step 2: Create auto-update workflow**

Create `.github/workflows/auto-update.yml`:

```yaml
name: Auto-Update Formula

on:
  schedule:
    - cron: '0 8 * * *'  # Daily at 8am UTC
  workflow_dispatch:

permissions:
  contents: write
  pull-requests: write

jobs:
  check-updates:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4

      - name: Check for updates
        id: check
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          # Current versions from formula
          CURRENT_LUCLI=$(grep "LUCLI_VERSION" Formula/wheels.rb | head -1 | sed 's/.*"\(.*\)".*/\1/')
          CURRENT_MODULE=$(grep "MODULE_VERSION" Formula/wheels.rb | head -1 | sed 's/.*"\(.*\)".*/\1/')
          echo "current_lucli=$CURRENT_LUCLI" >> "$GITHUB_OUTPUT"
          echo "current_module=$CURRENT_MODULE" >> "$GITHUB_OUTPUT"

          # Latest LuCLI release
          LATEST_LUCLI=$(gh release view --repo cybersonic/LuCLI --json tagName -q '.tagName' | sed 's/^v//')
          echo "latest_lucli=$LATEST_LUCLI" >> "$GITHUB_OUTPUT"

          # Latest Wheels release with module tarball
          LATEST_MODULE=$(gh release list --repo wheels-dev/wheels --limit 20 --json tagName,assets -q '
            [.[] | select(.assets[].name | test("wheels-module.*\\.tar\\.gz"))] | .[0].tagName
          ' | sed 's/^v//')
          echo "latest_module=$LATEST_MODULE" >> "$GITHUB_OUTPUT"

          # Determine if update needed
          NEEDS_UPDATE="false"
          if [ "$CURRENT_LUCLI" != "$LATEST_LUCLI" ] && [ -n "$LATEST_LUCLI" ]; then
            NEEDS_UPDATE="true"
            echo "LuCLI update: $CURRENT_LUCLI -> $LATEST_LUCLI"
          fi
          if [ "$CURRENT_MODULE" != "$LATEST_MODULE" ] && [ -n "$LATEST_MODULE" ]; then
            NEEDS_UPDATE="true"
            echo "Module update: $CURRENT_MODULE -> $LATEST_MODULE"
          fi
          echo "needs_update=$NEEDS_UPDATE" >> "$GITHUB_OUTPUT"

      - name: Compute SHA256 hashes
        if: steps.check.outputs.needs_update == 'true'
        id: hashes
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          LUCLI_VER="${{ steps.check.outputs.latest_lucli }}"
          MODULE_VER="${{ steps.check.outputs.latest_module }}"

          # LuCLI binaries
          curl -sfL "https://github.com/cybersonic/LuCLI/releases/download/v${LUCLI_VER}/lucli-${LUCLI_VER}-macos" -o /tmp/lucli-macos
          MACOS_SHA=$(shasum -a 256 /tmp/lucli-macos | awk '{print $1}')
          echo "macos_sha=$MACOS_SHA" >> "$GITHUB_OUTPUT"

          curl -sfL "https://github.com/cybersonic/LuCLI/releases/download/v${LUCLI_VER}/lucli-${LUCLI_VER}-linux" -o /tmp/lucli-linux
          LINUX_SHA=$(shasum -a 256 /tmp/lucli-linux | awk '{print $1}')
          echo "linux_sha=$LINUX_SHA" >> "$GITHUB_OUTPUT"

          # Module tarball
          curl -sfL "https://github.com/wheels-dev/wheels/releases/download/v${MODULE_VER}/wheels-module-${MODULE_VER}.tar.gz" -o /tmp/wheels-module.tar.gz
          MODULE_SHA=$(shasum -a 256 /tmp/wheels-module.tar.gz | awk '{print $1}')
          echo "module_sha=$MODULE_SHA" >> "$GITHUB_OUTPUT"

      - name: Update formula
        if: steps.check.outputs.needs_update == 'true'
        run: |
          LUCLI_VER="${{ steps.check.outputs.latest_lucli }}"
          MODULE_VER="${{ steps.check.outputs.latest_module }}"
          MACOS_SHA="${{ steps.hashes.outputs.macos_sha }}"
          LINUX_SHA="${{ steps.hashes.outputs.linux_sha }}"
          MODULE_SHA="${{ steps.hashes.outputs.module_sha }}"

          # Update version constants
          sed -i '' "s/LUCLI_VERSION = \".*\"/LUCLI_VERSION = \"${LUCLI_VER}\"/" Formula/wheels.rb
          sed -i '' "s/MODULE_VERSION = \".*\"/MODULE_VERSION = \"${MODULE_VER}\"/" Formula/wheels.rb

          # Update SHA256 hashes
          # macOS SHA is first sha256 in the file (inside if OS.mac? block)
          # Linux SHA is second sha256 (inside elsif OS.linux? block)
          # Module SHA is third sha256 (inside resource block)
          python3 -c "
          import re
          with open('Formula/wheels.rb', 'r') as f:
              content = f.read()
          shas = list(re.finditer(r'sha256 \"[a-f0-9]+\"', content))
          if len(shas) >= 3:
              # Replace in reverse order to preserve positions
              content = content[:shas[2].start()] + 'sha256 \"${MODULE_SHA}\"' + content[shas[2].end():]
              content = content[:shas[1].start()] + 'sha256 \"${LINUX_SHA}\"' + content[shas[1].end():]
              content = content[:shas[0].start()] + 'sha256 \"${MACOS_SHA}\"' + content[shas[0].end():]
          with open('Formula/wheels.rb', 'w') as f:
              f.write(content)
          "

      - name: Create PR
        if: steps.check.outputs.needs_update == 'true'
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          LUCLI_VER="${{ steps.check.outputs.latest_lucli }}"
          MODULE_VER="${{ steps.check.outputs.latest_module }}"
          BRANCH="auto-update/lucli-${LUCLI_VER}-module-${MODULE_VER}"

          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git checkout -b "$BRANCH"
          git add Formula/wheels.rb
          git commit -m "chore: update to LuCLI ${LUCLI_VER}, module ${MODULE_VER}"
          git push origin "$BRANCH"

          gh pr create \
            --title "chore: update to LuCLI ${LUCLI_VER}, module ${MODULE_VER}" \
            --body "Auto-update from upstream releases.

          - LuCLI: ${{ steps.check.outputs.current_lucli }} → ${LUCLI_VER}
          - Module: ${{ steps.check.outputs.current_module }} → ${MODULE_VER}" \
            --label "auto-update"

      - name: Enable auto-merge
        if: steps.check.outputs.needs_update == 'true'
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          LUCLI_VER="${{ steps.check.outputs.latest_lucli }}"
          MODULE_VER="${{ steps.check.outputs.latest_module }}"
          PR_URL=$(gh pr list --head "auto-update/lucli-${LUCLI_VER}-module-${MODULE_VER}" --json url -q '.[0].url')
          if [ -n "$PR_URL" ]; then
            gh pr merge "$PR_URL" --auto --squash
          fi
```

- [ ] **Step 3: Commit**

```bash
cd /Users/peter/GitHub/wheels-dev/homebrew-wheels
git add .github/workflows/
git commit -m "ci: add auto-update and CI workflows

Auto-update polls cybersonic/LuCLI and wheels-dev/wheels daily.
If either has a new release, updates formula and auto-merges PR."
```

---

### Task 4: Rewrite Chocolatey Package

**Repo:** `wheels-dev/chocolatey-wheels`

**Files:**
- Rewrite: `wheels.nuspec`
- Rewrite: `tools/chocolateyinstall.ps1`
- Rewrite: `tools/chocolateyuninstall.ps1`
- Rewrite: `tools/wheels.cmd`
- Rewrite: `README.md`
- Rewrite: `CLAUDE.md`
- Delete: `wheels.1.0.6.nupkg`

- [ ] **Step 1: Write wheels.nuspec**

```xml
<?xml version="1.0" encoding="utf-8"?>
<package xmlns="http://schemas.chocolatey.org/2010/07/nuspec">
  <metadata>
    <id>wheels</id>
    <version>2.0.0</version>
    <title>Wheels CLI</title>
    <authors>Wheels Team</authors>
    <owners>wheels-dev</owners>
    <summary>CLI for the Wheels MVC framework</summary>
    <description>Command-line tool for the Wheels MVC framework, powered by LuCLI. Provides project scaffolding, code generation, database migrations, testing, and server management.

## Features
- `wheels new myapp` — scaffold new projects
- `wheels generate model User` — code generation
- `wheels test` — run test suite
- `wheels server start` — development server
- `wheels dbmigrate latest` — database migrations

## Requirements
- Java 21 or later
    </description>
    <projectUrl>https://wheels.dev</projectUrl>
    <projectSourceUrl>https://github.com/wheels-dev/wheels</projectSourceUrl>
    <packageSourceUrl>https://github.com/wheels-dev/chocolatey-wheels</packageSourceUrl>
    <docsUrl>https://wheels.dev/guides</docsUrl>
    <bugTrackerUrl>https://github.com/wheels-dev/chocolatey-wheels/issues</bugTrackerUrl>
    <tags>wheels mvc framework cli lucee cfml lucli</tags>
    <copyright>2026 Wheels Team</copyright>
    <licenseUrl>https://github.com/wheels-dev/chocolatey-wheels/blob/master/LICENSE</licenseUrl>
    <requireLicenseAcceptance>false</requireLicenseAcceptance>
    <iconUrl>https://raw.githubusercontent.com/wheels-dev/chocolatey-wheels/master/logo_mark.png</iconUrl>
    <releaseNotes>Rewritten for LuCLI-based Wheels CLI. Replaces CommandBox dependency with LuCLI + Java 21.</releaseNotes>
    <dependencies>
      <dependency id="openjdk" version="21.0.0" />
    </dependencies>
  </metadata>
  <files>
    <file src="tools\**" target="tools" />
  </files>
</package>
```

- [ ] **Step 2: Write chocolateyinstall.ps1**

```powershell
$ErrorActionPreference = 'Stop'

$toolsDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

$lucliVersion = "0.3.3"
$moduleVersion = "4.0.0+50"

# Download LuCLI Windows launcher
$lucliUrl = "https://github.com/cybersonic/LuCLI/releases/download/v${lucliVersion}/lucli-${lucliVersion}.bat"
$lucliPath = Join-Path $toolsDir "lucli.bat"
Invoke-WebRequest -Uri $lucliUrl -OutFile $lucliPath -UseBasicParsing

# Download Wheels module
$moduleUrl = "https://github.com/wheels-dev/wheels/releases/download/v${moduleVersion}/wheels-module-${moduleVersion}.zip"
$modulePath = Join-Path $toolsDir "wheels-module.zip"
Invoke-WebRequest -Uri $moduleUrl -OutFile $modulePath -UseBasicParsing

# Extract module to tools/module/
$moduleDir = Join-Path $toolsDir "module"
if (Test-Path $moduleDir) { Remove-Item $moduleDir -Recurse -Force }
Expand-Archive -Path $modulePath -DestinationPath $moduleDir -Force
Remove-Item $modulePath -Force

# Write version marker
Set-Content -Path (Join-Path $moduleDir ".module-version") -Value $moduleVersion

Write-Host "Wheels CLI installed successfully!" -ForegroundColor Green
Write-Host "Run 'wheels --version' to verify." -ForegroundColor Cyan
```

- [ ] **Step 3: Write wheels.cmd**

```cmd
@echo off
setlocal

set "TOOLS_DIR=%~dp0"
set "MODULE_SRC=%TOOLS_DIR%module"
set "MODULE_DST=%USERPROFILE%\.wheels\modules\wheels"
set "VERSION_SRC=%MODULE_SRC%\.module-version"
set "VERSION_DST=%MODULE_DST%\.module-version"

:: Copy module on first run or when version changes
if exist "%VERSION_SRC%" (
    set /p SRC_VER=<"%VERSION_SRC%"
    set "DST_VER="
    if exist "%VERSION_DST%" set /p DST_VER=<"%VERSION_DST%"
    if not "!SRC_VER!"=="!DST_VER!" (
        if not exist "%MODULE_DST%" mkdir "%MODULE_DST%"
        xcopy /E /I /Y "%MODULE_SRC%\*" "%MODULE_DST%\" >nul 2>&1
    )
)

endlocal & "%~dp0lucli.bat" %*
```

- [ ] **Step 4: Write chocolateyuninstall.ps1**

```powershell
$ErrorActionPreference = 'Stop'

$toolsDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Clean up downloaded files
$filesToRemove = @("lucli.bat", "wheels-module.zip")
foreach ($file in $filesToRemove) {
    $path = Join-Path $toolsDir $file
    if (Test-Path $path) { Remove-Item $path -Force }
}

$moduleDir = Join-Path $toolsDir "module"
if (Test-Path $moduleDir) { Remove-Item $moduleDir -Recurse -Force }

Write-Host "Wheels CLI uninstalled." -ForegroundColor Green
Write-Host "Note: ~/.wheels/ directory was not removed. Delete it manually if desired." -ForegroundColor Yellow
```

- [ ] **Step 5: Delete old nupkg and update supporting files**

```bash
cd /Users/peter/GitHub/wheels-dev/chocolatey-wheels
rm -f wheels.1.0.6.nupkg
```

Update `README.md` and `CLAUDE.md` (same content pattern as Task 2, adapted for Chocolatey).

- [ ] **Step 6: Build and test locally**

```powershell
# On a Windows machine or VM:
choco pack wheels.nuspec
choco install wheels --source . --force
wheels --version
```

- [ ] **Step 7: Commit**

```bash
cd /Users/peter/GitHub/wheels-dev/chocolatey-wheels
git add -A
git commit -m "feat: rewrite package for LuCLI-based wheels CLI

Replace CommandBox wrapper with LuCLI binary + Wheels module.
- Downloads LuCLI .bat launcher from cybersonic/LuCLI releases
- Downloads Wheels module zip from wheels-dev/wheels releases
- Wrapper copies module to ~/.wheels/ on first run
- Depends on openjdk 21 instead of commandbox"
```

---

### Task 5: Add Auto-Update Workflow to Chocolatey Repo

**Repo:** `wheels-dev/chocolatey-wheels`

**Files:**
- Create: `.github/workflows/auto-update.yml`

- [ ] **Step 1: Create auto-update workflow**

Create `.github/workflows/auto-update.yml`:

```yaml
name: Auto-Update Package

on:
  schedule:
    - cron: '0 9 * * *'  # Daily at 9am UTC (1h after Homebrew)
  workflow_dispatch:

permissions:
  contents: write
  pull-requests: write

jobs:
  check-updates:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v4

      - name: Check for updates
        id: check
        shell: pwsh
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          # Current versions from nuspec install script
          $installScript = Get-Content tools/chocolateyinstall.ps1 -Raw
          $currentLucli = [regex]::Match($installScript, 'lucliVersion = "([^"]+)"').Groups[1].Value
          $currentModule = [regex]::Match($installScript, 'moduleVersion = "([^"]+)"').Groups[1].Value
          "current_lucli=$currentLucli" >> $env:GITHUB_OUTPUT
          "current_module=$currentModule" >> $env:GITHUB_OUTPUT

          # Latest LuCLI release
          $latestLucli = (gh release view --repo cybersonic/LuCLI --json tagName -q '.tagName') -replace '^v', ''
          "latest_lucli=$latestLucli" >> $env:GITHUB_OUTPUT

          # Latest Wheels release with module zip
          $releases = gh release list --repo wheels-dev/wheels --limit 20 --json tagName,assets | ConvertFrom-Json
          $latestModule = ($releases | Where-Object { $_.assets.name -match 'wheels-module.*\.zip' } | Select-Object -First 1).tagName -replace '^v', ''
          "latest_module=$latestModule" >> $env:GITHUB_OUTPUT

          $needsUpdate = ($currentLucli -ne $latestLucli -and $latestLucli) -or ($currentModule -ne $latestModule -and $latestModule)
          "needs_update=$($needsUpdate.ToString().ToLower())" >> $env:GITHUB_OUTPUT

      - name: Update install script
        if: steps.check.outputs.needs_update == 'true'
        shell: pwsh
        run: |
          $lucliVer = "${{ steps.check.outputs.latest_lucli }}"
          $moduleVer = "${{ steps.check.outputs.latest_module }}"

          # Update chocolateyinstall.ps1
          $content = Get-Content tools/chocolateyinstall.ps1 -Raw
          $content = $content -replace 'lucliVersion = "[^"]+"', "lucliVersion = `"$lucliVer`""
          $content = $content -replace 'moduleVersion = "[^"]+"', "moduleVersion = `"$moduleVer`""
          Set-Content tools/chocolateyinstall.ps1 $content

          # Update nuspec version (use LuCLI version as package version)
          [xml]$nuspec = Get-Content wheels.nuspec
          $nuspec.package.metadata.version = $lucliVer
          $nuspec.Save("wheels.nuspec")

      - name: Create PR
        if: steps.check.outputs.needs_update == 'true'
        shell: bash
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          LUCLI_VER="${{ steps.check.outputs.latest_lucli }}"
          MODULE_VER="${{ steps.check.outputs.latest_module }}"
          BRANCH="auto-update/lucli-${LUCLI_VER}-module-${MODULE_VER}"

          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git checkout -b "$BRANCH"
          git add -A
          git commit -m "chore: update to LuCLI ${LUCLI_VER}, module ${MODULE_VER}"
          git push origin "$BRANCH"

          gh pr create \
            --title "chore: update to LuCLI ${LUCLI_VER}, module ${MODULE_VER}" \
            --body "Auto-update from upstream releases." \
            --label "auto-update"

          PR_URL=$(gh pr list --head "$BRANCH" --json url -q '.[0].url')
          if [ -n "$PR_URL" ]; then
            gh pr merge "$PR_URL" --auto --squash
          fi
```

- [ ] **Step 2: Commit**

```bash
cd /Users/peter/GitHub/wheels-dev/chocolatey-wheels
git add .github/workflows/
git commit -m "ci: add auto-update workflow for Chocolatey package"
```

---

### Task 6: Final Integration Test

**Repo:** All three

- [ ] **Step 1: Push all changes**

```bash
# wheels repo
cd /Users/peter/GitHub/wheels-dev/wheels
git push origin develop

# homebrew repo
cd /Users/peter/GitHub/wheels-dev/homebrew-wheels
git push origin master

# chocolatey repo
cd /Users/peter/GitHub/wheels-dev/chocolatey-wheels
git push origin master
```

- [ ] **Step 2: Test Homebrew install from tap**

```bash
brew untap wheels-dev/wheels 2>/dev/null
brew tap wheels-dev/wheels
brew install wheels
wheels --version
wheels info
```

- [ ] **Step 3: Trigger auto-update workflow manually**

```bash
gh workflow run auto-update.yml --repo wheels-dev/homebrew-wheels
# Wait for workflow, check PR was created
gh pr list --repo wheels-dev/homebrew-wheels
```

- [ ] **Step 4: Commit any fixes found during integration**
