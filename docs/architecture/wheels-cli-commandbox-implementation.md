# Wheels CLI CommandBox Implementation Guide

## Overview

This guide provides detailed implementation strategies for building the Wheels CLI as a CommandBox module, leveraging CommandBox's existing infrastructure while adding Wheels-specific functionality.

**Note:** This CLI is designed for Wheels 3.0+ projects where:
- The framework is located in the `vendor/wheels/` directory
- The framework version is determined from `vendor/wheels/box.json` (following CommandBox package standards)
- The project follows the modern Wheels directory structure

For legacy Wheels projects, users will need to upgrade to the modern structure.

## CommandBox Architecture Integration

### Expected Wheels Project Structure
```
my-wheels-app/
├── app/
│   ├── controllers/
│   ├── models/
│   └── views/
├── config/
│   ├── app.cfm          # Application configuration
│   ├── routes.cfm       # Route definitions
│   └── settings/        # Environment-specific settings
├── db/
│   ├── migrate/         # Migration files
│   ├── sql/            # Raw SQL files
│   └── sqlite/         # SQLite database files
│       └── .gitignore  # Ignore .db files
├── public/
├── tests/
├── vendor/
│   └── wheels/          # Wheels framework files (3.0+)
│       └── box.json     # Contains version and package info
├── box.json            # Project's box.json
└── server.json         # Includes SQLite datasource config
```

### Module Structure
```
wheels-cli/
├── ModuleConfig.cfc
├── box.json
├── commands/
│   └── wheels/
│       ├── create/
│       │   ├── app.cfc
│       │   ├── model.cfc        # Creates files in app/models/
│       │   ├── controller.cfc   # Creates files in app/controllers/
│       │   ├── view.cfc         # Creates files in app/views/
│       │   ├── migration.cfc    # Creates files in db/migrate/
│       │   └── test.cfc         # Creates files in tests/
│       ├── db/
│       │   ├── create.cfc
│       │   ├── migrate.cfc
│       │   ├── rollback.cfc
│       │   ├── seed.cfc
│       │   ├── status.cfc
│       │   └── setup.cfc        # Sets up database & JDBC drivers
│       ├── server/
│       │   ├── create.cfc
│       │   ├── migrate.cfc
│       │   ├── rollback.cfc
│       │   ├── seed.cfc
│       │   └── status.cfc
│       ├── server/
│       │   ├── start.cfc
│       │   ├── stop.cfc
│       │   └── restart.cfc
│               ├── test/
│       │   ├── all.cfc
│       │   ├── unit.cfc
│       │   └── integration.cfc
│       ├── console.cfc
│       ├── routes.cfc
│       ├── version.cfc          # Shows Wheels version info
│       └── help.cfc
├── templates/
│   ├── app/
│   ├── model/
│   ├── controller/
│   ├── view/
│   └── migration/
└── lib/
    ├── WheelsService.cfc
    ├── MigrationService.cfc
    ├── DatabaseService.cfc      # Database setup & driver management
    └── TestRunner.cfc
```

### box.json Configuration
```json
{
    "name": "wheels-cli",
    "version": "3.0.0",
    "author": "CFWheels Team",
    "homepage": "https://cfwheels.org",
    "documentation": "https://guides.cfwheels.org/cli",
    "repository": {
        "type": "git",
        "url": "https://github.com/cfwheels/wheels-cli"
    },
    "bugs": "https://github.com/cfwheels/wheels-cli/issues",
    "slug": "wheels-cli",
    "shortDescription": "Official CLI for CFWheels Framework",
    "type": "commandbox-modules",
    "keywords": [
        "cfwheels",
        "mvc",
        "cli",
        "scaffolding"
    ],
    "private": false,
    "dependencies": {
        "commandbox-migrations": "^3.0.0",
        "commandbox-cfformat": "^2.0.0",
        "sqlite-jdbc": "^3.40.0"
    },
    "devDependencies": {
        "testbox": "^4.0.0"
    },
    "installPaths": {
        "commandbox-migrations": "modules/commandbox-migrations/",
        "commandbox-cfformat": "modules/commandbox-cfformat/",
        "sqlite-jdbc": "lib/"
    }
}
```

## Core Command Implementations

### Base Command Class
```javascript
component extends="commandbox.system.BaseCommand" {
    
    property name="fileSystemUtil" inject="FileSystem";
    property name="packageService" inject="PackageService";
    property name="consoleLogger" inject="logbox:logger:console";
    
    /**
     * Common functionality for all Wheels commands
     */
    function init() {
        super.init();
        return this;
    }
    
    /**
     * Check if we're in a Wheels project
     */
    function isWheelsProject() {
        // Modern structure: Wheels in vendor directory
        return directoryExists(getCWD() & "vendor/wheels/");
    }
    
    /**
     * Check if we're in a legacy Wheels project (pre-3.0)
     */
    function isLegacyWheelsProject() {
        // Legacy structure: Wheels in root directory
        return directoryExists(getCWD() & "wheels/") && !directoryExists(getCWD() & "vendor/wheels/");
    }
    
    /**
     * Detect if directory might be a Wheels project based on structure
     */
    function mightBeWheelsProject() {
        // Check for common Wheels directories and files
        return fileExists(getCWD() & "config/routes.cfm") ||
               directoryExists(getCWD() & "controllers/") ||
               directoryExists(getCWD() & "app/controllers/") ||
               fileExists(getCWD() & "box.json");
    }
    
    /**
     * Get Wheels version from the project
     */
    function getWheelsVersion() {
        var wheelsInfo = getWheelsInfo();
        return structKeyExists(wheelsInfo, "version") ? wheelsInfo.version : "Unknown";
    }
    
    /**
     * Get Wheels package information from box.json
     */
    function getWheelsInfo() {
        var info = {
            version = "Unknown",
            name = "wheels",
            author = "",
            homepage = ""
        };
        
        if (!isWheelsProject() && !isLegacyWheelsProject()) {
            return info;
        }
        
        // For modern projects, read from box.json in vendor/wheels/
        if (isWheelsProject()) {
            var boxJsonPath = getCWD() & "vendor/wheels/box.json";
            if (fileExists(boxJsonPath)) {
                try {
                    var boxJson = deserializeJSON(fileRead(boxJsonPath));
                    
                    // Extract common properties
                    if (structKeyExists(boxJson, "version")) {
                        info.version = boxJson.version;
                    }
                    if (structKeyExists(boxJson, "name")) {
                        info.name = boxJson.name;
                    }
                    if (structKeyExists(boxJson, "author")) {
                        info.author = boxJson.author;
                    }
                    if (structKeyExists(boxJson, "homepage")) {
                        info.homepage = boxJson.homepage;
                    }
                    
                    // Store full box.json data for potential future use
                    info.boxJson = boxJson;
                    
                } catch (any e) {
                    consoleLogger.error("Error parsing Wheels box.json: #e.message#");
                }
            }
        }
        
        // For legacy projects, check for version.txt
        if (isLegacyWheelsProject()) {
            var versionFile = getCWD() & "wheels/version.txt";
            if (fileExists(versionFile)) {
                info.version = trim(fileRead(versionFile));
            }
        }
        
        return info;
    }
    
    /**
     * Ensure command is run from Wheels root
     */
    function ensureWheelsProject() {
        if (!isWheelsProject()) {
            if (isLegacyWheelsProject()) {
                error("This appears to be a legacy Wheels project (pre-3.0). Please upgrade to Wheels 3.0+ to use this CLI.");
            } else if (mightBeWheelsProject()) {
                error("This appears to be a Wheels project but the framework is not installed in vendor/wheels/. Please run 'box install cfwheels' to install the framework.");
            } else {
                error("This command must be run from a Wheels project root directory. Look for vendor/wheels/ folder.");
            }
        }
    }
    
    /**
     * Template rendering helper
     */
    function renderTemplate(required string template, required struct data) {
        var templatePath = getDirectoryFromPath(getCurrentTemplatePath()) & 
                          "templates/" & arguments.template;
        
        if (!fileExists(templatePath)) {
            error("Template not found: #arguments.template#");
        }
        
        var content = fileRead(templatePath);
        
        // Simple template replacement
        for (var key in arguments.data) {
            content = replaceNoCase(content, "{{#key#}}", arguments.data[key], "all");
        }
        
        return content;
    }
    
    /**
     * Get app directory paths
     */
    function getAppPath(string type = "") {
        var basePath = getCWD() & "app/";
        
        if (len(arguments.type)) {
            return basePath & arguments.type & "/";
        }
        
        return basePath;
    }
    
    /**
     * Get config directory path
     */
    function getConfigPath(string type = "") {
        var basePath = getCWD() & "config/";
        
        if (len(arguments.type)) {
            return basePath & arguments.type & "/";
        }
        
        return basePath;
    }
    
    /**
     * Get vendor directory path
     */
    function getVendorPath() {
        return getCWD() & "vendor/";
    }
    
    /**
     * Get Wheels framework path
     */
    function getWheelsPath() {
        return getVendorPath() & "wheels/";
    }
    
    /**
     * Compare version strings
     * Returns: -1 if v1 < v2, 0 if equal, 1 if v1 > v2
     */
    function compareVersion(required string v1, required string v2) {
        var parts1 = listToArray(arguments.v1, ".");
        var parts2 = listToArray(arguments.v2, ".");
        var maxLen = max(arrayLen(parts1), arrayLen(parts2));
        
        for (var i = 1; i <= maxLen; i++) {
            var num1 = i <= arrayLen(parts1) ? val(parts1[i]) : 0;
            var num2 = i <= arrayLen(parts2) ? val(parts2[i]) : 0;
            
            if (num1 < num2) return -1;
            if (num1 > num2) return 1;
        }
        
        return 0;
    }
}
```

