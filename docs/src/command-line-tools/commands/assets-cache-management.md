# Asset & Cache Management (Coming Soon)
*These commands may not work as expected. A complete and stable version is **coming soon**.*


The Wheels CLI provides comprehensive commands for managing assets, caches, logs, and temporary files in your application. These commands help optimize performance, clean up disk space, and maintain your application.

## Overview

Asset and cache management commands are organized into four categories:

- **Asset Commands** (`wheels assets*`) - Compile, clean, and manage static assets
- **Cache Commands** (`wheels cache*`) - Clear various application caches
- **Log Commands** (`wheels log*`) - Manage and view log files
- **Temp Commands** (`wheels tmp*`) - Clean temporary files and directories

## Asset Management

### Precompiling Assets

The `wheels assets precompile` command prepares your assets for production deployment by minifying and optimizing them.

```bash
# Basic precompilation
wheels assets precompile

# Force recompilation of all assets
wheels assets precompile --force

# Target specific environment
wheels assets precompile --environment=staging
```

**What it does:**
- Minifies JavaScript files (removes comments and whitespace)
- Minifies CSS files (removes comments, whitespace, optimizes rules)
- Generates cache-busted filenames with MD5 hashes
- Creates a manifest.json file mapping original to compiled filenames
- Copies images with cache-busted names
- Stores all compiled assets in `/public/assets/compiled/`

**Example manifest.json:**
```json
{
  "application.js": "application-a1b2c3d4.min.js",
  "styles.css": "styles-e5f6g7h8.min.css",
  "logo.png": "logo-i9j0k1l2.png"
}
```

### Cleaning Old Assets

The `wheels assets clean` command removes old compiled assets while keeping recent versions.

```bash
# Clean old assets (keeps 3 versions by default)
wheels assets clean

# Keep 5 versions of each asset
wheels assets clean --keep=5

# Preview what would be deleted
wheels assets clean --dryRun
```

This is useful for:
- Freeing disk space after multiple deployments
- Keeping a few recent versions for rollback capability
- Maintaining a clean assets directory

### Removing All Assets

The `wheels assets clobber` command completely removes all compiled assets.

```bash
# Remove all compiled assets (with confirmation)
wheels assets clobber

# Skip confirmation prompt
wheels assets clobber --force
```

**Warning:** This command deletes all compiled assets and the manifest file. You'll need to run `wheels assets precompile` again before deploying.

## Cache Management

### Understanding Cache Types

Wheels uses several cache types to improve performance:

- **Query Cache**: Stores database query results
- **Page Cache**: Stores complete rendered HTML pages
- **Partial Cache**: Stores rendered view fragments
- **Action Cache**: Stores controller action results
- **SQL Cache**: Stores parsed SQL file contents

### Clearing Caches

The `wheels cache clear` command manages these caches:

```bash
# Clear all caches (with confirmation)
wheels cache clear

# Clear all caches without confirmation
wheels cache clear --force

# Clear specific cache type
wheels cache clear query      # Database query results
wheels cache clear page       # Full page cache
wheels cache clear partial    # View fragments
wheels cache clear action     # Controller actions
wheels cache clear sql        # SQL file cache
```

**Note:** The command automatically reloads the application after clearing caches to ensure changes take effect.

## Log Management

### Clearing Log Files

The `wheels log clear` command manages application log files:

```bash
# Clear all log files (with confirmation)
wheels log clear

# Clear specific environment logs
wheels log clear --environment=production

# Clear logs older than 30 days
wheels log clear --days=30

# Combine options
wheels log clear --environment=production --days=7 --force
```

### Tailing Log Files

The `wheels log tail` command displays log content in real-time:

```bash
# Tail development log (default)
wheels log tail

# Tail production log
wheels log tail --environment=production

# Show last 50 lines
wheels log tail --lines=50

# Tail specific log file
wheels log tail --file=custom.log

# Non-follow mode (just display and exit)
wheels log tail --follow=false
```

**Log Entry Color Coding:**
- 🔴 **Red**: ERROR level messages
- 🟡 **Yellow**: WARN/WARNING level messages
- 🔵 **Cyan**: INFO level messages
- ⚪ **Grey**: DEBUG level messages

Press `Ctrl+C` to stop following the log file.

