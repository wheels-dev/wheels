# Wheels CLI (Next Generation)

A modern, powerful CommandBox module that provides comprehensive CLI tooling for the CFWheels framework.

## 🚀 Features

- ✅ **Application Scaffolding** - Create new Wheels apps with intelligent defaults
- ✅ **Smart Code Generation** - Generate models, controllers, views with best practices
- ✅ **SQLite Zero-Config** - Start developing immediately without database setup
- ✅ **Advanced Templates** - Customizable templates with conditionals and loops
- ✅ **Database Management** - Complete migration workflow and multi-database support
- ✅ **Tab Completion** - Context-aware command completion for productivity
- ✅ **Multi-Format Output** - Support for text, JSON, XML, and table formats
- ✅ **Progress Indicators** - Visual feedback with spinners and progress bars
- ✅ **Environment Support** - Configuration management across environments
- ✅ **Comprehensive Testing** - Built with 66+ tests ensuring reliability

## 📦 Installation

### From ForgeBox (Coming Soon)
```bash
box install wheels-cli-next
```

### Development Installation
```bash
# Clone and link for local development
cd cli-new
box package link

# Reload CommandBox to register the module
box reload

# Verify installation
wheels version
```

## 🎯 Quick Start

```bash
# Create a new app with SQLite database
wheels create app myblog

# Navigate to your app
cd myblog

# Generate a complete scaffold
wheels create scaffold Post title:string content:text published:boolean

# Run migrations
wheels db migrate

# Start the development server
wheels server start
```

## 📖 Command Reference

### Application Commands

#### `wheels create app <name> [options]`
Create a new CFWheels application with complete project structure.

**Options:**
- `--template=<default|api|spa>` - Application template (default: default)
- `--database=<sqlite|mysql|postgresql|sqlserver|h2>` - Database type (default: sqlite)
- `--installDependencies=<true|false>` - Install dependencies (default: true)
- `--setupDatabase=<true|false>` - Setup database (default: true)
- `--directory=<path>` - Target directory (default: current)
- `--force` - Overwrite existing directory

**Example:**
```bash
wheels create app blog --template=api --database=postgresql
```

### Generator Commands

#### `wheels create model <name> [options]`
Generate a model with optional attributes and associations.

**Options:**
- `--attributes=<list>` - Comma-separated attributes (name:type)
- `--belongsTo=<list>` - BelongsTo associations
- `--hasMany=<list>` - HasMany associations
- `--hasOne=<list>` - HasOne associations
- `--validatesPresence=<list>` - Required fields
- `--validatesUniqueness=<list>` - Unique fields
- `--timestamps` - Add createdAt/updatedAt
- `--softDeletes` - Add soft delete support
- `--migration` - Generate migration file
- `--factory` - Generate test factory
- `--force` - Overwrite existing file

**Example:**
```bash
wheels create model User \
  --attributes="firstName:string,lastName:string,email:string,active:boolean" \
  --validatesPresence="firstName,lastName,email" \
  --validatesUniqueness="email" \
  --hasMany="posts,comments" \
  --timestamps \
  --migration
```

#### `wheels create controller <name> [options]`
Generate a controller with actions and optional views.

**Options:**
- `--actions=<list>` - Comma-separated action names
- `--resource` - Generate RESTful resource actions
- `--api` - Generate API controller (no new/edit)
- `--parent=<name>` - Parent controller to extend
- `--layout=<name>` - Layout to use
- `--beforeFilter=<name>` - Before filter to apply
- `--withViews` - Generate corresponding views
- `--force` - Overwrite existing file

**Example:**
```bash
wheels create controller api/v1/Users --api --beforeFilter=authenticate
```

#### `wheels create scaffold <name> [options]`
Generate complete MVC scaffold with model, controller, views, and migration.

**Options:**
- `--attributes=<list>` - Model attributes
- `--layout=<name>` - Layout for views
- All model and controller options

**Example:**
```bash
wheels create scaffold Product \
  --attributes="name:string,price:decimal,inStock:boolean,category:string"
```

