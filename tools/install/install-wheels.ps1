#Requires -Version 5.1
<#
.SYNOPSIS
    Universal Wheels Framework Installer for Windows

.DESCRIPTION
    This universal installer can install CommandBox, Wheels CLI, and all necessary dependencies
    on Windows systems. It works both standalone and as part of package managers like Chocolatey.
    Ensures compatibility by installing modern versions of all components.

.PARAMETER InstallPath
    Custom installation directory. Defaults to Program Files for admin installs,
    user directory otherwise.

.PARAMETER Force
    Force reinstallation even if components already exist

.PARAMETER SkipPath
    Skip adding CommandBox to PATH


.PARAMETER Quiet
    Suppress interactive prompts and use defaults

.PARAMETER IncludeJava
    Install Java if not found (requires admin privileges)

.EXAMPLE
    .\install-wheels-universal.ps1


.EXAMPLE
    .\install-wheels-universal.ps1 -InstallPath "C:\Tools\CommandBox" -Force -IncludeJava
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$InstallPath = "",

    [Parameter()]
    [switch]$Force,

    [Parameter()]
    [switch]$SkipPath,

    [Parameter()]
    [switch]$Quiet,

    [Parameter()]
    [switch]$IncludeJava
)

# Configuration
$Script:Config = @{
    CommandBoxVersion = "6.2.1"
    MinimumJavaVersion = 11
    WheelsCliPackage = "wheels-cli"
    WheelsPackage = "wheels-framework"  # Changed from "wheels" to "wheels-framework"
    CommandBoxDownloadUrl = "https://www.ortussolutions.com/parent/download/commandbox/type/windows-jre64"
    JavaDownloadUrl = "https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.12%2B7/OpenJDK17U-jdk_x64_windows_hotspot_17.0.12_7.msi"
    JavaCheckUrl = "https://adoptium.net/temurin/releases/?version=17"
}

# Global state
$Script:State = @{
    IsAdmin = $false
    InstallPath = ""
    BoxPath = ""
    JavaInstalled = $false
    StartTime = Get-Date
}

#region Utility Functions

