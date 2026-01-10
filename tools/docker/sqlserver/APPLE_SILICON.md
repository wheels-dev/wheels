# Running SQL Server on Apple Silicon (M1/M2/M3/M4)

This guide explains how to run Microsoft SQL Server on Apple Silicon Macs using Docker Desktop with Rosetta emulation.

## Current Implementation

The current configuration is optimized for Apple Silicon Macs:

1. Uses SQL Server 2022 with Rosetta emulation
2. Includes special configuration for path differences in SQL Server 2022
3. Adds certificate trust flags for secure connections
4. Sets appropriate resource allocation for Apple Silicon performance

## Required Docker Desktop Settings

For SQL Server to work properly on Apple Silicon:

1. Open Docker Desktop
2. Go to Settings > General
3. Enable "Use Virtualization framework" 
4. Go to Settings > Features in development
5. Enable "Use Rosetta for x86/amd64 emulation on Apple Silicon"
6. Restart Docker Desktop

## Resource Requirements

SQL Server needs significant resources:

1. Allocate more memory to Docker Desktop:
   - Go to Docker Desktop > Settings > Resources
   - Set Memory to at least 4GB (6GB recommended)
   - Increase CPU allocation to at least 2 cores if possible

2. The compose.yml file includes explicit resource reservations:
   ```yaml
   deploy:
     resources:
       limits:
         memory: 4G
       reservations:
         memory: 2G
   ```

## Building and Running

After configuring Docker Desktop:

1. Force a clean build:
   ```bash
   docker compose build --no-cache sqlserver_cicd
   ```

2. Start SQL Server:
   ```bash
   docker compose --profile sqlserver up
   ```

## SQL Server 2022 Path Differences

SQL Server 2022 uses different paths than previous versions:

- SQL Server 2022 sqlcmd path: `/opt/mssql-tools18/bin/sqlcmd`
- Previous versions used: `/opt/mssql-tools/bin/sqlcmd`

When working with SQL Server 2022, always use the `/opt/mssql-tools18/bin/` path for command-line tools and add the `-C` flag to trust the self-signed certificate.

## Command Reference

Run SQL commands against the SQL Server container:

```bash
# Interactive sqlcmd session
docker exec -it wheels-sqlserver-1 /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "x!bsT8t60yo0cTVTPq" -C

# Run a single query
docker exec wheels-sqlserver-1 /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "x!bsT8t60yo0cTVTPq" -Q "SELECT @@VERSION" -C
```

## Performance Considerations

SQL Server under Rosetta emulation can be resource-intensive. For development:

1. Use MySQL when possible:
   ```bash
   docker compose --profile quick-test up
   ```

2. Only start SQL Server when needed for specific testing:
   ```bash
   docker compose --profile sqlserver up
   ```

3. Optimize SQL queries for Rosetta emulation:
   - Keep transactions small
   - Minimize complex joins and sorts
   - Use lightweight schemas for development

## Troubleshooting

If you encounter issues:

1. Check Docker logs:
   ```bash
   docker compose logs sqlserver_cicd
   ```

2. Verify container is built correctly:
   ```bash
   docker compose build --no-cache sqlserver_cicd
   ```

3. Check database status:
   ```bash
   docker exec wheels-sqlserver-1 /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "x!bsT8t60yo0cTVTPq" -Q "SELECT name FROM sys.databases" -C
   ```

4. If needed, manually create the wheelstestdb database:
   ```bash
   docker exec wheels-sqlserver-1 /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "x!bsT8t60yo0cTVTPq" -Q "CREATE DATABASE wheelstestdb" -C
   ```

5. For severe issues, reset the SQL Server volume:
   ```bash
   docker compose down
   docker volume rm wheels_sqlserver_data
   docker compose --profile sqlserver up --build
   ```