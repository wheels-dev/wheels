# Wheels CLI Modernization: Detailed Implementation Plan

## Implementation Overview

This plan provides concrete, actionable steps to modernize the Wheels CLI by incrementally adding advanced capabilities while maintaining backward compatibility. Each phase includes specific code changes, new commands, and integration points with the existing ecosystem.

## Current State Analysis

### Existing Wheels CLI Structure
Based on research, the current Wheels CLI follows this structure:
```
wheels-cli/
├── box.json
├── ModuleConfig.cfc
├── commands/
│   ├── generate/
│   │   ├── app.cfc
│   │   ├── controller.cfc
│   │   ├── model.cfc
│   │   └── view.cfc
│   ├── dbmigrate/
│   │   ├── up.cfc
│   │   ├── down.cfc
│   │   └── create.cfc
│   └── new.cfc
└── templates/
    └── (various template files)
```

### Gap Analysis
- **Missing**: Advanced testing integration
- **Missing**: Resource-based scaffolding
- **Missing**: File watching capabilities
- **Missing**: Code quality tools
- **Missing**: Advanced migration features
- **Limited**: Basic scaffolding without relationships

## Phase 1: Foundation Enhancement (Month 1-2)

### 1.1 Project Setup & Dependencies

#### **Step 1.1.1: Update box.json Dependencies**
```json
{
    "name": "wheels-cli",
    "version": "2.0.0",
    "slug": "wheels-cli",
    "type": "commandbox-modules",
    "dependencies": {
        "testbox-cli": "^6.0.0",
        "commandbox-migrations": "^5.0.0",
        "commandbox-dotenv": "^3.0.0"
    },
    "devDependencies": {
        "testbox": "^6.0.0"
    },
    "installPaths": {
        "testbox": "testbox/",
        "testbox-cli": "modules/testbox-cli/",
        "commandbox-migrations": "modules/commandbox-migrations/"
    },
    "scripts": {
        "test": "testbox run",
        "test:watch": "testbox run --watch",
        "migrate": "migrate up"
    }
}
```

#### **Step 1.1.2: Update ModuleConfig.cfc**
```cfml
component {
    this.title = "Wheels CLI";
    this.author = "Wheels.dev Team";
    this.description = "Modern CLI for Wheels Framework";
    this.version = "2.0.0";
    this.autoMapModels = false;
    this.cfmapping = "wheels-cli";
    this.modelNamespace = "wheels-cli";
    
    // Dependencies
    this.dependencies = [
        "testbox-cli",
        "commandbox-migrations"
    ];
    
    function configure() {
        // Settings
        settings = {
            // Default template repository
            templateRepository = "https://github.com/wheels-dev/wheels-templates",
            // Testing configuration
            testbox = {
                runner = "/tests/runner.cfm",
                coverage = true,
                watchPaths = ["models/**", "handlers/**", "views/**"]
            },
            // Migration configuration
            migrations = {
                defaultDirectory = "db/migrations",
                seedDirectory = "db/seeds"
            }
        };
        
        // Interceptors
        interceptors = [
            { class = "#moduleMapping#.interceptors.WheelsCommandInterceptor" }
        ];
    }
    
    function onLoad() {
        // Register helper services
        binder.map("TemplateService@wheels-cli")
            .to("#moduleMapping#.models.TemplateService");
        binder.map("TestService@wheels-cli")
            .to("#moduleMapping#.models.TestService");
        binder.map("MigrationService@wheels-cli")
            .to("#moduleMapping#.models.MigrationService");
    }
}
```

### 1.2 Enhanced Test Integration

