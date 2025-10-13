# GitHub Actions - Wheels Test Suite

This document explains how Wheels uses GitHub Actions for continuous integration and deployment, specifically focused on the Docker-based testing infrastructure.

## Overview

Wheels uses GitHub Actions to automatically test all pull requests and releases across multiple CFML engines and databases using Docker containers. This ensures code quality and compatibility across all supported platforms.

## Workflow Files

### Core Workflows

| File | Purpose | Trigger |
|------|---------|---------|
| `.github/workflows/pr.yml` | Pull Request testing | Pull requests to `develop` |
| `.github/workflows/tests.yml` | Reusable test suite | Called by other workflows |
| `.github/workflows/release.yml` | Production releases | Push to `main` branch |
| `.github/workflows/snapshot.yml` | Development releases | Push to `develop` branch |

### Pull Request Workflow (`pr.yml`)

**Trigger**: Opening or updating pull requests to the `develop` branch

```yaml
on:
  pull_request:
    branches:
      - develop
```

**What it does**: Calls the reusable `tests.yml` workflow to run comprehensive tests.

### Test Suite Workflow (`tests.yml`) 

**The main testing workflow** - This is where all the Docker magic happens.

#### Test Matrix

Your code is tested against every combination of:

**CFML Engines**:
- Lucee 5, 6, 7
- Adobe ColdFusion 2018, 2021, 2023
- BoxLang 1

**Databases**:
- MySQL
- PostgreSQL 
- SQL Server
- H2 (embedded)
- Oracle

**Total**: ~35 different environment combinations

#### Matrix Strategy

```yaml
strategy:
  fail-fast: false
  matrix:
    cfengine: ["lucee5", "lucee6", "lucee7", "adobe2018", "adobe2021", "adobe2023", "boxlang"]
    dbengine: ["mysql", "postgres", "sqlserver", "h2", "oracle"]
```

**Exclusions**:
- Adobe engines exclude H2 database
- Adobe 2025 currently excluded from most combinations

## Docker Container Architecture

### CFML Engine Containers

| Engine | Container Name | Port | Docker Image |
|--------|----------------|------|--------------|
| Lucee 5 | `wheels-lucee5-1` | 60005 | `wheels-test-lucee5:v1.0.2` |
| Lucee 6 | `wheels-lucee6-1` | 60006 | `wheels-test-lucee6:v1.0.2` |
| Lucee 7 | `wheels-lucee7-1` | 60007 | `wheels-test-lucee7:v1.0.0` |
| Adobe 2018 | `wheels-adobe2018-1` | 62018 | `wheels-test-adobe2018:v1.0.2` |
| Adobe 2021 | `wheels-adobe2021-1` | 62021 | `wheels-test-adobe2021:v1.0.2` |
| Adobe 2023 | `wheels-adobe2023-1` | 62023 | `wheels-test-adobe2023:v1.0.1` |
| BoxLang | `wheels-boxlang-1` | 60001 | `wheels-test-boxlang:v1.0.0` |

### Database Containers

| Database | Container Name | Port Mapping | Image |
|----------|----------------|--------------|-------|
| MySQL | `wheels-mysql-1` | 3307→3306 | `mysql:9.3` |
| PostgreSQL | `wheels-postgres-1` | 5433→5432 | `postgres:14` |
| SQL Server | `wheels-sqlserver-1` | 1434→1433 | `wheels-sqlserver:v1.0.2` |
| Oracle | `wheels-oracle-1` | 1522→1521 | `gvenzl/oracle-free:23-slim` |
| H2 | (embedded) | n/a | Built into CFML engines |

## Test Execution Process

### Step-by-Step Process

1. **Checkout Repository**
   ```yaml
   - name: Checkout Repository
     uses: actions/checkout@v4
   ```

2. **Download Oracle JDBC** (Adobe CF only)
   ```bash
   wget https://download.oracle.com/otn-pub/otn_software/jdbc/1927/ojdbc10.jar
   ```

