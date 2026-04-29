<cfsetting requestTimeOut="1800">
<cfscript>
    // Built-in app-test runner. Used as a fallback by Public.cfc::testbox()
    // when the project doesn't have its own tests/runner.cfm. Scans the
    // project's tests/specs/ via TestBox and emits the same JSON shape as
    // the framework's core runner so the CLI's displayTestResults() can
    // parse it without a special case.
    //
    // The framework's runner (vendor/wheels/tests/runner.cfm) is heavy: it
    // overrides controllerPath/viewPath/modelPath to framework test assets,
    // hardcodes the wheelstestdb_<db> datasource convention, and applies
    // dozens of test-only settings. None of that fits user apps — user
    // tests should run against the same models/controllers/views that
    // power the live application, with the user's own datasource. So this
    // file deliberately does NOT include /wheels/tests/runner.cfm.

    // Resolve the test directory. Default to tests.specs (the convention
    // every Wheels app has), but allow ?directory= to scope to a subdir
    // like tests.specs.models. Only accept dotted paths beginning with
    // "tests." to avoid arbitrary CFC compilation.
    local.testDirectory = "tests.specs";
    if (StructKeyExists(url, "directory") && Len(Trim(url.directory))) {
        local.requested = Trim(url.directory);
        if (ReFindNoCase("^tests(\.[a-zA-Z0-9_]+)*$", local.requested)) {
            local.testDirectory = local.requested;
        }
    }

    // Resolve the target datasource. When url.useTestDB=true and a
    // <dataSourceName>_test datasource is registered, swap to it for
    // the duration of this run. Mirrors Rails' RAILS_ENV=test convention
    // without requiring users to manage two databases by hand. The CLI
    // passes useTestDB=true by default for `wheels test`; users opt out
    // via --no-test-db. See finding #10 in
    // docs/superpowers/plans/2026-04-29-fresh-vm-onboarding-findings.md.
    local.originalDataSource = application.wheels.dataSourceName;
    local.targetDataSource = local.originalDataSource;
    local.swappedDataSource = false;
    if (StructKeyExists(url, "useTestDB") && url.useTestDB) {
        local.candidate = local.originalDataSource & "_test";
        local.registered = GetApplicationMetaData().datasources;
        if (StructKeyExists(local.registered, local.candidate)) {
            local.targetDataSource = local.candidate;
            application.wheels.dataSourceName = local.candidate;
            local.swappedDataSource = true;
        }
    }

    try {
        // If the test database has no migrator-versions table, include
        // the user's tests/populate.cfm to bootstrap schema. Skip
        // silently when the file doesn't exist (advanced users with
        // their own setup).
        local.populatePath = ExpandPath("/tests/populate.cfm");
        if (local.swappedDataSource && FileExists(local.populatePath)) {
            try {
                local.dbinfo = application.wo.$dbinfo(
                    datasource = local.targetDataSource,
                    type = "tables"
                );
                local.tableList = ValueList(local.dbinfo.table_name);
                if (!FindNoCase(application.wheels.migratorTableName, local.tableList)) {
                    include "/tests/populate.cfm";
                }
            } catch (any populateErr) {
                // Surface populate.cfm errors as JSON; don't silently
                // run specs against an empty test DB.
                cfheader(statuscode = 500);
                cfcontent(type = "application/json");
                writeOutput(SerializeJSON({
                    success: false,
                    error: "tests/populate.cfm failed",
                    message: populateErr.message,
                    detail: populateErr.detail
                }));
                abort;
            }
        }

        try {
            testBox = new wheels.wheelstest.system.TestBox(
                directory = local.testDirectory,
                options   = { coverage = { enabled = false } }
            );
        } catch (any e) {
            cfheader(statuscode="500");
            cfcontent(type="application/json");
            writeOutput(SerializeJSON({
                success: false,
                error: "Failed to create TestBox instance",
                message: e.message
            }));
            abort;
        }

        // Sort bundles for stable output
        local.sortedBundles = testBox.getBundles();
        arraySort(local.sortedBundles, "textNoCase");
        testBox.setBundles(local.sortedBundles);

        if (!StructKeyExists(url, "format") || url.format == "html") {
            result = testBox.run(reporter = "wheels.wheelstest.system.reports.JSONReporter");
            decoded = DeserializeJSON(result);
            cfheader(statuscode = (decoded.totalFail > 0 || decoded.totalError > 0) ? 417 : 200);
            // For the html case the framework runner falls through to html.cfm;
            // for the app-runner we just emit the JSON in this branch too since
            // app tests are typically requested over JSON (CLI/CI). Users hitting
            // the URL in a browser still get a structured response they can read.
            cfcontent(type="application/json");
            writeOutput(result);
        } else if (url.format == "json") {
            result = testBox.run(reporter = "wheels.wheelstest.system.reports.JSONReporter");
            decoded = DeserializeJSON(result);
            if (decoded.totalFail > 0 || decoded.totalError > 0) {
                if (!StructKeyExists(url, "cli") || !url.cli) {
                    cfheader(statuscode = 417);
                }
            } else {
                cfheader(statuscode = 200);
            }
            cfcontent(type="application/json");
            cfheader(name="Access-Control-Allow-Origin", value="*");
            writeOutput(result);
        } else if (url.format == "txt") {
            result = testBox.run(reporter = "wheels.wheelstest.system.reports.TextReporter");
            cfcontent(type = "text/plain");
            writeOutput(result);
        } else if (url.format == "junit") {
            result = testBox.run(reporter = "wheels.wheelstest.system.reports.ANTJUnitReporter");
            cfcontent(type = "text/xml");
            writeOutput(result);
        }
    } finally {
        // Restore the original datasource so subsequent requests see the
        // dev DB again. Runs even if a spec throws or `abort` fires.
        if (local.swappedDataSource) {
            application.wheels.dataSourceName = local.originalDataSource;
        }
    }
</cfscript>
