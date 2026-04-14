# Database Seeding

Convention-based, idempotent seeding system with CLI and programmatic support.

## File Conventions

| File | Purpose | When it runs |
|------|---------|-------------|
| `app/db/seeds.cfm` | Shared seeds (all environments) | Always first |
| `app/db/seeds/development.cfm` | Dev-only seeds | After seeds.cfm, in development |
| `app/db/seeds/production.cfm` | Production seeds | After seeds.cfm, in production |

Execution is wrapped in a transaction. Shared seeds run first, then environment-specific seeds.

## seedOnce() — Idempotent Insert

`seedOnce()` checks for existing records via `uniqueProperties` before inserting. Re-running seeds is always safe.

```cfm
// app/db/seeds.cfm — Shared seeds
seedOnce(modelName="Role", uniqueProperties="name", properties={
    name: "admin", description: "Administrator"
});
seedOnce(modelName="Role", uniqueProperties="name", properties={
    name: "member", description: "Regular member"
});

// app/db/seeds/development.cfm — Dev-only seeds
seedOnce(modelName="User", uniqueProperties="email", properties={
    firstName: "Dev", lastName: "User", email: "dev@example.com"
});
```

**How it works**: calls `findOne()` with the `uniqueProperties` fields. If no match, creates the record. If a match exists, skips silently.

## CLI Commands

```bash
wheels db:seed                          # Run convention seeds (auto-detect)
wheels db:seed --environment=production # Seed for specific environment
wheels db:seed --generate               # Generate random test data (legacy)
wheels db:seed --generate --count=10    # Generate 10 records per model
wheels generate seed                    # Create app/db/seeds.cfm
wheels generate seed --all              # Create seeds.cfm + dev/prod stubs
```

## Programmatic Access

The seeder component is available at `application.wheels.seeder`:

```cfm
application.wheels.seeder.runSeeds();
```

## Migration Seed Data

For seed data inside migrations, use direct SQL (not `seedOnce()`):

```cfm
// Parameter binding is unreliable in migrations — use inline SQL
execute("INSERT INTO roles (name, createdAt, updatedAt) VALUES ('admin', NOW(), NOW())");
```

See `.ai/wheels/database/migrations/best-practices.md` for migration-specific guidance.
