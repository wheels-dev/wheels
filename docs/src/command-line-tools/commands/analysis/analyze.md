# wheels analyze
*These commands works correctly without options (parameters). Option support is under development and will be **available soon**.*

Base command for code analysis and quality checks.

## Synopsis

```bash
wheels analyze [subcommand] [options]
```

## Description

The `wheels analyze` command provides comprehensive code analysis tools for Wheels applications. It helps identify code quality issues, performance bottlenecks, and provides actionable insights for improvement.

## Subcommands

| Command | Description |
|---------|-------------|
| `code` | Analyze code quality and patterns |
| `performance` | Analyze performance characteristics |


## Direct Usage

When called without subcommands, show list of available commands:

```bash
wheels analyze help
```

## Analysis Overview

The analyze [code, performance] commands examines:

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

## Best Practices

1. Run analysis regularly
2. Fix high-priority issues first
3. Set realistic quality gates
4. Track metrics over time
5. Integrate with development workflow

## Troubleshooting

### Analysis Takes Too Long
- Exclude wheels directories
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
- [wheels test](../testing/test.md) - Run tests