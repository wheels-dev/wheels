# Wheels CLI Documentation

The Wheels CLI is a CommandBox module that provides command-line tools for Wheels framework applications. This documentation covers all available commands and their usage.

## Table of Contents

- [Installation](#installation)
- [Getting Started](#getting-started)
- [Command Reference](#command-reference)
  - [Application Management](#application-management)
  - [Development Tools](#development-tools)
  - [Database Commands](#database-commands)
  - [Testing](#testing)
  - [Configuration](#configuration)
  - [Frontend Integration](#frontend-integration)
  - [API Development](#api-development)
  - [DevOps Tools](#devops-tools)
  - [Performance Tools](#performance-tools)
  - [Dependency Management](#dependency-management)

## Installation

Install the Wheels CLI as a CommandBox module:

```bash
box install wheels-cli
```

## Getting Started

To create a new Wheels application:

```bash
wheels init myApp
```

This will create a new Wheels application in the "myApp" directory.

## Command Reference

### Application Management

#### Init

Creates a new Wheels application.

```bash
wheels init [name] [path] [reload] [version] [createFolders]
```

**Parameters:**
- `name`: Name of the application
- `path`: Path for the new application
- `reload`: Force a reload of the application
- `version`: Wheels version to use
- `createFolders`: Create standard folders structure

#### Reload

Reloads the Wheels application.

```bash
wheels reload
```

#### Info

Displays information about the Wheels application.

```bash
wheels info
```

#### Watch

Monitors file changes in the application and automatically reloads the application during development.

```bash
wheels watch [--includeDirs=controllers,models,views,config] [--excludeFiles=*.txt,*.log] [--interval=1]
```

**Parameters:**
- `includeDirs`: Comma-delimited list of directories to watch (defaults to controllers,models,views,config)
- `excludeFiles`: Comma-delimited list of file patterns to ignore
- `interval`: Interval in seconds to check for changes (default 1)

### Development Tools

#### Generate Controller

Generates a controller.

```bash
wheels generate controller [name] [actions]
```

**Parameters:**
- `name`: Name of the controller
- `actions`: Comma-delimited list of actions to generate

#### Generate Model

Generates a model.

```bash
wheels generate model [name] [properties]
```

**Parameters:**
- `name`: Name of the model
- `properties`: Comma-delimited list of properties to generate

#### Generate View

Generates a view.

```bash
wheels generate view [controller] [action]
```

**Parameters:**
- `controller`: Name of the controller
- `action`: Name of the action

#### Generate Property

Generates a property for a model.

```bash
wheels generate property [name] [type] [default] [null] [limit] [model]
```

**Parameters:**
- `name`: Name of the property
- `type`: Data type of the property
- `default`: Default value for the property
- `null`: Allow NULL values (true/false)
- `limit`: Character limit for the property
- `model`: Model to add the property to

#### Generate API Resource

Creates RESTful API controller and supporting files.

```bash
wheels generate api-resource [name] [--model=false] [--docs=false] [--auth=false]
```

**Parameters:**
- `name`: Name of the API resource (singular or plural)
- `model`: Generate associated model (true/false)
- `docs`: Generate API documentation template (true/false)
- `auth`: Include authentication checks (true/false)

#### Generate Frontend

Scaffold and integrate modern frontend frameworks with Wheels.

```bash
wheels generate frontend --framework=[framework] [--path=app/assets/frontend] [--api=false]
```

**Parameters:**
- `framework`: Frontend framework to use (react, vue, alpine)
- `path`: Directory to install frontend (defaults to /app/assets/frontend)
- `api`: Generate API endpoint for frontend (true/false)

#### Scaffold

Generates complete CRUD functionality for a resource.

```bash
wheels scaffold [name] [properties]
```

**Parameters:**
- `name`: Name of the resource
- `properties`: Comma-delimited list of properties to generate

### Database Commands

#### DBMigrate Create

Creates a database migration.

```bash
wheels dbmigrate create [type] [name] [column] [columnType] [default] [null] [limit] [precision] [scale]
```

**Parameters:**
- `type`: Type of migration (table, column, etc.)
- `name`: Name of the migration
- Other parameters vary by migration type

#### DBMigrate Up

Runs pending migrations.

```bash
wheels dbmigrate up
```

#### DBMigrate Down

Reverts the last migration.

```bash
wheels dbmigrate down [all]
```

**Parameters:**
- `all`: Revert all migrations (true/false)

#### DBMigrate Reset

Resets the database by reverting and reapplying all migrations.

```bash
wheels dbmigrate reset
```

#### DBMigrate Latest

Migrates the database to the latest version.

```bash
wheels dbmigrate latest
```

#### DBMigrate Info

Displays migration information.

```bash
wheels dbmigrate info
```

#### DB Seed

Generate and populate test data.

```bash
wheels db:seed [--models=] [--count=5] [--environment=] [--dataFile=]
```

**Parameters:**
- `models`: Comma-delimited list of models to seed (defaults to all)
- `count`: Number of records to generate per model
- `environment`: Environment to seed (defaults to current)
- `dataFile`: Path to JSON file containing seed data

#### DB Schema

Visualize the current database schema.

```bash
wheels db:schema [--format=text] [--output=] [--tables=]
```

**Parameters:**
- `format`: Output format (text, json, or sql)
- `output`: File to write schema to (if not specified, outputs to console)
- `tables`: Comma-delimited list of tables to include (defaults to all)

### Testing

#### Test

Runs tests.

```bash
wheels test [type] [servername] [reload] [debug]
```

**Parameters:**
- `type`: Type of tests to run (core, app, plugin)
- `servername`: Name of server to reload
- `reload`: Force a reload of the application
- `debug`: Show debug information

#### Test Coverage

Generate code coverage reports for tests.

```bash
wheels test:coverage [type] [--servername=] [--reload=false] [--debug=false] [--outputDir=tests/coverageReport]
```

**Parameters:**
- `type`: Type of tests to run (app, core, or plugin)
- `servername`: Name of server to reload (defaults to current)
- `reload`: Force a reload of wheels
- `debug`: Show debug info
- `outputDir`: Directory to output the coverage report

#### Test Debug

Run tests with interactive debugging capabilities.

```bash
wheels test:debug [type] [--spec=] [--servername=] [--reload=false] [--breakOnFailure=true] [--outputLevel=3]
```

**Parameters:**
- `type`: Type of tests to run (app, core, or plugin)
- `spec`: Specific test spec to run (e.g., models.user)
- `servername`: Name of server to reload (defaults to current)
- `reload`: Force a reload of wheels
- `breakOnFailure`: Stop test execution on first failure
- `outputLevel`: Output verbosity (1=minimal, 2=normal, 3=verbose)

### Configuration

#### Config List

List all configuration settings.

```bash
wheels config:list [--environment=] [--filter=] [--showSensitive=false]
```

**Parameters:**
- `environment`: Environment to display settings for (development, testing, production)
- `filter`: Filter results by this string
- `showSensitive`: Show sensitive information (passwords, keys, etc.)

#### Config Set

Set configuration values.

```bash
wheels config:set [setting] [--environment=development] [--encrypt=false]
```

**Parameters:**
- `setting`: Key=Value pair for the setting to update
- `environment`: Environment to apply settings to (development, testing, production, all)
- `encrypt`: Encrypt sensitive values

#### Config Environment

Manage environment-specific settings.

```bash
wheels config:env [action] [--source=] [--target=]
```

**Parameters:**
- `action`: Action to perform (list, create, copy)
- `source`: Source environment for copy action
- `target`: Target environment for create or copy action

### Frontend Integration

The frontend integration commands are covered in the [Generate Frontend](#generate-frontend) section.

### API Development

The API development commands are covered in the [Generate API Resource](#generate-api-resource) section.

### DevOps Tools

#### CI Init

Generate CI/CD configuration files for popular platforms.

```bash
wheels ci:init [platform] [--includeDeployment=true] [--dockerEnabled=true]
```

**Parameters:**
- `platform`: CI/CD platform to generate configuration for (github, gitlab, jenkins)
- `includeDeployment`: Include deployment configuration
- `dockerEnabled`: Enable Docker-based workflows

#### Docker Init

Initialize Docker configuration for development.

```bash
wheels docker:init [--db=mysql] [--dbVersion=] [--cfengine=lucee] [--cfVersion=5.3]
```

**Parameters:**
- `db`: Database to use (h2, mysql, postgres, mssql)
- `dbVersion`: Database version to use
- `cfengine`: ColdFusion engine to use (lucee, adobe)
- `cfVersion`: ColdFusion engine version

#### Docker Deploy

Create production-ready Docker configurations.

```bash
wheels docker:deploy [--environment=production] [--db=mysql] [--cfengine=lucee] [--optimize=true]
```

**Parameters:**
- `environment`: Deployment environment (production, staging)
- `db`: Database to use (h2, mysql, postgres, mssql)
- `cfengine`: ColdFusion engine to use (lucee, adobe)
- `optimize`: Enable production optimizations

### Performance Tools

#### Analyze

Identify performance bottlenecks in applications.

```bash
wheels analyze [--target=all] [--duration=60] [--report=true] [--threshold=5]
```

**Parameters:**
- `target`: Analysis target (controller, view, query, memory, or all)
- `duration`: Duration to run analysis in seconds
- `report`: Generate HTML report
- `threshold`: Threshold for reporting issues (1-10, where 10 is most severe)

### Dependency Management

#### Dependencies

Manage Wheels-specific dependencies and plugins.

```bash
wheels deps [action] [name] [version]
```

**Parameters:**
- `action`: Action to perform (list, install, update, remove, report)
- `name`: Name of the plugin or dependency (required for install, update, remove)
- `version`: Version to install (optional, for install action)