3. **Start CFML Engine Container**
   ```bash
   docker compose up -d ${{ matrix.cfengine }}
   ```

4. **Start Database Container** (if not H2)
   ```bash
   docker compose up -d ${{ matrix.dbengine }}
   ```

5. **Wait for Services**
   - Containers to be running
   - Services to respond on expected ports
   - Special 120s wait for Oracle database

6. **Install CFML Modules** (Adobe CF 2021+)
   ```bash
   docker exec wheels-${{ matrix.cfengine }}-1 box cfpm install image,mail,zip,debugger,caching,mysql,postgresql,sqlserver,oracle
   ```

7. **Run Tests with Retry Logic**
   ```bash
   TEST_URL="http://localhost:${PORT}/wheels/core/tests?db=${{ matrix.dbengine }}&format=json&only=failure,error"
   curl -s -o result.txt --max-time 900 "$TEST_URL"
   ```

### Test URL Structure

Tests are executed via HTTP requests to the CFML engine:

```
http://localhost:{PORT}/wheels/core/tests?db={DATABASE}&format=json&only=failure,error
```

**Parameters**:
- `db`: Database type (mysql, postgres, sqlserver, h2, oracle)
- `format`: Response format (json)
- `only`: Show only failures and errors

### Success Criteria

- **HTTP 200**: All tests passed
- **HTTP 500**: Test failures or errors
- **Connection refused**: Container startup issues

## Artifacts and Debugging

### Generated Artifacts

Every test run generates downloadable artifacts:

```
test-results-{engine}-{database}.txt     # JSON test results
logs-{engine}-{database}/                # Container logs
workflow-logs/                           # GitHub Actions logs
```

### Artifact Contents

**Test Results** (`test-results-*.txt`):
```json
{
  "tests": [...],
  "failures": [...],
  "errors": [...],
  "totalTests": 1234,
  "totalFailures": 0,
  "totalErrors": 0
}
```

**Container Logs**: CFML server startup and error logs
**Workflow Logs**: GitHub Actions execution details

## Debugging Failed Tests

### Common Failure Patterns

#### 1. Container Startup Issues
**Symptoms**:
```
Error: Container not ready after 60 attempts
```

**Solutions**:
- Usually Oracle database timing out
- Workflow automatically retries once
- Re-run the workflow if persistent

#### 2. Engine Compatibility Issues  
**Symptoms**:
```
✅ Tests pass on Lucee
❌ Tests fail on Adobe CF
```

**Common Causes**:
- CFML syntax differences
- Function availability differences
- Dynamic method invocation issues

**Example Fixes**:
```javascript
// Problem: Lucee syntax
component[method]()

// Solution: Use invoke()  
invoke(object=component, methodname=method)
```

#### 3. Database Compatibility Issues
**Symptoms**:
```
✅ Tests pass with H2
❌ Tests fail with PostgreSQL/MySQL
```

**Common Causes**:
- SQL syntax differences
- Data type handling
- Connection configuration

### Local Reproduction

To reproduce CI failures locally:

```bash
# Start the same containers as CI
docker compose up -d adobe2021 mysql

# Access the container
docker exec -it wheels-adobe2021-1 bash

# Navigate to test suite
cd /wheels-test-suite

# Run the same test
box wheels test run --testBundles=YourTest

# Or test via HTTP like CI does
curl "http://localhost:62021/wheels/core/tests?db=mysql&format=json"
```

## Performance and Timing

### Typical Execution Times

| Component | Time |
|-----------|------|
| Container startup | 2-5 minutes |
| Oracle database startup | 2-3 minutes |
| Test execution | 3-8 minutes |
| **Total per combination** | **5-15 minutes** |
| **Full matrix (35 combinations)** | **15-45 minutes** |

### Optimization Features

1. **Parallel Execution**: All matrix combinations run simultaneously
2. **Retry Logic**: Failed HTTP requests retry up to 3 times  
3. **Health Checks**: Containers wait for services to be ready
4. **Early Failure Detection**: Fast exit on critical errors

