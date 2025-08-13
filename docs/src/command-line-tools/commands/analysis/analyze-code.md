# analyze code
*This command works correctly without options (parameters). Option support is under development and will be **available soon**.*

## ⚠️ Known Issues

1. This command may not display real-time processing details.  
2. Options (parameters) are not yet fully functional.


Analyzes code quality in your Wheels application, checking for best practices, potential issues, and code standards compliance.

## Usage

```bash
wheels analyze code [path] [--fix] [--format=<format>] [--severity=<severity>] [--report]
```

## Parameters

- `path` - (Optional) Path to analyze. Default: current directory (`.`)
- `--fix` - (Optional) Attempt to fix issues automatically
- `--format` - (Optional) Output format: `console`, `json`, `junit`. Default: `console`
- `--severity` - (Optional) Minimum severity level: `info`, `warning`, `error`. Default: `warning`
- `--report` - (Optional) Generate HTML report

*Parameters are **coming soon**. Currently, this command works without parameters*.


## Description

The `analyze code` command performs comprehensive code quality analysis on your Wheels application. It checks for:

- Code complexity and maintainability
- Adherence to Wheels coding standards
- Potential bugs and code smells
- Duplicate code detection
- Function length and complexity metrics
- Variable naming conventions
- Deprecated function usage

## Examples

### Basic code analysis
```bash
wheels analyze code
```

### Analyze specific directory
```bash
wheels analyze code app/controllers
```

### Auto-fix issues
```bash
wheels analyze code --fix
```

### Generate HTML report
```bash
wheels analyze code --report
```

### Analyze with JSON output for CI/CD
```bash
wheels analyze code --format=json
```

### Check only errors (skip warnings)
```bash
wheels analyze code --severity=error
```

### Analyze and fix specific path with report
```bash
wheels analyze code app/models --fix --report
```

## Output

The command provides detailed feedback including:

- **Complexity Score**: Cyclomatic complexity for functions
- **Code Standards**: Violations of Wheels conventions
- **Duplicate Code**: Similar code blocks that could be refactored
- **Suggestions**: Recommendations for improvement
- **Metrics Summary**: Overall code health indicators

## Notes

- Large codebases may take several minutes to analyze
- The `--fix` flag will automatically fix issues where possible
- HTML reports are saved to the `reports/` directory with timestamps
- Integration with CI/CD pipelines is supported via JSON and JUnit output formats
- Use `.wheelscheck` config file for custom rules and configurations