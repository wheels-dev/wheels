/**
 * Run unit tests only
 * 
 * This is a wrapper for TestBox CLI that runs tests in the tests/unit directory.
 * Install TestBox CLI first: box install commandbox-testbox-cli
 * 
 * Examples:
 * wheels test:unit
 * wheels test:unit --reporter=spec
 * wheels test:unit --filter=UserTest
 */
component aliases='wheels test:unit' extends="../base" {
    
    property name="detailOutput" inject="DetailOutputService@wheels-cli";
    
    /**
     * @reporter.hint Test reporter format (simple, spec, junit, json, tap, min, doc)
     * @reporter.options simple,spec,junit,json,tap,min,doc
     * @verbose.hint Verbose output
     * @failFast.hint Stop on first test failure
     * @bundles.hint Comma-delimited list of test bundles to run
     * @labels.hint Comma-delimited list of test labels to run
     * @excludes.hint Comma-delimited list of test bundles to exclude
     * @filter.hint Test filter pattern
     * @directory.hint Unit test directory (default: tests/unit)
     */
    function run(
        string reporter = "simple",
        boolean verbose = false,
        boolean failFast = false,
        string bundles = "",
        string labels = "",
        string excludes = "",
        string filter = "",
        string directory = "tests/unit"
    ) {
        detailOutput.header("🧪", "Running unit tests");
        
        // Check if TestBox CLI is installed
        if (!isTestBoxCLIInstalled()) {
            error("TestBox CLI is not installed. Please run: box install commandbox-testbox-cli");
            return;
        }
        
        // Check if unit test directory exists
        var unitTestPath = fileSystemUtil.resolvePath(arguments.directory);
        if (!directoryExists(unitTestPath)) {
            print.yellowLine("Unit test directory not found: #arguments.directory#");
            print.line("Creating directory structure...");
            directoryCreate(unitTestPath, true);
            
            // Create a sample unit test
            createSampleUnitTest(unitTestPath);
        }
        
        // Build TestBox command parameters
        var params = {
            directory = arguments.directory,
            reporter = arguments.reporter,
            recurse = true
        };
        
        // Add optional parameters
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
            params.filter = arguments.filter;
        }
        
        if (arguments.verbose) {
            params.verbose = true;
        }
        
        if (arguments.failFast) {
            params.failfast = true;
        }
        
        // Execute TestBox command
        print.line("Executing: testbox run for unit tests");
        print.line();
        
        command('testbox run').params(argumentCollection=params).run();
    }
    
    /**
     * Check if TestBox CLI is installed
     */
    private boolean function isTestBoxCLIInstalled() {
        try {
            // Try to run testbox help command
            var result = command("testbox help").run(returnOutput=true);
            return true;
        } catch (any e) {
            return false;
        }
    }
    
    /**
     * Create a sample unit test file
     */
    private void function createSampleUnitTest(required string directory) {
        var sampleTest = 'component extends="testbox.system.BaseSpec" {
    
    function run() {
        describe("Sample Unit Test", function() {
            it("should pass this example test", function() {
                expect(true).toBe(true);
            });
            
            it("should demonstrate basic assertions", function() {
                var result = 2 + 2;
                expect(result).toBe(4);
                expect(result).toBeNumeric();
                expect(result).toBeGT(3);
            });
        });
    }
}';
        
        var testPath = arguments.directory & "/SampleUnitTest.cfc";
        fileWrite(testPath, sampleTest);
        print.greenLine("Created sample unit test: #testPath#");
    }
}