# Service Architecture Guide

Understanding the Wheels CLI service layer architecture.

## Overview

The Wheels CLI uses a service-oriented architecture that separates concerns and provides reusable functionality across commands. This architecture makes the CLI more maintainable, testable, and extensible.

## Architecture Diagram

```
┌─────────────────┐
│    Commands     │  ← User interacts with
├─────────────────┤
│    Services     │  ← Business logic
├─────────────────┤
│     Models      │  ← Data and utilities
├─────────────────┤
│   Templates     │  ← Code generation
└─────────────────┘
```

## Core Components

### 1. Commands (`/commands/wheels/`)

Commands are the user-facing interface:

```cfc
// commands/wheels/generate/model.cfc
component extends="wheels.cli.models.BaseCommand" {
    
    property name="codeGenerationService" inject="CodeGenerationService@wheels-cli";
    property name="migrationService" inject="MigrationService@wheels-cli";
    
    function run(
        required string name,
        boolean migration = true,
        string properties = "",
        boolean force = false
    ) {
        // Delegate to services
        var result = codeGenerationService.generateModel(argumentCollection=arguments);
        
        if (arguments.migration) {
            migrationService.createTableMigration(arguments.name, arguments.properties);
        }
        
        print.greenLine("✓ Model generated successfully");
    }
}
```

### 2. Services (`/models/`)

Services contain reusable business logic:

```cfc
// models/CodeGenerationService.cfc
component accessors="true" singleton {
    
    property name="templateService" inject="TemplateService@wheels-cli";
    property name="fileService" inject="FileService@wheels-cli";
    
    function generateModel(
        required string name,
        string properties = "",
        struct associations = {},
        boolean force = false
    ) {
        var modelName = helpers.capitalize(arguments.name);
        var template = templateService.getTemplate("model");
        var content = templateService.populateTemplate(template, {
            modelName: modelName,
            properties: parseProperties(arguments.properties),
            associations: arguments.associations
        });
        
        return fileService.writeFile(
            path = "/models/#modelName#.cfc",
            content = content,
            force = arguments.force
        );
    }
}
```

### 3. Base Classes

#### BaseCommand (`/models/BaseCommand.cfc`)

All commands extend from BaseCommand:

```cfc
component extends="commandbox.system.BaseCommand" {
    
    property name="print" inject="print";
    property name="fileSystemUtil" inject="FileSystem";
    
    function init() {
        // Common initialization
        return this;
    }
    
    // Common helper methods
    function ensureDirectoryExists(required string path) {
        if (!directoryExists(arguments.path)) {
            directoryCreate(arguments.path, true);
        }
    }
    
    function resolvePath(required string path) {
        return fileSystemUtil.resolvePath(arguments.path);
    }
}
```

## Service Catalog

### Core Services

#### TemplateService
Manages code generation templates with override system:
- **Template Loading**: Searches app snippets first, then CLI templates
- **Variable Substitution**: Replaces placeholders with actual values
- **Custom Template Support**: Apps can override any CLI template
- **Path Resolution**: `app/snippets/` overrides `/cli/templates/`
- **Dynamic Content**: Generates form fields, validations, relationships

Key features:
- Template hierarchy allows project customization
- Preserves markers for future CLI additions
- Supports conditional logic in templates
- Handles both simple and complex placeholders

See [Template System Guide](template-system.md) for detailed documentation.

#### MigrationService
Handles database migrations:
- Generate migration files
- Track migration status
- Execute migrations

#### TestService
Testing functionality:
- Run TestBox tests
- Generate coverage reports
- Watch mode support

#### CodeGenerationService
Centralized code generation:
- Generate models, controllers, views
- Handle associations
- Manage validations

### Feature Services

#### AnalysisService
Code analysis tools:
- Complexity analysis
- Code style checking
- Dependency analysis

#### SecurityService
Security scanning:
- SQL injection detection
- XSS vulnerability scanning
- Hardcoded credential detection

#### OptimizationService
Performance optimization:
- Cache analysis
- Query optimization
- Asset optimization

#### PluginService
Plugin management:
- Install/remove plugins
- Version management
- Dependency resolution

#### EnvironmentService
Environment management:
- Environment switching
- Configuration management
- Docker/Vagrant support

## Dependency Injection

Services use WireBox for dependency injection:

```cfc
// In ModuleConfig.cfc
function configure() {
    // Service mappings
    binder.map("TemplateService@wheels-cli")
        .to("wheels.cli.models.TemplateService")
        .asSingleton();
    
    binder.map("MigrationService@wheels-cli")
        .to("wheels.cli.models.MigrationService")
        .asSingleton();
}
```

## Creating a New Service

### 1. Create Service Component

```cfc
// models/MyNewService.cfc
component accessors="true" singleton {
    
    // Inject dependencies
    property name="fileService" inject="FileService@wheels-cli";
    property name="print" inject="print";
    
    function init() {
        return this;
    }
    
    function doSomething(required string input) {
        // Service logic here
        return processInput(arguments.input);
    }
    
    private function processInput(required string input) {
        // Private helper methods
        return arguments.input.trim();
    }
}
```

### 2. Register Service

In `/ModuleConfig.cfc`:

```cfc
binder.map("MyNewService@wheels-cli")
    .to("wheels.cli.models.MyNewService")
    .asSingleton();
```

### 3. Use in Commands

```cfc
component extends="wheels.cli.models.BaseCommand" {
    
    property name="myNewService" inject="MyNewService@wheels-cli";
    
    function run(required string input) {
        var result = myNewService.doSomething(arguments.input);
        print.line(result);
    }
}
```

## Service Patterns

### 1. Singleton Pattern

