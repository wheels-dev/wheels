# Framework Settings

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

## Configuration Categories

### Database Settings

```cfm
set(dataSourceName = "myapp");
set(dataSourceUserName = "user");
set(dataSourcePassword = "pass");
set(tableNamePrefix = "app_");
```

### URL and Routing Settings

```cfm
set(URLRewriting = "On");
set(obfuscateUrls = false);
set(loadDefaultRoutes = true);
```

### Caching Settings

```cfm
set(cacheActions = true);
set(cachePages = true);
set(cachePartials = true);
set(cacheQueries = true);
set(cacheRoutes = true);
set(defaultCacheTime = 60);
set(maximumItemsToCache = 5000);
```

### Security Settings

```cfm
set(reloadPassword = "securePassword");
set(csrfStore = "session"); // or "cookie"
set(allowCorsRequests = false);
```

### Error and Debug Settings

```cfm
set(showDebugInformation = true);
set(showErrorInformation = true);
set(sendEmailOnError = false);
set(errorEmailAddress = "admin@example.com");
set(errorEmailSubject = "App Error");
```

### ORM Settings

```cfm
set(automaticValidations = true);
set(timeStampOnCreateProperty = "createdAt");
set(timeStampOnUpdateProperty = "updatedAt");
set(softDeleteProperty = "deletedAt");
set(setUpdatedAtOnCreate = true);
set(transactionMode = "commit");
```

### Function Default Overrides

```cfm
// Set global defaults for any Wheels function
set(functionName = "findAll", perPage = 20);
set(functionName = "textField", class = "form-control");
set(functionName = "linkTo", encode = true);
```

### Asset Management

```cfm
set(assetQueryString = true);
set(assetPaths = {
    http: "assets1.example.com,assets2.example.com",
    https: "secure-assets.example.com"
});
```

### Plugin Settings

```cfm
set(overwritePlugins = false);
set(deletePluginDirectories = false);
set(loadIncompatiblePlugins = false);
```

## Detailed Setting Explanations

### Database Configuration

#### Primary Database Settings
- **dataSourceName**: Main database datasource name
- **dataSourceUserName**: Database username
- **dataSourcePassword**: Database password
- **tableNamePrefix**: Prefix for all table names

#### Test Database Settings
- **coreTestDataSourceName**: Datasource for running tests

### Caching Configuration

#### Cache Types
- **cacheActions**: Cache controller action output
- **cachePages**: Cache entire page responses
- **cachePartials**: Cache partial template output
- **cacheQueries**: Cache database query results
- **cacheRoutes**: Cache URL routing decisions

#### Cache Settings
- **defaultCacheTime**: Default cache duration in minutes
- **maximumItemsToCache**: Maximum number of items to cache
- **cacheControllerConfig**: Cache controller configuration
- **cacheModelConfig**: Cache model configuration

### Performance Settings

#### URL Rewriting
- **URLRewriting**: "On", "Partial", or "Off"
- **obfuscateUrls**: Hide URL parameters with encryption
- **loadDefaultRoutes**: Load Wheels default route patterns

#### Query Optimization
- **cacheQueriesDuringRequest**: Cache queries within single request
- **cacheQueryDataDuringRequest**: Cache query data structures

### Security Configuration

#### Password Protection
- **reloadPassword**: Password required for application reload
- **allowEnvironmentSwitchViaUrl**: Allow environment switching via URL

#### CSRF Protection
- **csrfStore**: Where to store CSRF tokens ("session" or "cookie")
- **csrfCookieName**: Name of CSRF cookie
- **csrfCookieEncryptionAlgorithm**: Encryption for CSRF cookies

#### CORS Settings
- **allowCorsRequests**: Allow cross-origin requests
- **accessControlAllowOrigin**: Allowed origins for CORS
- **accessControlAllowMethods**: Allowed HTTP methods for CORS

### Error Handling

