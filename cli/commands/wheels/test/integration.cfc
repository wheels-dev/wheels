/**
 * Run integration tests only
 * 
 * This is a wrapper for TestBox CLI that runs tests in the tests/integration directory.
 * Install TestBox CLI first: box install commandbox-testbox-cli
 * 
 * Examples:
 * wheels test:integration
 * wheels test:integration --reporter=spec
 * wheels test:integration --filter=UserWorkflowTest
 */
component aliases='wheels test:integration' extends="../base" {
    
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
     * @directory.hint Integration test directory (default: tests/integration)
     */
    function run(
        string reporter = "simple",
        boolean verbose = false,
        boolean failFast = false,
        string bundles = "",
        string labels = "",
        string excludes = "",
        string filter = "",
        string directory = "tests/integration"
    ) {
        detailOutput.header("🔗", "Running integration tests");
        
        // Check if TestBox CLI is installed
        if (!isTestBoxCLIInstalled()) {
            error("TestBox CLI is not installed. Please run: box install commandbox-testbox-cli");
            return;
        }
        
        // Check if integration test directory exists
        var integrationTestPath = fileSystemUtil.resolvePath(arguments.directory);
        if (!directoryExists(integrationTestPath)) {
            print.yellowLine("Integration test directory not found: #arguments.directory#");
            print.line("Creating directory structure...");
            directoryCreate(integrationTestPath, true);
            
            // Create a sample integration test
            createSampleIntegrationTest(integrationTestPath);
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
        print.line("Executing: testbox run for integration tests");
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
     * Create a sample integration test file
     */
    private void function createSampleIntegrationTest(required string directory) {
        var sampleTest = 'component extends="testbox.system.BaseSpec" {
    
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
        print.greenLine("Created sample integration test: #testPath#");
    }
}