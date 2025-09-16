#!/bin/bash

#
# Wheels Framework Installer for macOS and Linux
#
# This script installs CommandBox, Wheels CLI, and all necessary dependencies
# on Unix-based systems. It ensures compatibility by installing modern versions
# of all components and both 'wheels' and 'wheels-cli' packages.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/wheels-dev/wheels/develop/tools/install/install-wheels.sh | bash
#
#   Or download and run locally:
#   ./install-wheels.sh [options]
#
# Options:
#   --install-path PATH    Custom installation directory
#   --force               Force reinstallation
#   --skip-path           Skip adding CommandBox to PATH
#   --help                Show this help message
#

set -euo pipefail

# Configuration
COMMANDBOX_VERSION="6.2.1"
MINIMUM_JAVA_VERSION=11
WHEELS_CLI_PACKAGE="wheels-cli"
WHEELS_PACKAGE="wheels"

# URLs
COMMANDBOX_DOWNLOAD_URL="https://downloads.ortussolutions.com/ortussolutions/commandbox/${COMMANDBOX_VERSION}/commandbox-bin-${COMMANDBOX_VERSION}.zip"
JAVA_CHECK_URL="https://adoptium.net/temurin/releases/?version=17"

# Default values
INSTALL_PATH=""
FORCE=false
SKIP_PATH=false
HELP=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Output functions
log_info() { echo -e "${CYAN}INFO: $1${NC}"; }
log_success() { echo -e "${GREEN}SUCCESS: $1${NC}"; }
log_warning() { echo -e "${YELLOW}WARNING: $1${NC}"; }
log_error() { echo -e "${RED}ERROR: $1${NC}"; }

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --install-path)
                INSTALL_PATH="$2"
                shift 2
                ;;
            --force)
                FORCE=true
                shift
                ;;
            --skip-path)
                SKIP_PATH=true
                shift
                ;;
            --help|-h)
                HELP=true
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
}

# Show help
show_help() {
    cat << EOF

Wheels Framework Installer

This installer will set up CommandBox, Wheels CLI, and all dependencies
ensuring compatibility with modern CFML engines.

Usage: $0 [options]

Options:
  --install-path PATH    Custom installation directory
                        (default: /usr/local/bin or ~/.local/bin)
  --force               Force reinstallation even if components exist
  --skip-path           Skip adding CommandBox to PATH
  --help, -h            Show this help message

Examples:
  $0
  $0 --install-path /opt/commandbox --force
  curl -fsSL https://raw.githubusercontent.com/wheels-dev/wheels/develop/tools/install/install-wheels.sh | bash

Documentation: https://wheels.dev/guides

EOF
}

# Header
show_header() {
    echo ""
    echo -e "${MAGENTA}╔════════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║                           Wheels Framework Installer                          ║${NC}"
    echo -e "${MAGENTA}║                                                                                ║${NC}"
    echo -e "${MAGENTA}║  This installer will set up CommandBox, Wheels CLI, and all dependencies      ║${NC}"
    echo -e "${MAGENTA}║  ensuring compatibility with modern CFML engines.                             ║${NC}"
    echo -e "${MAGENTA}║                                                                                ║${NC}"
    echo -e "${MAGENTA}║  Components installed:                                                         ║${NC}"
    echo -e "${MAGENTA}║  • CommandBox ${COMMANDBOX_VERSION} (CFML CLI & Server)                                    ║${NC}"
    echo -e "${MAGENTA}║  • wheels (Core Wheels package)                                               ║${NC}"
    echo -e "${MAGENTA}║  • wheels-cli (Wheels CLI commands)                                           ║${NC}"
    echo -e "${MAGENTA}╚════════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Detect operating system
detect_os() {
    OS=$(uname -s)
    case $OS in
        Darwin)
            OS_TYPE="mac"
            ;;
        Linux)
            OS_TYPE="linux"
            ;;
        *)
            log_error "Unsupported operating system: $OS"
            exit 1
            ;;
    esac
    log_info "Operating system: $OS_TYPE"
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        IS_ROOT=true
        log_info "Running as root"
    else
        IS_ROOT=false
        log_info "Running as regular user"
    fi
}

