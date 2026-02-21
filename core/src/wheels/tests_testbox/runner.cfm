<cfsetting requestTimeOut="1800">
<cfscript>
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
        application.wo.$include(template = "/wheels/tests_testbox/routes.cfm")
        application.wo.$setNamedRoutePositions()

        var AssetPath = "/wheels/tests_testbox/_assets/"

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
        if (structKeyExists(url, "db") && listFind("mysql,sqlserver,sqlserver_cicd,postgres,h2,oracle,sqlite", url.db)) {
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
        application.testenv.db = application.wo.$dbinfo(datasource = application.wheels.dataSourceName, type = "version")

        // Setting up test database for test environment
        var tables = application.wo.$dbinfo(datasource = application.wheels.dataSourceName, type = "tables")
        var tableList = ValueList(tables.table_name)
        var populate = StructKeyExists(url, "populate") ? url.populate : true
        if (populate || !FindNoCase("c_o_r_e_authors", tableList)) {
            include "/wheels/tests_testbox/populate.cfm"
        }
    }

    try {
        // Try to create TestBox instance with coverage disabled
        testBox = new wheels.testbox.system.TestBox(
            directory="wheels.tests_testbox.specs",
            options={ coverage = { enabled = false } }
        );
    } catch (any e) {
        cfheader(statuscode="500");
        cfcontent(type="application/json");
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
            reporter = "wheels.testbox.system.reports.JSONReporter"
        );
    }
    else if(url.format eq "json"){
        result = testBox.run(
            reporter = "wheels.testbox.system.reports.JSONReporter"
        );
        cfcontent(type="application/json");
        cfheader(name="Access-Control-Allow-Origin", value="*");
        DeJsonResult = DeserializeJSON(result);
        if (DeJsonResult.totalFail > 0 || DeJsonResult.totalError > 0) {
            if(!structKeyExists(url, "cli") || !url.cli){
                cfheader(statuscode=417);
            }
        } else {
            cfheader(statuscode=200);
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

                count = 1;
                for(bundle in allBundles){
                    writeOutput("Bundle: #bundle.name##Chr(13)##Chr(10)#")
                    writeOutput("CFML Engine: #DeJsonResult.CFMLEngine# #DeJsonResult.CFMLEngineVersion##Chr(13)##Chr(10)#")
                    writeOutput("Duration: #bundle.totalDuration#ms#Chr(13)##Chr(10)#")
                    writeOutput("Labels: #ArrayToList(DeJsonResult.labels, ', ')##Chr(13)##Chr(10)#")
                    writeOutput("╔═══════════════════════════════════════════════════════════╗#Chr(13)##Chr(10)#║ Suites  ║ Specs   ║ Passed  ║ Failed  ║ Errored ║ Skipped ║#Chr(13)##Chr(10)#╠═══════════════════════════════════════════════════════════╣#Chr(13)##Chr(10)#║ #NumberFormat(bundle.totalSuites,'999')#     ║ #NumberFormat(bundle.totalSpecs,'999')#     ║ #NumberFormat(bundle.totalPass,'999')#     ║ #NumberFormat(bundle.totalFail,'999')#     ║ #NumberFormat(bundle.totalError,'999')#     ║ #NumberFormat(bundle.totalSkipped,'999')#     ║#Chr(13)##Chr(10)#╚═══════════════════════════════════════════════════════════╝#Chr(13)##Chr(10)##Chr(13)##Chr(10)#")
                    if(bundle.totalFail > 0 || bundle.totalError > 0){
                        for(suite in DeJsonResult.bundleStats[count].suiteStats){
                            writeOutput("Suite with Error or Failure: #suite.name##Chr(13)##Chr(10)##Chr(13)##Chr(10)#")
                            for(spec in suite.specStats){
                                writeOutput("       Spec Name: #spec.name##Chr(13)##Chr(10)#")
                                writeOutput("       Error Message: #spec.failMessage##Chr(13)##Chr(10)#")
                                writeOutput("       Error Detail: #spec.failDetail##Chr(13)##Chr(10)##Chr(13)##Chr(10)##Chr(13)##Chr(10)#")
                            }
                        }
                        count += 1;
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
            reporter = "wheels.testbox.system.reports.TextReporter"
        )
        cfcontent(type="text/plain");
        writeOutput(result)
    }
    else if(url.format eq "junit"){
        result = testBox.run(
            reporter = "wheels.testbox.system.reports.ANTJUnitReporter"
        )
        cfcontent(type="text/xml");
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
