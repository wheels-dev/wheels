# Wheels macOS Installer - Developer Guide

This document is for developers working on the Wheels macOS installer.

## What This Is

A **GUI-based macOS installer** that automates the complete setup of Wheels Framework. The installer:
- ✅ Collects user preferences through native macOS dialogs
- ✅ Downloads and installs CommandBox
- ✅ Installs Wheels CLI from ForgeBox
- ✅ Creates a complete Wheels application from templates
- ✅ Starts the development server automatically
- ✅ Provides detailed logging and error handling

**Architecture:**
- **Shell Script** (`install-wheels.sh`) - Core installation logic in Bash
- **Platypus Wrapper** - Converts shell script into native macOS app
- **Native Dialogs** - Uses macOS `osascript` for user input

**Why this architecture?**
- Minimal files in Git (shell script + config = 2 files)
- Native macOS look and feel
- No compilation required (just shell scripting)
- Easy to maintain and debug
- Professional GUI with Platypus

## File Structure

```
tools/installer/macos/
├── install-wheels.sh              # Main installation script (~800 lines)
├── WheelsInstaller.platypus       # Platypus configuration
├── build.sh                       # Build script (creates .app)
├── create-dmg.sh                  # DMG creation script
├── README.md                      # This file
│
├── build/                         # Build output (not in Git)
│   └── WheelsInstaller.app        # Built application
│
└── dmg/                           # Distribution (not in Git)
    └── WheelsInstaller.dmg        # Distributable DMG
```

## Development Setup

### Prerequisites

1. **macOS 10.13+** (High Sierra or later)
2. **Platypus** - App wrapper tool
3. **CommandBox** (for testing)
4. **Git**

### Install Platypus

```bash
# Option 1: Homebrew (recommended)
brew install platypus

# Option 2: Download from website
# https://sveinbjorn.org/platypus
```

Verify installation:
```bash
platypus --version
# Should output: Platypus 5.x
```

### Clone Repository

```bash
git clone https://github.com/wheels-dev/wheels.git
cd wheels/tools/installer/macos
```

## Building the Installer

### Quick Build

```bash
# Build the app
./build.sh

# Output: build/WheelsInstaller.app
```

### Create Distributable DMG

```bash
# Create DMG package
./create-dmg.sh

# Output: dmg/WheelsInstaller.dmg
```

### Complete Build Process

```bash
# 1. Build the app
./build.sh

# 2. Test the app
open build/WheelsInstaller.app

# 3. Create DMG for distribution
./create-dmg.sh

# 4. Upload DMG to GitHub Releases
```

## How It Works

### Installation Flow

```
User opens WheelsInstaller.app
        ↓
Shell script runs with GUI dialogs (Platypus)
        ↓
Collect user preferences via osascript dialogs:
  - CommandBox installation path
  - Application name and configuration
  - Template selection (5 options)
  - CFML engine selection (7 options)
  - Additional options
        ↓
Download CommandBox from Ortus Solutions
        ↓
Install CommandBox to specified path
        ↓
Add CommandBox to PATH (~/.zshrc or ~/.bash_profile)
        ↓
Install Wheels CLI from ForgeBox
        ↓
Create Wheels application using selected template
        ↓
Configure application (datasource, password, etc.)
        ↓
Start development server
        ↓
Show completion dialog with server URL
        ↓
Open browser to Wheels documentation
```

### User Interface (Native Dialogs)

The installer uses macOS native dialogs via `osascript`:

**Text Input:**
```bash
APP_NAME=$(osascript -e 'text returned of (display dialog "Application Name:" default answer "MyWheelsApp")')
```

**Yes/No Question:**
```bash
osascript -e 'button returned of (display dialog "Force reinstall CommandBox?" buttons {"Yes", "No"} default button "No")'
```

**Choice Selection:**
```bash
osascript -e 'choose from list {"Template 1", "Template 2"} with prompt "Select Template:"'
```

