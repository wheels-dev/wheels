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

.PARAMETER Quiet
    Suppress interactive prompts and use defaults.

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
    [switch]$Quiet,

    [Parameter()]
    [switch]$IncludeJava
)

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

#region System Configuration and User Settings

# --- Interactive prompts if parameters are missing ---
Write-Header "Wheels Framework Universal Installer" "Let's configure your installation and application setup"

# CommandBox Installation Configuration
if (-not $InstallPath) {
    Write-ColorOutput "CommandBox Installation Configuration:" -ForegroundColor Yellow
    Write-Host ""
    $defaultPath = if ([Security.Principal.WindowsIdentity]::GetCurrent().Groups -match "S-1-5-32-544") {
        # Admin install → Program Files
        "$env:ProgramFiles\CommandBox"
    } else {
        # User install → Local profile
        "$env:USERPROFILE\CommandBox"
    }
    $InstallPath = Read-Host ("Enter CommandBox installation path [{0}]" -f $defaultPath)
    if (-not $InstallPath) { $InstallPath = $defaultPath }
}

# Normalize CommandBox path

if ($InstallPath -notmatch "CommandBox$") {
    $InstallPath = Join-Path $InstallPath "CommandBox"
}

if (-not $PSBoundParameters.ContainsKey("Force")) {
    $ForceResponse = Read-Host "Force reinstall CommandBox if already installed? (Y/n) [n]"
    if ($ForceResponse -match "^[Yy]") { $Force = $true } else { $Force = $false }
}

if (-not $PSBoundParameters.ContainsKey("SkipPath")) {
    $SkipPathResponse = Read-Host "Skip adding CommandBox to PATH? (Y/n) [y]"
    if ($SkipPathResponse -match "^[Nn]") { $SkipPath = $false } else { $SkipPath = $true }
}

# Wheels Application Configuration
Write-ColorOutput "Now let's configure your Wheels application:" -ForegroundColor Yellow
Write-Host ""

# Initialize AppConfig in State
$Script:State.AppConfig = @{}

# Application Name
Write-ColorOutput "Step 1: Application Name" -ForegroundColor Cyan
Write-ColorOutput "Enter a name for your application. A new directory will be created with this name." -ForegroundColor Gray
Write-ColorOutput "Note: Names can only contain letters, numbers, underscores, and hyphens." -ForegroundColor Gray
do {
    $appName = Read-Host "Please enter a name for your application [MyWheelsApp]"
    if ([string]::IsNullOrEmpty($appName)) {
        $appName = "MyWheelsApp"
    }
    if ($appName -match '^[a-zA-Z0-9_-]+$') {
        $Script:State.AppConfig.ApplicationName = $appName
        Write-Success "Application name: $appName"
        break
    } else {
        Write-Warning "Invalid application name. Please use only letters, numbers, underscores, and hyphens."
    }
} while ($true)

# Template Selection
Write-Host ""
Write-ColorOutput "Step 2: Wheels Template Selection" -ForegroundColor Cyan
Write-ColorOutput "Which Wheels Template shall we use?" -ForegroundColor Gray
Write-Host ""
$templates = @(
    @{ Name = "3.0.x - Wheels Base Template - Bleeding Edge"; Value = "wheels-base-template@BE"; Default = $true }
    @{ Name = "2.5.x - Wheels Base Template - Stable Release"; Value = "wheels-base-template@stable"; Default = $false }
    @{ Name = "Wheels Template - HTMX - Alpine.js - Simple.css"; Value = "wheels-htmx-template"; Default = $false }
    @{ Name = "Wheels Starter App"; Value = "wheels-starter-template"; Default = $false }
    @{ Name = "Wheels - TodoMVC - HTMX - Demo App"; Value = "wheels-todomvc-template"; Default = $false }
)
for ($i = 0; $i -lt $templates.Count; $i++) {
    $marker = if ($templates[$i].Default) { "[X]" } else { "[ ]" }
    Write-Host "  $($i + 1). $marker $($templates[$i].Name)"
}
Write-Host ""
$choice = Read-Host "Select template (1-5) [1]"
if ([string]::IsNullOrEmpty($choice) -or $choice -eq "1") {
    $selectedTemplate = $templates[0]
} elseif ($choice -ge 2 -and $choice -le 5) {
    $selectedTemplate = $templates[$choice - 1]
} else {
    Write-Warning "Invalid selection, using default template"
    $selectedTemplate = $templates[0]
}
$Script:State.AppConfig.Template = $selectedTemplate.Value
Write-Success "Template: $($selectedTemplate.Name)"

