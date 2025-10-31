# Creating Custom Commands Guide

Learn how to extend Wheels CLI with your own custom commands.

## Overview

Wheels CLI is built on CommandBox, making it easy to add custom commands. Commands can be simple scripts or complex operations using the service architecture.

## Basic Command Structure

### 1. Create Command File

Create a new file in `/commands/wheels/`:

```cfc
// commands/wheels/hello.cfc
component extends="wheels.cli.models.BaseCommand" {
    
    /**
     * Say hello
     */
    function run(string name = "World") {
        print.line("Hello, #arguments.name#!");
    }
    
}
```

### 2. Run Your Command

```bash
wheels hello
# Output: Hello, World!

wheels hello John
# Output: Hello, John!
```

## Command Anatomy

### Component Structure

```cfc
component extends="wheels.cli.models.BaseCommand" {
    
    // Command metadata
    property name="name" default="mycommand";
    property name="description" default="Does something useful";
    
    // Service injection
    property name="myService" inject="MyService@wheels-cli";
    
    /**
     * Main command entry point
     * 
     * @name Name of something
     * @force Force overwrite
     * @name.hint The name to use
     * @force.hint Whether to force
     */
    function run(
        required string name,
        boolean force = false
    ) {
        // Command logic here
    }
    
}
```

### Command Help

CommandBox generates help from your code:

```bash
wheels hello --help

NAME
  wheels hello

SYNOPSIS
  wheels hello [name]

DESCRIPTION
  Say hello

ARGUMENTS
  name = World
    Name to greet
```

## Advanced Commands

### 1. Multi-Level Commands

Create nested command structure:

```cfc
// commands/wheels/deploy.cfc
component extends="wheels.cli.models.BaseCommand" {
    function run() {
        print.line("Usage: wheels deploy [staging|production]");
    }
}

// commands/wheels/deploy/staging.cfc
component extends="wheels.cli.models.BaseCommand" {
    function run() {
        print.line("Deploying to staging...");
    }
}

// commands/wheels/deploy/production.cfc
component extends="wheels.cli.models.BaseCommand" {
    function run() {
        print.line("Deploying to production...");
    }
}
```

Usage:
```bash
wheels deploy staging
wheels deploy production
```

### 2. Interactive Commands

Get user input:

```cfc
component extends="wheels.cli.models.BaseCommand" {
    
    function run() {
        // Simple input
        var name = ask("What's your name? ");
        
        // Masked input (passwords)
        var password = ask("Enter password: ", "*");
        
        // Confirmation
        if (confirm("Are you sure?")) {
            print.line("Proceeding...");
        }
        
        // Multiple choice
        var choice = multiselect()
            .setQuestion("Select features to install:")
            .setOptions([
                "Authentication",
                "API",
                "Admin Panel",
                "Blog"
            ])
            .ask();
    }
    
}
```

### 3. Progress Indicators

Show progress for long operations:

```cfc
component extends="wheels.cli.models.BaseCommand" {
    
    function run() {
        // Progress bar
        var progressBar = progressBar.create(total=100);
        
        for (var i = 1; i <= 100; i++) {
            // Do work
            sleep(50);
            
            // Update progress
            progressBar.update(
                current = i,
                message = "Processing item #i#"
            );
        }
        
        progressBar.clear();
        print.greenLine("✓ Complete!");
        
        // Spinner
        var spinner = progressSpinner.create();
        spinner.start("Loading...");
        
        // Do work
        sleep(2000);
        
        spinner.stop();
    }
    
}
```

## Using Services

### 1. Inject Existing Services

```cfc
component extends="wheels.cli.models.BaseCommand" {
    
    property name="codeGenerationService" inject="CodeGenerationService@wheels-cli";
    property name="templateService" inject="TemplateService@wheels-cli";
    
    function run(required string name) {
        // Use services
        var template = templateService.getTemplate("custom");
        var result = codeGenerationService.generateFromTemplate(
            template = template,
            data = {name: arguments.name}
        );
        
        print.greenLine("Generated: #result.path#");
    }
    
}
```

### 2. Create Custom Service