### Database Commands

#### `wheels db create [options]`
Create the database for current environment.

#### `wheels db drop [options]`
Drop the database (with confirmation).

#### `wheels db migrate [options]`
Run pending migrations.

**Options:**
- `--target=<version>` - Migrate to specific version
- `--step=<number>` - Number of migrations to run
- `--dry-run` - Show SQL without executing

#### `wheels db rollback [options]`
Rollback migrations.

**Options:**
- `--steps=<number>` - Number of migrations to rollback (default: 1)

#### `wheels db status [options]`
Show migration status with pending and executed migrations.

#### `wheels db seed [options]`
Run database seeders.

#### `wheels db setup [options]`
Complete database setup (create + migrate + seed).

#### `wheels db reset [options]`
Reset database (drop + create + migrate + seed).

**Options:**
- `--force` - Skip confirmation

#### `wheels db create migration <name> [options]`
Generate a migration file.

**Options:**
- `--create=<table>` - Create table migration
- `--alter=<table>` - Alter table migration
- `--drop=<table>` - Drop table migration

**Smart naming examples:**
- `CreateUsers` - Creates users table
- `AddEmailToUsers` - Adds email column
- `RemovePasswordFromUsers` - Removes password column
- `AddIndexToUsersEmail` - Adds index on email

### Additional Commands

#### `wheels routes [options]`
Display application routes.

**Options:**
- `--format=<text|json|table>` - Output format
- `--verbose` - Show additional details

#### `wheels console`
Launch interactive REPL console.

#### `wheels server <start|stop|restart> [options]`
Manage development server.

**Options:**
- `--port=<number>` - Server port (default: 8080)
- `--host=<host>` - Server host (default: localhost)

#### `wheels templates <list|copy> [options]`
Manage code generation templates.

## ⚙️ Configuration

### Project Configuration (.wheelscli.json)
Create a `.wheelscli.json` file in your project root:

```json
{
  "database": "postgresql",
  "template": "api",
  "author": "Your Name",
  "defaults": {
    "modelTimestamps": true,
    "controllerLayout": "main"
  }
}
```

### Environment Variables
- `WHEELS_DEFAULT_DB` - Default database type
- `WHEELS_DEFAULT_TEMPLATE` - Default app template
- `WHEELS_CLI_VERBOSE` - Enable verbose output

## 🧩 Architecture

### Modern CommandBox Module Structure
- **Singleton Services** - Efficient service management with WireBox
- **Interceptors** - Command lifecycle hooks for extensibility
- **Base Command Pattern** - Consistent command structure and utilities
- **Mock Infrastructure** - Comprehensive testing without external dependencies

### Key Components
- **ModuleConfig.cfc** - Central module configuration
- **BaseCommand.cfc** - Base class with utilities for all commands
- **Services** - Business logic separated into testable services
- **Templates** - Customizable code generation templates
- **Tab Completion** - Context-aware command completion

## 🧪 Testing

The CLI includes a comprehensive test suite with 66+ tests covering all major functionality.

### Running Tests
```bash
# Run all tests
box testbox run

# Run specific test category
box testbox run --directory=tests.specs.commands

# Watch mode for TDD
box testbox watch

# Generate coverage report
box testbox run --coverage --coverageReporter=html
```

### Test Categories
- **Unit Tests** - Commands and services
- **Integration Tests** - Complete workflows
- **Mock Infrastructure** - Isolated testing

## Template System

The CLI uses CommandBox's proven @VARIABLE@ placeholder system for templates:

- **CFML-Safe** - No conflicts with # characters in CSS or HTML
- **Customizable** - Copy templates to `config/templates/` to customize
- **Extensible** - Add your own variables and logic

### Template Variables

**Model Templates:**
- `@MODEL_NAME@` - Model name (e.g., User)
- `@TABLE_NAME@` - Table name (e.g., users)
- `@PROPERTY_DEFINITIONS@` - Property definitions
- `@VALIDATIONS@` - Validation rules
- `@ASSOCIATIONS@` - Model associations