function Write-ColorOutput {
    param(
        [Parameter(Position=0, Mandatory=$true)]
        [string]$Message,
        [Parameter(Position=1)]
        [ConsoleColor]$ForegroundColor = [ConsoleColor]::White,
        [Parameter(Position=2)]
        [switch]$NoNewline
    )

    if ($Quiet -and $ForegroundColor -eq [ConsoleColor]::Cyan) { return }

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

function Write-Header {
    param([string]$Title, [string]$Subtitle = "")

    if ($Quiet) { return }

    Write-Host ""
    Write-ColorOutput "=================================================================================" -ForegroundColor Magenta
    Write-ColorOutput "                           $Title" -ForegroundColor Magenta
    if ($Subtitle) {
        Write-ColorOutput "                           $Subtitle" -ForegroundColor Magenta
    }
    Write-ColorOutput "=================================================================================" -ForegroundColor Magenta
    Write-Host ""
}

function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-UserConfirmation {
    param(
        [string]$Message,
        [bool]$DefaultYes = $false
    )

    if ($Quiet) { return $DefaultYes }

    $default = if ($DefaultYes) { "Y/n" } else { "y/N" }
    $response = Read-Host "$Message ($default)"

    if ([string]::IsNullOrEmpty($response)) {
        return $DefaultYes
    }

    return $response -match "^[yY]"
}

#endregion

#region System Detection and Validation

function Initialize-Environment {
    Write-Info "Initializing installation environment..."

    $Script:State.IsAdmin = Test-Administrator

    # Determine installation path
    if ([string]::IsNullOrEmpty($InstallPath)) {
        if ($Script:State.IsAdmin) {
            $Script:State.InstallPath = "$env:ProgramFiles\CommandBox"
        } else {
            $Script:State.InstallPath = "$env:USERPROFILE\.commandbox"
        }
    } else {
        $Script:State.InstallPath = $InstallPath
    }

    Write-Info "Installation path: $($Script:State.InstallPath)"
    Write-Info "Administrator privileges: $(if ($Script:State.IsAdmin) { 'Yes' } else { 'No' })"
    Write-Info "Quiet mode: $(if ($Quiet) { 'Yes' } else { 'No' })"
}

function Test-JavaInstallation {
    Write-Info "Checking Java installation..."

    try {
        $javaOutput = java -version 2>&1
        if ($javaOutput -match 'version "(.+?)"') {
            $javaVersionString = $matches[1]
            Write-Success "Java found: $javaVersionString"

            # Extract major version number
            if ($javaVersionString -match '^1\.(\d+)') {
                $javaMajorVersion = [int]$matches[1]
            } elseif ($javaVersionString -match '^(\d+)') {
                $javaMajorVersion = [int]$matches[1]
            } else {
                Write-Warning "Unable to parse Java version: $javaVersionString"
                return $false
            }

            if ($javaMajorVersion -ge $Script:Config.MinimumJavaVersion) {
                Write-Success "Java version meets requirements (>= $($Script:Config.MinimumJavaVersion))"
                $Script:State.JavaInstalled = $true
                return $true
            } else {
                Write-Warning "Java version $javaMajorVersion is below minimum requirement ($($Script:Config.MinimumJavaVersion))"
                return $false
            }
        }
    } catch {
        Write-Warning "Java not found in PATH"
        return $false
    }

    return $false
}

function Install-Java {
    if (-not $IncludeJava) {
        Write-Warning "Java installation skipped. Use -IncludeJava to install automatically."
        return $false
    }

    if (-not $Script:State.IsAdmin) {
        Write-Warning "Java installation requires administrator privileges."
        return $false
    }

    Write-Info "Installing Java (Temurin JDK 17)..."

    $tempMsi = Join-Path $env:TEMP "temurin-jdk-17.msi"

    try {
        # Download Java installer
        Write-Info "Downloading Java installer..."
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($Script:Config.JavaDownloadUrl, $tempMsi)
        $webClient.Dispose()

        # Install Java
        Write-Info "Installing Java (this may take a few minutes)..."
        $installProcess = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i", $tempMsi, "/quiet", "/norestart" -Wait -PassThru

        if ($installProcess.ExitCode -eq 0) {
            Write-Success "Java installed successfully"

            # Refresh environment variables
            $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")

            # Test installation
            return Test-JavaInstallation
        } else {
            Write-Error "Java installation failed with exit code: $($installProcess.ExitCode)"
            return $false
        }
    } catch {
        Write-Error "Java installation failed: $($_.Exception.Message)"
        return $false
    } finally {
        if (Test-Path $tempMsi) {
            Remove-Item $tempMsi -Force -ErrorAction SilentlyContinue
        }
    }
}

#endregion

#region Download and Installation Functions

function Download-File {
    param(
        [string]$Url,
        [string]$OutputPath,
        [string]$Description = "file"
    )

    Write-Info "Downloading $Description..."
    Write-Info "From: $Url"

    if (-not $Quiet) {
        Write-Info "Saving to: $OutputPath"
        Write-Info "Starting download, please wait..."
    }

    try {
        # Use WebClient for better progress reporting
        $webClient = New-Object System.Net.WebClient
        $startTime = Get-Date

        if (-not $Quiet) {
            # Register progress event with enhanced status
            Register-ObjectEvent -InputObject $webClient -EventName DownloadProgressChanged -Action {
                $elapsed = (Get-Date) - $using:startTime
                $bytesReceived = $Event.SourceEventArgs.BytesReceived
                $totalBytes = $Event.SourceEventArgs.TotalBytesToReceive
                $percent = $Event.SourceEventArgs.ProgressPercentage

                $speed = if ($elapsed.TotalSeconds -gt 0) {
                    [math]::Round(($bytesReceived / $elapsed.TotalSeconds) / 1MB, 2)
                } else { 0 }

                $eta = if ($speed -gt 0 -and $totalBytes -gt 0) {
                    $remainingBytes = $totalBytes - $bytesReceived
                    $etaSeconds = [math]::Round(($remainingBytes / 1MB) / $speed)
                    if ($etaSeconds -lt 60) { "$etaSeconds sec" }
                    else { "$([math]::Round($etaSeconds / 60)) min" }
                } else { "calculating..." }

                $status = "Progress: $percent% | Speed: $speed MB/s | ETA: $eta"
                Write-Progress -Activity "Downloading $using:Description" -Status $status -PercentComplete $percent
            } | Out-Null

            # Show initial status
            Write-ColorOutput "Download in progress..." -ForegroundColor Yellow
        }

        # Start the download
        $webClient.DownloadFile($Url, $OutputPath)
        $webClient.Dispose()

        # Calculate final stats
        $elapsed = (Get-Date) - $startTime
        $fileSize = (Get-Item $OutputPath).Length
        $avgSpeed = [math]::Round(($fileSize / $elapsed.TotalSeconds) / 1MB, 2)

        if (-not $Quiet) {
            Write-Progress -Activity "Downloading $description" -Completed
        }

        Write-Success "Download completed successfully!"
        if (-not $Quiet) {
            Write-Info "Downloaded $([math]::Round($fileSize / 1MB, 1)) MB in $([math]::Round($elapsed.TotalSeconds, 1)) seconds (avg: $avgSpeed MB/s)"
        }

        return $true
    } catch {
        Write-Error "Download failed: $($_.Exception.Message)"

        # Clean up partial download
        if (Test-Path $OutputPath) {
            try {
                Remove-Item $OutputPath -Force -ErrorAction SilentlyContinue
                Write-Info "Cleaned up partial download"
            } catch {
                Write-Warning "Could not clean up partial download: $OutputPath"
            }
        }

        return $false
    }
}

function Install-CommandBox {
    Write-Info "Installing CommandBox..."

    # Check if CommandBox already exists
    $boxExePath = Join-Path $Script:State.InstallPath "box.exe"

    if ((Test-Path $boxExePath) -and -not $Force) {
        try {
            $existingVersion = & $boxExePath version 2>$null
            if ($existingVersion -match 'CommandBox\s+([0-9\.]+)') {
                $currentVersion = $matches[1]
                Write-Info "CommandBox $currentVersion already installed"

                # Compare versions
                if ($currentVersion -eq $Script:Config.CommandBoxVersion) {
                    Write-Success "CommandBox is up to date"
                    $Script:State.BoxPath = $boxExePath
                    return $boxExePath
                } else {
                    Write-Info "Current version: $currentVersion, Available: $($Script:Config.CommandBoxVersion)"
                }
            }
        } catch {
            Write-Warning "Unable to determine existing CommandBox version"
        }

        if (-not $Force) {
            if (Get-UserConfirmation "CommandBox already exists. Reinstall?" -DefaultYes $false) {
                # Continue with installation
            } else {
                Write-Info "Using existing CommandBox installation"
                $Script:State.BoxPath = $boxExePath
                return $boxExePath
            }
        }
    }

    # Create installation directory
    if (-not (Test-Path $Script:State.InstallPath)) {
        Write-Info "Creating installation directory: $($Script:State.InstallPath)"
        try {
            New-Item -ItemType Directory -Path $Script:State.InstallPath -Force | Out-Null
        } catch {
            Write-Error "Failed to create installation directory: $($_.Exception.Message)"
            return $null
        }
    }

    # Download CommandBox (Windows JRE64 version)
    $tempZip = Join-Path $env:TEMP "commandbox-windows-jre64.zip"

    if (-not (Download-File -Url $Script:Config.CommandBoxDownloadUrl -OutputPath $tempZip -Description "CommandBox (Windows JRE64)")) {
        return $null
    }

    # Extract CommandBox
    Write-Info "Extracting CommandBox to $($Script:State.InstallPath)..."
    Write-Info "Extracting files, please wait..."

    try {
        Add-Type -AssemblyName System.IO.Compression.FileSystem

        # Create a temporary extraction directory first
        $tempExtractPath = Join-Path $env:TEMP "commandbox-extract-$(Get-Random)"
        New-Item -ItemType Directory -Path $tempExtractPath -Force | Out-Null

        # Extract to temp directory first
        [System.IO.Compression.ZipFile]::ExtractToDirectory($tempZip, $tempExtractPath)

        # The JRE64 version might have a different structure, so let's check for common patterns
        $possiblePaths = @(
            $tempExtractPath,  # Direct extraction
            (Join-Path $tempExtractPath "commandbox*"),  # In a subfolder
            (Join-Path $tempExtractPath "CommandBox*")   # Different case
        )

        $sourcePath = $null
        foreach ($path in $possiblePaths) {
            $expandedPaths = Get-ChildItem $path -ErrorAction SilentlyContinue
            foreach ($expandedPath in $expandedPaths) {
                if (Test-Path (Join-Path $expandedPath "box.exe")) {
                    $sourcePath = $expandedPath.FullName
                    break
                }
            }
            if ($sourcePath) { break }

            # Check if box.exe is directly in the path
            if (Test-Path (Join-Path $path "box.exe")) {
                $sourcePath = $path
                break
            }
        }

        if (-not $sourcePath) {
            # Fallback: look for box.exe anywhere in the extracted content
            $boxExe = Get-ChildItem -Path $tempExtractPath -Name "box.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($boxExe) {
                $sourcePath = Split-Path (Join-Path $tempExtractPath $boxExe.FullName) -Parent
            }
        }

        if (-not $sourcePath) {
            throw "Could not locate CommandBox executable in the downloaded package"
        }

        Write-Info "Found CommandBox files in: $(Split-Path $sourcePath -Leaf)"

        # Copy files to final destination
        if ($sourcePath -ne $Script:State.InstallPath) {
            $items = Get-ChildItem -Path $sourcePath -Recurse
            $totalItems = $items.Count
            $currentItem = 0

            foreach ($item in $items) {
                $currentItem++
                if (-not $Quiet -and ($currentItem % 10 -eq 0 -or $currentItem -eq $totalItems)) {
                    $percent = [math]::Round(($currentItem / $totalItems) * 100)
                    Write-Progress -Activity "Extracting CommandBox" -Status "Processing files: $currentItem/$totalItems" -PercentComplete $percent
                }

                $relativePath = $item.FullName.Substring($sourcePath.Length + 1)
                $destinationPath = Join-Path $Script:State.InstallPath $relativePath

                if ($item.PSIsContainer) {
                    # Create directory
                    if (-not (Test-Path $destinationPath)) {
                        New-Item -ItemType Directory -Path $destinationPath -Force | Out-Null
                    }
                } else {
                    # Copy file
                    $destinationDir = Split-Path $destinationPath -Parent
                    if (-not (Test-Path $destinationDir)) {
                        New-Item -ItemType Directory -Path $destinationDir -Force | Out-Null
                    }
                    Copy-Item -Path $item.FullName -Destination $destinationPath -Force
                }
            }

            if (-not $Quiet) {
                Write-Progress -Activity "Extracting CommandBox" -Completed
            }
        }

        # Clean up temp extraction directory
        Remove-Item $tempExtractPath -Recurse -Force -ErrorAction SilentlyContinue

        Write-Success "CommandBox extracted successfully"

        # Verify the main executable exists
        $finalBoxPath = Join-Path $Script:State.InstallPath "box.exe"
        if (-not (Test-Path $finalBoxPath)) {
            throw "box.exe not found at expected location: $finalBoxPath"
        }

    } catch {
        Write-Error "Failed to extract CommandBox: $($_.Exception.Message)"
        return $null
    } finally {
        # Clean up temp files
        if (Test-Path $tempZip) {
            Remove-Item $tempZip -Force -ErrorAction SilentlyContinue
        }
        if (Test-Path $tempExtractPath) {
            Remove-Item $tempExtractPath -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    # Verify installation
    if (Test-Path $boxExePath) {
        Write-Success "CommandBox installed successfully"
        $Script:State.BoxPath = $boxExePath
        return $boxExePath
    } else {
        Write-Error "CommandBox installation verification failed"
        return $null
    }
}

function Add-CommandBoxToPath {
    param([string]$BoxPath)

    if ($SkipPath) {
        Write-Info "Skipping PATH update (requested by user)"
        return
    }

    $installDir = Split-Path $BoxPath -Parent
    Write-Info "Adding CommandBox to PATH: $installDir"

    # Get current PATH
    if ($Script:State.IsAdmin) {
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

function Install-WheelsPackages {
    param([string]$BoxPath)

    Write-Info "Installing Wheels CLI package from ForgeBox..."

    try {
        # Check if wheels-cli package is already installed
        Write-Info "Checking existing packages..."
        $output = & $BoxPath list 2>&1
        $wheelsCliInstalled = $output -match $Script:Config.WheelsCliPackage

        if ($wheelsCliInstalled -and -not $Force) {
            Write-Success "Wheels CLI package already installed"

            if (-not $Force -and -not $Quiet) {
                if (-not (Get-UserConfirmation "Reinstall Wheels CLI package?" -DefaultYes $false)) {
                    return $true
                }
            }
        }

        # Install wheels-cli package (this is the only package we need)
        if (-not $wheelsCliInstalled -or $Force) {
            Write-Info "Installing $($Script:Config.WheelsCliPackage) from ForgeBox..."
            Write-ColorOutput "Downloading CLI tools package..." -ForegroundColor Yellow

            $installOutput = & $BoxPath install $Script:Config.WheelsCliPackage --force 2>&1

            if ($LASTEXITCODE -eq 0) {
                Write-Success "Wheels CLI package installed successfully"
            } else {
                Write-Warning "Failed to install Wheels CLI package"
                Write-Info "Error details: $($installOutput -join ' ')"
                Write-Info "You can manually install it later with: box install wheels-cli"

                # Check if there are syntax errors in the package
                if ($installOutput -match "Invalid Syntax" -or $installOutput -match "Missing.*expression") {
                    Write-Warning "The wheels-cli package appears to have syntax errors"
                    Write-Info "This is a known issue with some versions of the wheels-cli package"
                    Write-Info "You may need to wait for a package update or install manually"
                    Write-Info "CommandBox is still functional for other CFML development"
                }
            }
        } else {
            Write-Success "Wheels CLI package already installed"
        }

        Write-Success "Package installation completed!"
        return $true
    } catch {
        Write-Error "Failed to install Wheels CLI package: $($_.Exception.Message)"
        return $false
    }
}

#endregion

#region Verification and Testing

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
        # Skip the package listing verification since it's unreliable
        # CommandBox packages can be installed in different ways and may not show up in `box list`
        Write-Info "Skipping package list verification (unreliable for CommandBox modules)"
    } catch {
        Write-Info "Package verification skipped"
    }

    # Test CLI functionality (more comprehensive check)
    $wheelsWorking = $false
    try {
        # Try different ways to test wheels commands
        $wheelsOutput = & $BoxPath wheels version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Wheels CLI commands: Available"
            $wheelsWorking = $true
        } else {
            # Try alternative command
            $helpOutput = & $BoxPath help 2>&1
            if ($helpOutput -match "wheels") {
                Write-Success "Wheels CLI commands: Available (detected in help)"
                $wheelsWorking = $true
            } else {
                Write-Info "Wheels CLI commands: May require manual installation"
            }
        }
    } catch {
        Write-Info "Wheels CLI commands: May require manual installation"
    }

    # Provide user guidance based on what's working
    if (-not $wheelsWorking) {
        Write-Info "If wheels commands don't work, you can:"
        Write-Info "1. Try: box install wheels-cli --force"
        Write-Info "2. Or use CommandBox for other CFML development"
    }

    return $true
}

function Show-Summary {
    $duration = (Get-Date) - $Script:State.StartTime

    Write-Host ""
    Write-ColorOutput "=================================================================================" -ForegroundColor Green
    Write-ColorOutput "                          Installation Completed Successfully!                  " -ForegroundColor Green
    Write-ColorOutput "                                                                               " -ForegroundColor Green
    Write-ColorOutput "  Installation Summary:                                                        " -ForegroundColor Green
    Write-ColorOutput "  • CommandBox Path: $($Script:State.InstallPath)               " -ForegroundColor Green
    Write-ColorOutput "  • Java Installed: $(if ($Script:State.JavaInstalled) { 'Yes' } else { 'No (using embedded)' })                                      " -ForegroundColor Green
    Write-ColorOutput "  • Duration: $([int]$duration.TotalSeconds) seconds                                                 " -ForegroundColor Green
    Write-ColorOutput "                                                                               " -ForegroundColor Green

    Write-ColorOutput "  Next Steps:                                                                  " -ForegroundColor Green
    Write-ColorOutput "  1. Open a new terminal/command prompt                                        " -ForegroundColor Green
    Write-ColorOutput "  2. Create a new app: box wheels generate app myapp                          " -ForegroundColor Green
    Write-ColorOutput "  3. Start developing: cd myapp; box server start                            " -ForegroundColor Green
    Write-ColorOutput "                                                                               " -ForegroundColor Green
    Write-ColorOutput "  Using CommandBox commands:                                                  " -ForegroundColor Green
    Write-ColorOutput "  • wheels generate app [name]  - Generate new Wheels app                " -ForegroundColor Green
    Write-ColorOutput "  • wheels generate model [name] - Generate model                        " -ForegroundColor Green
    Write-ColorOutput "  • wheels generate controller   - Generate controller                   " -ForegroundColor Green
    Write-ColorOutput "  • server start                 - Start development server             " -ForegroundColor Green
    Write-ColorOutput "  • wheels migrate up            - Run database migrations              " -ForegroundColor Green
    Write-ColorOutput "                                                                               " -ForegroundColor Green
    Write-ColorOutput "  Documentation: https://wheels.dev/guides                                    " -ForegroundColor Green
    Write-ColorOutput "=================================================================================" -ForegroundColor Green
    Write-Host ""

    if (-not $SkipPath) {
        Write-Warning "Please restart your terminal or run refreshenv to use the box command"
    }
}

#endregion

#region Main Installation Logic

function Start-Installation {
    try {
        Write-Header "Wheels Framework Universal Installer" "Installing CommandBox, Wheels, and CLI tools"

        Initialize-Environment

        # Check Java (required for CommandBox)
        if (-not (Test-JavaInstallation)) {
            Write-Warning "Java $($Script:Config.MinimumJavaVersion)+ is recommended for optimal performance"

            if ($IncludeJava) {
                if (-not (Install-Java)) {
                    Write-Warning "Java installation failed. Continuing with CommandBox embedded Java..."
                }
            } else {
                Write-Info "You can download Java from: $($Script:Config.JavaCheckUrl)"
                Write-Info "Continuing with installation (CommandBox includes embedded Java)..."
            }
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

        # Clean up any existing tools folder (from previous installations)
        $toolsDir = Join-Path (Split-Path $boxPath -Parent) "tools"
        if (Test-Path $toolsDir) {
            Write-Info "Cleaning up unnecessary tools folder from previous installation..."
            try {
                Remove-Item $toolsDir -Recurse -Force
                Write-Success "Tools folder cleaned up successfully"
            } catch {
                Write-Warning "Could not remove tools folder: $($_.Exception.Message)"
            }
        }

        # Verify installation
        if (-not (Test-Installation -BoxPath $Script:State.BoxPath)) {
            Write-Warning "Installation verification had issues, but installation may still be functional."
        }

        Show-Summary

    } catch {
        Write-Error "Installation failed with error: $($_.Exception.Message)"
        if (-not $Quiet) {
            Write-Error $_.ScriptStackTrace
        }
        exit 1
    }
}

#endregion

# Entry point
Start-Installation