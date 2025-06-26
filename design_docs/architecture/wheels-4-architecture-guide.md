# Wheels 4.0 Architecture Guide - Modular Vision

## Overview

This document outlines the vision for Wheels 4.0, focusing on a fully modular architecture that provides maximum flexibility while maintaining the simplicity that makes Wheels appealing. This is a living document that will evolve as we make architectural decisions throughout the 3.x lifecycle.

**Target Release**: Q1 2026 (following annual release cycle)

## Core Vision

Wheels 4.0 transforms from a monolithic framework into a modular ecosystem where developers can:
- Choose only the components they need
- Replace any component with alternatives
- Build microservices or full applications
- Scale from prototypes to enterprise systems

## Modular Architecture

### Module Ecosystem

```
wheels-ecosystem/
├── core-modules/                    # Essential framework modules
│   ├── wheels-foundation/          # Base classes, interfaces, DI container
│   ├── wheels-orm/                 # Database abstraction and models
│   ├── wheels-routing/             # Request routing and URL generation
│   ├── wheels-controller/          # Controller layer and middleware
│   ├── wheels-view/                # Templating and view rendering
│   ├── wheels-validation/          # Data validation framework
│   └── wheels-events/              # Event dispatching system
├── feature-modules/                 # Optional functionality
│   ├── wheels-auth/                # Authentication & authorization
│   ├── wheels-cache/               # Caching strategies
│   ├── wheels-queue/               # Job queues and workers
│   ├── wheels-mail/                # Email sending
│   ├── wheels-storage/             # File storage abstraction
│   ├── wheels-migrations/          # Database migrations
│   ├── wheels-testing/             # Testing utilities
│   ├── wheels-api/                 # API-specific tools
│   ├── wheels-websockets/          # Real-time features
│   └── wheels-scheduler/           # Task scheduling
├── adapter-modules/                 # Integration layers
│   ├── wheels-lucee-adapter/       # Lucee-specific optimizations
│   ├── wheels-adobe-adapter/       # Adobe CF compatibility
│   ├── wheels-boxlang-adapter/     # BoxLang native features
│   └── wheels-legacy-adapter/      # Backward compatibility
└── meta-packages/                   # Bundled configurations
    ├── wheels-complete/            # Everything included
    ├── wheels-api/                 # API development bundle
    ├── wheels-minimal/             # Core only
    └── wheels-enterprise/          # Enterprise features
```

### Module Independence

Each module is completely self-contained:

```json
// wheels-orm/box.json
{
    "name": "wheels-orm",
    "version": "4.0.0",
    "type": "wheels-module",
    "provides": ["wheels.orm", "wheels.model"],
    "requires": ["wheels.foundation"],
    "replaces": ["legacy-wheels-model"],
    "suggests": ["wheels-validation", "wheels-cache"],
    "autoload": {
        "psr-4": {
            "Wheels\\ORM\\": "src/"
        }
    }
}
```

## Key Architectural Principles

### 1. Interface-Driven Design

All modules communicate through well-defined interfaces:

```javascript
// wheels-foundation/src/contracts/ORMInterface.cfc
interface {
    public any function find(required string id);
    public array function findAll(struct criteria = {});
    public boolean function save(required any entity);
    public boolean function delete(required any entity);
    public any function new(struct properties = {});
}
```

### 2. Dependency Injection Container

Central to the modular architecture:

```javascript
// Application.cfc
component {
    function onApplicationStart() {
        // Create DI container
        application.wheels = new wheels.foundation.Container();
        
        // Register modules
        application.wheels.register("orm", "wheels.orm.ORMService");
        application.wheels.register("cache", "custom.RedisCacheService"); // Custom implementation
        
        // Auto-wire dependencies
        application.wheels.autowire();
    }
}
```

### 3. Event-Driven Architecture

Loose coupling through events:

```javascript
// Any module can dispatch events
application.wheels.dispatch("user.created", {user: newUser});

// Other modules can listen
application.wheels.listen("user.created", function(event) {
    // Send welcome email
    application.wheels.get("mail").send({
        to: event.data.user.email,
        template: "welcome"
    });
});
```

