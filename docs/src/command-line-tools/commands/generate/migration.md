# wheels generate migration

Generate database migration files using templates.

## Synopsis

```bash
wheels generate migration name=<migrationName> [options]

# Can also be used as:
wheels g migration name=<migrationName> [options]
```

## CommandBox Parameter Syntax

- **Named parameters**: `param=value` (e.g., `name=CreateUsersTable`, `table=users`)
- **Flag parameters**: `--flag` equals `flag=true` (e.g., `--force` equals `force=true`)
- **Param with value**: `--param=value` equals `param=value` (e.g., `--description="User management"`)

**Recommended:** Use named parameters: `wheels generate migration name=CreateUsersTable --create=users`

## Description

The `wheels generate migration` command creates database migration files using pre-built templates. Migrations provide version control for your database schema, allowing you to incrementally modify your database structure and roll back changes when needed. The command intelligently detects migration type from the name pattern and uses appropriate templates with transaction handling and error management.

## Arguments

| Argument | Description | Default |
|----------|-------------|---------|
| `name` | Migration name (e.g., CreateUsersTable, AddEmailToUsers) | Required |

### Migration Name Conventions
- Must start with a letter
- Can contain letters, numbers, and underscores
- Use PascalCase for readability
- Should describe the migration action clearly

**Common Patterns:**
- `Create[Table]Table` - Creates a new table
- `Add[Column]To[Table]` - Adds column(s) to existing table
- `Remove[Column]From[Table]` - Removes column(s) from table
- `Rename[OldColumn]To[NewColumn]` - Renames a column
- `Change[Column]In[Table]` - Modifies column type/properties
- `CreateIndexOn[Table]` - Adds an index
- `RemoveIndexFrom[Table]` - Removes an index

## Options

| Option | Description | Valid Values | Default |
|--------|-------------|--------------|---------|
| `create` | Table name to create (forces create_table type) | Valid table name | `""` |
| `table` | Table name to modify (for column operations) | Valid table name | `""` |
| `drop` | Table name to drop (forces remove_table type) | Valid table name | `""` |
| `description` | Migration description (added as hint) | Any descriptive text | `""` |
| `force` | Overwrite existing migration file | `true`, `false` | `false` |

## Migration Types and Templates

The command automatically detects the migration type and uses the appropriate template:

| Type | Template | Detected Pattern | Example |
|------|----------|------------------|---------|
| Create Table | `create-table.txt` | `Create*Table` | CreateUsersTable |
| Remove Table | `remove-table.txt` | `Drop*Table`, `Remove*Table` | DropUsersTable |
| Add Column | `create-column.txt` | `Add*To*` | AddEmailToUsers |
| Remove Column | `remove-column.txt` | `Remove*From*` | RemoveAgeFromUsers |
| Change Column | `change-column.txt` | `Change*In*` | ChangeNameInUsers |
| Rename Column | `rename-column.txt` | `Rename*To*` | RenameFirstnameToFullname |
| Add Index | `create-index.txt` | `CreateIndexOn*` | CreateIndexOnUsersEmail |
| Remove Index | `remove-index.txt` | `RemoveIndexFrom*` | RemoveIndexFromUsers |
| Blank | `blank.txt` | Any other pattern | CustomMigration |

## Examples

### Create Table Migration
```bash
wheels generate migration name=CreateUsersTable
```
Creates migration using `create-table.txt` template with transaction handling.

### Create Table with Explicit Table Name
```bash
wheels generate migration name=CreateUsersTable --create=users
```
Forces create_table type and uses "users" as table name.

### Add Column Migration
```bash
wheels generate migration name=AddEmailToUsers --table=users
```
Creates migration using `create-column.txt` template.

### Remove Column Migration
```bash
wheels generate migration name=RemoveAgeFromUsers --table=users
```
Creates migration using `remove-column.txt` template.

### Drop Table Migration
```bash
wheels generate migration name=DropProductsTable
```
Creates migration using `remove-table.txt` template.

### With Description
```bash
wheels generate migration name=CreateUsersTable --description="User authentication table"
```
Adds description as hint to the migration component.

### Blank/Custom Migration
```bash
wheels generate migration name=MigrateUserData --description="Move user data to new structure"
```
Creates blank migration for custom migration code.

### Force Overwrite
```bash
wheels generate migration name=CreateUsersTable --force=true
```
Overwrites existing migration file.

## Generated Code Examples

### Create Table Migration (Using Template)
```cfc
component extends="wheels.migrator.Migration" hint="CreateUsersTable" {

	function up() {
		transaction {
			try {
				t = createTable(name = 'users', force='false', id='true', primaryKey='id');
				t.timestamps();
				t.create();
			} catch (any e) {
				local.exception = e;
			}

			if (StructKeyExists(local, "exception")) {
				transaction action="rollback";
				Throw(errorCode = "1", detail = local.exception.detail, message = local.exception.message, type = "any");
			} else {
				transaction action="commit";
			}
		}
	}

	function down() {
		transaction {
			try {
				dropTable('users');
			} catch (any e) {
				local.exception = e;
			}

			if (StructKeyExists(local, "exception")) {
				transaction action="rollback";
				Throw(errorCode = "1", detail = local.exception.detail, message = local.exception.message, type = "any");
			} else {
				transaction action="commit";
			}
		}
	}

}
```

