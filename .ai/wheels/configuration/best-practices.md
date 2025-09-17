# Configuration Best Practices

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

## Configuration Organization

### Logical Grouping

```cfm
<cfscript>
// === DATABASE CONFIGURATION ===
set(dataSourceName = "myapp");
set(dataSourceUserName = "dbuser");
set(dataSourcePassword = "dbpass");
set(tableNamePrefix = "");

// === CACHING CONFIGURATION ===
set(cacheActions = true);
set(cachePages = true);
set(cachePartials = true);
set(defaultCacheTime = 60);

// === SECURITY CONFIGURATION ===
set(reloadPassword = "securePassword");
set(csrfStore = "session");
set(allowCorsRequests = false);

// === ERROR HANDLING ===
set(showDebugInformation = true);
set(sendEmailOnError = false);
set(errorEmailAddress = "admin@example.com");

// === FORM DEFAULTS ===
set(functionName = "textField", class = "form-control");
set(functionName = "textArea", class = "form-control");
set(functionName = "select", class = "form-select");
</cfscript>
```

### Documentation and Comments

```cfm
<cfscript>
// Custom application settings with detailed explanations
set(enableAdvancedFeatures = true); // Enable beta features for testing
set(maxFileUploadSize = 10); // Maximum file upload size in MB
set(apiRateLimit = 1000); // API requests per hour per user
set(sessionWarningTime = 5); // Minutes before session expiry to show warning
set(passwordExpiryDays = 90); // Days before password must be changed
</cfscript>
```

## Environment-Specific Best Practices

### Development Environment

```cfm
// /config/development/settings.cfm
<cfscript>
// === DEBUGGING ===
set(showDebugInformation = true);
set(showErrorInformation = true);
set(sendEmailOnError = false);

// === CACHING (disabled for easier development) ===
set(cacheActions = false);
set(cachePages = false);
set(cachePartials = false);
set(cacheControllerConfig = false);
set(cacheModelConfig = false);

// === DATABASE ===
set(dataSourceName = "myapp_dev");

// === ASSETS ===
set(assetQueryString = false); // Disable for easier debugging
set(compressCss = false);
set(compressJs = false);

// === DEVELOPMENT FEATURES ===
set(allowEnvironmentSwitchViaUrl = true);
set(reloadPassword = "dev123"); // Simple password for development
</cfscript>
```

### Production Environment

```cfm
// /config/production/settings.cfm
<cfscript>
// === PERFORMANCE ===
set(cacheActions = true);
set(cachePages = true);
set(cachePartials = true);
set(cacheQueries = true);
set(defaultCacheTime = 120); // Longer cache time for production

// === SECURITY ===
set(showDebugInformation = false);
set(showErrorInformation = false);
set(allowEnvironmentSwitchViaUrl = false);
set(reloadPassword = GetEnvironmentValue("PROD_RELOAD_PASSWORD"));

// === ERROR HANDLING ===
set(sendEmailOnError = true);
set(errorEmailAddress = "alerts@myapp.com");
set(excludeFromErrorEmail = "password,ssn,creditCard");

// === DATABASE ===
set(dataSourceName = "myapp_prod");
set(dataSourcePassword = GetEnvironmentValue("PROD_DB_PASSWORD"));

// === CDN CONFIGURATION ===
set(assetPaths = {
    http: "cdn.myapp.com",
    https: "secure-cdn.myapp.com"
});

// === MONITORING ===
set(enablePerformanceMonitoring = true);
set(logLevel = "ERROR"); // Only log errors in production
</cfscript>
```

### Testing Environment

```cfm
// /config/testing/settings.cfm
<cfscript>
// === TESTING OPTIMIZATIONS ===
set(cacheActions = true); // Cache for speed
set(cacheQueries = true); // Cache queries for faster tests
set(cachePages = false); // Don't cache pages (might interfere with tests)

// === DATABASE ===
set(dataSourceName = "myapp_test");
set(transactionMode = "rollback"); // Automatic rollback for test isolation

// === DEBUGGING ===
set(showDebugInformation = true); // Show debug info for test failures
set(sendEmailOnError = false); // Don't send emails during testing

// === TESTING FEATURES ===
set(allowTestDataGeneration = true);
set(resetDatabaseBetweenTests = true);
</cfscript>
```