### 4. Middleware Pipeline

Composable request handling:

```javascript
// config/middleware.cfc
application.wheels.middleware([
    "wheels.routing.RoutingMiddleware",
    "wheels.auth.AuthenticationMiddleware",
    "app.middleware.RateLimitMiddleware", // Custom middleware
    "wheels.controller.ControllerMiddleware"
]);
```

## Module Categories

### Core Modules (Required)

#### wheels-foundation
- Dependency injection container
- Base classes and interfaces
- Configuration management
- Module loader
- Event dispatcher

#### wheels-routing
- Route definition and matching
- URL generation
- Route caching
- RESTful routing helpers

### Feature Modules (Optional)

#### wheels-orm
- Active Record pattern implementation
- Query builder
- Relationship management
- Database adapters

#### wheels-auth
- Authentication strategies
- Authorization policies
- Session management
- OAuth/JWT support

#### wheels-api
- API versioning
- Rate limiting
- Response transformers
- OpenAPI documentation

### Adapter Modules

Enable framework features on different CFML engines:

```javascript
// wheels-boxlang-adapter uses native features
component implements="CacheAdapter" {
    function get(key) {
        return cache.get(arguments.key); // Native BoxLang cache
    }
}

// wheels-lucee-adapter uses Lucee extensions
component implements="CacheAdapter" {
    function get(key) {
        return cacheGet(arguments.key); // Lucee's cacheGet
    }
}
```

## Development Experience

### 1. Module Discovery

```bash
# Search for modules
wheels module:search auth

# View module details
wheels module:info wheels-auth

# Install module
wheels module:install wheels-auth

# Create custom module
wheels module:create my-custom-auth
```

### 2. Configuration

Modules can be configured in a central location:

```javascript
// config/modules.cfc
modules = {
    "wheels-orm": {
        defaultDatasource: "main",
        enableQueryLogging: true
    },
    "wheels-cache": {
        defaultDriver: "redis",
        ttl: 3600
    },
    "wheels-auth": {
        model: "User",
        fields: {
            identity: "email",
            credential: "password"
        }
    }
};
```

### 3. Module Replacement

Easy to swap implementations:

```json
// box.json
{
    "dependencies": {
        "wheels-foundation": "^4.0",
        "wheels-routing": "^4.0",
        "my-custom-orm": "^1.0", // Replaces wheels-orm
        "wheels-view": "^4.0"
    }
}
```

## Performance Optimizations

### 1. Lazy Loading

Modules are loaded only when needed:

```javascript
// Only loads ORM when model() is called
function getUser(id) {
    return model("User").findByKey(arguments.id);
}
```

### 2. Compiled Module Graph

Build step that optimizes module loading:

```bash
wheels build --production

# Creates optimized module graph
# Removes unused modules
# Inline small modules
# Pre-compiles configurations
```

### 3. Module Caching

```javascript
// Aggressive caching in production
if (application.wheels.isProduction()) {
    application.wheels.cache.modules = true;
    application.wheels.cache.ttl = 86400; // 24 hours
}
```

## Migration Strategy

### Compatibility Layer

Wheels 4.0 includes a compatibility module:

```javascript
// wheels-legacy-adapter provides old API
component extends="Model" {
    // Works in 4.0 with adapter
}

// Internally maps to new API
component extends="wheels.orm.Entity" {
    // New 4.0 approach
}
```

### Progressive Migration

Applications can migrate gradually:

```javascript
// Stage 1: Use compatibility layer (4.0)
application.wheels.modules.add("wheels-legacy-adapter");

// Stage 2: Update critical paths (4.1)
component extends="wheels.orm.Entity" {
    // New API for performance-critical models
}

// Stage 3: Complete migration (4.2)
// Remove legacy adapter
```

## Use Cases

### 1. Microservice

```json
{
    "dependencies": {
        "wheels-foundation": "^4.0",
        "wheels-routing": "^4.0",
        "wheels-orm": "^4.0"
    }
}
```

### 2. API-Only Application

