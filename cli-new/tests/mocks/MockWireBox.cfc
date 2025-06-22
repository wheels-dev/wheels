/**
 * Mock WireBox for testing
 * Provides dependency injection simulation for tests
 */
component {
    
    // Store registered instances
    variables.instances = {};
    variables.mappings = {};
    
    /**
     * Constructor
     */
    function init() {
        // Register default mocks
        registerMockServices();
        return this;
    }
    
    /**
     * Get an instance
     */
    function getInstance(required string name, struct initArguments = {}) {
        var cleanName = replaceNoCase(arguments.name, "@wheelscli", "", "all");
        
        if (structKeyExists(variables.instances, cleanName)) {
            return variables.instances[cleanName];
        }
        
        // Create mock based on name
        switch(cleanName) {
            case "ConfigService":
                return getMockConfigService();
            case "ProjectService":
                return getMockProjectService();
            case "TemplateService":
                return getMockTemplateService();
            case "FormatterService":
                return getMockFormatterService();
            case "DatabaseService":
                return getMockDatabaseService();
            case "MigrationService":
                return getMockMigrationService();
            case "WheelsService":
                return getMockWheelsService();
            case "TabCompletionService":
                return getMockTabCompletionService();
            case "PackageService":
                return getMockPackageService();
            case "ServerService":
                return getMockServerService();
            default:
                throw(type="MockNotFound", message="No mock registered for: #arguments.name#");
        }
    }
    
    /**
     * Register a mock instance
     */
    function registerInstance(required string name, required any instance) {
        variables.instances[name] = arguments.instance;
        return this;
    }
    
    /**
     * Check if instance exists
     */
    function containsInstance(required string name) {
        var cleanName = replaceNoCase(arguments.name, "@wheelscli", "", "all");
        return structKeyExists(variables.instances, cleanName);
    }
    
    /**
     * Register default mock services
     */
    private function registerMockServices() {
        // These will be created on demand
    }
    
    /**
     * Get mock ConfigService
     */
    private function getMockConfigService() {
        if (!structKeyExists(variables.instances, "ConfigService")) {
            var mock = {
                config = {},
                projectRoot = "",
                
                loadConfiguration = function() {
                    return this;
                },
                
                getConfig = function(string key = "", any defaultValue = "") {
                    if (len(arguments.key)) {
                        return structKeyExists(this.config, arguments.key) ? this.config[arguments.key] : arguments.defaultValue;
                    }
                    return this.config;
                },
                
                setConfig = function(required string key, required any value) {
                    this.config[arguments.key] = arguments.value;
                    return this;
                },
                
                saveConfiguration = function() {
                    return true;
                },
                
                getProjectRoot = function() {
                    return this.projectRoot;
                },
                
                setProjectRoot = function(required string path) {
                    this.projectRoot = arguments.path;
                    return this;
                }
            };
            
            variables.instances.ConfigService = mock;
        }
        
        return variables.instances.ConfigService;
    }
    
    /**
     * Get mock ProjectService
     */
    private function getMockProjectService() {
        if (!structKeyExists(variables.instances, "ProjectService")) {
            var mock = {
                isWheelsProject = function() {
                    return directoryExists(expandPath(".") & "/vendor/wheels");
                },
                
                getProjectInfo = function() {
                    return {
                        name = "test-project",
                        version = "1.0.0",
                        wheelsVersion = "2.5.0",
                        projectRoot = expandPath(".")
                    };
                },
                
                validateProject = function() {
                    return {
                        valid = true,
                        errors = []
                    };
                }
            };
            
            variables.instances.ProjectService = mock;
        }
        
        return variables.instances.ProjectService;
    }
    
    /**
     * Get mock TemplateService
     */
    private function getMockTemplateService() {
        if (!structKeyExists(variables.instances, "TemplateService")) {
            var mock = {
                renderTemplate = function(required string template, struct data = {}) {
                    var result = arguments.template;
                    for (var key in arguments.data) {
                        result = replaceNoCase(result, "@#key#@", arguments.data[key], "all");
                    }
                    return result;
                },
                
                getTemplate = function(required string name) {
                    return "Mock template content for: #arguments.name#";
                },
                
                listTemplates = function(string type = "") {
                    return ["default", "api", "spa"];
                }
            };
            
            variables.instances.TemplateService = mock;
        }
        
        return variables.instances.TemplateService;
    }
    
    /**
     * Get mock FormatterService
     */
    private function getMockFormatterService() {
        if (!structKeyExists(variables.instances, "FormatterService")) {
            var mock = {
                formatTable = function(required array data, array headers = []) {
                    return "Mock table output";
                },
                
                formatList = function(required array items, string bullet = "-") {
                    return arrayToList(arguments.items, chr(10) & arguments.bullet & " ");
                },
                
                formatJson = function(required any data) {
                    return serializeJSON(arguments.data, false, false);
                },
                
                formatXml = function(required any data) {
                    return "<data>Mock XML</data>";
                },
                
                pluralize = function(required string word, required numeric count) {
                    return arguments.count == 1 ? arguments.word : arguments.word & "s";
                },
                
                humanize = function(required string text) {
                    return reReplace(arguments.text, "([A-Z])", " \1", "all");
                },
                
                titleCase = function(required string text) {
                    return reReplace(lCase(arguments.text), "\b(\w)", "\u\1", "all");
                }
            };
            
            variables.instances.FormatterService = mock;
        }
        
        return variables.instances.FormatterService;
    }
    
    /**
     * Get mock DatabaseService
     */
    private function getMockDatabaseService() {
        if (!structKeyExists(variables.instances, "DatabaseService")) {
            var mock = {
                testConnection = function(struct datasource) {
                    return {
                        success = true,
                        message = "Connection successful"
                    };
                },
                
                setupSQLite = function(string path = "") {
                    return {
                        success = true,
                        databasesCreated = ["db/development.sqlite", "db/test.sqlite"]
                    };
                },
                
                createDatabase = function(required string name) {
                    return true;
                },
                
                dropDatabase = function(required string name) {
                    return true;
                },
                
                listTables = function() {
                    return ["users", "posts", "comments"];
                },
                
                tableExists = function(required string tableName) {
                    return listFindNoCase("users,posts,comments", arguments.tableName) > 0;
                },
                
                createDatasourceConfig = function(required string type, required string name) {
                    return {
                        "#arguments.name#" = {
                            "class" = "org.sqlite.JDBC",
                            "connectionString" = "jdbc:sqlite:db/development.sqlite",
                            "driver" = "SQLite"
                        }
                    };
                }
            };
            
            variables.instances.DatabaseService = mock;
        }
        
        return variables.instances.DatabaseService;
    }
    
    /**
     * Get mock MigrationService
     */
    private function getMockMigrationService() {
        if (!structKeyExists(variables.instances, "MigrationService")) {
            var mock = {
                generateMigration = function(required string name, array operations = []) {
                    return {
                        success = true,
                        fileName = dateFormat(now(), "yyyymmdd") & timeFormat(now(), "HHmmss") & "_#arguments.name#.cfc",
                        path = "db/migrate/"
                    };
                },
                
                runMigrations = function(string target = "") {
                    return {
                        success = true,
                        migrationsRun = 3,
                        message = "3 migrations executed successfully"
                    };
                },
                
                rollbackMigrations = function(numeric steps = 1) {
                    return {
                        success = true,
                        migrationsRolledBack = arguments.steps,
                        message = "#arguments.steps# migration(s) rolled back"
                    };
                },
                
                getMigrationStatus = function() {
                    return {
                        pending = ["20240120123456_CreateUsers.cfc"],
                        executed = ["20240119123456_CreatePosts.cfc", "20240118123456_CreateComments.cfc"]
                    };
                },
                
                parseMigrationName = function(required string name) {
                    return {
                        tableName = "users",
                        action = "create",
                        columnName = "",
                        columnType = ""
                    };
                }
            };
            
            variables.instances.MigrationService = mock;
        }
        
        return variables.instances.MigrationService;
    }
    
    /**
     * Get mock WheelsService
     */
    private function getMockWheelsService() {
        if (!structKeyExists(variables.instances, "WheelsService")) {
            var mock = {
                reloadFramework = function() {
                    return true;
                },
                
                getRoutes = function() {
                    return [
                        {name="root", pattern="/", controller="main", action="index"},
                        {name="users", pattern="/users", controller="users", action="index"}
                    ];
                },
                
                getVersion = function() {
                    return "2.5.0";
                },
                
                getEnvironment = function() {
                    return "development";
                },
                
                getSetting = function(required string name, any defaultValue = "") {
                    return arguments.defaultValue;
                }
            };
            
            variables.instances.WheelsService = mock;
        }
        
        return variables.instances.WheelsService;
    }
    
    /**
     * Get mock TabCompletionService
     */
    private function getMockTabCompletionService() {
        if (!structKeyExists(variables.instances, "TabCompletionService")) {
            var mock = {
                completeFiles = function(string pattern = "") {
                    return ["file1.cfm", "file2.cfc", "file3.txt"];
                },
                
                completeDirectories = function(string pattern = "") {
                    return ["app/", "config/", "tests/"];
                },
                
                completeModels = function() {
                    return ["User", "Post", "Comment"];
                },
                
                completeControllers = function() {
                    return ["Users", "Posts", "Comments"];
                },
                
                completeMigrations = function() {
                    return ["20240120123456_CreateUsers.cfc", "20240119123456_CreatePosts.cfc"];
                },
                
                completeFormatTypes = function() {
                    return ["text", "json", "xml", "table"];
                },
                
                completeDatabaseTypes = function() {
                    return ["sqlite", "mysql", "postgresql", "sqlserver", "h2"];
                }
            };
            
            variables.instances.TabCompletionService = mock;
        }
        
        return variables.instances.TabCompletionService;
    }
    
    /**
     * Get mock PackageService
     */
    private function getMockPackageService() {
        if (!structKeyExists(variables.instances, "PackageService")) {
            var mock = {
                getPackageInfo = function() {
                    return {
                        name = "test-project",
                        version = "1.0.0",
                        dependencies = {
                            "cfwheels" = "^2.5.0"
                        }
                    };
                },
                
                installPackage = function(required string packageName) {
                    return true;
                },
                
                updatePackage = function(required string packageName) {
                    return true;
                }
            };
            
            variables.instances.PackageService = mock;
        }
        
        return variables.instances.PackageService;
    }
    
    /**
     * Get mock ServerService
     */
    private function getMockServerService() {
        if (!structKeyExists(variables.instances, "ServerService")) {
            var mock = {
                startServer = function(struct options = {}) {
                    return {
                        success = true,
                        port = 8080,
                        message = "Server started on port 8080"
                    };
                },
                
                stopServer = function() {
                    return {
                        success = true,
                        message = "Server stopped"
                    };
                },
                
                getServerInfo = function() {
                    return {
                        running = true,
                        port = 8080,
                        host = "localhost"
                    };
                }
            };
            
            variables.instances.ServerService = mock;
        }
        
        return variables.instances.ServerService;
    }
}