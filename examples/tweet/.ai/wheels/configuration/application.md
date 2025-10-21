# Application Configuration

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

## Common Application Settings

### Application Identity
- **Application identity**: `this.name`, `this.applicationTimeout`
- **Session management**: `this.sessionManagement`, `this.sessionTimeout`
- **Client management**: `this.clientManagement`, `this.clientStorage`

### Security Settings
- **Security**: `this.secureJSON`, `this.scriptProtect`, `this.sessionRotate`
- **JSON protection**: Use `this.secureJSON = true` with `this.secureJSONPrefix`

### Database Configuration
- **Datasources**: `this.datasources` struct
- **Multiple databases**: Define different datasources for different environments

### Path Configuration
- **Mappings**: `this.mappings` struct
- **Custom paths**: `this.customTagPaths`, `this.componentPaths`

## Database Configuration Examples

### MySQL Database

```cfm
this.datasources['myapp'] = {
    class: 'com.mysql.cj.jdbc.Driver',
    connectionString: 'jdbc:mysql://localhost:3306/myapp?useSSL=false&serverTimezone=UTC',
    username: 'dbuser',
    password: 'dbpass',
    connectionTimeout: 30,
    connectionLimit: 100
};
```

### PostgreSQL Database

```cfm
this.datasources['myapp'] = {
    class: 'org.postgresql.Driver',
    connectionString: 'jdbc:postgresql://localhost:5432/myapp',
    username: 'dbuser',
    password: 'dbpass'
};
```

### H2 Database (Development)

```cfm
this.datasources['myapp-dev'] = {
    class: 'org.h2.Driver',
    connectionString: 'jdbc:h2:file:./db/h2/myapp-dev;MODE=MySQL',
    username: 'sa',
    password: ''
};
```

### SQL Server Database

```cfm
this.datasources['myapp'] = {
    class: 'com.microsoft.sqlserver.jdbc.SQLServerDriver',
    connectionString: 'jdbc:sqlserver://localhost:1433;databaseName=myapp',
    username: 'dbuser',
    password: 'dbpass'
};
```

## Multiple Datasources

```cfm
<cfscript>
    // Primary application database
    this.datasources['primary'] = {
        class: 'com.mysql.cj.jdbc.Driver',
        connectionString: 'jdbc:mysql://localhost:3306/myapp',
        username: 'app_user',
        password: 'app_pass'
    };

    // Analytics database
    this.datasources['analytics'] = {
        class: 'com.mysql.cj.jdbc.Driver',
        connectionString: 'jdbc:mysql://analytics-server:3306/analytics',
        username: 'analytics_user',
        password: 'analytics_pass'
    };

    // Cache database
    this.datasources['cache'] = {
        class: 'org.h2.Driver',
        connectionString: 'jdbc:h2:mem:cache;DB_CLOSE_DELAY=-1',
        username: 'sa'
    };
</cfscript>
```

## Session Configuration

### Basic Session Settings

```cfm
<cfscript>
    // Enable session management
    this.sessionManagement = true;
    this.sessionTimeout = CreateTimeSpan(0,0,30,0); // 30 minutes

    // Session storage
    this.sessionStorage = "memory"; // or "database", "registry"

    // Session cookies
    this.sessionCookie = {
        httpOnly: true,
        secure: true,
        sameSite: "strict"
    };
</cfscript>
```

### Client Management

```cfm
<cfscript>
    // Enable client management
    this.clientManagement = true;
    this.clientTimeout = CreateTimeSpan(90,0,0,0); // 90 days
    this.clientStorage = "database"; // or "registry", "cookie"
</cfscript>
```

## Security Settings

### JSON Security

```cfm
<cfscript>
    // Secure JSON responses
    this.secureJSON = true;
    this.secureJSONPrefix = "//";

    // Script protection
    this.scriptProtect = "all"; // or "none", "cgi", "form", "url", "cookie"
</cfscript>
```

### CSRF Protection

```cfm
<cfscript>
    // Generate CSRF tokens
    this.generateCSRFTokens = true;
    this.csrfGenerateUniqueTokens = true;
</cfscript>
```

## Path Mappings

### Custom Tag Paths

```cfm
<cfscript>
    // Add custom tag directories
    this.customTagPaths = ListAppend(
        this.customTagPaths,
        ExpandPath("../customtags")
    );
    this.customTagPaths = ListAppend(
        this.customTagPaths,
        ExpandPath("../vendor/tags")
    );
</cfscript>
```

### Component Paths

```cfm
<cfscript>
    // Add component directories
    this.componentPaths = [
        ExpandPath("../lib"),
        ExpandPath("../vendor/components")
    ];
</cfscript>
```

### Application Mappings

```cfm
<cfscript>
    // Create virtual mappings
    this.mappings["/lib"] = ExpandPath("../lib");
    this.mappings["/vendor"] = ExpandPath("../vendor");
    this.mappings["/shared"] = ExpandPath("../shared");
</cfscript>
```

## Environment-Specific Configuration

### Using Environment Variables

```cfm
<cfscript>
    // Database configuration from environment variables
    this.datasources['myapp'] = {
        class: GetEnvironmentValue("DB_CLASS", "org.h2.Driver"),
        connectionString: GetEnvironmentValue("DB_URL", "jdbc:h2:file:./db/app"),
        username: GetEnvironmentValue("DB_USER", "sa"),
        password: GetEnvironmentValue("DB_PASSWORD", "")
    };

    // Application name with environment suffix
    this.name = "MyApp_" & GetEnvironmentValue("ENVIRONMENT", "dev");
</cfscript>
```

### Conditional Configuration

```cfm
<cfscript>
    // Different settings based on server
    if (FindNoCase("localhost", CGI.SERVER_NAME)) {
        // Development settings
        this.datasources['myapp'] = {
            class: 'org.h2.Driver',
            connectionString: 'jdbc:h2:file:./db/dev'
        };
    } else {
        // Production settings
        this.datasources['myapp'] = {
            class: 'com.mysql.cj.jdbc.Driver',
            connectionString: 'jdbc:mysql://prod-db:3306/myapp'
        };
    }
</cfscript>
```

## Best Practices

### 1. Use Environment Variables for Sensitive Data

```cfm
// Don't hardcode passwords
this.datasources['myapp'].password = GetEnvironmentValue("DB_PASSWORD");
```

### 2. Set Appropriate Timeouts

```cfm
// Reasonable session timeout
this.sessionTimeout = CreateTimeSpan(0,0,30,0); // 30 minutes

// Application timeout for memory management
this.applicationTimeout = CreateTimeSpan(1,0,0,0); // 1 day
```

### 3. Enable Security Features

```cfm
// Secure session cookies
this.sessionCookie.httpOnly = true;
this.sessionCookie.secure = true;

// Secure JSON
this.secureJSON = true;
```

### 4. Organize Multiple Datasources

```cfm
// Use descriptive names
this.datasources['primary'] = { /* main app db */ };
this.datasources['analytics'] = { /* reporting db */ };
this.datasources['cache'] = { /* cache db */ };
```