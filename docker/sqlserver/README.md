# SQL Server for CFWheels Testing

This directory contains the Docker configuration for running Microsoft SQL Server in the CFWheels test environment, optimized for Apple Silicon Macs.

## Configuration Overview

The SQL Server container is configured to:

1. Use Microsoft SQL Server 2022 with Rosetta emulation
2. Set up a database called `wheelstestdb`
3. Use custom startup scripts with proper error handling
4. Implement health checks for orchestration

## Running SQL Server on Apple Silicon (M1/M2/M3/M4)

### Prerequisites

1. **Docker Desktop Settings**:
   - Open Docker Desktop → Settings → General
   - Enable "Use Virtualization framework" 
   - Go to Settings → Features in development
   - Enable "Use Rosetta for x86/amd64 emulation on Apple Silicon"
   - Restart Docker Desktop

2. **Resource Allocation**:
   - Go to Settings → Resources
   - Set Memory to at least 4GB
   - Allocate at least 2 CPU cores if possible

## Usage

SQL Server requires significant resources. For regular development, use MySQL instead:

```bash
# Start with just MySQL for quick testing
docker compose --profile mysql up

# Or use the quick-test profile (Lucee 5 + MySQL)
docker compose --profile quick-test up
```

For scenarios requiring SQL Server:

```bash
# Only start SQL Server by itself
docker compose --profile sqlserver up --build

# Or with a specific CFML engine
docker compose --profile lucee --profile sqlserver up
```

## Troubleshooting

### Path Issues

If you see error messages about `/opt/mssql-tools/bin/sqlcmd` not found, it's because SQL Server 2022 uses a different path:

- SQL Server 2022 uses `/opt/mssql-tools18/bin/sqlcmd`
- Always include the `-C` flag when using sqlcmd to trust the self-signed certificate

### First Startup

The first startup of SQL Server may take longer (1-2 minutes) as it:
- Initializes the database files
- Creates system databases
- Performs upgrades to the latest version

Subsequent startups will be faster once the database files are created in the persistent volume.

### Certificate Trust

When connecting to SQL Server, you need to trust the self-signed certificate:
- Add the `-C` flag to sqlcmd commands
- For client apps, set `TrustServerCertificate=true` in connection strings

### Database Access

To connect to SQL Server from your application:

- **Host**: localhost
- **Port**: 1434 (mapped from 1433)
- **User**: SA
- **Password**: x!bsT8t60yo0cTVTPq
- **Database**: wheelstestdb
- **Connection string**: `Server=localhost,1434;Database=wheelstestdb;User Id=SA;Password=x!bsT8t60yo0cTVTPq;TrustServerCertificate=True;`

## Technical Details

The configuration uses:

1. **User Switching**: The Dockerfile switches to root user for setup tasks, then back to mssql user for running SQL Server
2. **Robust Initialization**: The init-db.sh script includes:
   - Timeout handling
   - Automatic error recovery
   - Detailed logging
   - Process monitoring
3. **Memory Allocation**: SQL Server is configured with 4GB memory
4. **Data Persistence**: Data is stored in a named volume for persistence

## Accessing SQL Server Directly

For debugging or direct access:

```bash
# Connect using sqlcmd within the container
docker exec -it cfwheels-sqlserver_cicd-1 /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P 'x!bsT8t60yo0cTVTPq' -C

# List databases
docker exec cfwheels-sqlserver_cicd-1 /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P 'x!bsT8t60yo0cTVTPq' -Q "SELECT name FROM sys.databases" -C

# Create a table
docker exec cfwheels-sqlserver_cicd-1 /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P 'x!bsT8t60yo0cTVTPq' -Q "USE wheelstestdb; CREATE TABLE test (id INT, name NVARCHAR(100));" -C
```