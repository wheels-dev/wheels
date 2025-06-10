# wheels optimize

Base command for application optimization.

## Synopsis

```bash
wheels optimize [subcommand] [options]
```

## Description

The `wheels optimize` command provides tools to improve your Wheels application's performance. It analyzes and optimizes various aspects including database queries, asset delivery, caching strategies, and code execution.

## Subcommands

| Command | Description |
|---------|-------------|
| `performance` | Comprehensive performance optimization |

## Options

| Option | Description |
|--------|-------------|
| `--help` | Show help information |
| `--version` | Show version information |

## Direct Usage

When called without subcommands, runs automatic optimizations:

```bash
wheels optimize
```

This performs:
1. Database query optimization
2. Asset minification and bundling
3. Cache configuration
4. Code optimization

## Examples

### Run all optimizations
```bash
wheels optimize
```

### Optimize with detailed output
```bash
wheels optimize --verbose
```

### Dry run to preview changes
```bash
wheels optimize --dry-run
```

### Optimize specific areas
```bash
wheels optimize --only=database,assets
```

## Optimization Areas

### Database
- Index analysis and creation
- Query optimization
- Connection pooling
- Cache configuration

### Assets
- JavaScript minification
- CSS optimization
- Image compression
- Bundle creation

### Caching
- Query cache setup
- Page cache configuration
- Object cache optimization
- CDN integration

### Code
- Dead code elimination
- Function optimization
- Memory usage reduction
- Startup time improvement

## Output Example

```
Wheels Application Optimization
==============================

Analyzing application...
✓ Scanned 245 files
✓ Analyzed 1,234 queries
✓ Checked 456 assets

Optimizations Applied:
---------------------

Database (4 optimizations)
  ✓ Added index on users.email
  ✓ Added composite index on orders(user_id, created_at)
  ✓ Optimized slow query in ProductModel.cfc
  ✓ Enabled query caching for static queries

Assets (3 optimizations)
  ✓ Minified 23 JavaScript files (saved 145KB)
  ✓ Optimized 15 CSS files (saved 67KB)
  ✓ Compressed 34 images (saved 2.3MB)

Caching (2 optimizations)
  ✓ Configured Redis for object caching
  ✓ Enabled page caching for static routes

Code (3 optimizations)
  ✓ Removed 12 unused functions
  ✓ Optimized application startup
  ✓ Reduced memory footprint by 15%

Performance Impact:
  - Page load time: -32% (2.4s → 1.6s)
  - Database queries: -45% (avg 23ms → 12ms)
  - Memory usage: -15% (512MB → 435MB)
  - Startup time: -20% (8s → 6.4s)
```

## Configuration

Configure via `.wheels-optimize.json`:

```json
{
  "optimize": {
    "database": {
      "autoIndex": true,
      "queryCache": true,
      "slowQueryThreshold": 100
    },
    "assets": {
      "minify": true,
      "bundle": true,
      "compress": true,
      "compressionQuality": 85
    },
    "cache": {
      "provider": "redis",
      "ttl": 3600,
      "autoEvict": true
    },
    "code": {
      "removeDeadCode": true,
      "optimizeStartup": true,
      "memoryOptimization": true
    }
  }
}
```

## Optimization Strategies

### Development Mode
Focuses on developer experience:
```bash
wheels optimize --env=development
```
- Faster rebuilds
- Source maps preserved
- Debug information retained

### Production Mode
Maximum performance:
```bash
wheels optimize --env=production
```
- Aggressive minification
- Dead code elimination
- Maximum compression

### Balanced Mode
Balance between size and debuggability:
```bash
wheels optimize --mode=balanced
```

## Advanced Options

### Selective Optimization
```bash
# Only database optimizations
wheels optimize --only=database

# Exclude asset optimization
wheels optimize --skip=assets

# Specific optimizations
wheels optimize --optimizations=minify,compress,index
```

### Performance Budgets
```bash
# Set performance budgets
wheels optimize --budget-js=200kb --budget-css=50kb

# Fail if budgets exceeded
wheels optimize --strict-budgets
```

## Integration

### Build Process
```json
{
  "scripts": {
    "build": "wheels optimize --env=production",
    "build:dev": "wheels optimize --env=development"
  }
}
```

### CI/CD Pipeline
```yaml
- name: Optimize application
  run: |
    wheels optimize --env=production
    wheels optimize --verify
```

## Optimization Reports

### Generate Report
```bash
wheels optimize --report=optimization-report.html
```

### Report Contents
- Before/after metrics
- Optimization details
- Performance graphs
- Recommendations

## Rollback

If optimizations cause issues:

```bash
# Create backup before optimizing
wheels optimize --backup

# Rollback to backup
wheels optimize --rollback

# Rollback specific optimization
wheels optimize --rollback=database
```

## Best Practices

1. **Test After Optimization**: Verify functionality
2. **Monitor Performance**: Track real-world impact
3. **Incremental Approach**: Optimize gradually
4. **Keep Backups**: Enable rollback capability
5. **Document Changes**: Track what was optimized

## Performance Monitoring

After optimization:
```bash
# Verify optimizations
wheels optimize --verify

# Performance benchmark
wheels optimize --benchmark

# Compare before/after
wheels optimize --compare
```

## Common Issues

### Over-optimization
- Breaking functionality
- Debugging difficulties
- Longer build times

### Solutions
- Use balanced mode
- Keep source maps in development
- Test thoroughly

## Use Cases

1. **Pre-deployment**: Optimize before production
2. **Performance Issues**: Fix slow applications
3. **Cost Reduction**: Reduce resource usage
4. **User Experience**: Improve load times
5. **Scalability**: Prepare for growth

## Notes

- Always backup before optimization
- Some optimizations require restart
- Monitor application after optimization
- Optimization impact varies by application

## See Also

- [wheels optimize performance](optimize-performance.md) - Detailed performance optimization
- [wheels analyze performance](../analysis/analyze-performance.md) - Performance analysis
- [wheels cache](../core/cache.md) - Cache management
- [wheels config](../config/config.md) - Configuration management