## Security Best Practices

### Password Protection

```cfm
// Use strong, unique passwords
set(reloadPassword = "ComplexPassword123!@#");

// Use environment variables for production
set(reloadPassword = GetEnvironmentValue("RELOAD_PASSWORD"));
```

### Database Security

```cfm
// Never hardcode database passwords
set(dataSourcePassword = GetEnvironmentValue("DB_PASSWORD"));

// Use read-only users for analytics
this.datasources['analytics'] = {
    username: GetEnvironmentValue("ANALYTICS_USER", "readonly_user"),
    password: GetEnvironmentValue("ANALYTICS_PASSWORD")
};
```

### Session Security

```cfm
// Secure session configuration
this.sessionCookie = {
    httpOnly: true,
    secure: true,
    sameSite: "strict"
};

// CSRF protection
set(csrfStore = "session");
set(csrfCookieEncryptionAlgorithm = "AES");
```

## Performance Best Practices

### Caching Strategy

```cfm
// Aggressive caching for production
set(cacheActions = true);
set(cachePages = true);
set(cachePartials = true);
set(cacheQueries = true);
set(cacheRoutes = true);

// Longer cache times for static content
set(defaultCacheTime = 120); // 2 hours
set(maximumItemsToCache = 10000);
```

### Database Optimization

```cfm
// Connection pooling
this.datasources['myapp'].connectionLimit = 100;
this.datasources['myapp'].connectionTimeout = 30;

// Query optimization
set(cacheQueriesDuringRequest = true);
set(cacheQueryDataDuringRequest = true);
```

### Asset Optimization

```cfm
// CDN configuration
set(assetPaths = {
    http: "assets1.example.com,assets2.example.com",
    https: "secure-assets.example.com"
});

// Compression
set(compressCss = true);
set(compressJs = true);
set(assetQueryString = true); // Cache busting
```

## Maintenance and Monitoring

### Error Handling

```cfm
// Comprehensive error reporting
set(sendEmailOnError = true);
set(errorEmailAddress = "alerts@myapp.com");
set(errorEmailSubject = "[MyApp] Application Error");

// Exclude sensitive data from error reports
set(excludeFromErrorEmail = "password,creditCard,ssn,apiKey");
```

### Logging Configuration

```cfm
// Environment-specific logging levels
// Development: DEBUG
// Testing: INFO
// Production: ERROR

if (get("environment") == "production") {
    set(logLevel = "ERROR");
} else {
    set(logLevel = "DEBUG");
}
```

### Health Checks

```cfm
// Enable health check endpoints
set(enableHealthChecks = true);
set(healthCheckPassword = GetEnvironmentValue("HEALTH_CHECK_PASSWORD"));

// Monitor critical systems
set(monitorDatabase = true);
set(monitorCache = true);
set(monitorDiskSpace = true);
```

## Documentation Best Practices

### Configuration Documentation

```cfm
/*
=== MYAPP CONFIGURATION DOCUMENTATION ===

This file contains the core configuration for the MyApp application.

IMPORTANT SETTINGS:
- dataSourceName: Must match the datasource defined in Application.cfc
- reloadPassword: Required for application reloads in production
- cacheSettings: Adjust based on server memory and performance requirements

ENVIRONMENT OVERRIDES:
- development/settings.cfm: Disables caching, enables debugging
- production/settings.cfm: Enables full caching, disables debugging
- testing/settings.cfm: Optimized for automated testing

LAST UPDATED: 2024-01-15
MAINTAINED BY: Development Team
*/
```

### Change Management

```cfm
// Version your configuration changes
/*
CONFIGURATION CHANGELOG:
v1.3.0 (2024-01-15):
- Added CDN configuration for asset delivery
- Increased default cache time to 120 minutes
- Added health check monitoring

v1.2.0 (2023-12-10):
- Enhanced security settings for production
- Added CSRF protection configuration
- Updated database connection limits
*/
```