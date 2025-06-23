/**
 * Create a new Wheels application
 */
component extends="../base" {
    
    property name="packageService" inject="PackageService";
    property name="databaseService" inject="DatabaseService@wheels-cli-next";
    property name="serverService" inject="ServerService";
    property name="snippetService" inject="SnippetService@wheels-cli-next";
    
    /**
     * Create a new Wheels application
     * 
     * @name.hint Name of the application
     * @template.hint Application template
     * @template.options default,api,spa
     * @database.hint Database type
     * @database.optionsUDF completeDatabaseTypes
     * @installDependencies.hint Install dependencies after creation
     * @installDependencies.options true,false
     * @setupDatabase.hint Configure database and download drivers
     * @setupDatabase.options true,false
     * @directory.hint Directory to create the app in (defaults to current directory)
     * @force.hint Overwrite existing directory
     * @force.options true,false
     * @format.hint Output format
     * @format.optionsUDF completeFormatTypes
     * @help Create a new CFWheels application with scaffolding
     */
    function run(
        required string name,
        string template = "default",
        string database = "sqlite",
        boolean installDependencies = true,
        boolean setupDatabase = true,
        string directory = "",
        boolean force = false,
        string format = "text"
    ) {
            // Validate app name
            if (!reFind("^[a-zA-Z][a-zA-Z0-9_-]*$", arguments.name)) {
                error("Invalid application name. Use only letters, numbers, hyphens, and underscores. Must start with a letter.");
            }
            
            var result = {
                success = true,
                appName = arguments.name,
                appPath = "",
                filesCreated = [],
                errors = []
            };
            
            printHeader("Creating new Wheels application", arguments.name);
            
            var basePath = len(arguments.directory) ? arguments.directory : getCWD();
            var appPath = basePath & "/" & arguments.name;
            result.appPath = appPath;
            
            // Check if directory exists
            if (directoryExists(appPath) && !arguments.force) {
                if (!confirm("Directory '#arguments.name#' already exists. Overwrite?")) {
                    error("Directory already exists. Use --force to overwrite.");
                }
            }
            
            // Create directory structure
            print.line("Creating directory structure...");
            createAppStructure(appPath);
            
            // Create box.json for the project
            print.line("Creating package configuration...");
            createBoxJson(appPath, arguments.name, arguments.database);
            arrayAppend(result.filesCreated, "box.json");
            
            // Create server.json with database configuration
            print.line("Creating server configuration...");
            createServerJson(appPath, arguments.name, arguments.database);
            arrayAppend(result.filesCreated, "server.json");
            
            // Create initial configuration files
            print.line("Creating application files...");
            createApplicationFiles(appPath, arguments.name);
            createConfigFiles(appPath, arguments.database);
            createPublicFiles(appPath);
            arrayAppend(result.filesCreated, "Application.cfc", true);
            arrayAppend(result.filesCreated, "index.cfm", true);
            arrayAppend(result.filesCreated, "config/routes.cfm", true);
            
            // Setup database if requested
            if (arguments.setupDatabase && arguments.database == "sqlite") {
                print.line("Setting up SQLite database...");
                var dbResult = databaseService.setupSQLite(appPath);
                if (dbResult.success) {
                    arrayAppend(result.filesCreated, dbResult.databasesCreated, true);
                }
            }
            
            // Create initial test structure
            print.line("Creating test structure...");
            createTestStructure(appPath);
            arrayAppend(result.filesCreated, "tests/", true);
            
            // Install dependencies
            if (arguments.installDependencies) {
                print.line();
                print.yellowLine("Installing dependencies");
                print.line(repeatString("-", 30));
                shell.cd(appPath);
                shell.callCommand("install");
                shell.cd(basePath);
            }
            
            // Output results
            print.line();
            printSuccess("Application created successfully!");
            print.line();
            
            print.yellowLine("Next steps");
            print.line(repeatString("-", 20));
            print.indentedLine("1. cd #arguments.name#");
            
            var stepNumber = 2;
            if (!arguments.setupDatabase) {
                print.indentedLine("#stepNumber#. wheels db setup    ## Create and setup database");
                stepNumber++;
            }
            print.indentedLine("#stepNumber#. wheels server start ## Start the development server");
            stepNumber++;
            print.indentedLine("#stepNumber#. Open http://localhost:8080");
            
            print.line();
            print.yellowLine("Quick start");
            print.line(repeatString("-", 20));
            print.indentedLine("wheels create model Post title:string content:text --migration");
            print.indentedLine("wheels create controller Posts --resource");
            print.indentedLine("wheels db migrate");
            
            return result;
    }
    
    /**
     * Create application directory structure
     */
    private function createAppStructure(required string path) {
        var dirs = [
            "/app/controllers",
            "/app/models", 
            "/app/views/layout",
            "/config/settings",
            "/db/migrate",
            "/db/sql",
            "/db/seeds",
            "/public/dist",
            "/public/images",
            "/public/javascripts",
            "/public/stylesheets",
            "/tests/controllers",
            "/tests/models",
            "/tests/views",
            "/tests/helpers",
            "/vendor"
        ];
        
        // SQLite-specific directory
        directoryCreate(arguments.path & "/db/sqlite", true);
        
        for (var dir in dirs) {
            directoryCreate(arguments.path & dir, true);
            
            // Create .gitkeep files to preserve empty directories
            if (!findNoCase("/vendor", dir)) {
                fileWrite(arguments.path & dir & "/.gitkeep", "");
            }
        }
    }
    
    /**
     * Create box.json for the project
     */
    private function createBoxJson(
        required string path,
        required string appName,
        required string database
    ) {
        var boxJson = {
            "name": arguments.appName,
            "version": "0.0.1",
            "author": "",
            "description": "A CFWheels application",
            "homepage": "",
            "type": "mvc",
            "keywords": ["cfwheels", "mvc"],
            "private": true,
            "engines": {
                "lucee": ">=5.3",
                "adobe": ">=2018"
            },
            "dependencies": {
                "cfwheels": "^2.5.0"
            },
            "devDependencies": {
                "testbox": "^5.0.0"
            },
            "scripts": {
                "test": "wheels test all",
                "test:unit": "wheels test unit",
                "test:integration": "wheels test integration",
                "migrate": "wheels db migrate",
                "seed": "wheels db seed",
                "server": "wheels server start",
                "format": "cfformat run app/ tests/ --overwrite",
                "format:check": "cfformat check app/ tests/"
            }
        };
        
        // Add database-specific dependencies
        // SQLite JDBC driver is typically bundled with the server
        
        fileWrite(
            arguments.path & "/box.json",
            serializeJSON(boxJson, false, false)
        );
    }
    
    /**
     * Create server.json with database configuration
     */
    private function createServerJson(
        required string path,
        required string appName,
        required string database
    ) {
        var serverConfig = {
            "name": arguments.appName,
            "app": {
                "cfengine": "lucee@5"
            },
            "web": {
                "http": {
                    "port": 8080
                },
                "rewrites": {
                    "enable": true,
                    "logEnable": false,
                    "config": "config/urlrewrite.xml"
                },
                "rules": [
                    {
                        "pattern": "^/(flex2gateway|flashservices/gateway|messagebroker|lucee|LUCEE|WEB-INF|META-INF).*",
                        "action": "block",
                        "type": "regex"
                    }
                ]
            }
        };
        
        // Add database configuration
        var dbConfig = databaseService.createDatasourceConfig(
            arguments.database,
            reReplace(arguments.appName, "[^a-zA-Z0-9_]", "_", "all")
        );
        serverConfig.app.datasources = dbConfig;
        
        fileWrite(
            arguments.path & "/server.json",
            serializeJSON(serverConfig, false, false)
        );
    }
    
    /**
     * Create Application.cfc
     */
    private function createApplicationFiles(required string path, required string appName) {
        // Application.cfc
        var applicationContent = snippetService.getSnippet("app", "Application.cfc");
        applicationContent = snippetService.render(applicationContent, {
            APP_NAME = reReplace(arguments.appName, "[^a-zA-Z0-9]", "", "all")
        });
        
        fileWrite(arguments.path & "/Application.cfc", applicationContent);
        
        // Root index.cfm
        var indexContent = snippetService.getSnippet("app", "index.cfm");
        fileWrite(arguments.path & "/index.cfm", indexContent);
        
        // rewrite.cfm for URL rewriting
        var rewriteContent = snippetService.getSnippet("app", "rewrite.cfm");
        fileWrite(arguments.path & "/rewrite.cfm", rewriteContent);
    }
    
    /**
     * Create configuration files
     */
    private function createConfigFiles(required string path, required string database) {
        // URL rewrite configuration
        var urlRewriteContent = snippetService.getSnippet("config", "urlrewrite.xml");
        fileWrite(arguments.path & "/config/urlrewrite.xml", urlRewriteContent);
        
        // Routes configuration
        var routesContent = snippetService.getSnippet("config", "routes.cfm");
        fileWrite(arguments.path & "/config/routes.cfm", routesContent);
        
        // Settings
        var settingsContent = snippetService.getSnippet("config", "settings.cfm");
        settingsContent = snippetService.render(settingsContent, {
            DATABASE = arguments.database
        });
        fileWrite(arguments.path & "/config/settings.cfm", settingsContent);
        
        // Development settings
        var devSettingsContent = snippetService.getSnippet("config", "settings-development.cfm");
        fileWrite(arguments.path & "/config/settings/development.cfm", devSettingsContent);
        
        // Production settings
        var prodSettingsContent = snippetService.getSnippet("config", "settings-production.cfm");
        fileWrite(arguments.path & "/config/settings/production.cfm", prodSettingsContent);
    }
    
    /**
     * Create public files
     */
    private function createPublicFiles(required string path) {
        // robots.txt
        var robotsContent = snippetService.getSnippet("app", "robots.txt");
        fileWrite(arguments.path & "/public/robots.txt", robotsContent);
        
        // Basic CSS
        var cssContent = snippetService.getSnippet("app", "app.css");
        fileWrite(arguments.path & "/public/stylesheets/app.css", cssContent);
        
        // Basic layout file
        createMainController(arguments.path);
        createLayoutFile(arguments.path);
        createIndexView(arguments.path);
    }
    
    /**
     * Create main controller
     */
    private function createMainController(required string path) {
        var controllerContent = snippetService.getSnippet("app", "main-controller.cfc");
        fileWrite(arguments.path & "/app/controllers/Main.cfc", controllerContent);
    }
    
    /**
     * Create layout file
     */
    private function createLayoutFile(required string path) {
        var layoutContent = snippetService.getSnippet("layout", "default.cfm");
        fileWrite(arguments.path & "/app/views/layout/layout.cfm", layoutContent);
    }
    
    /**
     * Create index view
     */
    private function createIndexView(required string path) {
        var indexContent = snippetService.getSnippet("app", "main-index-view.cfm");
        directoryCreate(arguments.path & "/app/views/main", true);
        fileWrite(arguments.path & "/app/views/main/index.cfm", indexContent);
    }
    
    /**
     * Create test structure
     */
    private function createTestStructure(required string path) {
        // Test runner
        var runnerContent = snippetService.getSnippet("test", "runner.cfm");
        fileWrite(arguments.path & "/tests/runner.cfm", runnerContent);
        
        // Test Application.cfc
        var testAppContent = snippetService.getSnippet("test", "Application.cfc");
        fileWrite(arguments.path & "/tests/Application.cfc", testAppContent);
        
        // Create specs directory
        directoryCreate(arguments.path & "/tests/specs", true);
        fileWrite(arguments.path & "/tests/specs/.gitkeep", "");
    }
}