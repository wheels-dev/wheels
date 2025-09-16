# Wheels Framework Installers

This directory contains installers for setting up the Wheels Framework on fresh laptops across different operating systems. These installers will set up CommandBox, both the core Wheels package and Wheels CLI, ensuring you have everything needed to start developing with Wheels.

## What Gets Installed

Each installer will install:

1. **CommandBox 6.2.1** - The CFML CLI and development server
3. **wheels-cli** - Wheels CLI commands for generators and utilities

## Quick Installation

### macOS and Linux

```bash
# One-line install (recommended)
curl -fsSL https://raw.githubusercontent.com/wheels-dev/wheels/develop/tools/install/install-wheels.sh | bash

# Or download and run locally
wget https://raw.githubusercontent.com/wheels-dev/wheels/develop/tools/install/install-wheels.sh
chmod +x install-wheels.sh
./install-wheels.sh
```

### Windows

```powershell
# Download and run in PowerShell (Run as Administrator recommended)
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/wheels-dev/wheels/develop/tools/install/install-wheels.ps1" -OutFile "install-wheels.ps1"
.\install-wheels.ps1

# Or with parameters
.\install-wheels.ps1 -InstallPath "C:\Tools\CommandBox" -Force
```

## Installation Options

### Unix/Linux/Mac Options

```bash
./install-wheels.sh [options]

Options:
  --install-path PATH    Custom installation directory
                        (default: /usr/local/bin or ~/.local/bin)
  --force               Force reinstallation even if components exist
  --skip-path           Skip adding CommandBox to PATH
  --help, -h            Show help message
```

#### Examples

```bash
# Install with custom path
./install-wheels.sh --install-path /opt/commandbox

# Force reinstall everything
./install-wheels.sh --force

# Install without modifying PATH
./install-wheels.sh --skip-path
```

### Windows Options

```powershell
.\install-wheels.ps1 [parameters]

Parameters:
  -InstallPath          Custom installation directory
                       (default: Program Files for admin, user profile otherwise)
  -Force               Force reinstallation even if components exist
  -SkipPath            Skip adding CommandBox to PATH
```

#### Examples

```powershell
# Install with custom path
.\install-wheels.ps1 -InstallPath "C:\Tools\CommandBox"

# Force reinstall everything
.\install-wheels.ps1 -Force

# Install without modifying PATH
.\install-wheels.ps1 -SkipPath
```

## After Installation

Once installation is complete:

1. **Restart your terminal** or source your shell profile:
   ```bash
   # macOS/Linux
   source ~/.bashrc  # or ~/.zshrc
   ```

2. **Create your first Wheels app**:
   ```bash
   box wheels g app myapp
   cd myapp
   box server start
   ```

3. **Available commands**:
   - `box wheels g app <name>` - Generate new Wheels application
   - `box wheels g model <name>` - Generate model
   - `box wheels g controller <name>` - Generate controller
   - `box wheels g scaffold <name>` - Generate full CRUD scaffold
   - `box server start` - Start development server
   - `box server stop` - Stop development server

## System Requirements

### All Platforms
- **Internet connection** for downloading packages
- **Curl/wget** (Unix) or **PowerShell 5.1+** (Windows)
- **Unzip utility**

### Recommended
- **Java 11+** for optimal performance (CommandBox includes embedded Java if not available)

### Operating System Support
- **macOS** 10.12+
- **Linux** (Ubuntu 18.04+, CentOS 7+, other major distributions)
- **Windows** 10/11 with PowerShell 5.1+

## Installation Locations

### Default Installation Paths

**macOS/Linux:**
- **System-wide** (with sudo): `/usr/local/bin`
- **User-only**: `~/.local/bin`

**Windows:**
- **Administrator**: `C:\Program Files\CommandBox`
- **User**: `%USERPROFILE%\.commandbox`

### PATH Configuration

The installers automatically add CommandBox to your system PATH:

**macOS/Linux:**
- Updates `~/.bashrc` or `~/.zshrc`
- Updates current session PATH

**Windows:**
- Updates system or user PATH environment variable
- Updates current session PATH

## Package Sources

All packages are installed from official sources:

- **CommandBox**: Downloaded from [Ortus Solutions](https://downloads.ortussolutions.com/ortussolutions/commandbox/)
- **wheels-cli**: Installed from [ForgeBox](https://forgebox.io/view/wheels-cli)

## Troubleshooting

### Common Issues

**Permission denied (Unix/Linux)**:
```bash
# Either run with appropriate permissions or use custom path
./install-wheels.sh --install-path ~/.local/commandbox
```

**PowerShell execution policy (Windows)**:
```powershell
# Temporarily allow script execution
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\install-wheels.ps1
```

**CommandBox not found after installation**:
```bash
# Restart terminal or source shell profile
source ~/.bashrc  # or ~/.zshrc

# Or use full path until PATH is updated
/path/to/commandbox/box wheels g app myapp
```

### Verification

To verify your installation:

```bash
# Check CommandBox
box version

# Check Wheels packages
box list

# Check Wheels CLI
box wheels version
```

### Getting Help

- **Installation issues**: Check this README and try with `--force` flag
- **Wheels documentation**: [https://wheels.dev/guides](https://wheels.dev/guides)
- **CommandBox documentation**: [https://commandbox.ortusbooks.com](https://commandbox.ortusbooks.com)
- **Community support**: [Wheels Discord/Forums](https://wheels.dev/community)

## Manual Installation Alternative

If the automated installers don't work for your system, you can install manually:

1. **Download CommandBox**:
   ```bash
   # Download from: https://downloads.ortussolutions.com/ortussolutions/commandbox/
   # Extract to desired location and add to PATH
   ```

2. **Install Wheels packages**:
   ```bash
   box install wheels-cli
   ```

3. **Create your first app**:
   ```bash
   box wheels g app myapp
   ```

## Contributing

To improve these installers:

1. Fork the repository
2. Make changes to the installer scripts
3. Test on target platforms
4. Submit a pull request

The installer scripts are located at:
- `tools/install/install-wheels.sh` (Unix/Linux/Mac)
- `tools/install/install-wheels.ps1` (Windows)