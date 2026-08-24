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
    
    property name="detailOutput" inject="DetailOutputService@wheels-cli";
    
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
        error("DEPRECATED: CommandBox `wheels test:watch` is frozen and does not fail-closed. Use the LuCLI `wheels` binary (`wheels test`). Removal scheduled for Wheels 5.0. See cli/src/README.md.");
        return;
    }
}