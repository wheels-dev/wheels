# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with configuration files in a Wheels application.

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

**`app.cfm`** - Contains `this` scope variables for Application.cfc (application name, session settings, datasources, etc.)

**`environment.cfm`** - Sets the current environment (`development`, `testing`, `maintenance`, `production`)

**`settings.cfm`** - Global framework settings and defaults that apply across all environments

**`routes.cfm`** - URL routing configuration using the mapper DSL

**`[environment]/settings.cfm`** - Environment-specific overrides for global settings

## Application Configuration (`app.cfm`)

Configure Application.cfc `this` scope variables:

```cfm
<cfscript>
    /*
        Use this file to set variables for the Application.cfc's "this" scope.
    */
    
    // Application identity
    this.name = "MyWheelsApp";
    this.applicationTimeout = CreateTimeSpan(1,0,0,0);
    
    // Session management
    this.sessionManagement = true;
    this.sessionTimeout = CreateTimeSpan(0,0,30,0);
    
    // Security settings
    this.secureJSON = true;
    this.secureJSONPrefix = "//";
    
    // Custom tag paths
    this.customTagPaths = ListAppend(
        this.customTagPaths,
        ExpandPath("../customtags")
    );
    
    // Datasource configuration
    this.datasources['myapp'] = {
        class: 'com.mysql.cj.jdbc.Driver',
        connectionString: 'jdbc:mysql://localhost:3306/myapp?useSSL=false',
        username: 'dbuser',
        password: 'dbpass'
    };
    
    // H2 Database example (for development)
    this.datasources['myapp-dev'] = {
        class: 'org.h2.Driver',
        connectionString: 'jdbc:h2:file:./db/h2/myapp-dev;MODE=MySQL',
        username: 'sa'
    };
</cfscript>
```

### Common Application Settings
- **Application identity**: `this.name`, `this.applicationTimeout`
- **Session management**: `this.sessionManagement`, `this.sessionTimeout` 
- **Client management**: `this.clientManagement`, `this.clientStorage`
- **Security**: `this.secureJSON`, `this.scriptProtect`, `this.sessionRotate`
- **Datasources**: `this.datasources` struct
- **Mappings**: `this.mappings` struct
- **Custom paths**: `this.customTagPaths`, `this.componentPaths`

## Environment Configuration (`environment.cfm`)

Sets the current environment mode:

```cfm
<cfscript>
// Use this file to set the current environment for your application.
// You can set it to "development", "testing", "maintenance" or "production".
// Don't forget to issue a reload request (e.g. reload=true) after making changes.

set(environment = "development");
</cfscript>
```

### Environment Modes

**Development**
- Shows detailed errors on screen
- No error email notifications  
- Basic caching (config, schema, routes, images)
- Most convenient for active development

**Production**
- Full caching enabled (actions, pages, queries, partials)
- Custom error pages shown
- Error email notifications enabled
- Fastest performance mode

**Testing**  
- Same caching as production
- Error handling like development
- Good for testing at production speed with debugging

**Maintenance**
- Shows maintenance page to users
- Exceptions for specific IPs/user agents
- Useful for deploying updates

### Environment Switching

**Permanent switch**: Edit `/config/environment.cfm` then reload
```bash
# URL reload after file change
http://myapp.com/?reload=true
```

**Temporary switch via URL**:
```bash
# Switch to testing mode temporarily
http://myapp.com/?reload=testing

# With password protection
http://myapp.com/?reload=production&password=mypass
```

**Disable URL switching** (recommended for production):
```cfm
set(allowEnvironmentSwitchViaUrl = false);
```

## Framework Settings (`settings.cfm`)

Global framework configuration using `set()` function:

