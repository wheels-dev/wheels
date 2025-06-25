# wheels notes

Extract and display code annotations like TODO, FIXME, and OPTIMIZE from your application.

## Synopsis

```bash
wheels notes [annotations=<list>] [custom=<list>] [verbose=<boolean>]
```

## Description

The `notes` command scans your application code for annotations (comments with special markers) and displays them in an organized format. This helps track technical debt, pending tasks, and areas needing attention.

## Options

### annotations
- **Type**: String (comma-separated list)
- **Default**: TODO,FIXME,OPTIMIZE
- **Description**: Annotations to search for

### custom
- **Type**: String (comma-separated list)
- **Default**: (none)
- **Description**: Additional custom annotations to search for

### verbose
- **Type**: Boolean
- **Default**: false
- **Description**: Show file paths with line numbers

## Examples

### Basic Usage

Find default annotations:
```bash
wheels notes
```

Output:
```
Code Annotations
Searching for: TODO, FIXME, OPTIMIZE
======================================================================

Application:
  [TODO] Add validation for email format
  [TODO] Implement password reset functionality
  [FIXME] Handle null values in calculateTotal()
  [OPTIMIZE] Cache this query result

Tests:
  [TODO] Add integration tests for checkout process
  [FIXME] Mock external API calls

======================================================================
Summary:
  TODO: 3
  FIXME: 2
  OPTIMIZE: 1

Total annotations: 6
```

### Verbose Output

Show with file locations:
```bash
wheels notes verbose=true
```

Output:
```
Application:

  app/models/User.cfc:45
  TODO: Add validation for email format

  app/controllers/Auth.cfc:78
  TODO: Implement password reset functionality

  app/models/Order.cfc:123
  FIXME: Handle null values in calculateTotal()
```

### Specific Annotations

Search for only TODOs:
```bash
wheels notes TODO
```

Search for multiple:
```bash
wheels notes TODO,FIXME
```

### Custom Annotations

Add custom markers:
```bash
wheels notes custom=HACK,REVIEW
```

Search only custom markers:
```bash
wheels notes annotations="" custom=HACK,SECURITY,PERFORMANCE
```

## Supported Comment Formats

The command recognizes annotations in various comment styles:

### CFML Comments
```cfml
// TODO: Implement this feature
<!--- FIXME: This needs error handling --->
// TODO Add validation (colon optional)
```

### JavaScript Comments
```javascript
// TODO: Refactor this function
/* FIXME: Memory leak here */
// HACK: Temporary workaround
```

### CSS Comments
```css
/* TODO: Add responsive styles */
/* OPTIMIZE: Combine these selectors */
```

### Other Formats
```cfml
## TODO: Document this method (Markdown-style)
```

## Annotation Guidelines

### TODO
Use for:
- Features to implement
- Code to write
- Documentation to add

Example:
```cfml
// TODO: Add email notification when order ships
```

### FIXME
Use for:
- Broken code that needs fixing
- Known bugs
- Error handling gaps

Example:
```cfml
// FIXME: This breaks when user.name is null
```

### OPTIMIZE
Use for:
- Performance improvements needed
- Inefficient algorithms
- Caching opportunities

Example:
```cfml
// OPTIMIZE: This query runs on every request
```

### Custom Annotations

Common custom annotations:

- **HACK**: Temporary workarounds
- **REVIEW**: Code needing review
- **SECURITY**: Security concerns
- **DEPRECATED**: Code to be removed
- **PERFORMANCE**: Performance bottlenecks
- **REFACTOR**: Code needing refactoring

## Search Locations

The command searches in:

### Application
- `/app/**/*.cfc` - Controllers, Models
- `/app/**/*.cfm` - Views

### Configuration
- `/config/**/*.cfm` - Configuration files
- `/config/**/*.cfc` - Configuration components

### Tests
- `/tests/**/*.cfc` - Test files

### Migrations
- `/db/migrate/**/*.cfc` - Database migrations

### Assets (with JavaScript/CSS support)
- `/public/javascripts/**/*.js` - JavaScript files
- `/public/stylesheets/**/*.css` - CSS files

## Use Cases

### 1. Sprint Planning
```bash
# Find all pending tasks
wheels notes TODO verbose=true
```

### 2. Code Review
```bash
# Check for issues before merging
wheels notes FIXME,HACK verbose=true
```

### 3. Technical Debt Tracking
```bash
# Regular debt assessment
wheels notes TODO,FIXME,OPTIMIZE,REFACTOR
```

### 4. Security Audit
```bash
# Find security-related notes
wheels notes custom=SECURITY,VULNERABILITY
```

### 5. Performance Review
```bash
# Find optimization opportunities
wheels notes OPTIMIZE custom=PERFORMANCE,SLOW
```

## Best Practices

### Writing Good Annotations

1. **Be Specific**
   ```cfml
   // TODO: Add email validation using regex pattern for corporate emails
   // Not: TODO: Add validation
   ```

2. **Include Context**
   ```cfml
   // FIXME: calculateTax() returns negative values when discount > subtotal
   ```

3. **Add Names/Dates**
   ```cfml
   // TODO (john.doe - 2024-01): Implement after payment gateway is ready
   ```

4. **Link to Issues**
   ```cfml
   // FIXME: Issue #1234 - Handle UTF-8 characters in exports
   ```

### Team Standards

Establish conventions:
- Which annotations to use
- When to add them
- Format requirements
- Review frequency

## Output Organization

Annotations are grouped by location:
- **Application**: Core application code
- **Configuration**: Config files
- **Tests**: Test suite
- **Migrations**: Database migrations

## Integration Ideas

### Git Hooks
```bash
# Pre-commit hook to check TODOs
if wheels notes TODO | grep -q "TODO"; then
  echo "Warning: TODOs found"
fi
```

### CI/CD Pipeline
```bash
# Fail if critical issues exist
wheels notes FIXME custom=CRITICAL,BLOCKER
```

### Documentation
```bash
# Export for project docs
wheels notes verbose=true > technical-debt.txt
```

## Related Commands

- [`wheels stats`](stats.md) - Code statistics
- [`wheels analyze code`](../analysis/analyze-code.md) - Code quality analysis
- [`wheels test`](../testing/test.md) - Run tests

## Tips

- Review annotations regularly (weekly/sprint)
- Remove completed TODOs promptly
- Convert important TODOs to issue tracker tickets
- Use consistent annotation formats across the team
- Consider annotation count as a code quality metric

## Performance

The command is optimized to:
- Read files only once
- Use efficient regex matching
- Skip binary files
- Process files in memory

## Limitations

- Only searches comments, not string contents
- May miss annotations in unconventional comment formats
- Doesn't integrate with issue tracking systems
- No priority or categorization beyond annotation type