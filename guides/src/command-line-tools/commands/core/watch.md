# wheels watch

Watch Wheels application files for changes and automatically reload the application.

## Synopsis

```bash
wheels watch [options]
```

## Description

The `wheels watch` command monitors your application files for changes and automatically triggers actions like reloading the application, running tests, or executing custom commands. This provides a smooth development workflow with instant feedback.

## Arguments

| Argument | Description | Default |
|----------|-------------|---------|
| `includeDirs` | Comma-delimited list of directories to watch | `controllers,models,views,config,migrator/migrations` |
| `excludeFiles` | Comma-delimited list of file patterns to ignore | (none) |
| `interval` | Interval in seconds to check for changes | `1` |
| `reload` | Reload framework on changes | `true` |
| `tests` | Run tests on changes | `false` |
| `migrations` | Run migrations on schema changes | `false` |
| `command` | Custom command to run on changes | (none) |
| `debounce` | Debounce delay in milliseconds | `500` |

**Note**: In CommandBox, boolean flags are specified with `--flagname` and value parameters with `paramname=value`.

## Examples

### Basic file watching
```bash
wheels watch
```
Watches default directories for changes and reloads the application

### Watch with tests
```bash
wheels watch --tests
```
Runs tests automatically when files change

### Watch specific directories
```bash
wheels watch includeDirs="controllers,models"
```

### Exclude file patterns
```bash
wheels watch excludeFiles="*.txt,*.log"
```

### Watch with all features
```bash
wheels watch --reload --tests --migrations
```

### Custom command on changes
```bash
wheels watch command="wheels test run"
```

### Adjust check interval
```bash
wheels watch interval=2 debounce=1000
```

### Disable reload but run tests
```bash
wheels watch reload=false --tests
```

## What It Does

The watch command starts with:
1. An initial scan of all watched directories to establish baseline
2. Displays count of files being monitored
3. Checks for changes at the specified interval

When changes are detected:
- **With `--reload`**: Reloads the application
- **With `--tests`**: Runs tests (smart filtering based on changed files)
- **With `--migrations`**: Runs migrations if schema files changed
- **With `--command`**: Executes the specified command

## Output Example

```
🔄 Wheels Watch Mode
Monitoring files for changes...
Press Ctrl+C to stop watching

✓ Will reload framework on changes
✓ Will run tests on changes

Watching 145 files across 5 directories

📝 Detected changes:
  ~ /app/models/User.cfc (modified)
  + /app/models/Profile.cfc (new)

🔄 Reloading application...
✅ Application reloaded successfully at 14:32:15

🧪 Running tests...
✅ All actions completed, watching for more changes...
```

## File Exclusion

The `excludeFiles` parameter supports patterns:
- `*.txt` - Exclude all .txt files
- `*.log` - Exclude all .log files
- `temp.cfc` - Exclude specific file name
- Multiple patterns: `excludeFiles="*.txt,*.log,temp.*"`

## Smart Test Running

When `--tests` is enabled, the command intelligently determines which tests to run:
- Changes to models run model tests
- Changes to controllers run controller tests
- Multiple changes batch test execution

## Migration Detection

With `--migrations` enabled, the command detects:
- New migration files in `/migrator/migrations/`
- Changes to schema files
- Automatically runs `wheels dbmigrate up`

## Performance Considerations

- Initial scan time depends on project size
- Use `includeDirs` to limit scope
- Use `excludeFiles` to skip large files
- Adjust `interval` for less frequent checks
- Use `debounce` to batch rapid changes

## Common Workflows

### Development Workflow
```bash
# Terminal 1: Run server
box server start

# Terminal 2: Watch with reload and tests
wheels watch --reload --tests
```

### Frontend + Backend
```bash
# Watch backend files and run build command
wheels watch command="npm run build"
```

### Test-Driven Development
```bash
# Focus on models and controllers with tests
wheels watch includeDirs="models,controllers" --tests
```

### Database Development
```bash
# Watch for migration changes
wheels watch includeDirs="migrator/migrations" --migrations
```

## Best Practices

1. **Start Simple**: Use `wheels watch` with defaults first
2. **Add Features Gradually**: Enable tests, migrations as needed
3. **Optimize Scope**: Use `includeDirs` for faster performance
4. **Exclude Wisely**: Skip log files, temp files, etc.
5. **Batch Changes**: Increase debounce for multiple file saves

## Troubleshooting

- **High CPU Usage**: Reduce check frequency with `interval`
- **Missed Changes**: Check excluded patterns
- **Reload Errors**: Ensure reload password is configured
- **Test Failures**: Run tests manually to debug

## Notes

- Changes are tracked by file modification time
- New files are automatically detected
- Deleted files are removed from tracking
- Press Ctrl+C to stop watching

## See Also

- [wheels reload](reload.md) - Manual application reload
- [wheels test run](../testing/test-run.md) - Run tests manually
- [wheels dbmigrate up](../database/dbmigrate-up.md) - Run migrations