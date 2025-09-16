# Creating Migrations

## Description
Database migrations are version-controlled scripts that modify database schema systematically and reversibly.

## Key Points
- Generated via CLI commands in `/app/migrator/migrations/`
- Named with timestamp prefix: `[YYYYMMDDHHmmss]_description.cfc`
- Must extend `wheels.migrator.Migration`
- Every migration has `up()` and `down()` methods
- Always wrap operations in transactions

## Code Sample
```cfm
// Generate migration
wheels dbmigrate create table create_users_table

// Generated file: 20240125143022_create_users_table.cfc
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
```

## Usage
1. Use CLI: `wheels dbmigrate create [type] [name]`
2. Types: `blank`, `table`, `column`
3. Edit generated file to add schema changes
4. Implement both `up()` and `down()` methods
5. Run with `wheels dbmigrate latest`

## Related
- [Column Types](./column-types.md)
- [Running Migrations](./running-migrations.md)
- [Rollback](./rollback.md)

## Important Notes
- One logical change per migration
- Never modify completed migrations
- Test both up and down operations
- Always use transactions for atomicity