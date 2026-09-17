/**
 * Run Wheels application tests
 * Examples:
 * wheels test run
 * wheels test run UserTest
 * wheels test run type=core
 * wheels test run --verbose --debug
 * wheels test run filter="User*" --coverage
 */
component extends="../base" {
    
    property name="detailOutput" inject="DetailOutputService@wheels-cli";
    
    /**
     * @type.hint Type of tests to run: (app, core)
     * @recurse.hint Recurse into subdirectories
     * @reporter.hint Test reporter format (text, json, junit, tap, antjunit)
     * @verbose.hint Verbose output
     * @servername.hint Name of server to use
     * @filter.hint Filter tests by pattern or name
     * @lables.hint Run specific test lables
     * @coverage.hint Generate coverage report (boolean flag)
     */
    function run(
        string type = "app",
        string format = "txt",
        string bundles = "",
        string directory = "",
        boolean recurse = true,
        boolean verbose = true,
        string servername = "",
        string filter = "",
        string lables = "",
        boolean coverage = false,
        string reporter = "",
    ) {
        requireWheelsApp(getCWD());
        error("DEPRECATED: CommandBox `wheels test run` is frozen and does not fail-closed. Use the LuCLI `wheels` binary (`wheels test`). Removal scheduled for Wheels 5.0. See cli/src/README.md.");
        return;
    }

}