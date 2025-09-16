#Requires -Version 5.1
<#
.SYNOPSIS
    Wheels Framework Installer for Windows

.DESCRIPTION
    This script installs CommandBox, Wheels CLI, and all necessary dependencies
    on Windows systems. It ensures compatibility by installing modern versions
    of all components and both 'wheels' and 'wheels-cli' packages.

.PARAMETER InstallPath
    Custom installation directory. Defaults to Program Files for admin installs,
    user directory otherwise.

.PARAMETER Force
    Force reinstallation even if components already exist

.PARAMETER SkipPath
    Skip adding CommandBox to PATH

.EXAMPLE
    .\install-wheels.ps1

.EXAMPLE
    .\install-wheels.ps1 -InstallPath "C:\Tools\CommandBox" -Force
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$InstallPath = "",

    [Parameter()]
    [switch]$Force,

    [Parameter()]
    [switch]$SkipPath
)

# Configuration
$CommandBoxVersion = "6.2.1"
$MinimumJavaVersion = 11
$WheelsCliPackage = "wheels-cli"
$WheelsPackage = "wheels"

# URLs
$CommandBoxDownloadUrl = "https://downloads.ortussolutions.com/ortussolutions/commandbox/$CommandBoxVersion/commandbox-bin-$CommandBoxVersion.zip"
$JavaCheckUrl = "https://adoptium.net/temurin/releases/?version=17"

# Colors for output
function Write-ColorOutput {
    param(
        [Parameter(Position=0, Mandatory=$true)]
        [string]$Message,
        [Parameter(Position=1)]
        [ConsoleColor]$ForegroundColor = [ConsoleColor]::White,
        [Parameter(Position=2)]
        [switch]$NoNewline
    )

    $currentColor = $Host.UI.RawUI.ForegroundColor
    $Host.UI.RawUI.ForegroundColor = $ForegroundColor

    if ($NoNewline) {
        Write-Host $Message -NoNewline
    } else {
        Write-Host $Message
    }

    $Host.UI.RawUI.ForegroundColor = $currentColor
}

function Write-Info { param([string]$Message) Write-ColorOutput "INFO: $Message" -ForegroundColor Cyan }
function Write-Success { param([string]$Message) Write-ColorOutput "SUCCESS: $Message" -ForegroundColor Green }
function Write-Warning { param([string]$Message) Write-ColorOutput "WARNING: $Message" -ForegroundColor Yellow }
function Write-Error { param([string]$Message) Write-ColorOutput "ERROR: $Message" -ForegroundColor Red }

# Header
Write-Host ""
Write-ColorOutput "╔════════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
Write-ColorOutput "║                           Wheels Framework Installer                          ║" -ForegroundColor Magenta
Write-ColorOutput "║                                                                                ║" -ForegroundColor Magenta
Write-ColorOutput "║  This installer will set up CommandBox, Wheels CLI, and all dependencies      ║" -ForegroundColor Magenta
Write-ColorOutput "║  ensuring compatibility with modern CFML engines.                             ║" -ForegroundColor Magenta
Write-ColorOutput "║                                                                                ║" -ForegroundColor Magenta
Write-ColorOutput "║  Components installed:                                                         ║" -ForegroundColor Magenta
Write-ColorOutput "║  • CommandBox $CommandBoxVersion (CFML CLI & Server)                                    ║" -ForegroundColor Magenta
Write-ColorOutput "║  • wheels (Core Wheels package)                                               ║" -ForegroundColor Magenta
Write-ColorOutput "║  • wheels-cli (Wheels CLI commands)                                           ║" -ForegroundColor Magenta
Write-ColorOutput "╚════════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
Write-Host ""

# Check if running as administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

$isAdmin = Test-Administrator

# Determine installation path
if ([string]::IsNullOrEmpty($InstallPath)) {
    if ($isAdmin) {
        $InstallPath = "$env:ProgramFiles\CommandBox"
    } else {
        $InstallPath = "$env:USERPROFILE\.commandbox"
    }
}

