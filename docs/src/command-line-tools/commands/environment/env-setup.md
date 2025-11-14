# wheels env setup

Setup a new environment configuration for your Wheels application with comprehensive database, template, and configuration options.

## Synopsis

```bash
wheels env setup environment=<name> [options]
```

## Description

The `wheels env setup` command creates and configures new environments for your Wheels application. It generates:
- Environment-specific `.env.[environment]` files with database and server settings using **generic `DB_*` variable names**
- Configuration files at `config/[environment]/settings.cfm` with Wheels settings
- Template-specific files (Docker, Vagrant) if requested
- Server.json updates for environment-specific configurations
- Updates `config/environment.cfm` with the current environment setting

The command supports copying configurations from existing environments and allows full customization of database types, templates, and framework settings.

### Interactive Database Credentials

When setting up environments with server-based databases (MySQL, PostgreSQL, MSSQL, Oracle), if database credentials are not provided as command arguments, the command will **interactively prompt** you to enter:
- Database host (default: localhost)
- Database port (database-specific defaults)
- Database username (default: varies by database type)
- Database password (masked input)
- Oracle SID (Oracle only)

This ensures you never use incorrect default credentials that could cause authentication failures.

## Arguments

| Argument | Description | Required |
|----------|-------------|----------|
| `environment` | Environment name (e.g., development, staging, production, testing) | Yes |

**Note**: Always use named parameter syntax: `environment=name` to avoid parameter conflicts.

## Options

| Option | Description | Default | Valid Values |
|--------|-------------|---------|--------------|
| `--template` | Deployment template type | `local` | `local`, `docker`, `vagrant` |
| `--dbtype` | Database type | `h2` | `h2`, `sqlite`, `mysql`, `postgres`, `mssql`, `oracle` |
| `--database` | Custom database name | `wheels_[environment]` | Any valid database name |
| `--datasource` | ColdFusion datasource name | `wheels_[environment]` | Any valid datasource name |
| `--host` | Database host | `localhost` (or prompted) | Any valid hostname/IP |
| `--port` | Database port | Database-specific (or prompted) | Valid port number |
| `--username` | Database username | Database-specific (or prompted) | Any valid username |
| `--password` | Database password | *(prompted if not provided)* | Any string |
| `--sid` | Oracle SID (Oracle only) | `ORCL` (or prompted) | Any valid SID |
| `--base` | Base environment to copy from | *(none)* | Any existing environment name |
| `--force` | Overwrite existing environment | `false` | `true`, `false` |
| `--debug` | Enable debug settings | `false` | `true`, `false` |
| `--cache` | Enable cache settings | `false` | `true`, `false` |
| `--reloadPassword` | Custom reload password | `wheels[environment]` | Any string |
| `--skipDatabase` | Skip database creation | `false` | `true`, `false` |
| `--help` | Show detailed help information | `false` | - |

## Examples

### Basic Environment Setup
```bash
# Create development environment with H2 database (default)
wheels env setup environment=development

# Create development environment with SQLite database (file-based, no server required)
wheels env setup environment=development --dbtype=sqlite --database=myapp_dev

# Create staging environment with MySQL (will prompt for credentials)
wheels env setup environment=staging --dbtype=mysql

# Create production environment with PostgreSQL and caching enabled
wheels env setup environment=production --dbtype=postgres --cache=true --debug=false

# Create environment with explicit credentials (no prompting)
wheels env setup environment=test --dbtype=mssql --host=localhost --port=1433 --username=sa --password=MyPassword123!
```

### Interactive Credential Example
```bash
# Running without credentials prompts interactively
wheels env setup environment=production --dbtype=mssql

# Output:
# Setting up production environment...
#
# Database credentials not provided for mssql database
# Would you like to enter database credentials now? [y/n] y
#
# Please provide database connection details:
#
# Database Host [localhost]: localhost
# Database Port [1433]: 1433
# Database Username [sa]: sa
# Database Password: ************
#
# Database credentials captured successfully!
```

### Using Base Environment
```bash
# Copy settings from development environment but use PostgreSQL
wheels env setup environment=testing --base=development --dbtype=postgres

# Create staging environment based on production settings
wheels env setup environment=staging --base=production --database=staging_db

# Create QA environment with custom settings
wheels env setup environment=qa --base=development --dbtype=mysql --debug=true --cache=false
```

### Advanced Configuration
```bash
# Setup with custom database and datasource names
wheels env setup environment=integration --dbtype=mysql --database=wheels_integration_db --datasource=integration_ds

# Setup with specific reload password and debugging
wheels env setup environment=dev --debug=true --reloadPassword=mypassword123 --force

# Docker environment setup
wheels env setup environment=docker-dev --template=docker --dbtype=postgres --database=wheels_docker
```

