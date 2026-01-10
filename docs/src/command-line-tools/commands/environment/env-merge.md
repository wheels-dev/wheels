# Wheels env merge

## Overview

The `wheels env merge` command allows you to merge multiple environment configuration files (`.env` files) into a single consolidated file. This is particularly useful when working with different environments (development, staging, production) or when you have base configurations that need to be combined with environment-specific overrides.

## Command Syntax

```bash
wheels env merge <source1> <source2> [source3...] [options]
```

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| source1 | string | Yes | First source .env file to merge |
| source2 | string | Yes | Second source .env file to merge |
| source3, source4, ... | string | No | Additional source .env files to merge (unlimited) |
| --output | string | No | Output file name (default: .env.merge) |
| --dryRun | flag | No | Show what would be merged without actually writing the file |

## Basic Usage Examples

### Simple Two-File Merge
```bash
wheels env merge .env.defaults .env.local
```
This merges `.env.defaults` and `.env.local` into `.env.merge`

### Custom Output File
```bash
wheels env merge .env.defaults .env.local --output=.env
```
This merges the files and saves the result as `.env`

### Production Environment Merge
```bash
wheels env merge source1=.env source2=.env.production --output=.env.merged
```
Combines base configuration with production-specific settings

### Multiple File Merge
```bash
wheels env merge source1=base.env source2=common.env source3=dev.env source4=local.env --output=.env.development
```
Merges multiple files in the specified order (unlimited number of source files supported)

### Dry Run (Preview)
```bash
wheels env merge base.env override.env --dryRun
```
Shows what the merged result would look like without creating a file

## How It Works

### File Processing Order
Files are processed in the order they are specified on the command line. **Later files take precedence** over earlier ones when there are conflicting variable names.

### Supported File Formats
- **Properties format** (standard .env format):
  ```
  DATABASE_HOST=localhost
  DATABASE_PORT=5432
  API_KEY=your-secret-key
  ```
- **JSON format**:
  ```json
  {
    "DATABASE_HOST": "localhost",
    "DATABASE_PORT": "5432",
    "API_KEY": "your-secret-key"
  }
  ```

### File Parsing Details
- Empty lines and comments (lines starting with `#`) are skipped in properties files
- Values can contain `=` signs (everything after the first `=` is considered the value)
- Leading and trailing whitespace is trimmed from keys and values
- The command automatically detects whether a file is JSON or properties format

### Conflict Resolution
When the same variable exists in multiple files:
- The value from the **last processed file** wins
- Conflicts are tracked and reported with details showing:
  - The variable name
  - The original value and source file
  - The new value and source file
- You'll see a summary showing which values were overridden

## Output Features

### Organized Structure
The merged output file is automatically organized:
- Variables are grouped by prefix (e.g., `DATABASE_*`, `API_*`)
- Groups are sorted alphabetically
- Variables within groups are sorted alphabetically
- Includes generated header comments with:
  - Generation timestamp
  - Source information
  - Section headers for each variable group

### Security Features
When using `--dryRun` or viewing output, sensitive values are automatically masked:
- Variables containing `password`, `secret`, `key`, or `token` (case-insensitive) show as `***MASKED***`
- The actual values are still written to the output file (only display is masked)
- Each variable shows its source file for traceability

## Common Use Cases

### Development Workflow
```bash
# Start with base configuration
wheels env merge source1=.env.base source2=.env.development --output=.env

# Add local overrides
wheels env merge source1=.env source2=.env.local --output=.env
```

### Multi-Environment Setup
```bash
# Merge base, environment, and local configs
wheels env merge source1=.env.base source2=.env.staging source3=.env.local --output=.env
```

### Deployment Preparation
```bash
# Create production configuration
wheels env merge source1=.env.base source2=.env.production --output=.env.prod

# Preview staging configuration
wheels env merge source1=.env.base source2=.env.staging --dryRun
```

### Configuration Validation
```bash
# Check what the final configuration looks like
wheels env merge source1=.env.defaults source2=.env.current --dryRun
```

## Sample Output

### Command Execution
```
Merging environment files:
  1. .env.defaults
  2. .env.local
  3. .env.override

Merged 3 files into .env.merge
  Total variables: 15

Conflicts resolved (later files take precedence):
  DATABASE_HOST: 'db.example.com' (.env.defaults) → 'localhost' (.env.local)
  DEBUG_MODE: 'false' (.env.defaults) → 'true' (.env.override)
```

### Dry Run Output
```
Merged result (DRY RUN):

DATABASE Variables:
  DATABASE_HOST = localhost (from .env.local)
  DATABASE_NAME = myapp (from .env.defaults)
  DATABASE_PASSWORD = ***MASKED*** (from .env.local)
  DATABASE_PORT = 5432 (from .env.defaults)

API Variables:
  API_BASE_URL = https://api.example.com (from .env.defaults)
  API_KEY = ***MASKED*** (from .env.local)
  API_TOKEN = ***MASKED*** (from .env.override)

Other Variables:
  APP_NAME = MyApplication (from .env.defaults)
  DEBUG_MODE = true (from .env.override)
```

### Generated File Format
```env
# Merged Environment Configuration
# Generated by wheels env merge command
# Date: 2024-12-15 14:30:45

# API Configuration
API_BASE_URL=https://api.example.com
API_KEY=actual-key-value
API_TOKEN=actual-token-value

# DATABASE Configuration
DATABASE_HOST=localhost
DATABASE_NAME=myapp
DATABASE_PASSWORD=actual-password
DATABASE_PORT=5432

# Other Configuration
APP_NAME=MyApplication
DEBUG_MODE=true
```

## Error Handling

The command will stop and show an error if:
- Source files don't exist
- Less than two source files are provided
- Output file cannot be written (permissions, disk space, etc.)
- File read operations fail

## Important Notes

1. **Default output filename** is `.env.merge` (not `.env.merged`)
2. **Multiple files supported** - You can merge any number of files (not just 2 or 3)
3. **Option format** - Use double dashes for options: `--output`, `--dryRun`
4. **Value preservation** - Values containing `=` signs are properly preserved
5. **Comment handling** - Comments in source files are not preserved in the merged output

## Best Practices

1. **Use descriptive file names** that indicate their purpose (`.env.base`, `.env.production`, `.env.local`)

2. **Order files by precedence** - place base/default files first, overrides last

3. **Use dry-run first** to preview results before committing to a merge

4. **Keep sensitive data in local files** that aren't committed to version control

5. **Document your merge strategy** in your project's README

6. **Backup important configurations** before merging

7. **Review conflicts** - Pay attention to the conflicts report to ensure expected overrides

## Tips

- The merged file includes helpful comments showing when it was generated
- Variables are automatically organized by prefix for better readability
- Use the `--dryRun` option to understand what changes will be made
- The command validates all source files exist before starting the merge process
- You can merge as many files as needed in a single command
- The source file information is preserved during dry runs for debugging