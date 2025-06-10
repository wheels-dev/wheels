# wheels analyze

Base command for code analysis and quality checks.

## Synopsis

```bash
wheels analyze [subcommand] [options]
```

## Description

The `wheels analyze` command provides comprehensive code analysis tools for Wheels applications. It helps identify code quality issues, performance bottlenecks, security vulnerabilities, and provides actionable insights for improvement.

## Subcommands

| Command | Description |
|---------|-------------|
| `code` | Analyze code quality and patterns |
| `performance` | Analyze performance characteristics |
| `security` | Security vulnerability analysis (deprecated) |

## Options

| Option | Description |
|--------|-------------|
| `--help` | Show help information |
| `--version` | Show version information |

## Direct Usage

When called without subcommands, runs all analyses:

```bash
wheels analyze
```

This executes:
1. Code quality analysis
2. Performance analysis
3. Security scanning (if not deprecated)

## Examples

### Run all analyses
```bash
wheels analyze
```

### Quick analysis with summary
```bash
wheels analyze --summary
```

### Analyze specific directory
```bash
wheels analyze --path=./models
```

### Generate analysis report
```bash
wheels analyze --report=html --output=./analysis-report
```

## Analysis Overview

The analyze command examines:

### Code Quality
- Coding standards compliance
- Code complexity metrics
- Duplication detection
- Best practices adherence

### Performance
- N+1 query detection
- Slow query identification
- Memory usage patterns
- Cache effectiveness

### Security
- SQL injection risks
- XSS vulnerabilities
- Insecure configurations
- Outdated dependencies

## Output Example

```
Wheels Code Analysis Report
==========================

Code Quality
------------
✓ Files analyzed: 234
✓ Total lines: 12,456
⚠ Issues found: 23
  - High priority: 3
  - Medium priority: 12
  - Low priority: 8

Performance
-----------
✓ Queries analyzed: 156
⚠ Potential N+1 queries: 4
⚠ Slow queries detected: 2
✓ Cache hit ratio: 87%

Security (Deprecated)
--------------------
! Security analysis has been deprecated
! Use 'wheels security scan' instead

Summary Score: B+ (82/100)
```

## Analysis Configuration

Configure via `.wheels-analysis.json`:

```json
{
  "analyze": {
    "exclude": [
      "vendor/**",
      "tests/**",
      "*.min.js"
    ],
    "rules": {
      "complexity": {
        "maxComplexity": 10,
        "maxDepth": 4
      },
      "duplication": {
        "minLines": 5,
        "threshold": 0.05
      }
    },
    "performance": {
      "slowQueryThreshold": 1000,
      "cacheTargetRatio": 0.8
    }
  }
}
```

## Integration with CI/CD

### GitHub Actions Example
```yaml
- name: Run code analysis
  run: |
    wheels analyze --format=json --output=analysis.json
    wheels analyze --format=badge > analysis-badge.svg
```

### Quality Gates
Set minimum scores:
```bash
wheels analyze --min-score=80 --fail-on-issues=high
```

## Report Formats

### HTML Report
```bash
wheels analyze --report=html
```
- Interactive dashboard
- Detailed issue breakdown
- Code snippets with issues

### JSON Report
```bash
wheels analyze --format=json
```
- Machine-readable format
- CI/CD integration
- Custom processing

### Markdown Report
```bash
wheels analyze --format=markdown
```
- Documentation-friendly
- Pull request comments
- Wiki integration

## Analysis Rules

### Built-in Rules
- CFScript best practices
- SQL query optimization
- Security patterns
- Memory management

### Custom Rules
Create custom rules in `.wheels-analysis-rules/`:
```javascript
module.exports = {
  name: "custom-rule",
  check: function(file, content) {
    // Rule implementation
  }
};
```

## Baseline

Track improvement over time:

```bash
# Create baseline
wheels analyze --save-baseline

# Compare with baseline
wheels analyze --compare-baseline
```

## Ignoring Issues

### Inline Comments
```cfml
// wheels-analyze-ignore-next-line
complexQuery = ormExecuteQuery(sql, params);

/* wheels-analyze-ignore-start */
// Complex code block
/* wheels-analyze-ignore-end */
```

### Configuration File
```json
{
  "ignore": [
    {
      "rule": "sql-injection",
      "file": "legacy/*.cfc"
    }
  ]
}
```

## Performance Tips

1. **Incremental Analysis**: Analyze only changed files
2. **Parallel Processing**: Use multiple cores
3. **Cache Results**: Reuse analysis for unchanged files
4. **Focused Scans**: Target specific directories

## Use Cases

1. **Pre-commit Hooks**: Catch issues before commit
2. **Pull Request Checks**: Automated code review
3. **Technical Debt**: Track and reduce over time
4. **Team Standards**: Enforce coding guidelines
5. **Performance Monitoring**: Identify bottlenecks

## Best Practices

1. Run analysis regularly
2. Fix high-priority issues first
3. Set realistic quality gates
4. Track metrics over time
5. Integrate with development workflow

## Troubleshooting

### Analysis Takes Too Long
- Exclude vendor directories
- Use incremental mode
- Increase memory allocation

### Too Many False Positives
- Tune rule sensitivity
- Add specific ignores
- Update rule definitions

## Notes

- First run may take longer due to initial scanning
- Results are cached for performance
- Some rules require database connection
- Memory usage scales with codebase size

## See Also

- [wheels analyze code](analyze-code.md) - Code quality analysis
- [wheels analyze performance](analyze-performance.md) - Performance analysis
- [wheels security scan](../security/security-scan.md) - Security scanning
- [wheels test](../testing/test.md) - Run tests