# Wheels Framework Development Guide

This template includes a CommandBox task runner that makes it easy to test framework changes during development.

## Prerequisites

- Docker Desktop installed and running
- CommandBox installed (minimum version 5.0)
- Git (to clone the repository)

## Quick Start

1. Clone the Wheels repository:
   ```bash
   git clone https://github.com/wheels-dev/wheels.git
   cd wheels
   ```

2. Navigate to this template directory:
   ```bash
   cd templates/default
   ```

3. Start the development server:
   ```bash
   box task run start
   ```

   This will start a Lucee 6 server with H2 database on port 8080.

4. Access your application at: http://localhost:8080

## Available Commands

### Start Server
```bash
# Default (Lucee 6 + H2)
box task run start

# With specific engine
box task run start --engine=adobe2023

# With specific database
box task run start --database=mysql

# With custom port
box task run start --port=8888

# Combined options
box task run start --engine=adobe2021 --database=postgresql --port=9000
```

### Server Management
```bash
# Stop the server
box task run stop

# Restart the server
box task run restart

# Check server status
box task run status

# View logs
box task run logs

# Follow logs in real-time
box task run logs --follow
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
# Remove containers and volumes
box task run clean
```

## Supported Engines

- `lucee5` - Lucee 5.x
- `lucee6` - Lucee 6.x (default)
- `lucee7` - Lucee 7.x
- `adobe2018` - Adobe ColdFusion 2018
- `adobe2021` - Adobe ColdFusion 2021
- `adobe2023` - Adobe ColdFusion 2023
- `adobe2025` - Adobe ColdFusion 2025

## Supported Databases

- `h2` - H2 embedded database (default for Lucee)
- `mysql` - MySQL 8.0
- `postgresql` - PostgreSQL 15
- `sqlserver` - Microsoft SQL Server

## How It Works

The task runner:
1. Generates a `docker-compose.yml` file based on your selected options
2. Mounts the core framework files from the repository into the container
3. Starts the selected CFML engine and database
4. Provides live reloading - changes to files are immediately visible

### Volume Mappings

- `./` → `/app` - The template application
- `../../core/src/wheels` → `/app/vendor/wheels` - Core framework
- `../../vendor/wirebox` → `/app/vendor/wirebox` - WireBox dependency
- `../../vendor/testbox` → `/app/vendor/testbox` - TestBox testing framework

## Shortcuts

The `box.json` includes several shortcut scripts:

```bash
# Start with specific engines
box run-script dev:lucee6
box run-script dev:adobe2023

# Start with specific databases
box run-script dev:mysql
box run-script dev:postgresql

# Other shortcuts
box run-script stop
box run-script logs
box run-script test
```

## Troubleshooting

### Port Already in Use
If port 8080 is already in use, specify a different port:
```bash
box task run start --port=8888
```

### Docker Not Running
Make sure Docker Desktop is running before starting the server.

### Container Won't Start
Check the logs for errors:
```bash
box task run logs --tail=50
```

### Clean Start
If you're having issues, try a clean start:
```bash
box task run clean
box task run start
```

## Making Framework Changes

1. Edit core framework files in `../../core/src/wheels/`
2. Changes are immediately reflected in the running application
3. No need to restart the container
4. Use the browser's refresh to see changes

## Contributing

When submitting pull requests:
1. Test your changes with multiple engines
2. Run both application and core tests
3. Document any new features or changes
4. Follow the existing code style