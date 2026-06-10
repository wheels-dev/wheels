<cfsetting requestTimeOut="300">
<!---
    tests/populate.cfm — bootstraps the test database before specs run.

    `wheels test` runs against the `<appname>_test` datasource (a
    separate SQLite file from your dev DB) so chapter-6-style manual
    signups in development don't bleed into chapter-7 specs. The first
    time the test DB is empty (no migrator-versions table), the
    framework includes this file from app-runner.cfm to apply your
    migrations.

    Customise this file when you need test-specific seed data — model
    fixtures, baseline users, anything that should exist before EVERY
    test run. Keep it minimal; most specs should set up their own state
    via beforeEach/it blocks rather than relying on global fixtures.

    The framework only includes this file when:
    - the request was made with ?useTestDB=true (set automatically by
      `wheels test`; opt out with --no-test-db)
    - a `<dataSourceName>_test` datasource is registered (created
      automatically by `wheels new` when you accept the SQLite default)
    - the test DB has no migrator-versions table

    On second and subsequent runs the test DB schema persists, so this
    file is skipped. Delete `db/test.sqlite` to force a fresh schema.
--->
<cfscript>
    // Run all pending migrations against the active datasource —
    // app-runner.cfm has already swapped application.wheels.dataSourceName
    // to the <appname>_test datasource before this file is included.
    if (StructKeyExists(application.wheels, "migrator")) {
        // migrateToLatest() swallows per-migration exceptions into its return
        // string and stops migrating. A half-migrated test schema produces
        // baffling downstream errors (orphaned columns colliding with global
        // UDFs), so surface it loudly through app-runner's populate-500 path.
        local.migrateResult = application.wheels.migrator.migrateToLatest();
        if (FindNoCase("Error migrating", local.migrateResult ?: "")) {
            // Drop the versions table so the NEXT run re-enters populate and
            // fails loudly again (app-runner only includes populate.cfm when the
            // table is absent) — otherwise one failure leaves a silently
            // half-migrated schema. Fix the migration, then just re-run.
            try {
                QueryExecute(
                    "DROP TABLE IF EXISTS #application.wheels.migratorTableName#",
                    {},
                    {datasource: application.wheels.dataSourceName}
                );
            } catch (any dropErr) {}
            Throw(
                type = "PopulateCfm.MigrationFailed",
                message = "Test-db migration did not complete cleanly. Delete db/test.sqlite (or just re-run) after fixing the migration.",
                detail = local.migrateResult
            );
        }
    }

    // Add test-specific seed data below if you need it. For example:
    //
    //     application.wo.model("User").create(
    //         email = "fixture@example.com",
    //         password = "test1234"
    //     );
</cfscript>