Write-Info "Installation path: $InstallPath"
Write-Info "Administrator privileges: $(if ($isAdmin) { 'Yes' } else { 'No' })"

# Check Java installation
function Test-JavaInstallation {
    Write-Info "Checking Java installation..."

    try {
        $javaOutput = java -version 2>&1
        if ($javaOutput -match "version `"([^`"]+)`"") {
            $javaVersionString = $matches[1]
            Write-Success "Java found: $javaVersionString"

            # Extract major version number
            if ($javaVersionString -match "^1\.(\d+)") {
                $javaMajorVersion = [int]$matches[1]
            } elseif ($javaVersionString -match "^(\d+)") {
                $javaMajorVersion = [int]$matches[1]
            } else {
                Write-Warning "Unable to parse Java version: $javaVersionString"
                return $false
            }

            if ($javaMajorVersion -ge $MinimumJavaVersion) {
                Write-Success "Java version meets requirements (>= $MinimumJavaVersion)"
                return $true
            } else {
                Write-Warning "Java version $javaMajorVersion is below minimum requirement ($MinimumJavaVersion)"
                return $false
            }
        }
    } catch {
        Write-Warning "Java not found in PATH"
        return $false
    }

    return $false
}

# Download file with progress
function Download-File {
    param(
        [string]$Url,
        [string]$OutputPath
    )

    Write-Info "Downloading from: $Url"
    Write-Info "Saving to: $OutputPath"

    try {
        # Use WebClient for better progress reporting
        $webClient = New-Object System.Net.WebClient

        # Register progress event
        Register-ObjectEvent -InputObject $webClient -EventName DownloadProgressChanged -Action {
            $Global:ProgressPreference = 'Continue'
            Write-Progress -Activity "Downloading CommandBox" -Status "Progress: $($Event.SourceEventArgs.ProgressPercentage)%" -PercentComplete $Event.SourceEventArgs.ProgressPercentage
        } | Out-Null

        $webClient.DownloadFile($Url, $OutputPath)
        $webClient.Dispose()

        Write-Progress -Activity "Downloading CommandBox" -Completed
        Write-Success "Download completed"
        return $true
    } catch {
        Write-Error "Download failed: $($_.Exception.Message)"
        return $false
    }
}

# Install CommandBox
function Install-CommandBox {
    Write-Info "Installing CommandBox..."

    # Check if CommandBox already exists
    $boxExePath = Join-Path $InstallPath "box.exe"
    if ((Test-Path $boxExePath) -and -not $Force) {
        try {
            $existingVersion = & $boxExePath version 2>$null
            if ($existingVersion -match "CommandBox\s+([\d\.]+)") {
                $currentVersion = $matches[1]
                Write-Info "CommandBox $currentVersion already installed"

                # Compare versions (simplified - assumes semantic versioning)
                if ($currentVersion -eq $CommandBoxVersion) {
                    Write-Success "CommandBox is up to date"
                    return $boxExePath
                } else {
                    Write-Info "Current version: $currentVersion, Available: $CommandBoxVersion"
                }
            }
        } catch {
            Write-Warning "Unable to determine existing CommandBox version"
        }

        if (-not $Force) {
            $response = Read-Host "CommandBox already exists. Reinstall? (y/N)"
            if ($response -notmatch "^[yY]") {
                Write-Info "Using existing CommandBox installation"
                return $boxExePath
            }
        }
    }

    # Create installation directory
    if (-not (Test-Path $InstallPath)) {
        Write-Info "Creating installation directory: $InstallPath"
        try {
            New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
        } catch {
            Write-Error "Failed to create installation directory: $($_.Exception.Message)"
            return $null
        }
    }

    # Download CommandBox
    $tempZip = Join-Path $env:TEMP "commandbox-$CommandBoxVersion.zip"

    if (-not (Download-File -Url $CommandBoxDownloadUrl -OutputPath $tempZip)) {
        return $null
    }

    # Extract CommandBox
    Write-Info "Extracting CommandBox to $InstallPath..."
    try {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::ExtractToDirectory($tempZip, $InstallPath, $true)
        Write-Success "CommandBox extracted successfully"
    } catch {
        Write-Error "Failed to extract CommandBox: $($_.Exception.Message)"
        return $null
    } finally {
        # Clean up temp file
        if (Test-Path $tempZip) {
            Remove-Item $tempZip -Force
        }
    }

    # Verify installation
    if (Test-Path $boxExePath) {
        Write-Success "CommandBox installed successfully"
        return $boxExePath
    } else {
        Write-Error "CommandBox installation verification failed"
        return $null
    }
}

# Add CommandBox to PATH
function Add-CommandBoxToPath {
    param([string]$BoxPath)

    if ($SkipPath) {
        Write-Info "Skipping PATH update (requested by user)"
        return
    }

    $installDir = Split-Path $BoxPath -Parent
    Write-Info "Adding CommandBox to PATH: $installDir"

    # Get current PATH
    if ($isAdmin) {
        $currentPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
        $target = "Machine"
    } else {
        $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
        $target = "User"
    }

    # Check if already in PATH
    $pathEntries = $currentPath -split ";" | ForEach-Object { $_.Trim() }
    if ($installDir -in $pathEntries) {
        Write-Success "CommandBox already in PATH"
        return
    }

    # Add to PATH
    try {
        $newPath = "$currentPath;$installDir"
        [Environment]::SetEnvironmentVariable("PATH", $newPath, $target)

        # Update current session PATH
        $env:PATH += ";$installDir"

        Write-Success "CommandBox added to PATH"
    } catch {
        Write-Error "Failed to add CommandBox to PATH: $($_.Exception.Message)"
        Write-Info "You may need to manually add '$installDir' to your PATH"
    }
}

# Install Wheels packages
function Install-WheelsPackages {
    param([string]$BoxPath)

    Write-Info "Installing Wheels packages..."

    try {
        # Check if packages are already installed
        $output = & $BoxPath list 2>&1
        $wheelsInstalled = $output -match $WheelsPackage
        $wheelsCliInstalled = $output -match $WheelsCliPackage

        if ($wheelsInstalled -and $wheelsCliInstalled -and -not $Force) {
            Write-Success "Both Wheels packages already installed"

            if (-not $Force) {
                $response = Read-Host "Reinstall Wheels packages? (y/N)"
                if ($response -notmatch "^[yY]") {
                    return $true
                }
            }
        }

        # Install core wheels package
        if (-not $wheelsInstalled -or $Force) {
            Write-Info "Installing $WheelsPackage from ForgeBox..."
            $installOutput = & $BoxPath install $WheelsPackage --force 2>&1

            if ($LASTEXITCODE -eq 0) {
                Write-Success "Core Wheels package installed successfully"
            } else {
                Write-Error "Failed to install core Wheels package"
                Write-Error $installOutput
                return $false
            }
        } else {
            Write-Success "Core Wheels package already installed"
        }

        # Install wheels-cli package
        if (-not $wheelsCliInstalled -or $Force) {
            Write-Info "Installing $WheelsCliPackage from ForgeBox..."
            $installOutput = & $BoxPath install $WheelsCliPackage --force 2>&1

            if ($LASTEXITCODE -eq 0) {
                Write-Success "Wheels CLI package installed successfully"
            } else {
                Write-Error "Failed to install Wheels CLI package"
                Write-Error $installOutput
                return $false
            }
        } else {
            Write-Success "Wheels CLI package already installed"
        }

        return $true
    } catch {
        Write-Error "Failed to install Wheels packages: $($_.Exception.Message)"
        return $false
    }
}

# Verify installation
function Test-Installation {
    param([string]$BoxPath)

    Write-Info "Verifying installation..."

    # Test CommandBox
    try {
        $boxVersion = & $BoxPath version 2>$null
        Write-Success "CommandBox: $boxVersion"
    } catch {
        Write-Error "CommandBox verification failed"
        return $false
    }

    # Test packages
    try {
        $output = & $BoxPath list 2>&1

        if ($output -match $WheelsPackage) {
            Write-Success "Core Wheels package: Available"
        } else {
            Write-Error "Core Wheels package verification failed"
            return $false
        }

        if ($output -match $WheelsCliPackage) {
            Write-Success "Wheels CLI package: Available"
        } else {
            Write-Error "Wheels CLI package verification failed"
            return $false
        }
    } catch {
        Write-Error "Package verification failed"
        return $false
    }

    # Test CLI functionality
    try {
        $wheelsOutput = & $BoxPath wheels version 2>&1
        if ($LASTEXITCODE -eq 0 -or $wheelsOutput -match "wheels") {
            Write-Success "Wheels CLI commands: Available"
        } else {
            Write-Warning "Wheels CLI commands may not be fully functional"
        }
    } catch {
        Write-Warning "Wheels CLI commands may not be fully functional"
    }

    return $true
}

# Main installation process
function Start-Installation {
    Write-Info "Starting Wheels installation process..."

    # Check Java
    if (-not (Test-JavaInstallation)) {
        Write-Warning "Java $MinimumJavaVersion+ is recommended for optimal performance"
        Write-Info "You can download Java from: $JavaCheckUrl"
        Write-Info "Continuing with installation (CommandBox includes embedded Java)..."
    }

    # Install CommandBox
    $boxPath = Install-CommandBox
    if (-not $boxPath) {
        Write-Error "CommandBox installation failed. Aborting."
        exit 1
    }

    # Add to PATH
    Add-CommandBoxToPath -BoxPath $boxPath

    # Install Wheels packages
    if (-not (Install-WheelsPackages -BoxPath $boxPath)) {
        Write-Error "Wheels packages installation failed. Aborting."
        exit 1
    }

    # Verify installation
    if (-not (Test-Installation -BoxPath $boxPath)) {
        Write-Error "Installation verification failed."
        exit 1
    }

    # Success message
    Write-Host ""
    Write-ColorOutput "╔════════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-ColorOutput "║                          Installation Completed Successfully!                  ║" -ForegroundColor Green
    Write-ColorOutput "║                                                                                ║" -ForegroundColor Green
    Write-ColorOutput "║  Next Steps:                                                                   ║" -ForegroundColor Green
    Write-ColorOutput "║  1. Open a new terminal/command prompt                                         ║" -ForegroundColor Green
    Write-ColorOutput "║  2. Create a new app: box wheels g app myapp                                   ║" -ForegroundColor Green
    Write-ColorOutput "║  3. Start developing: cd myapp && box server start                             ║" -ForegroundColor Green
    Write-ColorOutput "║                                                                                ║" -ForegroundColor Green
    Write-ColorOutput "║  Available commands:                                                           ║" -ForegroundColor Green
    Write-ColorOutput "║  • box wheels g app <name>     - Generate new Wheels app                      ║" -ForegroundColor Green
    Write-ColorOutput "║  • box wheels g model <name>   - Generate model                               ║" -ForegroundColor Green
    Write-ColorOutput "║  • box wheels g controller     - Generate controller                          ║" -ForegroundColor Green
    Write-ColorOutput "║  • box server start            - Start development server                     ║" -ForegroundColor Green
    Write-ColorOutput "║                                                                                ║" -ForegroundColor Green
    Write-ColorOutput "║  Documentation: https://wheels.dev/guides                                     ║" -ForegroundColor Green
    Write-ColorOutput "╚════════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""

    if (-not $SkipPath) {
        Write-Warning "Please restart your terminal or run 'refreshenv' to use the 'box' command"
    }
}

# Error handling
try {
    Start-Installation
} catch {
    Write-Error "Installation failed with error: $($_.Exception.Message)"
    Write-Error $_.ScriptStackTrace
    exit 1
}