## Environment Variables

### Port Mappings
```yaml
env:
  PORT_lucee5: 60005
  PORT_lucee6: 60006
  PORT_lucee7: 60007
  PORT_adobe2018: 62018
  PORT_adobe2021: 62021
  PORT_adobe2023: 62023
  PORT_adobe2025: 62025
  PORT_boxlang: 60001
```

## Integration with Docker Compose

The GitHub Actions workflow uses the same `compose.yml` file as local development:

```bash
# CI does this:
docker compose up -d lucee5 mysql

# Which is equivalent to local:
docker compose up -d lucee5 mysql
```

**Key Differences**:
- CI doesn't start the TestUI
- CI uses specific port mappings
- CI includes additional health checks
- CI downloads Oracle JDBC drivers

## Troubleshooting Guide

### For Contributors

#### When Your PR Fails CI

1. **Check the pattern**:
   - Which engines/databases failed?
   - Is it a startup issue or actual test failure?

2. **Download artifacts**:
   - Go to Actions tab → Failed workflow → Artifacts
   - Download relevant test results

3. **Reproduce locally**:
   ```bash
   # Use same engine/database combination that failed
   docker compose up -d adobe2021 mysql
   docker exec -it wheels-adobe2021-1 bash
   cd /wheels-test-suite
   box wheels test run
   ```

4. **Common fixes**:
   - Engine syntax compatibility
   - Database query differences  
   - Function availability checks

#### When Tests Are Flaky

Some combinations may occasionally fail due to:
- GitHub Actions infrastructure issues
- Container startup timing
- Network connectivity

**Solution**: Re-run the workflow (usually resolves the issue)

### For Maintainers

#### Adding New Engines

1. **Create Dockerfile** in `tools/docker/{engine}/`
2. **Add to compose.yml** services section
3. **Update workflow matrix** in `tests.yml`
4. **Add port mapping** in environment variables
5. **Test locally** before merging

#### Adding New Databases

1. **Add to compose.yml** services section  
2. **Update workflow matrix** in `tests.yml`
3. **Configure Wheels adapters** if needed
4. **Test all engine combinations**

#### Updating Container Images

```bash
# Build and tag new images
docker build -t wheels-test-lucee7:v1.0.1 .

# Update references in:
# - compose.yml (image: tags)
# - This README (documentation)
```

## Monitoring and Maintenance

### Regular Maintenance Tasks

1. **Update base images** (monthly)
   - Oracle: `gvenzl/oracle-free:23-slim`
   - MySQL: `mysql:8.3`
   - PostgreSQL: `postgres:14`

2. **Update CFML engines** (as released)
   - Lucee releases
   - Adobe ColdFusion updates
   - BoxLang versions

3. **Monitor failure rates** (weekly)
   - Check for consistent failures
   - Update exclusion matrix if needed
   - Investigate performance regressions

### Health Monitoring

The workflow includes health checks for:
- Container startup success
- Service responsiveness  
- Database connectivity
- Test execution timeouts

## Contributing to the CI/CD System

### Testing Changes

Before modifying the workflows:

1. **Test locally** with Docker Compose
2. **Use feature branches** for workflow changes
3. **Monitor artifacts** for new failure patterns
4. **Update documentation** when adding features

### Best Practices

1. **Keep workflows idempotent**
2. **Use meaningful artifact names**
3. **Include debugging information**
4. **Document breaking changes**
5. **Test across all supported platforms**

## Conclusion

The GitHub Actions + Docker testing system provides:
- **Comprehensive coverage** across 35+ platform combinations
- **Automated quality gates** for all pull requests  
- **Detailed debugging information** when tests fail
- **Scalable architecture** for adding new platforms
- **Consistent results** across local and CI environments

This infrastructure ensures Wheels maintains high quality and broad compatibility across all supported CFML engines and databases.