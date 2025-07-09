# wheels ci init

Initialize continuous integration configuration for your Wheels application.

## Synopsis

```bash
wheels ci init [provider] [options]
```

## Description

The `wheels ci init` command sets up continuous integration (CI) configuration files for your Wheels application. It generates CI/CD pipeline configurations for popular CI providers like GitHub Actions, GitLab CI, Jenkins, and others.

## Arguments

| Argument | Description | Default |
|----------|-------------|---------|
| `provider` | CI provider to configure (github, gitlab, jenkins, travis, circle) | `github` |

## Options

| Option | Description |
|--------|-------------|
| `--template` | Use a specific template (basic, full, minimal) |
| `--branch` | Default branch name | `main` |
| `--engines` | CFML engines to test (lucee5, lucee6, adobe2018, adobe2021, adobe2023) | All engines |
| `--databases` | Databases to test against (h2, mysql, postgresql, sqlserver) | `h2` |
| `--force` | Overwrite existing CI configuration |
| `--help` | Show help information |

## Examples

### Initialize GitHub Actions
```bash
wheels ci init github
```

### Initialize with specific engines
```bash
wheels ci init github --engines=lucee6,adobe2023
```

### Initialize with multiple databases
```bash
wheels ci init github --databases=mysql,postgresql
```

### Initialize GitLab CI
```bash
wheels ci init gitlab --branch=develop
```

### Use full template with force overwrite
```bash
wheels ci init github --template=full --force
```

## What It Does

1. Creates CI configuration files in the appropriate location:
   - GitHub Actions: `.github/workflows/ci.yml`
   - GitLab CI: `.gitlab-ci.yml`
   - Jenkins: `Jenkinsfile`
   - Travis CI: `.travis.yml`
   - CircleCI: `.circleci/config.yml`

2. Configures test matrix for:
   - Multiple CFML engines
   - Multiple database systems
   - Different operating systems (if supported)

3. Sets up common CI tasks:
   - Dependency installation
   - Database setup
   - Test execution
   - Code coverage reporting
   - Artifact generation

## Generated Configuration

Example GitHub Actions configuration:

```yaml
name: CI
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        cfengine: [lucee5, lucee6, adobe2023]
        database: [h2]

    steps:
      - uses: actions/checkout@v4
      - name: Setup CommandBox
        uses: ortus-solutions/setup-commandbox@v2
      - name: Install dependencies
        run: box install
      - name: Start server
        run: box server start cfengine=${{ matrix.cfengine }}
      - name: Run tests
        run: box testbox run
```

## Templates

### Basic Template
- Single engine and database
- Essential test execution
- Minimal configuration

### Full Template
- Multiple engines and databases
- Code coverage
- Deployment steps
- Notifications

### Minimal Template
- Bare minimum for CI
- Quick setup
- No extras

## Use Cases

1. **New Project Setup**: Quickly add CI/CD to a new Wheels project
2. **Migration**: Move from one CI provider to another
3. **Standardization**: Apply consistent CI configuration across projects
4. **Multi-Engine Testing**: Ensure compatibility across CFML engines

## Notes

- Requires a valid Wheels application structure
- Some providers may require additional authentication setup
- Database services are configured as Docker containers where possible
- The command respects existing `.gitignore` patterns

## See Also

- [wheels test](../testing/test.md) - Run tests locally
- [wheels docker init](../tools/docker/docker-init.md) - Initialize Docker configuration
- [wheels deploy](../deploy/deploy.md) - Deployment commands
