# Wheels CLI

The official Command Line Interface for the CFWheels framework.

## Installation

Install the Wheels CLI module via CommandBox:

```bash
box install wheels-cli
```

## Features

- **Code Generation** - Generate applications, controllers, models, views, and complete scaffolds
- **Database Migrations** - Version control your database schema with migrations
- **Testing** - Run tests with coverage reports and debugging capabilities
- **Development Tools** - File watching, reloading, and environment management
- **Deployment** - Docker integration and CI/CD configuration

## Quick Start

Create a new Wheels application:

```bash
wheels new myapp
```

Generate a complete resource:

```bash
wheels scaffold Product name:string price:decimal description:text
```

Run database migrations:

```bash
wheels dbmigrate latest
```

## Documentation

Full documentation is available at:
https://guides.cfwheels.org/docs/command-line-tools/cli-commands

## Requirements

- CommandBox 5.0+
- CFWheels 3.0+

## License

Apache License 2.0