**Progress Notification:**
```bash
osascript -e 'display notification "Installing CommandBox..." with title "Wheels Installer"'
```

## Making Changes

### Adding New Templates

Edit `install-wheels.sh`, find the template selection section:

```bash
# Around line 580
local templates=(
    "wheels-base-template@BE - 3.0.x Bleeding Edge"
    "wheels-base-template@stable - 2.5.x Stable"
    "wheels-htmx-template - HTMX + Alpine.js"
    "wheels-starter-template - Starter App"
    "wheels-todomvc-template - TodoMVC Demo"
    "your-new-template - Your New Template"  # Add here
)
```

Then add the mapping:

```bash
# Around line 600
case "$selected_template" in
    *"Your New Template"*) TEMPLATE="your-new-template" ;;
    # ...
esac
```

### Adding New CFML Engines

Edit `install-wheels.sh`, find the engine selection section:

```bash
# Around line 620
local engines=(
    "Lucee (Latest)"
    "Adobe ColdFusion (Latest)"
    "Your New Engine"  # Add here
)
```

Then add the mapping:

```bash
# Around line 640
case "$selected_engine" in
    "Your New Engine") CFML_ENGINE="your-engine@version" ;;
    # ...
esac
```

### Modifying Installation Logic

The script is organized into sections (search for `# ===`):

```bash
# Configuration
# Global Variables
# GUI Detection
# Logging Functions
# GUI Functions
# Utility Functions
# System Detection
# Download Functions
# Installation Functions
# Application Creation
# User Configuration
# Main Installation
```

Add your functions to the appropriate section and maintain the logging pattern:

```bash
my_custom_function() {
    log_info "Starting custom operation..."
    show_progress "Processing..." 50

    # Your logic here

    if ! some_command; then
        stop_with_error "Operation failed" "Details..."
    fi

    log_success "Custom operation completed"
    show_progress "Complete" 100
}
```

### Updating Configuration

Edit the Configuration section at the top of `install-wheels.sh`:

```bash
# =============================
# Configuration
# =============================
readonly COMMANDBOX_VERSION="6.2.1"          # Update version here
readonly MINIMUM_JAVA_VERSION=11              # Update minimum Java
readonly WHEELS_CLI_PACKAGE="wheels-cli"
readonly COMMANDBOX_DOWNLOAD_URL="https://..."  # Update URL
```

## Testing

### Manual Testing

```bash
# Test shell script directly (no GUI)
bash install-wheels.sh

# Test with GUI (built app)
open build/WheelsInstaller.app

# Test DMG
open dmg/WheelsInstaller.dmg
# Then double-click WheelsInstaller.app
```

### Testing Checklist

- [ ] Fresh installation (no existing CommandBox)
- [ ] Upgrade scenario (CommandBox already installed)
- [ ] Force reinstallation option
- [ ] All 5 template options
- [ ] All 7 CFML engine options
- [ ] H2 database option (Lucee only)
- [ ] Bootstrap option (enabled/disabled)
- [ ] Package initialization option
- [ ] Custom installation paths
- [ ] Application name validation
- [ ] Network failure handling
- [ ] User cancellation at various stages
- [ ] Permissions handling
- [ ] Server startup verification
- [ ] PATH addition to shell config

### Log Files

Check logs during testing:

```bash
# View installation log
cat /tmp/wheels-installation.log

# View status file
cat /tmp/wheels-install-status.txt

# Monitor log in real-time
tail -f /tmp/wheels-installation.log
```

### Testing on Different macOS Versions

Test on:
- macOS 10.13 (High Sierra) - Minimum supported
- macOS 11 (Big Sur)
- macOS 12 (Monterey)
- macOS 13 (Ventura)
- macOS 14 (Sonoma)
- macOS 15 (Sequoia)

## Code Quality Standards

### Shell Script Best Practices

