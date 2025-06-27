<cfsetting requestTimeOut="1800">
<cfscript>
    try {
        // Get the requested format
        local.format = structKeyExists(url, "format") ? url.format : "html";
        
        // Setup test environment function
        function setTestboxEnvironment() {
            // creating backup for original environment
            application.$$$wheels = Duplicate(application.wheels);

            // load testbox routes
            application.wo.$include(template = "/wheels/tests_testbox/routes.cfm");
            application.wo.$setNamedRoutePositions();

            local.AssetPath = "/wheels/tests_testbox/_assets/";
            
            application.wo.set(rewriteFile = "index.cfm");
            application.wo.set(controllerPath = local.AssetPath & "controllers");
            application.wo.set(viewPath = local.AssetPath & "views");
            application.wo.set(modelPath = local.AssetPath & "models");
            application.wo.set(wheelsComponentPath = "/wheels");

            /* set migration level for tests*/
            application.wheels.migrationLevel = 2;
            
            /* turn off default validations for testing */
            application.wheels.automaticValidations = false;
            application.wheels.assetQueryString = false;
            application.wheels.assetPaths = false;

            /* redirections should always delay when testing */
            application.wheels.functions.redirectTo.delay = true;

            /* turn off transactions by default */
            application.wheels.transactionMode = "none";

            /* turn off request query caching */
            application.wheels.cacheQueriesDuringRequest = false;

            // CSRF
            application.wheels.csrfCookieName = "_wheels_test_authenticity";
            application.wheels.csrfCookieEncryptionAlgorithm = "AES";
            application.wheels.csrfCookieEncryptionSecretKey = GenerateSecretKey("AES");
            application.wheels.csrfCookieEncryptionEncoding = "Base64";

            // Setup CSRF token and cookie
            dummyController = application.wo.controller("dummy");
            csrfToken = dummyController.$generateCookieAuthenticityToken();

            cookie[application.wheels.csrfCookieName] = Encrypt(
                SerializeJSON({authenticityToken = csrfToken}),
                application.wheels.csrfCookieEncryptionSecretKey,
                application.wheels.csrfCookieEncryptionAlgorithm,
                application.wheels.csrfCookieEncryptionEncoding
            );
            
            // Set datasource based on URL parameter or default
            if (structKeyExists(url, "db") && listFind("mysql,sqlserver,sqlserver_cicd,postgres,h2", url.db)) {
                if (listFind("sqlserver,sqlserver_cicd", url.db)) {
                    application.wheels.dataSourceName = "wheelstestdb_sqlserver";
                } else {
                    application.wheels.dataSourceName = "wheelstestdb_" & url.db;
                }
            } else if (structKeyExists(application.wheels, "coreTestDataSourceName") && application.wheels.coreTestDataSourceName neq "|datasourceName|") {
                application.wheels.dataSourceName = application.wheels.coreTestDataSourceName;
            } else {
                // Use the current datasource as fallback
                application.wheels.dataSourceName = application.wheels.dataSourceName;
            }
            
            try {
                application.testenv.db = application.wo.$dbinfo(datasource = application.wheels.dataSourceName, type = "version");
            } catch (any e) {
                application.testenv.db = {driver_name: "Unknown", driver_ver: "Unknown"};
            }

            // Setting up test database for test environment
            try {
                local.tables = application.wo.$dbinfo(datasource = application.wheels.dataSourceName, type = "tables");
                local.tableList = ValueList(local.tables.table_name);
                local.populate = StructKeyExists(url, "populate") ? url.populate : true;
                if (local.populate || !FindNoCase("_c_o_r_e_authors", local.tableList)) {
                    include "populate.cfm";
                }
            } catch (any dbError) {
                // Skip database setup if there's an error (e.g., datasource doesn't exist)
                // Tests that require database will fail individually
            }
        }
        
        // Create TestBox configuration
        testBoxConfig = {
            directory: "wheels.tests_testbox.specs",
            recurse: true,
            bundles: "",
            labels: "",
            excludes: "",
            reportpath: "/wheels/tests_testbox",
            runner: [],
            callbacks: {},
            modules: {
                // Disable module loading to avoid BINDER errors
                autoLoad: false
            },
            coverage: {
                enabled: false
            }
        };
        
        // Create TestBox instance
        testBox = createObject("component", "testbox.system.TestBox");
        testBox.init(argumentCollection=testBoxConfig);
        
        // Sort bundles alphabetically
        local.sortedArray = testBox.getBundles();
        arraySort(local.sortedArray, "textNoCase");
        testBox.setBundles(local.sortedArray);
        
        // Setup test environment
        setTestboxEnvironment();
        
        // Run tests based on format
        try {
            switch(local.format) {
                case "json":
                    result = testBox.run(reporter="testbox.system.reports.JSONReporter");
                    cfheader(name="Access-Control-Allow-Origin", value="*");
                    
                    // Parse result to set proper status code
                    DeJsonResult = DeserializeJSON(result);
                    if (DeJsonResult.totalFail > 0 || DeJsonResult.totalError > 0) {
                        cfheader(statustext="Expectation Failed", statuscode=417);
                    } else {
                        cfheader(statustext="OK", statuscode=200);
                    }
                    
                    writeOutput(result);
                    break;
                    
                case "txt":
                case "text":
                    // Use JSON reporter and format as text to avoid reporter issues
                    result = testBox.run(reporter="testbox.system.reports.JSONReporter");
                    local.jsonData = deserializeJSON(result);
                    
                    writeOutput("WHEELS CORE TEST RESULTS" & chr(10));
                    writeOutput("========================" & chr(10) & chr(10));
                    writeOutput("Engine: " & local.jsonData.CFMLEngine & " " & local.jsonData.CFMLEngineVersion & chr(10));
                    writeOutput("TestBox: " & local.jsonData.version & chr(10));
                    writeOutput("Duration: " & numberFormat(local.jsonData.totalDuration/1000, "0.00") & " seconds" & chr(10) & chr(10));
                    
                    writeOutput("SUMMARY" & chr(10));
                    writeOutput("-------" & chr(10));
                    writeOutput("Total Bundles: " & local.jsonData.totalBundles & chr(10));
                    writeOutput("Total Suites:  " & local.jsonData.totalSuites & chr(10));
                    writeOutput("Total Specs:   " & local.jsonData.totalSpecs & chr(10));
                    writeOutput("Total Passed:  " & local.jsonData.totalPass & chr(10));
                    writeOutput("Total Failed:  " & local.jsonData.totalFail & chr(10));
                    writeOutput("Total Errors:  " & local.jsonData.totalError & chr(10));
                    writeOutput("Total Skipped: " & local.jsonData.totalSkipped & chr(10) & chr(10));
                    
                    if (local.jsonData.totalFail > 0 || local.jsonData.totalError > 0) {
                        writeOutput("FAILURES AND ERRORS" & chr(10));
                        writeOutput("===================" & chr(10));
                        for (bundle in local.jsonData.bundleStats) {
                            if (bundle.totalFail > 0 || bundle.totalError > 0) {
                                writeOutput(chr(10) & "Bundle: " & bundle.name & chr(10));
                                for (suite in bundle.suiteStats) {
                                    if (suite.totalFail > 0 || suite.totalError > 0) {
                                        for (spec in suite.specStats) {
                                            if (spec.status == "Failed" || spec.status == "Error") {
                                                writeOutput("  [" & spec.status & "] " & spec.name & chr(10));
                                                if (structKeyExists(spec, "failMessage") && len(spec.failMessage)) {
                                                    writeOutput("    " & spec.failMessage & chr(10));
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    break;
                    
                case "junit":
                case "xml":
                    try {
                        result = testBox.run(reporter="testbox.system.reports.ANTJUnitReporter");
                        writeOutput(result);
                    } catch (any junitError) {
                        // JUnit reporter might have issues, generate basic XML
                        result = testBox.run(reporter="testbox.system.reports.JSONReporter");
                        local.jsonData = deserializeJSON(result);
                        writeOutput('<?xml version="1.0" encoding="UTF-8"?>');
                        writeOutput('<testsuites>');
                        writeOutput('<testsuite name="Wheels Core Tests" tests="#local.jsonData.totalSpecs#" failures="#local.jsonData.totalFail#" errors="#local.jsonData.totalError#" skipped="#local.jsonData.totalSkipped#" time="#local.jsonData.totalDuration/1000#">');
                        writeOutput('</testsuite>');
                        writeOutput('</testsuites>');
                    }
                    break;
                    
                case "simple":
                    // Use JSON reporter and format as simple text
                    result = testBox.run(reporter="testbox.system.reports.JSONReporter");
                    local.jsonData = deserializeJSON(result);
                    
                    writeOutput("TestBox v" & local.jsonData.version & " " & chr(10));
                    writeOutput("=" & repeatString("=", 50) & chr(10));
                    if (local.jsonData.totalFail == 0 && local.jsonData.totalError == 0) {
                        writeOutput("[PASSED] ");
                    } else {
                        writeOutput("[FAILED] ");
                    }
                    writeOutput("Bundles:#local.jsonData.totalBundles# Suites:#local.jsonData.totalSuites# Specs:#local.jsonData.totalSpecs# Pass:#local.jsonData.totalPass# Fail:#local.jsonData.totalFail# Error:#local.jsonData.totalError# Skipped:#local.jsonData.totalSkipped# Time:#numberFormat(local.jsonData.totalDuration/1000, '0.000')#s" & chr(10));
                    writeOutput("=" & repeatString("=", 50) & chr(10));
                    break;
                    
                default: // html
                    // Try to use custom reporter first, fallback to JSON if it fails
                    try {
                        if (!structKeyExists(url, "reporter")) {
                            url.reporter = "wheels.tests_testbox.Reporter";
                        }
                        results = testBox.run(reporter=url.reporter);
                        
                        // Include navigation and output results
                        include "_navigation.cfm";
                        writeOutput(results);
                    } catch (any reporterError) {
                        // Fallback to JSON reporter with HTML formatting
                        result = testBox.run(reporter="testbox.system.reports.JSONReporter");
                        
                        // Use the HTML formatter
                        type = "Core";
                        include "html.cfm";
                    }
            }
        } finally {
            // Reset the original environment
            if (structKeyExists(application, "$$$wheels")) {
                application.wheels = application.$$$wheels;
                structDelete(application, "$$$wheels");
            }
        }
        
    } catch (any e) {
        // Handle errors based on format
        if (structKeyExists(url, "format")) {
            switch(url.format) {
                case "json":
                    writeOutput(serializeJSON({
                        success: false,
                        error: e.message,
                        detail: e.detail,
                        type: e.type
                    }));
                    break;
                    
                case "txt":
                case "text":
                    writeOutput("ERROR RUNNING CORE TESTS" & chr(10));
                    writeOutput("==========================" & chr(10));
                    writeOutput("Message: " & e.message & chr(10));
                    writeOutput("Detail: " & e.detail & chr(10));
                    if (structKeyExists(e, "stackTrace")) {
                        writeOutput("Stack Trace:" & chr(10));
                        writeOutput(e.stackTrace);
                    }
                    break;
                    
                default:
                    writeOutput("<h1>Error Running Core Tests</h1>");
                    writeOutput("<p><strong>Message:</strong> #e.message#</p>");
                    writeOutput("<p><strong>Detail:</strong> #e.detail#</p>");
                    if (structKeyExists(e, "stackTrace")) {
                        writeOutput("<h2>Stack Trace:</h2>");
                        writeOutput("<pre>#e.stackTrace#</pre>");
                    }
            }
        } else {
            // Default HTML error output
            writeOutput("<h1>Error Running Core Tests</h1>");
            writeOutput("<p><strong>Message:</strong> #e.message#</p>");
            writeOutput("<p><strong>Detail:</strong> #e.detail#</p>");
            if (structKeyExists(e, "stackTrace")) {
                writeOutput("<h2>Stack Trace:</h2>");
                writeOutput("<pre>#e.stackTrace#</pre>");
            }
        }
    }
</cfscript>