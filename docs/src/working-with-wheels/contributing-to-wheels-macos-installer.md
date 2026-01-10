# Contributing to Wheels macOS Installer

## Repository

The Wheels macOS Installer is located in the main Wheels repository at `tools/installer/macos/`:

**[GitHub Repository](https://github.com/wheels-dev/wheels/tree/develop/tools/installer/macos)**

## Development Setup

### Prerequisites
- macOS 10.13+ (High Sierra or later)
- Xcode Command Line Tools
- Git
- Internet connection for downloads

### Initial Setup

1. **Install Xcode Command Line Tools:**
   ```bash
   xcode-select --install
   ```

2. **Verify Swift installation:**
   ```bash
   swift --version
   # Should show Swift 5.7+ (included with Xcode CLT)
   ```

3. **Clone the Wheels repository:**
   ```bash
   git clone https://github.com/wheels-dev/wheels.git
   cd wheels/tools/installer/macos
   ```

4. **Build the installer:**
   ```bash
   ./build-swift.sh
   ```

5. **Test the installer:**
   ```bash
   open installer/wheels-installer.app
   ```

## Installer Structure

```
tools/installer/macos/
├── WheelsInstallerApp.swift    # Swift GUI application
├── install-wheels              # Bash installation script
├── Info.plist                  # App bundle configuration
├── build-swift.sh              # Build script (creates .app)
├── create-dmg.sh               # DMG creation script
├── assets/                     # App icons and resources
│   └── wheels_logo.icns        # Wheels Logo
├── installer/                  # Build output directory
│   ├── wheels-installer.app    # Built application
│   └── wheels-installer.dmg    # Distributable DMG
└── README.md                   # Developer technical guide
```

## Architecture Overview

The installer uses a two-component architecture:

- **Swift GUI** (`WheelsInstallerApp.swift`): Native macOS interface built with SwiftUI that collects user preferences
- **Bash Script** (`install-wheels`): Handles actual installation logic, downloads, and CommandBox setup
- **Communication**: Command-line arguments and real-time output streaming coordinate between components

**Parameter Flow:**
```
UI Controls → Swift State → Command Line Arguments → Bash Script → Installation
```

## Making Changes

### After Editing Swift UI

When you modify `WheelsInstallerApp.swift`:

```bash
# Rebuild the app
./build-swift.sh

# Test your changes
open installer/wheels-installer.app
```

### After Editing Bash Script

When you modify `install-wheels`:

```bash
# Option 1: Test script directly (no GUI)
./install-wheels --app-name "TestApp" --template "wheels-base-template@BE"

# Option 2: Rebuild and test with GUI
./build-swift.sh
open installer/wheels-installer.app
```

### After Editing Configuration

When you modify `Info.plist`:

```bash
# Rebuild to apply changes
./build-swift.sh

# Verify changes
open installer/wheels-installer.app
```

### Adding New Templates

1. **Edit** `WheelsInstallerApp.swift`
2. Find the template Picker (around line 150)
3. Add your template:
   ```swift
   Picker("Template:", selection: $template) {
       Text("3.0.x Bleeding Edge").tag("wheels-base-template@BE")
       Text("Your New Template").tag("your-template-name")  // Add here
   }
   ```
4. **Rebuild and test:**
   ```bash
   ./build-swift.sh
   open installer/wheels-installer.app
   ```

### Adding New CFML Engines

1. **Edit** `WheelsInstallerApp.swift`
2. Find the engine Picker (around line 160)
3. Add your engine:
   ```swift
   Picker("CFML Engine:", selection: $cfmlEngine) {
       Text("Lucee (Latest)").tag("lucee")
       Text("Your Engine").tag("your-engine")  // Add here
   }
   ```
4. **Rebuild and test:**
   ```bash
   ./build-swift.sh
   open installer/wheels-installer.app
   ```

### Updating CommandBox Version

1. **Edit** `install-wheels` (around line 16)
2. Change version:
   ```bash
   readonly COMMANDBOX_VERSION="6.3.0"  # Update here
   ```
3. **Rebuild:**
   ```bash
   ./build-swift.sh
   ```

### Updating Java Version

1. **Edit** `install-wheels` (around line 17)
2. Change version:
   ```bash
   readonly MINIMUM_JAVA_VERSION=21  # Update here
   ```
3. **Rebuild:**
   ```bash
   ./build-swift.sh
   ```

### Modifying Installation Logic

1. Edit functions in `install-wheels` script
2. Maintain consistent logging format: `[HH:MM:SS] LEVEL: Message`
3. Use logging functions: `log_info()`, `log_success()`, `log_error()`
4. Test script directly before embedding in app

## Testing Your Changes

### Quick Test (Script Only)

```bash
./install-wheels \
  --app-name "TestApp" \
  --template "wheels-base-template@BE" \
  --engine "lucee"
```

### Full Test (With GUI)

```bash
# Build
./build-swift.sh

# Run
open installer/wheels-installer.app

# Monitor logs in another terminal
tail -f /tmp/wheels-installation.log
```

### Test on Different macOS Versions

Recommended test matrix:
- macOS 11 (Big Sur)
- macOS 12 (Monterey)
- macOS 13 (Ventura)
- macOS 14 (Sonoma)

Test on both architectures:
- Intel Mac
- Apple Silicon Mac (M1/M2/M3)

### Edge Case Testing
- Existing CommandBox installation
- Network connectivity issues
- Limited user permissions
- Installation cancellation
- Java version compatibility
- Port 8080 already in use

## Code Quality Standards

### Swift Guidelines
- Use `@State` for UI state management
- Keep UI declarative with SwiftUI
- Handle errors gracefully with try/catch
- Use `DispatchQueue` for background work
- Maintain separation between UI and business logic

### Bash Guidelines
- Use strict mode: `set -e` and `set -u`
- Quote all variables: `"$VARIABLE"`
- Use `readonly` for constants
- Use `[[` instead of `[` for conditionals
- Maintain consistent logging format
- Use functions for reusability

### Logging Standards
```bash
log_info "Starting operation..."
log_success "Operation completed successfully"
log_error "Operation failed"
log_section "MAJOR STEP HEADING"
```

## Building and Packaging

### Build for Testing

```bash
# Build the .app
./build-swift.sh

# Test locally
open installer/wheels-installer.app
```

### Build for Distribution

```bash
# 1. Update version in Info.plist
# Edit CFBundleShortVersionString

# 2. Build the .app
./build-swift.sh

# 3. Create DMG
./create-dmg.sh

# 4. Test DMG
open installer/wheels-installer.dmg

# 5. DMG ready at: installer/wheels-installer.dmg
```

### Version Management

Update version in `Info.plist`:
```xml
<key>CFBundleShortVersionString</key>
<string>1.0.0</string>
```

## Contributing Process

Follow the standard Wheels contribution process:

1. **Open an Issue**: Before making changes, open an issue in the [issue tracker](https://github.com/wheels-dev/wheels/issues) describing your proposed changes
2. **Get Approval**: Wait for core team approval before starting development
3. **Fork and Branch**: Create a feature branch from `develop`
4. **Make Changes**: Implement your changes following the guidelines above
5. **Test Thoroughly**: Test on multiple macOS versions and architectures
6. **Submit Pull Request**: Create a pull request to the `develop` branch, before creating a PR, please also review [Contributing to Wheels](contributing-to-wheels.md) and [Submitting Pull Requests](submitting-pull-requests.md) guide
7. **Code Review**: Address any feedback from the core team

### Pull Request Guidelines
- Reference the issue number in your PR description
- Include clear commit messages describing changes
- Test installer on both Intel and Apple Silicon if possible
- Update documentation for user-facing changes
- Ensure no breaking changes without proper consideration

## Reporting Issues

Found a bug or have a feature request for the macOS installer?

**[Report Issues](https://github.com/wheels-dev/wheels/issues)**

When reporting installer-specific issues, please include:
- macOS version (e.g., macOS 14.1)
- Mac architecture (Intel or Apple Silicon)
- Swift version (`swift --version`)
- Installation log file (`/tmp/wheels-installation.log`)
- Steps to reproduce the issue
- Expected vs. actual behavior
- Any error messages or screenshots

## Debugging

### View Installation Logs

```bash
# View full log
cat /tmp/wheels-installation.log

# View recent entries
tail -n 50 /tmp/wheels-installation.log

# Watch log in real-time
tail -f /tmp/wheels-installation.log

# Search for errors
grep "ERROR" /tmp/wheels-installation.log
```

### Debug Mode

Enable debug mode in `install-wheels`:
```bash
# Add at top of script
set -x  # Shows each command as it runs
```

### Test Script Without GUI

```bash
# Run script directly with parameters
./install-wheels \
  --app-name "DebugTest" \
  --template "wheels-base-template@BE" \
  --engine "lucee" \
  --use-bootstrap
```

### Common Issues

- **Build fails**: Ensure Xcode Command Line Tools are installed (`xcode-select --install`)
- **App won't open**: Remove quarantine attribute (`xattr -d com.apple.quarantine installer/wheels-installer.app`)
- **Script changes not working**: Remember to rebuild after script changes (`./build-swift.sh`)
- **Installation fails**: Check logs at `/tmp/wheels-installation.log`

## Code Signing & Notarization

For public distribution, you need:

1. **Apple Developer Account** ($99/year)
2. **Developer ID Certificate**
3. **App Store Connect API key** (for notarization)

### Code Signing

```bash
# Sign the app
codesign --deep --force --verify --verbose \
         --sign "Developer ID Application: Your Name (TEAM_ID)" \
         installer/wheels-installer.app

# Verify signature
codesign --verify --verbose installer/wheels-installer.app
```

### Notarization

```bash
# 1. Create ZIP for notarization
ditto -c -k --keepParent installer/wheels-installer.app wheels-installer.zip

# 2. Submit for notarization
xcrun notarytool submit wheels-installer.zip \
    --apple-id "your@email.com" \
    --team-id "TEAM_ID" \
    --password "app-specific-password" \
    --wait

# 3. Staple notarization ticket
xcrun stapler staple installer/wheels-installer.app

# 4. Create DMG
./create-dmg.sh

# 5. Notarize DMG
xcrun notarytool submit installer/wheels-installer.dmg \
    --apple-id "your@email.com" \
    --team-id "TEAM_ID" \
    --password "app-specific-password" \
    --wait

# 6. Staple ticket to DMG
xcrun stapler staple installer/wheels-installer.dmg
```

## Release Process

Installer releases follow the main Wheels release cycle:

1. Changes are merged to `develop` branch
2. During Wheels release preparation, installer version is updated
3. Installer is built and tested on multiple macOS systems
4. DMG is created and code signed/notarized
5. Final DMG is included in release assets
6. Installation instructions updated in main documentation

## Support

For help with installer development:
- **[Community Discussions](https://github.com/wheels-dev/wheels/discussions)** - Ask questions and share ideas
- **[Issue Tracker](https://github.com/wheels-dev/wheels/issues)** - Report bugs and request features
- **[Wheels Documentation](https://wheels.dev)** - Complete framework documentation

---

**Remember**: Always rebuild with `./build-swift.sh` after making any code changes!
