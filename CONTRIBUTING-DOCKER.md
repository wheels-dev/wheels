# Contributing to Wheels Framework - Docker Development Guide

This guide explains how to use the Docker-based development environment for contributing to the Wheels Framework.

## Overview

The Wheels repository includes a CommandBox task runner system that makes it easy to test framework changes across different CFML engines and databases. Each template and example includes its own task runner that:

- Automatically configures Docker containers
- Maps the core framework files for live editing
- Supports multiple CFML engines and databases
- Provides a consistent development experience

## Prerequisites

1. **Docker Desktop** - [Download](https://www.docker.com/products/docker-desktop/)
2. **CommandBox 5.0+** - [Download](https://www.ortussolutions.com/products/commandbox)
3. **Git** - To clone the repository

## Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/wheels-dev/wheels.git
cd wheels
```

### 2. Install Dependencies

From the repository root:

```bash
box install
```

This installs WireBox, TestBox, and other dependencies in the `/vendor` directory.

### 3. Choose a Template or Example

Navigate to any template or example directory:

```bash
# For the default template
cd templates/default

# For the API template
cd templates/api

# For the blog example
cd examples/blog-app
```

### 4. Start Development Server

```bash
box task run start
```

This starts a Lucee 6 server with H2 database on port 60006 by default.

## Task Runner Commands

All templates and examples support these commands:

### Server Management

```bash
# Start with defaults (Lucee 6 on port 60006)
box task run start

# Start with specific engine (uses engine-specific default port)
box task run start --engine=adobe2023  # Starts on port 62023

# Start with specific database
box task run start --database=mysql

# Override the default port
box task run start --port=8888

# Stop server
box task run stop

# Restart server
box task run restart

# Check status
box task run status
```

### Logs and Debugging

```bash
# View logs
box task run logs

# Follow logs in real-time
box task run logs --follow

# View last 50 lines
box task run logs --tail=50
```

### Testing

```bash
# Run application tests
box task run test

# Run core framework tests
box task run test:core
```

### Cleanup

```bash
# Remove all containers and volumes
box task run clean
```

## Supported Configurations

### CFML Engines
- `lucee5` - Lucee 5.x (default port: 60005)
- `lucee6` - Lucee 6.x (default, port: 60006)
- `lucee7` - Lucee 7.x (default port: 60007)
- `adobe2018` - Adobe ColdFusion 2018 (default port: 62018)
- `adobe2021` - Adobe ColdFusion 2021 (default port: 62021)
- `adobe2023` - Adobe ColdFusion 2023 (default port: 62023)
- `adobe2025` - Adobe ColdFusion 2025 (default port: 62025)

### Databases
- `h2` - H2 embedded (default for Lucee, no separate container)
- `mysql` - MySQL 8.0
- `postgresql` - PostgreSQL 15
- `sqlserver` - Microsoft SQL Server

## Development Workflow

### 1. Making Framework Changes

Edit files in `/core/src/wheels/` - changes are immediately reflected in the running application.

### 2. Testing Changes

1. Make your changes to the core framework
2. Refresh your browser to see the changes
3. Run tests to ensure nothing is broken:
   ```bash
   box task run test:core
   ```

### 3. Testing Across Engines

Test your changes with different engines:

```bash
# Test with Lucee 7
box task run stop
box task run start --engine=lucee7

# Test with Adobe ColdFusion 2023
box task run stop
box task run start --engine=adobe2023
```

### 4. Testing with Different Databases

```bash
# Test with MySQL
box task run start --database=mysql

# Test with PostgreSQL
box task run start --database=postgresql
```

## File Structure

```
wheels/
├── core/                    # Core framework code
│   ├── src/
│   │   └── wheels/         # Framework source (mapped to /app/vendor/wheels)
│   └── tests/              # Core framework tests
├── templates/              # Application templates
│   ├── default/           # Default MVC template
│   ├── api/               # REST API template
│   └── spa/               # Single Page Application template
├── examples/              # Example applications
│   ├── blog-app/          # Blog example
│   └── ...
├── vendor/                # Dependencies (WireBox, TestBox)
└── tools/
    └── docker/           # Docker configurations
```

## Volume Mappings

The task runner creates these volume mappings:

- `./` → `/app` - Current template/example
- `../../core/src/wheels` → `/app/vendor/wheels` - Core framework
- `../../vendor/wirebox` → `/app/vendor/wirebox` - WireBox
- `../../vendor/testbox` → `/app/vendor/testbox` - TestBox

## Troubleshooting

### Port Already in Use

```bash
box task run start --port=8888
```

### Container Won't Start

Check Docker logs:
```bash
box task run logs --tail=100
```

### Database Connection Issues

Ensure the database container is healthy:
```bash
docker ps
```

### Clean Restart

```bash
box task run clean
box task run start
```

## Best Practices

1. **Test Multiple Engines** - Ensure your changes work across different CFML engines
2. **Run Tests** - Always run both application and core tests
3. **Check Logs** - Monitor logs for deprecation warnings or errors
4. **Document Changes** - Update documentation for any new features
5. **Follow Code Style** - Match the existing code style in the framework

## Advanced Usage

### Custom Docker Configuration

You can modify the `docker-compose.yml.template` in any template/example to add:
- Additional services
- Custom environment variables
- Volume mounts
- Network configurations

### Running Multiple Templates

Use different engines to run multiple templates simultaneously (each uses its default port):

```bash
# Terminal 1 - Default template with Lucee 6 (port 60006)
cd templates/default
box task run start

# Terminal 2 - API template with Adobe 2023 (port 62023)
cd templates/api
box task run start --engine=adobe2023

# Terminal 3 - Blog example with Lucee 7 (port 60007)
cd examples/blog-app
box task run start --engine=lucee7
```

Or override ports manually if needed:

```bash
box task run start --port=8080  # Custom port instead of engine default
```

## Getting Help

- Check the logs: `box task run logs`
- View task runner help: `box task run help`
- Ask in the [Wheels Discussions](https://github.com/wheels-dev/wheels/discussions)
- Report issues on [GitHub Issues](https://github.com/wheels-dev/wheels/issues)