### Template-Based Setups
```bash
# Local development (default)
wheels env setup environment=dev --template=local --dbtype=h2

# Docker containerized environment
wheels env setup environment=docker-staging --template=docker --dbtype=mysql

# Vagrant VM environment
wheels env setup environment=vm-test --template=vagrant --dbtype=postgres
```

## What It Creates

### 1. Environment Variables File (`.env.[environment]`)

**Note**: All database types now use **generic `DB_*` variable names** for portability and consistency.

For H2 database:
```bash
## Wheels Environment: development
## Generated on: 2025-01-18 12:30:00

## Application Settings
WHEELS_ENV=development
WHEELS_RELOAD_PASSWORD=wheelsdevelopment

## Database Settings
DB_TYPE=h2
DB_HOST=
DB_PORT=
DB_DATABASE=./db/wheels_development
DB_USER=sa
DB_PASSWORD=
DB_DATASOURCE=wheels_development

## Server Settings
SERVER_PORT=8080
SERVER_CFENGINE=lucee5
```

For SQLite database:
```bash
## Wheels Environment: development
## Generated on: 2025-01-18 12:30:00

## Application Settings
WHEELS_ENV=development
WHEELS_RELOAD_PASSWORD=wheelsdevelopment

## Database Settings
DB_TYPE=sqlite
DB_HOST=
DB_PORT=
DB_DATABASE=./db/myapp_dev.db
DB_USER=
DB_PASSWORD=
DB_DATASOURCE=wheels_development

## Server Settings
SERVER_PORT=8080
SERVER_CFENGINE=lucee5
```

For MySQL database:
```bash
## Wheels Environment: production
## Generated on: 2025-01-18 12:30:00

## Application Settings
WHEELS_ENV=production
WHEELS_RELOAD_PASSWORD=wheelsproduction

## Database Settings
DB_TYPE=mysql
DB_HOST=localhost
DB_PORT=3306
DB_DATABASE=wheels_production
DB_USER=wheels
DB_PASSWORD=wheels_password
DB_DATASOURCE=wheels_production

## Server Settings
SERVER_PORT=8080
SERVER_CFENGINE=lucee5
```

For Microsoft SQL Server:
```bash
## Wheels Environment: staging
## Generated on: 2025-01-18 12:30:00

## Application Settings
WHEELS_ENV=staging
WHEELS_RELOAD_PASSWORD=wheelsstaging

## Database Settings
DB_TYPE=mssql
DB_HOST=localhost
DB_PORT=1433
DB_DATABASE=wheels_staging
DB_USER=sa
DB_PASSWORD=MySecurePassword123!
DB_DATASOURCE=wheels_staging

## Server Settings
SERVER_PORT=8080
SERVER_CFENGINE=lucee5
```

### 2. Configuration File (`config/[environment]/settings.cfm`)

```cfml
<cfscript>
    // Environment: production
    // Generated: 2025-01-18 12:30:00
    // Debug Mode: Disabled
    // Cache Mode: Enabled

    // Database settings
    set(dataSourceName="wheels_production");

    // Environment settings
    set(environment="production");

    // Debug settings - controlled by debug argument
    set(showDebugInformation=false);
    set(showErrorInformation=false);

    // Caching settings - controlled by cache argument
    set(cacheFileChecking=true);
    set(cacheImages=true);
    set(cacheModelInitialization=true);
    set(cacheControllerInitialization=true);
    set(cacheRoutes=true);
    set(cacheActions=true);
    set(cachePages=true);
    set(cachePartials=true);
    set(cacheQueries=true);

    // Security
    set(reloadPassword="wheelsproduction");

    // URLs
    set(urlRewriting="partial");

    // Environment-specific settings
    set(sendEmailOnError=true);
    set(errorEmailAddress="dev-team@example.com");
</cfscript>
```

### 3. Template-Specific Files

#### Docker Template (`--template=docker`)
Creates:
- `docker-compose.[environment].yml`
- `Dockerfile` (if not exists)

#### Vagrant Template (`--template=vagrant`)
Creates:
- `Vagrantfile.[environment]`
- `vagrant/provision-[environment].sh`

## Database Types

### H2 (Embedded)
- **Use Case**: Development, testing, quick prototyping
- **Connection**: No network port required (embedded)
- **Database Path**: `./db/[database_name]`
- **Default Credentials**: username=`sa`, password=*(empty)*
- **Creation**: Database file created on first connection (lazy creation)

```bash
wheels env setup environment=dev --dbtype=h2 --database=my_dev_db
```

