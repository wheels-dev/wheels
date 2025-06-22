/**
 * Create a new Wheels application
 */
component extends="commands.wheels.BaseCommand" {
    
    property name="packageService" inject="PackageService";
    property name="databaseService" inject="DatabaseService@wheelscli";
    property name="serverService" inject="ServerService";
    
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
        return runCommand(function() {
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
            
            if (variables.commandMetadata.outputFormat == "text") {
                printHeader("Creating new Wheels application", arguments.name);
            }
            
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
            runWithSpinner("Creating directory structure", function() {
                createAppStructure(appPath);
            });
            
            // Create box.json for the project
            runWithSpinner("Creating package configuration", function() {
                createBoxJson(appPath, arguments.name, arguments.database);
                arrayAppend(result.filesCreated, "box.json");
            });
            
            // Create server.json with database configuration
            runWithSpinner("Creating server configuration", function() {
                createServerJson(appPath, arguments.name, arguments.database);
                arrayAppend(result.filesCreated, "server.json");
            });
            
            // Create initial configuration files
            runWithSpinner("Creating application files", function() {
                createApplicationFiles(appPath, arguments.name);
                createConfigFiles(appPath, arguments.database);
                createPublicFiles(appPath);
                arrayAppend(result.filesCreated, "Application.cfc", true);
                arrayAppend(result.filesCreated, "index.cfm", true);
                arrayAppend(result.filesCreated, "config/routes.cfm", true);
            });
            
            // Setup database if requested
            if (arguments.setupDatabase && arguments.database == "sqlite") {
                runWithSpinner("Setting up SQLite database", function() {
                    var dbResult = databaseService.setupSQLite(appPath);
                    if (dbResult.success) {
                        arrayAppend(result.filesCreated, dbResult.databasesCreated, true);
                    }
                });
            }
            
            // Create initial test structure
            runWithSpinner("Creating test structure", function() {
                createTestStructure(appPath);
                arrayAppend(result.filesCreated, "tests/", true);
            });
            
            // Install dependencies
            if (arguments.installDependencies) {
                if (variables.commandMetadata.outputFormat == "text") {
                    printSection("Installing dependencies");
                }
                command("install")
                    .inWorkingDirectory(appPath)
                    .run();
            }
            
            // Output results
            if (variables.commandMetadata.outputFormat == "text") {
                print.line();
                printSuccess("Application created successfully!");
                print.line();
                
                printSection("Next steps");
                print.indentedLine("1. cd #arguments.name#");
                
                var stepNumber = 2;
                if (!arguments.setupDatabase) {
                    print.indentedLine("#stepNumber#. wheels db setup    # Create and setup database");
                    stepNumber++;
                }
                print.indentedLine("#stepNumber#. wheels server start # Start the development server");
                stepNumber++;
                print.indentedLine("#stepNumber#. Open http://localhost:8080");
                
                print.line();
                printSection("Quick start");
                print.indentedLine("wheels create model Post title:string content:text --migration");
                print.indentedLine("wheels create controller Posts --resource");
                print.indentedLine("wheels db migrate");
            } else {
                output(result, arguments.format);
            }
        }, argumentCollection=arguments);
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
        if (arguments.database == "sqlite") {
            boxJson.dependencies["sqlite-jdbc"] = "^3.46.0";
        }
        
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
        var applicationContent = '<cfcomponent output="false">
    <cfscript>
        this.name = "@APP_NAME@";
        this.sessionManagement = true;
        this.sessionTimeout = createTimeSpan(0, 2, 0, 0);
        this.applicationTimeout = createTimeSpan(1, 0, 0, 0);
        
        // Wheels settings
        this.mappings["/wheels"] = getDirectoryFromPath(getCurrentTemplatePath()) & "vendor/wheels";
        this.datasource = "wheelsdatasource";
        
        // Include Wheels framework
        include "wheels/events/onapplicationstart.cfm";
        include "wheels/events/onrequeststart.cfm"; 
        include "wheels/events/onrequest.cfm";
        include "wheels/events/onrequestend.cfm";
        include "wheels/events/onerror.cfm";
        include "wheels/events/onsessionstart.cfm";
        include "wheels/events/onsessionend.cfm";
    </cfscript>
</cfcomponent>';
        
        applicationContent = renderTemplate(applicationContent, {
            app_name = reReplace(arguments.appName, "[^a-zA-Z0-9]", "", "all")
        });
        
        fileWrite(arguments.path & "/Application.cfc", applicationContent);
        
        // Root index.cfm
        fileWrite(arguments.path & "/index.cfm", '<cfinclude template="wheels/index.cfm">');
        
        // rewrite.cfm for URL rewriting
        fileWrite(arguments.path & "/rewrite.cfm", '<cfinclude template="wheels/rewrite.cfm">');
    }
    
    /**
     * Create configuration files
     */
    private function createConfigFiles(required string path, required string database) {
        // URL rewrite configuration
        var urlRewriteContent = '<?xml version="1.0" encoding="utf-8"?>
<urlrewrite>
    <rule>
        <note>Wheels catch-all route</note>
        <from>^(.*)$</from>
        <to>/rewrite.cfm$1</to>
    </rule>
</urlrewrite>';
        
        fileWrite(arguments.path & "/config/urlrewrite.xml", urlRewriteContent);
        
        // Routes configuration
        var routesContent = '<cfscript>
    /**
     * Routes Configuration
     * See: https://guides.cfwheels.org/docs/routing
     */
    
    // Draw your application routes below
    
    // Example RESTful resource
    // resources("posts");
    
    // Example nested resources
    // resources("users", function() {
    //     resources("posts");
    // });
    
    // Root route
    root(to="main##index");
    
    // Generic catch-all routes
    get(name="catchall", pattern="*", to="wheels##redirect");
</cfscript>';
        
        fileWrite(arguments.path & "/config/routes.cfm", routesContent);
        
        // Settings
        var settingsContent = '<cfscript>
    /**
     * Application Settings
     */
    
    // Reload password for development
    set(reloadPassword = "reload@#arguments.database#");
    
    // Environment settings will override these settings
    // based on the current environment (development, testing, production)
</cfscript>';
        
        fileWrite(arguments.path & "/config/settings.cfm", settingsContent);
        
        // Development settings
        var devSettingsContent = '<cfscript>
    /**
     * Development Environment Settings
     */
    
    // Show debugging information
    set(showDebugInformation = true);
    
    // Show error information
    set(showErrorInformation = true);
    
    // Auto reload
    set(autoReload = true);
    
    // Cache settings
    set(cacheFileChecking = false);
    set(cacheControllerInitialization = false);
    set(cacheModelInitialization = false);
    set(cachePlugins = false);
    set(cacheRoutes = false);
    set(cacheViewPaths = false);
</cfscript>';
        
        directoryCreate(arguments.path & "/config/settings", true);
        fileWrite(arguments.path & "/config/settings/development.cfm", devSettingsContent);
        
        // Production settings
        var prodSettingsContent = '<cfscript>
    /**
     * Production Environment Settings
     */
    
    // Hide debugging information
    set(showDebugInformation = false);
    
    // Hide error information
    set(showErrorInformation = false);
    
    // Disable auto reload
    set(autoReload = false);
    
    // Enable caching
    set(cacheFileChecking = true);
    set(cacheControllerInitialization = true);
    set(cacheModelInitialization = true);
    set(cachePlugins = true);
    set(cacheRoutes = true);
    set(cacheViewPaths = true);
</cfscript>';
        
        fileWrite(arguments.path & "/config/settings/production.cfm", prodSettingsContent);
    }
    
    /**
     * Create public files
     */
    private function createPublicFiles(required string path) {
        // robots.txt
        var robotsContent = "User-agent: *
Disallow: /config/
Disallow: /db/
Disallow: /tests/
Disallow: /vendor/";
        
        fileWrite(arguments.path & "/public/robots.txt", robotsContent);
        
        // Basic CSS
        var cssContent = "/* Wheels Application Styles */
body {
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    line-height: 1.6;
    color: #333;
    max-width: 1200px;
    margin: 0 auto;
    padding: 20px;
}

h1, h2, h3 {
    color: #2c3e50;
}

.flash-messages {
    padding: 10px;
    margin: 10px 0;
    border-radius: 4px;
}

.flash-success {
    background-color: #d4edda;
    color: #155724;
    border: 1px solid #c3e6cb;
}

.flash-error {
    background-color: #f8d7da;
    color: #721c24;
    border: 1px solid #f5c6cb;
}

.flash-notice {
    background-color: #d1ecf1;
    color: #0c5460;
    border: 1px solid #bee5eb;
}";
        
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
        var controllerContent = 'component extends="Controller" {
    
    /**
     * Controller configuration
     */
    function config() {
        // Add any filters or settings here
    }
    
    /**
     * Index action - home page
     */
    function index() {
        // This is your home page
        // Add any data you want to pass to the view here
    }
    
}';
        
        fileWrite(arguments.path & "/app/controllers/Main.cfc", controllerContent);
    }
    
    /**
     * Create layout file
     */
    private function createLayoutFile(required string path) {
        var layoutContent = '<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title><cfoutput>##contentForLayout("title")##</cfoutput></title>
    <cfoutput>##styleSheetLinkTag("app")##</cfoutput>
    <cfoutput>##contentForLayout("head")##</cfoutput>
</head>
<body>
    <header>
        <h1>Welcome to Wheels</h1>
    </header>
    
    <main>
        <cfif flashKeyExists("success")>
            <div class="flash-messages flash-success">
                <cfoutput>##flash("success")##</cfoutput>
            </div>
        </cfif>
        
        <cfif flashKeyExists("error")>
            <div class="flash-messages flash-error">
                <cfoutput>##flash("error")##</cfoutput>
            </div>
        </cfif>
        
        <cfif flashKeyExists("notice")>
            <div class="flash-messages flash-notice">
                <cfoutput>##flash("notice")##</cfoutput>
            </div>
        </cfif>
        
        <cfoutput>##contentForLayout()##</cfoutput>
    </main>
    
    <footer>
        <p><small>Powered by CFWheels</small></p>
    </footer>
    
    <cfoutput>##contentForLayout("scripts")##</cfoutput>
</body>
</html>';
        
        fileWrite(arguments.path & "/app/views/layout/layout.cfm", layoutContent);
    }
    
    /**
     * Create index view
     */
    private function createIndexView(required string path) {
        var indexContent = '<cfoutput>

##contentFor(title="Welcome to Wheels")##

<h2>Congratulations!</h2>

<p>You have successfully created a new Wheels application.</p>

<h3>What''s next?</h3>

<ul>
    <li>Generate a model: <code>wheels create model Post title:string content:text --migration</code></li>
    <li>Generate a controller: <code>wheels create controller Posts --resource</code></li>
    <li>Run migrations: <code>wheels db migrate</code></li>
    <li>Explore the <a href="https://guides.cfwheels.org">Wheels Guides</a></li>
</ul>

<h3>Your Application</h3>

<ul>
    <li>Framework Version: ##application.wheels.version##</li>
    <li>Environment: ##get("environment")##</li>
    <li>Datasource: ##get("dataSourceName")##</li>
    <li>Database: SQLite</li>
</ul>

</cfoutput>';
        
        directoryCreate(arguments.path & "/app/views/main", true);
        fileWrite(arguments.path & "/app/views/main/index.cfm", indexContent);
    }
    
    /**
     * Create test structure
     */
    private function createTestStructure(required string path) {
        // Test runner
        var runnerContent = '<cfscript>
    // TestBox Runner
    r = new testbox.system.TestBox();
    
    // Run tests
    results = r.run(
        directory = {
            mapping = "tests.specs",
            recurse = true
        }
    );
    
    // Output results
    writeOutput(results);
</cfscript>';
        
        fileWrite(arguments.path & "/tests/runner.cfm", runnerContent);
        
        // Test Application.cfc
        var testAppContent = 'component {
    this.name = "WheelsTestSuite" & hash(getCurrentTemplatePath());
    this.sessionManagement = false;
    
    // Set up test datasource
    this.datasource = "wheelstestdatasource";
    
    // Mappings
    this.mappings["/tests"] = getDirectoryFromPath(getCurrentTemplatePath());
    this.mappings["/app"] = expandPath("../app");
    this.mappings["/wheels"] = expandPath("../vendor/wheels");
    this.mappings["/testbox"] = expandPath("../vendor/testbox");
}';
        
        fileWrite(arguments.path & "/tests/Application.cfc", testAppContent);
        
        // Create specs directory
        directoryCreate(arguments.path & "/tests/specs", true);
        fileWrite(arguments.path & "/tests/specs/.gitkeep", "");
    }
}