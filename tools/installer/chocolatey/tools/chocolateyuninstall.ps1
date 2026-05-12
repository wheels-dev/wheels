$ErrorActionPreference = 'Stop'

$installDir = Join-Path $env:ChocolateyInstall 'lib\lucli\tools\bin'

# Remove shims
Uninstall-BinFile -Name 'lucli'
Uninstall-BinFile -Name 'wheels'

# Clean up installed files
if (Test-Path $installDir) {
    Remove-Item -Path $installDir -Recurse -Force
    Write-Host "LuCLI removed from $installDir" -ForegroundColor Green
}