# Reload Password
Write-Host ""
Write-ColorOutput "Step 3: Reload Password" -ForegroundColor Cyan
Write-ColorOutput "Set a reload password to secure your app. This allows you to restart your app via URL." -ForegroundColor Gray
$reloadPassword = Read-Host "Please enter a 'reload' password for your application [changeMe]"
if ([string]::IsNullOrEmpty($reloadPassword)) {
    $reloadPassword = "changeMe"
}
$Script:State.AppConfig.ReloadPassword = $reloadPassword
Write-Success "Reload password configured"

# Database Configuration
Write-Host ""
Write-ColorOutput "Step 4: Database Configuration" -ForegroundColor Cyan
Write-ColorOutput "Enter a datasource name for your database. You'll need to configure this in your CFML server admin." -ForegroundColor Gray
Write-ColorOutput "Tip: If using Lucee, we can auto-create an H2 database for development." -ForegroundColor Gray
$datasourceName = Read-Host "Please enter a datasource name [$($Script:State.AppConfig.ApplicationName)]"
if ([string]::IsNullOrEmpty($datasourceName)) {
    $datasourceName = $Script:State.AppConfig.ApplicationName
}
$Script:State.AppConfig.DatasourceName = $datasourceName
Write-Success "Datasource name: $datasourceName"

# CFML Engine
Write-Host ""
Write-ColorOutput "Step 5: CFML Engine" -ForegroundColor Cyan
Write-ColorOutput "Select the CFML engine for your application." -ForegroundColor Gray
Write-Host ""
$engines = @(
    @{ Name = "Lucee (Latest)"; Value = "lucee"; Default = $true }
    @{ Name = "Adobe ColdFusion (Latest)"; Value = "adobe"; Default = $false }
    @{ Name = "Lucee 6.x"; Value = "lucee@6"; Default = $false }
    @{ Name = "Lucee 5.x"; Value = "lucee@5"; Default = $false }
    @{ Name = "Adobe ColdFusion 2023"; Value = "adobe@2023"; Default = $false }
    @{ Name = "Adobe ColdFusion 2021"; Value = "adobe@2021"; Default = $false }
    @{ Name = "Adobe ColdFusion 2018"; Value = "adobe@2018"; Default = $false }
)
for ($i = 0; $i -lt $engines.Count; $i++) {
    $marker = if ($engines[$i].Default) { "[X]" } else { "[ ]" }
    Write-Host "  $($i + 1). $marker $($engines[$i].Name)"
}
Write-Host ""
$choice = Read-Host "Select CFML engine (1-7) [1]"
if ([string]::IsNullOrEmpty($choice) -or $choice -eq "1") {
    $selectedEngine = $engines[0]
} elseif ($choice -ge 2 -and $choice -le 7) {
    $selectedEngine = $engines[$choice - 1]
} else {
    Write-Warning "Invalid selection, using default engine"
    $selectedEngine = $engines[0]
}
$Script:State.AppConfig.CFMLEngine = $selectedEngine.Value
Write-Success "CFML Engine: $($selectedEngine.Name)"

# H2 Database for Lucee
if ($selectedEngine.Value -eq "lucee") {
    $H2Response = Read-Host "As you are using Lucee, would you like to setup and use the H2 Java embedded SQL database for development? (Y/n) [n]"
    if ($H2Response -match "^[Yy]") { $Script:State.AppConfig.UseH2Database = $true } else { $Script:State.AppConfig.UseH2Database = $false }
    Write-Success "H2 Database setup: $(if ($Script:State.AppConfig.UseH2Database) { 'Yes' } else { 'No' })"
} else {
    $Script:State.AppConfig.UseH2Database = $false
}

# Bootstrap Configuration
Write-Host ""
Write-ColorOutput "========= Twitter Bootstrap ======================" -ForegroundColor Cyan
$BootstrapResponse = Read-Host "Would you like us to setup some default Bootstrap settings? (Y/n) [y]"
if ($BootstrapResponse -match "^[Nn]") { $Script:State.AppConfig.UseBootstrap = $false } else { $Script:State.AppConfig.UseBootstrap = $true }
Write-Success "Bootstrap setup: $(if ($Script:State.AppConfig.UseBootstrap) { 'Yes' } else { 'No' })"

# Package Configuration
Write-Host ""
$InitPkgResponse = Read-Host "Finally, shall we initialize your application as a package by creating a box.json file? (Y/n) [y]"
if ($InitPkgResponse -match "^[Nn]") { $Script:State.AppConfig.InitializeAsPackage = $false } else { $Script:State.AppConfig.InitializeAsPackage = $true }
Write-Success "Initialize as package: $(if ($Script:State.AppConfig.InitializeAsPackage) { 'Yes' } else { 'No' })"