#### **Step 1.2.1: Create Test Generation Commands**
Create `/commands/generate/test.cfc`:
```cfml
/**
 * Generate test files for Wheels applications
 * Examples:
 * wheels generate test unit UserTest
 * wheels generate test integration UserControllerTest --open
 * wheels generate test model User --crud
 */
component extends="wheels-cli.models.BaseCommand" {
    
    property name="testService" inject="TestService@wheels-cli";
    property name="templateService" inject="TemplateService@wheels-cli";
    
    /**
     * @type.hint Type of test: unit, integration, model, controller
     * @type.options unit,integration,model,controller
     * @name.hint Name of the test (without Test suffix)
     * @open.hint Open the created file in editor
     * @crud.hint Generate CRUD test methods
     * @mock.hint Generate mock objects
     */
    function run(
        required string type,
        required string name,
        boolean open = false,
        boolean crud = false,
        boolean mock = false
    ) {
        // Validate we're in a Wheels project
        if (!isWheelsProject()) {
            error("This command must be run from the root of a Wheels application.");
            return;
        }
        
        var testPath = testService.generateTest(argumentCollection = arguments);
        
        print.greenLine("Created test: #testPath#");
        
        if (arguments.open) {
            openPath(testPath);
        }
        
        // Suggest running the test
        print.line()
             .yellowLine("Run your test with:")
             .line("wheels test run --filter=#arguments.name#Test");
    }
}
```

#### **Step 1.2.2: Create Test Runner Commands**
Create `/commands/test/run.cfc`:
```cfml
/**
 * Run Wheels application tests
 * Examples:
 * wheels test run
 * wheels test run --filter=UserTest --coverage
 * wheels test run --group=integration --reporter=junit
 */
component extends="wheels-cli.models.BaseCommand" {
    
    property name="testService" inject="TestService@wheels-cli";
    
    /**
     * @filter.hint Filter tests by name pattern
     * @group.hint Run specific test group (unit, integration, etc.)
     * @coverage.hint Generate coverage report
     * @reporter.hint Test reporter format (console, junit, json)
     * @reporter.options console,junit,json,tap
     * @watch.hint Watch for file changes and rerun tests
     * @verbose.hint Verbose output
     */
    function run(
        string filter = "",
        string group = "",
        boolean coverage = false,
        string reporter = "console",
        boolean watch = false,
        boolean verbose = false
    ) {
        if (arguments.watch) {
            return runWithWatch(argumentCollection = arguments);
        }
        
        var result = testService.runTests(argumentCollection = arguments);
        
        // Display results
        if (result.success) {
            print.greenBoldLine("✓ All tests passed!");
        } else {
            print.redBoldLine("✗ Some tests failed");
            setExitCode(1);
        }
        
        if (arguments.coverage && result.coverage) {
            displayCoverageReport(result.coverage);
        }
    }
    
    private function runWithWatch(argumentCollection) {
        print.yellowLine("Watching for file changes... (Press Ctrl+C to stop)")
             .line();
        
        // Use CommandBox file watcher
        var watcher = getInstance("FileWatcher@commandbox-core");
        watcher.watch(
            paths = ["models/**", "handlers/**", "tests/**"],
            callback = function() {
                print.line()
                     .cyanLine("Files changed, running tests...")
                     .line();
                testService.runTests(argumentCollection = arguments);
            }
        );
    }
}
```

### 1.3 Enhanced Migration System

#### **Step 1.3.1: Create Advanced Migration Commands**
Create `/commands/migration/create.cfc`:
```cfml
/**
 * Create a new database migration
 * Examples:
 * wheels migration create create_users_table
 * wheels migration create add_email_to_users --table=users
 * wheels migration create CreateUserPermissions --model=User
 */
component extends="commandbox-migrations.models.BaseMigrationCommand" {
    
    property name="migrationService" inject="MigrationService@wheels-cli";
    property name="templateService" inject="TemplateService@wheels-cli";
    
    /**
     * @name.hint Name of the migration
     * @table.hint Table name for table-specific migrations
     * @model.hint Model name to generate associated migration
     * @type.hint Migration type (create, modify, drop)
     * @type.options create,modify,drop
     * @open.hint Open the created file
     */
    function run(
        required string name,
        string table = "",
        string model = "",
        string type = "create",
        boolean open = false
    ) {
        // Call parent setup
        setup(manager = "default", setupDatasource = false);
        
        var migrationPath = migrationService.createMigration(
            name = arguments.name,
            table = arguments.table,
            model = arguments.model,
            type = arguments.type
        );
        
        print.greenLine("Created migration: #migrationPath#");
        
        if (arguments.open) {
            openPath(migrationPath);
        }
        
        // Show next steps
        print.line()
             .yellowLine("Next steps:")
             .line("1. Edit your migration file")
             .line("2. Run: wheels migration up");
    }
}
```

