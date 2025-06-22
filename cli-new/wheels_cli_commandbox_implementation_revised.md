# Wheels CLI CommandBox Implementation Guide (Revised)

## Overview

This guide provides detailed implementation strategies for building the Wheels CLI as a CommandBox module, leveraging CommandBox's existing infrastructure while adding Wheels-specific functionality.

**Implementation Context:** This CLI is being developed within the existing Wheels monorepo structure, which currently contains:
- Base template package (project scaffolding)
- Core framework package (in `vendor/wheels/`)  
- Existing CLI package (in `cli/`)

The new CLI will be developed in parallel, tested locally, and then integrated into the existing build/publish workflow.

**Target Project Structure:** This CLI is designed for Wheels 3.0+ projects where:
- The framework is located in the `vendor/wheels/` directory
- The framework version is determined from `vendor/wheels/box.json` (following CommandBox package standards)
- The project follows the modern Wheels directory structure

For legacy Wheels projects, users will need to upgrade to the modern structure.

## Development Approach & Monorepo Integration

### Current Wheels Monorepo Structure
```
wheels-monorepo/
├── .github/
│   └── workflows/
├── app/                    # Base template structure
├── config/
├── db/
├── public/
├── tests/
├── vendor/
│   └── wheels/             # Core framework package source
├── cli/                    # Current CLI package source
├── build/                  # Build scripts and configuration
├── docs/
├── box.json               # Root package descriptor
└── server.json
```

### Implementation Strategy

#### Phase 1: Parallel Development
1. **Create New CLI Directory**: `cli-next/` alongside existing `cli/`
2. **Develop New CLI**: Build CommandBox module in isolation
3. **Local Testing**: Link CommandBox installation to development directory
4. **Integration Testing**: Test with actual Wheels projects

#### Phase 2: Build Process Integration  
1. **Update Build Scripts**: Modify to handle new CLI structure
2. **Template Updates**: Ensure base template works with new CLI
3. **Package Dependencies**: Update version constraints between packages
4. **Documentation**: Update guides and examples

#### Phase 3: Migration & Release
1. **Beta Testing**: Community testing with new CLI
2. **Migration Guide**: Help existing users transition
3. **Package Publishing**: Release all three packages coordinately
4. **Deprecation Plan**: Phase out old CLI gradually

### Proposed Directory Structure
```
wheels-monorepo/
├── cli-next/                      # New CLI implementation
│   ├── ModuleConfig.cfc
│   ├── box.json                   # CLI package descriptor
│   ├── commands/
│   │   └── wheels/
│   │       ├── create/
│   │       ├── db/
│   │       ├── server/
│   │       ├── templates/
│   │       └── ...
│   ├── templates/                 # Built-in CLI templates
│   │   ├── app/
│   │   ├── model/
│   │   ├── controller/
│   │   ├── view/
│   │   └── migration/
│   ├── lib/                       # Supporting services
│   │   ├── WheelsService.cfc
│   │   ├── DatabaseService.cfc
│   │   └── ...
│   └── tests/                     # CLI-specific tests
├── vendor/wheels/                 # Core framework (unchanged)
├── cli/                          # Legacy CLI (maintained during transition)
└── [base template files]         # Updated to work with new CLI
```

### Development Workflow

#### Local Development Setup
```bash
# 1. Clone the monorepo
git clone https://github.com/wheels-dev/wheels.git
cd wheels

# 2. Link local CLI for development
box package link cli-next/

# 3. Verify CLI is available
wheels help

# 4. Test CLI with sample project
mkdir test-project
cd test-project
wheels create app sample-app
```

#### Testing Strategy
```bash
# Test in development
cd cli-next/
box testbox run

# Integration testing with real projects
cd ../test-projects/
wheels create app blog-test
cd blog-test
wheels create model Post title:string content:text --migration
wheels db:migrate
wheels server start
```

### Package Dependencies & Versioning

#### CLI Package (`cli-next/box.json`)
```json
{
    "name": "wheels-cli-next",
    "version": "3.0.0-beta.1",
    "type": "commandbox-modules",
    "dependencies": {
        "commandbox-migrations": "^3.0.0",
        "commandbox-cfformat": "^2.0.0", 
        "sqlite-jdbc": "^3.40.0"
    },
    "suggests": {
        "wheels": "^3.0.0"
    }
}
```

