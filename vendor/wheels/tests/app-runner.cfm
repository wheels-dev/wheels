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
</cfscript>
