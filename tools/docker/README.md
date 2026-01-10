# Wheels Internal Test Suites

## Directories

- `/src/docker/` - New Docker based standalone test suite (not for CI)
- `/src/docker/sqlserver` - SQL server specific config
- `/src/docker/testui` - Modern Test Suite frontend with container management

## Docker Compose Profiles

The Docker Compose setup now uses profiles to organize the containers:

- `db`: Database containers (MySQL, PostgreSQL, SQL Server)
- `lucee`: Lucee CFML engines (5, 6)
- `adobe`: Adobe ColdFusion engines (2018, 2021, 2023)
- `ui`: TestUI containers (web interface and API server) for running tests and managing containers
- `quick-test`: Minimal setup for quick testing (Lucee 5, MySQL)
- `current`: Latest versions of Lucee and Adobe engines
- `compatibility`: All CFML engines for compatibility testing
- `all`: All containers

## Usage with Profiles

Start containers using profiles:

```bash
# Start just the latest Lucee engine with MySQL
docker compose --profile quick-test up -d

# Start all Adobe ColdFusion engines
docker compose --profile adobe up -d

# Start SQL Server only
docker compose --profile sqlserver up -d

# Start all containers
docker compose --profile all up -d
```

### How to run (Legacy Method)

- Ensure docker is installed (beyond the scope of this document)
- Increase Docker's default allocated 2GB memory to about 4GB
- Ensure the following ports are free
  - `60005`
  - `60006`
  - `62018`
  - `62021`
  - `62023`
  - `3000`
- Navigate to the repo root
- Run `docker compose up`

### On first run

If this is the first time you've run it, docker will download a lot of stuff, namely:

- **Commandbox Docker image**, which in turn will get **Lucee5 / Lucee6 / ACF2018 / ACF2021 / ACF2023** (note, the Commandbox artifacts directory will be created/aliased to `/.Commandbox` for caching, so your images won't have to get them every time your image is rebuilt)
- **MySQL**
- **Postgres**
- **MSSQL 2022**

Once all the images are downloaded (this may take some time), the databases will attempt to start. MySQL/Postgres are fairly simple, using the predefined images which allow for a database to be created directly from docker compose; MSSQL doesn't allow for this annoyingly, so we're actually spinning up a custom image based on the Microsoft Azure one, which allows us to script for the creation of a new database.

Once the Databases are running, the Commandbox images will start. URL Rewriting is included by default. Note we're not using Commandbox's default, as we need Wheels-specific rewrites

### Datasources
Each database type is added as a datasource via `CFConfig.json` files. But there are different version of `CFConfig.json` for each flavor of engine. All engines get a copy of `wheelstestdb` which defaults to MySQL if no DB is sprecified. Additioanlly, all engines get a copy of `wheelstestdb_mysql`, `wheelstestdb_sqlserver`, and `wheelstestdb_postgres`. Lastly, the Lucee engine gets an additional datasource `wheelstestdb_h2` for testing against the built in H2 Database.

- `wheelstestdb` - Defaults to mySQL
- `wheelstestdb_mysql` MySQL
- `wheelstestdb_sqlserver` MSSQL
- `wheelstestdb_postgres` Postgres
- `wheelstestdb_h2` H2 Database

There's a new `db={{database}}` URL var which switches which datasource is used: the TestUI just appends this string to the test runner.

Please note that there is an additional datasource defined `msdb_sqlserver` which is initially used to create the wheelstestdb if it doesn't exists.

### What runs on what port

Docker compose basically creates it's own internal network and exposes the various services on different ports. You shouldn't need to connect to the databases directly so those ports aren't exposed to prevent clashes with externally running services

- Lucee 5 on `60005`
- Lucee 6 on `60006`
- ACF2018 on `62018`
- ACF2021 on `62021`
- ACF2023 on `62023`
- TestUI on `3000`
- TestUI API Server on `3001`

### Network Configuration

The containers use the following network configuration:

- Network aliases ensure that containers can communicate with each other
- SQL Server is accessible via the service name `sqlserver`
- CFML engine containers connect to databases using the hostnames defined in their CFConfig.json files

### How to actually run the tests

Use the Provided UI at `localhost:3000` for ease. The TestUI provides:
- Visual test runner with real-time results
- Container management - start stopped containers by clicking on them
- Pre-flight checks to ensure services are running
- Test history and statistics
- Support for all CFML engines and databases including Oracle

You can also access each CF Engine directly on it's respective port, i.e, to access ACF2018, you just go to `localhost:62018`

A sample task runner URL is `http://localhost:60005/wheels/core/tests?format=json&sort=directory%20asc&db=mysql`. You can change the port to hit a different engine and change the db name to test a different database.

### Other useful commands

You can start specific services or rebuild specific services by name using profiles or direct service names:

```bash
# Using profiles
docker compose --profile lucee up -d

# Using service names
docker compose up adobe2018
docker compose up sqlserver
```

Likewise if you need to rebuild any of the images, you can do it on an image by image basis if needed:

`docker compose up testui --build` *etc*

Which can be quicker than rebuilding everything via `docker compose up --build`

## Troubleshooting

If you encounter issues with a specific container:

1. Check the container logs: `docker logs <container-name>`
2. Verify network connectivity between containers
3. For SQL Server issues, see the specific README in the sqlserver directory
4. If using Apple Silicon (M1/M2/M3/M4), make sure to enable Rosetta for SQL Server

### Known Issues

There's an issue with CORS tests currently, which means those tests are currently commented out

### Rebuilding

You can force a rebuild of all the images via `docker compose up --build` which is useful if you change configuration of any of the Dockerfiles etc. The two adobe engines still take ages to boot this way (just an fyi)