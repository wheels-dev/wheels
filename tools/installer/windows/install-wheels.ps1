#Requires -Version 5.1
<#
.SYNOPSIS
    Wheels Installer

.DESCRIPTION
    Installs CommandBox, Java, and Wheels CLI with interactive prompts if parameters are not provided.
    Ensures compatibility by installing modern versions of all components.

.PARAMETER InstallPath
    Custom installation directory. Defaults to Program Files for admin installs, user directory otherwise.

.PARAMETER Force
    Force reinstallation even if components already exist.

.PARAMETER SkipPath
    Skip adding CommandBox to PATH.

.PARAMETER AppName
    Name for the Wheels application.

.PARAMETER Template
    Wheels template to use.

.PARAMETER ReloadPassword
    Reload password for the application.

.PARAMETER DatasourceName
    Datasource name for the database.

.PARAMETER CFMLEngine
    CFML engine to use.

.PARAMETER UseH2
    Use H2 database for Lucee.

.PARAMETER UseBootstrap
    Setup Bootstrap CSS framework.

.PARAMETER InitializeAsPackage
    Initialize application as a package.

.PARAMETER ApplicationBasePath
    Base path for the application installation.

.PARAMETER IncludeJava
    Install Java if not found (requires admin privileges).
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
    [string]$AppName = "MyWheelsApp",

    [Parameter()]
    [string]$Template = "wheels-base-template@^3.0.0",

    [Parameter()]
    [string]$ReloadPassword = "changeMe",

    [Parameter()]
    [string]$DatasourceName = "",

    [Parameter()]
    [string]$CFMLEngine = "lucee",

    [Parameter()]
    [switch]$UseH2,

    [Parameter()]
    [switch]$UseBootstrap,

    [Parameter()]
    [switch]$InitializeAsPackage,

    [Parameter()]
    [string]$ApplicationBasePath = "",

    [Parameter()]
    [switch]$IncludeJava
)

# =============================
# Standard small console setup
# =============================
try {
    $Host.UI.RawUI.WindowSize = New-Object System.Management.Automation.Host.Size (120, 35)
    $Host.UI.RawUI.BufferSize = New-Object System.Management.Automation.Host.Size (120, 1000)
} catch {
    # Console resizing failed - continue without resizing
    # This is common in some terminal emulators or restricted environments
}

# =============================
# Global error handling trap
# =============================
trap {
    # Handle unexpected script termination (window close, etc.)
    if ($Script:State -and -not $Script:State.StatusWritten) {
        try {
            $statusFile = Join-Path $env:TEMP "wheels-install-status.txt"
            if (Test-Path $statusFile) {
                Remove-Item $statusFile -Force -ErrorAction SilentlyContinue
            }
            "-1" | Out-File -FilePath $statusFile -Encoding ASCII -Force
        } catch {
            # Silent fail
        }
    }
    continue
}


# Configuration
$Script:Config = @{
    CommandBoxVersion = "6.2.1"
    MinimumJavaVersion = 17
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
    AppConfig = @{}
    TempFiles = @()
    LogFile = ""
    InstallationSucceeded = $false
    StatusWritten = $false
}

#region Logging Functions

function Initialize-Logging {
    # Use a persistent log file name (no timestamp) so it continues across runs
    $Script:State.LogFile = Join-Path $env:TEMP "wheels-installation.log"

    try {
        # Check if log file exists and append to it, or create new one
        $isNewLog = -not (Test-Path $Script:State.LogFile)

        if ($isNewLog) {
            Write-Info "Creating new log file: $($Script:State.LogFile)"
            # Create new log file with header
            $logHeader = @"
================================================================================
Wheels Installer Log
================================================================================
Log Created: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
================================================================================

"@
            $logHeader | Out-File -FilePath $Script:State.LogFile -Encoding UTF8
        } else {
            Write-Info "Continuing existing log file: $($Script:State.LogFile)"
            # Append new session marker to existing log
            $sessionHeader = @"


================================================================================
NEW INSTALLATION SESSION
================================================================================
Session Start: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Working Directory: $($PWD.Path)
Parameters:
  InstallPath: $InstallPath
  Force: $Force
  SkipPath: $SkipPath
  AppName: $AppName
  Template: $Template
  CFMLEngine: $CFMLEngine
  UseH2: $UseH2
  UseBootstrap: $UseBootstrap
  InitializeAsPackage: $InitializeAsPackage
  ApplicationBasePath: $ApplicationBasePath
================================================================================

"@
            $sessionHeader | Out-File -FilePath $Script:State.LogFile -Append -Encoding UTF8
        }

        Write-Info "Log file initialized: $($Script:State.LogFile)"
    } catch {
        Write-Warning "Could not initialize log file: $($_.Exception.Message)"
        $Script:State.LogFile = ""
    }
}

function Write-Log {
    param(
        [Parameter(Mandatory=$true)]
        [AllowEmptyString()]
        [string]$Message,
        [string]$Level = "INFO"
    )

    if (-not $Script:State.LogFile) { return }

    try {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
        if ($Message -eq "") {
            $logEntry = ""
        } else {
            $logEntry = "[$timestamp] [$Level] $Message"
        }
        $logEntry | Out-File -FilePath $Script:State.LogFile -Append -Encoding UTF8
    } catch {
        # Silently fail if logging doesn't work
    }
}

