# analyze code

Analyzes code quality in your Wheels application, checking for best practices, potential issues, and code standards compliance.

## Synopsis

```bash
wheels analyze code [--path=<path>] [--fix] [--format=<format>] [--severity=<severity>] [--report] [--verbose]
```

## CommandBox Parameter Syntax

This command supports multiple parameter formats:

- **Named parameters**: `name=value` (e.g., `path=app/controllers`, `format=json`)
- **Flag parameters**: `--flag` equals `flag=true` (e.g., `--fix` equals `fix=true`)
- **Flag with value**: `--flag=value` equals `flag=value` (e.g., `--path=app/models`)

**Parameter Mixing Rules:**

**ALLOWED:**
- All flags: `wheels analyze code --fix --report --verbose`
- Flags with values: `wheels analyze code --path=app/models --format=json`
- Named + flags: `path=app/controllers format=json --fix`

**NOT ALLOWED:**
- Positional parameters: This command does not support positional parameters

**Recommendation:** Use flag syntax for consistency: `wheels analyze code --path=app/models --fix --format=json`

## Parameters

| Parameter   | Description                                                                 | Default     |
|-------------|-----------------------------------------------------------------------------|-------------|
| `--path`    | Path to analyze (directory or file)                                         | `app`       |
| `--fix`     | Attempt to fix issues automatically                                         | `false`     |
| `--format`  | Output format: `console`, `json`, `junit`                                   | `console`   |
| `--severity`| Minimum severity level: `info`, `warning`, `error`                          | `warning`   |
| `--report`  | Generate HTML report                                                        | `false`     |
| `--verbose` | Show detailed progress during analysis                                      | `false`     |

## Description

The `analyze code` command performs comprehensive code quality analysis on your Wheels application. It automatically excludes framework files and focuses only on your application code.

### What It Checks

- **Code Complexity**: Cyclomatic complexity and function length metrics
- **Code Style**: Line length, indentation, trailing spaces, tabs vs spaces
- **Security Issues**: SQL injection risks, hardcoded credentials, evaluate() usage
- **Performance**: N+1 queries, missing query caching, SELECT * usage
- **Best Practices**: Variable scoping, output attributes, code organization
- **Wheels Conventions**: Controller/Model naming, validations, filters
- **Code Smells**: Long parameter lists, nested loops, TODO comments
- **Duplicate Code**: Detection of similar code blocks (30+ lines by default)
- **Deprecated Functions**: Outdated Wheels function usage

### Grading System

The analyzer assigns a health score (0-100) and letter grade (A-F) based on:
- **A** (90-100): Excellent code quality
- **B** (80-89): Good code quality with minor issues
- **C** (70-79): Acceptable code quality, needs improvement
- **D** (60-69): Poor code quality, significant refactoring needed
- **F** (0-59): Critical issues, immediate attention required

## Examples

### Basic code analysis
Analyzes all code in the `app/` directory by default:
```bash
wheels analyze code
```

### Analyze specific directory
```bash
# Flag syntax (recommended)
wheels analyze code --path=app/controllers

# OR named
wheels analyze code path=app/controllers
```

### Analyze specific file
```bash
# Flag syntax (recommended)
wheels analyze code --path=app/models/User.cfc

# OR named
wheels analyze code path=app/models/User.cfc
```

### Auto-fix issues
Automatically fixes issues like trailing spaces, tabs, and missing var scoping:
```bash
wheels analyze code --fix
```

### Generate HTML report
Creates a detailed HTML report with visualizations:
```bash
wheels analyze code --report
```
Reports are saved to `reports/code-analysis-[timestamp].html`

### Analyze with JSON output for CI/CD
```bash
wheels analyze code --format=json
```

### JUnit format for CI integration
```bash
wheels analyze code --format=junit
```

### Check only errors (skip warnings and info)
```bash
wheels analyze code --severity=error
```

### Verbose mode with progress indicators
```bash
wheels analyze code --verbose
```

### Comprehensive analysis with all options
```bash
wheels analyze code --path=app/models --fix --report --verbose
```

## Output Format

### Console Output (Default)
```
Analyzing code quality...

Scanning for files... Found 51 files to analyze
Analyzing: [==================================================] 100% Complete!
Detecting duplicate code... Found 0 duplicate blocks


==================================================
               CODE QUALITY REPORT
==================================================

           Excellent code quality
==================================================


Code Metrics
--------------------------------------------------
Files Analyzed:           51
Total Lines:              1184
Functions:                51
Avg Complexity:           0
Duplicate Blocks:         0
Code Smells:              0
Deprecated Calls:         0


           Grade: A (100/100)
Excellent! No issues found. Your code is pristine!
```

### JSON Output
Structured JSON with all metrics, issues, and file details for programmatic processing.

### JUnit Output
XML format compatible with CI/CD tools like Jenkins, GitLab CI, and GitHub Actions.

## Configuration

Create a `.wheelscheck` file in your project root to customize rules:

```json
{
  "rules": {
    "max-line-length": 120,
    "indent-size": 4,
    "max-function-length": 50,
    "max-function-complexity": 10,
    "max-file-length": 500,
    "duplicate-threshold": 30,
    "naming-convention": "camelCase"
  },
  "features": {
    "duplicateDetection": true,
    "complexityAnalysis": true,
    "wheelsConventions": true,
    "codeSmells": true
  },
  "exclude": [
    "custom/path/to/exclude/",
    "generated/"
  ]
}
```

## Excluded Directories

The analyzer automatically excludes:
- Wheels framework files (`vendor/wheels/`, `wheels/`)
- Third-party dependencies (`vendor/`, `node_modules/`)
- Test frameworks (`testbox/`, `tests/`)
- Build artifacts (`build/`, `dist/`)
- Version control (`.git/`, `.svn/`)
- System directories (`WEB-INF/`, `CFIDE/`)
- Generated files (`*.min.js`, `*.min.css`)

## Auto-fixable Issues

The following issues can be automatically fixed with the `--fix` flag:
- Trailing whitespace
- Tab characters (converted to spaces)
- Missing var scoping in functions
- Missing output attribute on components

## Integration with CI/CD

### GitHub Actions
```yaml
- name: Code Analysis
  run: |
    wheels analyze code --format=junit --severity=error
```

### GitLab CI
```yaml
code_quality:
  script:
    - wheels analyze code --format=json > code-quality.json
  artifacts:
    reports:
      codequality: code-quality.json
```

### Jenkins
```groovy
stage('Code Analysis') {
    steps {
        sh 'wheels analyze code --format=junit'
        junit 'code-analysis-results.xml'
    }
}
```

## Performance Considerations

- **Small projects** (< 100 files): Analysis completes in seconds
- **Medium projects** (100-500 files): 30-60 seconds typical
- **Large projects** (500+ files): Several minutes, use `--verbose` to track progress
- HTML report generation adds 5-30 seconds depending on project size


## Tips

1. Run analysis regularly during development to catch issues early
2. Use `--fix` for quick cleanup before commits
3. Include analysis in pre-commit hooks or CI pipelines
4. Start with `--severity=error` and gradually include warnings
5. Review the HTML report for visual insights into code quality
6. Use the grade as a benchmark to track improvement over time
7. Focus on fixing high-complexity functions first for maximum impact

## Troubleshooting

### No files found to analyze
- Ensure you're in a Wheels application root directory
- Check that the `app/` directory exists
- Verify path permissions

### Analysis taking too long
- Use `--path` to analyze specific directories
- Add frequently changing directories to exclude list
- Consider splitting analysis across multiple runs

### Fix not working
- Some issues require manual intervention
- Check file permissions for write access
- Review the specific fix recommendations in the output