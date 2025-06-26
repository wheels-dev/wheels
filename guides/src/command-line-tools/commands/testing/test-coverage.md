# wheels test coverage

Generate code coverage reports for your test suite.

## Synopsis

```bash
wheels test coverage [options]
```

## Description

The `wheels test coverage` command runs your test suite while collecting code coverage metrics. It generates detailed reports showing which parts of your code are tested and identifies areas that need more test coverage.

## Options

| Option | Description | Default |
|--------|-------------|---------|
| `--type` | Type of tests to run: app, core, or plugin | `app` |
| `--servername` | Name of server to reload | (current server) |
| `--reload` | Force a reload of wheels | `false` |
| `--debug` | Show debug info | `false` |
| `--output-dir` | Directory to output the coverage report | `tests/coverageReport` |

## Examples

### Generate basic coverage report
```bash
wheels test coverage
```

### Generate coverage for core tests
```bash
wheels test coverage --type=core
```

### Custom output directory
```bash
wheels test coverage --output-dir=reports/coverage
```

### Force reload before coverage
```bash
wheels test coverage --reload --debug
```

### Coverage for specific server
```bash
wheels test coverage --servername=myapp
```

## What It Does

1. **Instruments Code**: Adds coverage tracking to your application
2. **Runs Tests**: Executes all specified tests
3. **Collects Metrics**: Tracks which lines are executed
4. **Generates Reports**: Creates coverage reports in requested formats
5. **Analyzes Results**: Provides insights and recommendations

## Coverage Metrics

### Line Coverage
Percentage of code lines executed:
```
File: /app/models/User.cfc
Lines: 156/200 (78%)
```

### Function Coverage
Percentage of functions tested:
```
Functions: 45/50 (90%)
```

### Branch Coverage
Percentage of code branches tested:
```
Branches: 120/150 (80%)
```

### Statement Coverage
Percentage of statements executed:
```
Statements: 890/1000 (89%)
```

## Report Formats

### HTML Report
Interactive web-based report:
```bash
wheels test coverage --format=html
```

Features:
- File browser
- Source code viewer
- Line-by-line coverage
- Sortable metrics
- Trend charts

### JSON Report
Machine-readable format:
```bash
wheels test coverage --format=json
```

```json
{
  "summary": {
    "lines": { "total": 1000, "covered": 850, "percent": 85 },
    "functions": { "total": 100, "covered": 92, "percent": 92 },
    "branches": { "total": 200, "covered": 160, "percent": 80 }
  },
  "files": {
    "/app/models/User.cfc": {
      "lines": { "total": 200, "covered": 156, "percent": 78 }
    }
  }
}
```

### XML Report
For CI/CD integration:
```bash
wheels test coverage --format=xml
```

Compatible with:
- Jenkins
- GitLab CI
- GitHub Actions
- SonarQube

### Console Report
Quick terminal output:
```bash
wheels test coverage --format=console
```

```
Code Coverage Report
===================

Overall Coverage: 85.3%

File                          Lines    Funcs    Branch   Stmt
---------------------------- -------- -------- -------- --------
/app/models/User.cfc           78.0%    85.0%    72.0%    80.0%
/app/models/Order.cfc          92.0%    95.0%    88.0%    90.0%
/app/controllers/Users.cfc     85.0%    90.0%    82.0%    86.0%

Uncovered Files:
- /app/models/Legacy.cfc (0%)
- /app/helpers/Deprecated.cfc (0%)
```

## Coverage Thresholds

### Global Threshold
```bash
wheels test coverage --threshold=80
```

### Per-Metric Thresholds
Configure in `.wheels-coverage.json`:
```json
{
  "thresholds": {
    "global": 80,
    "lines": 85,
    "functions": 90,
    "branches": 75,
    "statements": 85
  }
}
```

### File-Specific Thresholds
```json
{
  "thresholds": {
    "global": 80,
    "files": {
      "/app/models/User.cfc": 90,
      "/app/models/Order.cfc": 95
    }
  }
}
```

## Configuration

### Coverage Configuration File
`.wheels-coverage.json`:
```json
{
  "include": [
    "app/models/**/*.cfc",
    "app/controllers/**/*.cfc"
  ],
  "exclude": [
    "app/models/Legacy.cfc",
    "**/*Test.cfc"
  ],
  "reporters": ["html", "json"],
  "reportDir": "./coverage",
  "thresholds": {
    "global": 80
  },
  "watermarks": {
    "lines": [50, 80],
    "functions": [50, 80],
    "branches": [50, 80],
    "statements": [50, 80]
  }
}
```

## Integration

### CI/CD Pipeline
```yaml
- name: Run tests with coverage
  run: |
    wheels test coverage --format=xml --threshold=80 --fail-on-low
    
- name: Upload coverage
  uses: codecov/codecov-action@v3
  with:
    file: ./coverage/coverage.xml
```

### Git Hooks
`.git/hooks/pre-push`:
```bash
#!/bin/bash
wheels test coverage --threshold=80 --fail-on-low
```

### Badge Generation
```bash
wheels test coverage --format=badge > coverage-badge.svg
```

## Analyzing Results

### Identify Untested Code
The HTML report highlights:
- **Red**: Uncovered lines
- **Yellow**: Partially covered branches
- **Green**: Fully covered code

### Focus Areas
1. **Critical Paths**: Ensure high coverage
2. **Complex Logic**: Test all branches
3. **Error Handling**: Cover edge cases
4. **New Features**: Maintain coverage

## Best Practices

1. **Set Realistic Goals**: Start with achievable thresholds
2. **Incremental Improvement**: Gradually increase thresholds
3. **Focus on Quality**: 100% coverage doesn't mean bug-free
4. **Test Business Logic**: Prioritize critical code
5. **Regular Monitoring**: Track coverage trends

## Performance Considerations

Coverage collection adds overhead:
- Slower test execution
- Increased memory usage
- Larger test artifacts

Tips:
- Run coverage in CI/CD, not every test run
- Use incremental coverage for faster feedback
- Exclude third-party code

## Troubleshooting

### Low Coverage
- Check if tests are actually running
- Verify include/exclude patterns
- Look for untested files

### Coverage Not Collected
- Ensure code is instrumented
- Check file path patterns
- Verify test execution

### Report Generation Failed
- Check output directory permissions
- Verify report format support
- Review error logs

## Advanced Usage

### Incremental Coverage
```bash
# Coverage for changed files only
wheels test coverage --since=HEAD~1
```

### Coverage Trends
```bash
# Generate trend data
wheels test coverage --save-baseline

# Compare with baseline
wheels test coverage --compare-baseline
```

### Merge Coverage
```bash
# From multiple test runs
wheels test coverage --merge coverage1.json coverage2.json
```

## Notes

- Coverage data is collected during test execution
- Some code may be unreachable and shouldn't count
- Focus on meaningful coverage, not just percentages
- Different metrics provide different insights

## See Also

- [wheels test](test.md) - Run tests
- [wheels test run](test-run.md) - Run specific tests
- [wheels test debug](test-debug.md) - Debug test execution
- [Testing Best Practices](../../testing/best-practices.md)