#### **Step 1.3.2: Create Seeder System**
Create `/commands/seed/create.cfc`:
```cfml
/**
 * Create a database seeder
 * Examples:
 * wheels seed create UserSeeder
 * wheels seed create UserSeeder --model=User --count=50
 */
component extends="wheels-cli.models.BaseCommand" {
    
    property name="migrationService" inject="MigrationService@wheels-cli";
    
    /**
     * @name.hint Name of the seeder
     * @model.hint Associated model name
     * @count.hint Number of records to generate
     */
    function run(
        required string name,
        string model = "",
        numeric count = 10
    ) {
        var seederPath = migrationService.createSeeder(argumentCollection = arguments);
        
        print.greenLine("Created seeder: #seederPath#");
        print.yellowLine("Run with: wheels seed run #arguments.name#");
    }
}
```

### 1.4 Resource-Based Scaffolding

#### **Step 1.4.1: Create Resource Generator**
Create `/commands/generate/resource.cfc`:
```cfml
/**
 * Generate a complete RESTful resource
 * Examples:
 * wheels generate resource User --api --tests
 * wheels generate resource Post --belongs-to=User --has-many=Comments
 */
component extends="wheels-cli.models.BaseCommand" {
    
    property name="templateService" inject="TemplateService@wheels-cli";
    
    /**
     * @name.hint Resource name (singular)
     * @api.hint Generate API-only resource (no views)
     * @tests.hint Generate associated tests
     * @migration.hint Generate database migration
     * @belongs-to.hint Parent model relationships (comma-separated)
     * @has-many.hint Child model relationships (comma-separated)
     * @attributes.hint Model attributes (name:type,email:string)
     * @open.hint Open generated files
     */
    function run(
        required string name,
        boolean api = false,
        boolean tests = true,
        boolean migration = true,
        string belongsTo = "",
        string hasMany = "",
        string attributes = "",
        boolean open = false
    ) {
        var generatedFiles = [];
        
        // Generate model
        var modelPath = generateModel(argumentCollection = arguments);
        arrayAppend(generatedFiles, modelPath);
        
        // Generate controller
        var controllerPath = generateController(argumentCollection = arguments);
        arrayAppend(generatedFiles, controllerPath);
        
        // Generate views (unless API-only)
        if (!arguments.api) {
            var viewPaths = generateViews(argumentCollection = arguments);
            generatedFiles.addAll(viewPaths);
        }
        
        // Generate tests
        if (arguments.tests) {
            var testPaths = generateTests(argumentCollection = arguments);
            generatedFiles.addAll(testPaths);
        }
        
        // Generate migration
        if (arguments.migration) {
            var migrationPath = generateMigration(argumentCollection = arguments);
            arrayAppend(generatedFiles, migrationPath);
        }
        
        // Display summary
        displayGenerationSummary(generatedFiles, arguments);
        
        if (arguments.open) {
            generatedFiles.each(function(file) {
                openPath(file);
            });
        }
    }
    
    private function generateModel(argumentCollection) {
        return templateService.generateFromTemplate(
            template = "resource/model.cfc",
            destination = "models/#arguments.name#.cfc",
            context = arguments
        );
    }
    
    private function generateController(argumentCollection) {
        var controllerName = arguments.api ? "#arguments.name#Api" : arguments.name;
        return templateService.generateFromTemplate(
            template = arguments.api ? "resource/api-controller.cfc" : "resource/controller.cfc",
            destination = "controllers/#controllerName#.cfc",
            context = arguments
        );
    }
}
```

## Phase 2: Advanced Features (Month 3-4)

### 2.1 File Watching System

