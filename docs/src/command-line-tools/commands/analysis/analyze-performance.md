# analyze performance

Analyzes application performance, identifying bottlenecks and optimization opportunities in your Wheels application.

## Usage

```bash
wheels analyze performance [--target=<target>] [--duration=<seconds>] [--report] [--threshold=<ms>] [--profile]
```

## Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `--target` | Analysis target: `all`, `controller`, `view`, `query`, `memory` | `all` |
| `--duration` | Duration to run analysis in seconds (1-300) | `30` |
| `--report` | Generate HTML performance report with charts | `false` |
| `--threshold` | Performance threshold in milliseconds for slow requests | `100` |
| `--profile` | Enable profiling mode for real metrics (when available) | `false` |

## Description

The `analyze performance` command monitors your Wheels application to identify performance bottlenecks and provide optimization recommendations. It tracks metrics in real-time and provides both console output and optional HTML reports.

### What It Monitors

- **Request Performance**: Response times, slow requests, controller/action patterns
- **Database Queries**: Query execution times, slow queries, query patterns
- **Memory Usage**: Memory consumption, peak usage, memory trends
- **View Rendering**: Template rendering times (when target includes views)
- **Overall Health**: Performance score and grade (A-F)

### Performance Grading

The analyzer assigns a performance grade based on collected metrics:
- **A** (90-100): Excellent performance
- **B** (80-89): Good performance
- **C** (70-79): Acceptable performance
- **D** (60-69): Poor performance, optimization needed
- **F** (0-59): Critical performance issues

## Examples

### Basic performance analysis
Monitor all metrics for 30 seconds:
```bash
wheels analyze performance
```

### Extended monitoring
Analyze for 2 minutes:
```bash
wheels analyze performance --duration=120
```

### Focus on database performance
Monitor only database queries:
```bash
wheels analyze performance --target=query
```

### Focus on memory usage
Monitor only memory consumption:
```bash
wheels analyze performance --target=memory
```

### Adjust performance threshold
Set slow request threshold to 200ms:
```bash
wheels analyze performance --threshold=200
```

### Enable profiling mode
Attempt to collect real metrics (if available):
```bash
wheels analyze performance --profile
```

### Generate HTML report
Create a detailed HTML report with charts:
```bash
wheels analyze performance --report
```

### Complete analysis
Full analysis with all options:
```bash
wheels analyze performance --target=all --duration=60 --threshold=200 --profile --report
```

## Output Format

### Console Output

```
Analyzing application performance...

Starting performance monitoring for 30 seconds...
Target: all
Threshold: 100ms

[====================] 100% Complete!

==================================================
       PERFORMANCE ANALYSIS COMPLETE
==================================================

Data Source: SIMULATED (Enable --profile for real data)

Request Performance
--------------------------------------------------
Requests Analyzed:          42
Average Response Time:     156ms
Slowest Request:          891ms
Fastest Request:           23ms
Slow Requests (>100ms):     18

Database Performance
--------------------------------------------------
Queries Executed:           42
Average Query Time:        28ms
Slow Queries (>50ms):       8

Memory Usage
--------------------------------------------------
Average Memory:           193MB
Peak Memory:              205MB

Top Slow Requests:
--------------------------------------------------
  1. reports.index() - 891ms
  2. users.create() - 645ms
  3. products.update() - 523ms
  4. orders.index() - 412ms
  5. dashboard.show() - 387ms

Top Slow Queries:
--------------------------------------------------
  1. SELECT * FROM orders WHERE id = ? - 187ms
  2. UPDATE products WHERE id = ? - 156ms
  3. SELECT * FROM users WHERE id = ? - 98ms

==================================================
Performance Grade: B (83/100)
==================================================

Performance Recommendations:
--------------------------------------------------
  * Implement caching strategies for frequently accessed data
  * Optimize database queries and add appropriate indexes
  * Enable query result caching in production
  * Minimize database round trips
  * Use connection pooling for database connections
```

### HTML Report

The HTML report includes:
- **Performance Dashboard**: Visual metrics with color-coded indicators
- **Performance Grade**: Large visual display of grade and score
- **Charts**: 
  - Response time trends over monitoring period
  - Memory usage over time
- **Detailed Tables**:
  - Top 10 slow requests with timing
  - Top 10 slow queries with execution times
- **Recommendations**: Context-aware optimization suggestions

Reports are saved to: `reports/performance-[timestamp].html`

## Data Collection

### Simulated Mode (Default)
- Generates realistic performance patterns
- Useful for testing and demonstration
- Provides consistent baseline metrics

### Profile Mode (--profile)
When enabled, attempts to:
- Access ColdFusion's metrics service
- Hook into Wheels debug information
- Collect real request/response times
- Capture actual query execution data
- Falls back to simulation if real data unavailable

## Performance Thresholds

Default thresholds used for categorization:
- **Slow Requests**: > 100ms (configurable via --threshold)
- **Slow Queries**: > 50ms (fixed)
- **High Memory**: > 500MB
- **Response Time Categories**:
  - Fast: < 100ms
  - Moderate: 100-300ms
  - Slow: > 300ms

## Recommendations

The analyzer provides context-aware recommendations based on:
- **High Average Response Time** (>200ms): Suggests caching strategies
- **Slow Queries Detected**: Recommends indexing and query optimization
- **High Memory Usage** (>500MB): Suggests memory optimization
- **Multiple Slow Requests**: Recommends async processing and lazy loading

## Integration

### CI/CD Pipeline
Exit codes for automation:
- `0`: Performance acceptable
- `1`: Performance issues detected (slow requests or queries found)

Example Jenkins integration:
```groovy
stage('Performance Check') {
    steps {
        sh 'wheels analyze performance --duration=60 --threshold=200'
    }
}
```

### Monitoring Strategy
1. Run regularly in staging environment
2. Compare metrics over time to track improvements
3. Use HTML reports for stakeholder communication
4. Set appropriate thresholds based on application requirements

## Best Practices

1. **Baseline First**: Establish performance baselines before optimization
2. **Target Specific Areas**: Use --target to focus on suspected bottlenecks
3. **Realistic Load**: Run during typical usage patterns for accurate results
4. **Profile Mode**: Enable --profile when real metrics are needed
5. **Regular Monitoring**: Schedule regular performance checks
6. **Track Trends**: Save reports to track performance over time

## Limitations

- **Simulated Data**: Default mode uses simulated data; enable --profile for real metrics
- **Single Instance**: Monitors single application instance only
- **External Services**: Doesn't track external API or service calls
- **Browser Performance**: Server-side only, doesn't measure client-side performance

## Troubleshooting

### No real data with --profile
- Ensure application has debug mode available
- Check ColdFusion administrator settings
- Verify appropriate permissions for metrics access

### High memory usage reported
- Normal for JVM applications
- Monitor trends rather than absolute values
- Consider JVM heap settings

### All requests showing as slow
- Adjust threshold to match application expectations
- Check if application is under unusual load
- Verify database connection pool settings