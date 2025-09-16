param(
    [string]$OutputDir = "installer",
    [string]$ExeName = "wheels-installer.exe"
)

Write-Host "Creating Wheels Windows Installer Executable..." -ForegroundColor Green

try {
    Get-Command ps2exe -ErrorAction Stop
    Write-Host "OK ps2exe found" -ForegroundColor Green
} catch {
    Write-Host "Installing ps2exe module..." -ForegroundColor Yellow
    Install-Module ps2exe -Force -Scope CurrentUser
    Import-Module ps2exe
}

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
    Write-Host "OK Created output directory: $OutputDir" -ForegroundColor Green
}

$OutputPath = Join-Path $OutputDir $ExeName

# Check if the source PowerShell script exists
$sourceScript = "install-wheels.ps1"
if (-not (Test-Path $sourceScript)) {
    Write-Error "Source script not found: $sourceScript"
    Write-Host "Please ensure install-wheels.ps1 exists in the same directory" -ForegroundColor Yellow
    exit 1
}

Write-Host "Converting PowerShell script to executable..." -ForegroundColor Yellow
Write-Host "Source: $sourceScript" -ForegroundColor Gray

ps2exe -inputFile $sourceScript `
       -outputFile $OutputPath `
       -title "Wheels Framework Installer" `
       -description "Wheels Framework Installer for Windows" `
       -company "Wheels Framework" `
       -version "1.0.0.0" `
       -copyright "(c) 2024 Wheels Framework" `
       -requireAdmin -verbose

if (Test-Path $OutputPath) {
    Write-Host "OK Successfully created: $OutputPath" -ForegroundColor Green
    Write-Host ""
    Write-Host "The executable is ready for installerribution!" -ForegroundColor Cyan
    Write-Host "File size: $([math]::Round((Get-Item $OutputPath).Length / 1MB, 2)) MB" -ForegroundColor Cyan
} else {
    Write-Error "Failed to create executable"
    exit 1
}