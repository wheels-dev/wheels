# wheels plugins list

Lists installed Wheels CLI plugins or shows available plugins from ForgeBox.

## Usage

```bash
wheels plugins list [--format=<format>] [--available]
```

## Parameters

- `--format` - (Optional) Output format: `table`, `json`. Default: `table`
- `--available` - (Optional) Show available plugins from ForgeBox

## Description

The `plugins list` command displays information about all plugins installed in your Wheels application, including:

- Plugin name and version
- Description and author information
- Dependencies on other plugins

## Examples

### List all local plugins
```bash
wheels plugins list
```


### Export as JSON
```bash
wheels plugins list --format=json
```

### Show available plugins from ForgeBox
```bash
wheels plugins list --available
```

## Output

### Table Format (Default)
```
Installed Wheels CLI Plugins

Name                Version    Description
---------------------------------------------
wheels-vue-cli      1.2.0     Vue.js integration for Wheels
wheels-docker       2.0.1     Docker deployment tools
wheels-testing      1.5.0     Advanced testing utilities

Total: 3 plugins
```

### Available Plugins from ForgeBox
```
================ Available Wheels Plugins From ForgeBox ======================
[Lists all available cfwheels-plugins from ForgeBox]
=============================================================================
```

### JSON Format
```json
{
  "plugins": [
    {
      "name": "wheels-vue-cli",
      "version": "1.2.0",
      "description": "Vue.js integration for Wheels"
    }
  ]
}
```

## Notes

- Plugins are stored in your project's `/plugins` folder
- Use `wheels plugins install` to add new plugins  
- The `--available` flag queries the ForgeBox registry