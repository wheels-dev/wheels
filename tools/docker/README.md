# Wheels Framework Docker Test Suite

This directory contains Docker configurations for testing the Wheels framework across multiple CFML engines and databases.

## Quick Start

### 1. Copy the environment file
```bash
cp .env.example .env
```

### 2. Run tests with different profiles

```bash
# Quick test with Lucee 6 + H2 database (minimal setup)
docker compose -f compose.minimal.yml up -d

# Test with specific profiles
docker compose --profile quick-test up -d    # Lucee 6 + MySQL
docker compose --profile lucee up -d         # All Lucee versions
docker compose --profile adobe up -d         # All Adobe CF versions
docker compose --profile db up -d            # All databases
docker compose --profile full-test up -d     # Everything
```

## Available Profiles

- **`quick-test`**: Lucee 6 + MySQL - fastest way to get started
- **`lucee`**: All Lucee engines (5, 6, 7)
- **`adobe`**: All Adobe ColdFusion engines (2018, 2021, 2023, 2025)
- **`db`**: All database servers (MySQL, PostgreSQL, SQL Server, Oracle)
- **`ui`**: TestUI web interface
- **`full-test`**: All engines and databases

## Port Mappings

| Service | Port | URL |
|---------|------|-----|
| Lucee 5 | 60005 | http://localhost:60005 |
| Lucee 6 | 60006 | http://localhost:60006 |
| Lucee 7 | 60007 | http://localhost:60007 |
| Adobe 2018 | 62018 | http://localhost:62018 |
| Adobe 2021 | 62021 | http://localhost:62021 |
| Adobe 2023 | 62023 | http://localhost:62023 |
| Adobe 2025 | 62025 | http://localhost:62025 |
| TestUI | 3000 | http://localhost:3000 |
| MySQL | 3307 | mysql://localhost:3307 |
| PostgreSQL | 5433 | postgresql://localhost:5433 |
| SQL Server | 1434 | sqlserver://localhost:1434 |
| Oracle | 1522 | oracle://localhost:1522 |

## Running Tests

### Via TestUI (Recommended)
1. Start the UI: `docker compose --profile ui up -d`
2. Open http://localhost:3000
3. Select engine and database
4. Click "Run Tests"

### Direct URLs
```bash
# Lucee 6 with H2
http://localhost:60006/wheels/testbox?db=h2

# Adobe 2021 with MySQL
http://localhost:62021/wheels/testbox?db=mysql

# With JSON format
http://localhost:60006/wheels/testbox?format=json&db=postgres
```

## Database Connections

All engines are pre-configured with these datasources:
- `wheelstestdb` - Default datasource (uses MySQL)
- `wheelstestdb_mysql` - MySQL specific
- `wheelstestdb_postgres` - PostgreSQL specific
- `wheelstestdb_sqlserver` - SQL Server specific
- `wheelstestdb_h2` - H2 embedded (Lucee only)
- `wheelstestdb_oracle` - Oracle specific

Use the `db` URL parameter to switch databases:
- `?db=h2` (Lucee only)
- `?db=mysql`
- `?db=postgres`
- `?db=sqlserver`
- `?db=oracle`

## Development Workflow

### Testing a specific engine
```bash
# Start just Lucee 6
docker compose up lucee6 -d

# View logs
docker compose logs -f lucee6

# Stop
docker compose down lucee6
```

### Rebuilding after changes
```bash
# Rebuild specific service
docker compose build lucee6
docker compose up lucee6 -d --force-recreate

# Rebuild all
docker compose build
docker compose --profile full-test up -d --force-recreate
```

### Troubleshooting

1. **Container won't start**: Check logs with `docker compose logs [service]`
2. **Port conflicts**: Change ports in `.env` file
3. **Memory issues**: Increase Docker memory allocation (4GB+ recommended)
4. **SQL Server on Apple Silicon**: Enable Rosetta in Docker Desktop

## Advanced Configuration

### Custom Environment Variables
Edit `.env` file to customize:
- Port numbers
- Database credentials
- Memory limits
- Container versions

### Adding New Engines
1. Create directory: `tools/docker/[engine]@[version]/`
2. Add Dockerfile, server.json, CFConfig.json, settings.cfm
3. Update compose.yml with new service
4. Add to appropriate profile

### Maintenance Commands
```bash
# Clean up everything
docker compose down -v --remove-orphans

# Remove unused images
docker image prune -a

# View resource usage
docker stats

# Access container shell
docker compose exec lucee6 bash
```

## Directory Structure
```
tools/docker/
├── README.md                   # This file
├── Dockerfile.template         # Template for unified Dockerfiles
├── server.json.template        # Template for server configurations
├── lucee@5/                   # Lucee 5 specific files
├── lucee@6/                   # Lucee 6 specific files
├── lucee@7/                   # Lucee 7 specific files
├── adobe@2018/                # Adobe CF 2018 files
├── adobe@2021/                # Adobe CF 2021 files
├── adobe@2023/                # Adobe CF 2023 files
├── adobe@2025/                # Adobe CF 2025 files
├── sqlserver/                 # SQL Server configuration
└── testui/                    # Test UI application
```

## Performance Tips

1. Use profiles to start only what you need
2. Use H2 database for fastest tests (Lucee only)
3. Allocate sufficient Docker memory (4GB minimum)
4. Use `.env` to reduce memory for unused services
5. Consider `compose.minimal.yml` for development

## Known Issues

- CORS tests are currently disabled
- Adobe engines take longer to start (be patient)
- SQL Server requires extra memory allocation
- Oracle container needs 2GB+ memory

## Contributing

When adding new engines or databases:
1. Follow the existing naming conventions
2. Update this README
3. Add to appropriate profiles
4. Test with minimal and full profiles
5. Document any special requirements