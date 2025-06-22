# Wheels Framework Overview

## What is Wheels?

Wheels is a modern MVC framework for ColdFusion (CFML) that provides:
- **Convention over Configuration**: Sensible defaults with flexibility when needed
- **ActiveRecord ORM**: Intuitive database interaction patterns
- **RESTful Routing**: Clean URLs and resource-oriented architecture
- **Rapid Development**: Code generation and scaffolding tools
- **Testing Support**: Built-in testing framework integration
- **Database Agnostic**: Works with MySQL, PostgreSQL, SQL Server, H2, and more

## Core Philosophy

1. **Developer Happiness**: Make common tasks simple and complex tasks possible
2. **CFML Best Practices**: Encourage modern ColdFusion development patterns
3. **Community Driven**: Open source with active contributor involvement
4. **Backward Compatibility**: Smooth upgrade paths between versions

## Framework Roadmap

### Version 3.0 (Current Focus)
- **Monorepo Architecture**: Unified development experience
- **Modern CLI**: Enhanced code generation and project management
- **Configuration Improvements**: Moved config to root for better organization
- **Performance Optimizations**: Faster routing and model operations
- **Enhanced Testing**: Better test isolation and fixtures

### Future Directions (3.x)
- **Async/Await Support**: Native asynchronous operations
- **GraphQL Integration**: First-class GraphQL support
- **Enhanced Caching**: Smarter caching strategies
- **WebSocket Support**: Real-time application capabilities
- **Plugin Ecosystem**: Improved plugin discovery and management

### Long-term Vision
- **Cloud-Native Features**: Better support for containerization and microservices
- **AI-Assisted Development**: Integration with AI coding assistants
- **Performance Monitoring**: Built-in APM capabilities
- **Multi-tenant Support**: Native multi-tenancy patterns

## Architectural Decisions

### MVC Architecture
CFWheels follows the Model-View-Controller pattern with clear separation:
- **Models**: ActiveRecord pattern with rich associations and validations
- **Views**: Template-based with helper functions and partials
- **Controllers**: RESTful actions with filters and request handling

### Key Design Patterns

1. **Convention over Configuration**
   - Predictable file locations and naming
   - Automatic routing based on controller/action names
   - Database table names derived from model names

2. **ActiveRecord ORM**
   - Models inherit database structure
   - Rich query API with method chaining
   - Automatic SQL generation with security built-in

3. **Request Lifecycle**
   - Application.cfc initialization
   - Route matching and parameter extraction
   - Controller instantiation and action execution
   - Automatic view rendering or explicit response

### Framework Components

#### Core Components
- **Dispatch.cfc**: Request routing and dispatching
- **Controller.cfc**: Base controller functionality
- **Model.cfc**: ActiveRecord implementation
- **Mapper.cfc**: Route configuration DSL
- **Migrator.cfc**: Database schema management

#### CLI Components
- **CommandBox Module**: Modern CLI for code generation
- **Snippet System**: Customizable code templates
- **Database Commands**: Migration and database management
- **Server Commands**: Development server control

#### Supporting Components
- **Test Framework**: Integration with TestBox
- **Plugin System**: Extend framework functionality
- **View Helpers**: HTML generation and form helpers
- **Security Features**: CSRF protection, SQL injection prevention

## Getting Started

To start using Wheels:

1. **Install via CommandBox**: `box install wheels`
2. **Create a new application**: `wheels new myapp`
3. **Start the development server**: `cd myapp && server start`
4. **Generate your first model**: `wheels generate model User name:string email:string`

For detailed guides, see the [User Documentation](/docs/src/getting-started/).