#### **Step 2.1.1: Create Watch Command**
Create `/commands/watch.cfc`:
```cfml
/**
 * Watch for file changes and perform actions
 * Examples:
 * wheels watch --reload
 * wheels watch --tests --migration
 * wheels watch --pattern="models/**" --command="wheels test run"
 */
component extends="wheels-cli.models.BaseCommand" {
    
    property name="fileWatcher" inject="FileWatcher@commandbox-core";
    property name="serverService" inject="ServerService@commandbox-core";
    
    /**
     * @reload.hint Reload framework on changes
     * @tests.hint Run tests on changes
     * @migration.hint Run migrations on schema changes
     * @pattern.hint File pattern to watch (default: all Wheels files)
     * @command.hint Custom command to run on changes
     * @debounce.hint Debounce delay in milliseconds
     */
    function run(
        boolean reload = false,
        boolean tests = false,
        boolean migration = false,
        string pattern = "models/**,handlers/**,views/**",
        string command = "",
        numeric debounce = 500
    ) {
        print.yellowLine("👀 Watching files for changes... (Press Ctrl+C to stop)")
             .line();
        
        var patterns = listToArray(arguments.pattern);
        var lastRun = now();
        
        fileWatcher.watch(
            paths = patterns,
            callback = function(changes) {
                // Debounce rapid changes
                if (dateDiff("l", lastRun, now()) < arguments.debounce) {
                    return;
                }
                lastRun = now();
                
                print.line()
                     .cyanLine("📝 Files changed:")
                     .line();
                
                changes.each(function(change) {
                    print.line("  " & change.type & ": " & change.path);
                });
                
                handleChanges(changes, arguments);
            }
        );
    }
    
    private function handleChanges(changes, options) {
        if (options.reload) {
            reloadFramework();
        }
        
        if (options.tests) {
            runCommand("wheels test run --filter=changed");
        }
        
        if (options.migration && hasMigrationChanges(changes)) {
            runCommand("wheels migration up");
        }
        
        if (len(options.command)) {
            runCommand(options.command);
        }
    }
}
```

### 2.2 Code Quality Tools

#### **Step 2.2.1: Create Analyze Command**
Create `/commands/analyze/code.cfc`:
```cfml
/**
 * Analyze code quality and patterns
 * Examples:
 * wheels analyze code
 * wheels analyze code --fix --format=json
 */
component extends="wheels-cli.models.BaseCommand" {
    
    property name="analysisService" inject="AnalysisService@wheels-cli";
    
    /**
     * @path.hint Path to analyze (default: current directory)
     * @fix.hint Attempt to fix issues automatically
     * @format.hint Output format (console, json, junit)
     * @format.options console,json,junit
     * @severity.hint Minimum severity level (info, warning, error)
     * @severity.options info,warning,error
     */
    function run(
        string path = ".",
        boolean fix = false,
        string format = "console",
        string severity = "warning"
    ) {
        print.yellowLine("🔍 Analyzing code quality...")
             .line();
        
        var results = analysisService.analyze(
            path = resolvePath(arguments.path),
            severity = arguments.severity
        );
        
        if (arguments.fix) {
            var fixed = analysisService.autoFix(results);
            print.greenLine("✅ Fixed #fixed.count# issues automatically");
        }
        
        displayResults(results, arguments.format);
        
        if (results.hasErrors) {
            setExitCode(1);
        }
    }
    
    private function displayResults(results, format) {
        switch (format) {
            case "json":
                print.line(serializeJSON(results, true));
                break;
            case "junit":
                print.line(generateJUnitXML(results));
                break;
            default:
                displayConsoleResults(results);
        }
    }
}
```

### 2.3 Documentation Generation

#### **Step 2.3.1: Create Docs Commands**
Create `/commands/docs/generate.cfc`:
```cfml
/**
 * Generate API documentation
 * Examples:
 * wheels docs generate
 * wheels docs generate --output=docs/api --format=html
 */
component extends="wheels-cli.models.BaseCommand" {
    
    property name="docService" inject="DocService@wheels-cli";
    
    /**
     * @output.hint Output directory for docs
     * @format.hint Documentation format (html, json, markdown)
     * @format.options html,json,markdown
     * @template.hint Documentation template to use
     * @serve.hint Start local server after generation
     */
    function run(
        string output = "docs/api",
        string format = "html",
        string template = "default",
        boolean serve = false
    ) {
        print.yellowLine("📚 Generating documentation...")
             .line();
        
        var outputPath = resolvePath(arguments.output);
        
        var result = docService.generate(
            source = resolvePath("models"),
            output = outputPath,
            format = arguments.format,
            template = arguments.template
        );
        
        print.greenLine("✅ Documentation generated in: #outputPath#");
        
        if (arguments.serve) {
            runCommand("wheels docs serve");
        }
    }
}
```

