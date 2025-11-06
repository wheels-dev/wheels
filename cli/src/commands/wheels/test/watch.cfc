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
     * @bundles.hint Comma-delimited list of test bundles to run
     * @labels.hint Comma-delimited list of test labels to run
     * @excludes.hint Comma-delimited list of test labels to exclude
     * @filter.hint Test filter pattern
     * @servername.hint Name of server to use
     */
    function run(
        string type = "app",
        string directory = "",
        string format = "txt",
        boolean verbose = false,
        numeric delay = 1000,
        string bundles = "",
        string labels = "",
        string excludes = "",
        string filter = "",
        string servername = ""
    ) {
        requireWheelsApp(getCWD());
        arguments = reconstructArgs(
            argStruct=arguments,
            allowedValues={
                type=["app", "core", "plugin"],
                format=["txt", "json", "junit", "html"]
            },
            numericRanges={
                delay={min=100, max=60000}
            }
        );
        arguments.directory = resolveTestDirectory(arguments.type, arguments.directory);
        
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