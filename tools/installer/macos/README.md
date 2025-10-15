# Wheels macOS Installer - Developer Guide

Welcome! This guide will help you understand and work with the Wheels macOS installer.

## What This Is

A **native macOS installer** that makes it easy to install Wheels Framework on Mac computers.

The installer has two main parts:
- **Swift GUI**: A user-friendly interface built with SwiftUI
- **Bash Script**: The installation logic that does the actual work

The installer automatically:
- Downloads and installs CommandBox
- Installs the Wheels CLI
- Creates a new Wheels application
- Starts your development server

Works on both Intel and Apple Silicon Macs.

## File Overview

```
tools/installer/macos/
├── WheelsInstallerApp.swift    # Swift GUI application
├── install-wheels              # Bash installation script
├── Info.plist                  # App bundle configuration
├── build-swift.sh              # Build script (creates .app)
├── create-dmg.sh               # DMG creation script
├── assets/                     # App icons and resources
│   └── wheels_logo.icns        # Built application
├── installer/                  # Build output directory
│   ├── wheels-installer.app    # Built application
│   └── wheels-installer.dmg    # Distributable DMG
└── README.md                   # This developer guide
```

## Code Architecture

### 1. Swift GUI Application (`WheelsInstallerApp.swift`)
**Language**: Swift
**Purpose**: Native macOS UI that collects parameters and executes Bash script

#### Key Components:

**Main Window (`ContentView`)**:
- Welcome screen
- Configuration form with text fields and pickers
- Real-time validation
- Native macOS controls (TextField, Picker, Toggle, Button)

**Configuration Options**:
```swift
- installPath: CommandBox installation location
- appName: Wheels application name
- reloadPassword: Application reload password
- datasourceName: Database datasource name
- template: Wheels app template selection (5 options)
- cfmlEngine: CFML engine selection (7 options)
- appBasePath: Application installation location
- useH2: Use H2 embedded database (Lucee only)
- useBootstrap: Include Bootstrap CSS
- initPackage: Initialize as CommandBox package
- force: Force reinstall CommandBox
```

**Installation Process (`InstallationView`)**:
- Real-time output display from Bash script
- Progress monitoring
- Scrollable output window
- Success/error handling
- Server URL capture and display

**Process Management**:
```swift
func runInstaller() {
    // Builds command with parameters
    // Executes install-wheels script
    // Captures output in real-time
    // Detects server URL from output
    // Shows completion status
}
```

#### Parameter Flow:
```
UI Controls → Swift State → Command Line Arguments → install-wheels script
```

**Example Command Generated**:
```bash
/path/to/install-wheels \
  --install-path "/Users/username/Desktop/commandbox" \
  --app-name "MyWheelsApp" \
  --reload-password "changeMe" \
  --datasource-name "MyWheelsApp" \
  --template "wheels-base-template@BE" \
  --engine "lucee" \
  --app-base-path "/Users/username/Desktop/Sites" \
  --use-h2 \
  --use-bootstrap \
  --init-package
```

### 2. Bash Installation Script (`install-wheels`)
**Language**: Bash
**Purpose**: Actual installation logic, downloads, and configuration

#### Key Architecture:
```bash
#!/bin/bash
set -e  # Exit on error
set -u  # Exit on undefined variable

# Configuration constants
readonly COMMANDBOX_VERSION="6.2.1"
readonly MINIMUM_JAVA_VERSION=17

# Logging functions
log_info()
log_success()
log_error()
log_section()

# Installation functions
check_java()              # Verify/install Java 17+
install_commandbox()      # Download and install CommandBox
add_to_path()            # Add CommandBox to shell PATH
install_wheels_cli()     # Install Wheels CLI from ForgeBox
create_application()     # Create Wheels app from template
start_server()           # Start development server
show_completion()        # Display success message
```

## Communication Between Components

### Command Line Arguments
**Method**: Swift passes configuration as command-line arguments
**Format**: `--flag value` or `--boolean-flag`

Swift builds the command dynamically:
```swift
var command = [scriptPath]
command.append(contentsOf: ["--install-path", installPath])
command.append(contentsOf: ["--app-name", appName])
if useH2 { command.append("--use-h2") }
// etc...
```

Bash parses arguments:
```bash
while [[ $# -gt 0 ]]; do
    case $1 in
        --install-path)
            INSTALL_PATH="$2"
            shift 2
            ;;
        --use-h2)
            USE_H2=true
            shift
            ;;
    esac
done
```

### Real-time Output Streaming

Swift captures stdout/stderr in real-time:
```swift
let pipe = Pipe()
process.standardOutput = pipe
process.standardError = pipe

let outputHandle = pipe.fileHandleForReading
outputHandle.readabilityHandler = { handle in
    let data = handle.availableData
    if let output = String(data: data, encoding: .utf8) {
        DispatchQueue.main.async {
            self.output += output
            self.parseServerURL(from: output)
        }
    }
}
```