## Phase 3: Ecosystem Integration (Month 5-6)

### 3.1 Enhanced Dependency Management

#### **Step 3.1.1: Create Plugin System**
Create `/commands/plugin/install.cfc`:
```cfml
/**
 * Install Wheels CLI plugins
 * Examples:
 * wheels plugin install wheels-vue-cli
 * wheels plugin install wheels-docker --dev
 */
component extends="wheels-cli.models.BaseCommand" {
    
    property name="pluginService" inject="PluginService@wheels-cli";
    
    /**
     * @name.hint Plugin name or repository URL
     * @dev.hint Install as development dependency
     * @global.hint Install globally
     * @version.hint Specific version to install
     */
    function run(
        required string name,
        boolean dev = false,
        boolean global = false,
        string version = ""
    ) {
        print.yellowLine("📦 Installing plugin: #arguments.name#...")
             .line();
        
        var result = pluginService.install(argumentCollection = arguments);
        
        if (result.success) {
            print.greenLine("✅ Plugin installed successfully");
            print.line("Run 'wheels plugin list' to see installed plugins");
        } else {
            print.redLine("❌ Failed to install plugin: #result.error#");
            setExitCode(1);
        }
    }
}
```

### 3.2 Environment Management

#### **Step 3.2.1: Create Environment Commands**
Create `/commands/env/setup.cfc`:
```cfml
/**
 * Setup development environment
 * Examples:
 * wheels env setup development
 * wheels env setup --template=docker --database=postgres
 */
component extends="wheels-cli.models.BaseCommand" {
    
    property name="envService" inject="EnvironmentService@wheels-cli";
    
    /**
     * @environment.hint Environment name (development, staging, production)
     * @template.hint Environment template (local, docker, vagrant)
     * @template.options local,docker,vagrant
     * @database.hint Database type (h2, mysql, postgres, mssql)
     * @database.options h2,mysql,postgres,mssql
     * @force.hint Overwrite existing configuration
     */
    function run(
        required string environment,
        string template = "local",
        string database = "h2",
        boolean force = false
    ) {
        print.yellowLine("🛠️  Setting up #arguments.environment# environment...")
             .line();
        
        var result = envService.setup(argumentCollection = arguments);
        
        if (result.success) {
            print.greenLine("✅ Environment setup complete!");
            displayNextSteps(result.nextSteps);
        } else {
            print.redLine("❌ Setup failed: #result.error#");
            setExitCode(1);
        }
    }
}
```

## Phase 4: Advanced Tooling (Month 7-8)

### 4.1 Performance & Security

#### **Step 4.1.1: Create Security Scanner**
Create `/commands/security/scan.cfc`:
```cfml
/**
 * Scan for security vulnerabilities
 * Examples:
 * wheels security scan
 * wheels security scan --fix --report=json
 */
component extends="wheels-cli.models.BaseCommand" {
    
    property name="securityService" inject="SecurityService@wheels-cli";
    
    /**
     * @path.hint Path to scan (default: current directory)
     * @fix.hint Attempt to fix issues automatically
     * @report.hint Generate report in specified format
     * @report.options console,json,html
     * @severity.hint Minimum severity to report
     * @severity.options low,medium,high,critical
     */
    function run(
        string path = ".",
        boolean fix = false,
        string report = "console",
        string severity = "medium"
    ) {
        print.yellowLine("🔒 Scanning for security issues...")
             .line();
        
        var results = securityService.scan(
            path = resolvePath(arguments.path),
            severity = arguments.severity
        );
        
        displaySecurityResults(results, arguments.report);
        
        if (arguments.fix && results.fixableIssues.len()) {
            var fixed = securityService.autoFix(results.fixableIssues);
            print.greenLine("✅ Fixed #fixed# security issues");
        }
        
        if (results.hasHighSeverity) {
            setExitCode(1);
        }
    }
}
```

### 4.2 Performance Optimization

