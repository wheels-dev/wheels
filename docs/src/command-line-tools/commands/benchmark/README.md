---
description: >-
  Benchmarking commands for performance testing, analysis, and optimization of
  your Wheels application.
---

# Benchmark Commands

Wheels provides comprehensive benchmarking tools to measure, analyze, and optimize the performance of your applications. These tools help identify bottlenecks, track performance improvements, and ensure optimal application performance.

## Available Commands

### Core Benchmarking Commands
- `wheels benchmark run` - Run performance benchmarks
- `wheels benchmark compare` - Compare benchmark results
- `wheels benchmark report` - Generate performance reports

### Specialized Benchmarks
- `wheels benchmark database` - Database query performance
- `wheels benchmark memory` - Memory usage analysis
- `wheels benchmark load` - Load testing and stress testing

## Quick Start

### Basic Performance Benchmark
```bash
# Run comprehensive benchmark
wheels benchmark run

# Run specific benchmark category
wheels benchmark run --category=database

# Generate detailed report
wheels benchmark report --format=html --output=performance-report.html
```

## Benchmark Categories

### Application Performance
- **Request Processing** - HTTP request/response performance
- **Controller Actions** - Individual controller method performance
- **Model Operations** - ORM and database operation performance
- **View Rendering** - Template rendering performance
- **Asset Processing** - Static asset handling performance

### System Resources
- **CPU Usage** - Processor utilization during operations
- **Memory Consumption** - RAM usage patterns and optimization
- **Disk I/O** - File system operation performance
- **Network Performance** - External API and service calls

### Database Performance
- **Query Execution** - SQL query performance analysis
- **Connection Pooling** - Database connection efficiency
- **Transaction Performance** - Database transaction overhead
- **ORM Overhead** - ActiveRecord vs. raw SQL performance

## Benchmark Configuration

### Configuration File
Create `/config/benchmark.cfm` for benchmark settings:

```cfm
<cfscript>
// Benchmark configuration
benchmark = {
    // General settings
    iterations = 1000,
    warmupRounds = 10,
    timeout = 30,

    // Test categories
    categories = {
        controllers = {
            enabled = true,
            actions = ["index", "show", "create", "update", "delete"]
        },
        models = {
            enabled = true,
            operations = ["findAll", "findByKey", "create", "update", "delete"]
        },
        database = {
            enabled = true,
            queries = ["simple", "complex", "joins", "aggregates"]
        }
    },

    // Performance thresholds
    thresholds = {
        responseTime = {
            excellent = 100,  // ms
            good = 500,       // ms
            acceptable = 1000, // ms
            poor = 2000       // ms
        },
        memoryUsage = {
            excellent = 10,   // MB
            good = 50,        // MB
            acceptable = 100, // MB
            poor = 200        // MB
        }
    }
};
</cfscript>
```

## Running Benchmarks

### Basic Benchmark Execution
```bash
wheels benchmark run
```
**Output:**
```
🚀 Running Wheels Performance Benchmarks
==================================================

Starting benchmark suite...

[1/6] Controller Performance
├── UsersController.index: 156ms avg (excellent)
├── UsersController.show: 89ms avg (excellent)
├── UsersController.create: 234ms avg (good)
├── UsersController.update: 198ms avg (good)
└── UsersController.delete: 145ms avg (excellent)

[2/6] Model Performance
├── User.findAll: 45ms avg (excellent)
├── User.findByKey: 12ms avg (excellent)
├── User.create: 67ms avg (excellent)
├── User.update: 52ms avg (excellent)
└── User.delete: 23ms avg (excellent)

[3/6] Database Performance
├── Simple queries: 8ms avg (excellent)
├── Complex queries: 156ms avg (excellent)
├── Join operations: 89ms avg (excellent)
└── Aggregate queries: 234ms avg (good)

[4/6] View Performance
├── Layout rendering: 34ms avg (excellent)
├── Partial rendering: 12ms avg (excellent)
└── Form helpers: 18ms avg (excellent)

[5/6] Memory Usage
├── Base memory: 45MB (excellent)
├── Peak memory: 78MB (excellent)
└── Memory leaks: None detected

[6/6] System Resources
├── CPU usage: 15% avg (excellent)
├── Disk I/O: 2.3MB/s (good)
└── Network: 450KB/s (excellent)

Summary:
✅ Overall Performance: Excellent
✅ Response Time: 143ms avg
✅ Memory Efficiency: Good
✅ Resource Usage: Optimal

All benchmarks completed successfully!
```

### Advanced Benchmarking
```bash
# Custom iteration count
wheels benchmark run --iterations=5000

# Specific test categories
wheels benchmark run --category=database,memory

# Load testing with concurrent users
wheels benchmark load --users=100 --duration=300

# Memory profiling
wheels benchmark memory --profile --gc-analysis
```

## Performance Analysis

### Detailed Metrics
Each benchmark provides comprehensive metrics:

- **Response Time Statistics**
  - Average, median, 95th percentile, 99th percentile
  - Min/max response times
  - Standard deviation

- **Throughput Measurements**
  - Requests per second
  - Operations per second
  - Data transfer rates

- **Resource Utilization**
  - CPU usage patterns
  - Memory allocation and deallocation
  - Disk I/O operations
  - Network bandwidth usage

### Performance Trends
```bash
# Track performance over time
wheels benchmark run --save-results --tag=v1.2.0

# Compare with previous versions
wheels benchmark compare --baseline=v1.1.0 --current=v1.2.0

# Generate trend report
wheels benchmark report --trend --period=30days
```

## Database Benchmarking