#### Base Template Package Updates
```json
{
    "name": "wheels-template-base",
    "version": "3.0.0",
    "dependencies": {
        "wheels": "^3.0.0"
    },
    "devDependencies": {
        "wheels-cli-next": "^3.0.0"
    }
}
```

#### Core Framework Package (minimal changes)
```json
{
    "name": "wheels",
    "version": "3.0.0",
    "suggests": {
        "wheels-cli-next": "^3.0.0"
    }
}
```

### Build Process Modifications

#### Updated Build Script (`build/release.boxr`)
```javascript
// Build CLI package
command("package")
    .inWorkingDirectory("cli-next")
    .params(
        destination="../artifacts/wheels-cli-next-@version@.zip",
        verbose=true
    )
    .run();

// Build template package (exclude cli-next during packaging)
command("package")
    .params(
        destination="artifacts/wheels-template-base-@version@.zip",
        ignoreList="cli-next/,cli/,vendor/wheels/,build/,docs/",
        verbose=true
    )
    .run();

// Build core framework package  
command("package")
    .inWorkingDirectory("vendor/wheels")
    .params(
        destination="../../artifacts/wheels-@version@.zip",
        verbose=true
    )
    .run();
```

#### CI/CD Pipeline Updates
```yaml
# .github/workflows/release.yml
jobs:
  build:
    steps:
      - name: Build New CLI
        run: |
          cd cli-next
          box package --destination=../artifacts/
          
      - name: Test CLI Integration
        run: |
          # Test CLI with template
          box package link cli-next/
          mkdir test-integration
          cd test-integration
          wheels create app test-app
          cd test-app
          wheels create model User name:string email:string:unique --migration
          wheels db:migrate
          
      - name: Publish to ForgeBox
        if: github.ref == 'refs/heads/main'
        run: |
          cd cli-next && box publish
          cd ../vendor/wheels && box publish  
          box publish # template from root
```

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

### New CLI Module Structure (`cli-next/`)
```
cli-next/
├── ModuleConfig.cfc               # CommandBox module configuration
├── box.json                       # Package descriptor for CLI
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
│       │   ├── start.cfc
│       │   ├── stop.cfc
│       │   └── restart.cfc
│       ├── test/
│       │   ├── all.cfc
│       │   ├── unit.cfc
│       │   └── integration.cfc
│       ├── templates/
│       │   ├── copy.cfc
│       │   ├── list.cfc
│       │   └── variables.cfc
│       ├── console.cfc
│       ├── routes.cfc
│       ├── version.cfc          # Shows Wheels version info
│       └── help.cfc
├── templates/                     # Built-in templates for CLI
│   ├── app/
│   │   ├── box.json.template
│   │   ├── server.json.template
│   │   └── config/
│   ├── model/
│   │   ├── Model.cfc
│   │   ├── ModelWithValidation.cfc
│   │   ├── ModelWithAudit.cfc
│   │   └── ModelComplete.cfc
│   ├── controller/
│   │   ├── Controller.cfc
│   │   ├── ResourceController.cfc
│   │   └── ApiController.cfc
│   ├── view/
│   │   ├── index.cfm
│   │   ├── show.cfm
│   │   ├── new.cfm
│   │   └── edit.cfm
│   ├── migration/
│   │   └── Migration.cfc
│   └── templates.json             # Default template configuration
├── lib/                           # Supporting services
│   ├── WheelsService.cfc
│   ├── MigrationService.cfc
│   ├── DatabaseService.cfc      # Database setup & driver management
│   ├── TestRunner.cfc
│   └── TemplateService.cfc      # Template management
└── tests/                         # CLI-specific tests
    ├── specs/
    │   ├── commands/
    │   ├── integration/
    │   └── unit/
    ├── Application.cfc
    └── runner.cfm
```