**Controller Templates:**
- `@CONTROLLER_NAME@` - Controller name
- `@MODEL_NAME@` - Associated model
- `@SINGULAR_LOWER_NAME@` - Singular lowercase
- `@PLURAL_LOWER_NAME@` - Plural lowercase
- `@CONTROLLER_ACTIONS@` - Action methods

## 🛠️ Development

### Directory Structure
```
cli-new/
├── ModuleConfig.cfc         # CommandBox module configuration
├── box.json                 # Package descriptor
├── commands/                # CLI commands
│   └── wheels/
│       ├── create/          # Creation commands (app, model, controller, etc.)
│       ├── db/              # Database commands
│       ├── server/          # Server management
│       ├── templates/       # Template management
│       └── BaseCommand.cfc  # Base command with utilities
├── models/                  # Service classes (WireBox singletons)
│   ├── ConfigService.cfc
│   ├── DatabaseService.cfc
│   ├── MigrationService.cfc
│   ├── ProjectService.cfc
│   ├── TemplateService.cfc
│   ├── FormatterService.cfc
│   ├── WheelsService.cfc
│   └── TabCompletionService.cfc
├── templates/               # Built-in code generation templates
│   ├── model/              # Model templates (default, api, test, validations)
│   ├── controller/         # Controller templates (default, resource, api)
│   ├── view/               # View templates (index, show, new, edit, form)
│   └── migration/          # Migration templates
├── interceptors/           # CommandBox interceptors
│   └── CLIInterceptor.cfc
└── tests/                  # Comprehensive test suite
    ├── specs/              # Test specifications
    ├── mocks/              # Mock objects
    └── helpers/            # Test utilities
```

### Setting Up Development Environment
```bash
# Clone the repository
git clone https://github.com/cfwheels/cfwheels.git
cd cfwheels/cli-new

# Install dependencies
box install

# Link for local development
box package link

# Reload CommandBox
box reload

# Run tests
box testbox run
```

### Adding New Commands

1. Create command file in appropriate directory:
```cfc
// commands/wheels/mycommand.cfc
component extends="commands.wheels.BaseCommand" {
    
    /**
     * @name.hint Parameter description
     * @name.optionsUDF completeModelNames
     */
    function run(required string name) {
        return runCommand(function() {
            // Command logic here
        }, argumentCollection=arguments);
    }
}
```

2. Add tab completion function to TabCompletionService if needed
3. Write tests in `tests/specs/commands/`
4. Update documentation

### Adding New Services

1. Create service in `models/` directory:
```cfc
component singleton accessors=true {
    
    function init() {
        return this;
    }
    
    // Service methods
}
```

2. Register in ModuleConfig.cfc WireBox mappings
3. Write tests in `tests/specs/services/`

### Testing Guidelines

- Write tests for all new commands and services
- Use BaseTestCase for command testing
- Mock external dependencies
- Aim for high code coverage
- Run tests before submitting PRs

### Release Process

1. Update version in box.json
2. Update CHANGELOG.md
3. Run full test suite
4. Build package: `box package`
5. Publish to ForgeBox: `box publish`

## 📋 Requirements

- **CommandBox** 5.0 or higher
- **CFWheels** 3.0+ project structure (vendor/wheels/)
- **CFML Engine**: 
  - Lucee 5.3.0+
  - Adobe ColdFusion 2018+
- **Operating System**: Windows, macOS, or Linux

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### How to Contribute
1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

### Code Style
- Follow existing patterns
- Use meaningful variable names
- Add JSDoc comments for all public methods
- Keep methods focused and small

## 📝 License

Apache License 2.0 - see [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- CommandBox team for the excellent CLI framework
- CFWheels community for feedback and testing
- Contributors who helped shape this tool

## 📞 Support

- **Documentation**: https://guides.cfwheels.org/cli
- **Issues**: https://github.com/cfwheels/cfwheels/issues
- **Community**: https://community.cfwheels.org
- **Discord**: https://discord.gg/cfwheels