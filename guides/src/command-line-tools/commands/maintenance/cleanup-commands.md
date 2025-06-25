# Cleanup Commands

## Overview

The cleanup commands help maintain your application by removing old log files, temporary files, and expired sessions. Regular cleanup improves performance, frees disk space, and keeps your application directory organized.

## Commands

### wheels cleanup:logs

Remove old log files from your application.

```bash
wheels cleanup:logs [days] [pattern] [directory] [--dryRun] [--force]
```

#### Parameters

- `days` - Number of days to keep logs (default: 7)
- `pattern` - File pattern to match (default: *.log)
- `directory` - Custom log directory (default: logs/)
- `--dryRun` - Show what would be deleted without actually deleting
- `--force` - Skip confirmation prompt

#### Examples

```bash
# Remove logs older than 7 days (default)
wheels cleanup:logs

# Keep last 30 days of logs
wheels cleanup:logs days=30

# Clean specific directory
wheels cleanup:logs directory="logs/custom"

# Match multiple patterns
wheels cleanup:logs pattern="*.log,*.txt"

# Preview without deleting
wheels cleanup:logs --dryRun

# Clean all logs immediately without confirmation
wheels cleanup:logs days=0 --force
```

#### Features

- Recursively scans for log files
- Shows file age and size statistics
- Removes empty directories after cleanup
- Detailed reporting of freed disk space

### wheels cleanup:tmp

Remove old temporary files from your application.

```bash
wheels cleanup:tmp [days] [directories] [patterns] [excludePatterns] [--dryRun] [--force]
```

#### Parameters

- `days` - Number of days to keep temporary files (default: 1)
- `directories` - Comma-separated list of directories to clean (default: tmp,temp,cache)
- `patterns` - Comma-separated list of file patterns to match (default: *,.*) 
- `excludePatterns` - Comma-separated list of patterns to exclude (default: .gitkeep,.gitignore)
- `--dryRun` - Show what would be deleted without actually deleting
- `--force` - Skip confirmation prompt

#### Examples

```bash
# Remove temp files older than 1 day (default)
wheels cleanup:tmp

# Keep last 3 days
wheels cleanup:tmp days=3

# Clean specific directories
wheels cleanup:tmp directories="tmp,temp,cache,uploads/temp"

# Custom file patterns
wheels cleanup:tmp patterns="*.tmp,*.cache,~*"

# Exclude important files
wheels cleanup:tmp excludePatterns=".gitkeep,important.tmp,*.lock"

# Preview cleanup
wheels cleanup:tmp --dryRun

# Force immediate cleanup
wheels cleanup:tmp days=0 --force
```

#### Features

- Cleans multiple temp directories
- Flexible pattern matching with exclusions
- Preserves important files (.gitkeep, .gitignore)
- Groups files by directory in output
- Removes empty directories after cleanup

### wheels cleanup:sessions

Remove expired session files from your application.

```bash
wheels cleanup:sessions [storage] [directory] [datasource] [table] [expiredOnly] [--dryRun] [--force]
```

#### Parameters

- `storage` - Session storage type: file or database (default: file)
- `directory` - Custom session directory for file storage (default: sessions/)
- `datasource` - Datasource name for database sessions
- `table` - Table name for database sessions (default: sessions)
- `expiredOnly` - Only remove expired sessions (default: true)
- `--dryRun` - Show what would be deleted without actually deleting
- `--force` - Skip confirmation prompt

#### Examples

```bash
# Clean file-based sessions
wheels cleanup:sessions

# Clean database sessions
wheels cleanup:sessions storage=database datasource=mydb

# Custom session directory
wheels cleanup:sessions directory="WEB-INF/lucee/sessions"

# Database with custom table
wheels cleanup:sessions \
  storage=database \
  datasource=mydb \
  table=user_sessions

# Delete all sessions (not just expired)
wheels cleanup:sessions expiredOnly=false --force

# Preview session cleanup
wheels cleanup:sessions --dryRun
```

#### Features

- Supports both file and database session storage
- Auto-detects common session directories:
  - `WEB-INF/cfclasses/sessions`
  - `WEB-INF/lucee/sessions`
  - `sessions/`
  - System temp directory
- Shows active vs expired session counts
- Configurable expiration detection (default: 2 hours)

## Best Practices

### 1. Schedule Regular Cleanups

Add to your cron jobs or scheduled tasks:

```bash
# Daily cleanup at 2 AM
0 2 * * * cd /path/to/app && wheels cleanup:logs days=7 --force
0 3 * * * cd /path/to/app && wheels cleanup:tmp days=1 --force
0 4 * * * cd /path/to/app && wheels cleanup:sessions --force
```

### 2. Test with Dry Run First

Always preview what will be deleted:

```bash
# Check what will be deleted
wheels cleanup:logs --dryRun
wheels cleanup:tmp --dryRun
wheels cleanup:sessions --dryRun

# If looks good, run the actual cleanup
wheels cleanup:logs --force
wheels cleanup:tmp --force
wheels cleanup:sessions --force
```

### 3. Monitor Disk Usage

```bash
# Check disk usage before cleanup
df -h

# Run cleanup commands
wheels cleanup:logs days=30 --force
wheels cleanup:tmp --force
wheels cleanup:sessions --force

# Check disk usage after cleanup
df -h
```

### 4. Deployment Cleanup

Include in your deployment script:

```bash
#!/bin/bash
# deployment.sh

# Clean up before deployment
wheels cleanup:tmp --force
wheels cleanup:sessions expiredOnly=false --force

# Deploy new code
git pull
wheels dbmigrate latest

# Clean up old logs after deployment
wheels cleanup:logs days=30 --force
```

### 5. Different Retention Policies

Set different retention periods based on file type:

```bash
# Keep error logs longer
wheels cleanup:logs pattern="error*.log" days=90
wheels cleanup:logs pattern="access*.log" days=7
wheels cleanup:logs pattern="debug*.log" days=1

# Clean different temp directories with different policies
wheels cleanup:tmp directories="cache" days=7
wheels cleanup:tmp directories="uploads/temp" days=1
wheels cleanup:tmp directories="tmp" days=0
```

## Output Examples

### Log Cleanup Output

```
Scanning for log files older than 7 days...
Cutoff date: 2024-01-08 10:30:00

Found 15 log file(s) to clean up:

┌─────────────────┬──────────┬──────────┬─────────────────────┐
│ File            │ Age      │ Size     │ Modified            │
├─────────────────┼──────────┼──────────┼─────────────────────┤
│ app.log.1       │ 10 days  │ 2.3 MB   │ 2024-01-05 14:23    │
│ app.log.2       │ 15 days  │ 1.8 MB   │ 2023-12-31 09:15    │
│ error.log.old   │ 30 days  │ 512 KB   │ 2023-12-16 18:45    │
└─────────────────┴──────────┴──────────┴─────────────────────┘

Total size to be freed: 4.6 MB

✓ Successfully deleted 15 log file(s).
✓ Freed 4.6 MB of disk space.
✓ Removed 2 empty directories.
```

### Session Cleanup Output

```
Scanning session files in: /app/WEB-INF/lucee/sessions

Session summary:
  Total sessions: 127
  Expired sessions: 89
  Active sessions: 38

Found 89 session file(s) to clean up:

Summary by age:
┌─────────────┬───────┐
│ Age Range   │ Count │
├─────────────┼───────┤
│ 2-24 hours  │ 45    │
│ 1-7 days    │ 32    │
│ > 7 days    │ 12    │
└─────────────┴───────┘

Total size to be freed: 1.2 MB

✓ Successfully deleted 89 session file(s).
✓ Freed 1.2 MB of disk space.
```

## Troubleshooting

### Permission Errors

If you get permission errors:

```bash
# Run with appropriate user
sudo -u www-data wheels cleanup:logs --force

# Or fix permissions
chmod -R 755 logs/
chown -R www-data:www-data logs/
```

### Files Not Being Detected

1. Check the directory path is correct
2. Verify the file pattern matches your files
3. Use `--dryRun` to see what's being scanned
4. Check if files are excluded by excludePatterns

### Session Cleanup Issues

1. For file sessions, ensure correct directory:
   ```bash
   # Find session files
   find / -name "*.cfm" -path "*/sessions/*" 2>/dev/null
   ```

2. For database sessions, verify table structure:
   ```sql
   -- Check if expires column exists
   DESCRIBE sessions;
   ```

## Performance Tips

1. **Run during off-peak hours** to minimize impact
2. **Clean incrementally** - don't let files accumulate for months
3. **Monitor cleanup duration** - adjust retention if taking too long
4. **Use specific patterns** to avoid scanning unnecessary files

## Related Commands

- [wheels cache:clear](../assets-cache-management.md) - Clear application caches
- [wheels maintenance:on](./maintenance-mode.md) - Enable maintenance during cleanup
- [wheels stats](../application-utilities/stats.md) - View application statistics