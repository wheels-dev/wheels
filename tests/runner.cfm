<cfsetting requestTimeOut="1800">
<cfscript>
    testBox = new testbox.system.TestBox(directory="tests.specs")

    setTestboxEnvironment()

    if (!structKeyExists(url, "format") || url.format eq "html") {
        result = testBox.run(
            reporter = "testbox.system.reports.JSONReporter"
        );
    }
    else if(url.format eq "json" && structKeyExists(url, "cli") && url.cli==true){
        // Handle TestBox CLI parameters when called from wheels test run
        testBoxArgs = {};
        
        // Handle recurse parameter (default true)
        if (structKeyExists(url, "recurse")) {
            testBoxArgs.recurse = url.recurse;
        }
    
        // Handle verbose parameter
        if (structKeyExists(url, "verbose") && url.verbose) {
            testBoxArgs.verbose = true;
        }
        
        
        // Determine reporter - default to JSON for CLI
        local.reporterClass = "testbox.system.reports.JSONReporter";
        
        if (structKeyExists(url, "reporter") && len(url.reporter)) {
          testBoxArgs.reporter = url.reporter;
        }
        
        // Run TestBox with the configured parameters
        result = testBox.run(argumentCollection = testBoxArgs);
        
        // Set appropriate content type based on reporter
        if (findNoCase("JSON", local.reporterClass)) {
            cfcontent(type="application/json");
        } else if (findNoCase("JUnit", local.reporterClass) || findNoCase("XML", local.reporterClass)) {
            cfcontent(type="text/xml");
        } else {
            cfcontent(type="text/plain");
        }
        
        // Handle outputFile parameter for single output
        if (structKeyExists(url, "outputFile") && len(url.outputFile)) {
            fileWrite(expandPath(url.outputFile), result);
        }
        
        writeOutput(result);
        
        cfheader(name="Access-Control-Allow-Origin", value="*");
        
        // Set status code based on results for JSON reporter
        if (findNoCase("JSON", local.reporterClass)) {
            try {
                if (!structKeyExists(local, "jsonData")) {
                    local.jsonData = deserializeJSON(result);
                }
                if (local.jsonData.totalFail > 0 || local.jsonData.totalError > 0) {
                } else {
                    cfheader(statustext="OK", statuscode=200);
                }
            } catch (any e) {
                // If not JSON, continue
            }
        }
    }
    else if(url.format eq "json"){
        result = testBox.run(
            reporter = "testbox.system.reports.JSONReporter"
        );
        cfcontent(type="application/json");
        cfheader(name="Access-Control-Allow-Origin", value="*");
        DeJsonResult = DeserializeJSON(result);
        if (DeJsonResult.totalFail > 0 || DeJsonResult.totalError > 0) {
            cfheader(statustext="Expectation Failed", statuscode=417);
        } else {
            cfheader(statustext="OK", statuscode=200);
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
            reporter = "testbox.system.reports.TextReporter"
        )        
        cfcontent(type="text/plain");
        writeOutput(result)
    }
    else if(url.format eq "junit"){
        result = testBox.run(
            reporter = "testbox.system.reports.ANTJUnitReporter"
        )
        cfcontent(type="text/xml");
        writeOutput(result)
    }
    // reset the original environment
    application.wheels = application.$$$wheels
    structDelete(application, "$$$wheels")
    if(!structKeyExists(url, "format") || url.format eq "html"){
        // Use our html template
        type = "App";
        include "/wheels/tests_testbox/html.cfm";
    }

    private function setTestboxEnvironment() {
        // creating backup for original environment
        application.$$$wheels = Duplicate(application.wheels)

        // load testbox routes
        application.wo.$include(template = "/tests/routes.cfm")
        application.wo.$setNamedRoutePositions()

        local.AssetPath = "/tests/_assets/"
        
        application.wo.set(rewriteFile = "index.cfm")
        application.wo.set(controllerPath = local.AssetPath & "controllers")
        application.wo.set(viewPath = local.AssetPath & "views")
        application.wo.set(modelPath = "/app/models")
        application.wo.set(wheelsComponentPath = "/wheels")

        /* turn off default validations for testing */
        application.wheels.automaticValidations = false
        application.wheels.assetQueryString = false
        application.wheels.assetPaths = false

        /* redirections should always delay when testing */
        application.wheels.functions.redirectTo.delay = true

        /* enable transactions for proper test isolation */
        application.wheels.transactionMode = "commit"

        /* turn off request query caching */
        application.wheels.cacheQueriesDuringRequest = false

        // CSRF
        application.wheels.csrfCookieName = "_wheels_test_authenticity"
        application.wheels.csrfCookieEncryptionAlgorithm = "AES"
        application.wheels.csrfCookieEncryptionSecretKey = GenerateSecretKey("AES")
        application.wheels.csrfCookieEncryptionEncoding = "Base64"

        // Setup CSRF token and cookie. The cookie can always be in place, even when the session-based CSRF storage is being
        // tested.
        dummyController = application.wo.controller("dummy")
        csrfToken = dummyController.$generateCookieAuthenticityToken()

        cookie[application.wheels.csrfCookieName] = Encrypt(
            SerializeJSON({authenticityToken = csrfToken}),
            application.wheels.csrfCookieEncryptionSecretKey,
            application.wheels.csrfCookieEncryptionAlgorithm,
            application.wheels.csrfCookieEncryptionEncoding
        )
        if(structKeyExists(url, "db") && listFind("mysql,sqlserver,postgres,h2", url.db)){
            application.wheels.dataSourceName = "wheelstestdb_" & url.db;
        } else if (application.wheels.coreTestDataSourceName eq "|datasourceName|") {
            application.wheels.dataSourceName = "wheelstestdb"; 
        } else {
            application.wheels.dataSourceName = application.wheels.coreTestDataSourceName;
        }
        application.testenv.db = application.wo.$dbinfo(datasource = application.wheels.dataSourceName, type = "version")

        local.populate = StructKeyExists(url, "populate") ? url.populate : true
        if (local.populate) {
            include "populate.cfm"
        }
    }
</cfscript>