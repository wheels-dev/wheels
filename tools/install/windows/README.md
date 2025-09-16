# Wheels Windows Installer Builder

This directory contains tools to create a Windows executable installer for the Wheels Framework.

## Overview

The installer builder converts the PowerShell installation script (`install-wheels.ps1`) into a standalone Windows executable (`.exe`) file that users can download and run without needing PowerShell knowledge or dealing with execution policies.

## Prerequisites

- **Windows machine** with PowerShell 5.1+
- **Internet connection** for downloading ps2exe module
- **Administrator privileges** (recommended for building)

## Files

- `create-installer-exe.ps1` - Script that builds the executable installer
- `README.md` - This documentation file

## How to Build the Installer

### Step 1: Prepare Environment

1. Open PowerShell as Administrator (recommended)
2. Navigate to this directory:
   ```powershell
   cd tools\install\windows
   ```

### Step 2: Run the Builder

```powershell
# Basic usage - creates wheels-installer.exe in installer/ folder
.\create-installer-exe.ps1

# Custom output name and location
.\create-installer-exe.ps1 -OutputDir "release" -ExeName "wheels-framework-installer.exe"
```

**Note**: The script automatically looks for `install-wheels.ps1` (the main installer script in the same directory).

### Step 3: What Happens

The script will:

1. **Check for source script** (`install-wheels.ps1`) and verify it exists
2. **Install ps2exe module** (if not already installed)
3. **Create output directory** (`installer/` by default)
4. **Convert PowerShell script to executable** using ps2exe
5. **Generate standalone .exe file** ready for distribution

### Step 4: Output

You'll get:
- **Executable file**: `installer/wheels-installer.exe` (or your custom name/location)
- **File size**: Approximately 2-5 MB
- **Self-contained**: Includes all PowerShell code embedded

## Distribution

### For End Users

The generated `.exe` file provides this user experience:

1. **Download** `wheels-installer.exe`
2. **Double-click** to run (Windows will prompt for admin privileges)
3. **Installation runs** with colorful progress indicators
4. **Browser opens** to Getting Started guide when complete
5. **Window closes** automatically after 2 seconds

### For Release Process

1. **Build the installer** using this script
2. **Test the executable** on a clean Windows machine
3. **Upload to GitHub Releases** or distribution server
4. **Update download links** in documentation

## Parameters

The `create-installer-exe.ps1` script accepts these parameters:

| Parameter | Default | Description |
|-----------|---------|-------------|
| `-OutputDir` | `"installer"` | Directory to create the executable in |
| `-ExeName` | `"wheels-installer.exe"` | Name of the output executable file |

## Examples

```powershell
# Create installer in default location (installer/wheels-installer.exe)
.\create-installer-exe.ps1

# Create installer with custom name in release folder
.\create-installer-exe.ps1 -OutputDir "release" -ExeName "wheels-framework-setup.exe"

# Create installer in parent directory (useful for distribution)
.\create-installer-exe.ps1 -OutputDir ".." -ExeName "wheels-installer.exe"
```

## Technical Details

### ps2exe Module

The installer uses the `ps2exe` PowerShell module which:
- Converts PowerShell scripts to standalone executables
- Embeds the entire PowerShell script inside the .exe
- Creates a .NET wrapper that can execute PowerShell code
- Supports command-line parameters and admin privileges

### Installer Properties

The generated executable has these properties:
- **Title**: "Wheels Framework Installer"
- **Description**: "Wheels Framework Installer for Windows"
- **Company**: "Wheels Framework"
- **Version**: "1.0.0.0"
- **Copyright**: "(c) 2024 Wheels Framework"
- **Requires Admin**: Yes (for optimal installation)

### Embedded Script

The executable contains the complete `install-wheels.ps1` script which:
- Downloads and installs CommandBox
- Installs wheels-cli package from ForgeBox
- Configures PATH environment variables
- Shows installation summary and opens documentation

### Source File Requirements

The builder script requires:
- `install-wheels.ps1` must exist in the same directory
- The script automatically verifies the source file exists before building
- If the source file is missing, you'll get a clear error message

## Troubleshooting

### Common Issues

**Source script not found:**
```
ERROR: Source script not found: install-wheels.ps1
```
- Ensure you're running from the `tools/install/windows/` directory
- Verify `install-wheels.ps1` exists in `tools/install/windows/`

**ps2exe module not installing:**
```powershell
# Manual installation
Install-Module ps2exe -Force -Scope CurrentUser -Repository PSGallery
Import-Module ps2exe
```

**Permission denied:**
```powershell
# Run PowerShell as Administrator
# Or use current user scope
Install-Module ps2exe -Scope CurrentUser
```

**Antivirus blocking:**
- Some antivirus software may flag generated executables
- This is normal for ps2exe-generated files
- You may need to add exceptions or sign the executable

### Verification

To verify the installer works:

1. **Test on clean Windows machine**
2. **Run without admin first** (should prompt)
3. **Run with admin** (should install successfully)
4. **Check that CommandBox and wheels-cli are installed**
5. **Verify browser opens to documentation**

## Release Checklist

Before releasing a new installer:

- [ ] Test on Windows 10 and Windows 11
- [ ] Test with and without admin privileges
- [ ] Verify CommandBox downloads successfully
- [ ] Verify wheels-cli package installs
- [ ] Test browser opening functionality
- [ ] Check file size is reasonable (< 10MB)
- [ ] Test on machine without PowerShell modules
- [ ] Verify installation summary displays correctly

## Maintenance

### Updating the Installer

When updating the main `install-wheels.ps1` script:

1. **Make changes** to `install-wheels.ps1` (same directory)
2. **Test the PowerShell script** directly
3. **Stay in Windows directory**: `cd tools/install/windows`
4. **Rebuild the executable** using `.\create-installer-exe.ps1`
5. **Test the new executable**
6. **Update version number** if needed
7. **Distribute the new executable**

### Version Management

To update the version number, edit the `ps2exe` command in `create-installer-exe.ps1`:

```powershell
ps2exe -inputFile $sourceScript `
       -outputFile $OutputPath `
       -version "1.1.0.0" `  # Update this line
       # ... other parameters
```

## Support

For issues with the installer builder:

1. **Check PowerShell execution policy**: `Get-ExecutionPolicy`
2. **Verify ps2exe installation**: `Get-Module ps2exe -ListAvailable`
3. **Test with verbose output**: The script already includes `-verbose`
4. **Check antivirus logs** for blocked files
5. **Try building on different Windows machine**

---

**Note**: This installer builder must be run on Windows as ps2exe is a Windows-only PowerShell module. The generated executable will only work on Windows systems.