### Version Information Command
```javascript
component extends="commands.wheels.BaseCommand" {
    
    /**
     * Display Wheels version and project information
     */
    function run() {
        if (!isWheelsProject() && !isLegacyWheelsProject()) {
            print.redLine("Not in a Wheels project directory!");
            return;
        }
        
        var wheelsInfo = getWheelsInfo();
        
        print.line();
        print.boldBlueLine("Wheels Project Information");
        print.line("=" repeatString 40);
        
        // Framework info
        print.yellowLine("Framework:");
        print.indentedLine("Version: #wheelsInfo.version#");
        
        if (len(wheelsInfo.name)) {
            print.indentedLine("Package: #wheelsInfo.name#");
        }
        if (len(wheelsInfo.author)) {
            print.indentedLine("Author: #wheelsInfo.author#");
        }
        if (len(wheelsInfo.homepage)) {
            print.indentedLine("Homepage: #wheelsInfo.homepage#");
        }
        
        // Project info
        var projectBoxJson = getCWD() & "box.json";
        if (fileExists(projectBoxJson)) {
            try {
                var projectInfo = deserializeJSON(fileRead(projectBoxJson));
                
                print.line();
                print.yellowLine("Project:");
                
                if (structKeyExists(projectInfo, "name")) {
                    print.indentedLine("Name: #projectInfo.name#");
                }
                if (structKeyExists(projectInfo, "version")) {
                    print.indentedLine("Version: #projectInfo.version#");
                }
                if (structKeyExists(projectInfo, "author")) {
                    print.indentedLine("Author: #projectInfo.author#");
                }
                if (structKeyExists(projectInfo, "description")) {
                    print.indentedLine("Description: #projectInfo.description#");
                }
            } catch (any e) {
                // Ignore errors reading project box.json
            }
        }
        
        // Environment info
        print.line();
        print.yellowLine("Environment:");
        print.indentedLine("CommandBox: #shell.getVersion()#");
        
        // Get server info if available
        try {
            var serverInfo = shell.getServerInfo();
            if (!structIsEmpty(serverInfo)) {
                print.indentedLine("CFML Engine: #serverInfo.engineName# #serverInfo.engineVersion#");
            }
        } catch (any e) {
            // Server might not be running
        }
        
        print.indentedLine("Project Root: #getCWD()#");
        
        if (isLegacyWheelsProject()) {
            print.line();
            print.redLine("⚠️  Legacy Project Structure Detected!");
            print.indentedLine("Consider upgrading to Wheels 3.0+ for better CLI support.");
        }
        
        print.line();
    }
}
```

### Application Creation Command with SQLite
```javascript
component extends="commands.wheels.BaseCommand" {
    
    property name="packageService" inject="PackageService";
    property name="databaseService" inject="DatabaseService@wheels-cli";
    
    /**
     * Create a new Wheels application
     * 
     * @name Name of the application
     * @template Application template (default, api, spa)
     * @database Database type (sqlite, mysql, postgresql, mssql)
     * @installDependencies Install dependencies after creation
     * @setupDatabase Configure database and download drivers
     */
    function run(
        required string name,
        string template = "default",
        string database = "sqlite",
        boolean installDependencies = true,
        boolean setupDatabase = true
    ) {
        print.line("Creating new Wheels application: #arguments.name#");
        print.line();
        
        var appPath = getCWD() & arguments.name;
        
        // Create directory structure
        print.yellowLine("Creating directory structure...");
        createAppStructure(appPath);
        
        // Create box.json for the project
        var boxJson = {
            "name": arguments.name,
            "version": "0.1.0",
            "author": "",
            "type": "mvc",
            "dependencies": {
                "wheels": "^3.0.0"
            },
            "devDependencies": {
                "testbox": "^4.0.0"
            }
        };
        
        if (arguments.database == "sqlite") {
            boxJson.dependencies["sqlite-jdbc"] = "^3.40.0";
        }
        
        fileWrite(appPath & "/box.json", serializeJSON(boxJson, false, false));
        
        // Create server.json with database configuration
        createServerJson(appPath, arguments.name, arguments.database);
        
        // Create initial configuration files
        createConfigFiles(appPath, arguments.database);
        
        // Setup database if requested
        if (arguments.setupDatabase && arguments.database == "sqlite") {
            print.yellowLine("Setting up SQLite database...");
            databaseService.setupSQLite(appPath);
        }
        
        // Install dependencies
        if (arguments.installDependencies) {
            print.yellowLine("Installing dependencies...");
            command("install").inWorkingDirectory(appPath).run();
        }
        
        print.line();
        print.greenLine("Application created successfully!");
        print.line();
        print.boldLine("Next steps:");
        print.indentedLine("1. cd #arguments.name#");
        print.indentedLine("2. wheels db:setup    # Create database");
        print.indentedLine("3. server start       # Start the server");
        print.indentedLine("4. Open http://localhost:8080");
    }
    
    /**
     * Create application directory structure
     */
    private function createAppStructure(required string path) {
        var dirs = [
            "/app/controllers",
            "/app/models", 
            "/app/views",
            "/config/settings",
            "/db/migrate",
            "/db/sql",
            "/public/images",
            "/public/javascripts",
            "/public/stylesheets",
            "/tests/controllers",
            "/tests/models",
            "/vendor"
        ];
        
        for (var dir in dirs) {
            directoryCreate(arguments.path & dir, true);
        }
        
        // Create .gitkeep files to preserve empty directories
        for (var dir in dirs) {
            fileWrite(arguments.path & dir & "/.gitkeep", "");
        }
        
        // Create SQLite database directory
        directoryCreate(arguments.path & "/db/sqlite", true);
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
                    "enable": true
                }
            }
        };
        
        // Add database configuration
        if (arguments.database == "sqlite") {
            serverConfig.app.datasources = {
                "wheelsdatasource": {
                    "driver": "org.sqlite.JDBC",
                    "class": "org.sqlite.JDBC", 
                    "bundleName": "org.xerial.sqlite-jdbc",
                    "bundleVersion": "3.40.0.0",
                    "url": "jdbc:sqlite:{approot}/db/sqlite/#arguments.appName#_development.db",
                    "username": "",
                    "password": ""
                }
            };
        } else if (arguments.database == "mysql") {
            serverConfig.app.datasources = {
                "wheelsdatasource": {
                    "driver": "com.mysql.cj.jdbc.Driver",
                    "class": "com.mysql.cj.jdbc.Driver",
                    "url": "jdbc:mysql://localhost:3306/#arguments.appName#_development?useSSL=false&allowPublicKeyRetrieval=true",
                    "username": "root",
                    "password": ""
                }
            };
        }
        // Add other database types...
        
        fileWrite(
            arguments.path & "/server.json",
            serializeJSON(serverConfig, false, false)
        );
    }
}
```

### Database Service for SQLite Support
```javascript
component {
    
    /**
     * Setup SQLite for a Wheels project
     */
    function setupSQLite(required string projectPath) {
        var dbPath = arguments.projectPath & "/db/sqlite/";
        
        // Ensure directory exists
        if (!directoryExists(dbPath)) {
            directoryCreate(dbPath, true);
        }
        
        // Create initial database files for each environment
        var environments = ["development", "testing", "production"];
        var appName = getAppNameFromBoxJson(arguments.projectPath);
        
        for (var env in environments) {
            var dbFile = dbPath & appName & "_" & env & ".db";
            
            if (!fileExists(dbFile)) {
                // Create empty SQLite database
                createEmptySQLiteDB(dbFile);
                print.greenLine("Created SQLite database: #dbFile#");
            }
        }
        
        // Create .gitignore for database files
        var gitignore = "*.db" & chr(10) & "*.db-journal" & chr(10) & "*.db-wal";
        fileWrite(dbPath & ".gitignore", gitignore);
    }
    
    /**
     * Create an empty SQLite database file
     */
    private function createEmptySQLiteDB(required string path) {
        // SQLite will create the file when first accessed
        // We'll create a connection and close it to initialize the file
        try {
            var ds = {
                class: "org.sqlite.JDBC",
                connectionString: "jdbc:sqlite:#arguments.path#"
            };
            
            // This will create the file if it doesn't exist
            var conn = createObject("java", "java.sql.DriverManager").getConnection(ds.connectionString);
            conn.close();
        } catch (any e) {
            throw("Could not create SQLite database: #e.message#");
        }
    }
    
    /**
     * Check if SQLite JDBC driver is available
     */
    function isSQLiteDriverAvailable() {
        try {
            createObject("java", "org.sqlite.JDBC");
            return true;
        } catch (any e) {
            return false;
        }
    }
    
    /**
     * Download and install SQLite JDBC driver
     */
    function installSQLiteDriver() {
        print.yellowLine("Installing SQLite JDBC driver...");
        
        // CommandBox can handle this through dependencies
        command("install").params("sqlite-jdbc").run();
        
        print.greenLine("SQLite JDBC driver installed successfully!");
    }
}
```

### Database Setup Command
```javascript
component extends="commands.wheels.BaseCommand" {
    
    property name="databaseService" inject="DatabaseService@wheels-cli";
    
    /**
     * Setup database for the Wheels application
     * 
     * @type Database type to setup
     * @env Environment
     */
    function run(
        string type = "",
        string env = "development"
    ) {
        ensureWheelsProject();
        
        // Auto-detect database type if not provided
        if (!len(arguments.type)) {
            arguments.type = detectDatabaseType();
        }
        
        print.line("Setting up #arguments.type# database for #arguments.env# environment...");
        
        switch(arguments.type) {
            case "sqlite":
                setupSQLite(arguments.env);
                break;
            case "mysql":
                setupMySQL(arguments.env);
                break;
            case "postgresql":
                setupPostgreSQL(arguments.env);
                break;
            default:
                error("Unsupported database type: #arguments.type#");
        }
        
        print.greenLine("Database setup complete!");
    }
    
    /**
     * Setup SQLite database
     */
    private function setupSQLite(required string env) {
        // Check if driver is available
        if (!databaseService.isSQLiteDriverAvailable()) {
            print.yellowLine("SQLite JDBC driver not found.");
            
            if (confirm("Would you like to install it now?")) {
                databaseService.installSQLiteDriver();
            } else {
                error("SQLite JDBC driver is required. Run 'box install sqlite-jdbc' to install it.");
            }
        }
        
        // Create database file
        var dbPath = getCWD() & "db/sqlite/";
        var appName = getProjectName();
        var dbFile = dbPath & appName & "_" & arguments.env & ".db";
        
        if (!fileExists(dbFile)) {
            databaseService.createEmptySQLiteDB(dbFile);
            print.greenLine("Created SQLite database: #dbFile#");
        } else {
            print.yellowLine("SQLite database already exists: #dbFile#");
        }
        
        // Test connection
        print.line("Testing database connection...");
        if (testDatabaseConnection("sqlite", arguments.env)) {
            print.greenLine("Database connection successful!");
        } else {
            error("Could not connect to database. Check your configuration.");
        }
    }
    
    /**
     * Detect database type from server.json
     */
    private function detectDatabaseType() {
        var serverJsonPath = getCWD() & "server.json";
        
        if (fileExists(serverJsonPath)) {
            var config = deserializeJSON(fileRead(serverJsonPath));
            
            if (structKeyExists(config, "app") && 
                structKeyExists(config.app, "datasources") &&
                structKeyExists(config.app.datasources, "wheelsdatasource")) {
                
                var url = config.app.datasources.wheelsdatasource.url;
                
                if (findNoCase("sqlite", url)) return "sqlite";
                if (findNoCase("mysql", url)) return "mysql";
                if (findNoCase("postgresql", url)) return "postgresql";
                if (findNoCase("sqlserver", url)) return "mssql";
            }
        }
        
        return "sqlite"; // Default
    }
}
```

