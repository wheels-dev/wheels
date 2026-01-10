# Configuration Overview

## Overview

The `/config` directory contains all configuration files for your Wheels application. In Wheels 3.0.0+, configuration was moved from `/app/config` to the root-level `/config` directory for better organization and clearer separation of concerns. These files control application behavior, database connections, routing, environment settings, and framework-wide defaults.

## File Structure and Purpose

### Core Configuration Files

```
/config/
├── app.cfm                    (Application.cfc this scope settings)
├── environment.cfm            (Current environment setting)
├── routes.cfm                 (URL routing configuration)
├── settings.cfm               (Global framework settings)
└── [environment]/
    ├── development/
    │   └── settings.cfm       (Development environment overrides)
    ├── testing/
    │   └── settings.cfm       (Testing environment overrides)
    ├── maintenance/
    │   └── settings.cfm       (Maintenance mode overrides)
    └── production/
        └── settings.cfm       (Production environment overrides)
```

### File Descriptions

#### `app.cfm`
Contains `this` scope variables for Application.cfc (application name, session settings, datasources, etc.)

#### `environment.cfm`
Sets the current environment (`development`, `testing`, `maintenance`, `production`)

#### `settings.cfm`
Global framework settings and defaults that apply across all environments

#### `routes.cfm`
URL routing configuration using the mapper DSL

#### `[environment]/settings.cfm`
Environment-specific overrides for global settings

## Configuration Loading Order

Wheels loads configuration in this order:

1. **Framework defaults** - Built-in Wheels defaults
2. **`/config/settings.cfm`** - Global application settings
3. **`/config/[environment]/settings.cfm`** - Environment-specific overrides
4. **URL parameters** - Temporary overrides via `?reload=environment`

Later settings override earlier ones.

## Accessing Configuration Values

### In Controllers/Models/Views

```cfm
// Get configuration values
environment = get("environment");
datasource = get("dataSourceName");
debugMode = get("showDebugInformation");

// Conditional logic based on environment
if (get("environment") == "development") {
    // Development-only code
}

// Check if setting exists
if (hasSettingValue("customSetting")) {
    customValue = get("customSetting");
}
```

### In Application Events

```cfm
// In /app/events/onapplicationstart.cfm
if (get("environment") == "production") {
    // Initialize production services
    initializeLogging();
    initializeMonitoring();
}
```

## Migration from Pre-3.0

### Breaking Change in Wheels 3.0.0

Configuration moved from `/app/config` to `/config` at root level.

### Automated Migration

```bash
# Use CommandBox recipe to migrate automatically
box recipe https://raw.githubusercontent.com/wheels-dev/wheels/develop/cli/recipes/config-migration.boxr
```

### Manual Migration Steps

1. Move `/app/config` to `/config`
2. Update `Application.cfc` path references
3. Update any hardcoded paths in application code
4. Update deployment scripts and documentation
5. Test that configuration loads correctly

## Debug Configuration

```cfm
// Dump all settings (development only)
<cfdump var="#application.wheels.settings#" label="Wheels Settings">

// Check specific setting
<cfoutput>Environment: #get("environment")#</cfoutput>
<cfoutput>Datasource: #get("dataSourceName")#</cfoutput>
<cfoutput>Debug Mode: #get("showDebugInformation")#</cfoutput>
```

## Configuration Categories

### Application Settings
- Application identity and session management
- Database connections and datasources
- Security settings and CSRF protection

### Framework Settings
- Caching configuration
- ORM and validation settings
- Function defaults and global overrides

### Routing Configuration
- URL patterns and route mappings
- Resource routing and custom routes
- Route helpers and parameters

### Environment Settings
- Environment-specific overrides
- Development vs production configurations
- Feature flags and conditional settings

## Best Practices

### 1. Use Environment Variables for Sensitive Data

```cfm
// Use environment variables for passwords
set(dataSourcePassword = GetEnvironmentValue("DB_PASSWORD"));
set(reloadPassword = GetEnvironmentValue("RELOAD_PASSWORD"));
```

### 2. Organize Settings Logically

```cfm
// Group related settings together
// Database settings
set(dataSourceName = "myapp");
set(dataSourceUserName = "user");
set(dataSourcePassword = "pass");

// Caching settings
set(cacheActions = true);
set(cachePages = true);
set(cachePartials = true);
```

### 3. Use Environment-Specific Overrides

```cfm
// Base configuration in /config/settings.cfm
set(showDebugInformation = false);

// Development override in /config/development/settings.cfm
set(showDebugInformation = true);
```

### 4. Document Custom Settings

```cfm
// Custom application settings with comments
set(enableAdvancedFeatures = true); // Enable beta features
set(maxFileUploadSize = 10); // Maximum file upload size in MB
set(apiRateLimit = 1000); // API requests per hour per user
```

## Common Configuration Patterns

### Multi-Environment Database Setup

```cfm
// In /config/settings.cfm (base config)
set(dataSourceName = "myapp");

// In /config/development/settings.cfm
set(dataSourceName = "myapp_dev");

// In /config/testing/settings.cfm
set(dataSourceName = "myapp_test");

// In /config/production/settings.cfm
set(dataSourceName = "myapp_prod");
```

### Feature Flags

```cfm
// In /config/settings.cfm
set(enableNewFeature = false);

// In /config/development/settings.cfm
set(enableNewFeature = true);

// In controllers/views
if (get("enableNewFeature")) {
    // Show new feature
}
```

### Performance Configuration

```cfm
// Development: No caching
set(cacheActions = false);
set(cachePages = false);

// Production: Full caching
set(cacheActions = true);
set(cachePages = true);
set(defaultCacheTime = 120);
```