# analyze performance

Analyzes application performance, identifying bottlenecks and optimization opportunities in your CFWheels application.

## Usage

```bash
wheels analyze performance [--target=<target>] [--duration=<seconds>] [--report] [--threshold=<ms>] [--profile]
```

## Parameters

- `--target` - (Optional) Analysis target: `all`, `controller`, `view`, `query`, `memory`. Default: `all`
- `--duration` - (Optional) Duration to run analysis in seconds. Default: `30`
- `--report` - (Optional) Generate HTML performance report
- `--threshold` - (Optional) Performance threshold in milliseconds. Default: `100`
- `--profile` - (Optional) Enable profiling mode

## Description

The `analyze performance` command profiles your CFWheels application to identify performance bottlenecks and provide optimization recommendations. It monitors:

- Request execution times
- Database query performance
- Memory usage patterns
- Cache effectiveness
- View rendering times
- Component instantiation overhead

## Examples

### Basic performance analysis
```bash
wheels analyze performance
```

### Analyze for 60 seconds with profiling
```bash
wheels analyze performance --duration=60 --profile
```

### Focus on database queries only
```bash
wheels analyze performance --target=query
```

### Show only slow operations (>500ms)
```bash
wheels analyze performance --threshold=500
```

### Generate HTML performance report
```bash
wheels analyze performance --report
```

### Complete analysis with all options
```bash
wheels analyze performance --target=all --duration=60 --threshold=200 --profile --report
```

## Output

The analysis provides:

- **Slowest Requests**: Top 10 slowest request paths
- **Query Analysis**: Slow queries and N+1 query detection
- **Memory Hotspots**: Areas of high memory allocation
- **Cache Statistics**: Hit/miss ratios for various caches
- **Recommendations**: Specific optimization suggestions

### Sample Output
```
Performance Analysis Results
===========================

Slowest Requests:
1. GET /users/search (avg: 850ms, calls: 45)
2. POST /orders/create (avg: 650ms, calls: 12)
3. GET /reports/generate (avg: 1200ms, calls: 8)

Database Issues:
- N+1 queries detected in UsersController.index
- Slow query in Order.findRecent() - 450ms avg
- Missing index suggested for users.created_at

Memory Usage:
- High allocation in ReportService.generate()
- Potential memory leak in SessionManager

Recommendations:
1. Add eager loading to UsersController.index
2. Create index on users.created_at
3. Implement query result caching for Order.findRecent()
```

## Notes

- Profiling adds minimal overhead to your application
- Best run in a staging environment with production-like data
- Can be integrated with APM tools for continuous monitoring
- Results are aggregated across all application instances