### Server URL Detection

Swift monitors output for server URL pattern:
```swift
func parseServerURL(from output: String) {
    let pattern = #"http://[^\s]+"#
    if let range = output.range(of: pattern, options: .regularExpression) {
        serverURL = String(output[range])
    }
}
```

### Logging System
**File**: `/tmp/wheels-installation.log`
**Format**: `[HH:MM:SS] LEVEL: Message`

**Features**:
- Persistent across runs
- Session markers separate attempts
- Multiple levels: INFO, SUCCESS, ERROR

## Quick Start for Developers

### First Time Setup

1. **Install Xcode Command Line Tools**
   ```bash
   xcode-select --install
   ```

2. **Clone the Repository**
   ```bash
   git clone https://github.com/wheels-dev/wheels.git
   cd wheels/tools/installer/macos
   ```

3. **Build the Installer**
   ```bash
   ./build-swift.sh
   ```

4. **Test It**
   ```bash
   open installer/wheels-installer.app
   ```

That's it! You're ready to develop.

## Making Changes

### You Changed the Swift UI

After editing `WheelsInstallerApp.swift`:

```bash
# Rebuild
./build-swift.sh

# Test
open installer/wheels-installer.app
```

### You Changed the Bash Script

After editing `install-wheels`:

```bash
# Option 1: Test the script directly (no GUI)
./install-wheels --app-name "TestApp" --template "wheels-base-template@BE"

# Option 2: Rebuild and test with GUI
./build-swift.sh
open installer/wheels-installer.app
```

### You Changed the Configuration

After editing `Info.plist`:

```bash
# Rebuild
./build-swift.sh

# Verify
open installer/wheels-installer.app
```

## Creating a Release

### For Testing (Internal)

```bash
# Build
./build-swift.sh

# Share the .app file
open installer/
# Send wheels-installer.app to testers
```

### For Distribution (Public)

```bash
# 1. Update version in Info.plist
# Edit CFBundleShortVersionString

# 2. Build
./build-swift.sh

# 3. Create DMG
./create-dmg.sh

# 4. Test DMG
open installer/wheels-installer.dmg

# 5. Upload to GitHub Releases
# The DMG is at: installer/wheels-installer.dmg
```

## Common Tasks

### Add a New Template Option

**Edit:** `WheelsInstallerApp.swift`

Find the template Picker (around line 150):
```swift
Picker("Template:", selection: $template) {
    Text("3.0.x Bleeding Edge").tag("wheels-base-template@BE")
    Text("2.5.x Stable").tag("wheels-base-template@stable")
    Text("Your New Template").tag("your-template-name")  // Add here
}
```

**Then:**
```bash
./build-swift.sh
open installer/wheels-installer.app
```

### Add a New CFML Engine

**Edit:** `WheelsInstallerApp.swift`

Find the engine Picker (around line 160):
```swift
Picker("CFML Engine:", selection: $cfmlEngine) {
    Text("Lucee (Latest)").tag("lucee")
    Text("Adobe ColdFusion").tag("adobe")
    Text("Your Engine").tag("your-engine")  // Add here
}
```

**Then:**
```bash
./build-swift.sh
open installer/wheels-installer.app
```

### Change CommandBox Version

**Edit:** `install-wheels`

Find (around line 16):
```bash
readonly COMMANDBOX_VERSION="6.2.1"
```

Change to new version:
```bash
readonly COMMANDBOX_VERSION="6.3.0"
```

**Then:**
```bash
./build-swift.sh
open installer/wheels-installer.app
```

### Change Minimum Java Version

**Edit:** `install-wheels`

Find (around line 17):
```bash
readonly MINIMUM_JAVA_VERSION=17
```

Change to new version:
```bash
readonly MINIMUM_JAVA_VERSION=21
```

**Then:**
```bash
./build-swift.sh
open installer/wheels-installer.app
```

## Testing Your Changes

### Quick Test (Just the Script)

```bash
./install-wheels \
  --app-name "TestApp" \
  --template "wheels-base-template@BE"
```

### Full Test (With GUI)

```bash
# Build
./build-swift.sh

# Run
open installer/wheels-installer.app

# Check logs
tail -f /tmp/wheels-installation.log
```

### Test on Different macOS Versions

Recommended test matrix:
- macOS 11 (Big Sur)
- macOS 12 (Monterey)
- macOS 13 (Ventura)
- macOS 14 (Sonoma)

Test on both:
- Intel Mac
- Apple Silicon Mac (M1/M2/M3)

## Troubleshooting

### Build Error: "Swift compiler not found"

**Solution:**
```bash
xcode-select --install
swift --version
```