# Determine installation path
determine_install_path() {
    if [[ -z "$INSTALL_PATH" ]]; then
        if [[ "$IS_ROOT" == true ]] || [[ -w "/usr/local/bin" ]]; then
            INSTALL_PATH="/usr/local/bin"
        else
            INSTALL_PATH="$HOME/.local/bin"
            # Create directory if it doesn't exist
            mkdir -p "$INSTALL_PATH"
        fi
    fi

    log_info "Installation path: $INSTALL_PATH"
}

# Check for required commands
check_dependencies() {
    local missing_deps=()

    # Check for essential commands
    for cmd in curl unzip; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_deps+=("$cmd")
        fi
    done

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Missing required dependencies: ${missing_deps[*]}"
        log_info "Please install these packages using your system's package manager:"

        case $OS_TYPE in
            mac)
                log_info "  brew install ${missing_deps[*]}"
                ;;
            linux)
                if command -v apt-get >/dev/null 2>&1; then
                    log_info "  sudo apt-get install ${missing_deps[*]}"
                elif command -v yum >/dev/null 2>&1; then
                    log_info "  sudo yum install ${missing_deps[*]}"
                elif command -v dnf >/dev/null 2>&1; then
                    log_info "  sudo dnf install ${missing_deps[*]}"
                fi
                ;;
        esac
        exit 1
    fi
}

