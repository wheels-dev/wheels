/**
 * Run integration tests only
 * 
 * This command runs tests in the tests/integration directory using the Wheels test runner.
 * 
 * Examples:
 * wheels test:integration
 * wheels test:integration --format=json
 * wheels test:integration --filter=UserWorkflowTest
 */
component aliases='wheels test:integration' extends="../base" {
    
    /**
     * @type.hint Type of tests to run: (app, core, plugin)
     * @format.hint Output format (txt, json, junit, html)
     * @format.options txt,json,junit,html
     * @verbose.hint Verbose output
     * @failFast.hint Stop on first test failure
     * @bundles.hint Comma-delimited list of test bundles to run
     * @labels.hint Comma-delimited list of test labels to run
     * @excludes.hint Comma-delimited list of test labels to exclude
     * @filter.hint Test filter pattern
     * @directory.hint Integration test directory (default: tests/integration)
     * @servername.hint Name of server to use
     */
    function run(
        string type = "app",
        string format = "txt",
        boolean verbose = false,
        boolean failFast = false,
        string bundles = "",
        string labels = "",
        string excludes = "",
        string filter = "",
        string directory = "integration",
        string servername = ""
    ) {
        arguments = reconstructArgs(arguments);
        arguments.directory = resolveTestDirectory(arguments.type, arguments.directory);
        
        // Validate we're in a Wheels project
        if (!isWheelsApp()) {
            error("This command must be run from the root of a Wheels application.");
        }
        
        // Check if integration test directory exists, create if not
        var integrationTestPath = fileSystemUtil.resolvePath(arguments.directory);
        if (!directoryExists(integrationTestPath)) {
            directoryCreate(integrationTestPath, true, true);
            createSampleIntegrationTest(integrationTestPath);
        }
        
        // Build the test URL
        var testUrl = buildTestUrl(
            type = arguments.type,
            servername = arguments.servername,
            format = arguments.format
        );
        
        // Add fail-fast parameter if specified
        if (arguments.failFast) {
            testUrl &= "&bail=true";
        }
        
        // Build TestBox command parameters
        var params = {
            runner = testUrl,
            directory = arguments.directory,
            recurse = true,
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
     * Create a sample integration test file
     */
    private void function createSampleIntegrationTest(required string directory) {
        var sampleTest = 'component extends="wheels.Testbox" {
    
    function beforeAll() {
        // Setup test database or test data
        // This runs once before all tests in this suite
    }
    
    function afterAll() {
        // Cleanup test data
        // This runs once after all tests in this suite
    }
    
    function run() {
        describe("Sample Integration Test", function() {
            
            beforeEach(function() {
                // Setup before each test
                // e.g., start a transaction
            });
            
            afterEach(function() {
                // Cleanup after each test
                // e.g., rollback transaction
            });
            
            it("should test a complete user workflow", function() {
                // Integration tests typically test multiple components working together
                
                // Example: Test user registration flow
                var userData = {
                    name: "Test User",
                    email: "test@example.com",
                    password: "testpass123"
                };
                
                // This would normally call your actual application code
                // var user = createUser(userData);
                // expect(user).toBeStruct();
                // expect(user.id).toBeGT(0);
                
                // For now, just a placeholder assertion
                expect(true).toBe(true);
            });
            
            it("should test database interactions", function() {
                // Integration tests often involve real database operations
                
                // Example: Test that a model can save and retrieve data
                // var testData = { name: "Integration Test" };
                // var saved = model("TestModel").create(testData);
                // var retrieved = model("TestModel").findByKey(saved.id);
                // expect(retrieved.name).toBe(testData.name);
                
                // Placeholder assertion
                expect("database").toInclude("data");
            });
            
            it("should test API endpoints", function() {
                // Integration tests can test full request/response cycles
                
                // Example: Test API endpoint
                // var http = new Http(url="http://localhost/api/users", method="GET");
                // var response = http.send().getPrefix();
                // expect(response.status_code).toBe(200);
                // expect(isJSON(response.filecontent)).toBeTrue();
                
                // Placeholder assertion
                expect("api").toHaveLength(3);
            });
        });
    }
}';
        
        var testPath = arguments.directory & "/SampleIntegrationTest.cfc";
        fileWrite(testPath, sampleTest);
    }
}