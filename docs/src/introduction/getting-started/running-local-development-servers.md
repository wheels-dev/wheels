# Running Local Development Servers

Wheels uses a Docker-based development environment that provides consistent, containerized development with support for multiple CFML engines and databases.

### Prerequisites

1. **Docker**: Install Docker Desktop from [docker.com](https://www.docker.com/products/docker-desktop)
2. **Wheels CLI**: Install the Wheels CommandBox module:
   ```bash
   box install wheels-cli
   ```

### Setting up Docker Development Environment

Navigate to the Wheels framework directory and go to the application template:

```bash
cd templates/base/src
```

Initialize your Docker development environment:

```bash
wheels docker init cfengine=adobe cfversion=2018 db=mysql
```

#### Command Options

**cfengine** options:
- `lucee` - Lucee CFML engine
- `adobe` - Adobe ColdFusion
- `boxlang` - BoxLang CFML engine

**cfversion** options:
- Major versions for Adobe ColdFusion: `2018`, `2021`, `2023`, `2025`
- Major versions for Lucee: `5`, `6`
- Major versions for BoxLang: `1`

**db** options:
- `mysql` - MySQL database
- `postgres` - PostgreSQL database  
- `mssql` - Microsoft SQL Server
- `h2` - H2 embedded database

#### Generated Files

The `wheels docker init` command creates several files in your project:

- **`.dockerignore`** - Specifies files to exclude from Docker build context
- **`Dockerfile`** - Container definition for your chosen CFML engine
- **`docker-compose.yml`** - Multi-container application definition
- **`CFConfig.json`** - CFML engine configuration with datasource setup

### Starting Your Development Environment  

After running the init command, start your containers:

```bash
docker-compose up -d
```

The containers will take a few minutes to start the first time as Docker downloads the necessary images. Once started, your application will be available at:

- **Default**: `http://localhost:8080`
- **Custom port**: Check your `server.json` file for the configured port

### Managing Your Docker Environment

```bash
# Stop the containers
docker-compose down

# View running containers
docker-compose ps

# View container logs
docker-compose logs

# Rebuild and restart
docker-compose up -d --build
```

## Additional Configuration

### Custom Ports

The default port is 8080, but you can customize this by modifying the `server.json` file in `templates/base/src`:

```json
{
    "name":"wheels",
    "web":{
        "host":"localhost",
        "http":{
            "port":3000
        },
        "webroot":"public",
        "rewrites":{
            "enable":true,
            "config":"public/urlrewrite.xml"
        }
    }
}
```

### Database Configuration

The generated `CFConfig.json` file automatically configures a datasource for your chosen database. The configuration includes:

- **Connection settings** for your selected database type
- **Default datasource** named `wheels-dev`
- **Appropriate drivers** for the database engine

### Development Workflow

1. **Make code changes** in your `templates/base/src` directory
2. **Changes are reflected immediately** due to Docker volume mounting
3. **Database changes persist** between container restarts
4. **Use standard Wheels commands** like migrations, generators, etc.

### Troubleshooting

**Containers won't start:**
```bash
# Check if ports are in use
docker-compose ps
netstat -an | grep 8080

# Force recreate containers
docker-compose down
docker-compose up -d --force-recreate
```

**Database connection issues:**
```bash
# Check database container logs
docker-compose logs db

# Restart just the database
docker-compose restart db
```

**Performance issues:**
- Ensure Docker Desktop has adequate memory allocated (4GB+ recommended)
- On Windows/Mac, enable file sharing for your project directory

{% hint style="info" %}
#### CFIDE / Lucee administrators

The default username and password for all administrators is `admin` & `commandbox`
{% endhint %}