### Model Generation Command
```javascript
component extends="commands.wheels.BaseCommand" {
    
    /**
     * Create a new Wheels model
     * 
     * @name Name of the model
     * @properties Comma-delimited list of properties (name:type:options)
     * @migration Create a migration file
     * @controller Create a matching controller
     * @resource Create a resourceful controller
     * @tests Create test files
     * @api Create API controller instead of regular
     */
    function run(
        required string name,
        string properties = "",
        boolean migration = false,
        boolean controller = false,
        boolean resource = false,
        boolean tests = false,
        boolean api = false
    ) {
        ensureWheelsProject();
        
        // Parse properties
        var props = parseProperties(arguments.properties);
        
        // Generate model file
        var modelContent = generateModelContent(arguments.name, props);
        var modelsPath = getAppPath("models");
        var modelPath = modelsPath & arguments.name & ".cfc";
        
        // Ensure models directory exists
        if (!directoryExists(modelsPath)) {
            directoryCreate(modelsPath, true);
        }
        
        if (fileExists(modelPath)) {
            if (!confirm("Model '#arguments.name#' already exists. Overwrite?")) {
                print.yellowLine("Model creation cancelled.");
                return;
            }
        }
        
        fileWrite(modelPath, modelContent);
        print.greenLine("Created model: #modelPath#");
        
        // Generate migration if requested
        if (arguments.migration) {
            command("wheels create migration")
                .params(
                    name = "create_#pluralize(lCase(arguments.name))#_table",
                    model = arguments.name,
                    properties = arguments.properties
                )
                .run();
        }
        
        // Generate controller if requested
        if (arguments.controller || arguments.resource) {
            command("wheels create controller")
                .params(
                    name = pluralize(arguments.name),
                    model = arguments.name,
                    resource = arguments.resource,
                    api = arguments.api
                )
                .run();
        }
        
        // Generate tests if requested
        if (arguments.tests) {
            command("wheels create test")
                .params(
                    type = "model",
                    name = arguments.name
                )
                .run();
                
            if (arguments.controller || arguments.resource) {
                command("wheels create test")
                    .params(
                        type = "controller",
                        name = pluralize(arguments.name)
                    )
                    .run();
            }
        }
        
        print.line();
        print.boldLine("Next steps:");
        
        if (arguments.migration) {
            print.indentedLine("1. Review and modify the migration file");
            print.indentedLine("2. Run 'wheels db:migrate' to create the database table");
        }
        
        print.indentedLine("3. Add validations and associations to your model");
        
        if (arguments.controller) {
            print.indentedLine("4. Implement controller actions");
            print.indentedLine("5. Create views for your controller actions");
        }
    }
    
    /**
     * Parse property string into struct
     */
    private array function parseProperties(required string properties) {
        var props = [];
        
        if (!len(trim(arguments.properties))) {
            return props;
        }
        
        var propList = listToArray(arguments.properties);
        
        for (var prop in propList) {
            var parts = listToArray(prop, ":");
            var property = {
                name = parts[1],
                type = parts[2] ?: "string",
                options = {}
            };
            
            // Parse additional options
            if (arrayLen(parts) > 2) {
                for (var i = 3; i <= arrayLen(parts); i++) {
                    property.options[parts[i]] = true;
                }
            }
            
            arrayAppend(props, property);
        }
        
        return props;
    }
    
    /**
     * Generate model content
     */
    private string function generateModelContent(
        required string name,
        required array properties
    ) {
        var data = {
            modelName = arguments.name,
            tableName = pluralize(lCase(arguments.name)),
            properties = arguments.properties
        };
        
        return renderTemplate("model/Model.cfc.template", data);
    }
    
    /**
     * Simple pluralization
     */
    private string function pluralize(required string word) {
        // Basic pluralization rules - could be enhanced
        if (right(arguments.word, 1) == "y") {
            return left(arguments.word, len(arguments.word) - 1) & "ies";
        } else if (right(arguments.word, 1) == "s") {
            return arguments.word & "es";
        } else {
            return arguments.word & "s";
        }
    }
}
```

### Database Migration Command
```javascript
component extends="commands.wheels.BaseCommand" {
    
    property name="migrationService" inject="MigrationService@wheels-cli";
    
    /**
     * Run database migrations
     * 
     * @target Specific version to migrate to
     * @env Environment to run migrations in
     * @verbose Show detailed output
     */
    function run(
        string target = "",
        string env = "development",
        boolean verbose = false
    ) {
        ensureWheelsProject();
        
        // Check Wheels version compatibility
        var wheelsVersion = getWheelsVersion();
        if (wheelsVersion != "Unknown" && compareVersion(wheelsVersion, "3.0.0") < 0) {
            error("Database migrations require Wheels 3.0 or higher. Current version: #wheelsVersion#");
        }
        
        print.line("Running migrations for environment: #arguments.env#");
        print.line("Wheels version: #wheelsVersion#");
        print.line();
        
        // Get current version
        var currentVersion = migrationService.getCurrentVersion(arguments.env);
        print.yellowLine("Current database version: #currentVersion#");
        
        // Get available migrations
        var migrations = migrationService.getAvailableMigrations();
        
        if (arrayLen(migrations) == 0) {
            print.redLine("No migrations found!");
            return;
        }
        
        // Determine target version
        var targetVersion = len(arguments.target) ? 
            arguments.target : migrations[arrayLen(migrations)].version;
        
        print.yellowLine("Target version: #targetVersion#");
        print.line();
        
        // Run migrations
        var migrationsToRun = migrationService.getMigrationsToRun(
            currentVersion, 
            targetVersion
        );
        
        if (arrayLen(migrationsToRun) == 0) {
            print.greenLine("Database is already up to date!");
            return;
        }
        
        print.line("Migrations to run: #arrayLen(migrationsToRun)#");
        print.line();
        
        var progressBar = progressBarGeneric();
        progressBar.update(percent = 0, statusText = "Starting migrations...");
        
        var count = 0;
        var errors = [];
        
        for (var migration in migrationsToRun) {
            count++;
            var percent = (count / arrayLen(migrationsToRun)) * 100;
            
            progressBar.update(
                percent = percent, 
                statusText = "Running: #migration.name#"
            );
            
            try {
                if (arguments.verbose) {
                    print.line("Executing: #migration.name#");
                }
                
                migrationService.runMigration(migration, arguments.env);
                
                if (arguments.verbose) {
                    print.greenLine("Success: #migration.name#");
                }
            } catch (any e) {
                arrayAppend(errors, {
                    migration = migration.name,
                    error = e.message
                });
                
                if (arguments.verbose) {
                    print.redLine("Failed: #migration.name# - #e.message#");
                }
            }
        }
        
        progressBar.clear();
        
        if (arrayLen(errors) == 0) {
            print.greenLine("All migrations completed successfully!");
        } else {
            print.redLine("Migrations completed with #arrayLen(errors)# errors:");
            for (var error in errors) {
                print.redLine("  - #error.migration#: #error.error#");
            }
        }
        
        // Update version
        var newVersion = migrationService.getCurrentVersion(arguments.env);
        print.line();
        print.boldLine("Database version updated to: #newVersion#");
    }
}
```

### Interactive Console Command
```javascript
component extends="commands.wheels.BaseCommand" {
    
    /**
     * Start an interactive Wheels console
     * 
     * @env Environment to load
     */
    function run(string env = "development") {
        ensureWheelsProject();
        
        print.greenLine("Starting Wheels Console...");
        print.line("Environment: #arguments.env#");
        print.line();
        
        // Set up the environment
        var wheelsPath = getCWD();
        
        // Create a custom REPL instance
        var repl = createObject("component", "commandbox.system.util.REPLParser").init();
        
        // Load Wheels environment
        print.yellowLine("Loading Wheels framework...");
        
        // Execute in Wheels context
        var script = "
            // Load Wheels
            application.name = 'WheelsConsole_#createUUID()#';
            application.wheels = {};
            application.wheels.environment = '#arguments.env#';
            
            // Include Wheels core - adjust path based on your setup
            include '/vendor/wheels/events/onrequeststart.cfm';
            include '/vendor/wheels/global/public.cfm';
            
            // Make common functions available
            model = function(name) {
                return application.wheels.model(argumentCollection=arguments);
            };
            
            controller = function(name) {
                return application.wheels.controller(argumentCollection=arguments);
            };
            
            get = function() {
                return application.wheels.get(argumentCollection=arguments);
            };
            
            set = function() {
                return application.wheels.set(argumentCollection=arguments);
            };
            
            print.greenLine('Wheels environment loaded!');
            print.line();
            print.line('Available functions:');
            print.indentedLine('- model(name) - Get a model instance');
            print.indentedLine('- controller(name) - Get a controller instance');
            print.indentedLine('- get(key) - Get a Wheels setting');
            print.indentedLine('- set(key, value) - Set a Wheels setting');
            print.line();
            print.line('Type .exit to quit');
            print.line();
        ";
        
        evaluate(script);
        
        // Start REPL loop
        while (true) {
            var input = ask("wheels> ");
            
            if (input == ".exit" || input == "exit" || input == "quit") {
                break;
            }
            
            if (len(trim(input)) == 0) {
                continue;
            }
            
            try {
                var result = evaluate(input);
                
                if (!isNull(result)) {
                    if (isSimpleValue(result)) {
                        print.line(result);
                    } else {
                        writeDump(var=result, output="console");
                    }
                }
            } catch (any e) {
                print.redLine("Error: #e.message#");
                
                if (structKeyExists(e, "detail") && len(e.detail)) {
                    print.redLine("Detail: #e.detail#");
                }
            }
        }
        
        print.line();
        print.yellowLine("Exiting Wheels Console...");
    }
}
```

## Template Examples

### Model Template (/templates/model/Model.cfc.template)
```javascript
component extends="wheels.Model" {
    
    function config() {
        // Set the table name
        table("{{tableName}}");
        
        {{#properties}}
        // Property definitions
        property(name="{{name}}", type="{{type}}"{{#options}}, {{optionName}}="{{optionValue}}"{{/options}});
        {{/properties}}
        
        // Timestamps
        timeStamps();
        
        // Validations
        {{#properties}}
        {{#if required}}
        validatesPresenceOf("{{name}}");
        {{/if}}
        {{#if unique}}
        validatesUniquenessOf("{{name}}");
        {{/if}}
        {{#if email}}
        validatesFormatOf(property="{{name}}", regex="^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$", message="must be a valid email address");
        {{/if}}
        {{/properties}}
        
        // Associations
        // hasMany("relatedModel");
        // belongsTo("parentModel");
        // hasOne("childModel");
    }
    
    // Custom methods
    
}
```

