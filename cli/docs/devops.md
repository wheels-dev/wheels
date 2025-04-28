# DevOps Commands

The Wheels CLI includes commands to streamline DevOps processes, including CI/CD configuration and Docker containerization.

## CI/CD Configuration

### CI Init

Generate CI/CD configuration files for popular CI/CD platforms.

#### Usage

```bash
wheels ci:init [platform] [--includeDeployment=true] [--dockerEnabled=true]
```

#### Parameters

- `platform`: CI/CD platform to generate configuration for (github, gitlab, jenkins) (required)
- `includeDeployment`: Include deployment configuration (default: true)
- `dockerEnabled`: Enable Docker-based workflows (default: true)

#### Examples

```bash
# Generate GitHub Actions configuration
wheels ci:init github

# Generate GitLab CI configuration without deployment
wheels ci:init gitlab --includeDeployment=false

# Generate Jenkins configuration without Docker
wheels ci:init jenkins --dockerEnabled=false
```

#### Generated Configurations

##### GitHub Actions

Creates `.github/workflows/` directory with:

- `ci.yml`: Testing workflow triggered on push and pull request
- `deploy.yml`: Deployment workflow triggered on pushes to main branch (if includeDeployment=true)

##### GitLab CI

Creates `.gitlab-ci.yml` with:

- Testing stage: Runs tests on every commit
- Build stage: Builds Docker image (if dockerEnabled=true)
- Deploy stage: Deploys application (if includeDeployment=true)

##### Jenkins

Creates `Jenkinsfile` with:

- Checkout stage: Gets the code
- Install Dependencies stage: Installs required dependencies
- Build stage: Builds Docker image (if dockerEnabled=true)
- Test stage: Runs tests
- Deploy stage: Deploys application (if includeDeployment=true)

## Docker Configuration

### Docker Init

Initialize Docker configuration for development.

#### Usage

```bash
wheels docker:init [--db=mysql] [--dbVersion=] [--cfengine=lucee] [--cfVersion=5.3]
```

#### Parameters

- `db`: Database to use (h2, mysql, postgres, mssql) (default: mysql)
- `dbVersion`: Database version to use (optional, defaults to latest stable)
- `cfengine`: ColdFusion engine to use (lucee, adobe) (default: lucee)
- `cfVersion`: ColdFusion engine version (default: 5.3)

#### Examples

```bash
# Initialize with default options (MySQL and Lucee)
wheels docker:init

# Initialize with PostgreSQL and Adobe ColdFusion
wheels docker:init --db=postgres --cfengine=adobe

# Initialize with specific versions
wheels docker:init --db=mysql --dbVersion=8.0 --cfengine=lucee --cfVersion=5.3
```

#### Generated Files

- `docker-compose.yml`: Defines services for development
- `Dockerfile`: Defines the ColdFusion application container
- `docker/db/`: Database initialization scripts
- `.dockerignore`: Files to exclude from Docker context

### Docker Deploy

Create production-ready Docker configurations for deploying your application.

#### Usage

```bash
wheels docker:deploy [--environment=production] [--db=mysql] [--cfengine=lucee] [--optimize=true]
```

#### Parameters

- `environment`: Deployment environment (production, staging) (default: production)
- `db`: Database to use (h2, mysql, postgres, mssql) (default: mysql)
- `cfengine`: ColdFusion engine to use (lucee, adobe) (default: lucee)
- `optimize`: Enable production optimizations (default: true)

#### Examples

```bash
# Create production configuration with default options
wheels docker:deploy

# Create staging configuration with PostgreSQL
wheels docker:deploy --environment=staging --db=postgres

# Create production configuration without optimizations
wheels docker:deploy --optimize=false
```

#### Generated Files

- `docker-compose.{environment}.yml`: Defines services for the specified environment
- `Dockerfile.{environment}`: Defines the optimized application container
- `.env.{environment}`: Environment variables for the specified environment
- `deploy.sh`: Deployment script
- `renew-ssl.sh`: SSL certificate renewal script (for production)
- `docker/nginx/`: Nginx configuration for reverse proxy and SSL

## Using Docker for Development

Once you've initialized Docker for development, you can:

1. **Start the environment**:
   ```bash
   docker-compose up -d
   ```

2. **View logs**:
   ```bash
   docker-compose logs -f
   ```

3. **Run commands in the container**:
   ```bash
   docker-compose exec cfwheels box wheels test
   ```

4. **Stop the environment**:
   ```bash
   docker-compose down
   ```

## Deploying with Docker

After creating production Docker configurations, you can:

1. **Configure environment variables**:
   Edit `.env.production` to set your specific environment variables

2. **Deploy using the script**:
   ```bash
   ./deploy.sh production
   ```

3. **Renew SSL certificates**:
   ```bash
   ./renew-ssl.sh
   ```

## CI/CD Integration

The generated CI/CD configurations can be customized to:

1. **Run tests** on every commit
2. **Build Docker images** for passing builds
3. **Deploy to staging** on feature branch merges
4. **Deploy to production** on main branch updates

## Best Practices

### Docker

1. **Layer Optimization**: Minimize the number of layers in your Dockerfile
2. **Multi-stage Builds**: Use multi-stage builds to keep final images small
3. **Environment Variables**: Use environment variables for configuration
4. **Volume Persistence**: Use volumes for data that needs to persist
5. **Container Networking**: Configure proper networking between containers

### CI/CD

1. **Parallel Testing**: Run tests in parallel to speed up builds
2. **Caching**: Cache dependencies to improve build times
3. **Secrets Management**: Never store secrets in your code or Docker images
4. **Approval Gates**: Add approval steps before production deployments
5. **Rollback Strategy**: Have a plan for rolling back failed deployments