### Add Column Migration (Using Template)
```cfc
component extends="wheels.migrator.Migration" hint="AddEmailToUsers" {

	function up() {
		transaction {
			try {
				addColumn(table='users', columnType='string', columnName='column_name', default='', null='true', limit='255');
			} catch (any e) {
				local.exception = e;
			}

			if (StructKeyExists(local, "exception")) {
				transaction action="rollback";
				Throw(errorCode = "1", detail = local.exception.detail, message = local.exception.message, type = "any");
			} else {
				transaction action="commit";
			}
		}
	}

	function down() {
		transaction {
			try {
				removeColumn(table='users', columnName='column_name');
			} catch (any e) {
				local.exception = e;
			}

			if (StructKeyExists(local, "exception")) {
				transaction action="rollback";
				Throw(errorCode = "1", detail = local.exception.detail, message = local.exception.message, type = "any");
			} else {
				transaction action="commit";
			}
		}
	}

}
```

### Blank Migration (Using Template)
```cfc
component extends="wheels.migrator.Migration" hint="MigrateUserData" {

	function up() {
		transaction {
			try {
				// your code goes here
			} catch (any e) {
				local.exception = e;
			}

			if (StructKeyExists(local, "exception")) {
				transaction action="rollback";
				Throw(errorCode = "1", detail = local.exception.detail, message = local.exception.message, type = "any");
			} else {
				transaction action="commit";
			}
		}
	}

	function down() {
		transaction {
			try {
				// your code goes here
			} catch (any e) {
				local.exception = e;
			}

			if (StructKeyExists(local, "exception")) {
				transaction action="rollback";
				Throw(errorCode = "1", detail = local.exception.detail, message = local.exception.message, type = "any");
			} else {
				transaction action="commit";
			}
		}
	}

}
```

## Smart Name Detection

The command infers table names from migration name patterns:

### Pattern Detection Examples

| Migration Name | Detected Type | Inferred Table | Template Used |
|---------------|---------------|----------------|---------------|
| `CreateUsersTable` | create_table | users | create-table.txt |
| `DropProductsTable` | remove_table | products | remove-table.txt |
| `AddEmailToUsers` | create_column | users | create-column.txt |
| `RemoveAgeFromUsers` | remove_column | users | remove-column.txt |
| `RenameFirstnameToFullname` | rename_column | (needs --table) | rename-column.txt |
| `ChangeStatusInOrders` | change_column | orders | change-column.txt |
| `CreateIndexOnUsersEmail` | create_index | users | create-index.txt |
| `CustomDataMigration` | blank | N/A | blank.txt |

## Template System

All migrations use templates from `/cli/src/templates/dbmigrate/`:

### Available Templates
- `blank.txt` - Empty migration with transaction wrapper
- `create-table.txt` - Create table with timestamps
- `remove-table.txt` - Drop table with reversible down()
- `create-column.txt` - Add column with options
- `remove-column.txt` - Remove column
- `change-column.txt` - Modify column type/properties
- `rename-column.txt` - Rename column
- `create-index.txt` - Add index to table
- `remove-index.txt` - Remove index from table

### Template Customization
You can override default templates by placing custom versions in `/app/snippets/dbmigrate/`:

```bash
# Copy template to customize
cp cli/src/templates/dbmigrate/create-table.txt app/snippets/dbmigrate/create-table.txt

# Edit your custom template
# Wheels will automatically use your version
```

## Template Variables

Templates use placeholder variables that are replaced during generation:

| Variable | Description | Example |
|----------|-------------|---------|
| `\|DBMigrateDescription\|` | Migration hint/description | CreateUsersTable |
| `\|tableName\|` | Table name | users |
| `\|columnName\|` | Column name | email |
| `\|columnType\|` | Column type | string |
| `\|force\|` | Force table creation | false |
| `\|id\|` | Auto-create ID column | true |
| `\|primaryKey\|` | Primary key name | id |
| `\|allowNull\|` | Allow NULL values | true |
| `\|limit\|` | Column length limit | 255 |
| `\|default\|` | Default value | "" |
| `\|unique\|` | Unique index | false |

## Migration Workflow

### 1. Generate Migration
```bash
wheels generate migration name=CreateUsersTable
```

### 2. Edit Migration File
```bash
# File created at: /app/migrator/migrations/20250119123045_CreateUsersTable.cfc
```

Add columns to the migration:
```cfc
function up() {
    transaction {
        try {
            t = createTable(name = 'users', force='false', id='true', primaryKey='id');
            t.string(columnNames='firstName,lastName', allowNull=false);
            t.string(columnNames='email', allowNull=false, limit=100);
            t.boolean(columnNames='active', default=true);
            t.timestamps();
            t.create();

            // Add index on email
            addIndex(table='users', columnNames='email', unique=true);
        } catch (any e) {
            local.exception = e;
        }

        if (StructKeyExists(local, "exception")) {
            transaction action="rollback";
            Throw(errorCode = "1", detail = local.exception.detail, message = local.exception.message, type = "any");
        } else {
            transaction action="commit";
        }
    }
}
```