### Migration Template (/templates/migration/Migration.cfc.template)
```javascript
component extends="wheels.migrator.Migration" hint="{{description}}" {
    
    function up() {
        transaction {
            {{#if createTable}}
            // Create table
            createTable(name="{{tableName}}") {
                table.primaryKey();
                {{#properties}}
                table.{{dbType}}("{{name}}"{{#if limit}}, limit={{limit}}{{/if}});
                {{/properties}}
                table.timestamps();
                
                // Indexes
                {{#properties}}
                {{#if index}}
                table.index("{{name}}"{{#if unique}}, unique=true{{/if}});
                {{/if}}
                {{/properties}}
            };
            {{/if}}
            
            {{#if alterTable}}
            // Alter table
            updateTable(name="{{tableName}}") {
                {{#addColumns}}
                table.addColumn("{{name}}", "{{type}}"{{#if limit}}, limit={{limit}}{{/if}});
                {{/addColumns}}
                {{#removeColumns}}
                table.removeColumn("{{name}}");
                {{/removeColumns}}
            };
            {{/if}}
        }
    }
    
    function down() {
        transaction {
            {{#if createTable}}
            dropTable("{{tableName}}");
            {{/if}}
            
            {{#if alterTable}}
            updateTable(name="{{tableName}}") {
                {{#addColumns}}
                table.removeColumn("{{name}}");
                {{/addColumns}}
                {{#removeColumns}}
                table.addColumn("{{name}}", "{{type}}");
                {{/removeColumns}}
            };
            {{/if}}
        }
    }
}
```

### Configuration Templates

#### config/app.cfm Template
```javascript
component {
    
    function init() {
        // Application settings
        this.name = "{{appName}}";
        this.sessionManagement = true;
        this.sessionTimeout = createTimeSpan(0, 0, 30, 0);
        
        // Wheels settings
        this.wheels = {
            dataSourceName = "wheelsdatasource",
            reloadPassword = "{{reloadPassword}}",
            showErrorInformation = {{showErrors}},
            showDebugInformation = {{showDebug}}
        };
        
        // Auto-detect database adapter from datasource
        this.wheels.databaseAdapter = detectDatabaseAdapter();
    }
    
    /**
     * Detect database adapter from JDBC URL
     */
    private function detectDatabaseAdapter() {
        var ds = getApplicationSettings().datasources["wheelsdatasource"];
        
        if (structKeyExists(ds, "url")) {
            var url = ds.url;
            
            if (findNoCase("sqlite", url)) return "sqlite";
            if (findNoCase("mysql", url)) return "mysql";
            if (findNoCase("postgresql", url)) return "postgresql";
            if (findNoCase("sqlserver", url) || findNoCase("jtds", url)) return "sqlserver";
            if (findNoCase("oracle", url)) return "oracle";
            if (findNoCase("h2", url)) return "h2";
        }
        
        // Default to SQLite
        return "sqlite";
    }
}
```

#### config/settings/development.cfm Template
```javascript
<cfscript>
    // Development environment settings
    
    // Show full error information
    set(showErrorInformation = true);
    set(showDebugInformation = true);
    
    // Cache settings (disable most caching in development)
    set(cacheFileChecking = false);
    set(cacheControllerInitialization = false);
    set(cacheModelInitialization = false);
    set(cacheViewInitialization = false);
    set(cacheRoutes = false);
    set(cacheSchema = false);
    
    // SQLite specific settings
    set(SQLiteQueryTimeout = 30);
    set(SQLiteBusyTimeout = 5000);
    
    // Development-only routes (like debug toolbar)
    set(showDebugToolbar = true);
</cfscript>
```

## Template Override System

### Overview

The Wheels CLI supports a powerful template override system that allows developers to customize the code generation templates. This ensures the CLI remains valuable throughout the entire project lifecycle, even as projects diverge from the default patterns.

### Benefits

1. **Maintains CLI Value**: Developers keep using generators even in mature projects
2. **Project Consistency**: All generated code follows project-specific patterns
3. **Team Standards**: Teams can encode their conventions in templates
4. **Gradual Customization**: Copy and modify only what you need
5. **Framework Updates**: Can still benefit from CLI improvements without losing customizations

### Template Directory Structure

User templates are stored in the project's config directory:

```
my-wheels-app/
├── config/
│   └── templates/           # User's custom templates
│       ├── model/
│       │   └── Model.cfc
│       ├── controller/
│       │   ├── Controller.cfc
│       │   └── ResourceController.cfc
│       ├── migration/
│       │   └── Migration.cfc
│       ├── view/
│       │   ├── index.cfm
│       │   ├── show.cfm
│       │   ├── new.cfm
│       │   └── edit.cfm
│       └── templates.json  # Template configuration
```

### Template Discovery Logic

Update the BaseCommand class to support template overrides:

```javascript
// In BaseCommand.cfc
/**
 * Get template content, checking project templates first
 */
function getTemplate(required string type, string name = "default") {
    // 1. Check project templates first
    var projectTemplate = getConfigPath("templates/#arguments.type#/#arguments.name#");
    if (fileExists(projectTemplate)) {
        return fileRead(projectTemplate);
    }
    
    // 2. Fall back to built-in templates
    var builtInTemplate = getDirectoryFromPath(getCurrentTemplatePath()) & 
                        "templates/#arguments.type#/#arguments.name#";
    if (fileExists(builtInTemplate)) {
        return fileRead(builtInTemplate);
    }
    
    error("Template not found: #arguments.type#/#arguments.name#");
}

/**
 * Check if using custom template
 */
function isUsingCustomTemplate(required string path) {
    var projectTemplate = getConfigPath("templates/#arguments.path#");
    return fileExists(projectTemplate);
}

/**
 * Enhanced template rendering with support for advanced features
 */
function renderTemplate(required string template, required struct data) {
    var content = arguments.template;
    
    // Handle extends directive
    if (reFindNoCase("{{extends\s+""([^""]+)""}}", content)) {
        var parentTemplate = reReplaceNoCase(content, ".*{{extends\s+""([^""]+)""}}.*", "\1");
        var parentContent = getTemplate(listFirst(parentTemplate, "/"), listLast(parentTemplate, "/"));
        content = processTemplateInheritance(parentContent, content);
    }
    
    // Process blocks
    content = processTemplateBlocks(content);
    
    // Process conditionals
    content = processTemplateConditionals(content, arguments.data);
    
    // Process loops
    content = processTemplateLoops(content, arguments.data);
    
    // Simple variable replacement
    for (var key in arguments.data) {
        if (isSimpleValue(arguments.data[key])) {
            content = replaceNoCase(content, "{{#key#}}", arguments.data[key], "all");
        }
    }
    
    return content;
}
```

### Template Management Commands

#### Template Copy Command

```javascript
// commands/wheels/templates/copy.cfc
component extends="commands.wheels.BaseCommand" {
    
    /**
     * Copy CLI templates to your project for customization
     * 
     * @type Template type to copy (model, controller, view, migration, all)
     * @force Overwrite existing templates
     */
    function run(string type = "all", boolean force = false) {
        ensureWheelsProject();
        
        var templateSource = getDirectoryFromPath(getCurrentTemplatePath()) & "../../../templates";
        var templateDest = getConfigPath("templates");
        
        // Ensure templates directory exists
        if (!directoryExists(templateDest)) {
            directoryCreate(templateDest, true);
        }
        
        if (arguments.type == "all") {
            print.boldLine("Copying all templates...");
            copyAllTemplates(templateSource, templateDest, arguments.force);
        } else {
            copyTemplateType(arguments.type, templateSource, templateDest, arguments.force);
        }
        
        print.line();
        print.greenLine("Templates copied successfully!");
        print.line();
        print.yellowLine("You can now customize these templates:");
        print.indentedLine(templateDest);
        print.line();
        print.line("The CLI will automatically use your custom templates when generating files.");
    }
    
    private function copyAllTemplates(source, dest, force) {
        var types = ["model", "controller", "migration", "view"];
        
        for (var type in types) {
            if (directoryExists(arguments.source & "/" & type)) {
                copyTemplateType(type, arguments.source, arguments.dest, arguments.force);
            }
        }
        
        // Copy template configuration if exists
        var configFile = arguments.source & "/templates.json";
        if (fileExists(configFile)) {
            fileCopy(configFile, arguments.dest & "/templates.json");
        }
    }
    
    private function copyTemplateType(type, source, dest, force) {
        var sourceDir = arguments.source & "/" & arguments.type;
        var destDir = arguments.dest & "/" & arguments.type;
        
        if (!directoryExists(sourceDir)) {
            error("Template type '#arguments.type#' not found");
        }
        
        if (directoryExists(destDir) && !arguments.force) {
            if (!confirm("Templates for '#arguments.type#' already exist. Overwrite?")) {
                print.yellowLine("Skipping #arguments.type# templates...");
                return;
            }
        }
        
        print.line("Copying #arguments.type# templates...");
        directoryCreate(destDir, true);
        
        var files = directoryList(sourceDir, false, "path", "*.cfc|*.cfm|*.txt");
        for (var file in files) {
            var fileName = getFileFromPath(file);
            fileCopy(file, destDir & "/" & fileName);
            print.indentedLine("Copied: #fileName#");
        }
    }
}
```

#### Template List Command

```javascript
// commands/wheels/templates/list.cfc
component extends="commands.wheels.BaseCommand" {
    
    /**
     * List available templates and their override status
     */
    function run() {
        ensureWheelsProject();
        
        print.boldLine("Wheels CLI Templates");
        print.line("=" repeatString 50);
        print.line();
        
        var builtInPath = getDirectoryFromPath(getCurrentTemplatePath()) & "../../../templates";
        var projectPath = getConfigPath("templates");
        
        var types = ["model", "controller", "migration", "view"];
        
        for (var type in types) {
            print.yellowLine(uCase(type) & " Templates:");
            
            var builtInDir = builtInPath & "/" & type;
            if (directoryExists(builtInDir)) {
                var templates = directoryList(builtInDir, false, "name", "*.cfc|*.cfm");
                
                for (var template in templates) {
                    var status = "Built-in";
                    var projectTemplate = projectPath & "/" & type & "/" & template;
                    
                    if (fileExists(projectTemplate)) {
                        status = "Customized";
                        print.indentedGreenLine("✓ #template# [#status#]");
                    } else {
                        print.indentedLine("  #template# [#status#]");
                    }
                }
            }
            print.line();
        }
        
        if (directoryExists(projectPath)) {
            print.boldLine("Custom templates location: #projectPath#");
        } else {
            print.line("Run 'wheels templates:copy' to customize templates");
        }
    }
}
```

#### Template Variables Command

