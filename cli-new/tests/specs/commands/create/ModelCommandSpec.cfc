/**
 * Tests for wheels create model command
 */
component extends="tests.BaseTestCase" {
    
    function beforeAll() {
        super.beforeAll();
        variables.commandPath = "create model";
    }
    
    function run() {
        describe("wheels create model", function() {
            
            beforeEach(function() {
                // Create test project structure
                createTestProject();
            });
            
            it("should create a basic model file", function() {
                var result = executeCommand(commandPath, {
                    name = "User"
                });
                
                expect(result.success).toBeTrue();
                assertFileCreated("app/models/User.cfc");
                assertOutputContains("Model created successfully");
                
                // Check file contents
                var content = fileRead(getTempDir() & "app/models/User.cfc");
                expect(content).toInclude('component extends="Model"');
                expect(content).toInclude('function config()');
            });
            
            it("should create a model with attributes", function() {
                var result = executeCommand(commandPath, {
                    name = "Post",
                    attributes = "title:string,content:text,publishedAt:datetime"
                });
                
                expect(result.success).toBeTrue();
                assertFileCreated("app/models/Post.cfc");
                
                var content = fileRead(getTempDir() & "app/models/Post.cfc");
                expect(content).toInclude('property name="title"');
                expect(content).toInclude('property name="content"');
                expect(content).toInclude('property name="publishedAt"');
            });
            
            it("should create a model with associations", function() {
                var result = executeCommand(commandPath, {
                    name = "Comment",
                    belongsTo = "Post,User"
                });
                
                expect(result.success).toBeTrue();
                assertFileCreated("app/models/Comment.cfc");
                
                var content = fileRead(getTempDir() & "app/models/Comment.cfc");
                expect(content).toInclude('belongsTo("post")');
                expect(content).toInclude('belongsTo("user")');
            });
            
            it("should create a model with validations", function() {
                var result = executeCommand(commandPath, {
                    name = "Product",
                    attributes = "name:string,price:decimal",
                    validatesPresence = "name,price"
                });
                
                expect(result.success).toBeTrue();
                assertFileCreated("app/models/Product.cfc");
                
                var content = fileRead(getTempDir() & "app/models/Product.cfc");
                expect(content).toInclude('validatesPresenceOf("name,price")');
            });
            
            it("should create a migration when --migration flag is set", function() {
                var result = executeCommand(commandPath, {
                    name = "Article",
                    attributes = "title:string,body:text",
                    migration = true
                });
                
                expect(result.success).toBeTrue();
                assertFileCreated("app/models/Article.cfc");
                assertDirectoryCreated("db/migrate");
                
                // Check that a migration file was created
                var migrationFiles = directoryList(getTempDir() & "db/migrate", false, "name");
                expect(arrayLen(migrationFiles)).toBe(1);
                expect(migrationFiles[1]).toInclude("CreateArticles");
            });
            
            it("should handle camelCase model names", function() {
                var result = executeCommand(commandPath, {
                    name = "BlogPost"
                });
                
                expect(result.success).toBeTrue();
                assertFileCreated("app/models/BlogPost.cfc");
                
                var content = fileRead(getTempDir() & "app/models/BlogPost.cfc");
                expect(content).toInclude('table("blog_posts")');
            });
            
            it("should not overwrite existing model without force", function() {
                // Create initial model
                executeCommand(commandPath, {
                    name = "User"
                });
                
                // Try to create again
                var result = executeCommand(commandPath, {
                    name = "User"
                });
                
                expect(result.success).toBeFalse();
                assertOutputContains("already exists");
            });
            
            it("should overwrite existing model with force flag", function() {
                // Create initial model
                executeCommand(commandPath, {
                    name = "User"
                });
                
                // Add mock user input for confirmation
                mockUserInput(["y"]);
                
                // Create again with force
                var result = executeCommand(commandPath, {
                    name = "User",
                    force = true
                });
                
                expect(result.success).toBeTrue();
                assertFileCreated("app/models/User.cfc");
            });
            
            it("should support JSON output format", function() {
                var result = executeCommand(commandPath, {
                    name = "User",
                    format = "json"
                });
                
                expect(result.success).toBeTrue();
                expect(result.data).toBeStruct();
                expect(result.data.success).toBeTrue();
                expect(result.data.modelName).toBe("User");
                expect(result.data.modelPath).toInclude("app/models/User.cfc");
            });
            
            it("should validate model name", function() {
                var result = executeCommand(commandPath, {
                    name = "123Invalid"
                });
                
                expect(result.success).toBeFalse();
                assertOutputContains("Invalid model name");
            });
            
            it("should create model in subdirectory", function() {
                var result = executeCommand(commandPath, {
                    name = "admin/User"
                });
                
                expect(result.success).toBeTrue();
                assertFileCreated("app/models/admin/User.cfc");
            });
            
            it("should handle timestamps option", function() {
                var result = executeCommand(commandPath, {
                    name = "Post",
                    timestamps = true
                });
                
                expect(result.success).toBeTrue();
                
                var content = fileRead(getTempDir() & "app/models/Post.cfc");
                expect(content).toInclude('property name="createdAt"');
                expect(content).toInclude('property name="updatedAt"');
            });
            
            it("should handle softDeletes option", function() {
                var result = executeCommand(commandPath, {
                    name = "Post",
                    softDeletes = true
                });
                
                expect(result.success).toBeTrue();
                
                var content = fileRead(getTempDir() & "app/models/Post.cfc");
                expect(content).toInclude('property name="deletedAt"');
                expect(content).toInclude('softDeletes()');
            });
            
            it("should create factory when --factory flag is set", function() {
                var result = executeCommand(commandPath, {
                    name = "User",
                    attributes = "name:string,email:string",
                    factory = true
                });
                
                expect(result.success).toBeTrue();
                assertFileCreated("app/models/User.cfc");
                assertFileCreated("tests/factories/UserFactory.cfc");
                
                var factoryContent = fileRead(getTempDir() & "tests/factories/UserFactory.cfc");
                expect(factoryContent).toInclude("name =");
                expect(factoryContent).toInclude("email =");
            });
        });
    }
}