### SQLite (File-Based)
- **Use Case**: Development, testing, prototyping, portable applications, embedded systems
- **Connection**: No network port required (file-based, serverless)
- **Database Path**: `./db/[database_name].db`
- **Default Credentials**: No username/password required (file-based authentication)
- **Creation**: Database file created immediately (eager creation)
- **JDBC Driver**: `org.sqlite.JDBC` (org.xerial.sqlite-jdbc v3.47.1.0) - included with Lucee/CommandBox
- **Auxiliary Files**: Creates `.db-wal`, `.db-shm`, `.db-journal` during operation
- **Configuration**: Uses absolute paths in datasource configuration
- **Advantages**:
  - Zero configuration - no server setup required
  - Portable - single file database, easy to backup/move
  - Fast - ideal for local development and testing
  - Self-contained - all data in one file
  - Cross-platform - works on Windows, macOS, Linux
- **Limitations**:
  - Single writer - not suitable for high-concurrency scenarios
  - File locking - can cause issues on network drives
  - Not recommended for production with multiple concurrent users

```bash
# Basic SQLite environment setup
wheels env setup environment=dev --dbtype=sqlite --database=myapp_dev

# SQLite with custom database name
wheels env setup environment=test --dbtype=sqlite --database=integration_tests

# SQLite for prototyping
wheels env setup environment=prototype --dbtype=sqlite --database=prototype_v1
```

### MySQL
- **Use Case**: Production, staging environments
- **Default Port**: 3306
- **Default Credentials**: username=`wheels`, password=`wheels_password`

```bash
wheels env setup environment=prod --dbtype=mysql --database=wheels_production
```

### PostgreSQL
- **Use Case**: Production, complex applications
- **Default Port**: 5432
- **Default Credentials**: username=`wheels`, password=`wheels_password`

```bash
wheels env setup environment=staging --dbtype=postgres
```

### Microsoft SQL Server
- **Use Case**: Enterprise environments
- **Default Port**: 1433
- **Default Credentials**: username=`sa`, password=`Wheels_Pass123!`

```bash
wheels env setup environment=enterprise --dbtype=mssql
```

## Base Environment Copying

When using `--base`, the command copies configuration from an existing environment:

### What Gets Copied:
- Database host, username, and password
- Server configuration (port, CF engine)
- Custom environment variables

### What Gets Modified:
- Environment name
- Database name (becomes `wheels_[new_environment]`)
- Database type, driver, and port (based on `--dbtype`)
- Reload password (becomes `wheels[new_environment]`)

```bash
# Copy from production but use H2 for testing
wheels env setup environment=test --base=production --dbtype=h2

# Copy from development but use different database name
wheels env setup environment=feature-branch --base=development --database=feature_test_db
```

## Environment Naming Conventions

### Recommended Names:
- `development` or `dev` - Local development
- `testing` or `test` - Automated testing
- `staging` - Pre-production testing
- `production` or `prod` - Live environment
- `qa` - Quality assurance
- `demo` - Client demonstrations

### Custom Names:
```bash
wheels env setup environment=feature-auth --base=development
wheels env setup environment=performance-test --base=production --cache=false
wheels env setup environment=client-demo --base=staging
```

## Template Options

### Local Template (default)
Best for traditional server deployments:
```bash
wheels env setup environment=prod --template=local --dbtype=mysql
```

### Docker Template
Creates containerized environment:
```bash
wheels env setup environment=docker-dev --template=docker --dbtype=postgres
```

Generated `docker-compose.docker-dev.yml`:
```yaml
version: '3.8'

services:
  app:
    build: .
    ports:
      - "8080:8080"
    environment:
      - WHEELS_ENV=docker-dev
      - DB_TYPE=postgres
      - DB_HOST=db
      - DB_PORT=5432
      - DB_NAME=wheels
      - DB_USER=wheels
      - DB_PASSWORD=wheels_password
    volumes:
      - .:/app
    depends_on:
      - db

  db:
    image: postgres:14
    ports:
      - "5432:5432"
    environment:
      POSTGRES_DB=wheels
      POSTGRES_USER=wheels
      POSTGRES_PASSWORD=wheels_password
    volumes:
      - db_data:/var/lib/postgresql/data

volumes:
  db_data:
```

### Vagrant Template
Creates VM-based environment:
```bash
wheels env setup environment=vm-test --template=vagrant --dbtype=mysql
```

## Next Steps After Setup

The command provides environment-specific next steps:

### Local Template:
1. Switch to environment: `wheels env switch [environment]`
2. Start server: `box server start`
3. Access application at: http://localhost:8080

