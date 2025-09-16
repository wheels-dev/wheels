# Environment Configuration

## Description
Configure different settings for development, testing, and production environments in Wheels applications.

## Key Points
- Set environment in `/config/environment.cfm`
- Available environments: development, testing, production, maintenance
- Override settings in `/config/[environment]/settings.cfm`
- Environment-specific configuration for databases, debugging, caching
- Use environment variables for sensitive information

## Code Sample
```cfm
<!-- /config/environment.cfm -->
<cfscript>
    // Set current environment
    set(environment="development");

    // Or set based on server conditions
    if (FindNoCase("production", cgi.server_name)) {
        set(environment="production");
    } else if (FindNoCase("staging", cgi.server_name)) {
        set(environment="testing");
    } else {
        set(environment="development");
    }
</cfscript>

<!-- /config/settings.cfm - Global settings -->
<cfscript>
    // Database configuration
    set(dataSourceName="myapp-dev");
    set(dataSourceUserName="username");
    set(dataSourcePassword="password");

    // URL rewriting
    set(URLRewriting="On");

    // Debugging
    set(showErrorInformation=true);
    set(sendEmailOnError=false);

    // Reload password
    set(reloadPassword="mypassword");
</cfscript>

<!-- /config/development/settings.cfm -->
<cfscript>
    // Development-specific settings
    set(dataSourceName="myapp-dev");
    set(showErrorInformation=true);
    set(showDebugInformation=true);
    set(cachePages=false);
    set(cachePartials=false);
    set(cacheQueries=false);

    // Migration settings
    set(autoMigrateDatabase=true);
    set(allowMigrationDown=true);
</cfscript>

<!-- /config/testing/settings.cfm -->
<cfscript>
    // Testing-specific settings
    set(dataSourceName="myapp-test");
    set(showErrorInformation=false);
    set(showDebugInformation=false);
    set(cachePages=false);

    // Disable email in tests
    set(sendEmailOnError=false);
</cfscript>

<!-- /config/production/settings.cfm -->
<cfscript>
    // Production-specific settings
    set(dataSourceName="myapp-prod");
    set(showErrorInformation=false);
    set(showDebugInformation=false);
    set(sendEmailOnError=true);

    // Enable caching
    set(cachePages=true);
    set(cachePartials=true);
    set(cacheQueries=true);

    // Migration settings
    set(autoMigrateDatabase=false);
    set(allowMigrationDown=false);

    // Security
    set(csrfProtection=true);
    set(obfuscateUrls=true);
</cfscript>
```

## Usage
1. Set environment in `/config/environment.cfm`
2. Configure global settings in `/config/settings.cfm`
3. Override settings in environment-specific files
4. Use environment variables for sensitive data
5. Test configuration in each environment

## Related
- [Settings Configuration](./settings.md)
- [Database Configuration](./datasources.md)
- [Security Configuration](./security.md)

## Important Notes
- Environment determines which override settings load
- Use environment variables for passwords and API keys
- Test all environments before deployment
- Production should disable debugging and enable caching
- Keep sensitive data out of version control