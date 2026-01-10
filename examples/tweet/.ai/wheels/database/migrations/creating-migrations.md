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
            t.string(columnNames="firstName,lastName", allowNull=false);
            t.string(columnNames="email", limit=100, allowNull=false);
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

## Data Seeding in Migrations
Migrations can also be used for data seeding, especially for initial application data:

```cfm
function up() {
    transaction {
        // Create table first
        t = createTable(name="posts", force=false);
        t.string(columnNames="title", limit=255, allowNull=false);
        t.text(columnNames="body", allowNull=false);
        t.timestamps();
        t.create();

        // Seed initial data - use direct SQL for reliability
        execute("INSERT INTO posts (title, body, createdAt, updatedAt)
                 VALUES ('Sample Post', 'This is sample content.', NOW(), NOW())");
    }
}
```

**Note:** For complex data seeding, use direct SQL statements with `execute()` rather than parameter binding, which can be unreliable in migration context.

## Important Notes
- One logical change per migration
- Never modify completed migrations
- Test both up and down operations
- Always use transactions for atomicity
- For data seeding, prefer direct SQL over complex parameter binding
- Can combine schema creation and data seeding in single migration