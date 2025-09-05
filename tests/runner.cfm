<cfsetting requestTimeOut="1800">
<cfscript>
    // Parameter defaults - handle all TestBox CLI parameters
    param name="url.directory" default="tests.specs";
    param name="url.bundles" default="";
    param name="url.recurse" default="true" type="boolean";
    param name="url.reporter" default="";
    param name="url.labels" default="";
    param name="url.excludes" default="";
    param name="url.testBundles" default="";
    param name="url.testSuites" default="";
    param name="url.testSpecs" default="";
    param name="url.verbose" default="false" type="boolean";
    param name="url.format" default="html";
    
    // Add new parameters for coverage and bail
    param name="url.coverage" default="false" type="boolean";
    param name="url.bail" default="false" type="boolean";
    param name="url.coveragePathToCapture" default="/app";
    param name="url.coverageWhitelist" default="*.cfc";
    param name="url.coverageBlacklist" default="*Test.cfc,*Spec.cfc";
    param name="url.coverageBrowserOutputDir" default="/tests/results/coverage";
    
    // Build TestBox options
    testBoxOptions = {};
    
    // Determine if using bundles or directory
    if (len(url.bundles)) {
        // If bundles are specified, use them
        testBoxOptions.bundles = url.bundles;
    } else {
        // Otherwise use directory
        testBoxOptions.directory = {
            mapping = url.directory,
            recurse = url.recurse
        };
    }
    
    // Add filtering options if provided
    if (len(url.labels)) {
        testBoxOptions.labels = url.labels;
    }
    
    if (len(url.excludes)) {
        testBoxOptions.excludes = url.excludes;
    }
    
    // Add test filtering if provided
    if (len(url.testBundles)) {
        testBoxOptions.testBundles = url.testBundles;
    }
    
    if (len(url.testSuites)) {
        testBoxOptions.testSuites = url.testSuites;
    }
    
    if (len(url.testSpecs)) {
        testBoxOptions.testSpecs = url.testSpecs;
    }
    
    // Add coverage options if enabled
    if (url.coverage) {
        // Check if FusionReactor is available using Java class detection
        hasFusionReactor = false;
        try {
            frAgentClass = createObject("java", "com.intergral.fusionreactor.agent.Agent");
            // Do a quick test to ensure the line performance instrumentation is loaded
            instrumentation = frAgentClass.getAgentInstrumentation().get("cflpi");
            if (!isNull(instrumentation)) {
                hasFusionReactor = true;
            }
        } catch (any e) {
            // FusionReactor not available or not properly configured
            hasFusionReactor = false;
        }

        if (!hasFusionReactor) {
            cfheader(statustext="Expectation Failed", statuscode=417);
            writeOutput("Warning: Code coverage requested but FusionReactor not detected. Please install FusionReactor first.#Chr(10)#");
            abort;
        }
        
        testBoxOptions.coverage = {
            enabled = hasFusionReactor,
            pathToCapture = url.coveragePathToCapture,
            whitelist = url.coverageWhitelist,
            blacklist = url.coverageBlacklist,
            browserOutputDir = url.coverageBrowserOutputDir
        };
    }
    
    // Add bail option (stop on first failure)
    if (url.bail) {
        testBoxOptions.bail = true;
    }
    
    // Initialize TestBox with options
    if (len(url.bundles)) {
        testBox = new testbox.system.TestBox(bundles=url.bundles);
    } else {
        testBox = new testbox.system.TestBox(
            directory=testBoxOptions.directory.mapping,
            recurse=testBoxOptions.directory.recurse
        );
    }

    setTestboxEnvironment()

    if (!structKeyExists(url, "format") || url.format eq "html") {
        // Determine reporter for HTML format
        if (len(url.reporter)) {
            testBoxOptions.reporter = url.reporter;
        } else {
            testBoxOptions.reporter = "testbox.system.reports.JSONReporter";
        }
        
        result = testBox.run(argumentCollection = testBoxOptions);
    }
    else if(url.format eq "json"){
        // Set JSON reporter
        testBoxOptions.reporter = "testbox.system.reports.JSONReporter";
        
        result = testBox.run(argumentCollection = testBoxOptions);
        
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
                    
                    // Add bail indicator if enabled
                    if (url.bail) {
                        writeOutput("Fail-Fast Mode: ENABLED#Chr(13)##Chr(10)#")
                    }
                    
                    // Add coverage indicator if enabled
                    if (url.coverage) {
                        writeOutput("Code Coverage: REQUESTED#Chr(13)##Chr(10)#")
                    }
                    
                    writeOutput("╔═══════════════════════════════════════════════════════════╗#Chr(13)##Chr(10)#║ Suites  ║ Specs   ║ Passed  ║ Failed  ║ Errored ║ Skipped ║#Chr(13)##Chr(10)#╠═══════════════════════════════════════════════════════════╣#Chr(13)##Chr(10)#║ #NumberFormat(bundle.totalSuites,'999')#     ║ #NumberFormat(bundle.totalSpecs,'999')#     ║ #NumberFormat(bundle.totalPass,'999')#     ║ #NumberFormat(bundle.totalFail,'999')#     ║ #NumberFormat(bundle.totalError,'999')#     ║ #NumberFormat(bundle.totalSkipped,'999')#     ║#Chr(13)##Chr(10)#╚═══════════════════════════════════════════════════════════════════╝#Chr(13)##Chr(10)##Chr(13)##Chr(10)#")
                    if(bundle.totalFail > 0 || bundle.totalError > 0){
                        for(suite in DeJsonResult.bundleStats[count].suiteStats){
                            writeOutput("Suite with Error or Failure: #suite.name##Chr(13)##Chr(10)##Chr(13)##Chr(10)#")
                            for(spec in suite.specStats){
                                writeOutput("       Spec Name: #spec.name##Chr(13)##Chr(10)#")
                                writeOutput("       Error Message: #spec.failMessage##Chr(13)##Chr(10)#")
                                writeOutput("       Error Detail: #spec.failDetail##Chr(13)##Chr(10)##Chr(13)##Chr(10)##Chr(13)##Chr(10)#")
                                
                                // If bail is enabled and we found a failure, indicate stopping
                                if (url.bail) {
                                    writeOutput("       [BAIL] Stopping test execution due to failure...#Chr(13)##Chr(10)##Chr(13)##Chr(10)#")
                                    break;
                                }
                            }
                            if (url.bail && (bundle.totalFail > 0 || bundle.totalError > 0)) {
                                break;
                            }
                        }
                        count += 1;
                    }
                    writeOutput("#Chr(13)##Chr(10)##Chr(13)##Chr(10)##Chr(13)##Chr(10)#")
                    
                    // Break out of bundle loop if bail is enabled
                    if (url.bail && (bundle.totalFail > 0 || bundle.totalError > 0)) {
                        break;
                    }
                }
                
            }else{
                for(bundle in DeJsonResult.bundleStats){
                    writeOutput("Bundle: #bundle.name##Chr(13)##Chr(10)#")
                    writeOutput("CFML Engine: #DeJsonResult.CFMLEngine# #DeJsonResult.CFMLEngineVersion##Chr(13)##Chr(10)#")
                    writeOutput("Duration: #bundle.totalDuration#ms#Chr(13)##Chr(10)#")
                    writeOutput("Labels: #ArrayToList(DeJsonResult.labels, ', ')##Chr(13)##Chr(10)#")
                    writeOutput("╔═══════════════════════════════════════════════════════════╗#Chr(13)##Chr(10)#║ Suites  ║ Specs   ║ Passed  ║ Failed  ║ Errored ║ Skipped ║#Chr(13)##Chr(10)#╠═══════════════════════════════════════════════════════════╣#Chr(13)##Chr(10)#║ #NumberFormat(bundle.totalSuites,'999')#     ║ #NumberFormat(bundle.totalSpecs,'999')#     ║ #NumberFormat(bundle.totalPass,'999')#     ║ #NumberFormat(bundle.totalFail,'999')#     ║ #NumberFormat(bundle.totalError,'999')#     ║ #NumberFormat(bundle.totalSkipped,'999')#     ║#Chr(13)##Chr(10)#╚═══════════════════════════════════════════════════════════════════════════════════╝#Chr(13)##Chr(10)##Chr(13)##Chr(10)##Chr(13)##Chr(10)#")
                }
            }
        }else{
            writeOutput(result)
        }
    }
    else if (url.format eq "txt") {
        // Set Text reporter
        testBoxOptions.reporter = "testbox.system.reports.TextReporter";
        
        result = testBox.run(argumentCollection = testBoxOptions);
        
        cfcontent(type="text/plain");
        writeOutput(result)
    }
    else if(url.format eq "junit"){
        // Set JUnit reporter
        testBoxOptions.reporter = "testbox.system.reports.ANTJUnitReporter";
        
        result = testBox.run(argumentCollection = testBoxOptions);
        
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
        application.wo.set(modelPath = local.AssetPath & "models")
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