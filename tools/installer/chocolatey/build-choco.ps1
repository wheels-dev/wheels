<#
.SYNOPSIS
    Builds the LuCLI Chocolatey package (.nupkg).

.DESCRIPTION
    Downloads the LuCLI release, computes SHA256 checksum, patches the install
    script, and runs `choco pack` to produce the .nupkg file.

.PARAMETER Version
    LuCLI version to package (e.g. "0.2.23"). Defaults to the version in the
    .nuspec file.

.EXAMPLE
    .\build-choco.ps1
    .\build-choco.ps1 -Version 0.3.0
#>
param(
    [string]$Version
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Read version from nuspec if not provided
if (-not $Version) {
    [xml]$nuspec = Get-Content (Join-Path $scriptDir 'lucli.nuspec')
    $Version = $nuspec.package.metadata.version
}

$downloadUrl = "https://github.com/cybersonic/LuCLI/releases/download/v${Version}/lucli-${Version}.bat"
$tempFile    = Join-Path $env:TEMP "lucli-${Version}.bat"

Write-Host "Building LuCLI Chocolatey package v$Version" -ForegroundColor Cyan
Write-Host "Downloading $downloadUrl ..."

# Download and compute checksum
Invoke-WebRequest -Uri $downloadUrl -OutFile $tempFile -UseBasicParsing
$checksum = (Get-FileHash -Path $tempFile -Algorithm SHA256).Hash.ToLower()
Remove-Item $tempFile -Force

Write-Host "SHA256: $checksum" -ForegroundColor Green

# Patch version into nuspec
$nuspecPath = Join-Path $scriptDir 'lucli.nuspec'
[xml]$nuspec = Get-Content $nuspecPath
$nuspec.package.metadata.version = $Version
$nuspec.Save($nuspecPath)

# Patch version and checksum into install script
$installPath = Join-Path $scriptDir 'tools\chocolateyinstall.ps1'
$installContent = Get-Content $installPath -Raw
$installContent = $installContent -replace "(?<=\`\$version\s*=\s*')[^']+", $Version
$installContent = $installContent -replace "(?<=checksum\s*=\s*')[^']*", $checksum
Set-Content -Path $installPath -Value $installContent -NoNewline

Write-Host "Patched install script with version=$Version checksum=$checksum"

# Build the package
Push-Location $scriptDir
try {
    choco pack lucli.nuspec
    $nupkg = "lucli.${Version}.nupkg"
    if (Test-Path $nupkg) {
        Write-Host "Package built: $nupkg" -ForegroundColor Green
    } else {
        Write-Error "Package file not found after choco pack"
    }
} finally {
    Pop-Location
}