function Write-LogSection {
    param([string]$SectionName)

    $separator = "=" * 80
    Write-Log "" "INFO"
    Write-Log $separator "INFO"
    Write-Log "SECTION: $SectionName" "INFO"
    Write-Log $separator "INFO"
}

function Write-LogError {
    param(
        [string]$Message,
        [System.Management.Automation.ErrorRecord]$ErrorRecord = $null
    )

    Write-Log $Message "ERROR"
    if ($ErrorRecord) {
        Write-Log "Exception Type: $($ErrorRecord.Exception.GetType().FullName)" "ERROR"
        Write-Log "Exception Message: $($ErrorRecord.Exception.Message)" "ERROR"
        Write-Log "Script Stack Trace: $($ErrorRecord.ScriptStackTrace)" "ERROR"
        Write-Log "Category Info: $($ErrorRecord.CategoryInfo.ToString())" "ERROR"
        Write-Log "Fully Qualified Error ID: $($ErrorRecord.FullyQualifiedErrorId)" "ERROR"
    }
}

function Show-LogLocation {
    if ($Script:State.LogFile -and (Test-Path $Script:State.LogFile)) {
        Write-Host ""
        Write-ColorOutput "Installation log saved to:" -ForegroundColor Yellow
        Write-ColorOutput $Script:State.LogFile -ForegroundColor Green
        Write-Host ""

        # Show last few lines of the log for immediate feedback
        try {
            $lastLines = Get-Content $Script:State.LogFile -Tail 10
            Write-ColorOutput "Last 10 log entries:" -ForegroundColor Yellow
            foreach ($line in $lastLines) {
                Write-Host $line -ForegroundColor Gray
            }
        } catch {
            Write-Warning "Could not read log file tail"
        }
    }
}

#endregion

#region Utility Functions

function Write-InstallationStatus {
    param([int]$ExitCode)

    # Guard against multiple status writes
    if ($Script:State.StatusWritten) {
        Write-Log "Status already written, skipping duplicate write" "INFO"
        return
    }

    try {
        # Delete any existing status file first to prevent stale data
        $statusFile = Join-Path $env:TEMP "wheels-install-status.txt"
        if (Test-Path $statusFile) {
            Remove-Item $statusFile -Force -ErrorAction SilentlyContinue
            Write-Log "Removed existing status file" "INFO"
        }

        # Create status info with log file path
        $statusInfo = if ($Script:State.LogFile) {
            @"
$ExitCode
$($Script:State.LogFile)
"@
        } else {
            "$ExitCode"
        }

        # Write atomically to single file
        $statusInfo | Out-File -FilePath $statusFile -Encoding ASCII -Force

        Write-Log "Installation status written to: $statusFile (Exit Code: $ExitCode)" "INFO"

        # Also write final status to log file
        Write-Log "=== FINAL INSTALLATION STATUS ===" "STATUS"
        $statusMessage = switch ($ExitCode) {
            0 { "SUCCESS - Installation completed successfully" }
            1 { "ERROR - Installation failed due to an error" }
            2 { "CANCELLED - Installation was cancelled by user" }
            3 { "ERROR - Installation failed due to unexpected error" }
            default { "UNKNOWN - Installation completed with unknown status ($ExitCode)" }
        }
        Write-Log $statusMessage "STATUS"
        Write-Log "=== END INSTALLATION STATUS ===" "STATUS"

        # Mark status as written
        $Script:State.StatusWritten = $true
    } catch {
        Write-Log "Failed to write installation status file: $($_.Exception.Message)" "WARNING"
    }
}

function Stop-WithCriticalError {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ErrorMessage,
        [string]$Details = "",
        [int]$ExitCode = 1
    )

    Write-LogError "CRITICAL ERROR: $ErrorMessage"
    if ($Details) {
        Write-Log "Error Details: $Details" "ERROR"
    }

    # Write status for installer
    Write-InstallationStatus -ExitCode $ExitCode

    Write-Host ""
    Write-ColorOutput "=================================================================================" -ForegroundColor Red
    Write-ColorOutput "                              CRITICAL ERROR                                    " -ForegroundColor Red
    Write-ColorOutput "=================================================================================" -ForegroundColor Red
    Write-Host ""

    Write-Error $ErrorMessage

    if ($Details) {
        Write-Host ""
        Write-ColorOutput "Error Details:" -ForegroundColor Yellow
        Write-Host $Details -ForegroundColor Gray
    }

    Write-Host ""
    Write-ColorOutput "The installation cannot continue. Please resolve the error and try again." -ForegroundColor Yellow
    Write-Host ""

    # Show log location before exiting
    Show-LogLocation

    Write-ColorOutput "Press any key to exit..." -ForegroundColor Cyan
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

    Cleanup-TempFiles
    Write-Log "Installation terminated with critical error. Exit code: $ExitCode" "ERROR"
    exit $ExitCode
}

function Add-TempFile {
    param([string]$FilePath)
    if ($FilePath -and -not ($Script:State.TempFiles -contains $FilePath)) {
        $Script:State.TempFiles += $FilePath
    }
}


function Cleanup-TempFiles {
    Write-Info "Cleaning up temporary files..."

    foreach ($tempFile in $Script:State.TempFiles) {
        if ($tempFile -and (Test-Path $tempFile)) {
            try {
                Remove-Item $tempFile -Force -Recurse -ErrorAction SilentlyContinue
                Write-Info "Removed: $tempFile"
            } catch {
                Write-Warning "Could not remove temporary file: $tempFile"
            }
        }
    }

    $Script:State.TempFiles = @()
}


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

