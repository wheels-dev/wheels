# Oracle Database Testing for CFWheels

This directory contains the Docker configuration for running Oracle Database tests with CFWheels.

## Prerequisites

1. Accept Oracle Database License Terms
   - Visit: https://container-registry.oracle.com
   - Sign in with your Oracle account
   - Accept the license for Oracle Database

2. Pull the Oracle image:
   ```bash
   docker pull container-registry.oracle.com/database/free:23.3.0.0
   ```

## Configuration

The Oracle container is configured with:
- Database: FREEPDB1 (Pluggable Database)
- User: wheelstestdb
- Password: wheelstestdb123!
- Port: 1521

## Running Oracle Tests

### Local Testing

1. Start Oracle container:
   ```bash
   docker compose --profile oracle up -d oracle
   ```

2. Wait for Oracle to be ready (can take 5-10 minutes on first run):
   ```bash
   docker compose logs -f oracle | grep "DATABASE IS READY TO USE"
   ```

3. Run tests with a specific CFML engine:
   ```bash
   docker compose --profile lucee up -d lucee5
   docker compose exec lucee5 box task run tests.cfc db=oracle
   ```

### GitHub Actions

Oracle tests are included in the test matrix but are currently excluded by default. To enable:

1. Remove the Oracle exclusions from `.github/workflows/tests.yml`
2. Ensure GitHub Actions has access to Oracle images

## Troubleshooting

### Container takes too long to start
Oracle Database requires significant resources:
- Minimum 4GB RAM allocated to Docker
- First startup can take 10+ minutes
- Subsequent startups are faster (~2-3 minutes)

### Connection issues
- Ensure port 1521 is not in use
- Check container logs: `docker compose logs oracle`
- Verify database is ready before running tests

### Test failures
- Oracle has different SQL syntax than other databases
- Check for Oracle-specific test workarounds
- Review the Oracle adapter in `vendor/wheels/model/adapters/Oracle.cfc`