## Temporary Files Management

### Clearing Temporary Files

The `wheels tmp clear` command manages temporary files:

```bash
# Clear all temporary files (with confirmation)
wheels tmp clear

# Skip confirmation
wheels tmp clear --force

# Clear specific types
wheels tmp clear cache        # Cache files only
wheels tmp clear sessions     # Session files only
wheels tmp clear uploads      # Upload files only

# Clear files older than 7 days
wheels tmp clear --days=7

# Combine options
wheels tmp clear --type=sessions --days=30 --force
```

The command also cleans up empty directories after removing files.

## Best Practices

### Production Deployment

1. **Before Deployment:**
   ```bash
   # Compile assets
   wheels assets precompile --environment=production
   
   # Clean old assets
   wheels assets clean --keep=3
   ```

2. **After Deployment:**
   ```bash
   # Clear all caches
   wheels cache clear all --force
   
   # Monitor logs
   wheels log tail --environment=production
   ```

### Regular Maintenance

Create a maintenance script for regular cleanup:

```bash
#!/bin/bash
# maintenance.sh

# Clear old logs (older than 30 days)
wheels log clear --days=30 --force

# Clear old temp files (older than 7 days)
wheels tmp clear --days=7 --force

# Clean old assets (keep last 5 versions)
wheels assets clean --keep=5

# Clear query cache
wheels cache clear query --force
```

### Development Workflow

During development:

```bash
# Watch logs while developing
wheels log tail

# Clear cache after model changes
wheels cache clear query

# Clear all caches when debugging
wheels cache clear all --force

# Clean temp files periodically
wheels tmp clear --force
```

## Troubleshooting

### Assets Not Updating

If assets aren't updating in production:

```bash
# Force recompilation
wheels assets:precompile --force

# Clear all caches
wheels cache clear all --force

# Verify manifest
cat public/assets/compiled/manifest.json
```

### Cache Not Clearing

If caches don't seem to clear:

```bash
# Check cache directories
ls -la tmp/cache/

# Force application reload
wheels reload --force

# Clear specific cache with reload
wheels cache clear query && wheels reload
```

### Log File Issues

If log files are missing or not updating:

```bash
# Check log directory
ls -la logs/

# Create new log file
wheels log clear --environment=development

# Check permissions
ls -la logs/*.log
```

### Disk Space Issues

To free up disk space:

```bash
# Check disk usage
du -sh tmp/ logs/ public/assets/compiled/

# Clean everything
wheels assets clean --keep=1
wheels log clear --days=7 --force
wheels tmp clear --force
wheels cache clear all --force
```

## Configuration

### Asset Configuration

In your Wheels settings:

```cfscript
// config/settings.cfm
set(assetsCacheMinutes = 1440); // 24 hours
set(assetsPath = "/assets");
set(useAssetFingerprinting = true);
```

### Cache Configuration

```cfscript
// config/settings.cfm
set(cacheQueries = true);
set(cachePages = true);
set(cachePartials = true);
set(cacheActions = true);
set(cacheCullPercentage = 10);
set(cacheCullInterval = 5);
set(maximumItemsToCache = 5000);
set(defaultCacheTime = 60); // minutes
```

### Log Configuration

```cfscript
// config/settings.cfm
set(logSQL = false); // Set to true in development
set(logQueries = false); // Set to true for debugging
```

## Integration with CI/CD

### GitHub Actions Example

```yaml
# .github/workflows/deploy.yml
- name: Compile Assets
  run: wheels assets precompile --environment=production

- name: Clean Old Assets
  run: wheels assets clean --keep=3

- name: Clear Caches
  run: wheels cache clear all --force
```

### Docker Integration

```dockerfile
# Dockerfile
RUN wheels assets precompile --environment=production
RUN wheels assets clean --keep=1
```

## Summary

The asset and cache management commands provide essential tools for maintaining a healthy Wheels application:

- **Assets**: Compile for production, clean old versions, remove all when needed
- **Caches**: Clear specific or all caches to ensure fresh data
- **Logs**: Monitor in real-time, clean old files to save space
- **Temp Files**: Regular cleanup prevents disk space issues

Regular use of these commands as part of your deployment and maintenance routines will keep your application running smoothly and efficiently.