# optimize performance

Automatically applies performance optimizations to your CFWheels application based on analysis results.

## Usage

```bash
wheels optimize performance [target] [--aggressive] [--dry-run] [--backup]
```

## Parameters

- `target` - (Optional) Target area to optimize. Default: current directory
- `--aggressive` - (Optional) Apply aggressive optimizations that may change behavior
- `--dry-run` - (Optional) Show what would be changed without applying
- `--backup` - (Optional) Create backup before applying changes

## Description

The `optimize performance` command automatically implements performance improvements identified through analysis. It can:

- Add database indexes
- Implement query result caching
- Optimize asset delivery
- Enable application-level caching
- Refactor inefficient code patterns
- Configure performance settings

## Examples

### Basic optimization
```bash
wheels optimize performance
```

### Optimize specific directory
```bash
wheels optimize performance app/models
```

### Preview changes without applying
```bash
wheels optimize performance --dry-run
```

### Aggressive optimization with backup
```bash
wheels optimize performance --aggressive --backup
```

### Optimize entire application aggressively
```bash
wheels optimize performance . --aggressive
```

## Optimization Targets

### Database
- Creates missing indexes
- Optimizes slow queries
- Adds query hints
- Implements connection pooling
- Configures query caching

### Caching
- Enables view caching
- Implements action caching
- Configures cache headers
- Sets up CDN integration
- Optimizes cache keys

### Assets
- Minifies CSS/JavaScript
- Implements asset fingerprinting
- Configures compression
- Optimizes images
- Sets up asset pipeline

### Code
- Refactors N+1 queries
- Implements lazy loading
- Optimizes loops
- Reduces object instantiation
- Improves algorithm efficiency

## Output

```
Performance Optimization
========================

Analyzing application... ✓
Creating backup... ✓

Applying optimizations:

Database Optimizations:
✓ Added index on users.email
✓ Added composite index on orders(user_id, created_at)
✓ Implemented query caching for User.findActive()
✓ Optimized ORDER BY clause in Product.search()

Caching Optimizations:
✓ Enabled action caching for ProductsController.index
✓ Added fragment caching to product listings
✓ Configured Redis for session storage
✓ Set cache expiration for static content

Asset Optimizations:
✓ Minified 15 JavaScript files (saved 145KB)
✓ Compressed 8 CSS files (saved 62KB)
✓ Enabled gzip compression
✓ Configured browser caching headers

Code Optimizations:
✓ Fixed N+1 query in OrdersController.index
✓ Replaced 3 array loops with cfloop query
✓ Implemented lazy loading for User.orders
~ Skipped: Complex refactoring in ReportService (requires --aggressive)

Summary:
- Applied: 18 optimizations
- Skipped: 3 (require manual review or --aggressive flag)
- Estimated improvement: 35-40% faster page loads

Next steps:
1. Run 'wheels reload' to apply changes
2. Test application thoroughly
3. Monitor performance metrics
```

## Dry Run Mode

Preview changes without applying them:

```bash
wheels optimize performance --dry-run

Optimization Preview
====================

Would apply the following changes:

1. Database: Create index on users.email
   SQL: CREATE INDEX idx_users_email ON users(email);

2. Cache: Enable action caching for ProductsController.index
   File: /app/controllers/ProductsController.cfc
   Add: <cfset caches(action="index", time=30)>

3. Query: Optimize Product.search()
   File: /app/models/Product.cfc
   Change: Add query hint for index usage

[... more changes ...]

Run without --dry-run to apply these optimizations.
```

## Aggressive Mode

Enables optimizations that may change application behavior:

```bash
wheels optimize performance --aggressive

Additional aggressive optimizations:
✓ Converted synchronous operations to async
✓ Implemented aggressive query result caching
✓ Reduced session timeout to 20 minutes
✓ Disabled debug output in production
✓ Implemented database connection pooling
⚠️ Changed default query timeout to 10 seconds
```

## Backup and Rollback

Backups are created automatically:

```bash
Backup created: /backups/optimize-backup-20240115-143022.zip

To rollback:
wheels optimize rollback --backup=optimize-backup-20240115-143022.zip
```

## Configuration

Customize optimization behavior in `/config/optimizer.json`:

```json
{
  "database": {
    "autoIndex": true,
    "indexThreshold": 1000,
    "queryTimeout": 30
  },
  "caching": {
    "defaultDuration": 3600,
    "cacheQueries": true
  },
  "assets": {
    "minify": true,
    "compress": true,
    "cdnEnabled": false
  }
}
```

## Notes

- Always test optimizations in a staging environment first
- Some optimizations require application restart
- Monitor application after applying optimizations
- Use `wheels analyze performance` to measure improvements
- Aggressive optimizations should be carefully reviewed