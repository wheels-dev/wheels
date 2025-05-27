# CFWheels TestUI Docker Usage

The CFWheels TestUI is now integrated into the main Docker Compose setup. This document provides instructions on how to use the Docker container for the new TestUI.

## Starting the TestUI

You can start the TestUI using the Docker Compose profile:

```bash
docker compose --profile ui up -d
```

This will start the TestUI container and make it available at http://localhost:3000.

## Using with Other Containers

You can start the TestUI along with other services:

```bash
# Start TestUI with Lucee 5 and MySQL
docker compose --profile ui --profile lucee --profile mysql up -d

# Start TestUI with all CFML engines and databases
docker compose --profile ui --profile all up -d
```

## Development Mode

For active development with hot-reloading:

```bash
# From the docker/testui directory
docker-compose -f docker-compose.dev.yml up
```

## Troubleshooting

If you encounter issues:

1. **Container not starting**: Check Docker logs
   ```bash
   docker logs cfwheels-testui-1
   ```

2. **API Proxy Issues**: The container is configured to proxy API requests to the appropriate CFML engines. Make sure those engines are running:
   ```bash
   docker compose --profile lucee up -d
   ```

3. **Host Connection Issues**: The container uses `host.docker.internal` to access services on the host. This should work on most Docker installations, but may require additional configuration on some Linux systems.

## Port Configuration

The TestUI container is configured to use the following ports:

- Port 3001: Web interface (http://localhost:3001)

If you need to change this, edit the compose.yml file's port mapping:

```yaml
ports:
  - "8080:80"  # Change 8080 to your desired port
```