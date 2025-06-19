# Application Utilities Commands

The Application Utilities commands provide essential tools for inspecting, analyzing, and managing your Wheels application. These commands help you understand your application's structure, health, and performance.

## Available Commands

### Route Management
- [`wheels routes`](routes.md) - Display all application routes
- [`wheels routes:match`](routes-match.md) - Find which route matches a given URL

### Application Information
- [`wheels about`](about.md) - Display comprehensive application information
- [`wheels version`](../core/info.md#version) - Show version information

### Code Analysis
- [`wheels stats`](stats.md) - Display code statistics for your application
- [`wheels notes`](notes.md) - Extract and display code annotations (TODO, FIXME, etc.)

### Health & Dependencies
- [`wheels doctor`](doctor.md) - Run health checks on your application
- [`wheels deptree`](deptree.md) - Display dependency tree

## Quick Examples

### Inspect Routes
```bash
# Show all routes
wheels routes

# Filter routes
wheels routes name=users

# Output as JSON
wheels routes format=json

# Find matching route
wheels routes:match /users/123 method=GET
```

### Analyze Code
```bash
# Get code statistics
wheels stats

# Extract TODOs and FIXMEs
wheels notes

# Run health check
wheels doctor
```

### Check Dependencies
```bash
# Show dependency tree
wheels deptree

# Show only production dependencies
wheels deptree production=true
```

## Common Use Cases

### 1. Understanding Application Structure
When you're new to a Wheels application or returning after some time:
```bash
# Get overview
wheels about

# Check routes
wheels routes

# See code statistics
wheels stats
```

### 2. Code Quality Review
Before committing code or during code reviews:
```bash
# Check for TODOs
wheels notes

# Run health checks
wheels doctor

# Review statistics
wheels stats verbose=true
```

### 3. Debugging Route Issues
When a URL isn't working as expected:
```bash
# Find matching route
wheels routes:match /api/users/123

# Check all user routes
wheels routes name=user
```

### 4. Dependency Management
When updating or auditing dependencies:
```bash
# View full dependency tree
wheels deptree

# Check production dependencies only
wheels deptree production=true
```

## Best Practices

1. **Regular Health Checks**: Run `wheels doctor` regularly to catch configuration issues early

2. **Track Technical Debt**: Use `wheels notes` to track TODOs and technical debt

3. **Monitor Code Growth**: Use `wheels stats` to monitor code growth and maintain good test coverage

4. **Document Routes**: Keep route names descriptive and use `wheels routes` to verify routing setup

5. **Dependency Audits**: Regularly check dependencies with `wheels deptree` to identify outdated or unnecessary packages

## Related Commands

- [`wheels test`](../testing/test.md) - Run tests to ensure code quality
- [`wheels analyze`](../analysis/analyze.md) - Deep code analysis
- [`wheels deps`](../core/deps.md) - Manage Wheels-specific dependencies
- [`wheels env`](../environment/env.md) - Manage environments

## Tips

- Use `wheels doctor` before deploying to catch potential issues
- Export route information with `wheels routes format=json` for documentation
- Combine `wheels stats` with `wheels test:coverage` for comprehensive code metrics
- Use `wheels notes custom=HACK,REVIEW` to track custom annotations