#### **Step 4.2.1: Create Performance Tools**
Create `/commands/optimize/performance.cfc`:
```cfml
/**
 * Optimize application performance
 * Examples:
 * wheels optimize performance
 * wheels optimize performance --cache --assets
 */
component extends="wheels-cli.models.BaseCommand" {
    
    property name="optimizationService" inject="OptimizationService@wheels-cli";
    
    /**
     * @cache.hint Optimize caching configuration
     * @assets.hint Optimize static assets
     * @database.hint Optimize database queries
     * @analysis.hint Generate performance analysis report
     */
    function run(
        boolean cache = true,
        boolean assets = true,
        boolean database = true,
        boolean analysis = false
    ) {
        print.yellowLine("⚡ Optimizing application performance...")
             .line();
        
        var results = {};
        
        if (arguments.cache) {
            results.cache = optimizationService.optimizeCache();
            print.greenLine("✅ Cache optimization complete");
        }
        
        if (arguments.assets) {
            results.assets = optimizationService.optimizeAssets();
            print.greenLine("✅ Asset optimization complete");
        }
        
        if (arguments.database) {
            results.database = optimizationService.optimizeDatabase();
            print.greenLine("✅ Database optimization complete");
        }
        
        if (arguments.analysis) {
            var report = optimizationService.generateReport(results);
            print.line()
                 .yellowLine("📊 Performance Analysis Report:")
                 .line(report);
        }
    }
}
```

## Implementation Services

### Service Layer Architecture

#### **Base Command Service**
Create `/models/BaseCommand.cfc`:
```cfml
component extends="commandbox.system.BaseCommand" {
    
    property name="configService" inject="ConfigService@commandbox-core";
    property name="fileSystemUtil" inject="FileSystem@commandbox-core";
    
    /**
     * Check if current directory is a Wheels project
     */
    function isWheelsProject() {
        return fileExists(resolvePath("box.json")) && 
               (fileExists(resolvePath("Application.cfc")) || 
                fileExists(resolvePath("Application.cfm")));
    }
    
    /**
     * Get Wheels version from box.json
     */
    function getWheelsVersion() {
        var boxPath = resolvePath("box.json");
        if (fileExists(boxPath)) {
            var boxData = deserializeJSON(fileRead(boxPath));
            return boxData.dependencies.keyExists("wheels") ? 
                   boxData.dependencies.wheels : "unknown";
        }
        return "unknown";
    }
    
    /**
     * Display file generation summary
     */
    function displayGenerationSummary(files, options) {
        print.line()
             .greenBoldLine("🎉 Generated #files.len()# files:")
             .line();
        
        files.each(function(file) {
            print.greenLine("  ✓ #file#");
        });
        
        print.line()
             .yellowLine("Next steps:")
             .line("1. Review generated files")
             .line("2. Run tests: wheels test run")
             .line("3. Start server: server start");
    }
}
```

#### **Template Service**
Create `/models/TemplateService.cfc`:
```cfml
component {
    
    property name="fileSystemUtil" inject="FileSystem@commandbox-core";
    
    /**
     * Generate file from template
     */
    function generateFromTemplate(
        required string template,
        required string destination,
        required struct context
    ) {
        var templatePath = expandPath("/wheels-cli/templates/#arguments.template#");
        var destinationPath = resolvePath(arguments.destination);
        
        if (!fileExists(templatePath)) {
            throw("Template not found: #arguments.template#");
        }
        
        var templateContent = fileRead(templatePath);
        var processedContent = processTemplate(templateContent, arguments.context);
        
        // Ensure destination directory exists
        var destinationDir = getDirectoryFromPath(destinationPath);
        if (!directoryExists(destinationDir)) {
            directoryCreate(destinationDir, true);
        }
        
        fileWrite(destinationPath, processedContent);
        
        return destinationPath;
    }
    
    private function processTemplate(content, context) {
        // Simple template processing - replace {{variable}} with context values
        var processed = arguments.content;
        
        for (var key in arguments.context) {
            var value = arguments.context[key];
            processed = reReplace(processed, "\{\{#key#\}\}", value, "all");
        }
        
        return processed;
    }
}
```

## Testing Strategy