### CLI Package Configuration (`cli-next/box.json`)
```json
{
    "name": "wheels-cli-next",
    "version": "3.0.0-beta.1",
    "author": "CFWheels Team",
    "homepage": "https://cfwheels.org",
    "documentation": "https://guides.cfwheels.org/cli",
    "repository": {
        "type": "git",
        "url": "https://github.com/wheels-dev/wheels"
    },
    "bugs": "https://github.com/wheels-dev/wheels/issues",
    "slug": "wheels-cli-next",
    "shortDescription": "Next-generation CLI for CFWheels Framework",
    "type": "commandbox-modules",
    "keywords": [
        "cfwheels",
        "mvc",
        "cli",
        "scaffolding",
        "commandbox"
    ],
    "private": false,
    "dependencies": {
        "commandbox-migrations": "^3.0.0",
        "commandbox-cfformat": "^2.0.0",
        "sqlite-jdbc": "^3.40.0"
    },
    "suggests": {
        "wheels": "^3.0.0"
    },
    "devDependencies": {
        "testbox": "^4.0.0"
    },
    "installPaths": {
        "commandbox-migrations": "modules/commandbox-migrations/",
        "commandbox-cfformat": "modules/commandbox-cfformat/",
        "sqlite-jdbc": "lib/"
    },
    "scripts": {
        "test": "testbox run",
        "test:watch": "testbox watch",
        "format": "cfformat run commands/",
        "package": "package destination=../artifacts/ --force"
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
     * Template rendering helper using CommandBox's @VARIABLE@ system
     */
    function renderTemplate(required string template, required struct data) {
        var content = arguments.template;
        
        // Phase 1: Replace simple variables using CommandBox's proven @VARIABLE@ syntax
        for (var key in arguments.data) {
            if (isSimpleValue(arguments.data[key])) {
                content = replaceNoCase(
                    content, 
                    "@#uCase(key)#@", 
                    arguments.data[key], 
                    "all"
                );
            }
        }
        
        // Phase 2: Handle complex content blocks
        content = renderContentBlocks(content, arguments.data);
        
        return content;
    }
    
    /**
     * Render complex content blocks (properties, validations, etc.)
     */
    private function renderContentBlocks(required string content, required struct data) {
        var result = arguments.content;
        
        // Handle property definitions
        if (findNoCase("@PROPERTY_DEFINITIONS@", result)) {
            var propertyContent = renderPropertyDefinitions(arguments.data.properties ?: []);
            result = replaceNoCase(result, "@PROPERTY_DEFINITIONS@", propertyContent, "all");
        }
        
        // Handle validations
        if (findNoCase("@VALIDATIONS@", result)) {
            var validationContent = renderValidations(arguments.data.properties ?: []);
            result = replaceNoCase(result, "@VALIDATIONS@", validationContent, "all");
        }
        
        // Handle associations
        if (findNoCase("@ASSOCIATIONS@", result)) {
            var associationContent = renderAssociations(arguments.data.associations ?: []);
            result = replaceNoCase(result, "@ASSOCIATIONS@", associationContent, "all");
        }
        
        // Handle controller actions
        if (findNoCase("@CONTROLLER_ACTIONS@", result)) {
            var actionContent = renderControllerActions(arguments.data);
            result = replaceNoCase(result, "@CONTROLLER_ACTIONS@", actionContent, "all");
        }
        
        return result;
    }
    
    /**
     * Render property definitions
     */
    private function renderPropertyDefinitions(required array properties) {
        var lines = [];
        
        for (var prop in arguments.properties) {
            var line = 'property(name="@PROPERTY_NAME@", type="@PROPERTY_TYPE@");';
            line = replaceNoCase(line, "@PROPERTY_NAME@", prop.name, "all");
            line = replaceNoCase(line, "@PROPERTY_TYPE@", prop.type, "all");
            
            arrayAppend(lines, "        " & line);  // Proper indentation
        }
        
        return arrayToList(lines, chr(10));
    }
    
    /**
     * Render validation definitions
     */
    private function renderValidations(required array properties) {
        var lines = [];
        
        for (var prop in arguments.properties) {
            // Required validation
            if (structKeyExists(prop.options, "required")) {
                var line = 'validatesPresenceOf("@PROPERTY_NAME@");';
                line = replaceNoCase(line, "@PROPERTY_NAME@", prop.name, "all");
                arrayAppend(lines, "        " & line);
            }
            
            // Unique validation
            if (structKeyExists(prop.options, "unique")) {
                var line = 'validatesUniquenessOf("@PROPERTY_NAME@");';
                line = replaceNoCase(line, "@PROPERTY_NAME@", prop.name, "all");
                arrayAppend(lines, "        " & line);
            }
            
            // Email validation
            if (structKeyExists(prop.options, "email")) {
                var line = 'validatesFormatOf(property="@PROPERTY_NAME@", regex="^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}$", message="must be a valid email address");';
                line = replaceNoCase(line, "@PROPERTY_NAME@", prop.name, "all");
                arrayAppend(lines, "        " & line);
            }
        }
        
        return arrayToList(lines, chr(10));
    }
    
    /**
     * Render association definitions
     */
    private function renderAssociations(required array associations) {
        var lines = [];
        
        for (var assoc in arguments.associations) {
            var line = '@ASSOCIATION_TYPE@("@ASSOCIATION_TARGET@");';
            line = replaceNoCase(line, "@ASSOCIATION_TYPE@", assoc.type, "all");
            line = replaceNoCase(line, "@ASSOCIATION_TARGET@", assoc.target, "all");
            
            arrayAppend(lines, "        // " & line);
        }
        
        return arrayToList(lines, chr(10));
    }
    
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
        
        // Select appropriate template
        var templateName = selectModelTemplate(props);
        var template = getTemplate("model", templateName);
        
        // Check if using custom template
        if (isUsingCustomTemplate("model/#templateName#")) {
            print.yellowLine("Using custom model template: #templateName#");
        }
        
        // Generate model file
        var modelContent = renderModelContent(arguments.name, props, template);
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
     * Select appropriate model template based on properties and configuration
     */
    private string function selectModelTemplate(required array properties) {
        var templateConfig = loadTemplateConfig();
        
        var hasValidations = arguments.properties.some(function(prop) {
            return structKeyExists(prop.options, "required") || 
                   structKeyExists(prop.options, "unique") ||
                   structKeyExists(prop.options, "email");
        });
        
        var includeAuditFields = templateConfig.model.includeAuditFields ?: false;
        var includeSoftDeletes = templateConfig.model.includeSoftDeletes ?: false;
        
        // Select template based on features needed
        if (includeAuditFields && includeSoftDeletes && hasValidations) {
            return "ModelComplete.cfc";
        } else if (hasValidations) {
            return "ModelWithValidation.cfc";
        } else if (includeAuditFields) {
            return "ModelWithAudit.cfc";
        } else {
            return "Model.cfc";
        }
    }
    
    /**
     * Generate model content using template
     */
    private string function renderModelContent(
        required string name,
        required array properties,
        required string template
    ) {
        var data = {
            modelName = arguments.name,
            tableName = pluralize(lCase(arguments.name)),
            properties = arguments.properties,
            timestamp = dateTimeFormat(now(), "yyyy-mm-dd HH:nn:ss"),
            generatedBy = "Wheels CLI v#getWheelsVersion()#"
        };
        
        return renderTemplate(arguments.template, data);
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
                consoleLogger.warn("Invalid template configuration JSON: #e.message#");
            }
        }
        
        // Return default configuration
        return {
            model = {
                includeAuditFields = false,
                includeSoftDeletes = false,
                baseClass = "wheels.Model"
            },
            controller = {
                baseClass = "wheels.Controller",
                requireAuthentication = false
            },
            view = {
                uiFramework = "bootstrap5",
                includeIcons = true
            }
        };
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

## Template Override System

### Overview

The Wheels CLI supports a powerful template override system using CommandBox's proven `@VARIABLE@` placeholder replacement. This approach ensures CFML compatibility while providing maximum customization flexibility.

### Key Features

1. **CommandBox-Native**: Uses the battle-tested `@VARIABLE@` placeholder system
2. **CFML-Safe**: No hash character conflicts with CSS colors, HTML fragments, or CFML parsing
3. **Project-Specific**: Templates stored in `config/templates/` directory
4. **Fallback System**: Graceful fallback to built-in templates
5. **Template Variants**: Multiple template types based on project needs

### Template Directory Structure

```
my-wheels-app/
├── config/
│   └── templates/           # User's custom templates
│       ├── model/
│       │   ├── Model.cfc              # Basic model
│       │   ├── ModelWithValidation.cfc # Model with validations
│       │   ├── ModelWithAudit.cfc     # Model with audit trail
│       │   └── ModelComplete.cfc      # Full-featured model
│       ├── controller/
│       │   ├── Controller.cfc         # Basic controller
│       │   ├── ResourceController.cfc # RESTful controller
│       │   └── ApiController.cfc      # API controller
│       ├── migration/
│       │   └── Migration.cfc
│       ├── view/
│       │   ├── index.cfm
│       │   ├── show.cfm
│       │   ├── new.cfm
│       │   └── edit.cfm
│       └── templates.json  # Template configuration
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
        
        print.boldLine("Copying templates using CommandBox @VARIABLE@ conventions...");
        
        if (arguments.type == "all") {
            copyAllTemplates(templateSource, templateDest, arguments.force);
        } else {
            copyTemplateType(arguments.type, templateSource, templateDest, arguments.force);
        }
        
        print.line();
        print.greenLine("Templates copied successfully!");
        print.line();
        print.yellowLine("Templates use CommandBox's proven @VARIABLE@ placeholder system:");
        print.indentedLine("- Variables use @VARIABLE_NAME@ syntax");
        print.indentedLine("- CFML-safe (no hash mark conflicts)");
        print.indentedLine("- Compatible with CSS colors and HTML fragments");
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
        
        print.boldLine("Wheels CLI Templates (CommandBox @VARIABLE@ System)");
        print.line("=" repeatString 60);
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
            print.line("Placeholder syntax: @VARIABLE_NAME@ (CommandBox standard)");
        } else {
            print.line("Run 'wheels templates:copy' to customize templates");
        }
    }
}
```

### Built-in Template Examples

#### Basic Model Template
```javascript
// templates/model/Model.cfc
/**
 * @MODEL_NAME@ Model
 * Generated: @TIMESTAMP@
 * Generator: @GENERATED_BY@
 */
