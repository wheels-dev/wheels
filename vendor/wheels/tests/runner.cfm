<cfsetting requestTimeOut="1800">
<cfscript>
    // Parameter defaults for filtering and caching
    param name="url.format" default="html";
    param name="url.testBundles" default="";
    param name="url.testSuites" default="";
    param name="url.testSpecs" default="";
    param name="url.labels" default="";
    param name="url.excludes" default="";
    param name="url.cli" default="false" type="boolean";
    param name="url.clearCache" default="false" type="boolean";

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

    // Build a flat array of failed/errored specs from deserialized JSON results
    variables.$_buildFailureSummary = function(required struct data) {
        var failures = [];
        for (var bundle in arguments.data.bundleStats) {
            if (bundle.totalFail == 0 && bundle.totalError == 0) continue;

            var suiteStack = [];
            for (var s in bundle.suiteStats) {
                ArrayAppend(suiteStack, s);
            }

            while (ArrayLen(suiteStack) > 0) {
                var suite = suiteStack[1];
                ArrayDeleteAt(suiteStack, 1);

                if (StructKeyExists(suite, "suiteStats") && ArrayLen(suite.suiteStats) > 0) {
                    for (var nested in suite.suiteStats) {
                        ArrayAppend(suiteStack, nested);
                    }
                }

                for (var spec in suite.specStats) {
                    if (spec.status eq "Failed" || spec.status eq "Error") {
                        var errMsg = "";
                        if (spec.status eq "Failed") {
                            errMsg = spec.failMessage;
                        } else if (IsStruct(spec.error) && StructKeyExists(spec.error, "message")) {
                            errMsg = spec.error.message;
                        }
                        ArrayAppend(failures, {
                            bundle = bundle.name,
                            suite = suite.name,
                            spec = spec.name,
                            status = spec.status,
                            message = errMsg,
                            duration = spec.totalDuration
                        });
                    }
                }
            }
        }
        return failures;
    }

    // Convert deserialized JSON test results to JUnit XML format
    variables.$_buildJunitXml = function(required struct data) {
        var NL = Chr(10);
        var xml = '<?xml version="1.0" encoding="UTF-8"?>' & NL;
        xml &= '<testsuites name="Wheels Core Tests"'
            & ' tests="' & arguments.data.totalSpecs & '"'
            & ' failures="' & arguments.data.totalFail & '"'
            & ' errors="' & arguments.data.totalError & '"'
            & ' skipped="' & arguments.data.totalSkipped & '">' & NL;

        for (var bundle in arguments.data.bundleStats) {
            xml &= '<testsuite name="' & XmlFormat(bundle.name) & '"'
                & ' tests="' & bundle.totalSpecs & '"'
                & ' failures="' & bundle.totalFail & '"'
                & ' errors="' & bundle.totalError & '"'
                & ' skipped="' & bundle.totalSkipped & '"'
                & ' time="' & NumberFormat(bundle.totalDuration / 1000, "0.000") & '">' & NL;

            // Walk suites iteratively (supports nested suites)
            var suiteStack = [];
            for (var s in bundle.suiteStats) {
                ArrayAppend(suiteStack, s);
            }

            while (ArrayLen(suiteStack) > 0) {
                var suite = suiteStack[1];
                ArrayDeleteAt(suiteStack, 1);

                if (StructKeyExists(suite, "suiteStats") && ArrayLen(suite.suiteStats) > 0) {
                    for (var nested in suite.suiteStats) {
                        ArrayAppend(suiteStack, nested);
                    }
                }

                for (var spec in suite.specStats) {
                    xml &= '  <testcase classname="' & XmlFormat(bundle.name & "." & suite.name) & '"'
                        & ' name="' & XmlFormat(spec.name) & '"'
                        & ' time="' & NumberFormat(spec.totalDuration / 1000, "0.000") & '">';

                    if (spec.status eq "Failed") {
                        xml &= NL & '    <failure message="' & XmlFormat(spec.failMessage) & '">'
                            & XmlFormat(spec.failDetail) & '</failure>';
                    } else if (spec.status eq "Error") {
                        var errMsg = "";
                        if (IsStruct(spec.error) && StructKeyExists(spec.error, "message")) {
                            errMsg = spec.error.message;
                        }
                        xml &= NL & '    <error message="' & XmlFormat(errMsg) & '"></error>';
                    } else if (spec.status eq "Skipped") {
                        xml &= NL & '    <skipped/>';
                    }

                    xml &= '</testcase>' & NL;
                }
            }

            xml &= '</testsuite>' & NL;
        }

        xml &= '</testsuites>';
        return xml;
    }

    // Build plain text report from deserialized JSON results
    variables.$_buildTextReport = function(required struct data, numeric durationMs = 0, boolean fromCache = false) {
        var NL = Chr(10);
        var txt = "Wheels Core Test Results" & NL;
        txt &= "========================" & NL;
        txt &= "Engine: " & arguments.data.CFMLEngine & " " & arguments.data.CFMLEngineVersion & NL;
        if (arguments.durationMs > 0) {
            txt &= "Duration: " & NumberFormat(arguments.durationMs) & "ms";
            if (arguments.fromCache) txt &= " (from cache)";
            txt &= NL;
        }
        txt &= "Total: " & arguments.data.totalSpecs
            & " | Pass: " & arguments.data.totalPass
            & " | Fail: " & arguments.data.totalFail
            & " | Error: " & arguments.data.totalError
            & " | Skipped: " & arguments.data.totalSkipped & NL;
        txt &= NL;

        if (arguments.data.totalFail > 0 || arguments.data.totalError > 0) {
            txt &= "--- FAILURES & ERRORS ---" & NL;
            var failedSpecs = variables.$_buildFailureSummary(arguments.data);
            for (var f in failedSpecs) {
                txt &= "[" & UCase(f.status) & "] " & f.bundle & " > " & f.suite & " > " & f.spec & NL;
                if (len(f.message)) {
                    txt &= "  " & f.message & NL;
                }
                txt &= NL;
            }
            txt &= "---" & NL;
            txt &= ArrayLen(failedSpecs) & " issue(s) found" & NL;
        } else {
            txt &= "All specs passed." & NL;
        }

        return txt;
    }

    // --- TestBox Initialization ---
    try {
        testBox = new wheels.wheelstest.system.TestBox(
            directory="wheels.tests.specs",
            options={ coverage = { enabled = false } }
        );
    } catch (any e) {
        cfheader(statuscode="500");
        cfcontent(type="application/json");
        writeOutput('{"success":false,"error":"Failed to create TestBox instance: ' & replace(e.message, '"', '\"', "all") & '"}');
        abort;
    }

    // Sorting the bundles Alphabetically
    local.sortedArray = testBox.getBundles()
    arraySort(local.sortedArray, "textNoCase")
    testBox.setBundles(local.sortedArray)

    // --- Cache Lookup ---
    cacheKeyInput = "core:"
        & (structKeyExists(url, "db") ? url.db : "default")
        & ":" & url.testBundles
        & ":" & url.testSuites
        & ":" & url.testSpecs
        & ":" & url.labels
        & ":" & url.excludes;
    cacheKey = Hash(cacheKeyInput);

    // Check for cached results (5-minute TTL)
    fromCache = false;
    runDuration = 0;

    if (!url.clearCache
        && StructKeyExists(server, "_wheelsTestCache")
        && StructKeyExists(server._wheelsTestCache, cacheKey)
        && DateDiff("n", server._wheelsTestCache[cacheKey].timestamp, Now()) < 5) {
        result = server._wheelsTestCache[cacheKey].jsonResult;
        runDuration = server._wheelsTestCache[cacheKey].durationMs;
        fromCache = true;
    }

    // --- Run Tests (cache miss) ---
    if (!fromCache) {
        testRunOptions = {
            reporter = "wheels.wheelstest.system.reports.JSONReporter"
        };
        if (len(url.testBundles)) testRunOptions.testBundles = url.testBundles;
        if (len(url.testSuites)) testRunOptions.testSuites = url.testSuites;
        if (len(url.testSpecs)) testRunOptions.testSpecs = url.testSpecs;
        if (len(url.labels)) testRunOptions.labels = url.labels;
        if (len(url.excludes)) testRunOptions.excludes = url.excludes;

        variables.$_setTestboxEnv();
        runStart = GetTickCount();
        result = testBox.run(argumentCollection = testRunOptions);
        runDuration = GetTickCount() - runStart;

        // Cache the result
        if (!StructKeyExists(server, "_wheelsTestCache")) server._wheelsTestCache = {};
        server._wheelsTestCache[cacheKey] = {
            jsonResult = result,
            timestamp = Now(),
            durationMs = runDuration
        };
    }

    // --- Format Output ---
    if (!structKeyExists(url, "format") || url.format eq "html") {
        // HTML uses the JSON result internally; html.cfm handles rendering
    }
    else if (url.format eq "json") {
        cfcontent(type="application/json");
        cfheader(name="Access-Control-Allow-Origin", value="*");
        DeJsonResult = DeserializeJSON(result);

        // Enhanced metadata
        DeJsonResult["testDurationMs"] = runDuration;
        DeJsonResult["fromCache"] = fromCache;

        // Flat failure summary for easy parsing by CI tools
        if (DeJsonResult.totalFail > 0 || DeJsonResult.totalError > 0) {
            DeJsonResult["failedSpecs"] = variables.$_buildFailureSummary(DeJsonResult);
            if (!url.cli) {
                cfheader(statuscode=417);
            }
        } else {
            cfheader(statuscode=200);
        }

        // Handle "only" parameter for filtered output (backward compatible)
        if (structKeyExists(url, "only") && url.only eq "failure,error") {
            allBundles = DeJsonResult.bundleStats;
            if (DeJsonResult.totalFail > 0 || DeJsonResult.totalError > 0) {

                // Filter test results to only failed/errored specs
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

                // Build lookup of filtered bundles by name for safe access
                filteredBundleMap = {};
                for (fb in filteredBundles) {
                    filteredBundleMap[fb.name] = fb;
                }

                for (bundle in allBundles) {
                    writeOutput("Bundle: #bundle.name##Chr(13)##Chr(10)#")
                    writeOutput("CFML Engine: #DeJsonResult.CFMLEngine# #DeJsonResult.CFMLEngineVersion##Chr(13)##Chr(10)#")
                    writeOutput("Duration: #bundle.totalDuration#ms#Chr(13)##Chr(10)#")
                    writeOutput("Labels: #ArrayToList(DeJsonResult.labels, ', ')##Chr(13)##Chr(10)#")
                    writeOutput("╔═══════════════════════════════════════════════════════════╗#Chr(13)##Chr(10)#║ Suites  ║ Specs   ║ Passed  ║ Failed  ║ Errored ║ Skipped ║#Chr(13)##Chr(10)#╠═══════════════════════════════════════════════════════════╣#Chr(13)##Chr(10)#║ #NumberFormat(bundle.totalSuites,'999')#     ║ #NumberFormat(bundle.totalSpecs,'999')#     ║ #NumberFormat(bundle.totalPass,'999')#     ║ #NumberFormat(bundle.totalFail,'999')#     ║ #NumberFormat(bundle.totalError,'999')#     ║ #NumberFormat(bundle.totalSkipped,'999')#     ║#Chr(13)##Chr(10)#╚═══════════════════════════════════════════════════════════╝#Chr(13)##Chr(10)##Chr(13)##Chr(10)#")
                    if (bundle.totalFail > 0 || bundle.totalError > 0) {
                        if (structKeyExists(filteredBundleMap, bundle.name)) {
                            for (suite in filteredBundleMap[bundle.name].suiteStats) {
                                writeOutput("Suite with Error or Failure: #suite.name##Chr(13)##Chr(10)##Chr(13)##Chr(10)#")
                                for (spec in suite.specStats) {
                                    writeOutput("       Spec Name: #spec.name##Chr(13)##Chr(10)#")
                                    writeOutput("       Error Message: #spec.failMessage##Chr(13)##Chr(10)#")
                                    writeOutput("       Error Detail: #spec.failDetail##Chr(13)##Chr(10)##Chr(13)##Chr(10)##Chr(13)##Chr(10)#")
                                }
                            }
                        }
                    }
                    writeOutput("#Chr(13)##Chr(10)##Chr(13)##Chr(10)##Chr(13)##Chr(10)#")
                }

            } else {
                for (bundle in DeJsonResult.bundleStats) {
                    writeOutput("Bundle: #bundle.name##Chr(13)##Chr(10)#")
                    writeOutput("CFML Engine: #DeJsonResult.CFMLEngine# #DeJsonResult.CFMLEngineVersion##Chr(13)##Chr(10)#")
                    writeOutput("Duration: #bundle.totalDuration#ms#Chr(13)##Chr(10)#")
                    writeOutput("Labels: #ArrayToList(DeJsonResult.labels, ', ')##Chr(13)##Chr(10)#")
                    writeOutput("╔═══════════════════════════════════════════════════════════╗#Chr(13)##Chr(10)#║ Suites  ║ Specs   ║ Passed  ║ Failed  ║ Errored ║ Skipped ║#Chr(13)##Chr(10)#╠═══════════════════════════════════════════════════════════╣#Chr(13)##Chr(10)#║ #NumberFormat(bundle.totalSuites,'999')#     ║ #NumberFormat(bundle.totalSpecs,'999')#     ║ #NumberFormat(bundle.totalPass,'999')#     ║ #NumberFormat(bundle.totalFail,'999')#     ║ #NumberFormat(bundle.totalError,'999')#     ║ #NumberFormat(bundle.totalSkipped,'999')#     ║#Chr(13)##Chr(10)#╚═══════════════════════════════════════════════════════════╝#Chr(13)##Chr(10)##Chr(13)##Chr(10)##Chr(13)##Chr(10)#")
                }
            }
        } else {
            writeOutput(SerializeJSON(DeJsonResult))
        }
    }
    else if (url.format eq "junit") {
        // Build JUnit XML from cached JSON results (no re-run needed)
        cfcontent(type="text/xml");
        jsonData = DeserializeJSON(result);
        writeOutput(variables.$_buildJunitXml(jsonData));
    }
    else if (url.format eq "txt") {
        // Build text report from cached JSON results (no re-run needed)
        cfcontent(type="text/plain");
        jsonData = DeserializeJSON(result);
        writeOutput(variables.$_buildTextReport(jsonData, runDuration, fromCache));
    }

    // Reset the original environment (only if we modified it)
    if (!fromCache) {
        application.wheels = application.$$$wheels
        structDelete(application, "$$$wheels")
    }

    if (!structKeyExists(url, "format") || url.format eq "html") {
        // Use our html template
        type = "Core";
        include "html.cfm";
    }
</cfscript>