### 3. Check Migration Status
```bash
wheels dbmigrate info
```

### 4. Run Migration
```bash
wheels dbmigrate latest
```

### 5. Rollback if Needed
```bash
wheels dbmigrate down
```

## Column Types

Common column types available in migrations:

| Method | Database Type | Example |
|--------|---------------|---------|
| `t.string()` | VARCHAR(255) | `t.string(columnNames='email')` |
| `t.text()` | TEXT | `t.text(columnNames='bio')` |
| `t.integer()` | INTEGER | `t.integer(columnNames='age')` |
| `t.biginteger()` | BIGINT | `t.biginteger(columnNames='views')` |
| `t.decimal()` | DECIMAL | `t.decimal(columnNames='price', precision=10, scale=2)` |
| `t.float()` | FLOAT | `t.float(columnNames='rating')` |
| `t.boolean()` | BOOLEAN | `t.boolean(columnNames='active')` |
| `t.date()` | DATE | `t.date(columnNames='birthdate')` |
| `t.datetime()` | DATETIME | `t.datetime(columnNames='registeredAt')` |
| `t.time()` | TIME | `t.time(columnNames='startTime')` |
| `t.binary()` | BLOB | `t.binary(columnNames='avatar')` |
| `t.timestamps()` | DATETIME | Creates createdAt and updatedAt |

## Best Practices

1. **Descriptive Names**: Use clear, action-oriented migration names
2. **One Change Per Migration**: Keep migrations focused on single changes
3. **Always Include down()**: Make migrations reversible when possible
4. **Use Transactions**: Templates include transactions by default
5. **Test Rollbacks**: Always test `down()` method works correctly
6. **Index Performance Columns**: Add indexes on frequently queried columns
7. **Document Complex Migrations**: Use description parameter for clarity
8. **Avoid Data in Migrations**: Keep migrations schema-only when possible

## Common Patterns

### Create Table with Relationships
```cfc
function up() {
    transaction {
        try {
            t = createTable(name = 'posts', force='false', id='true');
            t.string(columnNames='title', allowNull=false);
            t.text(columnNames='content');
            t.references(name='userId', references='users');
            t.boolean(columnNames='published', default=false);
            t.timestamps();
            t.create();

            addIndex(table='posts', columnNames='userId');
        } catch (any e) {
            local.exception = e;
        }
        // Transaction handling...
    }
}
```

### Add Multiple Columns
```cfc
function up() {
    transaction {
        try {
            addColumn(table='users', columnType='string', columnName='phoneNumber', limit=20);
            addColumn(table='users', columnType='boolean', columnName='emailVerified', default=false);
            addColumn(table='users', columnType='datetime', columnName='lastLoginAt');

            addIndex(table='users', columnNames='phoneNumber');
        } catch (any e) {
            local.exception = e;
        }
        // Transaction handling...
    }
}
```

### Data Migration
```cfc
function up() {
    transaction {
        try {
            // Add new column
            addColumn(table='users', columnType='string', columnName='fullName');

            // Migrate data (use with caution)
            execute("UPDATE users SET fullName = CONCAT(firstName, ' ', lastName)");

            // Remove old columns
            removeColumn(table='users', columnName='firstName');
            removeColumn(table='users', columnName='lastName');
        } catch (any e) {
            local.exception = e;
        }
        // Transaction handling...
    }
}
```

## Error Handling

### Migration Already Exists
```bash
wheels generate migration name=CreateUsersTable
# Error: Migration file already exists. Use force=true to overwrite.

# Solution:
wheels generate migration name=CreateUsersTable --force=true
```

### Invalid Migration Name
```bash
wheels generate migration name="Create Users Table"
# Error: Invalid migration name. Use only letters, numbers, and underscores.

# Solution:
wheels generate migration name=CreateUsersTable
```

### Migration Fails to Run
```bash
wheels dbmigrate latest
# Error during migration execution

# Check the migration file for syntax errors
# Review database logs
# Test the down() method
wheels dbmigrate down
```

## Template Benefits

Using templates provides several advantages:

**Transaction Safety** - All operations wrapped in transactions
**Error Handling** - Automatic try/catch with rollback
**Consistency** - Same structure across all migrations
**Best Practices** - Templates follow Wheels conventions
**Customizable** - Override templates in /app/snippets/
**Maintainability** - Centralized template updates

## See Also

- [wheels dbmigrate latest](../database/dbmigrate-latest.md) - Run migrations
- [wheels dbmigrate info](../database/dbmigrate-info.md) - Check migration status
- [wheels dbmigrate create table](../database/dbmigrate-create-table.md) - Alternative table creation
- [wheels dbmigrate create blank](../database/dbmigrate-create-blank.md) - Alternative blank migration
- [wheels generate model](model.md) - Generate models
- [Database Migrations Guide](../../cli-guides/migrations.md) - Migration best practices
- [Template System Guide](../../cli-guides/template-system.md) - Customize templates
