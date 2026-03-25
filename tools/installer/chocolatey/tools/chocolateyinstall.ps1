$ErrorActionPreference = 'Stop'

$toolsDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

# LuCLI version — must match the .nuspec <version>
$version    = '0.2.23'
$installDir = Join-Path $env:ChocolateyInstall 'lib\lucli\tools\bin'

$packageArgs = @{
    packageName    = 'lucli'
    url            = "https://github.com/cybersonic/LuCLI/releases/download/v${version}/lucli-${version}.bat"
    checksum       = ''  # Populated by build-choco.ps1 at pack time
    checksumType   = 'sha256'
    fileFullPath   = Join-Path $installDir 'lucli.bat'
}

New-Item -ItemType Directory -Path $installDir -Force | Out-Null

# Download the self-contained LuCLI Windows binary (.bat with embedded runtime)
Get-ChocolateyWebFile @packageArgs

# Create a `wheels` convenience wrapper that delegates to `lucli wheels`
$wheelsPath = Join-Path $installDir 'wheels.bat'
$wheelsContent = @"
@echo off
setlocal
"%~dp0lucli.bat" wheels %*
"@
Set-Content -Path $wheelsPath -Value $wheelsContent -Encoding ASCII

# Register shims so both `lucli` and `wheels` are on PATH
Install-BinFile -Name 'lucli'  -Path (Join-Path $installDir 'lucli.bat')
Install-BinFile -Name 'wheels' -Path $wheelsPath

Write-Host "LuCLI $version installed. Run 'lucli --version' to verify." -ForegroundColor Green
Write-Host ""
Write-Host "To install the Wheels framework module:" -ForegroundColor Cyan
Write-Host "  lucli modules install wheels" -ForegroundColor White