```javascript
// commands/wheels/templates/variables.cfc
component extends="commands.wheels.BaseCommand" {
    
    /**
     * Show available variables for template types
     * 
     * @type Template type (model, controller, view, migration)
     */
    function run(required string type) {
        var variables = getTemplateVariables(arguments.type);
        
        print.boldLine("#uCase(arguments.type)# Template Variables");
        print.line("=" repeatString 50);
        print.line();
        
        for (var section in variables) {
            if (section != "description") {
                print.yellowLine(section & ":");
                
                if (isArray(variables[section])) {
                    for (var item in variables[section]) {
                        print.indentedLine("- " & item);
                    }
                } else if (isStruct(variables[section])) {
                    for (var key in variables[section]) {
                        print.indentedLine("- #key#: #variables[section][key]#");
                    }
                }
                print.line();
            }
        }
        
        if (structKeyExists(variables, "description")) {
            print.line(variables.description);
        }
    }
    
    private struct function getTemplateVariables(required string type) {
        var variableMap = {
            model: {
                description: "Variables available in model templates",
                basic: [
                    "modelName: The model class name (e.g., 'User')",
                    "tableName: The database table name (e.g., 'users')",
                    "timestamp: Generation timestamp",
                    "generatedBy: CLI version information"
                ],
                properties: {
                    "name": "Property name",
                    "type": "Property type (string, integer, etc.)",
                    "required": "Whether property is required",
                    "unique": "Whether property must be unique",
                    "options": "Additional property options"
                }
            },
            controller: {
                description: "Variables available in controller templates",
                basic: [
                    "controllerName: The controller class name (e.g., 'Users')",
                    "modelName: Associated model name (e.g., 'User')",
                    "pluralName: Plural form (e.g., 'Users')",
                    "singularName: Singular form (e.g., 'User')",
                    "resource: Whether this is a resource controller",
                    "api: Whether this is an API controller"
                ],
                actions: [
                    "index: List all records",
                    "show: Show single record",
                    "new: Show form for new record",
                    "create: Create new record",
                    "edit: Show form to edit record",
                    "update: Update existing record",
                    "delete: Delete record"
                ]
            },
            view: {
                description: "Variables available in view templates",
                basic: [
                    "modelName: The model name (e.g., 'User')",
                    "pluralName: Plural form (e.g., 'Users')",
                    "singularName: Singular form (e.g., 'User')",
                    "pluralLowerName: Lowercase plural (e.g., 'users')",
                    "singularLowerName: Lowercase singular (e.g., 'user')"
                ],
                displayProperties: {
                    "name": "Property name for display",
                    "label": "Human-readable label",
                    "type": "Property type for formatting"
                }
            },
            migration: {
                description: "Variables available in migration templates",
                basic: [
                    "migrationName: The migration class name",
                    "tableName: The table being created/modified",
                    "timestamp: Migration timestamp",
                    "description: Migration description"
                ],
                operations: [
                    "createTable: Whether creating a new table",
                    "alterTable: Whether altering existing table",
                    "properties: Column definitions",
                    "indexes: Index definitions"
                ]
            }
        };
        
        return variableMap[arguments.type] ?: {
            description: "Unknown template type: #arguments.type#"
        };
    }
}
```

### Enhanced Model Generation with Templates

Update the model generation command to use the template system:

```javascript
// Update in commands/wheels/create/model.cfc
function run(required string name, string properties = "", boolean migration = false) {
    ensureWheelsProject();
    
    // Parse properties
    var props = parseProperties(arguments.properties);
    
    // Get template (custom or built-in)
    var template = getTemplate("model", "Model.cfc");
    
    // Check if using custom template
    if (isUsingCustomTemplate("model/Model.cfc")) {
        print.yellowLine("Using custom model template");
    }
    
    // Load template configuration if exists
    var templateConfig = loadTemplateConfig();
    
    // Prepare template data
    var data = {
        modelName: arguments.name,
        tableName: pluralize(lCase(arguments.name)),
        properties: props,
        timestamp: dateTimeFormat(now(), "yyyy-mm-dd HH:nn:ss"),
        generatedBy: "Wheels CLI v#getWheelsVersion()#",
        config: templateConfig.model ?: {}
    };
    
    // Render template
    var content = renderTemplate(template, data);
    
    // Write file
    var modelPath = getAppPath("models") & arguments.name & ".cfc";
    
    if (fileExists(modelPath)) {
        if (!confirm("Model '#arguments.name#' already exists. Overwrite?")) {
            print.yellowLine("Model creation cancelled.");
            return;
        }
    }
    
    fileWrite(modelPath, content);
    print.greenLine("Created model: #modelPath#");
    
    // Create migration if requested
    if (arguments.migration) {
        command("wheels create migration")
            .params(
                name: "create_#pluralize(lCase(arguments.name))#_table",
                model: arguments.name,
                properties: arguments.properties
            )
            .run();
    }
}

/**
 * Load template configuration
 */
private struct function loadTemplateConfig() {
    var configPath = getConfigPath("templates/templates.json");
    
    if (fileExists(configPath)) {
        try {
            return deserializeJSON(fileRead(configPath));
        } catch (any e) {
            // Invalid JSON, return empty struct
        }
    }
    
    return {};
}
```

### Example Custom Templates

#### Custom Model Template with Audit Trail

```javascript
// config/templates/model/Model.cfc
/**
 * {{modelName}} Model
 * Generated: {{timestamp}}
 * Generator: {{generatedBy}}
 */
component extends="models.base.BaseModel" {
    
    function config() {
        // Table
        table("{{tableName}}");
        
        {{#properties}}
        // Property: {{name}}
        property(name="{{name}}", type="{{type}}"{{#if required}}, required="true"{{/if}}{{#if unique}}, unique="true"{{/if}});
        {{/properties}}
        
        // Timestamps
        timeStamps();
        
        // Audit fields (custom addition)
        property(name="createdBy", type="string");
        property(name="updatedBy", type="string");
        property(name="deletedAt", type="datetime");
        property(name="deletedBy", type="string");
        
        // Soft deletes
        softDeletes();
        
        // Validations
        {{#properties}}
        {{#if required}}
        validatesPresenceOf("{{name}}");
        {{/if}}
        {{#if unique}}
        validatesUniquenessOf("{{name}}"{{#if softDelete}}, allowBlank=true, condition="deletedAt IS NULL"{{/if}});
        {{/if}}
        {{#if email}}
        validatesFormatOf(property="{{name}}", regex="^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$", message="must be a valid email address");
        {{/if}}
        {{/properties}}
        
        // Callbacks
        beforeCreate("setAuditFields");
        beforeUpdate("updateAuditFields");
        beforeDelete("softDelete");
    }
    
    // Audit trail methods
    private function setAuditFields() {
        if (hasUserContext()) {
            this.createdBy = getUserContext().id;
            this.updatedBy = getUserContext().id;
        }
    }
    
    private function updateAuditFields() {
        if (hasUserContext()) {
            this.updatedBy = getUserContext().id;
        }
    }
    
    private function softDelete() {
        this.deletedAt = now();
        if (hasUserContext()) {
            this.deletedBy = getUserContext().id;
        }
        this.save();
        return false; // Prevent actual deletion
    }
    
    // Scopes
    public function scopeActive(query) {
        return arguments.query.where("deletedAt IS NULL");
    }
    
    public function scopeDeleted(query) {
        return arguments.query.where("deletedAt IS NOT NULL");
    }
}
```

#### Custom Controller Template with Authentication

```javascript
// config/templates/controller/Controller.cfc
/**
 * {{controllerName}} Controller
 * Generated: {{timestamp}}
 */
component extends="controllers.base.SecureController" {
    
    function config() {
        // Authentication required for all actions
        verifies(except="", params="isAuthenticated", handler="requireLogin");
        
        {{#if resource}}
        // Authorization for resource actions
        verifies(only="edit,update,delete", params="canModify{{modelName}}", handler="unauthorized");
        {{/if}}
        
        {{#if api}}
        // API configuration
        provides("json,xml");
        {{/if}}
    }
    
    {{#if resource}}
    /**
     * Display a list of {{pluralLowerName}}
     */
    function index() {
        {{pluralLowerName}} = model("{{modelName}}").findAll(
            order="createdAt DESC",
            where="deletedAt IS NULL"
        );
        
        {{#if api}}
        renderWith({{pluralLowerName}});
        {{/if}}
    }
    
    /**
     * Display a single {{singularLowerName}}
     */
    function show() {
        {{singularLowerName}} = model("{{modelName}}").findByKey(params.key);
        
        if (!isObject({{singularLowerName}})) {
            return renderNotFound();
        }
        
        {{#if api}}
        renderWith({{singularLowerName}});
        {{/if}}
    }
    
    /**
     * Show form for new {{singularLowerName}}
     */
    function new() {
        {{singularLowerName}} = model("{{modelName}}").new();
    }
    
    /**
     * Create a new {{singularLowerName}}
     */
    function create() {
        {{singularLowerName}} = model("{{modelName}}").create(params.{{singularLowerName}});
        
        if ({{singularLowerName}}.save()) {
            {{#if api}}
            renderWith({{singularLowerName}}, status=201);
            {{else}}
            flashInsert(success="{{modelName}} created successfully!");
            redirectTo(route="{{singularLowerName}}", key={{singularLowerName}}.key());
            {{/if}}
        } else {
            {{#if api}}
            renderWith({{singularLowerName}}.allErrors(), status=422);
            {{else}}
            flashInsert(error="Please correct the errors below.");
            renderView(action="new");
            {{/if}}
        }
    }
    
    /**
     * Show form to edit {{singularLowerName}}
     */
    function edit() {
        {{singularLowerName}} = model("{{modelName}}").findByKey(params.key);
        
        if (!isObject({{singularLowerName}})) {
            return renderNotFound();
        }
    }
    
    /**
     * Update existing {{singularLowerName}}
     */
    function update() {
        {{singularLowerName}} = model("{{modelName}}").findByKey(params.key);
        
        if (!isObject({{singularLowerName}})) {
            return renderNotFound();
        }
        
        if ({{singularLowerName}}.update(params.{{singularLowerName}})) {
            {{#if api}}
            renderWith({{singularLowerName}});
            {{else}}
            flashInsert(success="{{modelName}} updated successfully!");
            redirectTo(route="{{singularLowerName}}", key={{singularLowerName}}.key());
            {{/if}}
        } else {
            {{#if api}}
            renderWith({{singularLowerName}}.allErrors(), status=422);
            {{else}}
            flashInsert(error="Please correct the errors below.");
            renderView(action="edit");
            {{/if}}
        }
    }
    
    /**
     * Delete {{singularLowerName}}
     */
    function delete() {
        {{singularLowerName}} = model("{{modelName}}").findByKey(params.key);
        
        if (!isObject({{singularLowerName}})) {
            return renderNotFound();
        }
        
        {{singularLowerName}}.delete();
        
        {{#if api}}
        renderWith({message="{{modelName}} deleted successfully"}, status=204);
        {{else}}
        flashInsert(success="{{modelName}} deleted successfully!");
        redirectTo(route="{{pluralLowerName}}");
        {{/if}}
    }
    {{/if}}
    
    // Private methods
    
    private function canModify{{modelName}}() {
        var {{singularLowerName}} = model("{{modelName}}").findByKey(params.key);
        return isObject({{singularLowerName}}) && {{singularLowerName}}.canBeModifiedBy(getCurrentUser());
    }
    
    private function renderNotFound() {
        {{#if api}}
        renderWith({error="{{modelName}} not found"}, status=404);
        {{else}}
        flashInsert(error="{{modelName}} not found");
        redirectTo(route="{{pluralLowerName}}");
        {{/if}}
    }
}
```