### Docker Template:
1. Start Docker environment: `docker-compose -f docker-compose.[environment].yml up`
2. Access application at: http://localhost:8080
3. Stop environment: `docker-compose -f docker-compose.[environment].yml down`

### Vagrant Template:
1. Start Vagrant VM: `vagrant up`
2. Access application at: http://localhost:8080 or http://192.168.56.10:8080
3. SSH into VM: `vagrant ssh`
4. Stop VM: `vagrant halt`

## Configuration Management

### Environment Detection
Update `config/environment.cfm` to automatically detect environments:

```cfml
<cfscript>
// Auto-detect environment based on server name
if (cgi.server_name contains "staging") {
    this.env = "staging";
} else if (cgi.server_name contains "test") {
    this.env = "testing";
} else if (cgi.server_name contains "demo") {
    this.env = "demo";
} else if (cgi.server_name contains "localhost") {
    this.env = "development";
} else {
    this.env = "production";
}
</cfscript>
```

### Environment Variables Integration
Load `.env.[environment]` files in `Application.cfc`:

```cfml
<cfscript>
component extends="wheels.Controller" {

    function config() {
        // Load environment-specific variables
        var envFile = expandPath(".env." & get("environment"));
        if (fileExists(envFile)) {
            loadEnvironmentFile(envFile);
        }
    }

    private function loadEnvironmentFile(filePath) {
        var lines = fileRead(arguments.filePath).listToArray(chr(10));
        for (var line in lines) {
            if (len(trim(line)) && !line.startsWith("##")) {
                var parts = line.listToArray("=");
                if (arrayLen(parts) >= 2) {
                    var key = trim(parts[1]);
                    var value = trim(parts[2]);
                    // Set as system property or use in configuration
                    set(lCase(key), value);
                }
            }
        }
    }
}
</cfscript>
```

## Validation and Testing

After creating an environment, validate the setup:

```bash
# List all environments to verify creation
wheels env list

# Switch to the new environment
wheels env switch [environment]

# Test database connection
wheels test run --type=core

# Check configuration
wheels env current
```

## Error Handling

### Common Issues and Solutions:

**Environment already exists:**
```bash
wheels env setup environment=staging --force
```

**Base environment not found:**
```bash
# Check available environments
wheels env list
# Use correct base environment name
wheels env setup environment=test --base=development
```

**Database connection issues:**
- Verify database credentials in `.env.[environment]`
- Check database server is running
- Validate port configuration

**Permission issues:**
- Ensure write permissions for config directory
- Check file system permissions

## Best Practices

### 1. Environment Naming
- Use consistent, descriptive names
- Avoid spaces and special characters
- Follow team conventions

### 2. Database Management
- Use separate databases per environment
- Document database naming conventions
- Implement proper backup strategies

### 3. Security
- Use strong, unique reload passwords
- Never commit sensitive credentials
- Use environment variables for secrets

### 4. Configuration
- Start with a solid base environment
- Document environment purposes
- Test configurations thoroughly

### 5. Template Selection
- `local`: Traditional server deployments
- `docker`: Containerized applications
- `vagrant`: Isolated development VMs

## Integration Examples

### CI/CD Pipeline
```bash
# Create testing environment for CI
wheels env setup environment=ci-test --base=production --dbtype=h2 --debug=false

# Create staging environment for deployment testing
wheels env setup environment=staging --base=production --dbtype=mysql --cache=true
```

### Feature Development
```bash
# Create feature-specific environment
wheels env setup environment=feature-login --base=development --database=login_feature_db

# Create A/B testing environments
wheels env setup environment=variant-a --base=production --database=variant_a_db
wheels env setup environment=variant-b --base=production --database=variant_b_db
```

## Troubleshooting

### Configuration File Issues
1. Check syntax in generated `settings.cfm`
2. Verify file permissions in config directory
3. Review environment variable formats

### Database Connection Problems
1. Verify database server is running
2. Check credentials in `.env.[environment]`
3. Test connection manually
4. Review port configurations (remember H2 has no port)

### Environment Detection
1. Check `config/environment.cfm` logic
2. Verify server variables
3. Test detection rules manually

## Performance Considerations

### Development Environments
- Enable debugging for detailed information
- Disable caching for hot reload
- Use H2 for fast setup and teardown

### Production Environments
- Disable debugging for performance
- Enable all caching options
- Use optimized database configurations

## See Also

- [wheels env list](env-list.md) - List all environments
- [wheels env switch](env-switch.md) - Switch between environments
- [wheels env current](env-current.md) - Show current environment
- [Environment Configuration Guide](../../working-with-wheels/switching-environments.md)