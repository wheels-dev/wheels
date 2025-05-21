# Using the CFWheels Test Environment

CFWheels includes a comprehensive test environment specifically designed for testing the core framework itself. This environment is crucial for contributors to ensure their changes pass all tests across multiple platforms before submitting pull requests. This guide covers how to use the Docker-based test environment effectively.

## Overview

The CFWheels test environment uses Docker containers to provide a standardized setup for testing core framework functionality across:

- Multiple CFML engines (Lucee 5/6, Adobe ColdFusion 2018/2021/2023)
- Multiple database platforms (MySQL, SQL Server, PostgreSQL, H2)
- A modern test user interface (TestUI)
- Automated test execution capabilities

This containerized approach ensures that all core framework tests run consistently across platforms, helping maintain compatibility across all supported environments.

> **Important**: This test environment is specifically for running the core framework tests to validate contributions to the CFWheels project. If you're looking to test your own CFWheels-based application, please refer to [Testing Your Application](testing-your-application.md) for guidance on setting up tests within your application.

## Prerequisites

To use the CFWheels core test environment, you'll need:

1. [Docker](https://www.docker.com/products/docker-desktop/) installed and running
2. [Git](https://git-scm.com/downloads) to clone the CFWheels repository
3. [CommandBox](https://www.ortussolutions.com/products/commandbox) installed to manage dependencies and run commands
4. Basic familiarity with command-line operations

## Setting Up the Test Environment

### 1. Clone the CFWheels Repository

If you haven't already done so, clone the CFWheels repository:

```bash
git clone https://github.com/cfwheels/cfwheels.git
cd cfwheels
```

### 2. Install Dependencies with CommandBox

Before running tests, you need to install dependencies using CommandBox:

```bash
# Start CommandBox (if not using the globally installed version)
box

# Install dependencies
install

# Exit CommandBox shell (if you entered it)
exit
```

Alternatively, you can run the install command directly:

```bash
box install
```

This will install all the necessary dependencies specified in the `box.json` file.

### 3. Start the Test Environment

The test environment uses Docker Compose profiles to selectively start components. Use one of the following commands based on your needs:

```bash
# Start everything (all engines, databases, and test UI)
docker compose --profile all up -d

# Start just the test UI
docker compose --profile ui up -d

# Start a specific CFML engine and database
docker compose --profile lucee --profile mysql up -d

# Start a minimum testing setup
docker compose --profile quick-test up -d
```

The first time you run these commands, Docker will build or download the necessary images, which may take several minutes.

### 4. Access the Test User Interface

Once the containers are running, access the TestUI by navigating to:

```
http://localhost:3001
```

This web interface allows you to:
- Select CFML engines and databases for testing
- Run specific test suites or individual tests
- View test results and error details
- Manage Docker containers directly from the UI

## Available Docker Profiles

The test environment includes several profiles you can use with `docker compose --profile [profile] up -d`:

| Profile | Description |
|---------|-------------|
| `all` | All CFML engines, databases, and the TestUI |
| `ui` | Just the modern TestUI |
| `ui-legacy` | The legacy TestUI interface |
| `lucee` | Lucee 5 and 6 engines |
| `adobe` | Adobe ColdFusion 2018, 2021, 2023 engines |
| `db` | All database platforms |
| `mysql` | MySQL database only |
| `postgres` | PostgreSQL database only |
| `sqlserver` | SQL Server database only |
| `quick-test` | Minimal setup for quick testing (Lucee 5 + MySQL) |
| `compatibility` | Engines used for compatibility testing |
| `current` | Latest stable versions of engines |
| `legacy` | Older versions of engines |

You can combine multiple profiles by specifying them together:

```bash
docker compose --profile lucee --profile mysql --profile ui up -d
```

## Running Core Framework Tests

When contributing to CFWheels, it's essential to run tests against various engine-database combinations to ensure compatibility. Here's how to run tests in different scenarios:

### Via the TestUI

1. Open the TestUI at http://localhost:3001
2. Select the CFML engine and database you want to test against (e.g., Lucee 5 + MySQL)
3. Select the test bundle or specific test to run
4. Click "Run Tests" to execute them
5. View the results in the UI
6. Repeat with different engine-database combinations to ensure full compatibility

### Via Command Line

You can also run tests directly via command line for specific engine-database combinations:

#### Testing with Lucee 5 and MySQL

```bash
# Connect to the Lucee 5 container
docker exec -it cfwheels-test-lucee5 /bin/bash

# Run all tests
cd /cfwheels-test-suite
box wheels test app

# Run a specific test
box wheels test app TestName

# Run a specific test bundle
box wheels test app testBundles=controllers
```

#### Testing with Adobe ColdFusion 2021 and SQL Server

```bash
# Connect to the Adobe 2021 container
docker exec -it cfwheels-test-adobe2021 /bin/bash

# Run all tests
cd /cfwheels-test-suite
box wheels test app

# Specify a test bundle
box wheels test app testBundles=models
```

#### Testing with Lucee 6 and PostgreSQL

```bash
# Connect to the Lucee 6 container
docker exec -it cfwheels-test-lucee6 /bin/bash

# Run all tests
cd /cfwheels-test-suite
box wheels test app

# Run a specific test with specific options
box wheels test app testBundles=core&testSpecs=testCaseOne
```

### Running Comprehensive Test Suite

For thorough testing before submitting a PR, you should run tests on multiple engine-database combinations:

1. Test with Lucee 5 + MySQL (minimum requirement)
2. Test with at least one Adobe ColdFusion version (e.g., CF 2021)
3. Test with at least one alternative database (e.g., SQL Server or PostgreSQL)

### Via CommandBox Locally

You can also run tests locally using CommandBox without Docker, though this will only test against your locally installed CFML engine:

```bash
# Start a server
box server start

# Run all tests
box wheels test app

# Run a specific test
box wheels test app TestName

# Run tests with specific parameters
box wheels test app testBundles=controllers
```

## Test Environment Components

### CFML Engines

| Engine | Container Name | Port |
|--------|----------------|------|
| Lucee 5 | cfwheels-test-lucee5 | 60005 |
| Lucee 6 | cfwheels-test-lucee6 | 60006 |
| Adobe 2018 | cfwheels-test-adobe2018 | 62018 |
| Adobe 2021 | cfwheels-test-adobe2021 | 62021 |
| Adobe 2023 | cfwheels-test-adobe2023 | 62023 |

### Databases

| Database | Container Name | Port |
|----------|----------------|------|
| MySQL | mysql | 3307 (3306 internal) |
| PostgreSQL | postgres | 5433 (5432 internal) |
| SQL Server | sqlserver_cicd | 1434 (1433 internal) |
| H2 | (embedded) | n/a |

### Test User Interface

| Component | URL | Description |
|-----------|-----|-------------|
| Modern TestUI | http://localhost:3001 | Vue.js based interface with dark/light theme |
| Legacy TestUI | http://localhost:3000 | Original test interface |

## Pre-flight Checks and Container Management

The TestUI includes features to help manage the test environment:

1. **Pre-flight Checks**: Verify that all required containers are running before executing tests
2. **Container Management**: Start, stop, and restart containers directly from the UI
3. **Container Profiles**: Manage predefined sets of containers for specific testing needs

## Creating New Core Framework Tests

When contributing to CFWheels, you may need to create new tests for your code changes:

1. Create a new test file in the appropriate directory:
   - For core functions: `/tests/functions/YourTest.cfc`
   - For request tests: `/tests/requests/YourTest.cfc`

2. Follow the TestBox syntax for your tests:

```cfml
component extends="wheels.Test" {
    
    function setup() {
        // Code to run before each test
    }
    
    function teardown() {
        // Code to run after each test
    }
    
    function test_your_feature() {
        // Your test code
        assert(true);
    }
}
```

3. Run your new test using the methods described above to ensure it passes on all engine-database combinations

## Troubleshooting

### Common Issues

1. **Container won't start**: 
   - Check container logs: `docker logs container_name`
   - Ensure ports aren't already in use on your system
   - Try stopping and removing all containers: `docker compose down`

2. **Tests fail inconsistently**:
   - Ensure your database container is healthy
   - Check for resource constraints (memory/CPU)
   - Use the pre-flight feature in the TestUI to verify container health

3. **Port conflicts**:
   - Edit the port mappings in compose.yml if needed
   - Use `docker ps` to see what ports are in use

4. **CommandBox issues**:
   - Make sure CommandBox is properly installed and in your PATH
   - Try running `box version` to verify installation
   - Update CommandBox with `box upgrade` if you encounter compatibility issues

5. **Tests pass on one engine but fail on another**:
   - This typically indicates an engine compatibility issue
   - Check for engine-specific functions or behaviors
   - Use conditional code with proper engine detection when necessary

### Viewing Logs

```bash
# View logs from a specific container
docker logs cfwheels-test-lucee5

# Follow logs in real-time
docker logs -f cfwheels-test-lucee5
```

### Container Shell Access

```bash
# Connect to a running container
docker exec -it cfwheels-test-lucee5 /bin/bash
```

## Keeping the Test Environment Updated

To update your test environment to the latest version:

```bash
# Pull the latest code
git pull

# Update dependencies
box install

# Rebuild the containers
docker compose build

# Restart the environment
docker compose --profile all down
docker compose --profile all up -d
```

## Conclusion

The CFWheels test environment is a critical tool for ensuring that contributions to the core framework work consistently across all supported platforms. By thoroughly testing your changes across different CFML engines and databases, you help maintain the high quality and broad compatibility that CFWheels users expect.

After verifying that your changes pass all tests, you're ready to submit a pull request. For detailed instructions on the PR process, see [Submitting Pull Requests](submitting-pull-requests.md).