function Write-Info {
    param([string]$Message)
    Write-ColorOutput "INFO: $Message" -ForegroundColor Cyan
    Write-Log $Message "INFO"
}
function Write-Success {
    param([string]$Message)
    Write-ColorOutput "SUCCESS: $Message" -ForegroundColor Green
    Write-Log $Message "SUCCESS"
}
function Write-Warning {
    param([string]$Message)
    Write-ColorOutput "WARNING: $Message" -ForegroundColor Yellow
    Write-Log $Message "WARNING"
}
function Write-Error {
    param([string]$Message)
    Write-ColorOutput "ERROR: $Message" -ForegroundColor Red
    Write-Log $Message "ERROR"
}

function Write-Header {
    param([string]$Title, [string]$Subtitle = "")

    $width = 81   # match the border length
    Write-Host ""
    Write-ColorOutput ("=" * $width) -ForegroundColor Magenta

    # Center Title
    $titleLine = $Title.PadLeft(([math]::Floor(($width + $Title.Length) / 2)), " ")
    Write-ColorOutput $titleLine -ForegroundColor Magenta

    # Center Subtitle (if provided)
    if ($Subtitle) {
        $subtitleLine = $Subtitle.PadLeft(([math]::Floor(($width + $Subtitle.Length) / 2)), " ")
        Write-ColorOutput $subtitleLine -ForegroundColor Magenta
    }

    Write-ColorOutput ("=" * $width) -ForegroundColor Magenta
    Write-Host ""
}

function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}


#endregion

#region System Configuration and User Settings

# --- Configuration using passed parameters ---
Write-Header "Wheels Installer" "Configuring installation and application setup"

# Set default InstallPath if not provided
if (-not $InstallPath) {
    $defaultPath = if ([Security.Principal.WindowsIdentity]::GetCurrent().Groups -match "S-1-5-32-544") {
        # Admin install → Program Files
        "$env:ProgramFiles\CommandBox"
    } else {
        # User install → Local profile
        "$env:USERPROFILE\CommandBox"
    }
    $InstallPath = $defaultPath
}

# Normalize CommandBox path
if ($InstallPath -notmatch "CommandBox$") {
    $InstallPath = Join-Path $InstallPath "CommandBox"
}

# Set default DatasourceName if not provided
if (-not $DatasourceName) {
    $DatasourceName = $AppName
}

# Set default ApplicationBasePath if not provided
if (-not $ApplicationBasePath) {
    $baseDir = Split-Path $InstallPath -Parent
    $ApplicationBasePath = Join-Path $baseDir "inetpub"
}

# Initialize AppConfig in State with passed parameters
$Script:State.AppConfig = @{
    ApplicationName = $AppName
    Template = $Template
    ReloadPassword = $ReloadPassword
    DatasourceName = $DatasourceName
    CFMLEngine = $CFMLEngine
    UseH2Database = $UseH2
    UseBootstrap = $UseBootstrap
    InitializeAsPackage = $InitializeAsPackage
}

# Validate and create CommandBox installation directory
if (-not (Test-Path $InstallPath)) {
    try {
        New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
        Write-Success "Created CommandBox installation directory: $InstallPath"
    } catch {
        Stop-WithCriticalError "Failed to create CommandBox installation directory" "Path: $InstallPath`nError: $($_.Exception.Message)`n`nThis could be due to insufficient permissions or invalid path."
    }
} else {
    Write-Success "CommandBox installation directory verified: $InstallPath"
}

# Validate and create application path
if (-not (Test-Path $ApplicationBasePath)) {
    try {
        New-Item -ItemType Directory -Path $ApplicationBasePath -Force | Out-Null
        Write-Success "Created application directory: $ApplicationBasePath"
    } catch {
        Stop-WithCriticalError "Failed to create application directory" "Path: $ApplicationBasePath`nError: $($_.Exception.Message)`n`nThis could be due to insufficient permissions or invalid path."
    }
} else {
    Write-Success "Application directory verified: $ApplicationBasePath"
}
$Script:State.AppConfig.ApplicationPath = Join-Path $ApplicationBasePath $AppName
Write-Success "Application base path: $ApplicationBasePath"
Write-Success "Full application path: $($Script:State.AppConfig.ApplicationPath)"

$bootstrapStatus  = if ($UseBootstrap) { 'true' } else { 'false' }
$h2Status         = if ($UseH2) { 'true' } else { 'false' }
$packageStatus    = if ($InitializeAsPackage) { 'true' } else { 'false' }