```bash
# ✅ Good: Use strict mode
set -e  # Exit on error
set -u  # Exit on undefined variable

# ✅ Good: Use readonly for constants
readonly COMMANDBOX_VERSION="6.2.1"

# ✅ Good: Quote variables
if [[ "$APP_NAME" == "test" ]]; then

# ❌ Bad: Unquoted variables
if [[ $APP_NAME == test ]]; then

# ✅ Good: Use [[ ]] instead of [ ]
if [[ -f "$file" ]]; then

# ✅ Good: Use functions for reusability
download_file() {
    local url="$1"
    local output="$2"
    # ...
}

# ✅ Good: Error handling
if ! some_command; then
    log_error "Command failed"
    return 1
fi
```

### Logging Standards

```bash
# Use consistent logging functions
log_info "Information message"
log_success "Success message"
log_warning "Warning message"
log_error "Error message"

# Use log sections for major steps
log_section "COMMANDBOX INSTALLATION"

# Always log before operations
log_info "Downloading CommandBox..."
download_file "$url" "$output"
log_success "Download complete"
```

### Error Handling

```bash
# Always check command success
if ! command_that_might_fail; then
    stop_with_error "Operation failed" "Additional details..."
fi

# Use trap for cleanup
trap cleanup_temp_files EXIT

# Provide helpful error messages
stop_with_error "Failed to create directory" \
    "Path: $dir\nThis could be due to insufficient permissions."
```

## Distribution

### Creating Release DMG

```bash
# 1. Build the app
./build.sh

# 2. Create DMG
./create-dmg.sh

# 3. DMG is ready at: dmg/WheelsInstaller.dmg
```

### Code Signing (Optional)

For distribution outside the Mac App Store:

```bash
# Sign the app
codesign --deep --force --verify --verbose \
         --sign "Developer ID Application: Your Name" \
         build/WheelsInstaller.app

# Verify signature
codesign --verify --verbose build/WheelsInstaller.app
spctl --assess --verbose build/WheelsInstaller.app
```

### Notarization (Required for macOS 10.15+)

```bash
# 1. Create a zip for notarization
ditto -c -k --keepParent build/WheelsInstaller.app WheelsInstaller.zip

# 2. Submit for notarization
xcrun notarytool submit WheelsInstaller.zip \
    --apple-id "your@email.com" \
    --team-id "TEAM_ID" \
    --password "app-specific-password" \
    --wait

# 3. Staple the notarization ticket
xcrun stapler staple build/WheelsInstaller.app

# 4. Now create DMG
./create-dmg.sh
```

### GitHub Release Process

1. Build and test the installer
2. Create DMG package
3. Create GitHub release/tag
4. Upload DMG as release asset
5. Update installation documentation

## Troubleshooting

### Common Issues

#### Issue: "WheelsInstaller.app" can't be opened because it is from an unidentified developer

**Solution for users:**
```bash
# Right-click → Open, or:
xattr -cr WheelsInstaller.app
```

**Solution for developers:** Code sign and notarize the app

#### Issue: Platypus not found

**Solution:**
```bash
brew install platypus
```

#### Issue: CommandBox download fails

**Solution:**
- Check internet connection
- Verify CommandBox download URL is current
- Check firewall/proxy settings

#### Issue: Permission denied when installing

**Solution:**
- Choose a user-writable installation path
- Or run with admin privileges (not recommended)

#### Issue: Server doesn't start

**Solution:**
- Check port 8080 is not in use
- Check Java is installed (or CommandBox JRE works)
- Check application was created successfully

### Debugging

#### Enable Debug Mode

```bash
# Add to top of install-wheels.sh
set -x  # Print commands as they execute
```

#### View Detailed Logs

```bash
# Watch log in real-time
tail -f /tmp/wheels-installation.log

# Search for errors
grep "ERROR" /tmp/wheels-installation.log

# View last 50 lines
tail -n 50 /tmp/wheels-installation.log
```

#### Test Script Without GUI

```bash
# Run script directly (bypasses Platypus)
bash install-wheels.sh

# This runs without GUI dialogs and shows all output
```