Most services are singletons:

```cfc
component singleton {
    // Shared instance across commands
}
```

### 2. Factory Pattern

For creating multiple instances:

```cfc
component {
    function createGenerator(required string type) {
        switch(arguments.type) {
            case "model":
                return new ModelGenerator();
            case "controller":
                return new ControllerGenerator();
        }
    }
}
```

### 3. Strategy Pattern

For different implementations:

```cfc
component {
    function setStrategy(required component strategy) {
        variables.strategy = arguments.strategy;
    }
    
    function execute() {
        return variables.strategy.execute();
    }
}
```

## Testing Services

### Unit Testing Services

```cfc
component extends="testbox.system.BaseSpec" {
    
    function beforeAll() {
        // Create service instance
        variables.templateService = createMock("wheels.cli.models.TemplateService");
    }
    
    function run() {
        describe("TemplateService", function() {
            
            it("loads templates correctly", function() {
                var template = templateService.getTemplate("model");
                expect(template).toBeString();
                expect(template).toInclude("component extends=""Model""");
            });
            
            it("substitutes variables", function() {
                var result = templateService.populateTemplate(
                    "Hello {{name}}",
                    {name: "World"}
                );
                expect(result).toBe("Hello World");
            });
            
        });
    }
}
```

### Mocking Dependencies

```cfc
function beforeAll() {
    // Create mock
    mockFileService = createEmptyMock("FileService");
    
    // Define behavior
    mockFileService.$("writeFile").$results(true);
    
    // Inject mock
    templateService.$property(
        propertyName = "fileService",
        mock = mockFileService
    );
}
```

## Best Practices

### 1. Single Responsibility

Each service should have one clear purpose:

```cfc
// Good: Focused service
component name="ValidationService" {
    function validateModel() {}
    function validateController() {}
}

// Bad: Mixed responsibilities
component name="UtilityService" {
    function validateModel() {}
    function sendEmail() {}
    function generatePDF() {}
}
```

### 2. Dependency Injection

Always inject dependencies:

```cfc
// Good: Injected dependency
property name="fileService" inject="FileService@wheels-cli";

// Bad: Direct instantiation
variables.fileService = new FileService();
```

### 3. Error Handling

Services should handle errors gracefully:

```cfc
function generateFile(required string path) {
    try {
        // Attempt operation
        fileWrite(arguments.path, content);
        return {success: true};
    } catch (any e) {
        // Log error
        logError(e);
        // Return error info
        return {
            success: false,
            error: e.message
        };
    }
}
```

### 4. Configuration

Services should be configurable:

```cfc
component {
    property name="settings" inject="coldbox:modulesettings:wheels-cli";
    
    function getTimeout() {
        return variables.settings.timeout ?: 30;
    }
}
```

## Service Communication

### Event-Driven

Services can emit events:

```cfc
// In service
announce("wheels-cli:modelGenerated", {model: modelName});

// In listener
function onModelGenerated(event, data) {
    // React to event
}
```

### Direct Communication

Services can call each other:

```cfc
component {
    property name="validationService" inject="ValidationService@wheels-cli";
    
    function generateModel() {
        // Validate first
        if (!validationService.isValidModelName(name)) {
            throw("Invalid model name");
        }
        // Continue generation
    }
}
```

## Extending Services

### Creating Service Plugins

```cfc
// models/plugins/MyServicePlugin.cfc
component implements="IServicePlugin" {
    
    function enhance(required component service) {
        // Add new method
        arguments.service.myNewMethod = function() {
            return "Enhanced!";
        };
    }
}
```

### Service Decorators

```cfc
component extends="BaseService" {
    
    property name="decoratedService";
    
    function init(required component service) {
        variables.decoratedService = arguments.service;
        return this;
    }
    
    function doSomething() {
        // Add behavior
        log("Calling doSomething");
        // Delegate
        return variables.decoratedService.doSomething();
    }
}
```

## Performance Considerations

### 1. Lazy Loading

Load services only when needed:

```cfc
function getTemplateService() {
    if (!structKeyExists(variables, "templateService")) {
        variables.templateService = getInstance("TemplateService@wheels-cli");
    }
    return variables.templateService;
}
```

### 2. Caching

Cache expensive operations:

```cfc
component {
    property name="cache" default={};
    
    function getTemplate(required string name) {
        if (!structKeyExists(variables.cache, arguments.name)) {
            variables.cache[arguments.name] = loadTemplate(arguments.name);
        }
        return variables.cache[arguments.name];
    }
}
```

### 3. Async Operations

Use async for long-running tasks:

```cfc
function analyzeLargeCodebase() {
    thread name="analysis-#createUUID()#" {
        // Long running analysis
    }
}
```

## Debugging Services

### Enable Debug Logging

```cfc
component {
    property name="log" inject="logbox:logger:{this}";
    
    function doSomething() {
        log.debug("Starting doSomething with args: #serializeJSON(arguments)#");
        // ... logic ...
        log.debug("Completed doSomething");
    }
}
```

### Service Inspection

```bash
# In CommandBox REPL
repl> getInstance("TemplateService@wheels-cli")
repl> getMetadata(getInstance("TemplateService@wheels-cli"))
```

## Future Enhancements

Planned service architecture improvements:

1. **Service Mesh**: Inter-service communication layer
2. **Service Discovery**: Dynamic service registration
3. **Circuit Breakers**: Fault tolerance patterns
4. **Service Metrics**: Performance monitoring
5. **API Gateway**: Unified service access

## See Also

- [Creating Custom Commands](creating-commands.md)
- [Template System](template-system.md)
- [Testing Guide](testing.md)
- [Contributing Guide](../CONTRIBUTING.md)