# Performance Analysis Commands

The Wheels CLI provides tools to analyze and optimize the performance of your application.

## Analyze

Identify performance bottlenecks in your Wheels application.

### Usage

```bash
wheels analyze [--target=all] [--duration=60] [--report=true] [--threshold=5]
```

### Parameters

- `target`: Analysis target (controller, view, query, memory, or all) (default: all)
- `duration`: Duration to run analysis in seconds (default: 60)
- `report`: Generate HTML report (default: true)
- `threshold`: Threshold for reporting issues (1-10, where 10 is most severe) (default: 5)

### Examples

```bash
# Run a complete analysis with default settings
wheels analyze

# Analyze only controller performance
wheels analyze --target=controller

# Run a quick analysis for 30 seconds
wheels analyze --duration=30

# Run a detailed analysis with a lower threshold to catch more issues
wheels analyze --threshold=3
```

### Analysis Targets

#### Controller Analysis

Examines controller performance, including:

- Execution time by controller and action
- Number of calls to each controller
- Slow controller actions
- Inefficient controller patterns

#### View Analysis

Examines view rendering performance, including:

- Render time for each view
- View size and complexity
- View caching effectiveness
- Inefficient view patterns

#### Query Analysis

Examines database query performance, including:

- Query execution time
- Number of calls to each query
- Slow queries
- Query optimization opportunities
- Inefficient query patterns

#### Memory Analysis

Examines memory usage, including:

- Memory usage by component
- Memory leaks
- Excessive memory consumption
- Memory optimization opportunities

### Analysis Report

The HTML report includes:

- Executive summary of findings
- Detailed analysis by category
- Charts and graphs of performance metrics
- Recommendations for improvement
- Code snippets highlighting problem areas

## Performance Optimization Best Practices

### Controller Optimization

1. **Minimize Logic**: Keep controllers thin and move business logic to models
2. **Caching**: Use caching for expensive operations
3. **Lazy Loading**: Only load what you need when you need it
4. **Async Operations**: Use asynchronous operations for non-critical tasks

### View Optimization

1. **Partial Caching**: Cache rendered partials that don't change often
2. **Minimize View Logic**: Keep complex logic out of views
3. **Optimize Loops**: Avoid nested loops in views
4. **CSS/JS Optimization**: Minify and combine CSS and JavaScript files

### Query Optimization

1. **Index Key Columns**: Ensure frequently queried columns are indexed
2. **Limit Result Sets**: Only retrieve the data you need
3. **Join Optimization**: Optimize joins and avoid unnecessary joins
4. **Query Caching**: Cache query results when appropriate

### Memory Optimization

1. **Clean Up Resources**: Properly close resources when done
2. **Variable Scope**: Use the appropriate variable scope
3. **Limit Session Data**: Only store necessary data in session
4. **Garbage Collection**: Be mindful of garbage collection

## Using the Analyze Command for Ongoing Optimization

### Regular Analysis

Schedule regular performance analysis to catch issues early:

```bash
# Weekly performance check
wheels analyze --report=true --duration=120
```

### Pre-Release Analysis

Run more thorough analysis before major releases:

```bash
# Comprehensive pre-release analysis
wheels analyze --threshold=3 --duration=300
```

### Performance Regression Testing

Use the analyze command to detect performance regressions:

```bash
# Create a baseline performance report
wheels analyze --target=all

# After making changes, compare with baseline
wheels analyze --target=all
```

### Production Performance Monitoring

While the `analyze` command is primarily for development and testing, you can apply similar principles to production monitoring:

1. Use the patterns identified in development analysis to set up production monitoring
2. Set up alerts for when performance metrics exceed thresholds
3. Regularly compare production performance with development analysis baselines

## Understanding Analysis Results

The performance analysis provides metrics and recommendations that you can use to optimize your application:

### Performance Metrics

- **Response Time**: How long it takes to process a request
- **Execution Time**: How long each component takes to execute
- **Memory Usage**: How much memory is consumed
- **Call Count**: How often each component is called

### Severity Levels

The analysis uses severity levels (1-10) to prioritize issues:

- **1-3**: Minor issues that may not need immediate attention
- **4-6**: Moderate issues that should be addressed
- **7-8**: Serious issues that require attention
- **9-10**: Critical issues that need immediate action

By addressing high-severity issues first, you can make the most significant performance improvements with the least effort.