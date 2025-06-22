/**
 * Integration tests for app creation workflow
 */
component extends="tests.BaseTestCase" {
    
    function run() {
        describe("App Creation Workflow", function() {
            
            it("should create a complete application with all components", function() {
                var appName = "test-blog-app";
                
                // Create the app
                var result = executeCommand("create app", {
                    name = appName,
                    template = "default",
                    database = "sqlite",
                    installDependencies = false,
                    setupDatabase = true
                });
                
                expect(result.success).toBeTrue();
                
                // Verify directory structure
                var appPath = getTempDir() & appName & "/";
                assertDirectoryCreated(appName);
                assertDirectoryCreated(appName & "/app/controllers");
                assertDirectoryCreated(appName & "/app/models");
                assertDirectoryCreated(appName & "/app/views");
                assertDirectoryCreated(appName & "/config");
                assertDirectoryCreated(appName & "/db/migrate");
                assertDirectoryCreated(appName & "/db/sqlite");
                assertDirectoryCreated(appName & "/public");
                assertDirectoryCreated(appName & "/tests");
                assertDirectoryCreated(appName & "/vendor");
                
                // Verify files
                assertFileCreated(appName & "/Application.cfc");
                assertFileCreated(appName & "/index.cfm");
                assertFileCreated(appName & "/box.json");
                assertFileCreated(appName & "/server.json");
                assertFileCreated(appName & "/config/routes.cfm");
                assertFileCreated(appName & "/config/settings.cfm");
                
                // Verify SQLite databases were created
                assertFileCreated(appName & "/db/sqlite/development.sqlite");
                assertFileCreated(appName & "/db/sqlite/test.sqlite");
                
                // Change to app directory for subsequent commands
                var originalDir = getTempDir();
                directoryChange(appPath);
                
                try {
                    // Create a model with migration
                    result = executeCommand("create model", {
                        name = "Post",
                        attributes = "title:string,content:text,published:boolean",
                        migration = true
                    });
                    
                    expect(result.success).toBeTrue();
                    assertFileCreated("app/models/Post.cfc");
                    
                    // Create a controller
                    result = executeCommand("create controller", {
                        name = "Posts",
                        actions = "index,show,new,create,edit,update,delete"
                    });
                    
                    expect(result.success).toBeTrue();
                    assertFileCreated("app/controllers/Posts.cfc");
                    
                    // Create views
                    result = executeCommand("create view", {
                        name = "posts/index"
                    });
                    
                    expect(result.success).toBeTrue();
                    assertFileCreated("app/views/posts/index.cfm");
                    
                    // Check routes
                    result = executeCommand("routes", {
                        format = "json"
                    });
                    
                    expect(result.success).toBeTrue();
                    expect(result.data).toBeStruct();
                    expect(result.data.routes).toBeArray();
                    
                } finally {
                    // Restore original directory
                    directoryChange(originalDir);
                }
            });
            
            it("should create an API template application", function() {
                var result = executeCommand("create app", {
                    name = "test-api",
                    template = "api",
                    database = "sqlite",
                    installDependencies = false
                });
                
                expect(result.success).toBeTrue();
                
                // Verify API-specific configurations
                var serverJson = deserializeJSON(fileRead(getTempDir() & "test-api/server.json"));
                expect(serverJson).toBeStruct();
                
                var routesContent = fileRead(getTempDir() & "test-api/config/routes.cfm");
                expect(routesContent).toInclude("namespace");
                expect(routesContent).toInclude("/api/v1");
            });
            
            it("should handle full scaffold generation", function() {
                // Create app first
                executeCommand("create app", {
                    name = "scaffold-test",
                    installDependencies = false
                });
                
                // Change to app directory
                var appPath = getTempDir() & "scaffold-test/";
                directoryChange(appPath);
                
                try {
                    // Generate scaffold
                    var result = executeCommand("create scaffold", {
                        name = "Product",
                        attributes = "name:string,price:decimal,inStock:boolean"
                    });
                    
                    expect(result.success).toBeTrue();
                    
                    // Verify all components were created
                    assertFileCreated("app/models/Product.cfc");
                    assertFileCreated("app/controllers/Products.cfc");
                    assertDirectoryCreated("app/views/products");
                    assertFileCreated("app/views/products/index.cfm");
                    assertFileCreated("app/views/products/show.cfm");
                    assertFileCreated("app/views/products/new.cfm");
                    assertFileCreated("app/views/products/edit.cfm");
                    assertFileCreated("app/views/products/_form.cfm");
                    
                    // Verify migration was created
                    var migrationFiles = directoryList("db/migrate", false, "name");
                    expect(arrayLen(migrationFiles)).toBeGT(0);
                    expect(migrationFiles[1]).toInclude("CreateProducts");
                    
                } finally {
                    directoryChange(getTempDir());
                }
            });
            
            it("should handle database operations", function() {
                // Create app
                executeCommand("create app", {
                    name = "db-test",
                    setupDatabase = true,
                    installDependencies = false
                });
                
                var appPath = getTempDir() & "db-test/";
                directoryChange(appPath);
                
                try {
                    // Check database status
                    var result = executeCommand("db status", {
                        format = "json"
                    });
                    
                    expect(result.success).toBeTrue();
                    expect(result.data.database).toBe("sqlite");
                    
                    // Create a migration
                    result = executeCommand("db create migration", {
                        name = "CreateUsers"
                    });
                    
                    expect(result.success).toBeTrue();
                    
                    // Run migrations
                    result = executeCommand("db migrate");
                    expect(result.success).toBeTrue();
                    
                } finally {
                    directoryChange(getTempDir());
                }
            });
        });
    }
}