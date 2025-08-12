# Development Workflow Commands

This guide covers the Wheels CLI commands designed to enhance your development workflow, including framework upgrades, performance testing, and documentation generation.

## Table of Contents

- [Framework Initialization](#framework-initialization)
- [Framework Upgrades](#framework-upgrades)
- [Performance Testing](#performance-testing)
- [Documentation Generation](#documentation-generation)
- [Best Practices](#best-practices)

## Framework Initialization

The `wheels init` command helps bootstrap existing Wheels applications to work with the CLI.

### When to Use

Use this command when you have:
- An existing Wheels application without CLI integration
- A project cloned from version control missing configuration files
- A need to reset CLI configuration files

### Basic Usage

```bash
# Initialize in current directory
wheels init

# Initialize with custom application name
wheels init name=myapp

# Force overwrite existing files
wheels init --force
```

### What It Does

The command creates three essential files:

1. **vendor/wheels/box.json** - Tracks the Wheels framework version
2. **server.json** - CommandBox server configuration with Wheels-specific settings
3. **box.json** - Application package configuration

### Interactive Prompts

When you run `wheels init`, it will ask for:

- **Application Name**: Used for unique server naming (special characters are removed)
- **Default CFML Engine**: Your preference (e.g., lucee5, adobe2023)

### Example

```bash
$ wheels init
======================================
Wheels CLI v3.0.0
======================================
You don't have a box.json. Let's create one

Application name: My Awesome App
We'll use: myawesomeapp for the server name

What's your preferred CFML Engine [lucee5]: lucee5

✓ Created vendor/wheels/box.json
✓ Created server.json
✓ Created box.json

Your application is now configured for the Wheels CLI!
```

## Framework Upgrades

The `wheels upgrade` command provides an interactive wizard for upgrading your Wheels framework version.

### Checking for Updates

```bash
# Check if updates are available
wheels upgrade --check

# Output:
# Current Wheels version: 2.5.0
# Upgrade available: 3.0.0
# Run 'wheels upgrade' to start the upgrade process.
```

### Interactive Upgrade

```bash
# Start the upgrade wizard
wheels upgrade

# The wizard will:
# 1. Show available versions
# 2. Let you select target version
# 3. Check for breaking changes
# 4. Show upgrade steps
# 5. Create backup (optional)
# 6. Perform the upgrade
```

### Direct Upgrade

```bash
# Upgrade to specific version
wheels upgrade --to=3.0.0

# Skip all confirmations
wheels upgrade --to=3.0.0 --force

# Upgrade without creating backup
wheels upgrade --backup=false
```

### Breaking Changes Detection

The upgrade command automatically detects potential breaking changes:

```
⚠️  Breaking Changes Detected:
  • Major version upgrade - review changelog for breaking changes
  • Wheels 3.x uses CommandBox modules
  • New routing engine with different syntax
  • Updated model callback names
```

### Backup Management

By default, upgrades create a backup in `backups/upgrade-[timestamp]/` containing:
- `/app` directory
- `/config` directory
- `/vendor/wheels` directory
- `box.json` and `server.json`
- `.env` files

### Post-Upgrade Steps

After a successful upgrade:

1. Run your test suite: `wheels test run`
2. Check the upgrade guide at <https://wheels.dev/3.0.0/guides/introduction/upgrading>
3. Review deprecated features
4. Update your plugins to compatible versions

## Performance Testing

### Benchmarking with `wheels benchmark`

The benchmark command performs load testing on your application endpoints.

#### Basic Benchmarking

```bash
# Benchmark homepage
wheels benchmark /

# Benchmark with more requests
wheels benchmark /products --requests=1000 --concurrent=10
```

#### Advanced Options

```bash
# POST request with data
wheels benchmark /api/users \
  --method=POST \
  --data='{"name":"test","email":"test@example.com"}' \
  --headers="Content-Type:application/json"

# Custom timeout
wheels benchmark /slow-endpoint --timeout=60

# Save results
wheels benchmark / --output=json --save=benchmark-results.json
```

#### Using Configuration Files

Create a `benchmark.json` file:

```json
{
  "scenarios": [
    {
      "name": "Homepage",
      "url": "/",
      "requests": 1000,
      "concurrent": 10
    },
    {
      "name": "API Create User",
      "url": "/api/users",
      "method": "POST",
      "headers": {
        "Content-Type": "application/json",
        "Authorization": "Bearer token123"
      },
      "data": "{\"name\":\"Test User\"}",
      "requests": 500,
      "concurrent": 5
    }
  ]
}
```

Run all scenarios:

```bash
wheels benchmark --config=benchmark.json
```

#### Understanding Results

```
Benchmark Results:
──────────────────────────────────────────────────
Total Requests: 1000
Concurrent: 10
Total Time: 45.23s

Successful: 995 (99.5%)
Failed: 5

Response Times (ms):
  Min: 23
  Max: 892
  Mean: 145
  Median: 134
  95th percentile: 289
  99th percentile: 456

Throughput:
  Requests/sec: 22.11
  Data transferred: 4.5 MB
  Avg response size: 4.6 KB

Status Codes:
  200: 995
  500: 5
```

### Profiling with `wheels profile`

The profile command provides detailed performance analysis of individual requests.

#### Basic Profiling

```bash
# Profile an endpoint
wheels profile /products

# Multiple iterations for accuracy
wheels profile /api/users --iterations=10
```

#### Interactive Mode

```bash
wheels profile --interactive

# This starts an interactive session where you can:
# 1. Profile multiple endpoints
# 2. Compare performance
# 3. Save results
```

#### Detailed Analysis

```bash
# Generate HTML report with charts
wheels profile /complex-page --output=html --save=profile.html

# Profile POST request
wheels profile /search \
  --method=POST \
  --data='{"query":"wheels framework"}' \
  --iterations=5
```

#### Profile Results

The profiler provides:

1. **Response Time Statistics**
   - Min, Max, Mean, Median times
   - Standard deviation
   - Consistency analysis

2. **Phase Breakdown**
   - DNS lookup time
   - Connection time
   - Request processing
   - Response download

3. **Wheels-Specific Metrics**
   - Query count and time
   - Memory usage
   - Cache hits/misses

4. **Recommendations**
   - High query count warnings
   - Slow query detection
   - Optimization suggestions

Example output:
```
Profile Results:
────────────────────────────────────────────────────────────
URL: http://localhost:8080/products
Method: GET
Iterations: 10

Response Times (ms):
  Min: 156
  Max: 234
  Mean: 189
  Median: 185
  Std Dev: 24

Wheels Analysis:
  Query Count: 47 avg
  Query Time: 134ms avg

Recommendations:
  • High query count detected (47 avg). Consider using includes() to reduce N+1 queries.
  • Review query performance and add indexes if needed.
```

## Documentation Generation

The `wheels docs` commands help manage and generate documentation for your application.

### Opening Documentation

```bash
# Open Wheels framework documentation
wheels docs

# This opens the official Wheels documentation in your browser
```

### Generating API Documentation

```bash
# Generate documentation for all components
wheels docs:generate

# Generate with specific format
wheels docs:generate --format=html
wheels docs:generate --format=markdown
wheels docs:generate --format=json
```

### Customization Options

```bash
# Use Bootstrap template
wheels docs:generate --format=html --template=bootstrap

# Generate for specific components only
wheels docs:generate --type=models
wheels docs:generate --type=controllers,services

# Verbose output
wheels docs:generate --verbose

# Serve documentation after generation
wheels docs:generate --serve --port=8080
```

### Output Structure

Generated documentation includes:

1. **Component Documentation**
   - Properties with types and hints
   - Methods with parameters and return types
   - Inheritance hierarchy
   - Usage examples from hints

2. **Navigation**
   - Organized by component type
   - Searchable index
   - Cross-references

3. **Formats**
   - **HTML**: Full styling with syntax highlighting
   - **Markdown**: GitHub-compatible format
   - **JSON**: Raw metadata for custom processing

### Example HTML Output

The HTML documentation includes:
- Syntax highlighted code examples
- Collapsible sections for methods
- Parameter tables
- Return type information
- Property listings

## Best Practices

### 1. Regular Framework Updates

```bash
# Check for updates monthly
wheels upgrade --check

# Test upgrades in development first
wheels upgrade --to=3.0.0
wheels test run
```

### 2. Performance Monitoring

```bash
# Benchmark after significant changes
wheels benchmark / --save=baseline.json

# Profile slow pages
wheels profile /slow-page --iterations=10
```

### 3. Documentation Maintenance

```bash
# Regenerate docs after API changes
wheels docs:generate --format=markdown

# Commit generated docs to repository
git add docs/api/
git commit -m "Update API documentation"
```

### 4. Continuous Integration

Add these commands to your CI pipeline:

```yaml
# .github/workflows/ci.yml
- name: Check for framework updates
  run: wheels upgrade --check

- name: Run benchmarks
  run: wheels benchmark --config=ci-benchmark.json

- name: Generate documentation
  run: wheels docs:generate --format=markdown
```

### 5. Team Workflows

For team development:

```bash
# After cloning a repository
git clone https://github.com/team/project
cd project
wheels init --force
box install
wheels db setup

# Before committing
wheels profile /new-feature
wheels docs:generate
```

## Troubleshooting

### Init Command Issues

**Problem**: "Directory already has box.json"
```bash
# Solution: Use force flag
wheels init --force
```

**Problem**: "Cannot determine Wheels version"
```bash
# Solution: Ensure /vendor/wheels exists
box install
wheels init
```

### Upgrade Command Issues

**Problem**: "Backup failed"
```bash
# Solution: Check disk space and permissions
# Or skip backup
wheels upgrade --backup=false
```

**Problem**: "Version not found"
```bash
# Solution: Check available versions
wheels upgrade --check
```

### Benchmark/Profile Issues

**Problem**: "Server not running"
```bash
# Solution: Start server first
server start
wheels benchmark /
```

**Problem**: "Timeout errors"
```bash
# Solution: Increase timeout
wheels benchmark / --timeout=120
wheels profile / --timeout=120
```

## Summary

The development workflow commands enhance your Wheels development experience by providing:

- Easy CLI integration for existing projects
- Safe, guided framework upgrades
- Performance testing and profiling tools
- Automated documentation generation

Use these tools regularly to maintain a healthy, well-documented, and performant Wheels application.
