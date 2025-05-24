# wheels watch

Watch for file changes and automatically reload the application.

## Synopsis

```bash
wheels watch [path] [--extensions] [--exclude] [--reload-mode]
```

## Description

The `wheels watch` command monitors your application files for changes and automatically triggers actions like reloading the application or running tests. This provides a smooth development workflow with instant feedback.

## Arguments

| Argument | Description | Default |
|----------|-------------|---------|
| `path` | Directory to watch | `.` (current directory) |

## Options

| Option | Description | Default |
|--------|-------------|---------|
| `--extensions` | File extensions to watch | `.cfc,.cfm,.json` |
| `--exclude` | Paths to exclude | `temp/,logs/,.git/` |
| `--reload-mode` | Reload mode when changes detected | `development` |
| `--test` | Run tests on change | `false` |
| `--debounce` | Milliseconds to wait before reacting | `500` |
| `--help` | Show help information | |

## Examples

### Basic file watching
```bash
wheels watch
```
Watches current directory for `.cfc`, `.cfm`, and `.json` changes

### Watch specific directory
```bash
wheels watch ./src
```

### Watch additional file types
```bash
wheels watch --extensions=".cfc,.cfm,.js,.css"
```

### Exclude directories
```bash
wheels watch --exclude="node_modules/,temp/,logs/"
```

### Auto-run tests
```bash
wheels watch --test
```

### Custom debounce timing
```bash
wheels watch --debounce=1000
```

## Default Behavior

When a file change is detected:

1. **CFC Files** (models, controllers)
   - Triggers application reload
   - Clears relevant caches
   - Runs tests if `--test` enabled

2. **CFM Files** (views)
   - Clears view cache
   - No full reload needed

3. **Config Files** (.json, settings.cfm)
   - Full application reload
   - Re-reads configuration

## Output Example

```
[Wheels Watch] Monitoring for changes...
[Wheels Watch] Watching: /Users/myapp
[Wheels Watch] Extensions: .cfc, .cfm, .json
[Wheels Watch] Excluded: temp/, logs/, .git/

[12:34:56] Change detected: models/User.cfc
[12:34:56] Reloading application...
[12:34:57] ✓ Application reloaded successfully

[12:35:23] Change detected: views/users/index.cfm
[12:35:23] Clearing view cache...
[12:35:23] ✓ View cache cleared

[12:36:45] Multiple changes detected:
  - controllers/Products.cfc
  - models/Product.cfc
[12:36:45] Reloading application...
[12:36:46] ✓ Application reloaded successfully
[12:36:46] Running tests...
[12:36:48] ✓ All tests passed (15 specs, 0 failures)
```

## Advanced Configuration

Create `.wheels-watch.json` for project-specific settings:

```json
{
  "extensions": [".cfc", ".cfm", ".js", ".css"],
  "exclude": ["node_modules/", "temp/", ".git/", "logs/"],
  "reload": {
    "mode": "development",
    "debounce": 500
  },
  "test": {
    "enabled": true,
    "on": ["models/", "controllers/"],
    "command": "wheels test run"
  },
  "custom": [
    {
      "pattern": "assets/",
      "command": "npm run build"
    }
  ]
}
```

## Performance Considerations

- Large directories may slow down watching
- Use `--exclude` to skip unnecessary paths
- Increase `--debounce` for grouped changes
- Consider watching specific subdirectories

## Integration with Editors

### VS Code
Add to `.vscode/tasks.json`:
```json
{
  "label": "Wheels Watch",
  "type": "shell",
  "command": "wheels watch",
  "problemMatcher": [],
  "isBackground": true
}
```

### Sublime Text
Create build system:
```json
{
  "cmd": ["wheels", "watch"],
  "working_dir": "${project_path}"
}
```

## Common Patterns

### Development Workflow
```bash
# Terminal 1: Run server
box server start

# Terminal 2: Watch for changes
wheels watch --test
```

### Frontend + Backend
```bash
wheels watch --extensions=".cfc,.cfm,.js,.vue" \
  --custom='{"pattern":"src/","command":"npm run build"}'
```

### Test-Driven Development
```bash
wheels watch models/ controllers/ --test --reload-mode=testing
```

## Troubleshooting

- **Too many file descriptors**: Increase system limits or exclude more directories
- **Changes not detected**: Check file extensions and excluded paths
- **Slow response**: Increase debounce time or watch specific directories
- **Tests failing**: Ensure test environment is properly configured

## Notes

- Requires file system events support
- Some network drives may not support watching
- Symbolic links are followed by default

## See Also

- [wheels reload](reload.md) - Manual application reload
- [wheels test run](../testing/test-run.md) - Run tests
- [wheels config set](../config/config-set.md) - Configure watch settings