```cfc
// models/CustomService.cfc
component singleton {
    
    function processData(required struct data) {
        // Service logic
        return data;
    }
    
}

// Register in ModuleConfig.cfc
binder.map("CustomService@wheels-cli")
    .to("wheels.cli.models.CustomService")
    .asSingleton();
```

## File Operations

### Reading Files

```cfc
function run(required string file) {
    var filePath = resolvePath(arguments.file);
    
    if (!fileExists(filePath)) {
        error("File not found: #filePath#");
    }
    
    var content = fileRead(filePath);
    print.line(content);
}
```

### Writing Files

```cfc
function run(required string name) {
    var content = "Hello, #arguments.name#!";
    var filePath = resolvePath("output.txt");
    
    if (fileExists(filePath) && !confirm("Overwrite existing file?")) {
        return;
    }
    
    fileWrite(filePath, content);
    print.greenLine("✓ File created: #filePath#");
}
```

### Directory Operations

```cfc
function run(required string dir) {
    // Create directory
    ensureDirectoryExists(arguments.dir);
    
    // List files
    var files = directoryList(
        path = resolvePath(arguments.dir),
        recurse = true,
        filter = "*.cfc"
    );
    
    for (var file in files) {
        print.line(file);
    }
}
```

## Output Formatting

### Colored Output

```cfc
function run() {
    // Basic colors
    print.line("Normal text");
    print.redLine("Error message");
    print.greenLine("Success message");
    print.yellowLine("Warning message");
    print.blueLine("Info message");
    
    // Bold
    print.boldLine("Important!");
    print.boldRedLine("Critical error!");
    
    // Inline colors
    print.line("This is #print.red('red')# and #print.green('green')#");
}
```

### Tables

```cfc
function run() {
    // Create table
    print.table([
        ["Name", "Type", "Size"],
        ["users.cfc", "Model", "2KB"],
        ["posts.cfc", "Model", "3KB"],
        ["comments.cfc", "Model", "1KB"]
    ]);
    
    // With headers
    var data = queryNew("name,type,size", "varchar,varchar,varchar", [
        ["users.cfc", "Model", "2KB"],
        ["posts.cfc", "Model", "3KB"]
    ]);
    
    print.table(
        data = data,
        headers = ["File Name", "Type", "File Size"]
    );
}
```

### Trees

```cfc
function run() {
    print.tree([
        {
            label: "models",
            children: [
                {label: "User.cfc"},
                {label: "Post.cfc"},
                {label: "Comment.cfc"}
            ]
        },
        {
            label: "controllers",
            children: [
                {label: "Users.cfc"},
                {label: "Posts.cfc"}
            ]
        }
    ]);
}
```

## Error Handling

### Basic Error Handling

```cfc
function run(required string file) {
    try {
        var content = fileRead(arguments.file);
        processFile(content);
        print.greenLine("✓ Success");
    } catch (any e) {
        print.redLine("✗ Error: #e.message#");
        
        if (arguments.verbose ?: false) {
            print.line(e.detail);
            print.line(e.stacktrace);
        }
        
        // Set exit code
        return 1;
    }
}
```

### Custom Error Messages

```cfc
function run(required string name) {
    // Validation
    if (!isValidName(arguments.name)) {
        error("Invalid name. Names must be alphanumeric.");
    }

    // Warnings
    if (hasSpecialChars(arguments.name)) {
        print.yellowLine("Warning: Special characters detected");
    }

    // Success
    print.greenLine("Name is valid");
}

private function error(required string message) {
    print.redLine("#arguments.message#");
    exit(1);
}
```

## Command Testing

### Unit Testing Commands

```cfc
// tests/commands/HelloTest.cfc
component extends="wheels.Testbox" {
    
    function run() {
        describe("Hello Command", function() {
            
            it("greets with default name", function() {
                var result = execute("wheels hello");
                expect(result).toInclude("Hello, World!");
            });
            
            it("greets with custom name", function() {
                var result = execute("wheels hello John");
                expect(result).toInclude("Hello, John!");
            });
            
        });
    }
    
    private function execute(required string command) {
        // Capture output
        savecontent variable="local.output" {
            shell.run(arguments.command);
        }
        return local.output;
    }
    
}
```

### Integration Testing

