# Contributing to Wheels Windows Installer

## Repository

The Wheels Windows Installer is located in the main Wheels repository at `tools/installer/windows/`:

**[GitHub Repository](https://github.com/wheels-dev/wheels/tree/develop/tools/installer/windows)**

## Development Setup

### Prerequisites
- Windows 10/11
- Inno Setup 6.0+ ([Download](https://jrsoftware.org/isinfo.php))
- PowerShell 5.1+ (built into Windows)
- Git
- Administrator privileges (for testing installations)

### Initial Setup
1. Clone the Wheels repository:
   ```bash
   git clone https://github.com/wheels-dev/wheels.git
   cd wheels/tools/installer/windows
   ```

2. Verify Inno Setup installation:
   ```powershell
   # Should open Inno Setup Compiler
   & "C:\Program Files (x86)\Inno Setup 6\Compil32.exe" /?
   ```

## Installer Structure

```
tools/installer/windows/
├── install-wheels.iss          # Inno Setup GUI installer (Pascal)
├── install-wheels.ps1          # PowerShell installation engine
├── installer/                  # Build output directory
│   └── wheels-installer.exe    # Generated installer executable
└── README.md                   # Developer technical guide
```

## Architecture Overview

The installer uses a two-component architecture:

- **Inno Setup Script** (`install-wheels.iss`): Professional Windows GUI that collects user preferences through wizard pages
- **PowerShell Engine** (`install-wheels.ps1`): Handles actual installation logic, downloads, and CommandBox setup
- **Communication**: Status files and logging system coordinate between components

**Parameter Flow:**
```
UI Controls → Pascal Functions → PowerShell Command Line → Installation Logic
```

## Making Changes

### Adding New Templates
1. Update template radio buttons in `InitializeWizard()` function
2. Modify `GetTemplate()` function to return new template identifier
3. Verify template exists on ForgeBox
4. Test installation with new template

### Adding New CFML Engines
1. Add engine radio button in engine selection page
2. Update `GetEngine()` function in Pascal code
3. Test engine installation via CommandBox
4. Verify compatibility with existing templates

### Modifying Installation Logic
1. Edit PowerShell functions in appropriate `#region` blocks
2. Maintain consistent logging using `Write-Log` functions
3. Update error handling with `Write-LogError`
4. Add status reporting for new features

### UI Improvements
1. Modify wizard pages in `InitializeWizard()`
2. Add parameter validation in `NextButtonClick()`
3. Update getter functions for new parameters
4. Test parameter passing to PowerShell

## Testing Your Changes

### Local Testing
1. Build installer in Inno Setup (F9 key)
2. Test on clean Windows system (VM recommended)
3. Verify all wizard pages work correctly
4. Test installation completion and error scenarios
5. Check log files: `%TEMP%\wheels-installation.log`
6. Verify status file: `%TEMP%\wheels-install-status.txt`

### PowerShell Testing
Test PowerShell script directly:
```powershell
.\install-wheels.ps1 -AppName "TestApp" -Template "wheels-base-template@BE"

# Check logs
Get-Content "$env:TEMP\wheels-installation.log" -Tail 20
```

### Edge Case Testing
- Existing CommandBox installation
- Network connectivity issues
- Limited user permissions
- Installation cancellation
- Java version compatibility

## Code Quality Standards

### PowerShell Guidelines
- Use approved PowerShell verbs (`Install-`, `Get-`, `Set-`)
- Maintain consistent logging format: `[YYYY-MM-DD HH:MM:SS.fff] [LEVEL] Message`
- Always use try/catch with `Write-LogError` for errors
- Add functions to appropriate `#region` blocks

### Inno Setup Guidelines
- Use CamelCase for function names
- Keep getter functions simple (return values only)
- Add input validation in `NextButtonClick()`
- Document complex Pascal logic with comments

### Communication Protocol
- PowerShell writes status to single file: `%TEMP%\wheels-install-status.txt`
- Status format: Line 1 = exit code, Line 2 = log file path
- Guard variables prevent duplicate status writes
- Inno Setup reads status file and displays appropriate message

## Building and Packaging

### Build Process
1. Open `install-wheels.iss` in Inno Setup Compiler
2. Press F9 or Build → Compile
3. Output generated: `installer\wheels-installer.exe`
4. Test installer on clean Windows system

### Version Management
Update version in Inno Setup `[Setup]` section:
```pascal
AppVersion=1.0
```

## Contributing Process

Follow the standard Wheels contribution process:

1. **Open an Issue**: Before making changes, open an issue in the [issue tracker](https://github.com/wheels-dev/wheels/issues) describing your proposed changes
2. **Get Approval**: Wait for core team approval before starting development
3. **Fork and Branch**: Create a feature branch from `develop`
4. **Make Changes**: Implement your changes following the guidelines above
5. **Test Thoroughly**: Test on clean Windows systems with different scenarios
6. **Submit Pull Request**: Create a pull request to the `develop` branch, before creating a PR, please also review [Contributing to Wheels](working-with-wheels/contributing-to-wheels.md) and [Submitting Pull Requests](submitting-pull-requests.md) guide
7. **Code Review**: Address any feedback from the core team

### Pull Request Guidelines
- Reference the issue number in your PR description
- Include clear commit messages describing changes
- Test installer on multiple Windows versions if possible
- Update documentation for user-facing changes
- Ensure no breaking changes without proper consideration

## Reporting Issues

Found a bug or have a feature request for the Windows installer?

**[Report Issues](https://github.com/wheels-dev/wheels/issues)**

When reporting installer-specific issues, please include:
- Windows version (10/11)
- PowerShell version (`$PSVersionTable.PSVersion`)
- Installation log file (`%TEMP%\wheels-installation.log`)
- Steps to reproduce the issue
- Expected vs. actual behavior
- Any error messages or dialog screenshots

## Debugging

### Log Analysis
```powershell
# View installation logs
Get-Content "$env:TEMP\wheels-installation.log"

# Filter for errors
Get-Content "$env:TEMP\wheels-installation.log" | Select-String "ERROR|CRITICAL"

# Monitor logs in real-time
Get-Content "$env:TEMP\wheels-installation.log" -Wait -Tail 10
```

### Common Issues
- **Status shows -1**: PowerShell script terminated unexpectedly, check execution policy
- **Parameter issues**: Add debug output to Pascal getter functions
- **Installation failures**: Review detailed logs for specific error messages

## Release Process

Installer releases follow the main Wheels release cycle:

1. Changes are merged to `develop` branch
2. During Wheels release preparation, installer version is updated
3. Installer is built and tested on multiple Windows systems
4. Final installer executable is included in release assets
5. Installation instructions updated in main documentation

## Support

For help with installer development:
- **[Community Discussions](https://github.com/wheels-dev/wheels/discussions)** - Ask questions and share ideas
- **[Issue Tracker](https://github.com/wheels-dev/wheels/issues)** - Report bugs and request features
- **[Wheels Documentation](https://wheels.dev)** - Complete framework documentation