/**
 * Base test case for Wheels applications
 * Provides helper methods and setup for testing
 */
component extends="testbox.system.BaseSpec" {
    
    /**
     * Setup before all tests
     */
    function beforeAll() {
        // Set test environment
        request.wheels.testMode = true;
        
        // Initialize test database transaction
        if (structKeyExists(application, "wheels") && structKeyExists(application.wheels, "transactionMode")) {
            application.wheels.transactionMode = "rollback";
        }
    }
    
    /**
     * Setup before each test
     */
    function beforeEach() {
        // Start a new transaction for each test
        if (isDefined("transaction")) {
            transaction action="begin";
        }
    }
    
    /**
     * Teardown after each test
     */
    function afterEach() {
        // Rollback transaction to keep database clean
        if (isDefined("transaction")) {
            transaction action="rollback";
        }
    }
    
    /**
     * Process a controller request for testing
     */
    function processRequest(
        required string controller,
        required string action,
        string method = "GET",
        struct params = {},
        struct session = {},
        struct cookies = {}
    ) {
        var result = {
            status = 200,
            headers = {},
            cookies = {},
            session = arguments.session
        };
        
        // Set up request context
        request.wheels.params = {
            controller = arguments.controller,
            action = arguments.action
        };
        
        // Merge additional params
        structAppend(request.wheels.params, arguments.params);
        
        // Set request method
        request.requestMethod = arguments.method;
        
        try {
            // Get controller instance
            var controllerInstance = application.wheels.controller(arguments.controller);
            
            // Process the action
            controllerInstance.processAction();
            
            // Get response data
            result.status = controllerInstance.response.status ?: 200;
            result.headers = controllerInstance.response.headers ?: {};
            
            // Get view variables
            var viewVariables = controllerInstance.variables();
            structAppend(result, viewVariables);
            
        } catch (any e) {
            result.status = 500;
            result.error = e;
        }
        
        return result;
    }
    
    /**
     * Create a test model instance
     */
    function createTestModel(required string modelName, struct properties = {}) {
        return model(arguments.modelName).create(arguments.properties);
    }
    
    /**
     * Clean up test data for a model
     */
    function cleanupTestData(required string modelName) {
        model(arguments.modelName).deleteAll(reload=true);
    }
    
    /**
     * Get a model instance
     */
    function model(required string name) {
        return application.wheels.model(arguments.name);
    }
}