#### Debug Information
- **showDebugInformation**: Show debug panel in footer
- **showErrorInformation**: Show detailed error messages
- **debugEmailAddress**: Email address for debug information

#### Error Notifications
- **sendEmailOnError**: Send email when errors occur
- **errorEmailAddress**: Email address for error notifications
- **errorEmailSubject**: Subject line for error emails
- **excludeFromErrorEmail**: Properties to exclude from error emails

### ORM Configuration

#### Automatic Features
- **automaticValidations**: Enable automatic model validations
- **setUpdatedAtOnCreate**: Set updatedAt when creating records
- **transactionMode**: Default transaction handling ("commit", "rollback", "none")

#### Timestamp Properties
- **timeStampOnCreateProperty**: Property name for creation timestamp
- **timeStampOnUpdateProperty**: Property name for update timestamp
- **softDeleteProperty**: Property name for soft delete timestamp

#### Naming Conventions
- **tableNamePrefix**: Prefix for database table names
- **classSuffix**: Suffix for generated class names

### Asset Management

#### Query Strings
- **assetQueryString**: Add query strings to assets for cache busting
- **assetQueryStringLength**: Length of asset query strings

#### CDN Configuration
- **assetPaths**: CDN URLs for serving assets
- **assetHost**: Default asset host

### Function Defaults

Set global defaults for any Wheels function:

```cfm
// Pagination defaults
set(functionName = "findAll", perPage = 25);
set(functionName = "paginationLinks", class = "pagination");

// Form defaults
set(functionName = "textField", class = "form-control");
set(functionName = "textArea", class = "form-control");
set(functionName = "select", class = "form-select");

// Link defaults
set(functionName = "linkTo", encode = true);
set(functionName = "buttonTo", class = "btn btn-primary");

// Image defaults
set(functionName = "imageTag", class = "img-fluid");
```

## Environment-Specific Overrides

### Development Settings Example

```cfm
// In /config/development/settings.cfm
<cfscript>
// Disable caching for development
set(cacheActions = false);
set(cachePages = false);
set(cachePartials = false);

// Show all debug information
set(showDebugInformation = true);
set(showErrorInformation = true);

// Don't send error emails
set(sendEmailOnError = false);

// Development database
set(dataSourceName = "myapp_dev");
</cfscript>
```

### Production Settings Example

```cfm
// In /config/production/settings.cfm
<cfscript>
// Enable all caching
set(cacheActions = true);
set(cachePages = true);
set(cachePartials = true);
set(cacheQueries = true);
set(defaultCacheTime = 120);

// Hide debug information
set(showDebugInformation = false);
set(showErrorInformation = false);

// Send error emails
set(sendEmailOnError = true);
set(errorEmailAddress = "alerts@myapp.com");

// Production database
set(dataSourceName = "myapp_prod");

// Secure settings
set(allowEnvironmentSwitchViaUrl = false);
</cfscript>
```

## Best Practices

### 1. Group Related Settings

```cfm
// Group related function defaults
// Form defaults
set(functionName = "textField", class = "form-control");
set(functionName = "textArea", class = "form-control");
set(functionName = "select", class = "form-select");

// Pagination defaults
set(functionName = "findAll", perPage = 25);
set(functionName = "paginationLinks", class = "pagination");
```

### 2. Use Environment Variables for Sensitive Data

```cfm
// Use environment variables for passwords
set(dataSourcePassword = GetEnvironmentValue("DB_PASSWORD"));
set(reloadPassword = GetEnvironmentValue("RELOAD_PASSWORD"));
```

### 3. Performance Tuning by Environment

```cfm
// Development: No caching for easier development
// Testing: Minimal caching for faster feedback
// Production: Full caching for performance
```

### 4. Security Hardening

```cfm
// Production security settings
set(allowEnvironmentSwitchViaUrl = false);
set(showDebugInformation = false);
set(showErrorInformation = false);
set(reloadPassword = "VerySecureRandomPassword");
```