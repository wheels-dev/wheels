/**
 * Run tests with interactive debugging capabilities
 * 
 * {code:bash}
 * wheels test:debug
 * wheels test:debug app
 * wheels test:debug core spec:models.user
 * {code}
 */
component extends="../base" {

    /**
     * @type Type of tests to run (app, core, or plugin)
     * @spec Specific test spec to run (e.g., models.user)
     * @servername Name of server to reload (defaults to current)
     * @reload Force a reload of wheels
     * @breakOnFailure Stop test execution on first failure
     * @outputLevel Output verbosity (1=minimal, 2=normal, 3=verbose)
     */
    function run(
        string type="app", 
        string spec="", 
        string servername="", 
        boolean reload=false,
        boolean breakOnFailure=true,
        numeric outputLevel=3
    ) {
        // Welcome message
        print.line();
        print.boldMagentaLine("Wheels Test Debug Mode");
        print.line();
        
        // Format URL parameters
        local.urlParams = "&type=#arguments.type#&debug=true&outputLevel=#arguments.outputLevel#";
        
        if (len(trim(arguments.spec))) {
            local.urlParams &= "&spec=#arguments.spec#";
        }
        
        if (arguments.reload) {
            local.urlParams &= "&reload=true";
        }
        
        if (arguments.breakOnFailure) {
            local.urlParams &= "&breakOnFailure=true";
        }
        
        // Send command to TestBox
        print.line("Running #arguments.type# tests in debug mode...");
        if (len(trim(arguments.spec))) {
            print.line("Test spec: #arguments.spec#");
        }
        print.line();
        
        // Call the test command with debug parameters
        local.result = $sendToCliCommand(urlstring="&command=test#local.urlParams#");
        
        // Output detailed results
        if (structKeyExists(local.result, "testResults")) {
            print.boldYellowLine("Debug Results:");
            print.line();
            
            if (isStruct(local.result.testResults) && structKeyExists(local.result.testResults, "TEST_RESULTS")) {
                local.testData = local.result.testResults.TEST_RESULTS;
                
                // Display summary
                print.boldGreenLine("SUMMARY:");
                print.yellowLine("Total Tests: #local.testData.TOTALSPECS#");
                print.greenLine("Passed: #local.testData.PASSED#");
                print.redLine("Failed: #local.testData.FAILED#");
                print.yellowLine("Errors: #local.testData.ERRORS#");
                print.yellowLine("Skipped: #local.testData.SKIPPED#");
                print.yellowLine("Duration: #local.testData.DURATION# ms");
                print.line();
                
                // Display failures with detailed information
                if (local.testData.FAILED > 0 && structKeyExists(local.testData, "FAILURES") && arrayLen(local.testData.FAILURES) > 0) {
                    print.boldRedLine("FAILURES:");
                    print.line();
                    
                    for (local.failure in local.testData.FAILURES) {
                        print.redLine("Test: #local.failure.name#");
                        print.yellowLine("Message: #local.failure.message#");
                        
                        if (structKeyExists(local.failure, "tagContext") && arrayLen(local.failure.tagContext) > 0) {
                            print.yellowLine("Stack Trace:");
                            for (local.i = 1; local.i <= min(arrayLen(local.failure.tagContext), 5); local.i++) {
                                local.trace = local.failure.tagContext[local.i];
                                print.line("  Line #local.trace.line#: #local.trace.template#");
                            }
                        }
                        
                        print.line();
                    }
                }
            } else {
                print.line(serializeJSON(local.result.testResults));
            }
        } else {
            print.boldRedLine("Debug results not available. Make sure TestBox is properly configured.");
        }
        
        print.line();
    }
}