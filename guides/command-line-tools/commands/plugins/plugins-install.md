# plugins install

Installs a CFWheels plugin from various sources including ForgeBox, GitHub, or local files.

## Usage

```bash
wheels plugins install <plugin> [--version=<version>] [--force] [--save]
```

## Parameters

- `plugin` - (Required) Plugin name, ForgeBox slug, GitHub URL, or local path
- `--version` - (Optional) Specific version to install. Default: latest
- `--force` - (Optional) Force installation even if plugin exists
- `--save` - (Optional) Save plugin to box.json dependencies

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
wheels plugins install authentication
```

### Install specific version
```bash
wheels plugins install dbmigrate --version=3.0.0
```

### Install from GitHub
```bash
wheels plugins install https://github.com/user/wheels-plugin
```

### Install from local file
```bash
wheels plugins install /path/to/plugin.zip
```

### Force reinstall
```bash
wheels plugins install routing --force
```

### Install and save to dependencies
```bash
wheels plugins install cache-manager --save
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
Installing plugin: authentication
==================================

Downloading from ForgeBox... ✓
Checking compatibility... ✓
Creating backup... ✓
Installing plugin files... ✓
Installing dependencies... ✓
Running setup scripts... ✓

Plugin 'authentication' (v2.1.0) installed successfully!

Post-installation notes:
- Run 'wheels reload' to activate the plugin
- Check documentation at /plugins/authentication/README.md
- Configure settings in /config/authentication.cfm
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