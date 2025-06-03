/**
 * Run Wheels application tests
 * Examples:
 * wheels test run
 * wheels test run --filter=UserTest --coverage
 * wheels test run --group=integration --reporter=junit
 */
component extends="wheels-cli.models.BaseCommand" {
    
    /**
     * @filter.hint Filter tests by name pattern
     * @group.hint Run specific test group (unit, integration, models, controllers)
     * @coverage.hint Generate coverage report
     * @reporter.hint Test reporter format (console, junit, json, tap)
     * @reporter.options console,junit,json,tap
     * @watch.hint Watch for file changes and rerun tests
     * @verbose.hint Verbose output
     * @fail-fast.hint Stop on first test failure
     */
    function run(
        string filter = "",
        string group = "",
        boolean coverage = false,
        string reporter = "console",
        boolean watch = false,
        boolean verbose = false,
        boolean "fail-fast" = false
    ) {
        // Validate we're in a Wheels project
        if (!isWheelsProject()) {
            error("This command must be run from the root of a Wheels application.");
            return;
        }
        
        if (arguments.watch) {
            return runWithWatch(argumentCollection = arguments);
        }
        
        var result = runTests(argumentCollection = arguments);
        
        // Display results
        if (result.success) {
            print.greenBoldLine("✓ All tests passed!");
            print.line("#result.totalTests# tests, #result.totalPassed# passed, #result.totalFailed# failed");
        } else {
            print.redBoldLine("✗ Some tests failed");
            print.line("#result.totalTests# tests, #result.totalPassed# passed, #result.totalFailed# failed");
            setExitCode(1);
        }
        
        if (arguments.coverage && structKeyExists(result, "coverage")) {
            displayCoverageReport(result.coverage);
        }
    }
    
    private function runTests(argumentCollection) {
        print.yellowLine("🧪 Running tests...")
             .line();
        
        var testboxPath = fileSystemUtil.resolvePath("tests/runner.cfm");
        if (!fileExists(testboxPath)) {
            // Create a basic runner if it doesn't exist
            createTestRunner();
        }
        
        // Build test URL
        var serverInfo = getServerInfo();
        var testURL = serverInfo.serverURL & "/tests/runner.cfm?";
        
        // Add parameters
        var params = [];
        if (len(arguments.filter)) {
            arrayAppend(params, "testBundles=#arguments.filter#");
        }
        if (len(arguments.group)) {
            arrayAppend(params, "testSuites=#arguments.group#");
        }
        if (arguments.reporter != "console") {
            arrayAppend(params, "reporter=#arguments.reporter#");
        }
        if (arguments.coverage) {
            arrayAppend(params, "coverage=true");
        }
        
        testURL &= arrayToList(params, "&");
        
        // Run tests
        try {
            var httpResult = new Http(url=testURL, timeout=300).send().getPrefix();
            
            if (isJSON(httpResult.filecontent)) {
                return deserializeJSON(httpResult.filecontent);
            } else {
                // Parse HTML output for console reporter
                return parseConsoleOutput(httpResult.filecontent);
            }
        } catch (any e) {
            print.redLine("Error running tests: #e.message#");
            return {
                success = false,
                totalTests = 0,
                totalPassed = 0,
                totalFailed = 0,
                error = e.message
            };
        }
    }
    
    private function runWithWatch(argumentCollection) {
        print.yellowLine("👀 Watching for file changes... (Press Ctrl+C to stop)")
             .line();
        
        var fileWatcher = getInstance("FileWatcher@commandbox-core");
        var watchPaths = ["models/**", "controllers/**", "tests/**", "views/**"];
        
        // Run tests initially
        runTests(argumentCollection = arguments);
        
        fileWatcher.watch(
            paths = watchPaths,
            callback = function() {
                print.line()
                     .cyanLine("📝 Files changed, running tests...")
                     .line();
                runTests(argumentCollection = arguments);
            }
        );
    }
    
    private function displayCoverageReport(coverage) {
        print.line()
             .yellowBoldLine("📊 Coverage Report:")
             .line();
        
        if (isStruct(arguments.coverage)) {
            print.line("Overall Coverage: #arguments.coverage.percentage#%");
            
            if (structKeyExists(arguments.coverage, "files")) {
                print.line()
                     .line("File Coverage:");
                for (var file in arguments.coverage.files) {
                    var fileCoverage = arguments.coverage.files[file];
                    var indicator = fileCoverage.percentage >= 80 ? "✓" : "⚠";
                    print.line("  #indicator# #file#: #fileCoverage.percentage#%");
                }
            }
        }
    }
    
    private function parseConsoleOutput(html) {
        // Basic parsing of HTML test output
        var result = {
            success = true,
            totalTests = 0,
            totalPassed = 0,
            totalFailed = 0
        };
        
        // Look for test summary in HTML
        if (findNoCase("failed", arguments.html)) {
            result.success = false;
        }
        
        // Extract numbers from common test output patterns
        var testPattern = "(\d+)\s+test[s]?";
        var passPattern = "(\d+)\s+pass(ed)?";
        var failPattern = "(\d+)\s+fail(ed)?";
        
        var testMatch = reFind(testPattern, arguments.html, 1, true);
        if (arrayLen(testMatch.match) > 1) {
            result.totalTests = val(testMatch.match[2]);
        }
        
        var passMatch = reFind(passPattern, arguments.html, 1, true);
        if (arrayLen(passMatch.match) > 1) {
            result.totalPassed = val(passMatch.match[2]);
        }
        
        var failMatch = reFind(failPattern, arguments.html, 1, true);
        if (arrayLen(failMatch.match) > 1) {
            result.totalFailed = val(failMatch.match[2]);
        }
        
        return result;
    }
    
    private function createTestRunner() {
        var runnerContent = '<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Test Runner</title>
</head>
<body>
    <cfscript>
        // Create TestBox instance
        testbox = new testbox.system.TestBox();
        
        // Run tests
        param name="url.testBundles" default="";
        param name="url.testSuites" default="";
        param name="url.reporter" default="simple";
        param name="url.coverage" default="false";
        
        options = {
            reporter = url.reporter
        };
        
        if (len(url.testBundles)) {
            options.bundles = url.testBundles;
        }
        
        if (len(url.testSuites)) {
            options.testSuites = url.testSuites;
        }
        
        if (url.coverage) {
            options.coverage = {
                enabled = true,
                pathToCapture = "/models,/controllers"
            };
        }
        
        results = testbox.run(argumentCollection = options);
        
        // Output results
        if (url.reporter == "json") {
            content type="application/json";
            writeOutput(serializeJSON({
                success = results.getTotalFail() == 0,
                totalTests = results.getTotalSpecs(),
                totalPassed = results.getTotalPass(),
                totalFailed = results.getTotalFail(),
                coverage = isBoolean(url.coverage) && url.coverage ? results.getCoverageData() : {}
            }));
        } else {
            writeOutput(results.getResultsOutput());
        }
    </cfscript>
</body>
</html>';
        
        var runnerPath = fileSystemUtil.resolvePath("tests/runner.cfm");
        var runnerDir = getDirectoryFromPath(runnerPath);
        
        if (!directoryExists(runnerDir)) {
            directoryCreate(runnerDir, true);
        }
        
        fileWrite(runnerPath, runnerContent);
        print.yellowLine("Created test runner at: #runnerPath#");
    }
}