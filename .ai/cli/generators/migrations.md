# Migration Generation

## Description
Generate database migration files for schema changes, table creation, and data transformations using Wheels CLI.

## Key Points
- Use `wheels g migration` to generate migration files
- Descriptive names become migration class names
- Automatic timestamp prefix for ordering
- Support for table, column, and data migrations
- Includes up() and down() methods for reversibility

## Code Sample
```bash
# Create new table migration
wheels g migration CreateUsersTable

# Add column migration
wheels g migration AddEmailToUsers --attributes="email:string:unique"

# Remove column migration
wheels g migration RemovePhoneFromUsers

# Create index migration
wheels g migration AddIndexToUsersEmail

# Generated migration: /app/migrator/migrations/20240125143022_create_users_table.cfc
component extends="wheels.migrator.Migration" {

    function up() {
        transaction {
            t = createTable(name="users", force=false);
            t.string(columnNames="firstName,lastName", null=false);
            t.string(columnNames="email", limit=100, null=false);
            t.boolean(columnNames="active", default=true);
            t.timestamps();
            t.create();

            addIndex(table="users", columnNames="email", unique=true);
        }
    }

    function down() {
        transaction {
            dropTable("users");
        }
    }
}

# Column addition migration
component extends="wheels.migrator.Migration" {

    function up() {
        transaction {
            addColumn(table="users", column="phoneNumber", type="string", limit=15);
            addIndex(table="users", columnNames="phoneNumber");
        }
    }

    function down() {
        transaction {
            removeIndex(table="users", columnNames="phoneNumber");
            dropColumn(table="users", columnNames="phoneNumber");
        }
    }
}
```

## Usage
1. Run `wheels g migration MigrationName`
2. Use descriptive names: `CreateUsersTable`, `AddEmailToUsers`
3. Use `--attributes` for column specifications
4. Edit generated file to add specific changes
5. Always implement both up() and down() methods

## Related
- [Creating Migrations](../../database/migrations/creating-migrations.md)
- [Column Types](../../database/migrations/column-types.md)
- [Running Migrations](../../database/migrations/running-migrations.md)

## Important Notes
- Migration names become CFC class names
- Always use transactions for data integrity
- Test both up and down migrations
- Use descriptive names for maintainability
- Down method must reverse up method exactly