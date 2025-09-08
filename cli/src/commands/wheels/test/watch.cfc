/**
 * Watch for file changes and automatically rerun tests
 * 
 * This command watches for file changes and reruns tests using the Wheels test runner.
 * 
 * Examples:
 * wheels test:watch
 * wheels test:watch --directory=tests/unit
 * wheels test:watch --format=json --delay=500
 */
component aliases='wheels test:watch' extends="../base" {
    
    /**
     * @type.hint Type of tests to run: (app, core, plugin)
     * @directory.hint Test directory to watch (default: tests/specs)
     * @format.hint Output format (txt, json, junit, html)
     * @format.options txt,json,junit,html
     * @verbose.hint Verbose output
     * @delay.hint Delay in milliseconds before rerunning tests (default: 1000)
     * @watchPaths.hint Additional paths to watch (comma-separated)
     * @excludePaths.hint Paths to exclude from watching (comma-separated)
     * @bundles.hint Comma-delimited list of test bundles to run
     * @labels.hint Comma-delimited list of test labels to run
     * @excludes.hint Comma-delimited list of test labels to exclude
     * @filter.hint Test filter pattern
     * @servername.hint Name of server to use
     */
    function run(
        string type = "app",
        string directory = "tests/specs",
        string format = "txt",
        boolean verbose = false,
        numeric delay = 1000,
        string watchPaths = "",
        string excludePaths = "",
        string bundles = "",
        string labels = "",
        string excludes = "",
        string filter = "",
        string servername = ""
    ) {
        arguments = reconstructArgs(arguments);
        
        // Validate we're in a Wheels project
        if (!isWheelsApp()) {
            error("This command must be run from the root of a Wheels application.");
        }
        
        print.line("========================================");
        print.boldLine("Starting Test Watcher");
        print.line("========================================");
        print.line();
        print.yellowLine("Watching for file changes...");
        print.line("Press Ctrl+C to stop watching");
        print.line();
        
        // Build the test URL
        var testUrl = buildTestUrl(
            type = arguments.type,
            servername = arguments.servername,
            format = arguments.format
        );
        
        // Build TestBox watch command parameters
        var params = {
            runner = testUrl,
            directory = arguments.directory,
            delay = arguments.delay,
            verbose = arguments.verbose
        };
        
        // Add additional watch paths if specified
        if (len(arguments.watchPaths)) {
            params.paths = arguments.watchPaths;
        }
        
        // Add exclude paths if specified
        if (len(arguments.excludePaths)) {
            params.excludePaths = arguments.excludePaths;
        }
        
        // Add optional filtering parameters
        if (len(arguments.bundles)) {
            params.bundles = arguments.bundles;
        }
        
        if (len(arguments.labels)) {
            params.labels = arguments.labels;
        }
        
        if (len(arguments.excludes)) {
            params.excludes = arguments.excludes;
        }
        
        if (len(arguments.filter)) {
            // Handle filter parameter
            if (reFindNoCase("Test$", arguments.filter)) {
                params.testBundles = arguments.filter;
            } else {
                params.testSpecs = arguments.filter;
            }
        }
        
        // Show watching configuration
        print.line("Configuration:");
        print.line("  Type: #arguments.type# tests");
        print.line("  Directory: #arguments.directory#");
        print.line("  Format: #arguments.format#");
        print.line("  Delay: #arguments.delay#ms");
        
        if (len(arguments.watchPaths)) {
            print.line("  Additional paths: #arguments.watchPaths#");
        }
        
        if (len(arguments.excludePaths)) {
            print.line("  Excluded paths: #arguments.excludePaths#");
        }
        
        if (len(arguments.filter)) {
            print.line("  Filter: #arguments.filter#");
        }
        
        if (len(arguments.labels)) {
            print.line("  Labels: #arguments.labels#");
        }
        
        print.line();
        print.line("Executing: testbox watch");
        print.line();
        
        try {
            // Execute TestBox watch command
            command('testbox watch').params(argumentCollection=params).run();
        } catch (any e) {
            // Handle interruption gracefully
            if (findNoCase("interrupted", e.message) || findNoCase("ctrl", e.message)) {
                print.line();
                print.yellowLine("Watch mode stopped by user");
            } else {
                print.redLine("Error in watch mode: #e.message#");
            }
        }
    }
}