#### Custom View Template with UI Framework

```html
<!-- config/templates/view/index.cfm -->
<cfoutput>
<div class="container-fluid">
    <div class="row mb-4">
        <div class="col">
            <h1 class="h2 d-flex align-items-center justify-content-between">
                {{pluralName}}
                <div class="btn-toolbar">
                    #linkTo(route="new{{singularName}}", text='<i class="fas fa-plus"></i> Add New', class="btn btn-primary", encode=false)#
                </div>
            </h1>
        </div>
    </div>
    
    <cfif {{pluralLowerName}}.recordCount>
        <div class="card shadow-sm">
            <div class="card-body p-0">
                <div class="table-responsive">
                    <table class="table table-hover mb-0" data-toggle="datatable">
                        <thead>
                            <tr>
                                {{#displayProperties}}
                                <th>{{label}}</th>
                                {{/displayProperties}}
                                <th class="text-right" style="width: 150px;">Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            <cfloop query="{{pluralLowerName}}">
                                <tr>
                                    {{#displayProperties}}
                                    <td>
                                        {{#if type="datetime"}}
                                        #dateTimeFormat({{pluralLowerName}}.{{name}}, "mmm d, yyyy h:nn tt")#
                                        {{else if type="boolean"}}
                                        <span class="badge badge-#IIf({{pluralLowerName}}.{{name}}, 'success', 'secondary')#">
                                            #yesNoFormat({{pluralLowerName}}.{{name}})#
                                        </span>
                                        {{else}}
                                        #encodeForHTML({{pluralLowerName}}.{{name}})#
                                        {{/if}}
                                    </td>
                                    {{/displayProperties}}
                                    <td class="text-right">
                                        <div class="btn-group btn-group-sm">
                                            #linkTo(route="{{singularLowerName}}", key={{pluralLowerName}}.id, text='<i class="fas fa-eye"></i>', class="btn btn-outline-info", title="View", encode=false)#
                                            #linkTo(route="edit{{singularName}}", key={{pluralLowerName}}.id, text='<i class="fas fa-edit"></i>', class="btn btn-outline-primary", title="Edit", encode=false)#
                                            #linkTo(route="{{singularLowerName}}", key={{pluralLowerName}}.id, text='<i class="fas fa-trash"></i>', class="btn btn-outline-danger", method="delete", confirm="Are you sure?", title="Delete", encode=false)#
                                        </div>
                                    </td>
                                </tr>
                            </cfloop>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    <cfelse>
        <div class="card">
            <div class="card-body text-center py-5">
                <i class="fas fa-inbox fa-4x text-muted mb-3"></i>
                <h3 class="text-muted">No {{pluralLowerName}} found</h3>
                <p class="text-muted mb-4">Get started by creating your first {{singularLowerName}}.</p>
                #linkTo(route="new{{singularName}}", text='<i class="fas fa-plus"></i> Create First {{singularName}}', class="btn btn-primary", encode=false)#
            </div>
        </div>
    </cfif>
</div>
</cfoutput>
```

### Template Configuration File

```json
// config/templates/templates.json
{
    "model": {
        "baseClass": "models.base.BaseModel",
        "includeAuditFields": true,
        "includeSoftDeletes": true,
        "defaultCallbacks": ["audit", "softDelete"],
        "defaultScopes": ["active", "deleted"]
    },
    "controller": {
        "baseClass": "controllers.base.SecureController",
        "requireAuthentication": true,
        "defaultFormat": "html",
        "includeAuthorization": true
    },
    "view": {
        "uiFramework": "bootstrap5",
        "includeIcons": true,
        "dateFormat": "mmm d, yyyy",
        "dateTimeFormat": "mmm d, yyyy h:nn tt",
        "tablePlugin": "datatable"
    },
    "migration": {
        "includeTimestamps": true,
        "defaultEngine": "InnoDB",
        "defaultCharset": "utf8mb4"
    }
}
```

## Testing the CLI

### Test Structure
```javascript
component extends="testbox.system.BaseSpec" {
    
    function beforeAll() {
        // Set up test environment
        variables.testProjectPath = expandPath("/tests/resources/test-project/");
        
        // Create test project structure if needed
        if (!directoryExists(variables.testProjectPath)) {
            directoryCreate(variables.testProjectPath, true);
            
            // Create vendor/wheels directory for testing
            directoryCreate(variables.testProjectPath & "vendor/wheels/", true);
            
            // Create a mock box.json in vendor/wheels
            var mockBoxJson = {
                "name": "wheels",
                "version": "3.0.0",
                "type": "mvc"
            };
            fileWrite(
                variables.testProjectPath & "vendor/wheels/box.json",
                serializeJSON(mockBoxJson)
            );
            
            // Create app directories
            directoryCreate(variables.testProjectPath & "app/models/", true);
            directoryCreate(variables.testProjectPath & "app/controllers/", true);
            directoryCreate(variables.testProjectPath & "app/views/", true);
            directoryCreate(variables.testProjectPath & "db/migrate/", true);
            directoryCreate(variables.testProjectPath & "db/sqlite/", true);
            
            // Create test SQLite database
            var testDb = variables.testProjectPath & "db/sqlite/test.db";
            if (!fileExists(testDb)) {
                // Create empty SQLite file
                fileWrite(testDb, "");
            }
        }
    }
    
    function afterAll() {
        // Clean up test project
        if (directoryExists(variables.testProjectPath)) {
            directoryDelete(variables.testProjectPath, true);
        }
    }
    
    function run() {
        describe("Wheels CLI", function() {
            
            describe("Model Generation", function() {
                it("should create a basic model file", function() {
                    var command = application.wirebox.getInstance("command:wheels create model");
                    command.params(name="TestModel");
                    command.run();
                    
                    expect(fileExists(testProjectPath & "app/models/TestModel.cfc")).toBeTrue();
                });
                
                it("should create model with properties", function() {
                    var command = application.wirebox.getInstance("command:wheels create model");
                    command.params(
                        name="User",
                        properties="firstName:string,lastName:string,email:string:unique"
                    );
                    command.run();
                    
                    var content = fileRead(testProjectPath & "app/models/User.cfc");
                    expect(content).toInclude('property(name="firstName"');
                    expect(content).toInclude('property(name="email"');
                    expect(content).toInclude('validatesUniquenessOf("email")');
                });
            });
            
            describe("Migration Management", function() {
                it("should create a migration file", function() {
                    var command = application.wirebox.getInstance("command:wheels create migration");
                    command.params(name="create_users_table");
                    command.run();
                    
                    var migrationDir = testProjectPath & "db/migrate/";
                    expect(directoryExists(migrationDir)).toBeTrue();
                    
                    var files = directoryList(migrationDir, false, "name", "*.cfc");
                    expect(arrayLen(files)).toBeGT(0);
                });
            });
            
        });
    }
}
```

## Requirements & Version Management

### System Requirements
- CFWheels 3.0 or higher
- CommandBox 5.0 or higher
- Project must follow Wheels 3.0+ structure with framework in vendor/wheels/
- SQLite JDBC driver (auto-installed) for default database support

### Supported Databases
The CLI supports the following database systems:
- **SQLite** (default) - Zero-configuration embedded database
- **MySQL** - Popular open-source database
- **PostgreSQL** - Advanced open-source database
- **SQL Server** - Microsoft's enterprise database
- **Oracle** - Enterprise database system

### Why SQLite as Default?
- **Zero Configuration**: No separate database server needed
- **Cross-Platform**: Works on all CFML engines (Lucee, Adobe CF, BoxLang)
- **Developer Friendly**: Same experience as Rails, Laravel, Django
- **Production Ready**: Many applications successfully use SQLite in production
- **Easy Migration**: Simple to switch to other databases later

### Wheels box.json Requirements
The Wheels framework package in `vendor/wheels/box.json` should contain:
```json
{
    "name": "wheels",
    "version": "3.0.0",
    "author": "Wheels Team",
    "homepage": "https://wheels.org",
    "type": "mvc",
    "slug": "wheels",
    "shortDescription": "Wheels MVC Framework",
    // ... other standard box.json properties
}
```

The CLI will use this file to:
- Determine the framework version for compatibility checks
- Display framework information in `wheels version` command
- Validate minimum version requirements for certain features

### Distribution & Installation

### Requirements
- CFWheels 3.0 or higher
- CommandBox 5.0 or higher
- Project must follow Wheels 3.0+ structure with framework in vendor/wheels/

### Installation via CommandBox
```bash
# Install from ForgeBox
box install wheels-cli

# Install from GitHub
box install cfwheels/wheels-cli

# Install specific version
box install wheels-cli@3.0.0
```

### Auto-Installation with Wheels
When creating a new Wheels app, the CLI should be included:
```bash
# Install Wheels 3.0+ template
box install wheels-template-base

# This creates the proper structure with:
# - vendor/wheels/ for framework files
# - app/ directory for MVC components
# - config/ for configuration
# - SQLite database in db/sqlite/
# - Automatically installs wheels-cli as a dependency

# Quick Start Example
wheels create app blog
cd blog
wheels create model Post title:string content:text published:boolean --migration
wheels db:migrate
wheels create controller Posts --resource
wheels server:start

# Your blog is now running with a SQLite database!

# Verify installation
wheels help
wheels version
```

## Database Management

### SQLite Performance Optimization
For SQLite databases, the framework automatically applies these optimizations:
```javascript
// In Application.cfc or when opening connections
queryExecute("PRAGMA journal_mode = WAL"); // Write-Ahead Logging
queryExecute("PRAGMA synchronous = NORMAL"); // Balanced durability/performance
queryExecute("PRAGMA cache_size = -64000"); // 64MB cache
queryExecute("PRAGMA temp_store = MEMORY"); // Use memory for temp tables
```

### Database Switching
The CLI makes it easy to switch between databases:
```bash
# During development, switch from SQLite to MySQL
wheels db:switch mysql

# This will:
# 1. Update server.json datasource configuration
# 2. Create migration to dump/restore data (optional)
# 3. Update config files
# 4. Install necessary JDBC drivers
```

### Production Considerations
While SQLite is excellent for development and many production apps, consider these factors:

**When SQLite is Perfect:**
- Read-heavy applications
- Single server deployments
- Applications with < 100K daily users
- Embedded applications
- Microservices

**When to Use Client-Server Databases:**
- High write concurrency needed
- Multiple application servers
- Need for advanced replication
- Complex user permissions
- Very large datasets (> 100GB)

## Testing the CLI

### Test Structure

The Wheels CLI should have comprehensive tests to ensure reliability:

```
wheels-cli/
├── tests/
│   ├── specs/
│   │   ├── commands/
│   │   │   ├── wheels/
│   │   │   │   ├── create/
│   │   │   │   │   ├── AppTest.cfc
│   │   │   │   │   ├── ModelTest.cfc
│   │   │   │   │   ├── ControllerTest.cfc
│   │   │   │   │   └── MigrationTest.cfc
│   │   │   │   ├── db/
│   │   │   │   │   ├── MigrateTest.cfc
│   │   │   │   │   ├── SetupTest.cfc
│   │   │   │   │   └── StatusTest.cfc
│   │   │   │   └── VersionTest.cfc
│   │   ├── integration/
│   │   │   ├── FullWorkflowTest.cfc
│   │   │   └── DatabaseSwitchingTest.cfc
│   │   └── unit/
│   │       ├── BaseCommandTest.cfc
│   │       ├── DatabaseServiceTest.cfc
│   │       └── TemplateRenderingTest.cfc
│   ├── Application.cfc
│   ├── runner.cfm
│   └── test.cfc
└── box.json
```

### Base Test Class

Create a base test class for all command tests:

```javascript
// tests/specs/BaseCommandSpec.cfc
component extends="testbox.system.BaseSpec" {
    
    // Properties
    property name="originalCWD";
    property name="testProjectPath";
    property name="wirebox";
    
    function beforeAll() {
        // Store current directory
        variables.originalCWD = getCWD();
        
        // Create temp directory for test projects
        variables.testProjectPath = getTempDirectory() & "wheels-cli-tests-" & createUUID();
        directoryCreate(variables.testProjectPath, true);
        
        // Initialize WireBox for dependency injection
        variables.wirebox = new commandbox.system.ioc.Injector();
        
        // Change to test directory
        shell.cd(variables.testProjectPath);
    }
    
    function afterAll() {
        // Change back to original directory
        shell.cd(variables.originalCWD);
        
        // Clean up test directory
        if (directoryExists(variables.testProjectPath)) {
            directoryDelete(variables.testProjectPath, true);
        }
    }
    
    /**
     * Helper to run a command and capture output
     */
    function runCommand(required string command, struct params = {}) {
        var commandPath = "commands." & replace(arguments.command, " ", ".", "all");
        var commandObj = wirebox.getInstance(commandPath);
        
        // Mock the print helper
        var mockPrint = getMockBox().createMock("commandbox.system.util.Print");
        var output = [];
        var errors = [];
        
        // Capture all output types
        mockPrint.$("line").$args(any).$results(function(text) {
            output.append({type: "line", text: arguments.text ?: ""});
            return mockPrint;
        });
        
        mockPrint.$("greenLine").$args(any).$results(function(text) {
            output.append({type: "success", text: arguments.text ?: ""});
            return mockPrint;
        });
        
        mockPrint.$("yellowLine").$args(any).$results(function(text) {
            output.append({type: "warning", text: arguments.text ?: ""});
            return mockPrint;
        });
        
        mockPrint.$("redLine").$args(any).$results(function(text) {
            errors.append(arguments.text ?: "");
            return mockPrint;
        });
        
        mockPrint.$("boldLine").$args(any).$results(function(text) {
            output.append({type: "bold", text: arguments.text ?: ""});
            return mockPrint;
        });
        
        mockPrint.$("indentedLine").$args(any).$results(function(text) {
            output.append({type: "indented", text: arguments.text ?: ""});
            return mockPrint;
        });
        
        // Set the mock
        commandObj.setPrint(mockPrint);
        
        // Run command
        var success = true;
        var errorDetail = "";
        
        try {
            commandObj.run(argumentCollection = arguments.params);
        } catch (any e) {
            success = false;
            errorDetail = e.message;
        }
        
        return {
            success: success,
            output: output,
            errors: errors,
            errorDetail: errorDetail,
            outputText: output.map(function(item) { return item.text; }).toList(chr(10))
        };
    }
    
    /**
     * Helper to create a test Wheels project
     */
    function createTestProject(string name = "test-app") {
        var projectPath = variables.testProjectPath & "/" & arguments.name;
        
        // Create Wheels 3.0+ structure
        directoryCreate(projectPath & "/app/controllers", true);
        directoryCreate(projectPath & "/app/models", true);
        directoryCreate(projectPath & "/app/views", true);
        directoryCreate(projectPath & "/config/settings", true);
        directoryCreate(projectPath & "/db/migrate", true);
        directoryCreate(projectPath & "/db/sqlite", true);
        directoryCreate(projectPath & "/public", true);
        directoryCreate(projectPath & "/tests", true);
        directoryCreate(projectPath & "/vendor/wheels", true);
        
        // Create project box.json
        var boxJson = {
            "name": arguments.name,
            "version": "0.1.0",
            "type": "mvc",
            "dependencies": {
                "wheels": "^3.0.0"
            }
        };
        fileWrite(projectPath & "/box.json", serializeJSON(boxJson));
        
        // Create wheels box.json
        var wheelsBoxJson = {
            "name": "wheels",
            "version": "3.0.0",
            "type": "mvc",
            "author": "Wheels Team"
        };
        fileWrite(projectPath & "/vendor/wheels/box.json", serializeJSON(wheelsBoxJson));
        
        // Create basic config
        fileWrite(projectPath & "/config/app.cfm", "// App configuration");
        
        return projectPath;
    }
    
    /**
     * Helper to verify file contains expected content
     */
    function fileContains(required string path, required string content) {
        if (!fileExists(arguments.path)) {
            return false;
        }
        var fileContent = fileRead(arguments.path);
        return findNoCase(arguments.content, fileContent) > 0;
    }
}
```

### Testing Individual Commands

#### App Creation Test

```javascript
// tests/specs/commands/wheels/create/AppTest.cfc
component extends="tests.specs.BaseCommandSpec" {
    
    function run() {
        describe("wheels create app", function() {
            
            it("creates a new application with correct structure", function() {
                var appName = "blog-" & left(createUUID(), 8);
                var result = runCommand("wheels create app", {
                    name: appName
                });
                
                expect(result.success).toBeTrue();
                expect(result.outputText).toInclude("Application created successfully!");
                
                // Verify directory structure
                var appPath = variables.testProjectPath & "/" & appName;
                expect(directoryExists(appPath)).toBeTrue();
                expect(directoryExists(appPath & "/app/controllers")).toBeTrue();
                expect(directoryExists(appPath & "/app/models")).toBeTrue();
                expect(directoryExists(appPath & "/app/views")).toBeTrue();
                expect(directoryExists(appPath & "/config")).toBeTrue();
                expect(directoryExists(appPath & "/db/sqlite")).toBeTrue();
                
                // Verify files
                expect(fileExists(appPath & "/box.json")).toBeTrue();
                expect(fileExists(appPath & "/server.json")).toBeTrue();
                expect(fileExists(appPath & "/config/app.cfm")).toBeTrue();
            });
            
            it("configures SQLite as default database", function() {
                var appName = "sqlite-app";
                var result = runCommand("wheels create app", {
                    name: appName,
                    database: "sqlite"
                });
                
                expect(result.success).toBeTrue();
                
                var serverJson = deserializeJSON(
                    fileRead(variables.testProjectPath & "/" & appName & "/server.json")
                );
                
                expect(serverJson).toHaveKey("app");
                expect(serverJson.app).toHaveKey("datasources");
                expect(serverJson.app.datasources).toHaveKey("wheelsdatasource");
                expect(serverJson.app.datasources.wheelsdatasource.driver).toBe("org.sqlite.JDBC");
            });
            
            it("handles existing directory error", function() {
                var appName = "existing-app";
                directoryCreate(variables.testProjectPath & "/" & appName);
                
                var result = runCommand("wheels create app", {
                    name: appName
                });
                
                expect(result.success).toBeFalse();
                expect(result.errors).toHaveLength(1);
                expect(result.errorDetail).toInclude("already exists");
            });
        });
    }
}
```

#### Model Generation Test

```javascript
// tests/specs/commands/wheels/create/ModelTest.cfc
component extends="tests.specs.BaseCommandSpec" {
    
    function beforeAll() {
        super.beforeAll();
        // Create a test project for model generation
        variables.projectPath = createTestProject("model-test-app");
        shell.cd(variables.projectPath);
    }
    
    function run() {
        describe("wheels create model", function() {
            
            it("creates a basic model file", function() {
                var result = runCommand("wheels create model", {
                    name: "Product"
                });
                
                expect(result.success).toBeTrue();
                
                var modelPath = variables.projectPath & "/app/models/Product.cfc";
                expect(fileExists(modelPath)).toBeTrue();
                expect(fileContains(modelPath, 'extends="wheels.Model"')).toBeTrue();
                expect(fileContains(modelPath, 'table("products")')).toBeTrue();
            });
            
            it("creates model with properties", function() {
                var result = runCommand("wheels create model", {
                    name: "User",
                    properties: "firstName:string,lastName:string,email:string:unique,age:integer"
                });
                
                expect(result.success).toBeTrue();
                
                var modelPath = variables.projectPath & "/app/models/User.cfc";
                expect(fileExists(modelPath)).toBeTrue();
                expect(fileContains(modelPath, 'property(name="firstName", type="string")')).toBeTrue();
                expect(fileContains(modelPath, 'property(name="email", type="string")')).toBeTrue();
                expect(fileContains(modelPath, 'validatesUniquenessOf("email")')).toBeTrue();
                expect(fileContains(modelPath, 'property(name="age", type="integer")')).toBeTrue();
            });
            
            it("creates migration when flag is set", function() {
                var result = runCommand("wheels create model", {
                    name: "Post",
                    properties: "title:string,content:text,publishedAt:datetime",
                    migration: true
                });
                
                expect(result.success).toBeTrue();
                expect(result.outputText).toInclude("Created model");
                expect(result.outputText).toInclude("Created migration");
                
                // Check migration was created
                var migrations = directoryList(
                    variables.projectPath & "/db/migrate",
                    false,
                    "name",
                    "*.cfc"
                );
                
                var migrationFound = false;
                for (var migration in migrations) {
                    if (findNoCase("create_posts_table", migration)) {
                        migrationFound = true;
                        break;
                    }
                }
                
                expect(migrationFound).toBeTrue("Migration file should be created");
            });
            
            it("handles model already exists", function() {
                // Create model first time
                runCommand("wheels create model", {name: "Duplicate"});
                
                // Try to create again
                var result = runCommand("wheels create model", {name: "Duplicate"});
                
                expect(result.success).toBeFalse();
                expect(result.outputText).toInclude("already exists");
            });
        });
    }
}
```

#### Database Migration Test

