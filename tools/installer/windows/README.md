# Wheels Windows Installer - Developer Guide

This document is for developers working on the Wheels Windows installer. If you're new to this codebase, read this first.

## What This Is

A **GUI Windows installer** built with **Inno Setup** that wraps a **PowerShell installation script**. The installer collects user preferences through a wizard, then executes PowerShell with those parameters to perform the actual installation.

**Why this architecture?**
- Inno Setup provides professional GUI and Windows integration
- PowerShell handles complex installation logic and downloads
- Separation allows easier maintenance of UI vs. installation logic

## File Overview

```
tools/install/windows/
├── install-wheels.iss          # Inno Setup GUI installer (Pascal)
├── install-wheels.ps1          # PowerShell installation engine script
├── installer/                  # Build output directory
└── README.md                   # This developer guide
```

## Code Architecture

### 1. Inno Setup Script (`install-wheels.iss`)
**Language**: Pascal
**Purpose**: GUI wizard that collects parameters and executes PowerShell

#### Key Sections:
```pascal
[Setup]          # Installer metadata and behavior
[Files]          # Files to embed (the PowerShell script)
[Run]            # PowerShell execution with fallbacks
[Code]           # Pascal functions for UI logic and parameter handling
```

#### Critical Functions You Need to Know:
- **`GetInstallPath()`, `GetAppName()`, etc.**: Convert UI selections to command-line parameters
- **`CheckInstallResult()`**: Reads status file written by PowerShell and displays result
- **`InitializeWizard()`**: Creates all the wizard pages and controls

#### Parameter Flow:
```
UI Controls → Getter Functions → PowerShell Command Line → install-wheels.ps1
```

**Example PowerShell Command Generated:**
```pascal
pwsh.exe -NoProfile -ExecutionPolicy Bypass -File "{tmp}\install-wheels.ps1"
  -InstallPath "C:\Program Files\CommandBox"
  -AppName "MyWheelsApp"
  -Template "wheels-base-template@BE"
  -ReloadPassword "changeMe"
  -DatasourceName "MyWheelsApp"
  -CFMLEngine "lucee"
  -UseBootstrap
  -InitializeAsPackage
  -ApplicationBasePath "C:\Program Files\inetpub"
```

**Parameters are collected from Inno Setup UI and passed to PowerShell** - this is the bridge between the two systems.

### 2. PowerShell Script (`install-wheels.ps1`)
**Language**: PowerShell 5.1+
**Purpose**: Actual installation logic, downloads, and configuration

#### Key Architecture:
```powershell
$Script:State = @{...}           # Global state management
$Script:Config = @{...}          # Configuration constants

#region Logging Functions         # Consistent logging system
#region Utility Functions         # Status files, error handling
#region Download Functions        # File downloads with progress
#region Installation Logic        # CommandBox, Java, Wheels setup
#region Application Creation      # Wheels app generation
```

## Communication Between Components

### Status File System
**File**: `%TEMP%\wheels-install-status.txt`
**Purpose**: PowerShell → Inno Setup communication

```
Line 1: Exit Code (0=success, 1=error, 2=cancelled, 3=unexpected, -1=interrupted)
Line 2: Log file path for detailed information
```

**Critical Implementation Details:**
- PowerShell **deletes old status file** before writing new one (prevents stale data)
- Inno Setup **deletes status file** after reading (cleanup for next run)
- **Guard variable** `$Script:State.StatusWritten` prevents duplicate writes
- **Trap handler** writes `-1` if PowerShell terminates unexpectedly

### Logging System
**File**: `%TEMP%\wheels-installation.log`
**Format**: `[YYYY-MM-DD HH:MM:SS.fff] [LEVEL] Message`

**Key Features:**
- **Persistent across runs** (no timestamp in filename)
- **Session markers** separate multiple installation attempts
- **Consistent formatting** through `Write-Log` function
- **Multiple levels**: INFO, SUCCESS, WARNING, ERROR, STATUS

## Development Workflow

### Making Changes

1. **For UI Changes**: Edit `install-wheels.iss`
   - Add/modify wizard pages in `InitializeWizard()`
   - Update parameter getter functions
   - Test parameter passing to PowerShell

2. **For Installation Logic**: Edit `install-wheels.ps1`
   - Modify functions in appropriate regions
   - Maintain consistent logging format
   - Update status reporting if needed

3. **Testing Changes**:
   ```powershell
   # Test PowerShell directly with parameters
   .\install-wheels.ps1 -AppName "TestApp" -Template "wheels-base-template@BE"

   # Check status file contents
   Get-Content "$env:TEMP\wheels-install-status.txt"

   # Review logs
   Get-Content "$env:TEMP\wheels-installation.log" -Tail 20
   ```

### Building the Installer

