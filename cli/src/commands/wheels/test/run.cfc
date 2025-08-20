/**
 * Run Wheels application tests
 * Examples:
 * wheels test run
 * wheels test run UserTest
 * wheels test run filter=UserTest --coverage
 * wheels test run group=integration reporter=junit
 */
component extends="../base" {
    
    /**
     * @spec.hint Specific test spec/bundle to run
     * @filter.hint Filter tests by name pattern
     * @group.hint Run specific test group (unit, integration, models, controllers)
     * @bundles.hint Comma-separated list of test bundles to run
     * @labels.hint Comma-separated list of test labels to include
     * @excludes.hint Comma-separated list of patterns to exclude
     * @coverage.hint Generate coverage report
     * @coverageOutputDir.hint Directory for coverage output
     * @reporter.hint Test reporter format (simple, text, json, junit, tap)
     * @reporter.options simple,text,json,junit,tap
     * @outputFile.hint Output file for test results (for junit/json reporters)
     * @watch.hint Watch for file changes and rerun tests
     * @verbose.hint Verbose output
     * @failFast.hint Stop on first test failure
     * @threads.hint Number of parallel threads for test execution
     * @type.hint Type of tests to run: app, core, or plugin
     * @servername.hint Name of server to reload
     * @reload.hint Force a reload of wheels
     * @debug.hint Show debug info and passing tests
     */
    function run(
        string spec = "",
        string filter = "",
        string group = "",
        string bundles = "",
        string labels = "",
        string excludes = "",
        boolean coverage = false,
        string coverageOutputDir = "coverage",
        string reporter = "simple",
        string outputFile = "",
        boolean watch = false,
        boolean verbose = false,
        boolean failFast = false,
        numeric threads = 1,
        string type = "app",
        string servername = "",
        boolean reload = false,
        boolean debug = false
    ) {
        arguments = reconstructArgs(arguments);
        
        // Validate we're in a Wheels project
        if (!isWheelsApp()) {
            error("This command must be run from the root of a Wheels application.");
        }
        
        if (arguments.watch) {
            return runWithWatch(argumentCollection = arguments);
        }
        
        // Build test suite configuration
        var suite = buildTestSuite(argumentCollection = arguments);
        
        // Output suite variables
        outputSuiteVariables(suite);
        
        // Run the test suite
        runTestSuite(suite);
    }
    
    private function buildTestSuite(argumentCollection) {
        // Get server configuration
        var serverConfig = getServerConfig(arguments.servername);
        var serverDetails = serverService.resolveServerDetails( serverProps={ name=arguments.servername } );
        
        // Build configuration
        var config = {
            type = arguments.type,
            servername = arguments.servername,
            serverdefaultName = serverDetails.defaultName,
            configFile = serverDetails.defaultServerConfigFile,
            host = serverConfig.host,
            port = serverConfig.port,
            format = "json", // Always use JSON for parsing
            debug = arguments.debug,
            reload = arguments.reload,
            reporter = arguments.reporter,
            coverage = arguments.coverage,
            verbose = arguments.verbose,
            failFast = arguments.failFast,
            threads = arguments.threads
        };
        
        // Build URL parameters
        var params = {
            format = "json",
            coverage = false,

        };
        
        // Handle spec/filter parameters
        if (len(arguments.spec)) {
            params.testBundles = arguments.spec;
        } else if (len(arguments.filter)) {
            params.testBundles = arguments.filter;
        } else if (len(arguments.bundles)) {
            params.testBundles = arguments.bundles;
        }
        
        if (len(arguments.group)) {
            params.testSuites = arguments.group;
        }
        
        if (len(arguments.labels)) {
            params.labels = arguments.labels;
        }
        
        if (len(arguments.excludes)) {
            params.excludes = arguments.excludes;
        }
        
        if (arguments.reload) {
            params.reload = "true";
        }
        
        if (arguments.failFast) {
            params.options = "failFast:true";
        }
        
        if (arguments.threads > 1) {
            params.options = (structKeyExists(params, "options") ? params.options & ";" : "") & "threads:#arguments.threads#";
        }
        
        // Build test URL
        config.testurl = buildTestUrl(
            type = config.type,
            servername = config.servername,
            params = params
        );
        
        return config;
    }
    
    private function outputSuiteVariables(suite) {
        print.line("Type:       #suite.type#");
        print.line("Server:     #suite.servername#");
        print.line("Name:       #suite.serverdefaultName#");
        print.line("Config:     #suite.configFile#");
        print.line("Host:       #suite.host#");
        print.line("Port:       #suite.port#");
        print.line("URL:        #suite.testurl#");
        print.line("Debug:      #suite.debug#");
        print.line("Reload:     #suite.reload#");
        print.line("Format:     #suite.format#");
        if (suite.coverage) {
            print.line("Coverage:   #suite.coverage#");
        }
    }
    
    private function runTestSuite(suite) {
        print.greenBoldLine( "================#ucase(suite.type)# Tests =======================" ).toConsole();
        
        // Advice we are running
        print.boldCyanLine( "Executing tests, please wait..." )
            .blinkingRed( "Please wait...")
            .printLine()
            .toConsole();
        
        try {
            // Execute HTTP request
            var httpResult = executeTestRequest(
                url = suite.testurl,
                timeout = 300,
                debug = suite.verbose
            );
            
            if (!httpResult.success) {
                return error( 'Error executing tests: #CR# #httpResult.error#' );
            }
            
            if (isJson(httpResult.content)) {
                outputTestResults(deserializeJSON(httpResult.content), suite.debug, suite.coverage);
            } else {
                // Try to parse HTML or display raw content
                print.line(httpResult.content);
            }
            
        } catch (any e) {
            return error( 'Error executing tests: #CR# #e.message##CR##e.detail#' );
        }
    }
    
    private function outputTestResults(result, debug, coverage = false) {
        var hiddenCount = 0;
        
        // Normalize result structure - handle different response formats
        if (!structKeyExists(result, "totalError")) {
            result.totalError = structKeyExists(result, "totalErrors") ? result.totalErrors : 0;
        }
        if (!structKeyExists(result, "totalFail")) {
            result.totalFail = structKeyExists(result, "totalFailures") ? result.totalFailures : 0;
        }
        if (!structKeyExists(result, "totalPass")) {
            result.totalPass = structKeyExists(result, "totalPassed") ? result.totalPassed : 
                            (structKeyExists(result, "totalSpecs") ? result.totalSpecs - result.totalFail - result.totalError : 0);
        }
        if (!structKeyExists(result, "totalSkipped")) {
            result.totalSkipped = structKeyExists(result, "totalSkip") ? result.totalSkip : 0;
        }
        if (!structKeyExists(result, "totalBundles")) {
            result.totalBundles = structKeyExists(result, "bundleStats") ? arrayLen(result.bundleStats) : 0;
        }
        if (!structKeyExists(result, "totalSuites")) {
            result.totalSuites = 0;
            if (structKeyExists(result, "bundleStats")) {
                for (var bundle in result.bundleStats) {
                    if (structKeyExists(bundle, "suiteStats")) {
                        result.totalSuites += arrayLen(bundle.suiteStats);
                    }
                }
            }
        }
        if (!structKeyExists(result, "totalSpecs")) {
            result.totalSpecs = result.totalPass + result.totalFail + result.totalError + result.totalSkipped;
        }
        
        // Test completion status
        if (result.totalError == 0 && result.totalFail == 0) {
            print.greenBoldLine( "================ Tests Complete: All Good! =============" );
        } else {
            print.redBoldLine( "================ Tests Complete: Failures! =============" );
        }
        
        print.boldLine( "================ Results: =======================" );
        
        // Display detailed results if there are failures or debug is on
        if (structKeyExists(result, "bundleStats") && isArray(result.bundleStats)) {
            for (var bundle in result.bundleStats) {
                if (structKeyExists(bundle, "suiteStats") && isArray(bundle.suiteStats)) {
                    for (var suite in bundle.suiteStats) {
                        if (structKeyExists(suite, "specStats") && isArray(suite.specStats)) {
                            for (var spec in suite.specStats) {
                                var status = structKeyExists(spec, "status") ? spec.status : "Unknown";
                                
                                if (status != "Passed" && status != "Skipped") {
                                    print.boldLine("Test Bundle:")
                                         .boldRedLine("       #structKeyExists(bundle, 'name') ? bundle.name : 'Unknown'#:")
                                         .boldLine("Test Suite:")
                                         .boldRedLine("       #structKeyExists(suite, 'name') ? suite.name : 'Unknown'#:")
                                         .boldLine("Test Name:")
                                         .boldRedLine("       #structKeyExists(spec, 'name') ? spec.name : 'Unknown'#:");
                                    
                                    if (structKeyExists(spec, "failMessage") && len(spec.failMessage)) {
                                        print.boldLine("Message:");
                                        // Try to format HTML messages if present
                                        try {
                                            if (structKeyExists(variables, "Formatter")) {
                                                print.line("#Formatter.HTML2ANSI(spec.failMessage)#");
                                            } else {
                                                print.line("#spec.failMessage#");
                                            }
                                        } catch (any e) {
                                            print.line("#spec.failMessage#");
                                        }
                                    }
                                    
                                    print.line("----------------------------------------------------")
                                         .line();
                                } else {
                                    if (debug) {
                                        var bundleName = structKeyExists(bundle, "name") ? bundle.name : "";
                                        var suiteName = structKeyExists(suite, "name") ? suite.name : "";
                                        var specName = structKeyExists(spec, "name") ? spec.name : "";
                                        var duration = structKeyExists(spec, "totalDuration") ? spec.totalDuration : 0;
                                        print.greenline("#bundleName# #suiteName#: #specName# :#duration#ms");
                                    } else {
                                        hiddenCount++;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        if (hiddenCount > 0) {
            print.boldLine( "Output from #hiddenCount# tests hidden");
        }
        
        // Summary
        print.Line("================ Summary: =======================" )
             .line("= Bundles: #result.totalBundles#")
             .line("= Suites: #result.totalSuites#")
             .line("= Specs: #result.totalSpecs#")
             .line("= Skipped: #result.totalSkipped#")
             .line("= Errors: #result.totalError#")
             .line("= Failures: #result.totalFail#")
             .line("= Successes: #result.totalPass#");
        
        if (structKeyExists(result, "totalDuration")) {
            print.line("= Duration: #numberFormat(result.totalDuration / 1000, '0.00')#s");
        }
        
        print.Line("==================================================" );
        
        // Display coverage if available
        if (coverage && structKeyExists(result, "coverage")) {
            displayCoverageReport(result.coverage);
        }
    }
    
    private function displayCoverageReport(coverage) {
        print.line()
             .yellowBoldLine("================ Coverage Report: =======================")
             .line();
        
        if (isStruct(arguments.coverage)) {
            if (structKeyExists(arguments.coverage, "percentage")) {
                var percent = numberFormat(arguments.coverage.percentage, '0.0');
                print.line("= Overall Coverage: #percent#%");
            }
            
            if (structKeyExists(arguments.coverage, "lines")) {
                print.line("= Lines:     #numberFormat(arguments.coverage.lines.percent, '0.0')#% (#arguments.coverage.lines.covered#/#arguments.coverage.lines.total#)");
            }
            
            if (structKeyExists(arguments.coverage, "functions")) {
                print.line("= Functions: #numberFormat(arguments.coverage.functions.percent, '0.0')#% (#arguments.coverage.functions.covered#/#arguments.coverage.functions.total#)");
            }
            
            print.Line("==========================================================");
        }
    }
}