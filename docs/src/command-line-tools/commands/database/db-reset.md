# wheels db reset (Coming Soon)
*This command may not work as expected. A complete and stable version is **coming soon**.*

Reset the database by dropping it and recreating it from scratch.

## Synopsis

```bash
wheels db reset [--datasource=<name>] [--environment=<env>] [--force] [--skip-seed] [--seed-count=<n>]
```

## Description

The `wheels db reset` command completely rebuilds your database by executing four operations in sequence:

1. Drops the existing database (`wheels db drop`)
2. Creates a new database (`wheels db create`)
3. Runs all migrations (`wheels dbmigrate latest`)
4. Seeds the database with sample data (`wheels db seed`)

This is a destructive operation that will delete all existing data.

## Options

### --datasource=<name>
Specify which datasource to use. If not provided, uses the default datasource from your Wheels configuration.

```bash
wheels db reset --datasource=myapp_dev
```

### --environment=<env>
Specify the environment to use. Defaults to the current environment.

```bash
wheels db reset --environment=testing
```

### --force
Skip the confirmation prompt. Use with caution!

```bash
wheels db reset --force
```

### --skip-seed
Skip the database seeding step.

```bash
wheels db reset --skip-seed
```

### --seed-count=<n>
Number of records to generate per model when seeding. Defaults to 5.

```bash
wheels db reset --seed-count=20
```

## Examples

### Basic Usage

Reset with confirmation:
```bash
wheels db reset
# Will prompt: Are you sure you want to reset the database? Type 'yes' to confirm:
```

### Force Reset

Reset without confirmation:
```bash
wheels db reset --force
```

### Reset Test Database

```bash
wheels db reset --datasource=myapp_test --environment=testing --force
```

### Reset Without Seeding

```bash
wheels db reset --skip-seed --force
```

## Safety Features

1. **Confirmation Required**: Must type "yes" to confirm (unless --force)
2. **Production Warning**: Extra warning for production environment
3. **Special Production Confirmation**: Must type "reset production database" for production

## Warning

**This operation is irreversible!** All data will be permanently lost.

## Common Use Cases

### Development Reset
```bash
# When you need a fresh start
wheels db reset --force --seed-count=50
```

### Before Major Changes
```bash
# Backup first
wheels db dump --output=backup-before-reset.sql

# Then reset
wheels db reset
```

### Automated Testing
```bash
# In test scripts
wheels db reset --environment=testing --force --skip-seed
```

## What Happens

1. **Drop Database**
   - All tables and data are deleted
   - Database is completely removed

2. **Create Database**
   - Fresh database is created
   - Character set and collation are set (MySQL)

3. **Run Migrations**
   - All migrations run from scratch
   - Schema is recreated

4. **Seed Database** (unless --skip-seed)
   - Sample data is generated
   - Useful for development/testing

## Error Recovery

If reset fails partway through:

```bash
# Manual recovery steps
wheels db drop --force        # Ensure old database is gone
wheels db create             # Create new database
wheels dbmigrate latest      # Run migrations
wheels db seed              # Seed data (optional)
```

## Best Practices

1. **Always backup production data first**
2. **Use --force only in automated scripts**
3. **Avoid resetting production databases**
4. **Use db setup for new databases instead**

## Related Commands

- [`wheels db setup`](db-setup.md) - Setup new database (non-destructive)
- [`wheels db drop`](db-drop.md) - Just drop database
- [`wheels db dump`](db-dump.md) - Backup before reset
- [`wheels dbmigrate reset`](dbmigrate-reset.md) - Reset just migrations