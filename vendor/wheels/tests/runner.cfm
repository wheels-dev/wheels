<cfsetting requestTimeOut="1800">
<cfscript>
    // Flag this request as a test harness run so framework internals
    // (e.g. flash cookie writes) can short-circuit operations that are
    // unsafe after the response buffer auto-commits mid-suite. Read by
    // wheels.controller.flash::$inTestHarness().
    request.$wheelsTestRun = true;

    // Pre-size the response buffer so the servlet response stays uncommitted
    // through the entire `testBox.run()` call. On Adobe CF 2023/2025 the
    // default 8KB output buffer auto-flushes once any spec writes that crosses
    // it (test runner debug output, partial spec writes from `processRequest`
    // controllers, etc.); once the response is committed, every subsequent
    // `cfheader` is a no-op — and any `statusCode = 404` an inner spec
    // happened to set via `$throwErrorOrShow404Page` becomes the response's
    // final HTTP code. The compat-matrix CI parser only accepts 200/417, so
    // the 404 leak fails the run even when the JSON test body reports
    // `totalPass = 3681`. Expanding the buffer to 16 MB keeps the response
    // uncommitted long enough for `runner.cfm`'s end-of-suite
    // `$header(statusCode = 200|417)` to land. Best-effort: engines that
    // don't expose `setBufferSize` or reject the value fall through silently
    // and rely on the defensive helpers downstream.
    try {
        getPageContext().getResponse().setBufferSize(16 * 1024 * 1024);
    } catch (any e) {
        // Engine doesn't support the call or rejected the size — skip and
        // let the defensive `$header()` / `$content()` short-circuits handle
        // whatever committed-response state the request ends up in.
    }

    // Define helper functions as variables-scoped closures to avoid Adobe CF's
    // DuplicateFunctionDefinitionException (this file can be included from multiple
    // CFC methods via different include paths)
    variables.$_duplicateWheelsEnv = function(required struct original) {
        var backup = {}
        for (var key in arguments.original) {
            if (IsSimpleValue(arguments.original[key]) || IsArray(arguments.original[key]) || IsStruct(arguments.original[key])) {
                backup[key] = arguments.original[key]
            }
        }
        return backup
    }

    variables.$_setTestboxEnv = function() {
        // creating backup for original environment
        if (structKeyExists(server, "boxlang")) {
            application.$$$wheels = variables.$_duplicateWheelsEnv(application.wheels)
        } else {
            application.$$$wheels = Duplicate(application.wheels)
        }

        // load testbox routes
        application.wo.$include(template = "/wheels/tests/routes.cfm")
        application.wo.$setNamedRoutePositions()

        var AssetPath = "/wheels/tests/_assets/"

        application.wo.set(rewriteFile = "index.cfm")
        application.wo.set(controllerPath = AssetPath & "controllers")
        application.wo.set(viewPath = AssetPath & "views")
        application.wo.set(modelPath = AssetPath & "models")
        application.wo.set(wheelsComponentPath = "/wheels")

        /* set migration level for tests*/
        application.wheels.migrationLevel = 2;

        /* turn off default validations for testing */
        application.wheels.automaticValidations = false
        application.wheels.assetQueryString = false
        application.wheels.assetPaths = false

        /* redirections should always delay when testing */
        application.wheels.functions.redirectTo.delay = true

        /* turn off transactions by default */
        application.wheels.transactionMode = "none"

        /* turn off request query caching */
        application.wheels.cacheQueriesDuringRequest = false

        // CSRF
        application.wheels.csrfCookieName = "_wheels_test_authenticity"
        application.wheels.csrfCookieEncryptionAlgorithm = "AES"
        application.wheels.csrfCookieEncryptionSecretKey = GenerateSecretKey("AES")
        application.wheels.csrfCookieEncryptionEncoding = "Base64"

        // Setup CSRF token and cookie. The cookie can always be in place, even when the session-based CSRF storage is being
        // tested.
        var dummyController = application.wo.controller("dummy")
        var csrfToken = dummyController.$generateCookieAuthenticityToken()

        cookie[application.wheels.csrfCookieName] = Encrypt(
            SerializeJSON({authenticityToken = csrfToken}),
            application.wheels.csrfCookieEncryptionSecretKey,
            application.wheels.csrfCookieEncryptionAlgorithm,
            application.wheels.csrfCookieEncryptionEncoding
        )
        if (structKeyExists(url, "db") && listFind("mysql,sqlserver,sqlserver_cicd,postgres,h2,oracle,sqlite,cockroachdb", url.db)) {
            if (listFind("sqlserver,sqlserver_cicd", url.db)) {
                application.wheels.dataSourceName = "wheelstestdb_sqlserver";
            } else {
                application.wheels.dataSourceName = "wheelstestdb_" & url.db;
            }
        } else if (application.wheels.coreTestDataSourceName eq "|datasourceName|") {
            application.wheels.dataSourceName = "wheelstestdb";
        } else {
            application.wheels.dataSourceName = application.wheels.coreTestDataSourceName;
        }

        // Clear model cache when switching datasources so models are
        // re-initialized with the correct adapter for the target database.
        // Without this, models cached from a prior datasource (e.g. H2 from
        // the warm-up request) retain the wrong adapter when testing against
        // a different database like CockroachDB.
        StructClear(application.wheels.models);

        application.testenv.db = application.wo.$dbinfo(datasource = application.wheels.dataSourceName, type = "version")

        // Setting up test database for test environment
        var tables = application.wo.$dbinfo(datasource = application.wheels.dataSourceName, type = "tables")
        var tableList = ValueList(tables.table_name)
        var populate = StructKeyExists(url, "populate") ? url.populate : true
        if (populate || !FindNoCase("c_o_r_e_authors", tableList)) {
            include "/wheels/tests/populate.cfm"
        }
    }

    // Resolve the TestBox scope from url.directory with a conservative allowlist.
    // Permitted roots (plus any dotted sub-path of them):
    //   wheels.tests.*            — core framework specs
    //   vendor.<package>.tests.*  — first-party / installed package specs
    // The /wheels/core/tests endpoint is unauthenticated and only safe in dev;
    // the allowlist is defense-in-depth so stray input can't drive arbitrary
    // CFC compilation through whatever mappings happen to be registered.
    local.testDirectory = "wheels.tests.specs";
    if (StructKeyExists(url, "directory") && Len(Trim(url.directory))) {
        local.requestedDirectory = Trim(url.directory);
        if (ReFindNoCase(
            "^(wheels\.tests|vendor\.[a-z0-9][a-z0-9\-]*\.tests)(\.[a-zA-Z0-9_]+)*$",
            local.requestedDirectory
        )) {
            local.testDirectory = local.requestedDirectory;
        }
    }

    try {
        // Try to create TestBox instance with coverage disabled
        testBox = new wheels.wheelstest.system.TestBox(
            directory=local.testDirectory,
            options={ coverage = { enabled = false } }
        );
    } catch (any e) {
        // Best-effort response setup — `application.wo.$header()` / `$content()`
        // short-circuit if the response is already committed (Adobe CF + Undertow)
        // so a downstream cfheader/cfcontent rejection doesn't mask the actual
        // TestBox-creation failure we're trying to report.
        application.wo.$header(statuscode="500");
        application.wo.$content(type="application/json");
        writeOutput('{"success":false,"error":"Failed to create TestBox instance: ' & replace(e.message, '"', '\"', "all") & '"}');
        abort;
    }

    //Sorting the bundles Alphabetically
    local.sortedArray = testBox.getBundles()
    arraySort(local.sortedArray, "textNoCase")
    testBox.setBundles(local.sortedArray)

    variables.$_setTestboxEnv()
    if (!structKeyExists(url, "format") || url.format eq "html") {
        result = testBox.run(
            reporter = "wheels.wheelstest.system.reports.JSONReporter"
        );
        DeJsonResult = DeserializeJSON(result);

        if (DeJsonResult.totalFail > 0 || DeJsonResult.totalError > 0) {
            application.wo.$header(statuscode=417);
        } else {
            application.wo.$header(statuscode=200);
        }
    }
    else if(url.format eq "json"){
        result = testBox.run(
            reporter = "wheels.wheelstest.system.reports.JSONReporter"
        );
        // `$header()` / `$content()` short-circuit when the servlet response is
        // already committed (Adobe CF 2023/2025 commits mid-`testBox.run()` once
        // any test output flushes the buffer). The status-code header is the
        // signal the CI parser keys on, so best-effort is the right contract —
        // a committed response keeps whatever statuscode the engine already
        // wrote, and the JSON body still appends below.
        application.wo.$content(type="application/json");
        application.wo.$header(name="Access-Control-Allow-Origin", value="*");
        DeJsonResult = DeserializeJSON(result);
        if (DeJsonResult.totalFail > 0 || DeJsonResult.totalError > 0) {
            if(!structKeyExists(url, "cli") || !url.cli){
                application.wo.$header(statuscode=417);
            }
        } else {
            application.wo.$header(statuscode=200);
        }
        // Check if 'only' parameter is provided in the URL
        if (structKeyExists(url, "only") && url.only eq "failure,error") {
            allBundles = DeJsonResult.bundleStats;
            if(DeJsonResult.totalFail > 0 || DeJsonResult.totalError > 0){

                // Filter test results
                filteredBundles = [];

                for (bundle in DeJsonResult.bundleStats) {
                    if (bundle.totalError > 0 || bundle.totalFail > 0) {
                        filteredSuites = [];

                        for (suite in bundle.suiteStats) {
                            if (suite.totalError > 0 || suite.totalFail > 0) {
                                filteredSpecs = [];

                                for (spec in suite.specStats) {
                                    if (spec.status eq "Error" || spec.status eq "Failed") {
                                        arrayAppend(filteredSpecs, spec);
                                    }
                                }

                                if (arrayLen(filteredSpecs) > 0) {
                                    suite.specStats = filteredSpecs;
                                    arrayAppend(filteredSuites, suite);
                                }
                            }
                        }

                        if (arrayLen(filteredSuites) > 0) {
                            bundle.suiteStats = filteredSuites;
                            arrayAppend(filteredBundles, bundle);
                        }
                    }
                }

                DeJsonResult.bundleStats = filteredBundles;
                // Update the result with filtered data

                // Build lookup of filtered bundles by name for safe access
                filteredBundleMap = {};
                for (fb in filteredBundles) {
                    filteredBundleMap[fb.name] = fb;
                }

                for(bundle in allBundles){
                    writeOutput("Bundle: #bundle.name##Chr(13)##Chr(10)#")
                    writeOutput("CFML Engine: #DeJsonResult.CFMLEngine# #DeJsonResult.CFMLEngineVersion##Chr(13)##Chr(10)#")
                    writeOutput("Duration: #bundle.totalDuration#ms#Chr(13)##Chr(10)#")
                    writeOutput("Labels: #ArrayToList(DeJsonResult.labels, ', ')##Chr(13)##Chr(10)#")
                    writeOutput("╔═══════════════════════════════════════════════════════════╗#Chr(13)##Chr(10)#║ Suites  ║ Specs   ║ Passed  ║ Failed  ║ Errored ║ Skipped ║#Chr(13)##Chr(10)#╠═══════════════════════════════════════════════════════════╣#Chr(13)##Chr(10)#║ #NumberFormat(bundle.totalSuites,'999')#     ║ #NumberFormat(bundle.totalSpecs,'999')#     ║ #NumberFormat(bundle.totalPass,'999')#     ║ #NumberFormat(bundle.totalFail,'999')#     ║ #NumberFormat(bundle.totalError,'999')#     ║ #NumberFormat(bundle.totalSkipped,'999')#     ║#Chr(13)##Chr(10)#╚═══════════════════════════════════════════════════════════╝#Chr(13)##Chr(10)##Chr(13)##Chr(10)#")
                    if(bundle.totalFail > 0 || bundle.totalError > 0){
                        if (structKeyExists(filteredBundleMap, bundle.name)) {
                            for(suite in filteredBundleMap[bundle.name].suiteStats){
                                writeOutput("Suite with Error or Failure: #suite.name##Chr(13)##Chr(10)##Chr(13)##Chr(10)#")
                                for(spec in suite.specStats){
                                    writeOutput("       Spec Name: #spec.name##Chr(13)##Chr(10)#")
                                    writeOutput("       Error Message: #spec.failMessage##Chr(13)##Chr(10)#")
                                    writeOutput("       Error Detail: #spec.failDetail##Chr(13)##Chr(10)##Chr(13)##Chr(10)##Chr(13)##Chr(10)#")
                                }
                            }
                        }
                    }
                    writeOutput("#Chr(13)##Chr(10)##Chr(13)##Chr(10)##Chr(13)##Chr(10)#")
                }

            }else{
                for(bundle in DeJsonResult.bundleStats){
                    writeOutput("Bundle: #bundle.name##Chr(13)##Chr(10)#")
                    writeOutput("CFML Engine: #DeJsonResult.CFMLEngine# #DeJsonResult.CFMLEngineVersion##Chr(13)##Chr(10)#")
                    writeOutput("Duration: #bundle.totalDuration#ms#Chr(13)##Chr(10)#")
                    writeOutput("Labels: #ArrayToList(DeJsonResult.labels, ', ')##Chr(13)##Chr(10)#")
                    writeOutput("╔═══════════════════════════════════════════════════════════╗#Chr(13)##Chr(10)#║ Suites  ║ Specs   ║ Passed  ║ Failed  ║ Errored ║ Skipped ║#Chr(13)##Chr(10)#╠═══════════════════════════════════════════════════════════╣#Chr(13)##Chr(10)#║ #NumberFormat(bundle.totalSuites,'999')#     ║ #NumberFormat(bundle.totalSpecs,'999')#     ║ #NumberFormat(bundle.totalPass,'999')#     ║ #NumberFormat(bundle.totalFail,'999')#     ║ #NumberFormat(bundle.totalError,'999')#     ║ #NumberFormat(bundle.totalSkipped,'999')#     ║#Chr(13)##Chr(10)#╚═══════════════════════════════════════════════════════════╝#Chr(13)##Chr(10)##Chr(13)##Chr(10)##Chr(13)##Chr(10)#")
                }
            }
        }else{
            writeOutput(result)
        }
    }
    else if (url.format eq "txt") {
        result = testBox.run(
            reporter = "wheels.wheelstest.system.reports.TextReporter"
        )
        application.wo.$content(type="text/plain");
        writeOutput(result)
    }
    else if(url.format eq "junit"){
        result = testBox.run(
            reporter = "wheels.wheelstest.system.reports.ANTJUnitReporter"
        )
        application.wo.$content(type="text/xml");
        writeOutput(result)
    }
    // reset the original environment
    application.wheels = application.$$$wheels
    structDelete(application, "$$$wheels")
    if(!structKeyExists(url, "format") || url.format eq "html"){
        // Use our html template
        type = "Core";
        include "html.cfm";
    }
</cfscript>