# Configuration Summary
Write-Host ""
Write-ColorOutput "+-----------------------------------------------------------------------------------+" -ForegroundColor Green
Write-ColorOutput "| Configuration Summary:                                                            |" -ForegroundColor Green
Write-ColorOutput "+-----------------------+-----------------------------------------------------------+" -ForegroundColor Green
Write-ColorOutput "| CommandBox Path       | $($InstallPath.PadRight(57)) |" -ForegroundColor Green
Write-ColorOutput "| Template              | $($Template.PadRight(57)) |" -ForegroundColor Green
Write-ColorOutput "| Application Name      | $($AppName.PadRight(57)) |" -ForegroundColor Green
Write-ColorOutput "| Application Directory | $($Script:State.AppConfig.ApplicationPath.PadRight(57)) |" -ForegroundColor Green
Write-ColorOutput "| Reload Password       | $($ReloadPassword.PadRight(57)) |" -ForegroundColor Green
Write-ColorOutput "| Datasource Name       | $($DatasourceName.PadRight(57)) |" -ForegroundColor Green
Write-ColorOutput "| CF Engine             | $($CFMLEngine.PadRight(57)) |" -ForegroundColor Green
Write-ColorOutput "| Setup Bootstrap       | $($bootstrapStatus.PadRight(57)) |" -ForegroundColor Green
Write-ColorOutput "| Setup H2 Database     | $($h2Status.PadRight(57)) |" -ForegroundColor Green
Write-ColorOutput "| Initialize box.json   | $($packageStatus.PadRight(57)) |" -ForegroundColor Green
Write-ColorOutput "| Force Installation    | $($Force.ToString().ToLower().PadRight(57)) |" -ForegroundColor Green
Write-ColorOutput "| Skip add to PATH      | $($SkipPath.ToString().ToLower().PadRight(57)) |" -ForegroundColor Green
Write-ColorOutput "+-----------------------+-----------------------------------------------------------+" -ForegroundColor Green
Write-Host ""

Write-Success "Configuration set! Starting installation and application setup..."
Write-Host ""

#endregion

#region System Detection and Validation

function Initialize-Environment {
    Write-LogSection "ENVIRONMENT INITIALIZATION"
    Write-Info "Initializing installation environment..."

    $Script:State.IsAdmin = Test-Administrator

    # Set Installation path (already configured in the user prompts section)
    $Script:State.InstallPath = $InstallPath

    Write-Info "Installation path: $($Script:State.InstallPath)"
    Write-Info "Administrator privileges: $(if ($Script:State.IsAdmin) { 'Yes' } else { 'No' })"
}

function Test-JavaInstallation {
    Write-LogSection "JAVA DETECTION"
    Write-Info "Checking Java installation..."

    try {
        $javaOutput = & java -version *>&1
        $javaLine = $javaOutput | Select-Object -First 1
        if ($javaLine -match 'version "(.+?)"') {
            $javaVersionString = $matches[1]
            Write-Success "Java found: $javaVersionString"

            # Extract major version number
            if ($javaVersionString -match '^1\.(\d+)') {
                $javaMajorVersion = [int]$matches[1]
            } elseif ($javaVersionString -match '^(\d+)') {
                $javaMajorVersion = [int]$matches[1]
            } else {
                Write-Warning "Unable to parse Java version: $javaVersionString"
                Write-Info "Will install Java $($Script:Config.MinimumJavaVersion) to ensure compatibility"
                return $false
            }

            if ($javaMajorVersion -ge $Script:Config.MinimumJavaVersion) {
                Write-Success "Java version meets requirements (>= $($Script:Config.MinimumJavaVersion))"
                $Script:State.JavaInstalled = $true
                return $true
            } else {
                Write-Warning "Java version $javaMajorVersion is below minimum requirement ($($Script:Config.MinimumJavaVersion))"
                Write-Info "Will upgrade to Java $($Script:Config.MinimumJavaVersion) for optimal performance"
                return $false
            }
        }
    } catch {
        Write-Info "Java not found in PATH"
        Write-Info "Will install Java $($Script:Config.MinimumJavaVersion) for optimal performance"
        return $false
    }

    return $false
}

