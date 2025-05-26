# wheels init

Bootstrap an existing Wheels application for CLI usage.

## Synopsis

```bash
wheels init [name] [directory] [reload] [version] [createFolders]
```

## Description

The `wheels init` command initializes an existing Wheels application to work with the Wheels CLI. It sets up the necessary configuration files and creates a `.wheels-cli.json` file in your project root.

## Arguments

| Argument | Description | Default |
|----------|-------------|---------|
| `name` | Name of the application | Current directory name |
| `directory` | The directory to initialize | `.` (current directory) |
| `reload` | Reload password for the application | `wheels` |
| `version` | Wheels version to use | Latest stable |
| `createFolders` | Create Wheels directory structure | `true` |

## Options

| Option | Description |
|--------|-------------|
| `--help` | Show help information |

## Examples

### Initialize current directory
```bash
wheels init
```

### Initialize with custom name
```bash
wheels init myapp
```

### Initialize specific directory
```bash
wheels init myapp ./projects/myapp
```

### Initialize with custom reload password
```bash
wheels init myapp . secretPassword
```

### Initialize without creating folders
```bash
wheels init myapp . wheels latest false
```

## What It Does

1. Creates `.wheels-cli.json` configuration file
2. Sets up application name and version
3. Configures reload password
4. Optionally creates standard Wheels directory structure:
   - `/config`
   - `/controllers`
   - `/models`
   - `/views`
   - `/tests`
   - `/plugins`

## Configuration File

The generated `.wheels-cli.json` contains:

```json
{
  "name": "myapp",
  "version": "2.5.0",
  "reload": "wheels",
  "framework": "wheels",
  "createFolders": true
}
```

## Notes

- Run this command in the root directory of your Wheels application
- The reload password is used for the `wheels reload` command
- If folders already exist, they won't be overwritten

## See Also

- [wheels generate app](../generate/app.md) - Create a new Wheels application
- [wheels reload](reload.md) - Reload the application
- [wheels info](info.md) - Display version information