component extends="wheels.Model" {
    
    function config() {
        // Table configuration
        table("@TABLE_NAME@");
        
        // Property definitions
@PROPERTY_DEFINITIONS@
        
        // Timestamps
        timeStamps();
        
        // Validations
@VALIDATIONS@
        
        // Associations
@ASSOCIATIONS@
    }
}
```

#### Complete Model Template with Audit Trail
```javascript
// templates/model/ModelComplete.cfc
/**
 * @MODEL_NAME@ Model
 * Generated: @TIMESTAMP@
 * Generator: @GENERATED_BY@
 */
component extends="models.base.BaseModel" {
    
    function config() {
        // Table
        table("@TABLE_NAME@");
        
        // Property definitions
@PROPERTY_DEFINITIONS@
        
        // Timestamps
        timeStamps();
        
        // Audit fields
        property(name="createdBy", type="string");
        property(name="updatedBy", type="string");
        property(name="deletedAt", type="datetime");
        property(name="deletedBy", type="string");
        
        // Soft deletes
        softDeletes();
        
        // Validations
@VALIDATIONS@
        
        // Callbacks
        beforeCreate("setAuditFields");
        beforeUpdate("updateAuditFields");
        beforeDelete("softDelete");
        
        // Associations
@ASSOCIATIONS@
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

#### Resource Controller Template
```javascript
// templates/controller/ResourceController.cfc
/**
 * @CONTROLLER_NAME@ Controller
 * Generated: @TIMESTAMP@
 */
component extends="controllers.base.SecureController" {
    
    function config() {
        // Authentication required for all actions
        verifies(except="", params="isAuthenticated", handler="requireLogin");
        
        // Authorization for resource actions
        verifies(only="edit,update,delete", params="canModify@MODEL_NAME@", handler="unauthorized");
        
        // API configuration
        provides("json,xml");
    }
    
    /**
     * Display a list of @PLURAL_LOWER_NAME@
     */
    function index() {
        @PLURAL_LOWER_NAME@ = model("@MODEL_NAME@").findAll(
            order="createdAt DESC",
            where="deletedAt IS NULL"
        );
        
        renderWith(@PLURAL_LOWER_NAME@);
    }
    
    /**
     * Display a single @SINGULAR_LOWER_NAME@
     */
    function show() {
        @SINGULAR_LOWER_NAME@ = model("@MODEL_NAME@").findByKey(params.key);
        
        if (!isObject(@SINGULAR_LOWER_NAME@)) {
            return renderNotFound();
        }
        
        renderWith(@SINGULAR_LOWER_NAME@);
    }
    
    /**
     * Show form for new @SINGULAR_LOWER_NAME@
     */
    function new() {
        @SINGULAR_LOWER_NAME@ = model("@MODEL_NAME@").new();
    }
    
    /**
     * Create a new @SINGULAR_LOWER_NAME@
     */
    function create() {
        @SINGULAR_LOWER_NAME@ = model("@MODEL_NAME@").create(params.@SINGULAR_LOWER_NAME@);
        
        if (@SINGULAR_LOWER_NAME@.save()) {
            renderWith(@SINGULAR_LOWER_NAME@, status=201);
        } else {
            renderWith(@SINGULAR_LOWER_NAME@.allErrors(), status=422);
        }
    }
    
    /**
     * Show form to edit @SINGULAR_LOWER_NAME@
     */
    function edit() {
        @SINGULAR_LOWER_NAME@ = model("@MODEL_NAME@").findByKey(params.key);
        
        if (!isObject(@SINGULAR_LOWER_NAME@)) {
            return renderNotFound();
        }
    }
    
    /**
     * Update existing @SINGULAR_LOWER_NAME@
     */
    function update() {
        @SINGULAR_LOWER_NAME@ = model("@MODEL_NAME@").findByKey(params.key);
        
        if (!isObject(@SINGULAR_LOWER_NAME@)) {
            return renderNotFound();
        }
        
        if (@SINGULAR_LOWER_NAME@.update(params.@SINGULAR_LOWER_NAME@)) {
            renderWith(@SINGULAR_LOWER_NAME@);
        } else {
            renderWith(@SINGULAR_LOWER_NAME@.allErrors(), status=422);
        }
    }
    
    /**
     * Delete @SINGULAR_LOWER_NAME@
     */
    function delete() {
        @SINGULAR_LOWER_NAME@ = model("@MODEL_NAME@").findByKey(params.key);
        
        if (!isObject(@SINGULAR_LOWER_NAME@)) {
            return renderNotFound();
        }
        
        @SINGULAR_LOWER_NAME@.delete();
        
        renderWith({message="@MODEL_NAME@ deleted successfully"}, status=204);
    }
    
    // Private methods
    
    private function canModify@MODEL_NAME@() {
        var @SINGULAR_LOWER_NAME@ = model("@MODEL_NAME@").findByKey(params.key);
        return isObject(@SINGULAR_LOWER_NAME@) && @SINGULAR_LOWER_NAME@.canBeModifiedBy(getCurrentUser());
    }
    
    private function renderNotFound() {
        renderWith({error="@MODEL_NAME@ not found"}, status=404);
    }
}
```

#### Bootstrap View Template
```html
<!-- templates/view/index.cfm -->
<cfoutput>
<div class="container-fluid">
    <div class="row mb-4">
        <div class="col">
            <h1 class="h2 d-flex align-items-center justify-content-between">
                @PLURAL_NAME@
                <div class="btn-toolbar">
                    ##linkTo(route="new@SINGULAR_NAME@", text='<i class="fas fa-plus"></i> Add New', class="btn btn-primary", encode=false)##
                </div>
            </h1>
        </div>
    </div>
    
    <cfif @PLURAL_LOWER_NAME@.recordCount>
        <div class="card shadow-sm">
            <div class="card-body p-0">
                <div class="table-responsive">
                    <table class="table table-hover mb-0" data-toggle="datatable">
                        <thead>
                            <tr>
@TABLE_HEADERS@
                                <th class="text-right" style="width: 150px;">Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            <cfloop query="@PLURAL_LOWER_NAME@">
                                <tr>
@TABLE_CELLS@
                                    <td class="text-right">
                                        <div class="btn-group btn-group-sm">
                                            ##linkTo(route="@SINGULAR_LOWER_NAME@", key=@PLURAL_LOWER_NAME@.id, text='<i class="fas fa-eye"></i>', class="btn btn-outline-info", title="View", encode=false)##
                                            ##linkTo(route="edit@SINGULAR_NAME@", key=@PLURAL_LOWER_NAME@.id, text='<i class="fas fa-edit"></i>', class="btn btn-outline-primary", title="Edit", encode=false)##
                                            ##linkTo(route="@SINGULAR_LOWER_NAME@", key=@PLURAL_LOWER_NAME@.id, text='<i class="fas fa-trash"></i>', class="btn btn-outline-danger", method="delete", confirm="Are you sure?", title="Delete", encode=false)##
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
                <h3 class="text-muted">No @PLURAL_LOWER_NAME@ found</h3>
                <p class="text-muted mb-4">Get started by creating your first @SINGULAR_LOWER_NAME@.</p>
                ##linkTo(route="new@SINGULAR_NAME@", text='<i class="fas fa-plus"></i> Create First @SINGULAR_NAME@', class="btn btn-primary", encode=false)##
            </div>
        </div>
    </cfif>
</div>
</cfoutput>
```

### Template Configuration

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

### Benefits of This Approach

#### Technical Benefits
1. **CFML Compatible**: No hash mark conflicts with CSS, HTML, or CFML
2. **Proven System**: Uses CommandBox's battle-tested placeholder replacement
3. **Performance**: Simple string replacement, no complex parsing
4. **Maintainable**: Standard approach familiar to CommandBox users

#### Developer Benefits
1. **Safe Templates**: CSS colors `##00CCFF` work correctly without escaping
2. **No Special Syntax**: HTML fragments with anchors work naturally
3. **Predictable**: CommandBox users already know `@VARIABLE@` syntax
4. **Extensible**: Easy to add new placeholder types

#### Team Benefits
1. **Consistency**: All generated code follows project patterns
2. **Knowledge Sharing**: Templates encode team conventions
3. **Onboarding**: New developers instantly follow established patterns
4. **Maintenance**: Updates to templates propagate to all new code

## Testing the CLI

### Local Development Testing

#### Setting Up Development Environment
```bash
# 1. Clone the Wheels monorepo
git clone https://github.com/wheels-dev/wheels.git
cd wheels

# 2. Create and set up the new CLI directory
mkdir cli-next
cd cli-next

# 3. Initialize the CLI package
box init
# (Configure as shown in box.json above)

# 4. Link the local CLI for testing
box package link

# 5. Verify CLI is available globally
wheels help
# Should show the new CLI commands

# 6. Test CLI installation status
box list
# Should show wheels-cli-next as linked
```

#### Development Testing Workflow
```bash
# Test CLI commands in isolation
cd cli-next/
box testbox run

# Create test project for integration testing
cd ../
mkdir test-projects
cd test-projects

# Test app creation
wheels create app blog-test --database=sqlite
cd blog-test

# Verify project structure
ls -la
# Should show: app/, config/, db/, vendor/, box.json, server.json

# Test model generation
wheels create model Post title:string content:text published:boolean --migration

# Verify generated files
cat app/models/Post.cfc
cat db/migrate/*_create_posts_table.cfc

# Test database setup
wheels db:setup
wheels db:migrate

# Test server commands
wheels server:start
# Open http://localhost:8080 to verify

# Test template customization
wheels templates:copy model
# Verify files copied to config/templates/model/

# Test with custom templates
wheels create model Comment content:text --migration
# Should use custom template if available
```

### Monorepo Integration Testing

#### Testing with Development Framework
```bash
# Test CLI with local framework development
cd wheels/  # monorepo root

# Link local framework for testing
cd vendor/wheels
box package link
cd ../../

# Create test project using local packages
mkdir integration-test
cd integration-test

# Install local packages
box install wheels  # Uses linked local version
box install wheels-cli-next  # Uses linked local version

# Test full workflow
wheels create app integration-test
cd integration-test
wheels create model User firstName:string lastName:string email:string:unique --migration --controller --resource
wheels db:migrate
wheels server:start
```

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
        describe("Wheels CLI Template System", function() {
            
            describe("Template Rendering", function() {
                it("should replace @VARIABLE@ placeholders correctly", function() {
                    var template = "Model name: @MODEL_NAME@, Table: @TABLE_NAME@";
                    var data = {
                        modelName = "User",
                        tableName = "users"
                    };
                    
                    var command = new commands.wheels.BaseCommand();
                    var result = command.renderTemplate(template, data);
                    
                    expect(result).toBe("Model name: User, Table: users");
                });
                
                it("should handle CFML-safe content without conflicts", function() {
                    var template = "CSS color: ##00CCFF, Link: <a href='##top'>Top</a>, Model: @MODEL_NAME@";
                    var data = {
                        modelName = "Product"
                    };
                    
                    var command = new commands.wheels.BaseCommand();
                    var result = command.renderTemplate(template, data);
                    
                    expect(result).toBe("CSS color: ##00CCFF, Link: <a href='##top'>Top</a>, Model: Product");
                });
            });
            
            describe("Model Generation", function() {
                it("should create a basic model file", function() {
                    var command = application.wirebox.getInstance("command:wheels create model");
                    command.params(name="TestModel");
                    command.run();
                    
                    expect(fileExists(testProjectPath & "app/models/TestModel.cfc")).toBeTrue();
                });
                
                it("should create model with properties using @VARIABLE@ syntax", function() {
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
                    expect(content).toInclude("User Model"); // From @MODEL_NAME@ replacement
                });
            });
            
            describe("Template Override System", function() {
                it("should use custom templates when available", function() {
                    // Create custom template
                    var customTemplate = '/**
 * Custom @MODEL_NAME@ Model
 */
component extends="app.base.Model" {
    function config() {
        table("@TABLE_NAME@");
    }
}';
                    var templatePath = testProjectPath & "config/templates/model/Model.cfc";
                    directoryCreate(getDirectoryFromPath(templatePath), true);
                    fileWrite(templatePath, customTemplate);
                    
                    // Generate model
                    var command = application.wirebox.getInstance("command:wheels create model");
                    command.params(name="CustomModel");
                    command.run();
                    
                    var content = fileRead(testProjectPath & "app/models/CustomModel.cfc");
                    expect(content).toInclude("Custom CustomModel Model");
                    expect(content).toInclude('extends="app.base.Model"');
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

## Distribution & Installation

### Development Phase Installation
```bash
# For CLI development and testing
git clone https://github.com/wheels-dev/wheels.git
cd wheels/cli-next
box package link

# Verify installation
wheels version
```

### Beta Release Installation
```bash
# Install beta CLI from ForgeBox
box install wheels-cli-next@beta

# Or install specific beta version
box install wheels-cli-next@3.0.0-beta.1
```

### Production Release Installation
```bash
# Install from ForgeBox (when released)
box install wheels-cli-next

# Install from GitHub
box install wheels-dev/wheels

# Install specific version
box install wheels-cli-next@3.0.0
```

### Migration Strategy

#### Phase 1: Parallel Development (Current)
- **Old CLI**: `wheels-cli` package remains available and supported
- **New CLI**: `wheels-cli-next` package available for testing
- **Users**: Can test new CLI alongside existing projects
- **Documentation**: Both CLIs documented separately

#### Phase 2: Beta Testing (3-6 months)
- **Community Testing**: Beta testers use `wheels-cli-next` in real projects
- **Feedback Integration**: Issues and improvements incorporated
- **Template Updates**: Base template updated to work optimally with new CLI
- **Migration Tools**: Scripts to help convert custom templates

#### Phase 3: Release & Adoption (6-9 months)
- **Package Transition**: `wheels-cli-next` becomes `wheels-cli` 
- **Old CLI Deprecation**: `wheels-cli` (legacy) marked as deprecated
- **Default Installation**: New Wheels apps get new CLI by default
- **Migration Guide**: Comprehensive guide for existing users

#### Phase 4: Legacy Support (12+ months)
- **Legacy Maintenance**: Old CLI receives security updates only
- **End of Life**: Clear timeline for legacy CLI end-of-support
- **Migration Assistance**: Community support for stragglers

### Auto-Installation with Wheels
When creating a new Wheels app, the CLI should be included:
```bash
# Install Wheels 3.0+ template (updated for new CLI)
box install wheels-template-base

# This creates the proper structure with:
# - vendor/wheels/ for framework files
# - app/ directory for MVC components  
# - config/ for configuration
# - SQLite database in db/sqlite/
# - Automatically installs wheels-cli-next as a dependency

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

### Package Compatibility Matrix

| Package | Version | CLI Package | Framework Package | Template Package |
|---------|---------|-------------|-------------------|------------------|
| Legacy | 2.x | wheels-cli | wheels@2.x | wheels-template@2.x |
| Current | 3.0 (transition) | wheels-cli OR wheels-cli-next | wheels@3.0 | wheels-template-base@3.0 |
| Future | 3.1+ | wheels-cli (new) | wheels@3.1+ | wheels-template-base@3.1+ |

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
    print.line("Please report this issue at: https://github.com/wheels-dev/wheels/issues");
}
```

## Conclusion

This implementation guide provides a solid foundation for building a professional-grade CLI for Wheels that leverages CommandBox's powerful features while maintaining the simplicity and convention-over-configuration philosophy that Wheels developers expect.

Key benefits of this approach:
- **CommandBox Integration**: Uses proven `@VARIABLE@` placeholder system
- **CFML Compatibility**: No hash character conflicts with CSS, HTML, or CFML
- **SQLite Default**: Zero-configuration development experience
- **Template Flexibility**: Powerful override system that grows with projects
- **Cross-platform**: Works on Lucee, Adobe CF, and BoxLang
- **Modern Structure**: Follows Wheels 3.0+ directory conventions
- **Team-Friendly**: Templates encode and share team knowledge

The CLI will help developers be more productive by automating common tasks while providing the flexibility to customize generated code to their specific needs. The template override system ensures the CLI remains valuable throughout the entire project lifecycle, from initial prototyping to mature enterprise applications.