```cfc
it("generates files correctly", function() {
    // Run command
    execute("wheels generate custom test");
    
    // Verify files created
    expect(fileExists("/custom/test.cfc")).toBeTrue();
    
    // Verify content
    var content = fileRead("/custom/test.cfc");
    expect(content).toInclude("component");
    
    // Cleanup
    fileDelete("/custom/test.cfc");
});
```

## Best Practices

### 1. Command Naming

- Use verbs for actions: `generate`, `create`, `deploy`
- Use nouns for resources: `model`, `controller`, `migration`
- Be consistent with existing commands

### 2. Argument Validation

```cfc
function run(required string name, string type = "default") {
    // Validate required
    if (!len(trim(arguments.name))) {
        error("Name cannot be empty");
    }
    
    // Validate options
    var validTypes = ["default", "custom", "advanced"];
    if (!arrayFind(validTypes, arguments.type)) {
        error("Invalid type. Must be one of: #arrayToList(validTypes)#");
    }
}
```

### 3. Provide Feedback

```cfc
function run() {
    print.line("Starting process...").toConsole();
    
    // Show what's happening
    print.indentedLine("→ Loading configuration");
    var config = loadConfig();
    
    print.indentedLine("→ Processing files");
    var count = processFiles();
    
    print.indentedLine("→ Saving results");
    saveResults();
    
    print.greenBoldLine("✓ Complete! Processed #count# files.");
}
```

### 4. Make Commands Idempotent

```cfc
function run(required string name) {
    var filePath = resolvePath("#arguments.name#.txt");
    
    // Check if already exists
    if (fileExists(filePath)) {
        print.yellowLine("File already exists, skipping");
        return;
    }
    
    // Create file
    fileWrite(filePath, "content");
    print.greenLine("✓ Created file");
}
```

## Publishing Commands

### 1. Package as Module

Create `box.json`:

```json
{
    "name": "my-wheels-commands",
    "version": "1.0.0",
    "type": "commandbox-modules",
    "dependencies": {
        "wheels-cli": "^3.0.0"
    }
}
```

### 2. Module Structure

```
my-wheels-commands/
├── ModuleConfig.cfc
├── commands/
│   └── wheels/
│       └── mycommand.cfc
└── models/
    └── MyService.cfc
```

### 3. Publish to ForgeBox

```bash
box forgebox publish
```

## Examples

### Database Backup Command

```cfc
// commands/wheels/db/backup.cfc
component extends="wheels.cli.models.BaseCommand" {
    
    property name="datasource" inject="coldbox:datasource";
    
    function run(string file = "backup-#dateFormat(now(), 'yyyy-mm-dd')#.sql") {
        print.line("Creating database backup...").toConsole();
        
        var spinner = progressSpinner.create();
        spinner.start("Backing up database");
        
        try {
            // Get database info
            var dbInfo = getDatabaseInfo();
            
            // Create backup
            var backupPath = resolvePath(arguments.file);
            createBackup(dbInfo, backupPath);
            
            spinner.stop();
            print.greenBoldLine("✓ Backup created: #backupPath#");
            
        } catch (any e) {
            spinner.stop();
            print.redLine("✗ Backup failed: #e.message#");
            return 1;
        }
    }
    
}
```

### Code Quality Command

```cfc
// commands/wheels/quality.cfc
component extends="wheels.cli.models.BaseCommand" {
    
    property name="analysisService" inject="AnalysisService@wheels-cli";
    
    function run(string path = ".", boolean fix = false) {
        var issues = analysisService.analyze(arguments.path);
        
        if (arrayLen(issues)) {
            print.redLine("Found #arrayLen(issues)# issues:");
            
            for (var issue in issues) {
                print.line("#issue.file#:#issue.line# - #issue.message#");
            }
            
            if (arguments.fix) {
                print.line().line("Attempting fixes...");
                var fixed = analysisService.fix(issues);
                print.greenLine("Fixed #fixed# issues");
            }
        } else {
            print.greenLine("✓ No issues found!");
        }
    }
    
}
```

## See Also

- [Service Architecture](service-architecture.md)
- [Testing Guide](testing.md)
- [CommandBox Documentation](https://commandbox.ortusbooks.com/)
- [Contributing to Wheels CLI](../CONTRIBUTING.md)