### Query Performance Analysis
```bash
# Analyze specific queries
wheels benchmark database --queries=custom --config=slow-queries.json

# ORM vs. Raw SQL comparison
wheels benchmark database --compare-orm

# Connection pool optimization
wheels benchmark database --connection-pool --sizes=5,10,20,50
```

### Sample Database Benchmark Results
```
📊 Database Performance Analysis
==================================================

Query Performance:
├── Simple SELECT: 8ms avg (1,250 ops/sec)
├── JOIN operations: 45ms avg (222 ops/sec)
├── Complex WHERE: 23ms avg (434 ops/sec)
├── Aggregate functions: 156ms avg (64 ops/sec)
└── Subqueries: 89ms avg (112 ops/sec)

ORM Performance:
├── findAll(): 45ms avg (ORM overhead: +12ms)
├── findByKey(): 12ms avg (ORM overhead: +4ms)
├── create(): 67ms avg (ORM overhead: +8ms)
└── update(): 52ms avg (ORM overhead: +6ms)

Connection Pool Analysis:
├── Pool size 5: 234ms avg response
├── Pool size 10: 156ms avg response (optimal)
├── Pool size 20: 167ms avg response
└── Pool size 50: 189ms avg response

Recommendations:
✅ Optimize aggregate queries (add indexes)
✅ Connection pool size 10 is optimal
⚠️  Consider query caching for complex operations
```

## Memory Benchmarking

### Memory Usage Analysis
```bash
# Comprehensive memory analysis
wheels benchmark memory --full-analysis

# Memory leak detection
wheels benchmark memory --leak-detection --duration=3600

# Garbage collection analysis
wheels benchmark memory --gc-profiling
```

### Memory Analysis Results
```
🧠 Memory Usage Analysis
==================================================

Memory Allocation:
├── Application startup: 45MB
├── Peak usage: 156MB
├── Average usage: 78MB
└── Memory growth rate: 0.2MB/hour

Garbage Collection:
├── GC frequency: Every 2.3 minutes
├── Average GC time: 12ms
├── Memory recovered: 15MB avg
└── GC efficiency: 94%

Memory Hotspots:
├── User session data: 23MB (29%)
├── Database query cache: 18MB (23%)
├── Template cache: 12MB (15%)
└── Static assets: 8MB (10%)

Recommendations:
✅ Memory usage within acceptable limits
⚠️  Consider session cleanup optimization
✅ GC performance is good
```

## Load Testing

### Stress Testing
```bash
# Simulate concurrent users
wheels benchmark load --users=500 --ramp-up=60 --duration=300

# API endpoint stress testing
wheels benchmark load --endpoint=/api/users --method=POST --users=200

# Database load testing
wheels benchmark load --database --connections=100 --queries=1000
```

### Load Test Results
```
🔥 Load Testing Results
==================================================

Test Configuration:
├── Concurrent users: 500
├── Ramp-up time: 60 seconds
├── Test duration: 5 minutes
└── Target endpoints: All

Performance Metrics:
├── Average response time: 234ms
├── 95th percentile: 567ms
├── 99th percentile: 1.2s
├── Requests per second: 2,145
├── Total requests: 643,500
└── Failed requests: 0.02%

Resource Usage:
├── CPU usage: 65% avg, 89% peak
├── Memory usage: 245MB avg, 312MB peak
├── Disk I/O: 15MB/s avg
└── Network: 2.3GB total transferred

Bottlenecks Identified:
⚠️  Database connection pool at capacity
⚠️  CPU usage peaks during traffic spikes
✅ Memory usage stable
✅ Network bandwidth sufficient

Recommendations:
📈 Increase database connection pool to 25
📈 Consider CPU scaling for peak traffic
📈 Implement request queuing for traffic spikes
```

## Performance Optimization

### Automated Optimization Suggestions
The benchmarking tools provide actionable optimization recommendations:

#### Database Optimizations
- **Index Recommendations** - Missing indexes for slow queries
- **Query Optimization** - Inefficient query patterns
- **Connection Pool Tuning** - Optimal pool size recommendations
- **Caching Strategies** - Query and result caching opportunities

#### Application Optimizations
- **Code Hotspots** - Slow methods and functions
- **Memory Leaks** - Potential memory leak locations
- **Resource Usage** - Inefficient resource utilization
- **Caching Opportunities** - Template and data caching recommendations

### Performance Tracking
```bash
# Save benchmark results with metadata
wheels benchmark run --save --tag=release-2.1 --notes="Post optimization"

# Compare performance improvements
wheels benchmark compare --before=release-2.0 --after=release-2.1

# Generate improvement report
wheels benchmark report --comparison --format=pdf
```

## CI/CD Integration

### Automated Performance Testing
```bash
# Performance regression testing
wheels benchmark run --baseline=main --fail-on-regression=10%

# Performance gates in deployment pipeline
wheels benchmark run --threshold-file=performance-gates.json --exit-on-fail
```

### GitHub Actions Integration
```yaml
name: Performance Testing
on: [push, pull_request]

jobs:
  performance:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Run Benchmarks
        run: |
          wheels benchmark run --save-results --tag=${{ github.sha }}
          wheels benchmark report --format=json --output=benchmark-results.json

      - name: Performance Regression Check
        run: |
          wheels benchmark compare --baseline=main --current=${{ github.sha }} --fail-on-regression=15%
```

## Related Documentation

- [Configuration and Defaults](../../../working-with-wheels/configuration-and-defaults.md)
- [Caching](../../../handling-requests-with-controllers/caching.md)
- [Testing](../../../working-with-wheels/testing-your-application.md)