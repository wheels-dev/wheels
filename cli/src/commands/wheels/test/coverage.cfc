/**
 * Generate code coverage reports for tests
 * 
 * This command runs tests with code coverage enabled using FusionReactor.
 * FusionReactor must be installed with code coverage enabled.
 * 
 * Examples:
 * wheels test:coverage
 * wheels test:coverage filter="User*" --verbose
 */
component aliases='wheels test:coverage' extends="../base" {
    
    property name="detailOutput" inject="DetailOutputService@wheels-cli";
    
    /**
     * @type.hint Type of tests to run: (app, core, plugin)
     * @directory.hint Test directory to run (default: tests/specs)
     * @outputDir.hint Directory to output the report (relative to project root)
     * @threshold.hint Coverage percentage threshold (0-100)
     * @pathsToCapture.hint Paths to capture for coverage (default: /app)
     * @whitelist.hint Whitelist paths for coverage (default: *.cfc)
     * @blacklist.hint Blacklist paths from coverage (default: *Test.cfc,*Spec.cfc)
     * @bundles.hint Comma-delimited list of test bundles to run
     * @labels.hint Comma-delimited list of test labels to run
     * @excludes.hint Comma-delimited list of test labels to exclude
     * @filter.hint Test filter pattern
     * @verbose.hint Verbose output
     * @servername.hint Name of server to use
     * @outputFile.hint Base name for output files (default: test-results-coverage)
     */
    function run(
        string type = "app",
        string format = "txt",
        string directory = "tests/specs",
        string outputDir = "tests/results/coverage",
        numeric threshold = 0,
        string pathsToCapture = "/app",
        string whitelist = "*.cfc",
        string blacklist = "*Test.cfc,*Spec.cfc",
        string bundles = "",
        string labels = "",
        string excludes = "",
        string filter = "",
        boolean verbose = true,
        string servername = "",
        string outputFile = "test-results-coverage"
    ) {
        requireWheelsApp(getCWD());
        error("DEPRECATED: CommandBox `wheels test:coverage` is frozen and does not fail-closed. Use the LuCLI `wheels` binary (`wheels test`). Removal scheduled for Wheels 5.0. See cli/src/README.md.");
        return;
    }
    
}