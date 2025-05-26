# wheels deps

Manage application dependencies.

## Synopsis

```bash
wheels deps
```

## Description

The `wheels deps` command helps manage your Wheels application's dependencies, including CFML modules, Wheels plugins, and JavaScript packages.

## Options

| Option | Description |
|--------|-------------|
| `--help` | Show help information |

## Features

1. **Dependency Analysis**
   - Scans `box.json` for CFML dependencies
   - Checks `package.json` for Node.js dependencies
   - Identifies Wheels plugins

2. **Version Checking**
   - Compares installed vs required versions
   - Identifies outdated packages
   - Shows available updates

3. **Dependency Installation**
   - Installs missing dependencies
   - Updates outdated packages
   - Resolves version conflicts

## Output Example

```
╔═══════════════════════════════════════════════╗
║          Dependency Analysis                  ║
╚═══════════════════════════════════════════════╝

CFML Dependencies (box.json):
✓ wheels          2.5.0    (up to date)
✓ cbvalidation    3.0.0    (up to date)
⚠ sqlbuilder      1.2.0    (1.3.0 available)
✗ testbox         Missing  (4.5.0 required)

Wheels Plugins:
✓ multimodule     1.0.0    (active)
✓ scaffold        2.1.0    (active)

Node Dependencies (package.json):
✓ webpack         5.88.0   (up to date)
✓ babel-core      7.22.0   (up to date)

Status: 1 missing, 1 outdated

Would you like to:
[1] Install missing dependencies
[2] Update outdated dependencies
[3] Update all dependencies
[4] Exit

Choice:
```

## Dependency Sources

### CFML Dependencies (`box.json`)
```json
{
  "dependencies": {
    "wheels": "^2.5.0",
    "testbox": "^4.5.0"
  }
}
```

### Wheels Plugins
Located in `/plugins` directory or installed via ForgeBox.

### Node Dependencies (`package.json`)
```json
{
  "dependencies": {
    "webpack": "^5.88.0"
  }
}
```

## Commands Executed

Behind the scenes, `wheels deps` runs:

```bash
# For CFML dependencies
box install

# For Node dependencies
npm install

# For Wheels plugins
wheels plugins list
```

## Use Cases

- Check dependency status before deployment
- Ensure all team members have same dependencies
- Update dependencies safely
- Troubleshoot missing functionality

## Best Practices

1. Run after pulling new code
2. Check before deployments
3. Update dependencies incrementally
4. Test after updates

## Notes

- Requires `box.json` for CFML dependencies
- Optional `package.json` for Node dependencies
- Some plugins may require manual configuration

## See Also

- [wheels plugins list](../plugins/plugins-list.md) - List installed plugins
- [wheels init](init.md) - Initialize application
- [wheels test](../testing/test.md) - Test after dependency updates