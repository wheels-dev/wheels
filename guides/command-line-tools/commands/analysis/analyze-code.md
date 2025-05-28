# analyze code

Analyzes code quality in your CFWheels application, checking for best practices, potential issues, and code standards compliance.

## Usage

```bash
wheels analyze code [path] [--type=<type>] [--format=<format>] [--output=<file>]
```

## Parameters

- `path` - (Optional) Specific file or directory to analyze. Defaults to entire application.
- `--type` - (Optional) Type of analysis: `all`, `complexity`, `standards`, `duplication`. Default: `all`
- `--format` - (Optional) Output format: `console`, `json`, `html`. Default: `console`
- `--output` - (Optional) File path to save analysis results

## Description

The `analyze code` command performs comprehensive code quality analysis on your CFWheels application. It checks for:

- Code complexity and maintainability
- Adherence to CFWheels coding standards
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

### Check only for code duplication
```bash
wheels analyze code --type=duplication
```

### Generate HTML report
```bash
wheels analyze code --format=html --output=reports/code-analysis.html
```

### Analyze complexity for models
```bash
wheels analyze code app/models --type=complexity
```

## Output

The command provides detailed feedback including:

- **Complexity Score**: Cyclomatic complexity for functions
- **Code Standards**: Violations of CFWheels conventions
- **Duplicate Code**: Similar code blocks that could be refactored
- **Suggestions**: Recommendations for improvement
- **Metrics Summary**: Overall code health indicators

## Notes

- Large codebases may take several minutes to analyze
- The complexity threshold can be configured in settings
- HTML reports include interactive charts and detailed breakdowns
- Integration with CI/CD pipelines is supported via JSON output