# Application Path Configuration
Write-Host ""
Write-ColorOutput "Step 6: Application Installation Path" -ForegroundColor Cyan
Write-ColorOutput "Choose where to install your Wheels application." -ForegroundColor Gray
Write-Host ""
# Default application path based on CommandBox path
$baseDir = Split-Path $InstallPath -Parent
$defaultAppPath = Join-Path $baseDir "inetpub"
Write-ColorOutput "Default application path: $defaultAppPath" -ForegroundColor Gray
$customPath = Read-Host "Enter a different application directory path (leave empty for default) [$defaultAppPath]"
if ([string]::IsNullOrEmpty($customPath)) {
    $appBasePath = $defaultAppPath
} else {
    # Add inetpub to custom path
    $appBasePath = Join-Path $customPath "inetpub"
    Write-Info "Application base path will be: $appBasePath"
}
# Validate and create path if needed
if (-not (Test-Path $appBasePath)) {
    $createPath = Get-UserConfirmation "The path '$appBasePath' does not exist. Create it? (y/n) [y]" -DefaultYes $true
    if ($createPath) {
        try {
            New-Item -ItemType Directory -Path $appBasePath -Force | Out-Null
            Write-Success "Created application directory: $appBasePath"
        } catch {
            Write-Error "Failed to create application directory: $($_.Exception.Message)"
            exit 1
        }
    } else {
        Write-Error "Cannot proceed without a valid application directory."
        exit 1
    }
} else {
    Write-Success "Application directory verified: $appBasePath"
}
$Script:State.AppConfig.ApplicationPath = Join-Path $appBasePath $Script:State.AppConfig.ApplicationName
Write-Success "Full application path: $($Script:State.AppConfig.ApplicationPath)"

$bootstrapStatus  = if ($Script:State.AppConfig.UseBootstrap) { 'true' } else { 'false' }
$h2Status         = if ($Script:State.AppConfig.UseH2Database) { 'true' } else { 'false' }
$packageStatus    = if ($Script:State.AppConfig.InitializeAsPackage) { 'true' } else { 'false' }

# Final Summary
Write-Host ""
Write-ColorOutput "+-----------------------------------------------------------------------------------+" -ForegroundColor Green
Write-ColorOutput "| Configuration Summary - Please confirm your selections:                           |" -ForegroundColor Green
Write-ColorOutput "+-----------------------+-----------------------------------------------------------+" -ForegroundColor Green
Write-ColorOutput "| CommandBox Path       | $($InstallPath.PadRight(57)) |" -ForegroundColor Green
Write-ColorOutput "| Template              | $($Script:State.AppConfig.Template.PadRight(57)) |" -ForegroundColor Green
Write-ColorOutput "| Application Name      | $($Script:State.AppConfig.ApplicationName.PadRight(57)) |" -ForegroundColor Green
Write-ColorOutput "| Install Directory     | $($Script:State.AppConfig.ApplicationPath.PadRight(57)) |" -ForegroundColor Green
Write-ColorOutput "| Reload Password       | $($Script:State.AppConfig.ReloadPassword.PadRight(57)) |" -ForegroundColor Green
Write-ColorOutput "| Datasource Name       | $($Script:State.AppConfig.DatasourceName.PadRight(57)) |" -ForegroundColor Green
Write-ColorOutput "| CF Engine             | $($Script:State.AppConfig.CFMLEngine.PadRight(57)) |" -ForegroundColor Green
Write-ColorOutput "| Setup Bootstrap       | $($bootstrapStatus.PadRight(57)) |" -ForegroundColor Green
Write-ColorOutput "| Setup H2 Database     | $($h2Status.PadRight(57)) |" -ForegroundColor Green
Write-ColorOutput "| Initialize as Package | $($packageStatus.PadRight(57)) |" -ForegroundColor Green
Write-ColorOutput "| Force Installation    | $($Force.ToString().ToLower().PadRight(57)) |" -ForegroundColor Green
Write-ColorOutput "| Skip add to PATH      | $($SkipPath.ToString().ToLower().PadRight(57)) |" -ForegroundColor Green
Write-ColorOutput "+-----------------------+-----------------------------------------------------------+" -ForegroundColor Green
Write-Host ""

$proceed = Get-UserConfirmation "Does this configuration look correct? Proceed with installation?" -DefaultYes $true
if (-not $proceed) {
    Write-Warning "Installation cancelled by user."
    Write-Host ""
    Write-Host "Press any key to close..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 0
}