## Contributing

### Contribution Process

1. **Open an Issue** - Describe proposed changes
2. **Get Approval** - Wait for core team approval
3. **Fork and Branch** - Create feature branch from `develop`
4. **Make Changes** - Follow shell scripting best practices
5. **Test Thoroughly** - Test on multiple macOS versions
6. **Submit PR** - Create pull request to `develop` branch

### Pull Request Guidelines

- Reference issue number in PR description
- Test on at least 2 different macOS versions
- Update README for user-facing changes
- Maintain code style consistency
- Add comments for complex logic
- Update version number if needed

### Code Review Checklist

- [ ] Shell script follows best practices
- [ ] Error handling is comprehensive
- [ ] Logging is consistent and helpful
- [ ] User dialogs are clear and friendly
- [ ] Changes are tested on real hardware
- [ ] Documentation is updated
- [ ] No breaking changes without discussion

## Architecture Decisions

### Why Platypus?

- ✅ Minimal files in Git (just shell script + config)
- ✅ Native macOS look and feel
- ✅ No compilation required
- ✅ Easy to maintain (shell scripting)
- ✅ Professional progress bars and UI
- ✅ Free and open source

### Why Shell Script Instead of Swift?

- ✅ Minimal repository footprint (1 file vs hundreds)
- ✅ No Xcode project files
- ✅ Easy to edit and test
- ✅ No compilation step
- ✅ Portable (runs on any macOS with Bash)
- ✅ Easy to debug

### Why Native Dialogs (osascript)?

- ✅ Built into macOS (no dependencies)
- ✅ Familiar macOS UI
- ✅ AppleScript is stable and well-documented
- ✅ Works on all macOS versions

## Resources

### Documentation

- **Platypus Documentation**: https://sveinbjorn.org/platypus
- **Bash Scripting Guide**: https://www.gnu.org/software/bash/manual/
- **AppleScript Guide**: https://developer.apple.com/library/archive/documentation/AppleScript/
- **CommandBox Documentation**: https://commandbox.ortusbooks.com/
- **Wheels Documentation**: https://wheels.dev

### Tools

- **Platypus**: App wrapper for shell scripts
- **VSCode**: Good editor for shell scripts
- **ShellCheck**: Shell script linter (`brew install shellcheck`)

### Testing Tools

```bash
# Validate shell script syntax
bash -n install-wheels.sh

# Run ShellCheck
shellcheck install-wheels.sh

# Test with different shells
bash install-wheels.sh
zsh install-wheels.sh
```

## Comparing to Windows Installer

### Similarities

- Both use GUI wizards
- Both collect same configuration options
- Both perform same installation steps
- Both provide progress feedback
- Both have comprehensive logging
- Both handle errors gracefully

### Differences

| Feature | Windows | macOS |
|---------|---------|-------|
| **GUI Technology** | Inno Setup (Pascal) | Platypus + osascript |
| **Script Language** | PowerShell | Bash |
| **Files in Git** | 2 files (.iss + .ps1) | 2 files (.sh + .platypus) |
| **Package Format** | .exe installer | .dmg disk image |
| **Code Signing** | Authenticode | Apple Developer ID |
| **Distribution** | Direct .exe | DMG with .app inside |

## Future Enhancements

### Potential Improvements

1. **Custom Icons** - Add Wheels logo to app and DMG
2. **Progress Percentages** - More granular progress reporting
3. **Resume Capability** - Resume interrupted installations
4. **Update Checker** - Check for newer versions before installing
5. **Multiple Languages** - i18n support for dialogs
6. **Silent Mode** - Command-line mode with no GUI
7. **Uninstaller** - App to remove Wheels installation

### Extension Points

- Add templates by updating template array and case statement
- Add engines by updating engine array and case statement
- Add options by adding new dialog prompts
- Customize downloads by updating download URLs

---

**Remember**: This installer is a user's first impression of Wheels on macOS. Make it reliable, user-friendly, and delightful!
