# plugins install

Installs a CFWheels CLI plugin from various sources including ForgeBox, GitHub, or local files.

## Usage

```bash
wheels plugins install <name> [--dev] [--global] [--version=<version>]
```

## Parameters

- `name` - (Required) Plugin name or repository URL
- `--dev` - (Optional) Install as development dependency
- `--global` - (Optional) Install globally
- `--version` - (Optional) Specific version to install

## Description

The `plugins install` command downloads and installs CFWheels plugins into your application. It supports multiple installation sources:

- **ForgeBox Registry**: Official and community plugins
- **GitHub Repositories**: Direct installation from GitHub
- **Local Files**: ZIP files or directories
- **URL Downloads**: Direct ZIP file URLs

The command automatically:
- Checks plugin compatibility
- Resolves dependencies
- Backs up existing plugins
- Runs installation scripts

## Examples

### Install from ForgeBox
```bash
wheels plugins install wheels-vue-cli
```

### Install specific version
```bash
wheels plugins install wheels-docker --version=2.0.0
```

### Install from GitHub
```bash
wheels plugins install https://github.com/user/wheels-plugin
```

### Install as development dependency
```bash
wheels plugins install wheels-docker --dev
```

### Install globally
```bash
wheels plugins install wheels-cli-tools --global
```

### Install with multiple options
```bash
wheels plugins install wheels-testing --dev --version=1.5.0
```

## Installation Process

1. **Download**: Fetches plugin from specified source
2. **Validation**: Checks compatibility and requirements
3. **Backup**: Creates backup of existing plugin (if any)
4. **Installation**: Extracts files to plugins directory
5. **Dependencies**: Installs required dependencies
6. **Initialization**: Runs plugin setup scripts
7. **Verification**: Confirms successful installation

## Output

```
📦 Installing plugin: wheels-vue-cli...

✅ Plugin installed successfully
```

If installation fails:
```
📦 Installing plugin: invalid-plugin...

❌ Plugin installation failed
Error: Plugin not found in repository
```

## Plugin Sources

### ForgeBox
```bash
# Install by name (searches ForgeBox)
wheels plugins install plugin-name

# Install specific ForgeBox ID
wheels plugins install forgebox:plugin-slug
```

### GitHub
```bash
# HTTPS URL
wheels plugins install https://github.com/user/repo

# GitHub shorthand
wheels plugins install github:user/repo

# Specific branch/tag
wheels plugins install github:user/repo#v2.0.0
```

### Direct URL
```bash
wheels plugins install https://example.com/plugin.zip
```

## Notes

- Plugins must be compatible with your CFWheels version
- Always backup your application before installing plugins
- Some plugins require manual configuration after installation
- Use `wheels plugins list` to verify installation
- Restart your application to activate new plugins