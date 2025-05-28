# wheels info

Display CLI and Wheels framework version information.

## Synopsis

```bash
wheels info
```

## Description

The `wheels info` command displays detailed information about your Wheels CLI installation, the current Wheels application, and the environment.

## Options

| Option | Description |
|--------|-------------|
| `--help` | Show help information |

## Output

The command displays:

1. **CLI Information**
   - Wheels CLI version
   - CommandBox version
   - Installation path

2. **Application Information** (if in a Wheels app directory)
   - Application name
   - Wheels framework version
   - Reload password status
   - Configuration file location

3. **Environment Information**
   - CFML engine and version
   - Operating system
   - Java version

## Example Output

```
╔═══════════════════════════════════════════════╗
║           Wheels CLI Information              ║
╚═══════════════════════════════════════════════╝

CLI Version:      3.0.0
CommandBox:       5.9.0
Installation:     ~/.commandbox/cfml/modules/wheels-cli/

╔═══════════════════════════════════════════════╗
║         Application Information               ║
╚═══════════════════════════════════════════════╝

Application:      myapp
Wheels Version:   2.5.0
Reload Password:  [CONFIGURED]
Config File:      .wheels-cli.json

╔═══════════════════════════════════════════════╗
║         Environment Information               ║
╚═══════════════════════════════════════════════╝

CFML Engine:      Lucee 5.3.10.120
OS:              macOS 13.0
Java:            11.0.19
```

## Use Cases

- Verify CLI installation
- Check Wheels framework version
- Troubleshoot environment issues
- Confirm application configuration

## Notes

- Run from within a Wheels application directory for full information
- Application information only appears when `.wheels-cli.json` exists
- Sensitive information like passwords are masked

## See Also

- [wheels init](init.md) - Initialize a Wheels application
- [wheels deps](deps.md) - Manage dependencies