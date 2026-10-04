<cfsetting requestTimeOut="300">
<!---
    tests/populate.cfm — bootstraps the test database before specs run.

    The framework's app-test runner (included by tests/runner.cfm) runs the
    specs on the `starterApp_test` datasource (H2, defined in config/app.cfm)
    and includes this file first to apply your pending migrations there
    (migrateToLatest() is a no-op when already current). It isn't included
    for a run on the primary datasource (useTestDB=false).

    Add test-specific seed data below if every run needs it. It runs before
    every test run, so it must be idempotent; most specs should set up their
    own state in beforeEach/it blocks instead.

    To start from a fresh test schema, stop the server and delete
    db/h2/starterApp_test.*.
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
            // Drop the versions table so the NEXT run re-attempts the failing
            // migration and fails loudly again — otherwise one failure leaves a
            // silently half-migrated schema. Fix the migration, then just re-run.
            // Note: `DROP TABLE IF EXISTS` is unsupported on Oracle < 23c, so
            // the self-healing re-entry loop only latches for one run there;
            // the loud-failure Throw below still fires on the first failure.
            try {
                QueryExecute(
                    "DROP TABLE IF EXISTS #application.wheels.migratorTableName#",
                    {},
                    {datasource: application.wheels.dataSourceName}
                );
            } catch (any dropErr) {}
            Throw(
                type = "PopulateCfm.MigrationFailed",
                message = "Test-db migration did not complete cleanly. Fix the failing migration and re-run (or delete db/h2/starterApp_test.* with the server stopped).",
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
