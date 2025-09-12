# wheels init

Bootstrap an existing Wheels application for CLI usage.

## Synopsis

```bash
wheels init
```

## Description

The `wheels init` command initializes an existing Wheels application to work with the Wheels CLI. It's an interactive command that helps set up necessary configuration files (box.json and server.json) for an existing Wheels installation.

## Arguments

This command has no arguments - it runs interactively and prompts for required information.


## Interactive Prompts

When you run `wheels init`, you'll be prompted for:

1. **Confirmation** - Confirm you want to proceed with initialization
2. **Application Name** - Used to make server.json server name unique (if box.json doesn't exist)
3. **CF Engine** - Default CFML engine (e.g., `lucee5`, `adobe2021`) (if server.json doesn't exist)

## Examples

### Initialize current directory
```bash
wheels init
```

Example interaction:
```
==================================== Wheels init ===================================
 This function will attempt to add a few things
 to an EXISTING Wheels installation to help
 the CLI interact.

 We're going to assume the following:
  - you've already setup a local datasource/database
  - you've already set a reload password

 We're going to try and do the following:
  - create a box.json to help keep track of the wheels version
  - create a server.json
====================================================================================

Sound ok? [y/n] y
Please enter an application name: myapp
Please enter a default cfengine: lucee5
```

## What It Does

1. **Creates `vendor/wheels/box.json`** - Tracks the Wheels framework version
2. **Creates `server.json`** - Configures CommandBox server settings with:
   - Unique server name based on application name
   - Selected CF engine
   - Default port and settings
3. **Creates `box.json`** - Main project configuration file with:
   - Application name
   - Wheels version dependency
   - Project metadata

## Generated Files

### server.json
```json
{
  "name": "myapp",
  "web": {
    "http": {
      "port": 60000
    }
  },
  "app": {
    "cfengine": "lucee5"
  }
}
```

### box.json
```json
{
  "name": "myapp",
  "version": "1.0.0",
  "dependencies": {
    "wheels": "^2.5.0"
  }
}
```

## Prerequisites

Before running `wheels init`:
- Have an existing Wheels application
- Database/datasource already configured
- Reload password already set in your application settings

## Notes

- Run this command in the root directory of your Wheels application
- Files are only created if they don't already exist
- The command detects your current Wheels version automatically
- Special characters are stripped from application names

## See Also

- [wheels generate app](../generate/app.md) - Create a new Wheels application
- [wheels reload](reload.md) - Reload the application
- [wheels info](info.md) - Display version information