```cfm
<cfscript>
    /*
        Use this file to configure your application.
        Environment-specific files can override these settings.
    */
    
    // Database configuration
    set(dataSourceName = "myapp");
    set(dataSourceUserName = "dbuser");
    set(dataSourcePassword = "dbpass");
    set(coreTestDataSourceName = "myapp_test");
    
    // URL rewriting
    set(URLRewriting = "On"); // "On", "Partial", or "Off"
    
    // Security
    set(reloadPassword = "mySecurePassword123");
    
    // Error handling
    set(showDebugInformation = true);
    set(showErrorInformation = true);
    set(sendEmailOnError = false);
    set(errorEmailAddress = "admin@myapp.com");
    
    // Caching settings
    set(cacheActions = true);
    set(cachePages = true);
    set(cachePartials = true);
    set(cacheQueries = true);
    set(defaultCacheTime = 60);
    
    // ORM settings
    set(tableNamePrefix = "");
    set(automaticValidations = true);
    set(timeStampOnCreateProperty = "createdAt");
    set(timeStampOnUpdateProperty = "updatedAt");
    set(softDeleteProperty = "deletedAt");
    
    // Function defaults
    set(functionName = "findAll", perPage = 25);
    set(functionName = "linkTo", encode = false);
    
    // Asset settings
    set(assetQueryString = true);
    set(assetPaths = {
        http: "cdn1.myapp.com,cdn2.myapp.com",
        https: "secure-cdn.myapp.com"
    });
</cfscript>
```

### Configuration Categories

#### Database Settings
```cfm
set(dataSourceName = "myapp");
set(dataSourceUserName = "user");
set(dataSourcePassword = "pass");
set(tableNamePrefix = "app_");
```

#### URL and Routing Settings
```cfm
set(URLRewriting = "On");
set(obfuscateUrls = false);
set(loadDefaultRoutes = true);
```

#### Caching Settings
```cfm
set(cacheActions = true);
set(cachePages = true);
set(cachePartials = true);
set(cacheQueries = true);
set(cacheRoutes = true);
set(defaultCacheTime = 60);
set(maximumItemsToCache = 5000);
```

#### Security Settings
```cfm
set(reloadPassword = "securePassword");
set(csrfStore = "session"); // or "cookie"
set(allowCorsRequests = false);
```

#### Error and Debug Settings
```cfm
set(showDebugInformation = true);
set(showErrorInformation = true);
set(sendEmailOnError = false);
set(errorEmailAddress = "admin@example.com");
set(errorEmailSubject = "App Error");
```

#### ORM Settings
```cfm
set(automaticValidations = true);
set(timeStampOnCreateProperty = "createdAt");
set(timeStampOnUpdateProperty = "updatedAt");
set(softDeleteProperty = "deletedAt");
set(setUpdatedAtOnCreate = true);
set(transactionMode = "commit");
```

#### Function Default Overrides
```cfm
// Set global defaults for any Wheels function
set(functionName = "findAll", perPage = 20);
set(functionName = "textField", class = "form-control");
set(functionName = "linkTo", encode = true);
```

#### Asset Management
```cfm
set(assetQueryString = true);
set(assetPaths = {
    http: "assets1.example.com,assets2.example.com",
    https: "secure-assets.example.com"
});
```

#### Plugin Settings  
```cfm
set(overwritePlugins = false);
set(deletePluginDirectories = false);
set(loadIncompatiblePlugins = false);
```

## Routing Configuration (`routes.cfm`)

Define URL patterns and map them to controller actions:

```cfm
<cfscript>
    // Use this file to add routes to your application
    // Don't forget to reload after changes: ?reload=true
    // See https://wheels.dev/3.0.0/guides/handling-requests-with-controllers/routing
    
    mapper()
        // Resource-based routing (recommended)
        .resources("users")
        .resources("posts")
        .resources("comments")  // Nested resources use separate declarations
        
        // Singular resource (no primary key in URL)
        .resource("profile")
        .resource("cart")
        
        // Custom routes
        .get(name="search", pattern="search", to="search##index")
        .get(name="about", pattern="about", to="pages##about")
        .post(name="contact", pattern="contact", to="contact##create")
        
        // API routes with namespace
        .namespace("api", {
            resources: ["users", "posts"]
        })
        
        // Catch-all wildcard routing
        .wildcard()
        
        // Root route (homepage)
        .root(to="home##index", method="get")
    .end();
</cfscript>
```

### Routing Patterns

#### Resource Routing
```cfm
.resources("products")
// Creates: index, show, new, create, edit, update, delete actions

.resources("categories", {
    except: ["delete"]
})
.resources("products")  // Nested resources declared separately
```

#### Custom Routes
```cfm
.get(name="productSearch", pattern="products/search", to="products##search")
.post(name="newsletter", pattern="newsletter/signup", to="newsletter##signup")
.patch(name="activate", pattern="users/[key]/activate", to="users##activate")
.delete(name="clearCart", pattern="cart/clear", to="cart##clear")
```