Write-Success "Configuration confirmed! Starting installation and application setup..."
Write-Host ""

#endregion

#region System Detection and Validation

function Initialize-Environment {
    Write-Info "Initializing installation environment..."

    $Script:State.IsAdmin = Test-Administrator

    # Set Installation path (already configured in the user prompts section)
    $Script:State.InstallPath = $InstallPath

    Write-Info "Installation path: $($Script:State.InstallPath)"
    Write-Info "Administrator privileges: $(if ($Script:State.IsAdmin) { 'Yes' } else { 'No' })"
    Write-Info "Quiet mode: $(if ($Quiet) { 'Yes' } else { 'No' })"
}

function Test-JavaInstallation {
    Write-Info "Checking Java installation..."

    try {
        $javaOutput = & java -version *>&1
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

#region Wheels Application Creation

function Create-WheelsApplication {
    param([string]$BoxPath)

    Write-Host ""
    Write-ColorOutput "=================================================================================" -ForegroundColor Blue
    Write-ColorOutput "                          Creating Wheels Application                           " -ForegroundColor Blue
    Write-ColorOutput "=================================================================================" -ForegroundColor Blue
    Write-Host ""

    $appName = $Script:State.AppConfig.ApplicationName
    $appPath = $Script:State.AppConfig.ApplicationPath
    $template = $Script:State.AppConfig.Template

    Write-Info "Creating Wheels application: $appName"
    Write-Info "Location: $appPath"
    Write-Info "Template: $template"

    try {
        # Change to the parent directory where the app will be created
        $appParentDir = Split-Path $appPath -Parent
        Push-Location $appParentDir

        # Build the wheels generate app command
        $generateCmd = @("wheels", "generate", "app", $appName, "--template=$template")

        # Add additional parameters
        if ($Script:State.AppConfig.ReloadPassword -ne "") {
            $generateCmd += "--reloadPassword=$($Script:State.AppConfig.ReloadPassword)"
        }

        if ($Script:State.AppConfig.DatasourceName -ne $appName) {
            $generateCmd += "--datasourceName=$($Script:State.AppConfig.DatasourceName)"
        }

        if ($Script:State.AppConfig.CFMLEngine -ne "lucee") {
            $generateCmd += "--cfmlEngine=$($Script:State.AppConfig.CFMLEngine)"
        }

        if ($Script:State.AppConfig.UseH2Database) {
            $generateCmd += "--setupH2=true"
        }

        if ($Script:State.AppConfig.UseBootstrap) {
            $generateCmd += "--useBootstrap=true"
        }

        if ($Script:State.AppConfig.InitializeAsPackage) {
            $generateCmd += "--initPackage=true"
        }

        Write-Info "Executing: box $($generateCmd -join ' ')"
        Write-ColorOutput "Creating application, please wait..." -ForegroundColor Yellow

        # Execute the command
        $output = & $BoxPath $generateCmd 2>&1

        if ($LASTEXITCODE -eq 0) {
            Write-Success "Wheels application created successfully!"
        } else {
            Write-Warning "Application creation may have completed with warnings."
            Write-Info "Output: $($output -join ' ')"
        }

    } catch {
        Write-Error "Failed to create Wheels application: $($_.Exception.Message)"
        return $false
    } finally {
        Pop-Location
    }

    # Verify the application was created
    if (Test-Path $appPath) {
        Write-Success "Application directory verified: $appPath"
        return $true
    } else {
        Write-Error "Application directory not found: $appPath"
        return $false
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
        Write-Error "Application directory not found: $appPath"
        return $false
    }

    try {
        Push-Location $appPath

        Write-Info "Starting development server for $($Script:State.AppConfig.ApplicationName)..."
        Write-ColorOutput "Server is starting, please wait..." -ForegroundColor Yellow

        # Start the server
        $output = & $BoxPath server start 2>&1

        if ($LASTEXITCODE -eq 0) {
            Write-Success "Development server started successfully!"

            # Extract server URL if available in output
            $urlMatch = $output | Select-String -Pattern "http://[^\\s]+"
            if ($urlMatch) {
                $serverUrl = $urlMatch.Matches[0].Value
                Write-Success "Server URL: $serverUrl"
                $Script:State.ServerUrl = $serverUrl
            }
        } else {
            Write-Warning "Server start may have completed with issues."
            Write-Info "Output: $($output -join ' ')"
        }

    } catch {
        Write-Error "Failed to start development server: $($_.Exception.Message)"
        return $false
    } finally {
        Pop-Location
    }

    return $true
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

function Show-CompletionSummary {
    $duration = (Get-Date) - $Script:State.StartTime

    Write-Host ""
    Write-ColorOutput "=================================================================================" -ForegroundColor Green
    Write-ColorOutput "                    Installation and Setup Completed Successfully!             " -ForegroundColor Green
    Write-ColorOutput "=================================================================================" -ForegroundColor Green
    Write-Host ""

    Write-ColorOutput "Installation Summary:" -ForegroundColor Green
    Write-ColorOutput "• CommandBox Path: $($Script:State.InstallPath)" -ForegroundColor Green
    Write-ColorOutput "• Java Installed: $(if ($Script:State.JavaInstalled) { 'Yes' } else { 'No (using embedded)' })" -ForegroundColor Green
    Write-ColorOutput "• Application Name: $($Script:State.AppConfig.ApplicationName)" -ForegroundColor Green
    Write-ColorOutput "• Application Path: $($Script:State.AppConfig.ApplicationPath)" -ForegroundColor Green
    if ($Script:State.ServerUrl) {
        Write-ColorOutput "• Server URL: $($Script:State.ServerUrl)" -ForegroundColor Green
    }
    Write-ColorOutput "• Total Duration: $([int]$duration.TotalSeconds) seconds" -ForegroundColor Green
    Write-Host ""

    Write-ColorOutput "Your Wheels application is ready! Here's what you can do:" -ForegroundColor Green
    Write-Host ""
    Write-ColorOutput "Development Commands (run from $($Script:State.AppConfig.ApplicationPath)):" -ForegroundColor Yellow
    Write-ColorOutput "• box server start/stop/restart  - Manage development server" -ForegroundColor Gray
    Write-ColorOutput "• box wheels generate model [name] - Generate model" -ForegroundColor Gray
    Write-ColorOutput "• box wheels generate controller [name] - Generate controller" -ForegroundColor Gray
    Write-ColorOutput "• box wheels generate view [name] - Generate view" -ForegroundColor Gray
    Write-ColorOutput "• box wheels migrate up - Run database migrations" -ForegroundColor Gray
    Write-Host ""

    Write-ColorOutput "Resources:" -ForegroundColor Yellow
    Write-ColorOutput "• Documentation: https://wheels.dev/guides" -ForegroundColor Gray
    Write-ColorOutput "• Getting Started: https://wheels.dev/guides#start-a-new-application-using-the-command-line" -ForegroundColor Gray
    Write-Host ""

    if (-not $SkipPath) {
        Write-Warning "Note: You may need to restart your terminal or run 'refreshenv' to use the 'box' command globally"
    }

    Write-Host ""
    Write-ColorOutput "Press any key to open your application in the browser..." -ForegroundColor Cyan
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

    # Open the application in browser if server is running
    if ($Script:State.ServerUrl -and -not $Quiet) {
        Write-Host ""
        Write-Info "Opening your Wheels application in the browser..."
        try {
            Start-Process $Script:State.ServerUrl
            Write-Success "Browser opened successfully!"
            Start-Sleep -Seconds 2
        } catch {
            Write-Warning "Could not open browser automatically."
            Write-Info "Please visit: $($Script:State.ServerUrl)"
        }
    } else {
        Write-Host ""
        Write-Info "Opening Wheels Getting Started Guide in your browser..."
        if (-not $Quiet) {
            try {
                Start-Process "https://wheels.dev/guides#start-a-new-application-using-the-command-line"
                Write-Success "Browser opened successfully!"
                Start-Sleep -Seconds 2
            } catch {
                Write-Warning "Could not open browser automatically."
                Write-Info "Please visit: https://wheels.dev/guides#start-a-new-application-using-the-command-line"
            }
        }
    }

    Write-Host ""
    Write-ColorOutput "Happy coding with Wheels!" -ForegroundColor Green
}

#endregion

#region Main Installation Logic

function Start-Installation {
    try {
        Write-Header "Wheels Framework Universal Installer" "Installing CommandBox, Wheels CLI, and creating your application"

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

        # Create Wheels application (configuration already collected at startup)
        if (-not (Create-WheelsApplication -BoxPath $Script:State.BoxPath)) {
            Write-Error "Failed to create Wheels application. Installation completed but app creation failed."
            exit 1
        }

        # Start development server
        if (-not (Start-WheelsServer -BoxPath $Script:State.BoxPath)) {
            Write-Warning "Application created successfully, but server failed to start."
            Write-Info "You can manually start the server by running 'box server start' in your app directory."
        }

        # Show completion summary
        Show-CompletionSummary

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