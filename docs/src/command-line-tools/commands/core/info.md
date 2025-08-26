# wheels info

Display CLI and Wheels framework version information.

## Synopsis

```bash
wheels info
```

## Description

The `wheels info` command displays information about the Wheels CLI module and identifies the Wheels framework version in the current directory.

## Arguments

This command has no arguments.

## Options

| Option | Description |
|--------|-------------|
| `--help` | Show help information |

## Output

The command displays:

1. **Wheels ASCII Art** - A colorful banner
2. **Current Working Directory** - Where you're running the command from
3. **CommandBox Module Root** - Where the CLI module is installed
4. **Current Wheels Version** - The detected Wheels framework version in this directory

## Example Output

```
,--.   ,--.,--.                   ,--.            ,-----.,--.   ,--. 
|  |   |  ||  ,---.  ,---.  ,---. |  | ,---.     '  .--./|  |   |  | 
|  |.'.|  ||  .-.  || .-. :| .-. :|  |(  .-'     |  |    |  |   |  | 
|   ,'.   ||  | |  |\   --.\   --.|  |.-'  `)    '  '--'\|  '--.|  | 
'--'   '--'`--' `--' `----' `----'`--'`----'      `-----'`-----'`--' 
============================ Wheels CLI ============================
Current Working Directory: /Users/username/myapp
CommandBox Module Root: /Users/username/.CommandBox/cfml/modules/wheels-cli/
Current Wheels Version in this directory: 3.0.0-SNAPSHOT
====================================================================
```

## Use Cases

- Verify CLI installation location
- Check Wheels framework version in current directory
- Troubleshoot path issues
- Quick visual confirmation of Wheels environment

## Notes

- The Wheels version is detected by looking for box.json files in the vendor/wheels directory
- If no Wheels version is found, it will show "Not Found"
- The colorful ASCII art helps quickly identify you're using Wheels CLI

## See Also

- [wheels init](init.md) - Initialize a Wheels application
- [wheels deps](deps.md) - Manage dependencies