#### Route Constraints
```cfm
.get(name="userPosts", pattern="users/[userId]/posts/[postId]", to="posts##show", {
    constraints: {
        userId: "\d+",
        postId: "\d+"
    }
})
```

#### Route Parameters
- **`[key]`** - Primary key parameter (maps to `params.key`)
- **`[slug]`** - URL-friendly identifier
- **`[any-name]`** - Custom parameter name
- **Optional parameters**: Use `?` suffix like `[category?]`

### Route Helper Usage
After defining routes, use them in views:

```cfm
<!--- Resource routes --->
#linkTo(route="products", text="All Products")#
#linkTo(route="newProduct", text="New Product")#
#linkTo(route="product", key=product.id, text="View Product")#
#linkTo(route="editProduct", key=product.id, text="Edit")#

<!--- Custom routes --->
#linkTo(route="search", text="Search Products")#
#linkTo(route="about", text="About Us")#

<!--- With parameters --->
#linkTo(route="userPosts", userId=user.id, postId=post.id)#
```

### Routing Best Practices

#### Route Ordering
Routes are processed in order - first match wins. Order routes from most specific to most general:

```cfm
mapper()
    // 1. Resource routes first
    .resources("posts")
    .resources("comments")

    // 2. Custom routes
    .get(name="search", pattern="search", to="search##index")
    .get(name="admin", pattern="admin", to="admin##dashboard")

    // 3. Root route
    .root(to="posts##index", method="get")

    // 4. Wildcard routing last
    .wildcard()
.end();
```

#### Common Routing Mistakes

**❌ Incorrect nested resource syntax:**
```cfm
.resources("posts", function(nested) {
    nested.resources("comments");  // This doesn't work in CFWheels
})
```

**✅ Correct approach - separate declarations:**
```cfm
.resources("posts")
.resources("comments")
```

**❌ Wrong route ordering:**
```cfm
mapper()
    .wildcard()        // Too early - catches everything
    .resources("posts") // Never reached
.end();
```

**✅ Correct ordering:**
```cfm
mapper()
    .resources("posts") // Specific routes first
    .wildcard()         // Catch-all last
.end();
```

#### Route Testing
Always test routes after changes:
1. Use `?reload=true` to reload configuration
2. Check the debug footer "Routes" link to view all routes
3. Test both positive and negative cases
4. Verify route helpers generate correct URLs

## Environment-Specific Settings

Override global settings per environment in `/config/[environment]/settings.cfm`:

### Development Settings (`/config/development/settings.cfm`)
```cfm
<cfscript>
// Development-specific settings
set(showDebugInformation = true);
set(showErrorInformation = true);
set(sendEmailOnError = false);

// Disable caching for easier development
set(cacheActions = false);
set(cachePages = false);
set(cachePartials = false);

// Use development database
set(dataSourceName = "myapp_dev");

// Debug-friendly asset handling
set(assetQueryString = false);
</cfscript>
```

### Production Settings (`/config/production/settings.cfm`)
```cfm
<cfscript>
// Production optimizations
set(showDebugInformation = false);
set(showErrorInformation = false);
set(sendEmailOnError = true);
set(errorEmailAddress = "alerts@myapp.com");

// Full caching enabled
set(cacheActions = true);
set(cachePages = true);
set(cachePartials = true);
set(cacheQueries = true);
set(defaultCacheTime = 120);

// Production database
set(dataSourceName = "myapp_production");

// CDN configuration
set(assetPaths = {
    http: "cdn.myapp.com",
    https: "secure-cdn.myapp.com"
});

// Security hardening
set(reloadPassword = "verySecureProductionPassword");
set(allowEnvironmentSwitchViaUrl = false);
</cfscript>
```

### Testing Settings (`/config/testing/settings.cfm`)
```cfm
<cfscript>
// Testing environment
set(showDebugInformation = true);
set(sendEmailOnError = false);

// Use test database
set(dataSourceName = "myapp_test");

// Fast caching but visible errors
set(cacheActions = true);
set(cacheQueries = true);
</cfscript>
```

## Configuration Best Practices

### 1. Environment-Appropriate Settings
```cfm
// Different settings per environment
// Development: debugging on, caching off
// Production: debugging off, caching on, error emails
// Testing: production-like caching with development-like error reporting
```