function Install-Java {
    Write-Info "Installing Java (Temurin JDK $($Script:Config.MinimumJavaVersion)) for optimal performance..."

    if (-not $Script:State.IsAdmin) {
        Write-Warning "Administrator privileges required for Java installation."
        Write-Info "Continuing with CommandBox embedded Java (performance may be reduced)."
        return $false
    }

    $tempMsi = Join-Path $env:TEMP "temurin-jdk-$($Script:Config.MinimumJavaVersion).msi"
    Add-TempFile -FilePath $tempMsi

    try {
        # Download Java installer
        Write-Info "Downloading Java installer (this may take a few minutes)..."
        if (-not (Download-File -Url $Script:Config.JavaDownloadUrl -OutputPath $tempMsi -Description "Java JDK $($Script:Config.MinimumJavaVersion)")) {
            Write-Warning "Java download failed. Continuing with CommandBox embedded Java."
            return $false
        }

        # Install Java silently
        Write-Info "Installing Java (this may take several minutes)..."
        $installProcess = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i", $tempMsi, "/quiet", "/norestart" -Wait -PassThru

        if ($installProcess.ExitCode -eq 0) {
            Write-Success "Java $($Script:Config.MinimumJavaVersion) installed successfully"

            # Refresh environment variables
            $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")

            # Test installation
            Start-Sleep -Seconds 2  # Give system time to update
            return Test-JavaInstallation
        } else {
            Write-Warning "Java installation completed with exit code: $($installProcess.ExitCode)"
            Write-Info "Continuing with CommandBox embedded Java."
            return $false
        }
    } catch {
        Write-Warning "Java installation failed: $($_.Exception.Message)"
        Write-Info "Continuing with CommandBox embedded Java (performance may be reduced)."
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
    Write-Info "Saving to: $OutputPath"
    Write-Info "Starting download, please wait..."

    # Track this temporary file for cleanup
    Add-TempFile -FilePath $OutputPath

    try {
        # Use WebClient for better progress reporting
        $webClient = New-Object System.Net.WebClient
        $startTime = Get-Date

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

        # Start the download
        $webClient.DownloadFile($Url, $OutputPath)
        $webClient.Dispose()

        # Calculate final stats
        $elapsed = (Get-Date) - $startTime
        $fileSize = (Get-Item $OutputPath).Length
        $avgSpeed = [math]::Round(($fileSize / $elapsed.TotalSeconds) / 1MB, 2)

        Write-Progress -Activity "Downloading $description" -Completed

        Write-Success "Download completed successfully!"
        Write-Info "Downloaded $([math]::Round($fileSize / 1MB, 1)) MB in $([math]::Round($elapsed.TotalSeconds, 1)) seconds (avg: $avgSpeed MB/s)"

        return $true
    } catch {
        # Clean up partial download
        if (Test-Path $OutputPath) {
            try {
                Remove-Item $OutputPath -Force -ErrorAction SilentlyContinue
                Write-Info "Cleaned up partial download"
            } catch {
                Write-Warning "Could not clean up partial download: $OutputPath"
            }
        }

        Stop-WithCriticalError "Download failed: $Description" "URL: $Url`nDestination: $OutputPath`nError: $($_.Exception.Message)`n`nThis could be due to network connectivity issues or invalid download URL."
    }
}

function Install-CommandBox {
    Write-LogSection "COMMANDBOX INSTALLATION"
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
            Write-Info "Using existing CommandBox installation"
            $Script:State.BoxPath = $boxExePath
            return $boxExePath
        }
    }

    # Create installation directory
    if (-not (Test-Path $Script:State.InstallPath)) {
        Write-Info "Creating installation directory: $($Script:State.InstallPath)"
        try {
            New-Item -ItemType Directory -Path $Script:State.InstallPath -Force | Out-Null
        } catch {
            Stop-WithCriticalError "Failed to create CommandBox installation directory during setup" "Path: $($Script:State.InstallPath)`nError: $($_.Exception.Message)`n`nThis could be due to insufficient permissions."
        }
    }

    # Download CommandBox (Windows JRE64 version)
    $tempZip = Join-Path $env:TEMP "commandbox-windows-jre64.zip"
    Add-TempFile -FilePath $tempZip

    if (-not (Download-File -Url $Script:Config.CommandBoxDownloadUrl -OutputPath $tempZip -Description "CommandBox (Windows JRE64)")) {
        # Download-File now handles critical errors, so this line should not be reached
        Stop-WithCriticalError "CommandBox download failed" "Unable to download CommandBox from ForgeBox. Please check your internet connection."
    }

    # Extract CommandBox
    Write-Info "Extracting CommandBox to $($Script:State.InstallPath)..."
    Write-Info "Extracting files, please wait..."

    try {
        Add-Type -AssemblyName System.IO.Compression.FileSystem

        # Create a temporary extraction directory first
        $tempExtractPath = Join-Path $env:TEMP "commandbox-extract-$(Get-Random)"
        Add-TempFile -FilePath $tempExtractPath
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
            Stop-WithCriticalError "CommandBox executable not found in downloaded package" "The downloaded CommandBox package does not contain the expected box.exe file.`nThis could be due to a corrupted download or changes in the CommandBox distribution format."
        }

        Write-Info "Found CommandBox files in: $(Split-Path $sourcePath -Leaf)"

        # Copy files to final destination
        if ($sourcePath -ne $Script:State.InstallPath) {
            $items = Get-ChildItem -Path $sourcePath -Recurse
            $totalItems = $items.Count
            $currentItem = 0

            foreach ($item in $items) {
                $currentItem++
                if ($currentItem % 10 -eq 0 -or $currentItem -eq $totalItems) {
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

            Write-Progress -Activity "Extracting CommandBox" -Completed
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
        Stop-WithCriticalError "Failed to extract CommandBox" "Error: $($_.Exception.Message)`n`nThis could be due to a corrupted download or insufficient disk space."
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
        Stop-WithCriticalError "CommandBox installation verification failed" "The CommandBox executable was not found at the expected location: $boxExePath`nThe installation may have been incomplete or corrupted."
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
        $output = & $BoxPath list 2>&1
        $wheelsCliInstalled = $output -match $Script:Config.WheelsCliPackage

        if ($wheelsCliInstalled) {
            if (-not $Force) {
                Write-Success "Wheels CLI package already installed (skipping re-install)"
                return $true
            }
            Write-Info "Force flag detected, re-installing Wheels CLI package..."
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
        Stop-WithCriticalError "Failed to install Wheels CLI package" "Error: $($_.Exception.Message)`n`nThis could be due to network connectivity issues or ForgeBox being unavailable.`nCommandBox is installed but Wheels CLI tools are not available."
    }
}

#endregion

#region Wheels Application Creation

function Create-WheelsApplication {
    param([string]$BoxPath)

    Write-LogSection "WHEELS APPLICATION CREATION"

    Write-Host ""
    Write-ColorOutput "=================================================================================" -ForegroundColor Blue
    Write-ColorOutput "                          Creating Wheels Application                           " -ForegroundColor Blue
    Write-ColorOutput "=================================================================================" -ForegroundColor Blue
    Write-Host ""

    $appName = $Script:State.AppConfig.ApplicationName
    $appPath = $Script:State.AppConfig.ApplicationPath
    $template = $Script:State.AppConfig.Template

    Write-Info "Checking if server already exists for: $appName"

    try {
        # Get list of all servers
        $serversJson = & $BoxPath server list --json 2>$null
        if ($serversJson) {
            $servers = $serversJson | ConvertFrom-Json

            # Check if server with this name already exists
            $existing = $servers | Where-Object { $_.name -eq $appName }

            if ($existing) {
                $serverDetails = "Name: $($existing.name)"
                if ($existing.weburl) {
                    $serverDetails += "`nURL: $($existing.weburl)"
                } elseif ($existing.host -and $existing.port) {
                    $serverDetails += "`nURL: http://$($existing.host):$($existing.port)"
                }
                if ($existing.webroot) {
                    $serverDetails += "`nWebroot: $($existing.webroot)"
                }

                Stop-WithCriticalError "A CommandBox server already exists with this name" "$serverDetails`n`nThis could cause conflicts during application creation.`nPlease choose a different application name or remove the existing server first using 'box server stop $appName' and 'box server forget $appName'."
            }
        }
    } catch {
        Stop-WithCriticalError "Failed to check existing servers" "Application Name: $appName`nError: $($_.Exception.Message)`n`nThis could be due to CommandBox not being properly installed or network connectivity issues preventing server list retrieval."
    }

    Write-Info "Creating Wheels application: $appName"
    Write-Info "Location: $appPath"
    Write-Info "Template: $template"

    try {
        # Change to the parent directory where the app will be created
        $appParentDir = Split-Path $appPath -Parent
        Push-Location $appParentDir

        # Build the wheels generate app command
        $generateCmd = @("wheels", "generate", "app", "name=$appName", "template=$template", "force=true")

        # Add additional parameters
        if ($Script:State.AppConfig.ReloadPassword -ne "") {
            $generateCmd += "reloadPassword=$($Script:State.AppConfig.ReloadPassword)"
        }

        if ($Script:State.AppConfig.DatasourceName -ne $appName) {
            $generateCmd += "datasourceName=$($Script:State.AppConfig.DatasourceName)"
        }

        if ($Script:State.AppConfig.CFMLEngine -ne "lucee") {
            $generateCmd += "cfmlEngine=$($Script:State.AppConfig.CFMLEngine)"
        }

        if ($Script:State.AppConfig.UseH2Database) {
            $generateCmd += "setupH2=true"
        }

        if ($Script:State.AppConfig.UseBootstrap) {
            $generateCmd += "useBootstrap=true"
        }

        if ($Script:State.AppConfig.InitializeAsPackage) {
            $generateCmd += "initPackage=true"
        }

        Write-Info "Executing: box $($generateCmd -join ' ')"
        Write-ColorOutput "Creating application, please wait..." -ForegroundColor Yellow

        # Execute the command
        $output = & $BoxPath $generateCmd 2>&1
        # # Execute the command
        # # Start CommandBox process and stream its output in real-time
        # $psi = New-Object System.Diagnostics.ProcessStartInfo
        # $psi.FileName = $BoxPath
        # $psi.Arguments = $generateCmd -join " "
        # $psi.RedirectStandardOutput = $true
        # $psi.RedirectStandardError = $true
        # $psi.UseShellExecute = $false
        # $psi.CreateNoWindow = $true

        # $process = New-Object System.Diagnostics.Process
        # $process.StartInfo = $psi

        # # Register event handlers to print output asynchronously
        # $process.add_OutputDataReceived({
        #     if ($_.Data) { Write-Host $_.Data }
        # })
        # $process.add_ErrorDataReceived({
        #     if ($_.Data) { Write-Host $_.Data -ForegroundColor Red }
        # })

        # $process.Start() | Out-Null
        # $process.BeginOutputReadLine()
        # $process.BeginErrorReadLine()

        # $process.WaitForExit()
        # $LASTEXITCODE = $process.ExitCode

        if ($LASTEXITCODE -eq 0) {
            Write-Success "Wheels application created successfully!"
        } else {
            Write-Warning "Application creation may have completed with warnings."
            Write-Info "Output: $($output -join ' ')"
        }

    } catch {
        Stop-WithCriticalError "Failed to create Wheels application" "Application Name: $appName`nApplication Path: $appPath`nTemplate: $template`nError: $($_.Exception.Message)`n`nThis could be due to insufficient permissions, invalid template, or CommandBox configuration issues."
    } finally {
        Pop-Location
    }

    # Verify the application was created
    if (Test-Path $appPath) {
        Write-Success "Application directory verified: $appPath"
        return $true
    } else {
        Stop-WithCriticalError "Application directory not found after creation" "Expected Path: $appPath`n`nThe Wheels application generation appeared to complete but the application directory was not created.`nThis could indicate a problem with the template or CommandBox configuration."
    }
}

function Get-WheelsServerStatus {
    param([string]$BoxPath)

    Push-Location $Script:State.AppConfig.ApplicationPath
    try {
        $statusJson = & $BoxPath server status --json 2>$null
        if ($statusJson) {
            $status = $statusJson | ConvertFrom-Json
            if ($status.status -eq "running") {
                return $status.defaultBaseURL
            }
        }
        return $null
    } finally {
        Pop-Location
    }
}

function Start-WheelsServer {
    param([string]$BoxPath)

    Write-Host ""
    Write-ColorOutput "=================================================================================" -ForegroundColor Blue
    Write-ColorOutput "                            Starting Development Server                         " -ForegroundColor Blue
    Write-ColorOutput "=================================================================================" -ForegroundColor Blue
    Write-Host ""

    $appPath = $Script:State.AppConfig.ApplicationPath

    if (-not (Test-Path $appPath)) {
        Stop-WithCriticalError "Application directory not found for server startup" "Expected Path: $appPath`n`nThe application directory does not exist. This should not happen if the application was created successfully."
    }

    try {
        Push-Location $appPath

        Write-Info "Checking development server for $($Script:State.AppConfig.ApplicationName)..."
        Write-ColorOutput "Server is starting, please wait..." -ForegroundColor Yellow

        # Step 1: Check if server already running
        $statusJson = & $BoxPath server status --json *>&1
        $isRunning = $false
        $serverUrl = $null

        if ($statusJson) {
            try {
                $status = $statusJson | ConvertFrom-Json -ErrorAction Stop
                if ($status.status -eq "running") {
                    $isRunning = $true
                    $serverUrl = $status.defaultBaseURL
                    if (-not $serverUrl -and $status.port) {
                        $serverUrl = "http://localhost:$($status.port)"
                    }
                }
            } catch {
                Write-Warning "Could not parse server status JSON: $statusJson"
            }
        }

        # Step 2: If not running, try to start
        if (-not $isRunning) {
            Write-Info "Server not running, starting now..."
            $output = & $BoxPath server start 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Warning "Server start may have completed with issues."
                Write-Info "Output: $($output -join ' ')"
            }

            # Check status again after start
            $statusJson = & $BoxPath server status --json 2>$null
            if ($statusJson) {
                $status = $statusJson | ConvertFrom-Json
                if ($status.status -eq "running") {
                    $isRunning = $true
                    $serverUrl = $status.defaultBaseURL
                    if (-not $serverUrl -and $status.port) {
                        $serverUrl = "http://localhost:$($status.port)"
                    }
                }
            }
        }

        # Step 3: Report result
        if ($isRunning -and $serverUrl) {
            Write-Success "Development server is running!"
            Write-Success "Server URL: $serverUrl"
            $Script:State.ServerUrl = $serverUrl
        } else {
            Write-Warning "Could not determine server status or URL."
        }

    } catch {
        Stop-WithCriticalError "Failed to start development server" "Application Path: $appPath`nError: $($_.Exception.Message)`n`nThis could be due to port conflicts, Java issues, or application configuration problems."
    } finally {
        Pop-Location
    }

    return $true
}

#endregion

#region Verification and Testing

function Test-Installation {
    param([string]$BoxPath)

    Write-Info "Verifying CommandBox installation..."

    # Test CommandBox basic functionality
    try {
        $boxVersion = & $BoxPath version 2>$null
        if (-not $boxVersion) {
            Stop-WithCriticalError "CommandBox executable not responding" "The CommandBox executable exists but does not respond to version command.`nThis could indicate a corrupted installation or missing dependencies."
        }
        Write-Success "CommandBox: $boxVersion"
    } catch {
        Stop-WithCriticalError "CommandBox verification failed" "Error: $($_.Exception.Message)`n`nCommandBox executable failed to run. This could be due to:`n- Missing Java runtime`n- Corrupted installation`n- Antivirus interference`n- Insufficient permissions"
    }

    return $true
}

function Show-CompletionSummary {
    $duration = (Get-Date) - $Script:State.StartTime

    # Ensure we have a server URL
    if (-not $Script:State.ServerUrl) {
        try {
            Push-Location $Script:State.AppConfig.ApplicationPath
            $statusJson = & $Script:State.InstallPath\box.exe server status --json 2>$null
            if ($statusJson) {
                $status = $statusJson | ConvertFrom-Json
                if ($status.running) {
                    $Script:State.ServerUrl = $status.serverInfo.url
                    if (-not $Script:State.ServerUrl -and $status.serverInfo.ports.http) {
                        $Script:State.ServerUrl = "http://localhost:$($status.serverInfo.ports.http)"
                    }
                }
            }
        } finally {
            Pop-Location
        }
    }

    Write-Host ""
    Write-ColorOutput "=================================================================================" -ForegroundColor Green
    Write-ColorOutput "                    Installation and Setup Completed Successfully!             " -ForegroundColor Green
    Write-ColorOutput "=================================================================================" -ForegroundColor Green
    Write-Host ""

    Write-ColorOutput "Installation Summary:" -ForegroundColor Green
    Write-ColorOutput "CommandBox Path: $($Script:State.InstallPath)" -ForegroundColor Green
    Write-ColorOutput "Java Installed: $(if ($Script:State.JavaInstalled) { 'Yes' } else { 'No (using embedded)' })" -ForegroundColor Green
    Write-ColorOutput "Application Name: $($Script:State.AppConfig.ApplicationName)" -ForegroundColor Green
    Write-ColorOutput "Application Path: $($Script:State.AppConfig.ApplicationPath)" -ForegroundColor Green
    if ($Script:State.ServerUrl) {
        Write-ColorOutput "Server URL: $($Script:State.ServerUrl)" -ForegroundColor Green
    } else {
        Write-ColorOutput "Server URL: Not available (server not running)" -ForegroundColor Yellow
    }
    Write-ColorOutput "Total Duration: $([int]$duration.TotalSeconds) seconds" -ForegroundColor Green
    Write-Host ""

    Write-ColorOutput "Your Wheels application is ready! Here's what you can do:" -ForegroundColor Green
    Write-Host ""
    Write-ColorOutput "Development Commands (run from $($Script:State.AppConfig.ApplicationPath)):" -ForegroundColor Yellow
    Write-ColorOutput "box server start/stop/restart  - Manage development server" -ForegroundColor Gray
    Write-ColorOutput "box wheels generate model [name] - Generate model" -ForegroundColor Gray
    Write-ColorOutput "box wheels generate controller [name] - Generate controller" -ForegroundColor Gray
    Write-ColorOutput "box wheels generate view [name] - Generate view" -ForegroundColor Gray
    Write-ColorOutput "box wheels migrate up - Run database migrations" -ForegroundColor Gray
    Write-Host ""

    Write-ColorOutput "Resources:" -ForegroundColor Yellow
    Write-ColorOutput "Documentation: https://wheels.dev/guides" -ForegroundColor Gray
    Write-ColorOutput "Getting Started: https://wheels.dev/guides#start-a-new-application-using-the-command-line" -ForegroundColor Gray
    if ($Script:State.ServerUrl) {
        Write-ColorOutput "Application: $($Script:State.ServerUrl)" -ForegroundColor Gray
    }
    Write-Host ""

    if (-not $SkipPath) {
        Write-Warning "Note: You may need to restart your terminal or run 'refreshenv' to use the 'box' command globally"
    }

    Write-Host ""
    if ($Script:State.ServerUrl) {
        Write-ColorOutput "Press any key to open your application in the browser..." -ForegroundColor Cyan
    } else {
        Write-ColorOutput "Press any key to finish..." -ForegroundColor Cyan
    }
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

    # Open Wheels Guides in browser if server is running
    if ($Script:State.ServerUrl) {
        Write-Host ""
        Write-Info "Opening Wheels Guides in the browser..."
        try {
            Start-Process "https://wheels.dev/guides"
            Write-Success "Documentation opened successfully!"
            Start-Sleep -Seconds 2
        } catch {
            Write-Warning "Could not open documentation automatically."
            Write-Info "Please visit: https://wheels.dev/guides"
        }
    } else {
        Write-Warning "No server URL available. Please start the server first."
    }

    # Show log file location
    Show-LogLocation

    Write-Host ""
    Write-ColorOutput "Happy coding with Wheels!" -ForegroundColor Green
}

#endregion

#region Main Installation Logic

function Start-Installation {
    try {
        # Initialize logging first
        Initialize-Logging
        Write-LogSection "INSTALLATION START"

        Write-Header "Wheels Installer" "Installing CommandBox, Wheels CLI, and Application"

        Initialize-Environment

        # Check Java and auto-install/upgrade if needed
        if (-not (Test-JavaInstallation)) {
            # Automatically attempt to install/upgrade Java
            if (-not (Install-Java)) {
                Write-Info "Continuing with CommandBox embedded Java..."
            }
        }

        # Install CommandBox
        $boxPath = Install-CommandBox
        if (-not $boxPath) {
            Stop-WithCriticalError "CommandBox installation failed" "The CommandBox installation process failed. Please check the error messages above."
        }

        # Add to PATH
        Add-CommandBoxToPath -BoxPath $boxPath

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

        # Verify CommandBox installation
        if (-not (Test-Installation -BoxPath $Script:State.BoxPath)) {
            Stop-WithCriticalError "CommandBox installation verification failed" "CommandBox was installed but verification failed. The installation may be corrupted."
        }

        # Install Wheels packages
        if (-not (Install-WheelsPackages -BoxPath $boxPath)) {
            Stop-WithCriticalError "Wheels packages installation failed" "The Wheels CLI package installation failed. Please check the error messages above."
        }

        # Create Wheels application (configuration already collected at startup)
        if (-not (Create-WheelsApplication -BoxPath $Script:State.BoxPath)) {
            Stop-WithCriticalError "Failed to create Wheels application" "Installation of CommandBox completed successfully but application creation failed. Please check the error messages above."
        }

        # Server should already be running, just check status
        $Script:State.ServerUrl = Get-WheelsServerStatus -BoxPath $Script:State.BoxPath
        if (-not $Script:State.ServerUrl) {
            Write-Warning "Application created successfully, but server does not appear to be running."
            Write-Info "You can manually start the server by running 'box server start' in your app directory."
        }

        # Clean up temporary files on successful completion
        Cleanup-TempFiles

        # Log completion
        Write-LogSection "INSTALLATION COMPLETED SUCCESSFULLY"
        Write-Log "Total installation time: $([int]((Get-Date) - $Script:State.StartTime).TotalSeconds) seconds" "SUCCESS"

        # Mark installation as successful
        $Script:State.InstallationSucceeded = $true
        Write-Log "Installation completed successfully" "SUCCESS"

        # Write success status for installer
        Write-InstallationStatus -ExitCode 0

        # Show completion summary
        Show-CompletionSummary

        # Exit with success code
        exit 0

    } catch {
        Write-LogError "Installation failed with unexpected error" $_
        Stop-WithCriticalError "Installation failed with unexpected error" "Error: $($_.Exception.Message)`n`nStack Trace:`n$($_.ScriptStackTrace)`n`nThis is an unexpected error. Please report this issue." -ExitCode 3
    }
}

#endregion

# Entry point
Start-Installation