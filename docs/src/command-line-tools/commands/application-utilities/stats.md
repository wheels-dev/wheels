# wheels stats (coming Soon)
*This command may not work as expected. A complete and stable version is **coming soon**.*

Display comprehensive code statistics for your Wheels application.

## Synopsis

```bash
wheels stats [verbose=<boolean>]
```

## Description

The `stats` command analyzes your application's codebase and provides detailed statistics including lines of code, comments, file counts, and code quality metrics. It helps you understand the size and complexity of your application.

## Options

### verbose
- **Type**: Boolean
- **Default**: false
- **Description**: Show detailed statistics including largest files

## Examples

### Basic Statistics

```bash
wheels stats
```

Output:
```
Code Statistics
======================================================================
Type                Files     Lines     LOC       Comments  Blank
----------------------------------------------------------------------
Controllers         12        2,450     1,890     230       330
Models             8         3,200     2,750     180       270
Views              45        1,800     1,500     50        250
Helpers            3         450       380       40        30
Tests              23        4,500     3,800     200       500
Migrations         15        600       500       20        80
Config             5         300       250       30        20
Javascripts        10        2,000     1,600     200       200
Stylesheets        5         800       600       100       100
----------------------------------------------------------------------
Total              126       16,100    13,270    1,050     1,780

Code Metrics
======================================================================
Code to Test Ratio: 1:1.1 (110% test coverage by LOC)
Average Lines per File: 128
Average LOC per File: 105
Comment Percentage: 7%
```

### Verbose Output

```bash
wheels stats verbose=true
```

Additional output:
```
Detailed File Analysis
======================================================================
Largest Files (by LOC):
  1. app/models/User.cfc (450 LOC)
  2. app/controllers/Admin.cfc (380 LOC)
  3. tests/models/UserTest.cfc (350 LOC)
  4. app/models/Product.cfc (320 LOC)
  5. app/controllers/Products.cfc (290 LOC)
  6. public/javascripts/application.js (280 LOC)
  7. app/models/Order.cfc (250 LOC)
  8. tests/integration/CheckoutTest.cfc (240 LOC)
  9. app/controllers/Api.cfc (220 LOC)
  10. public/stylesheets/main.css (200 LOC)
```

## Metrics Explained

### File Types

- **Controllers**: Application controllers (*.cfc in /app/controllers)
- **Models**: Domain models (*.cfc in /app/models)
- **Views**: View templates (*.cfm in /app/views)
- **Helpers**: Helper functions (*.cfc in /app/helpers)
- **Tests**: Test files (*.cfc in /tests)
- **Migrations**: Database migrations (*.cfc in /db/migrate)
- **Config**: Configuration files (*.cfm, *.cfc in /config)
- **Javascripts**: JavaScript files (*.js in /public/javascripts)
- **Stylesheets**: CSS/SCSS files (*.css, *.scss, *.sass in /public/stylesheets)

### Statistics Columns

- **Files**: Number of files of this type
- **Lines**: Total lines including blanks and comments
- **LOC**: Lines of Code (actual code, excluding comments and blanks)
- **Comments**: Lines containing comments
- **Blank**: Empty lines

### Code Metrics

- **Code to Test Ratio**: Ratio of test LOC to application code LOC
- **Average Lines per File**: Total lines divided by file count
- **Average LOC per File**: Total LOC divided by file count
- **Comment Percentage**: Percentage of comments to total code

## Comment Detection

The command recognizes different comment styles:

### CFML Comments
```cfml
// Single line comment
<!--- Multi-line
      comment --->
```

### JavaScript Comments
```javascript
// Single line comment
/* Multi-line
   comment */
```

### CSS Comments
```css
/* CSS comment */
```

## Use Cases

### 1. Project Health Assessment
```bash
wheels stats
```
Check:
- Test coverage ratio (aim for 1:1 or higher)
- Comment percentage (5-15% is typical)
- File size distribution

### 2. Code Review Preparation
```bash
wheels stats verbose=true
```
Identify:
- Largest files that may need refactoring
- Areas with low test coverage
- Files lacking documentation

### 3. Project Documentation
```bash
wheels stats > project-stats.txt
```
Include in documentation to show:
- Project size and complexity
- Test coverage metrics
- Code organization

### 4. Refactoring Targets
Use verbose mode to find:
- Oversized files (>300 LOC)
- Controllers/models that do too much
- Areas needing more tests

## Best Practices

### Ideal Metrics

- **Code to Test Ratio**: 1:1 or higher
- **Average LOC per File**: 100-200 lines
- **Comment Percentage**: 5-15%
- **Largest Files**: Under 500 LOC

### Warning Signs

- Test ratio below 1:0.5 (50% coverage)
- Files over 500 LOC
- Comment percentage below 3%
- Controllers larger than models

## Interpreting Results

### Good Signs
- High test coverage (1:1 or better)
- Consistent file sizes
- Adequate comments
- More view files than controllers (proper MVC separation)

### Areas for Improvement
- Low test coverage (below 1:0.5)
- Very large files (over 500 LOC)
- Low comment percentage (under 3%)
- More controller code than model code

## Performance

The command efficiently analyzes files by:
- Reading files once
- Processing in memory
- Skipping binary files
- Ignoring vendor/modules directories

## Related Commands

- [`wheels about`](about.md) - General application information
- [`wheels notes`](notes.md) - Extract code annotations
- [`wheels test:coverage`](../testing/test-coverage.md) - Actual test coverage
- [`wheels analyze code`](../analysis/analyze-code.md) - Code quality analysis

## Tips

- Run regularly to track code growth
- Use verbose mode to identify refactoring candidates
- Compare stats before and after major features
- Set team standards for file sizes and test coverage

## Limitations

- LOC counting is line-based, not statement-based
- Test coverage ratio is based on LOC, not actual code coverage
- Comments in strings may be counted as comments
- Doesn't analyze code complexity or quality

## File Filters

The command uses these patterns:
- Controllers: `*.cfc` in `/app/controllers`
- Models: `*.cfc` in `/app/models`
- Views: `*.cfm` in `/app/views`
- Tests: `*.cfc` in `/tests`
- JavaScript: `*.js` in `/public/javascripts`
- CSS: `*.css`, `*.scss`, `*.sass` in `/public/stylesheets`