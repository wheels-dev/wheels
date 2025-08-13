# wheels db setup (Coming Soon)
*This command may not work as expected. A complete and stable version is **coming soon**.*

Setup a complete database by creating it, running migrations, and seeding data.

## Synopsis

```bash
wheels db setup [--datasource=<name>] [--environment=<env>] [--skip-seed] [--seed-count=<n>]
```

## Description

The `wheels db setup` command performs a complete database initialization in one command. It executes three operations in sequence:

1. Creates the database (`wheels db create`)
2. Runs all migrations (`wheels dbmigrate latest`)
3. Seeds the database with sample data (`wheels db seed`)

This is ideal for setting up a new development environment or initializing a test database.

## Options

### --datasource=<name>
Specify which datasource to use. If not provided, uses the default datasource from your Wheels configuration.

```bash
wheels db setup --datasource=myapp_dev
```

### --environment=<env>
Specify the environment to use. Defaults to the current environment.

```bash
wheels db setup --environment=testing
```

### --skip-seed
Skip the database seeding step.

```bash
wheels db setup --skip-seed
```

### --seed-count=<n>
Number of records to generate per model when seeding. Defaults to 5.

```bash
wheels db setup --seed-count=20
```

## Examples

### Basic Usage

Full setup with default options:
```bash
wheels db setup
```

### Setup Without Sample Data

Create and migrate only:
```bash
wheels db setup --skip-seed
```

### Setup Test Database

```bash
wheels db setup --datasource=myapp_test --environment=testing --seed-count=10
```

### Production Setup

```bash
wheels db setup --environment=production --skip-seed
```

## What It Does

The command executes these steps in order:

1. **Create Database**
   - Creates new database if it doesn't exist
   - Uses datasource configuration for connection details

2. **Run Migrations**
   - Executes all pending migrations
   - Creates schema from migration files

3. **Seed Database** (unless --skip-seed)
   - Generates sample data for testing
   - Creates specified number of records per model

## Error Handling

If any step fails:
- The command stops execution
- Shows which step failed
- Provides instructions for manual recovery

## Common Use Cases

### New Developer Setup
```bash
git clone https://github.com/myproject/repo.git
cd repo
box install
wheels db setup
server start
```

### Reset Development Database
```bash
wheels db drop --force
wheels db setup --seed-count=50
```

### Continuous Integration
```bash
# In CI script
wheels db setup --environment=testing --skip-seed
wheels test run
```

## Best Practices

1. **Use for development**: Perfect for getting started quickly
2. **Skip seeding in production**: Use `--skip-seed` for production
3. **Customize seed count**: More data for performance testing
4. **Check migrations first**: Ensure migrations are up to date

## Related Commands

- [`wheels db create`](db-create.md) - Just create database
- [`wheels db reset`](db-reset.md) - Drop and recreate everything
- [`wheels dbmigrate latest`](dbmigrate-latest.md) - Just run migrations
- [`wheels db seed`](db-seed.md) - Just seed data