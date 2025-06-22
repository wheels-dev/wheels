/**
 * Tests for wheels create controller command
 */
component extends="tests.BaseTestCase" {
    
    function beforeAll() {
        super.beforeAll();
        variables.commandPath = "create controller";
    }
    
    function run() {
        describe("wheels create controller", function() {
            
            beforeEach(function() {
                createTestProject();
            });
            
            it("should create a basic controller", function() {
                var result = executeCommand(commandPath, {
                    name = "Users"
                });
                
                expect(result.success).toBeTrue();
                assertFileCreated("app/controllers/Users.cfc");
                assertOutputContains("Controller created successfully");
                
                var content = fileRead(getTempDir() & "app/controllers/Users.cfc");
                expect(content).toInclude('component extends="Controller"');
                expect(content).toInclude('function config()');
            });
            
            it("should create a controller with actions", function() {
                var result = executeCommand(commandPath, {
                    name = "Posts",
                    actions = "index,show,new,create"
                });
                
                expect(result.success).toBeTrue();
                assertFileCreated("app/controllers/Posts.cfc");
                
                var content = fileRead(getTempDir() & "app/controllers/Posts.cfc");
                expect(content).toInclude("function index()");
                expect(content).toInclude("function show()");
                expect(content).toInclude("function new()");
                expect(content).toInclude("function create()");
            });
            
            it("should create a RESTful resource controller", function() {
                var result = executeCommand(commandPath, {
                    name = "Products",
                    resource = true
                });
                
                expect(result.success).toBeTrue();
                assertFileCreated("app/controllers/Products.cfc");
                
                var content = fileRead(getTempDir() & "app/controllers/Products.cfc");
                // Should have all RESTful actions
                expect(content).toInclude("function index()");
                expect(content).toInclude("function show()");
                expect(content).toInclude("function new()");
                expect(content).toInclude("function create()");
                expect(content).toInclude("function edit()");
                expect(content).toInclude("function update()");
                expect(content).toInclude("function delete()");
                
                // Should have provides() for API support
                expect(content).toInclude("provides(");
            });
            
            it("should create an API controller", function() {
                var result = executeCommand(commandPath, {
                    name = "api/v1/Users",
                    api = true
                });
                
                expect(result.success).toBeTrue();
                assertFileCreated("app/controllers/api/v1/Users.cfc");
                
                var content = fileRead(getTempDir() & "app/controllers/api/v1/Users.cfc");
                expect(content).toInclude("onlyProvides(");
                expect(content).toInclude('"json"');
                expect(content).not.toInclude("function new()"); // No new/edit for API
                expect(content).not.toInclude("function edit()");
            });
            
            it("should handle nested controller paths", function() {
                var result = executeCommand(commandPath, {
                    name = "admin/Users"
                });
                
                expect(result.success).toBeTrue();
                assertFileCreated("app/controllers/admin/Users.cfc");
                assertDirectoryCreated("app/controllers/admin");
            });
            
            it("should add before filters", function() {
                var result = executeCommand(commandPath, {
                    name = "Users",
                    beforeFilter = "authenticate"
                });
                
                expect(result.success).toBeTrue();
                
                var content = fileRead(getTempDir() & "app/controllers/Users.cfc");
                expect(content).toInclude('filters(through="authenticate")');
            });
            
            it("should not overwrite existing controller without force", function() {
                // Create initial controller
                executeCommand(commandPath, {
                    name = "Users"
                });
                
                // Try to create again
                var result = executeCommand(commandPath, {
                    name = "Users"
                });
                
                expect(result.success).toBeFalse();
                assertOutputContains("already exists");
            });
            
            it("should overwrite with force flag", function() {
                // Create initial controller
                executeCommand(commandPath, {
                    name = "Users"
                });
                
                // Mock user confirmation
                mockUserInput(["y"]);
                
                // Create again with force
                var result = executeCommand(commandPath, {
                    name = "Users",
                    actions = "index,show",
                    force = true
                });
                
                expect(result.success).toBeTrue();
                
                var content = fileRead(getTempDir() & "app/controllers/Users.cfc");
                expect(content).toInclude("function index()");
                expect(content).toInclude("function show()");
            });
            
            it("should create views with controller when flag is set", function() {
                var result = executeCommand(commandPath, {
                    name = "Posts",
                    actions = "index,show,new,edit",
                    withViews = true
                });
                
                expect(result.success).toBeTrue();
                assertFileCreated("app/controllers/Posts.cfc");
                assertDirectoryCreated("app/views/posts");
                assertFileCreated("app/views/posts/index.cfm");
                assertFileCreated("app/views/posts/show.cfm");
                assertFileCreated("app/views/posts/new.cfm");
                assertFileCreated("app/views/posts/edit.cfm");
            });
            
            it("should support JSON output format", function() {
                var result = executeCommand(commandPath, {
                    name = "Users",
                    actions = "index,show",
                    format = "json"
                });
                
                expect(result.success).toBeTrue();
                expect(result.data).toBeStruct();
                expect(result.data.success).toBeTrue();
                expect(result.data.controllerName).toBe("Users");
                expect(result.data.controllerPath).toInclude("app/controllers/Users.cfc");
                expect(result.data.actions).toBeArray();
                expect(arrayLen(result.data.actions)).toBe(2);
            });
            
            it("should validate controller name", function() {
                var result = executeCommand(commandPath, {
                    name = "123Invalid"
                });
                
                expect(result.success).toBeFalse();
                assertOutputContains("Invalid controller name");
            });
            
            it("should handle layout specification", function() {
                var result = executeCommand(commandPath, {
                    name = "Admin",
                    layout = "admin"
                });
                
                expect(result.success).toBeTrue();
                
                var content = fileRead(getTempDir() & "app/controllers/Admin.cfc");
                expect(content).toInclude('layout("admin")');
            });
            
            it("should handle parent controller specification", function() {
                var result = executeCommand(commandPath, {
                    name = "AdminUsers",
                    parent = "SecureController"
                });
                
                expect(result.success).toBeTrue();
                
                var content = fileRead(getTempDir() & "app/controllers/AdminUsers.cfc");
                expect(content).toInclude('extends="SecureController"');
            });
        });
    }
}