### Unit Tests for New Commands
Create `/tests/specs/integration/GenerateResourceTest.cfc`:
```cfml
component extends="testbox.system.BaseSpec" {
    
    function beforeAll() {
        // Setup test environment
        variables.testDir = getTempDirectory() & "wheels-cli-test-" & createUUID();
        directoryCreate(variables.testDir);
        
        // Initialize mock Wheels project
        setupMockWheelsProject();
    }
    
    function afterAll() {
        if (directoryExists(variables.testDir)) {
            directoryDelete(variables.testDir, true);
        }
    }
    
    function run() {
        describe("Generate Resource Command", function() {
            
            it("should generate a complete resource", function() {
                var result = runCommand("wheels generate resource User --api --tests");
                
                expect(result.exitCode).toBe(0);
                expect(fileExists("#variables.testDir#/models/User.cfc")).toBeTrue();
                expect(fileExists("#variables.testDir#/controllers/UserApi.cfc")).toBeTrue();
                expect(fileExists("#variables.testDir#/tests/specs/unit/UserTest.cfc")).toBeTrue();
            });
            
            it("should handle relationships correctly", function() {
                var result = runCommand("wheels generate resource Post --belongs-to=User --has-many=Comments");
                
                expect(result.exitCode).toBe(0);
                
                var modelContent = fileRead("#variables.testDir#/models/Post.cfc");
                expect(modelContent).toInclude("belongsTo('User')");
                expect(modelContent).toInclude("hasMany('Comments')");
            });
            
        });
    }
    
    private function setupMockWheelsProject() {
        // Create minimal Wheels project structure
        fileWrite("#variables.testDir#/box.json", '{"dependencies":{"wheels":"3.0.0"}}');
        fileWrite("#variables.testDir#/Application.cfc", 'component extends="wheels.Application" {}');
        directoryCreate("#variables.testDir#/models", true);
        directoryCreate("#variables.testDir#/controllers", true);
        directoryCreate("#variables.testDir#/tests/specs/unit", true);
    }
}
```

## Deployment & Distribution

### CI/CD Pipeline
Create `/.github/workflows/release.yml`:
```yaml
name: Release Wheels CLI

on:
  release:
    types: [published]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Setup CommandBox
        uses: Ortus-Solutions/setup-commandbox@v2.0.1
      - name: Install Dependencies
        run: box install
      - name: Run Tests
        run: box testbox run
        
  publish:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Setup CommandBox
        uses: Ortus-Solutions/setup-commandbox@v2.0.1
      - name: Build Package
        run: box recipe build/build.boxr
      - name: Publish to ForgeBox
        run: box publish
        env:
          FORGEBOX_TOKEN: ${{ secrets.FORGEBOX_TOKEN }}
```

## Migration Guide

### Backward Compatibility Strategy
1. **Alias Support**: Maintain existing command aliases
2. **Deprecation Warnings**: Gradually deprecate old patterns with warnings
3. **Configuration Migration**: Auto-migrate old configuration formats
4. **Documentation**: Provide clear migration guides

### Example Migration Script
Create `/commands/migrate-cli.cfc`:
```cfml
/**
 * Migrate from old CLI version to new version
 */
component extends="wheels-cli.models.BaseCommand" {
    
    function run() {
        print.yellowLine("🔄 Migrating CLI configuration...")
             .line();
        
        // Migrate old box.json format
        migrateBoxJson();
        
        // Update file structure
        migrateFileStructure();
        
        // Update configuration files
        migrateConfiguration();
        
        print.greenLine("✅ Migration complete!");
        print.yellowLine("Please review changes and commit to version control.");
    }
}
```

## Success Metrics & Monitoring

### Key Performance Indicators
- **Command Execution Time**: < 2 seconds for most operations
- **Test Coverage**: > 85% for all new functionality
- **Documentation Coverage**: 100% for public APIs
- **User Adoption**: Track command usage via analytics

### Monitoring Dashboard
Create analytics tracking for:
- Most used commands
- Error rates by command
- Performance metrics
- User feedback scores

This implementation plan provides a concrete roadmap for modernizing the Wheels CLI while maintaining backward compatibility and providing immediate value to developers. Each phase builds upon the previous one, allowing for incremental delivery and feedback incorporation.