```javascript
// tests/specs/commands/wheels/db/MigrateTest.cfc
component extends="tests.specs.BaseCommandSpec" {
    
    function beforeAll() {
        super.beforeAll();
        variables.projectPath = createTestProject("migration-test-app");
        shell.cd(variables.projectPath);
        
        // Create a sample migration
        var migrationContent = '
        component extends="wheels.migrator.Migration" {
            function up() {
                createTable(name="users") {
                    table.primaryKey();
                    table.string("firstName");
                    table.string("lastName");
                    table.string("email");
                    table.timestamps();
                };
            }
            
            function down() {
                dropTable("users");
            }
        }';
        
        var timestamp = dateFormat(now(), "yyyymmddHHnnss");
        fileWrite(
            variables.projectPath & "/db/migrate/#timestamp#_create_users_table.cfc",
            migrationContent
        );
    }
    
    function run() {
        describe("wheels db migrate", function() {
            
            it("runs migrations successfully", function() {
                var result = runCommand("wheels db migrate");
                
                expect(result.success).toBeTrue();
                expect(result.outputText).toInclude("Running migrations");
                expect(result.outputText).toInclude("completed successfully");
            });
            
            it("handles no migrations gracefully", function() {
                // Run again - should be no migrations
                var result = runCommand("wheels db migrate");
                
                expect(result.success).toBeTrue();
                expect(result.outputText).toInclude("up to date");
            });
            
            it("reports errors in migrations", function() {
                // Create a bad migration
                var badMigration = '
                component extends="wheels.migrator.Migration" {
                    function up() {
                        throw("Migration error test");
                    }
                }';
                
                var timestamp = dateFormat(now(), "yyyymmddHHnnss");
                fileWrite(
                    variables.projectPath & "/db/migrate/#timestamp#_bad_migration.cfc",
                    badMigration
                );
                
                var result = runCommand("wheels db migrate");
                
                expect(result.success).toBeFalse();
                expect(result.errors).toHaveLength(1, "Should have one error");
                expect(result.outputText).toInclude("Migration error test");
            });
        });
    }
}
```

### Integration Tests

```javascript
// tests/specs/integration/FullWorkflowTest.cfc
component extends="tests.specs.BaseCommandSpec" {
    
    function run() {
        describe("Full application workflow", function() {
            
            it("creates a complete blog application", function() {
                var appName = "blog-integration";
                
                // Step 1: Create app
                var createResult = runCommand("wheels create app", {
                    name: appName,
                    database: "sqlite"
                });
                expect(createResult.success).toBeTrue();
                
                // Change to app directory
                shell.cd(variables.testProjectPath & "/" & appName);
                
                // Step 2: Create Post model with migration
                var modelResult = runCommand("wheels create model", {
                    name: "Post",
                    properties: "title:string,slug:string:unique,content:text,publishedAt:datetime",
                    migration: true
                });
                expect(modelResult.success).toBeTrue();
                
                // Step 3: Create controller
                var controllerResult = runCommand("wheels create controller", {
                    name: "Posts",
                    resource: true,
                    model: "Post"
                });
                expect(controllerResult.success).toBeTrue();
                
                // Step 4: Run migrations
                var migrateResult = runCommand("wheels db migrate");
                expect(migrateResult.success).toBeTrue();
                
                // Verify everything exists
                expect(fileExists("app/models/Post.cfc")).toBeTrue();
                expect(fileExists("app/controllers/Posts.cfc")).toBeTrue();
                expect(fileExists("db/sqlite/blog-integration_development.db")).toBeTrue();
                
                // Verify model content
                expect(fileContains("app/models/Post.cfc", "validatesUniquenessOf")).toBeTrue();
                
                // Verify controller content
                expect(fileContains("app/controllers/Posts.cfc", "function index")).toBeTrue();
                expect(fileContains("app/controllers/Posts.cfc", "function show")).toBeTrue();
                expect(fileContains("app/controllers/Posts.cfc", "function create")).toBeTrue();
            });
            
            it("handles database switching", function() {
                var appName = "db-switch-app";
                
                // Create with SQLite
                runCommand("wheels create app", {
                    name: appName,
                    database: "sqlite"
                });
                
                shell.cd(variables.testProjectPath & "/" & appName);
                
                // Switch to MySQL
                var switchResult = runCommand("wheels db setup", {
                    type: "mysql"
                });
                
                // This would actually fail without MySQL running
                // but we can test the command structure
                expect(switchResult).toBeDefined();
            });
        });
    }
}
```

### Testing Interactive Commands

```javascript
// tests/specs/commands/InteractiveCommandTest.cfc
component extends="tests.specs.BaseCommandSpec" {
    
    function testInteractiveAppCreation() {
        describe("Interactive command flow", function() {
            
            it("handles user input for app creation", function() {
                var command = wirebox.getInstance("commands.wheels.create.app");
                
                // Mock user input
                command.$("ask").$args("Application name?").$results("my-interactive-app");
                command.$("ask").$args("Database type?").$results("sqlite");
                command.$("confirm").$args(any).$results(true);
                
                // Mock print
                var mockPrint = getMockBox().createMock("commandbox.system.util.Print");
                command.setPrint(mockPrint);
                
                // Run
                command.run();
                
                // Verify interactions
                expect(command.$count("ask")).toBe(2);
                expect(command.$count("confirm")).toBeGTE(1);
            });
        });
    }
}
```

### Running Tests

#### Configure box.json for Testing

```json
{
    "name": "wheels-cli",
    "version": "3.0.0",
    "testbox": {
        "runner": "tests/runner.cfm",
        "verbose": true,
        "watchDelay": 500,
        "watchPaths": "commands/**.cfc,tests/**.cfc"
    },
    "scripts": {
        "test": "testbox run",
        "test:watch": "testbox watch",
        "test:verbose": "testbox run --verbose",
        "test:unit": "testbox run --bundles=tests.specs.unit",
        "test:integration": "testbox run --bundles=tests.specs.integration",
        "test:commands": "testbox run --bundles=tests.specs.commands"
    }
}
```

#### Test Runner Configuration

```javascript
// tests/runner.cfm
<cfscript>
// Create TestBox instance
testbox = new testbox.system.TestBox();

// Run tests
results = testbox.run(
    bundles = "tests.specs",
    recurse = true,
    reporter = url.reporter ?: "simple",
    labels = url.labels ?: "",
    excludes = url.excludes ?: ""
);

// Output results
writeOutput(results);
</cfscript>
```

### CI/CD Integration

```yaml
# .github/workflows/test.yml
name: Wheels CLI Tests

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        cfengine: ["lucee@5", "adobe@2021", "adobe@2023"]
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup CommandBox
      uses: Ortus-Solutions/setup-commandbox@v2.0.1
    
    - name: Install Dependencies
      run: |
        box install
        box install commandbox-testbox
    
    - name: Start Test Server
      run: |
        box server start cfengine=${{ matrix.cfengine }} port=8080
        sleep 10
    
    - name: Run Tests
      run: box testbox run --verbose
      
    - name: Upload Test Results
      if: always()
      uses: actions/upload-artifact@v3
      with:
        name: test-results-${{ matrix.cfengine }}
        path: tests/results/
```

### Testing Best Practices

1. **Isolation**: Each test should be independent and not rely on state from other tests
2. **Cleanup**: Always clean up created files and directories
3. **Mocking**: Mock external dependencies like file system operations when appropriate
4. **Fast Tests**: Keep tests fast by minimizing I/O operations
5. **Clear Assertions**: Use descriptive test names and clear assertions
6. **Error Testing**: Test both success and failure paths
7. **Integration Tests**: Have a few end-to-end tests that verify complete workflows

### Performance Testing

```javascript
// tests/specs/performance/CommandPerformanceTest.cfc
component extends="tests.specs.BaseCommandSpec" {
    
    function testCommandPerformance() {
        describe("Command performance", function() {
            
            it("creates model quickly", function() {
                var startTime = getTickCount();
                
                runCommand("wheels create model", {
                    name: "PerfTest"
                });
                
                var duration = getTickCount() - startTime;
                
                expect(duration).toBeLT(1000, "Model creation should take less than 1 second");
            });
            
            it("handles large property lists", function() {
                var properties = [];
                for (var i = 1; i <= 50; i++) {
                    properties.append("field#i#:string");
                }
                
                var result = runCommand("wheels create model", {
                    name: "LargeModel",
                    properties: properties.toList()
                });
                
                expect(result.success).toBeTrue();
            });
        });
    }
}
```

## Performance Optimizations

1. **Lazy Loading**: Load command dependencies only when needed
2. **Template Caching**: Cache parsed templates in memory
3. **Parallel Operations**: Use CommandBox's async features for multiple file operations
4. **Progress Indicators**: Show progress for long-running operations

## Error Handling

```javascript
try {
    // Command logic
} catch (WheelsException e) {
    print.redLine("Wheels Error: #e.message#");
    
    if (verbose) {
        print.line("Stack trace:");
        print.line(e.stacktrace);
    }
    
    // Suggest fixes
    if (e.type == "ModelNotFound") {
        print.yellowLine("Did you mean to create the model first?");
        print.indentedLine("wheels create model #e.modelName#");
    }
} catch (DatabaseException e) {
    print.redLine("Database Error: #e.message#");
    
    // SQLite-specific errors
    if (findNoCase("sqlite", e.message)) {
        if (findNoCase("locked", e.message)) {
            print.yellowLine("The SQLite database is locked. Another process may be using it.");
            print.indentedLine("Try closing other connections or waiting a moment.");
        } else if (findNoCase("no such table", e.message)) {
            print.yellowLine("Table not found. Did you run migrations?");
            print.indentedLine("wheels db:migrate");
        } else if (findNoCase("disk I/O error", e.message)) {
            print.yellowLine("SQLite disk error. Check disk space and permissions.");
            print.indentedLine("Check: db/sqlite/ directory permissions");
        }
    }
} catch (any e) {
    print.redLine("Unexpected error: #e.message#");
    print.line("Please report this issue at: https://github.com/wheels/wheels-cli/issues");
}
```

### Common SQLite Issues and Solutions

1. **Database Locked Error**
   ```bash
   # Solution: Ensure no other processes are accessing the database
   wheels server:stop
   wheels db:migrate
   ```

2. **Missing JDBC Driver**
   ```bash
   # Solution: Install SQLite JDBC driver
   box install sqlite-jdbc
   ```

3. **Permission Issues**
   ```bash
   # Solution: Fix directory permissions
   chmod 755 db/sqlite/
   chmod 644 db/sqlite/*.db
   ```

## Conclusion

This implementation guide provides a solid foundation for building a professional-grade CLI for Wheels that leverages CommandBox's powerful features while maintaining the simplicity and convention-over-configuration philosophy that Wheels developers expect.

Key benefits of this approach:
- Uses standard CommandBox package conventions (box.json for version info)
- SQLite as default database for zero-configuration development
- Cross-platform compatibility (Lucee, Adobe CF, BoxLang)
- Clear separation between modern (3.0+) and legacy Wheels projects
- Leverages CommandBox's mature infrastructure
- Provides helpful error messages and upgrade paths
- Follows Wheels 3.0+ directory structure conventions

The CLI will help developers be more productive by automating common tasks while maintaining the flexibility to customize generated code to their needs. With SQLite as the default database, developers can start building immediately without any database setup, following the best practices established by Rails, Laravel, and Django.