```json
{
    "dependencies": {
        "wheels-foundation": "^4.0",
        "wheels-routing": "^4.0",
        "wheels-controller": "^4.0",
        "wheels-orm": "^4.0",
        "wheels-api": "^4.0"
        // No view module needed
    }
}
```

### 3. Static Site Generator

```json
{
    "dependencies": {
        "wheels-foundation": "^4.0",
        "wheels-view": "^4.0",
        "wheels-routing": "^4.0"
        // No ORM or controller needed
    }
}
```

### 4. Enterprise Application

```json
{
    "dependencies": {
        "wheels-enterprise": "^4.0" // Meta-package including:
        // - All core modules
        // - Authentication & authorization
        // - Caching with Redis
        // - Queue system
        // - Monitoring
        // - API tools
    }
}
```

## Testing Strategy

### Module Testing

Each module has comprehensive tests:

```javascript
// wheels-orm/tests/ORMTest.cfc
component extends="wheels.testing.ModuleTestCase" {
    
    function beforeAll() {
        // Test in isolation
        this.loadModule("wheels-orm", {
            mockDependencies: true
        });
    }
    
    function testFindMethod() {
        var mockDB = this.mock("wheels.foundation.Database");
        this.module.setDatabase(mockDB);
        
        var result = this.module.find("123");
        
        expect(mockDB).toHaveBeenCalledWith("find", {id: "123"});
    }
}
```

### Integration Testing

Test module combinations:

```javascript
// tests/integration/ORMWithCacheTest.cfc
component extends="wheels.testing.IntegrationTestCase" {
    
    function beforeAll() {
        this.loadModules([
            "wheels-orm",
            "wheels-cache"
        ]);
    }
    
    function testCachedQueries() {
        var user = model("User").findByKey(1, cache: true);
        var cachedUser = model("User").findByKey(1, cache: true);
        
        expect(this.getQueryCount()).toBe(1); // Only one query
    }
}
```

## Documentation

### Module Documentation

Each module includes:
- README.md - Overview and quick start
- API.md - Complete API reference
- GUIDE.md - Usage guide with examples
- CHANGELOG.md - Version history

### Central Documentation

Wheels 4.0 documentation includes:
- Module development guide
- Architecture overview
- Migration guides
- Module compatibility matrix

## Community Modules

### Module Registry

Central registry for community modules:

```bash
# Browse community modules
wheels registry:search authentication

# Submit module
wheels registry:submit my-wheels-module

# Install community module
wheels install someuser/custom-auth-module
```

### Module Standards

Requirements for community modules:
- Follow naming convention: wheels-[feature]
- Include comprehensive tests
- Provide documentation
- Declare compatibility
- Semantic versioning

## Future Considerations

### Progressive Web App Support
- wheels-pwa module for offline support
- Service worker integration
- Push notifications

### GraphQL Integration
- wheels-graphql module
- Schema generation from models
- Subscription support

### Serverless Deployment
- wheels-serverless adapter
- Function-based routing
- Cold start optimization

### AI/ML Integration
- wheels-ai module
- Model serving
- Training pipeline integration

## Success Metrics

### Technical Metrics
- Module load time < 10ms
- Zero-dependency modules possible
- 90%+ test coverage per module
- Memory footprint reduction of 40%

### Adoption Metrics
- 50+ community modules in first year
- 80% of apps use modular approach
- Clear migration path for all users

## Timeline

While detailed implementation steps will be determined as we progress, the high-level timeline:

- **2025 Q1-Q2**: Internal refactoring and interface design
- **2025 Q3-Q4**: Alpha releases and community feedback
- **2026 Q1**: Wheels 4.0 Release

## Conclusion

Wheels 4.0 represents a fundamental shift in architecture while maintaining the developer-friendly experience that makes Wheels special. By embracing modularity, we enable:

- Greater flexibility for developers
- Better performance through selective loading
- Easier maintenance and testing
- A thriving ecosystem of community modules
- Future-proof architecture for emerging technologies

This document will evolve as we make decisions and gather feedback throughout the Wheels 3.x lifecycle.