### App Won't Open: "Unidentified developer"

**Solution:**
```bash
xattr -d com.apple.quarantine installer/wheels-installer.app
# Or: Right-click → Open
```

### Installation Fails

**Check logs:**
```bash
cat /tmp/wheels-installation.log
```

### Script Changes Not Working

**Make sure you rebuilt:**
```bash
./build-swift.sh
```

The script is embedded in the .app, so you must rebuild after changes.

## How It Works

### The Simple Version

1. User opens `wheels-installer.app`
2. Swift GUI collects preferences
3. GUI runs the `install-wheels` bash script
4. Script downloads CommandBox
5. Script installs Wheels CLI
6. Script creates the application
7. Script starts the server
8. GUI shows the results

### Command Flow

```
User Input → Swift GUI → Bash Script → Installation
```

Example command generated:
```bash
/path/to/install-wheels \
  --install-path "/Users/john/Desktop/commandbox" \
  --app-name "MyApp" \
  --template "wheels-base-template@BE" \
  --engine "lucee" \
  --use-bootstrap
```

## Important Files Explained

### `WheelsInstallerApp.swift`
The GUI. Written in Swift/SwiftUI. Collects user input and runs the bash script.

**Main sections:**
- `ContentView`: The configuration form
- `InstallationView`: Shows output during installation
- `runInstaller()`: Executes the bash script

### `install-wheels`
The installation script. Written in Bash. Does the actual work.

**Main functions:**
- `check_java()`: Verifies/installs Java
- `install_commandbox()`: Downloads and installs CommandBox
- `install_wheels_cli()`: Installs Wheels CLI
- `create_application()`: Creates the Wheels app
- `start_server()`: Starts the dev server

### `Info.plist`
App metadata. Contains version, name, permissions.

**Key fields:**
- `CFBundleShortVersionString`: Version number (e.g., "1.0.0")
- `CFBundleIdentifier`: App ID (com.wheels.installer)
- `CFBundleName`: Display name

### `build-swift.sh`
Automates the build process. Compiles Swift, creates .app bundle, embeds script.

### `create-dmg.sh`
Creates distributable DMG file for end users.

## Code Signing & Notarization

For public distribution, you need:

1. **Apple Developer Account** ($99/year)
2. **Developer ID Certificate**
3. **Code signing**
4. **Notarization**

**Basic code signing:**
```bash
codesign --deep --force --sign "Developer ID Application: Your Name" \
         installer/wheels-installer.app
```

**Notarization (required for macOS 10.15+):**
```bash
# Create ZIP
ditto -c -k --keepParent installer/wheels-installer.app wheels-installer.zip

# Submit for notarization
xcrun notarytool submit wheels-installer.zip \
    --apple-id "your@email.com" \
    --team-id "TEAM_ID" \
    --password "app-specific-password" \
    --wait

# Staple ticket
xcrun stapler staple installer/wheels-installer.app

# Then create DMG
./create-dmg.sh
```

## GitHub Workflow

### Making Changes

```bash
# 1. Create feature branch
git checkout -b fix/my-improvement

# 2. Make changes
# Edit files...

# 3. Build and test
./build-swift.sh
open installer/wheels-installer.app

# 4. Commit
git add .
git commit -m "Improve installer UI"

# 5. Push and create PR
git push origin fix/my-improvement
```

### Creating a Release

```bash
# 1. Update version in Info.plist
# 2. Commit version bump
git commit -am "Bump version to 1.1.0"

# 3. Create tag
git tag -a macos-installer-v1.1.0 -m "macOS Installer v1.1.0"
git push origin macos-installer-v1.1.0

# 4. Build release
./build-swift.sh
./create-dmg.sh

# 5. Upload installer/wheels-installer.dmg to GitHub Releases
```

## Logs & Debugging

### Installation Log
```bash
# View full log
cat /tmp/wheels-installation.log

# Watch in real-time
tail -f /tmp/wheels-installation.log

# Search for errors
grep "ERROR" /tmp/wheels-installation.log
```

### Debug Mode

Enable in `install-wheels`:
```bash
# Add at top of file
set -x  # Shows each command as it runs
```

### Run Script Without GUI
```bash
# Test installation logic directly
./install-wheels \
  --app-name "DevTest" \
  --template "wheels-base-template@BE" \
  --engine "lucee"
```

## Resources

- **Wheels Documentation**: https://wheels.dev
- **Swift Guide**: https://docs.swift.org/swift-book/
- **Bash Reference**: https://www.gnu.org/software/bash/manual/
- **CommandBox Docs**: https://commandbox.ortusbooks.com/

## Getting Help

- **Issues**: https://github.com/wheels-dev/wheels/issues
- **Discussions**: https://github.com/wheels-dev/wheels/discussions

---