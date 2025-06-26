# analyze security (Deprecated)

**⚠️ DEPRECATED**: This command has been deprecated. Please use `wheels security scan` instead.

## Migration Notice

The `analyze security` command has been moved to provide better organization and expanded functionality. 

### Old Command (Still Works)
```bash
wheels analyze security [path] [--fix] [--report=<format>] [--severity=<level>] [--deep]
```

### New Command
```bash
wheels security scan [path] [--fix] [--output=<format>] [--detailed]
```

## Parameter Mapping

When called, the deprecated command forwards parameters to the new command:
- `path` → `path`
- `--fix` → `--fix`
- `--report` → `--output`
- `--severity` → (handled internally)
- `--deep` → `--detailed`

## Why the Change?

- Better command organization with dedicated security namespace
- Enhanced scanning capabilities
- Improved reporting options
- Integration with security vulnerability databases

## See Also

- [security scan](../security/security-scan.md) - The replacement command with enhanced features

## Deprecation Timeline

- **Deprecated**: v1.5.0
- **Warning Added**: v1.6.0
- **Removal Planned**: v2.0.0

The command currently redirects to `wheels security scan` with a deprecation warning.