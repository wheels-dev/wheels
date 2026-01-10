/**
 * Run unit tests only
 * 
 * This command runs tests in the tests/unit directory using the Wheels test runner.
 * 
 * Examples:
 * wheels test:unit
 * wheels test:unit --format=json
 * wheels test:unit --filter=UserTest
 */
component aliases='wheels test:unit' extends="../base" {
    
    property name="detailOutput" inject="DetailOutputService@wheels-cli";
    
    /**
     * @type.hint Type of tests to run: (app, core, plugin)
     * @format.hint Output format (txt, json, junit, html)
     * @format.options txt,json,junit,html
     * @verbose.hint Verbose output
     * @bundles.hint Comma-delimited list of test bundles to run
     * @labels.hint Comma-delimited list of test labels to run
     * @excludes.hint Comma-delimited list of test labels to exclude
     * @filter.hint Test filter pattern
     * @directory.hint Unit test directory (default: tests/unit)
     * @servername.hint Name of server to use
     */
    function run(
        string type = "app",
        string format = "txt",
        boolean verbose = false,
        string bundles = "",
        string labels = "",
        string excludes = "",
        string filter = "",
        string directory = "unit",
        string servername = ""
    ) {
        requireWheelsApp(getCWD());
        arguments = reconstructArgs(
            argStruct=arguments,
            allowedValues={
                type=["app", "core", "plugin"],
                format=["txt", "json", "junit", "html"]
            }
        );
        arguments.directory = resolveTestDirectory(arguments.type, arguments.directory);
        
        // Check if unit test directory exists, create if not
        var unitTestPath = fileSystemUtil.resolvePath(arguments.directory);
        if (!directoryExists(unitTestPath)) {
            directoryCreate(unitTestPath, true, true);
            createSampleUnitTest(unitTestPath);
            detailOutput.create("unit test directory: #arguments.directory#");
        }
        
        // Build the test URL using arguments
        var testUrl = buildTestUrl(
            type = arguments.type,
            servername = arguments.servername,
            format = arguments.format
        );
        
        // Build TestBox command parameters
        var params = {
            runner = testUrl,
            directory = arguments.directory,
            recurse = true,
            verbose = arguments.verbose
        };
        
        // Add optional filtering parameters
        if (len(arguments.bundles)) {
            params.testbundles = arguments.bundles;
        }
        
        if (len(arguments.labels)) {
            params.labels = arguments.labels;
        }
        
        if (len(arguments.excludes)) {
            params.excludes = arguments.excludes;
        }
        
        if (len(arguments.filter)) {
            // Handle filter parameter - if it ends with "Test", treat as bundle
            if (reFindNoCase("Test$", arguments.filter)) {
                params.testBundles = arguments.filter;
            } else {
                params.testSpecs = arguments.filter;
            }
        }
        
        try {
            // Execute TestBox command
            command("testbox run").params(argumentCollection = params).run();
        } catch (any e) {
            // Let TestBox handle its own output and errors
            if (!findNoCase("failing exit code", e.message)) {
                rethrow;
            }
        }
    }
    
    /**
     * Create a sample unit test file
     */
    private void function createSampleUnitTest(required string directory) {
        var sampleTest = 'component extends="wheels.Testbox" {
    
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
            
            it("should show how to test a function", function() {
                // Example of testing a function
                var calculator = {
                    add: function(a, b) { return a + b; },
                    multiply: function(a, b) { return a * b; }
                };
                
                expect(calculator.add(5, 3)).toBe(8);
                expect(calculator.multiply(4, 7)).toBe(28);
            });
        });
    }
}';
        
        var testPath = arguments.directory & "/SampleUnitTest.cfc";
        fileWrite(testPath, sampleTest);
    }
}