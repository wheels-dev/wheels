# Wheels env merge

## Overview

The `wheels env merge` command allows you to merge multiple environment configuration files (`.env` files) into a single consolidated file. This is particularly useful when working with different environments (development, staging, production) or when you have base configurations that need to be combined with environment-specific overrides.

## Command Syntax

```bash
wheels env merge <source1> <source2> [additional_sources...] [options]
```

## Parameters

### Required Parameters
- **`source1`** - First source .env file to merge
- **`source2`** - Second source .env file to merge
- **`additional_sources`** - Optional additional .env files (can specify multiple)

### Optional Parameters
- **`--output`** - Output file name (default: `.env.merged`)
- **`--dry-run`** - Show what would be merged without actually writing the file

## Basic Usage Examples

### Simple Two-File Merge
```bash
wheels env merge .env.defaults .env.local
```
This merges `.env.defaults` and `.env.local` into `.env.merged`

### Custom Output File
```bash
wheels env merge .env.defaults .env.local --output=.env
```
This merges the files and saves the result as `.env`

### Production Environment Merge
```bash
wheels env merge .env .env.production --output=.env.merged
```
Combines base configuration with production-specific settings

### Multiple File Merge
```bash
wheels env merge base.env common.env dev.env local.env --output=.env.development
```
Merges multiple files in the specified order

### Dry Run (Preview)
```bash
wheels env merge base.env override.env --dry-run
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

### Conflict Resolution
When the same variable exists in multiple files:
- The value from the **last processed file** wins
- Conflicts are tracked and reported
- You'll see a summary showing which values were overridden

## Output Features

### Organized Structure
The merged output file is automatically organized:
- Variables are grouped by prefix (e.g., `DATABASE_*`, `API_*`)
- Groups are sorted alphabetically
- Variables within groups are sorted alphabetically
- Comments indicate the source and generation date

### Security Features
When using `--dry-run` or viewing output, sensitive values are automatically masked:
- Variables containing `password`, `secret`, `key`, or `token` show as `***MASKED***`
- The actual values are still written to the output file (only display is masked)

## Common Use Cases

### Development Workflow
```bash
# Start with base configuration
wheels env merge .env.base .env.development --output=.env

# Add local overrides
wheels env merge .env .env.local --output=.env
```

### Deployment Preparation
```bash
# Create production configuration
wheels env merge .env.base .env.production --output=.env.prod

# Preview staging configuration
wheels env merge .env.base .env.staging --dry-run
```

### Configuration Validation
```bash
# Check what the final configuration looks like
wheels env merge .env.defaults .env.current --dry-run
```

## Sample Output

### Command Execution
```
Merging environment files:
  1. .env.defaults
  2. .env.local

Merged 2 files into .env.merged
  Total variables: 15

Conflicts resolved (later files take precedence):
  DATABASE_HOST: 'db.example.com' (.env.defaults) → 'localhost' (.env.local)
  DEBUG_MODE: 'false' (.env.defaults) → 'true' (.env.local)
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

Other Variables:
  APP_NAME = MyApplication (from .env.defaults)
  DEBUG_MODE = true (from .env.local)
```

## Error Handling

The command will stop and show an error if:
- Source files don't exist
- Less than two source files are provided
- Output file cannot be written (permissions, disk space, etc.)

## Best Practices

1. **Use descriptive file names** that indicate their purpose (`.env.base`, `.env.production`, `.env.local`)

2. **Order files by precedence** - place base/default files first, overrides last

3. **Use dry-run first** to preview results before committing to a merge

4. **Keep sensitive data in local files** that aren't committed to version control

5. **Document your merge strategy** in your project's README

6. **Backup important configurations** before merging

## Tips

- The merged file includes helpful comments showing when it was generated
- Variables are automatically organized by prefix for better readability
- Use the `--dry-run` option to understand what changes will be made
- The command validates all source files exist before starting the merge process