**Prerequisites:**
- **Inno Setup 6.0+ installed** (Download: https://jrsoftware.org/isinfo.php)
- Windows machine

**Important**: You MUST have Inno Setup installed to build this installer. The `.iss` file is a Pascal script that requires the Inno Setup Compiler.

**Build Steps:**
1. Download and install Inno Setup if not already installed
2. Open `install-wheels.iss` in Inno Setup Compiler
3. Press F9 or Build → Compile
4. Output: `installer\wheels-installer.exe`

## Critical Implementation Details

### PowerShell Execution Chain
The installer tries three PowerShell execution methods (fallback chain):
```pascal
1. pwsh.exe          # PowerShell Core (preferred)
2. Windows PowerShell # Built-in Windows version
3. powershell.exe    # PATH fallback
```

**Why**: Different Windows systems have different PowerShell installations.

### Error Handling Strategy

#### PowerShell Side:
```powershell
trap {
    # Handles unexpected termination (window close, etc.)
    # Writes -1 status if not already written
}

function Write-InstallationStatus {
    # Guard prevents duplicate status writes
    # Deletes old status file first
    # Writes final status to log
}
```

#### Inno Setup Side:
```pascal
procedure CheckInstallResult();
  # Reads status file
  # Maps exit codes to user messages
  # Displays appropriate success/error dialog
```

### Parameter Validation
```pascal
function NextButtonClick(CurPageID: Integer): Boolean;
  # Validates user input before proceeding
  # Currently validates: Application name, Datasource name
  # Returns false to prevent page advance on invalid input
```

## Key Development Insights

### Parameter Collection System
The Inno Setup wizard collects user input through multiple pages, then **converts UI state into PowerShell parameters**. This happens in the `[Run]` section:

```pascal
Parameters: "-NoProfile -ExecutionPolicy Bypass -File ""{tmp}\install-wheels.ps1""
  -InstallPath ""{code:GetInstallPath}""
  {code:GetForceParam}
  -AppName ""{code:GetAppName}""
  -Template ""{code:GetTemplate}""
  // ... more parameters
```

Each `{code:FunctionName}` calls a Pascal function that reads the UI controls and returns the appropriate parameter value.

### Status Communication Protocol
**Flow**: PowerShell writes status → Inno Setup reads status → Displays result

**Critical**: The status file acts as the **only communication channel** from PowerShell back to Inno Setup. Without this file, Inno Setup can't determine if installation succeeded or failed.

## Code Style Guidelines

### PowerShell Script:
- Use `Write-Log` for all logging (maintains format consistency)
- Always use try/catch with `Write-LogError` for error details
- Add new functions to appropriate `#region` blocks
- Use `$Script:State` for persistent data, `$Script:Config` for constants

### Inno Setup Script:
- Use consistent variable naming: `CamelCase` for functions, `lowercase` for variables
- Add validation in `NextButtonClick` for new input fields
- Keep getter functions simple (just return the value)
- Document any complex Pascal logic with comments

## Testing Checklist for Developers

### Unit Testing (Manual):
- [ ] Test PowerShell script directly with various parameter combinations
- [ ] Test each wizard page navigation
- [ ] Test parameter validation (invalid names, etc.)
- [ ] Test status file creation and reading

### Integration Testing:
- [ ] Full installer run on clean Windows VM
- [ ] Test all template options
- [ ] Test different CFML engine selections
- [ ] Test error scenarios (network down, permissions, etc.)
- [ ] Test cancellation at different stages

### Edge Cases:
- [ ] CommandBox already installed
- [ ] Java already installed but old version
- [ ] Application name conflicts with existing server
- [ ] Insufficient permissions
- [ ] Network connectivity issues

## Debugging Tips

### Enable Detailed Logging:
```powershell
# In install-wheels.ps1, add more Write-Log calls
Write-Log "About to execute: $command" "INFO"
```

### Inno Setup Debugging:
```pascal
// Add temporary debug messages
MsgBox('Debug: InstallationResult = ' + IntToStr(InstallationResult));
```

### Log Analysis:
```powershell
# View recent logs with filtering
Get-Content "$env:TEMP\wheels-installation.log" | Select-String "ERROR|CRITICAL"

# Monitor log in real-time during testing
Get-Content "$env:TEMP\wheels-installation.log" -Wait -Tail 10
```

## Architecture Decisions

### Why Inno Setup Instead of Other Installers?
- **Professional appearance**: Native Windows look and feel
- **Wide compatibility**: Works on Windows 7+ without dependencies
- **Flexibility**: Full control over UI and installation logic
- **Size efficiency**: Small installer executable
- **Code signing support**: Easy to sign for Windows trust

### Why PowerShell for Installation Logic?
- **Native Windows tooling**: Available on all modern Windows
- **Rich object model**: Easy HTTP downloads, file operations
- **Error handling**: Structured exception handling
- **Community**: Large ecosystem and examples

### Why Single Status File?
- **Prevents race conditions**: No timing issues between multiple files
- **Atomic operations**: One write, one read
- **Simpler debugging**: Single source of truth for installation status

## Future Enhancement Ideas

### Potential Improvements:
1. **Progress Reporting**: Real-time progress from PowerShell to Inno Setup
2. **Rollback Capability**: Ability to undo failed installations
3. **Silent Installation**: Command-line parameters for unattended installs
4. **Update Detection**: Check for newer versions before installing
5. **Custom Templates**: Allow user-provided template URLs

### Extension Points:
- Add new wizard pages by extending `InitializeWizard()`
- Add new templates by updating template radio button logic
- Add new CFML engines by extending engine selection
- Add new validation rules in `NextButtonClick()`

## Resources

### Documentation:
- **Inno Setup Documentation**: https://jrsoftware.org/ishelp/
- **PowerShell Documentation**: https://docs.microsoft.com/powershell/
- **CommandBox Documentation**: https://commandbox.ortusbooks.com/

### Tools:
- **Inno Setup Compiler**: For building installers
- **VSCode**: Good editor for both Pascal and PowerShell
- **PowerShell ISE**: Built-in PowerShell development environment

---

**Remember**: This installer affects the first impression users have of Wheels. Keep it reliable, user-friendly, and well-tested.