# Check Java installation
check_java() {
    log_info "Checking Java installation..."

    if command -v java >/dev/null 2>&1; then
        java_version=$(java -version 2>&1 | head -n 1)
        log_success "Java found: $java_version"

        # Extract major version
        if [[ $java_version =~ version\ \"1\.([0-9]+) ]]; then
            java_major_version=${BASH_REMATCH[1]}
        elif [[ $java_version =~ version\ \"([0-9]+) ]]; then
            java_major_version=${BASH_REMATCH[1]}
        else
            log_warning "Unable to parse Java version: $java_version"
            return 1
        fi

        if [[ $java_major_version -ge $MINIMUM_JAVA_VERSION ]]; then
            log_success "Java version meets requirements (>= $MINIMUM_JAVA_VERSION)"
            return 0
        else
            log_warning "Java version $java_major_version is below minimum requirement ($MINIMUM_JAVA_VERSION)"
            return 1
        fi
    else
        log_warning "Java not found in PATH"
        return 1
    fi
}

# Download file with progress
download_file() {
    local url=$1
    local output_path=$2

    log_info "Downloading from: $url"
    log_info "Saving to: $output_path"

    if command -v curl >/dev/null 2>&1; then
        if curl -fSL --progress-bar "$url" -o "$output_path"; then
            log_success "Download completed"
            return 0
        else
            log_error "Download failed"
            return 1
        fi
    else
        log_error "curl not found"
        return 1
    fi
}

# Install CommandBox
install_commandbox() {
    log_info "Installing CommandBox..."

    local box_path="$INSTALL_PATH/box"

    # Check if CommandBox already exists
    if [[ -f "$box_path" ]] && [[ "$FORCE" != true ]]; then
        if "$box_path" version >/dev/null 2>&1; then
            local existing_version
            existing_version=$("$box_path" version 2>/dev/null | grep -o "CommandBox [0-9]\+\.[0-9]\+\.[0-9]\+" | grep -o "[0-9]\+\.[0-9]\+\.[0-9]\+" || echo "unknown")
            log_info "CommandBox $existing_version already installed"

            if [[ "$existing_version" == "$COMMANDBOX_VERSION" ]]; then
                log_success "CommandBox is up to date"
                echo "$box_path"
                return 0
            else
                log_info "Current version: $existing_version, Available: $COMMANDBOX_VERSION"
            fi
        fi

        if [[ "$FORCE" != true ]]; then
            echo -n "CommandBox already exists. Reinstall? (y/N): "
            read -r response
            if [[ ! "$response" =~ ^[yY] ]]; then
                log_info "Using existing CommandBox installation"
                echo "$box_path"
                return 0
            fi
        fi
    fi

    # Create temp directory
    local temp_dir
    temp_dir=$(mktemp -d)
    local temp_zip="$temp_dir/commandbox-$COMMANDBOX_VERSION.zip"

    # Download CommandBox
    if ! download_file "$COMMANDBOX_DOWNLOAD_URL" "$temp_zip"; then
        rm -rf "$temp_dir"
        return 1
    fi

    # Extract and install
    log_info "Extracting CommandBox to $INSTALL_PATH..."

    if ! unzip -q "$temp_zip" -d "$temp_dir"; then
        log_error "Failed to extract CommandBox"
        rm -rf "$temp_dir"
        return 1
    fi

    # Copy box executable
    if [[ -f "$temp_dir/box" ]]; then
        cp "$temp_dir/box" "$box_path"
        chmod +x "$box_path"
        log_success "CommandBox installed successfully"
    else
        log_error "CommandBox executable not found in archive"
        rm -rf "$temp_dir"
        return 1
    fi

    # Clean up
    rm -rf "$temp_dir"

    # Verify installation
    if [[ -f "$box_path" ]] && "$box_path" version >/dev/null 2>&1; then
        log_success "CommandBox installation verified"
        echo "$box_path"
        return 0
    else
        log_error "CommandBox installation verification failed"
        return 1
    fi
}

# Add CommandBox to PATH
add_commandbox_to_path() {
    local box_path=$1
    local install_dir
    install_dir=$(dirname "$box_path")

    if [[ "$SKIP_PATH" == true ]]; then
        log_info "Skipping PATH update (requested by user)"
        return 0
    fi

    log_info "Adding CommandBox to PATH: $install_dir"

    # Check if already in PATH
    if echo "$PATH" | grep -q "$install_dir"; then
        log_success "CommandBox already in PATH"
        return 0
    fi

    # Determine which shell config file to update
    local shell_config=""
    if [[ -n "${ZSH_VERSION:-}" ]] || [[ "$SHELL" == *"zsh"* ]]; then
        shell_config="$HOME/.zshrc"
    elif [[ -n "${BASH_VERSION:-}" ]] || [[ "$SHELL" == *"bash"* ]]; then
        if [[ "$OS_TYPE" == "mac" ]]; then
            shell_config="$HOME/.bash_profile"
        else
            shell_config="$HOME/.bashrc"
        fi
    fi

    # Add to shell config if found
    if [[ -n "$shell_config" ]]; then
        local path_line="export PATH=\"$install_dir:\$PATH\""

        if [[ -f "$shell_config" ]] && grep -q "export PATH.*$install_dir" "$shell_config"; then
            log_success "PATH already configured in $shell_config"
        else
            echo "" >> "$shell_config"
            echo "# Added by Wheels installer" >> "$shell_config"
            echo "$path_line" >> "$shell_config"
            log_success "PATH updated in $shell_config"
        fi
    fi

    # Update current session PATH
    export PATH="$install_dir:$PATH"
    log_success "CommandBox added to current session PATH"
}

# Install Wheels packages
install_wheels_packages() {
    local box_path=$1

    log_info "Installing Wheels packages..."

    # Check if already installed
    local wheels_installed=false
    local wheels_cli_installed=false

    if "$box_path" list 2>/dev/null | grep -q "$WHEELS_PACKAGE" && [[ "$FORCE" != true ]]; then
        wheels_installed=true
        log_success "Core Wheels package already installed"
    fi

    if "$box_path" list 2>/dev/null | grep -q "$WHEELS_CLI_PACKAGE" && [[ "$FORCE" != true ]]; then
        wheels_cli_installed=true
        log_success "Wheels CLI package already installed"
    fi

    # Ask for reinstallation if both are installed
    if [[ "$wheels_installed" == true ]] && [[ "$wheels_cli_installed" == true ]] && [[ "$FORCE" != true ]]; then
        echo -n "Both Wheels packages already installed. Reinstall? (y/N): "
        read -r response
        if [[ ! "$response" =~ ^[yY] ]]; then
            return 0
        fi
    fi

    # Install core wheels package
    if [[ "$wheels_installed" != true ]] || [[ "$FORCE" == true ]]; then
        log_info "Installing $WHEELS_PACKAGE from ForgeBox..."
        if "$box_path" install "$WHEELS_PACKAGE" --force >/dev/null 2>&1; then
            log_success "Core Wheels package installed successfully"
        else
            log_error "Failed to install core Wheels package"
            return 1
        fi
    fi

    # Install wheels-cli package
    if [[ "$wheels_cli_installed" != true ]] || [[ "$FORCE" == true ]]; then
        log_info "Installing $WHEELS_CLI_PACKAGE from ForgeBox..."
        if "$box_path" install "$WHEELS_CLI_PACKAGE" --force >/dev/null 2>&1; then
            log_success "Wheels CLI package installed successfully"
        else
            log_error "Failed to install Wheels CLI package"
            return 1
        fi
    fi

    return 0
}

# Verify installation
verify_installation() {
    local box_path=$1

    log_info "Verifying installation..."

    # Test CommandBox
    if ! "$box_path" version >/dev/null 2>&1; then
        log_error "CommandBox verification failed"
        return 1
    fi

    local box_version
    box_version=$("$box_path" version 2>/dev/null | head -n 1)
    log_success "CommandBox: $box_version"

    # Test core Wheels package
    if "$box_path" list 2>/dev/null | grep -q "$WHEELS_PACKAGE"; then
        log_success "Core Wheels package: Available"
    else
        log_error "Core Wheels package verification failed"
        return 1
    fi

    # Test Wheels CLI package
    if "$box_path" list 2>/dev/null | grep -q "$WHEELS_CLI_PACKAGE"; then
        log_success "Wheels CLI package: Available"
    else
        log_error "Wheels CLI package verification failed"
        return 1
    fi

    # Test CLI functionality
    if "$box_path" wheels version >/dev/null 2>&1 || "$box_path" wheels --help >/dev/null 2>&1; then
        log_success "Wheels CLI commands: Available"
    else
        log_warning "Wheels CLI commands may not be fully functional"
    fi

    return 0
}

# Show success message
show_success() {
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                          Installation Completed Successfully!                  ║${NC}"
    echo -e "${GREEN}║                                                                                ║${NC}"
    echo -e "${GREEN}║  Next Steps:                                                                   ║${NC}"
    echo -e "${GREEN}║  1. Restart your terminal or run: source ~/.bashrc (or ~/.zshrc)              ║${NC}"
    echo -e "${GREEN}║  2. Create a new app: box wheels g app myapp                                   ║${NC}"
    echo -e "${GREEN}║  3. Start developing: cd myapp && box server start                             ║${NC}"
    echo -e "${GREEN}║                                                                                ║${NC}"
    echo -e "${GREEN}║  Available commands:                                                           ║${NC}"
    echo -e "${GREEN}║  • box wheels g app <name>     - Generate new Wheels app                      ║${NC}"
    echo -e "${GREEN}║  • box wheels g model <name>   - Generate model                               ║${NC}"
    echo -e "${GREEN}║  • box wheels g controller     - Generate controller                          ║${NC}"
    echo -e "${GREEN}║  • box server start            - Start development server                     ║${NC}"
    echo -e "${GREEN}║                                                                                ║${NC}"
    echo -e "${GREEN}║  Documentation: https://wheels.dev/guides                                     ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    if [[ "$SKIP_PATH" != true ]]; then
        log_warning "Please restart your terminal or run 'source ~/.bashrc' (or ~/.zshrc) to use the 'box' command"
    fi
}

# Main installation function
main() {
    parse_args "$@"

    if [[ "$HELP" == true ]]; then
        show_help
        exit 0
    fi

    show_header

    log_info "Starting Wheels installation process..."

    # System checks
    detect_os
    check_root
    determine_install_path
    check_dependencies

    # Java check (optional)
    if ! check_java; then
        log_warning "Java $MINIMUM_JAVA_VERSION+ is recommended for optimal performance"
        log_info "You can download Java from: $JAVA_CHECK_URL"
        log_info "Continuing with installation (CommandBox includes embedded Java)..."
    fi

    # Install CommandBox
    local box_path
    if ! box_path=$(install_commandbox); then
        log_error "CommandBox installation failed. Aborting."
        exit 1
    fi

    # Add to PATH
    add_commandbox_to_path "$box_path"

    # Install Wheels packages
    if ! install_wheels_packages "$box_path"; then
        log_error "Wheels packages installation failed. Aborting."
        exit 1
    fi

    # Verify installation
    if ! verify_installation "$box_path"; then
        log_error "Installation verification failed."
        exit 1
    fi

    show_success
}

# Error handling
set -eE
trap 'log_error "Installation failed on line $LINENO"' ERR

# Run main function with all arguments
main "$@"