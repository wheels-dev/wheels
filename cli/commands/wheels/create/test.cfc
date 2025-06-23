/**
 * Create test files
 */
component extends="../base" {
    
    property name="snippetService" inject="SnippetService@wheelscli";
    
    /**
     * Create test files for models, controllers, or helpers
     * 
     * @type Type of test to create (model, controller, view, helper, integration)
     * @name Name of the component to test
     * @methods Comma-delimited list of methods to test
     * @force Overwrite existing test files
     * @help Generate test files for your Wheels components
     * 
     * Examples:
     * wheels create test model User
     * wheels create test controller Posts
     * wheels create test integration UserRegistration
     */
    function run(
        required string type,
        required string name,
        string methods = "",
        boolean force = false
    ) {
        ensureWheelsProject();
        
        // Validate test type
        if (!listFindNoCase("model,controller,view,helper,integration", arguments.type)) {
            error("Invalid test type. Valid types are: model, controller, view, helper, integration");
        }
        
        print.line();
        print.boldBlueLine("Creating #arguments.type# test: #arguments.name#");
        
        // Create test file based on type
        switch(arguments.type) {
            case "model":
                createModelTest(arguments.name, arguments.methods, arguments.force);
                break;
            case "controller":
                createControllerTest(arguments.name, arguments.methods, arguments.force);
                break;
            case "view":
                createViewTest(arguments.name, arguments.methods, arguments.force);
                break;
            case "helper":
                createHelperTest(arguments.name, arguments.methods, arguments.force);
                break;
            case "integration":
                createIntegrationTest(arguments.name, arguments.methods, arguments.force);
                break;
        }
        
        print.line();
        print.boldLine("Next steps:");
        print.indentedLine("1. Implement your test cases");
        print.indentedLine("2. Run tests with 'wheels test all' or 'box testbox run'");
        print.indentedLine("3. Run specific test with 'box testbox run --testBundles=tests.specs.#arguments.type#.#arguments.name#Test'");
    }
    
    /**
     * Create model test
     */
    private function createModelTest(name, methods, force) {
        var testPath = getCWD() & "/tests/specs/models/";
        var testFile = testPath & arguments.name & "Test.cfc";
        
        if (!directoryExists(testPath)) {
            directoryCreate(testPath, true);
        }
        
        if (fileExists(testFile) && !arguments.force) {
            if (!confirm("Test file '#arguments.name#Test' already exists. Overwrite?")) {
                print.yellowLine("Test creation cancelled.");
                return;
            }
        }
        
        var methodList = len(arguments.methods) ? listToArray(arguments.methods) : [];
        
        var testContent = generateModelTestContent(arguments.name, methodList);
        fileWrite(testFile, testContent);
        
        print.greenLine("✓ Created test: tests/specs/models/#arguments.name#Test.cfc");
    }
    
    /**
     * Create controller test
     */
    private function createControllerTest(name, methods, force) {
        var testPath = getCWD() & "/tests/specs/controllers/";
        var testFile = testPath & arguments.name & "Test.cfc";
        
        if (!directoryExists(testPath)) {
            directoryCreate(testPath, true);
        }
        
        if (fileExists(testFile) && !arguments.force) {
            if (!confirm("Test file '#arguments.name#Test' already exists. Overwrite?")) {
                print.yellowLine("Test creation cancelled.");
                return;
            }
        }
        
        var methodList = len(arguments.methods) ? listToArray(arguments.methods) : 
                         ["index", "show", "new", "create", "edit", "update", "delete"];
        
        var testContent = generateControllerTestContent(arguments.name, methodList);
        fileWrite(testFile, testContent);
        
        print.greenLine("✓ Created test: tests/specs/controllers/#arguments.name#Test.cfc");
    }
    
    /**
     * Generate model test content
     */
    private function generateModelTestContent(name, methods) {
        var modelLower = lCase(arguments.name);
        var modelPlural = pluralize(arguments.name);
        
        // Generate method tests if any
        var methodTests = "";
        for (var method in arguments.methods) {
            methodTests &= '
            
            describe("##' & method & '()", function() {
                it("should ' & method & ' correctly", function() {
                    // Test ' & method & ' method
                });
            });';
        }
        
        var content = snippetService.getSnippet("test", "model.cfc");
        return snippetService.render(content, {
            MODEL_NAME = arguments.name,
            MODEL_LOWER = modelLower,
            TABLE_NAME = lCase(modelPlural),
            GENERATED_DATE = dateTimeFormat(now(), "yyyy-mm-dd HH:nn:ss"),
            METHOD_TESTS = methodTests
        });
    }
    
    /**
     * Generate controller test content
     */
    private function generateControllerTestContent(name, methods) {
        var controllerLower = lCase(arguments.name);
        var modelName = singularize(arguments.name);
        var modelLower = lCase(modelName);
        
        // Generate method tests
        var methodTests = "";
        for (var method in arguments.methods) {
            methodTests &= generateControllerMethodTest(arguments.name, method, modelName);
        }
        
        var content = snippetService.getSnippet("test", "controller.cfc");
        return snippetService.render(content, {
            CONTROLLER_NAME = arguments.name,
            MODEL_NAME = modelName,
            GENERATED_DATE = dateTimeFormat(now(), "yyyy-mm-dd HH:nn:ss"),
            METHOD_TESTS = methodTests
        });
    }
    
    /**
     * Generate test for controller method
     */
    private function generateControllerMethodTest(controller, method, model) {
        var methodContent = "";
        
        switch(arguments.method) {
            case "index":
                methodContent = '
                it("should return a list of ' & lCase(pluralize(model)) & '", function() {
                    var result = processRequest(controller="' & controller & '", action="' & method & '");
                    
                    expect(result.status).toBe(200);
                    expect(result).toHaveKey("' & lCase(pluralize(model)) & '");
                    expect(result.' & lCase(pluralize(model)) & ').toBeQuery();
                });';
                break;
                
            case "show":
                methodContent = '
                it("should return a single ' & lCase(model) & '", function() {
                    var result = processRequest(
                        controller="' & controller & '", 
                        action="' & method & '",
                        params={key=test' & model & '.id}
                    );
                    
                    expect(result.status).toBe(200);
                    expect(result).toHaveKey("' & lCase(model) & '");
                });
                
                it("should return 404 for non-existent ' & lCase(model) & '", function() {
                    var result = processRequest(
                        controller="' & controller & '", 
                        action="' & method & '",
                        params={key=0}
                    );
                    
                    expect(result.status).toBe(404);
                });';
                break;
                
            case "new":
                methodContent = '
                it("should display the new ' & lCase(model) & ' form", function() {
                    var result = processRequest(controller="' & controller & '", action="' & method & '");
                    
                    expect(result.status).toBe(200);
                    expect(result).toHaveKey("' & lCase(model) & '");
                    expect(result.' & lCase(model) & '.id).toBeEmpty();
                });';
                break;
                
            case "create":
                methodContent = '
                it("should create a new ' & lCase(model) & ' with valid data", function() {
                    var initialCount = model("' & model & '").count();
                    
                    var result = processRequest(
                        controller="' & controller & '", 
                        action="' & method & '",
                        method="POST",
                        params={
                            ' & lCase(model) & '={
                                // Add valid properties
                            }
                        }
                    );
                    
                    expect(model("' & model & '").count()).toBe(initialCount + 1);
                    expect(result.status).toBe(302); // Redirect on success
                });
                
                it("should not create ' & lCase(model) & ' with invalid data", function() {
                    var initialCount = model("' & model & '").count();
                    
                    var result = processRequest(
                        controller="' & controller & '", 
                        action="' & method & '",
                        method="POST",
                        params={
                            ' & lCase(model) & '={
                                // Add invalid properties
                            }
                        }
                    );
                    
                    expect(model("' & model & '").count()).toBe(initialCount);
                    expect(result.' & lCase(model) & '.hasErrors()).toBeTrue();
                });';
                break;
                
            default:
                methodContent = '
                it("should handle ' & method & ' action", function() {
                    // Test ' & method & ' action
                });';
        }
        
        var content = snippetService.getSnippet("test", "controller-method.cfc");
        return snippetService.render(content, {
            METHOD = method,
            METHOD_CONTENT = methodContent
        });
    }
    
    /**
     * Create view test
     */
    private function createViewTest(name, methods, force) {
        var testPath = getCWD() & "/tests/specs/views/";
        var testFile = testPath & arguments.name & "ViewTest.cfc";
        
        if (!directoryExists(testPath)) {
            directoryCreate(testPath, true);
        }
        
        if (fileExists(testFile) && !arguments.force) {
            if (!confirm("Test file '#arguments.name#ViewTest' already exists. Overwrite?")) {
                print.yellowLine("Test creation cancelled.");
                return;
            }
        }
        
        var testContent = snippetService.getSnippet("test", "view.cfc");
        testContent = snippetService.render(testContent, {
            NAME = arguments.name,
            GENERATED_DATE = dateTimeFormat(now(), "yyyy-mm-dd HH:nn:ss")
        });
        
        fileWrite(testFile, testContent);
        print.greenLine("✓ Created test: tests/specs/views/#arguments.name#ViewTest.cfc");
    }
    
    /**
     * Create helper test
     */
    private function createHelperTest(name, methods, force) {
        var testPath = getCWD() & "/tests/specs/helpers/";
        var testFile = testPath & arguments.name & "Test.cfc";
        
        if (!directoryExists(testPath)) {
            directoryCreate(testPath, true);
        }
        
        if (fileExists(testFile) && !arguments.force) {
            if (!confirm("Test file '#arguments.name#Test' already exists. Overwrite?")) {
                print.yellowLine("Test creation cancelled.");
                return;
            }
        }
        
        var testContent = snippetService.getSnippet("test", "helper.cfc");
        testContent = snippetService.render(testContent, {
            NAME = arguments.name,
            GENERATED_DATE = dateTimeFormat(now(), "yyyy-mm-dd HH:nn:ss")
        });
        
        fileWrite(testFile, testContent);
        print.greenLine("✓ Created test: tests/specs/helpers/#arguments.name#Test.cfc");
    }
    
    /**
     * Create integration test
     */
    private function createIntegrationTest(name, methods, force) {
        var testPath = getCWD() & "/tests/specs/integration/";
        var testFile = testPath & arguments.name & "Test.cfc";
        
        if (!directoryExists(testPath)) {
            directoryCreate(testPath, true);
        }
        
        if (fileExists(testFile) && !arguments.force) {
            if (!confirm("Test file '#arguments.name#Test' already exists. Overwrite?")) {
                print.yellowLine("Test creation cancelled.");
                return;
            }
        }
        
        var testContent = snippetService.getSnippet("test", "integration.cfc");
        testContent = snippetService.render(testContent, {
            NAME = arguments.name,
            GENERATED_DATE = dateTimeFormat(now(), "yyyy-mm-dd HH:nn:ss")
        });
        
        fileWrite(testFile, testContent);
        print.greenLine("✓ Created test: tests/specs/integration/#arguments.name#Test.cfc");
    }
}