# wheels deptree

Display the dependency tree for your Wheels application.

## Synopsis

```bash
wheels deptree [depth=<number>] [production=<boolean>] [format=<format>]
```

## Description

The `deptree` command visualizes your application's dependency hierarchy, showing which packages depend on which others. It helps you understand your dependency graph, identify outdated packages, and spot potential conflicts.

## Options

### depth
- **Type**: Number
- **Default**: 3
- **Description**: Maximum depth to traverse in the dependency tree

### production
- **Type**: Boolean
- **Default**: false
- **Description**: Only show production dependencies (exclude devDependencies)

### format
- **Type**: String
- **Default**: tree
- **Options**: tree, list
- **Description**: Output format for dependencies

## Examples

### Basic Dependency Tree

```bash
wheels deptree
```

Output:
```
Application Dependencies
======================================================================
Project: myapp
Version: 1.0.0

├── wheels @ ^2.5.0 [installed: 2.5.0]
│   ├── wirebox @ ^7.0.0 [installed: 7.2.0]
│   └── testbox @ ^5.0.0 [installed: 5.2.0]
│       └── mockdatacfc @ ^3.6.0 [installed: 3.6.0]
├── commandbox-dotenv @ ^1.0.0 [installed: 1.5.0]
├── commandbox-cfformat @ ^0.15.0 [installed: 0.15.3]
│   └── cbjavaloader @ ^2.0.0 [installed: 2.1.0]
└── qb @ ^9.0.0 [installed: 9.2.0]
    └── cbpaginator @ ^2.5.0 [installed: 2.5.0]

======================================================================
Total: 4 production, 2 development dependencies
```

### Limited Depth

Show only direct dependencies:
```bash
wheels deptree depth=1
```

Output:
```
├── wheels @ ^2.5.0 [installed: 2.5.0]
├── commandbox-dotenv @ ^1.0.0 [installed: 1.5.0]
├── commandbox-cfformat @ ^0.15.0 [installed: 0.15.3]
└── qb @ ^9.0.0 [installed: 9.2.0]
```

### Production Only

```bash
wheels deptree production=true
```

Shows only dependencies, not devDependencies.

### List Format

```bash
wheels deptree format=list
```

Output:
```
Application Dependencies
======================================================================
Project: myapp
Version: 1.0.0

Package                  Required        Installed      Status
----------------------------------------------------------------------
wheels                  ^2.5.0          2.5.0          Installed
commandbox-dotenv       ^1.0.0          1.5.0          Installed
commandbox-cfformat     ^0.15.0         0.15.3         Installed
qb                      ^9.0.0          9.2.0          Installed
testbox                 ^5.0.0          Not installed  Missing
mockdatacfc            ^3.6.0          3.6.0          Installed

======================================================================
Total: 4 production, 2 development dependencies
```

## Understanding the Output

### Tree Format Symbols
- `├──` Branch connection
- `└──` Last item in branch
- `│` Vertical continuation

### Version Information
- `@` Required version/range
- `[installed: x.x.x]` Actual installed version
- `[not installed]` Package is missing

### Status Indicators
- Green `[installed]` - Package is installed
- Red `[not installed]` - Package is missing

## Version Ranges

Common version specifications:
- `^2.5.0` - Compatible with 2.5.0 (>=2.5.0 <3.0.0)
- `~2.5.0` - Approximately 2.5.0 (>=2.5.0 <2.6.0)
- `>=2.5.0` - 2.5.0 or higher
- `2.5.0` - Exact version
- `*` - Any version

## Use Cases

### 1. Dependency Audit
```bash
# Check all dependencies
wheels deptree

# Look for missing packages (red items)
# Check for version mismatches
```

### 2. Before Updates
```bash
# See what depends on what
wheels deptree depth=2

# Plan update strategy
box update packageName
```

### 3. Troubleshooting Conflicts
```bash
# Deep dive into dependencies
wheels deptree depth=5

# Find conflicting sub-dependencies
```

### 4. Documentation
```bash
# Document production dependencies
wheels deptree production=true format=list > dependencies.txt
```

### 5. CI/CD Verification
```bash
# Ensure all dependencies are installed
wheels deptree format=list | grep "Not installed" && exit 1
```

## Dependency Sources

The command reads from `box.json`:

```json
{
  "name": "myapp",
  "version": "1.0.0",
  "dependencies": {
    "wheels": "^2.5.0",
    "qb": "^9.0.0"
  },
  "devDependencies": {
    "testbox": "^5.0.0",
    "commandbox-cfformat": "^0.15.0"
  }
}
```

## Installation Status

The command checks if packages are installed by looking in:
- `/modules/` directory
- Package-specific subdirectories
- `box.json` files within packages

## Common Issues

### Missing Dependencies
```
└── testbox @ ^5.0.0 [not installed]
```
**Solution**: Run `box install`

### Version Mismatches
```
├── wheels @ ^2.5.0 [installed: 2.3.0]
```
**Solution**: Run `box update wheels`

### Deep Dependency Conflicts
When sub-dependencies conflict:
```
├── packageA @ ^1.0.0
│   └── sharedLib @ ^2.0.0
└── packageB @ ^1.0.0
    └── sharedLib @ ^3.0.0  // Conflict!
```

## Best Practices

### 1. Regular Audits
```bash
# Weekly dependency check
wheels deptree
box outdated
```

### 2. Document Dependencies
```bash
# Add to README
wheels deptree production=true format=list
```

### 3. Minimal Dependencies
- Only add necessary packages
- Prefer packages with fewer sub-dependencies
- Regular cleanup of unused packages

### 4. Version Pinning
For critical applications:
```json
"dependencies": {
  "wheels": "2.5.0",  // Exact version
  "qb": "9.2.0"
}
```

## Integration with Other Commands

### Update Workflow
```bash
# 1. Check current state
wheels deptree

# 2. Check for updates
box outdated

# 3. Update specific package
box update packageName

# 4. Verify
wheels deptree
```

### Installation Workflow
```bash
# 1. Install all dependencies
box install

# 2. Verify installation
wheels deptree

# 3. Run health check
wheels doctor
```

## Related Commands

- [`wheels deps`](../core/deps.md) - Manage Wheels-specific dependencies
- [`box install`](https://commandbox.ortusbooks.com/package-management/installing-packages) - Install packages
- [`box update`](https://commandbox.ortusbooks.com/package-management/updating-packages) - Update packages
- [`box outdated`](https://commandbox.ortusbooks.com/package-management/outdated-packages) - Check for updates

## Tips

- Use `depth=1` for a quick overview
- Check dependencies before major updates
- Document your dependency tree in project docs
- Use production=true for deployment documentation
- Regular audits help prevent security issues

## Future Enhancements

Planned features:
- Circular dependency detection
- License information display
- Security vulnerability warnings
- Dependency size information
- Export to various formats (JSON, GraphViz)