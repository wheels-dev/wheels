# Migration Rollback

## Description
Reverse database migrations using the `down()` method to undo schema changes systematically.

## Key Points
- `wheels dbmigrate down` rolls back last migration
- `wheels dbmigrate reset` rolls back all migrations
- `down()` method must reverse `up()` exactly
- Use transactions to ensure atomicity
- Production rollbacks should be restricted

## Code Sample
```cfm
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

// Commands
wheels dbmigrate down     // Rollback last migration
wheels dbmigrate reset    // Rollback ALL migrations (caution!)
```

## Usage
1. Ensure `down()` method reverses `up()` operations
2. Test rollback in development: up → down → up
3. Use `down` for single migration rollback
4. Use `reset` only in development (destroys all data)
5. Disable in production with `allowMigrationDown=false`

## Related
- [Creating Migrations](./creating-migrations.md)
- [Running Migrations](./running-migrations.md)
- [Production Configuration](../../configuration/environments.md)

## Important Notes
- Down must exactly reverse up operations
- Order matters: reverse the sequence of up operations
- Always test rollback before deploying
- Production rollbacks risk data loss
- Some operations cannot be reversed (data deletion)