### 2. Secure Sensitive Data
```cfm
// Use environment variables for sensitive config
set(dataSourcePassword = GetEnvironmentValue("DB_PASSWORD"));
set(reloadPassword = GetEnvironmentValue("RELOAD_PASSWORD"));

// Or use encrypted configuration files
```

### 3. Database Configuration Patterns
```cfm
// Multiple datasources
this.datasources['primary'] = { /* main db */ };
this.datasources['analytics'] = { /* analytics db */ };
this.datasources['cache'] = { /* cache db */ };

// Environment-specific datasources
this.datasources['myapp'] = {
    class: GetEnvironmentValue("DB_CLASS", "org.h2.Driver"),
    connectionString: GetEnvironmentValue("DB_URL", "jdbc:h2:file:./db/app"),
    username: GetEnvironmentValue("DB_USER", "sa"),
    password: GetEnvironmentValue("DB_PASSWORD", "")
};
```

### 4. Performance Tuning
```cfm
// Production performance settings
set(cacheActions = true);
set(cachePages = true);
set(cachePartials = true);
set(cacheQueries = true);
set(defaultCacheTime = 60);
set(maximumItemsToCache = 10000);

// Development convenience settings  
set(cacheActions = false);
set(cacheControllerConfig = false);
set(cacheModelConfig = false);
```

### 5. Function Defaults Organization
```cfm
// Group related function defaults
// Form defaults
set(functionName = "textField", class = "form-control");
set(functionName = "textArea", class = "form-control");
set(functionName = "select", class = "form-select");

// Pagination defaults
set(functionName = "findAll", perPage = 25);
set(functionName = "paginationLinks", class = "pagination");

// Link defaults
set(functionName = "linkTo", encode = true);
set(functionName = "buttonTo", class = "btn btn-primary");
```

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

### API Configuration
```cfm
// API endpoints per environment
// Development
set(apiBaseUrl = "http://localhost:3000/api");
set(apiKey = "dev-key-123");

// Production  
set(apiBaseUrl = "https://api.myapp.com/v1");
set(apiKey = GetEnvironmentValue("PROD_API_KEY"));
```

### Email Configuration
```cfm
// Email settings per environment
// Development - log emails, don't send
set(sendEmailOnError = false);
set(mailMethod = "file");
set(mailPath = "./logs/mail");

// Production - send real emails
set(sendEmailOnError = true);
set(errorEmailAddress = "alerts@myapp.com");
set(mailMethod = "smtp");
set(mailServer = "smtp.myapp.com");
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

## Troubleshooting Configuration

### Common Issues

**Configuration not loading**:
- Check file syntax for CFML errors
- Verify file permissions
- Ensure proper `<cfscript>` tags

**Settings not taking effect**:
- Issue reload: `?reload=true`
- Check environment-specific overrides
- Verify setting name spelling

**Route conflicts**:
- Check route order (first match wins)
- Use route debugging: Click "Routes" in debug footer
- Verify pattern syntax

**Database connection issues**:
- Verify datasource configuration
- Check database driver availability  
- Test connection in CF Admin

### Debug Configuration
```cfm
// Dump all settings (development only)
<cfdump var="#application.wheels.settings#" label="Wheels Settings">

// Check specific setting
<cfoutput>Environment: #get("environment")#</cfoutput>
<cfoutput>Datasource: #get("dataSourceName")#</cfoutput>
<cfoutput>Debug Mode: #get("showDebugInformation")#</cfoutput>
```

## Security Considerations

### Production Hardening
```cfm
// Disable environment switching via URL
set(allowEnvironmentSwitchViaUrl = false);

// Strong reload password
set(reloadPassword = "VerySecureRandomPassword123!");

// Error email configuration
set(sendEmailOnError = true);
set(excludeFromErrorEmail = "password,ssn,creditCard");

// Disable debug information
set(showDebugInformation = false);
set(showErrorInformation = false);
```

### Sensitive Data Protection
```cfm
// Use environment variables for secrets
set(dataSourcePassword = GetEnvironmentValue("DB_PASSWORD"));
set(apiKey = GetEnvironmentValue("API_SECRET"));

// Encrypt configuration files containing sensitive data
// Store encryption keys outside application directory
```

This configuration system provides flexible, environment-aware settings management that scales from development through production deployment.