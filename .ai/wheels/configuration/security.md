# Configuration Security

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

## Application Security Settings

### Session Security

```cfm
// In /config/app.cfm
<cfscript>
// Secure session configuration
this.sessionManagement = true;
this.sessionTimeout = CreateTimeSpan(0,0,30,0); // 30 minutes
this.sessionCookie = {
    httpOnly: true,        // Prevent JavaScript access
    secure: true,          // HTTPS only
    sameSite: "strict"     // CSRF protection
};

// Prevent session fixation
this.sessionRotate = true;
</cfscript>
```

### JSON Security

```cfm
// Prevent JSON hijacking
this.secureJSON = true;
this.secureJSONPrefix = "//";

// Additional JSON security
set(jsonSecure = true);
set(jsonPrefix = "while(1);");
```

### CSRF Protection

```cfm
// Enable CSRF protection
set(csrfStore = "session"); // or "cookie"
set(csrfCookieName = "_csrf_token");
set(csrfCookieEncryptionAlgorithm = "AES");

// Generate unique tokens per request
this.generateCSRFTokens = true;
this.csrfGenerateUniqueTokens = true;
```

### Script Protection

```cfm
// Protect against script injection
this.scriptProtect = "all"; // or "none", "cgi", "form", "url", "cookie"

// Custom script protection
set(scriptProtectLevel = "high");
set(allowedScriptTags = ""); // Block all script tags
```

## Database Security

### Connection Security

```cfm
// Use environment variables for database credentials
this.datasources['myapp'] = {
    class: 'com.mysql.cj.jdbc.Driver',
    connectionString: GetEnvironmentValue("DB_URL"),
    username: GetEnvironmentValue("DB_USER"),
    password: GetEnvironmentValue("DB_PASSWORD"),

    // SSL configuration
    connectionString: "jdbc:mysql://localhost:3306/myapp?useSSL=true&requireSSL=true",

    // Connection limits
    connectionLimit: 50,
    connectionTimeout: 30
};
```

### Read-Only Connections

```cfm
// Separate read-only datasource for reporting
this.datasources['readonly'] = {
    class: 'com.mysql.cj.jdbc.Driver',
    connectionString: GetEnvironmentValue("READONLY_DB_URL"),
    username: GetEnvironmentValue("READONLY_DB_USER"),
    password: GetEnvironmentValue("READONLY_DB_PASSWORD"),
    readOnly: true
};
```

### Database Encryption

```cfm
// Database column encryption
set(encryptionAlgorithm = "AES");
set(encryptionKey = GetEnvironmentValue("DB_ENCRYPTION_KEY"));

// Encrypted connection strings
set(encryptDataSourceConnections = true);
```

## Password Security

### Reload Password Security

```cfm
// Production reload password
set(reloadPassword = GetEnvironmentValue("RELOAD_PASSWORD"));

// Password complexity requirements
set(reloadPasswordMinLength = 12);
set(reloadPasswordRequireSpecialChars = true);

// Disable reload in production
set(disableReloadInProduction = true);
```

### User Password Policies

```cfm
// Password policy settings
set(passwordMinLength = 8);
set(passwordRequireUppercase = true);
set(passwordRequireLowercase = true);
set(passwordRequireNumbers = true);
set(passwordRequireSpecialChars = true);
set(passwordExpiryDays = 90);
set(passwordHistoryCount = 5);
```

## CORS Security

```cfm
// CORS configuration
set(allowCorsRequests = false); // Disable by default

// If CORS is needed, be specific
set(allowCorsRequests = true);
set(accessControlAllowOrigin = "https://trusted-domain.com");
set(accessControlAllowMethods = "GET,POST");
set(accessControlAllowHeaders = "Content-Type,Authorization");
set(accessControlMaxAge = 3600);
```

## Error Information Security

### Error Message Filtering

```cfm
// Hide sensitive information in errors
set(showErrorInformation = false);
set(excludeFromErrorEmail = "password,ssn,creditCard,apiKey,token");

// Custom error pages
set(customErrorPages = true);
set(errorPagePath = "/errors/");

// Log errors without exposing details
set(logErrors = true);
set(errorLogLevel = "ERROR");
```

### Debug Information Security

```cfm
// Disable debug information in production
set(showDebugInformation = false);

// IP-based debug access (if needed)
set(debugAllowedIPs = "127.0.0.1,192.168.1.100");

// Debug password protection
set(debugPassword = GetEnvironmentValue("DEBUG_PASSWORD"));
```

## File Upload Security

```cfm
// File upload restrictions
set(allowFileUploads = true);
set(maxFileUploadSize = 10); // MB
set(allowedFileExtensions = "jpg,jpeg,png,gif,pdf,doc,docx");
set(uploadDirectory = "/uploads/");
set(scanUploadsForViruses = true);

// Prevent executable uploads
set(blockedFileExtensions = "exe,bat,com,scr,vbs,js,jar");
```

## API Security

### API Key Management

```cfm
// API configuration
set(apiEnabled = true);
set(apiRequireAuthentication = true);
set(apiKeyHeader = "X-API-Key");
set(apiRateLimit = 1000); // requests per hour
set(apiVersioning = true);

// API key encryption
set(encryptApiKeys = true);
set(apiKeyEncryptionAlgorithm = "AES");
```

### Rate Limiting

```cfm
// Rate limiting configuration
set(enableRateLimiting = true);
set(rateLimitRequests = 100); // per window
set(rateLimitWindow = 3600); // seconds (1 hour)
set(rateLimitByIP = true);
set(rateLimitByUser = true);
```

## Logging and Monitoring Security

### Security Event Logging

```cfm
// Security logging
set(logSecurityEvents = true);
set(securityLogLevel = "WARN");
set(logFailedLogins = true);
set(logPasswordChanges = true);
set(logPrivilegeEscalation = true);

// Log file security
set(logFilePermissions = "600"); // Owner read/write only
set(logFileDirectory = "/secure/logs/");
```

### Monitoring Configuration

```cfm
// Security monitoring
set(enableSecurityMonitoring = true);
set(monitorFailedLogins = true);
set(monitorSuspiciousActivity = true);
set(alertOnSecurityEvents = true);
set(securityAlertEmail = "security@myapp.com");
```

## Environment-Specific Security

### Development Security

```cfm
// Development security (still important!)
set(allowEnvironmentSwitchViaUrl = true);
set(reloadPassword = "dev123"); // Simple for development
set(showDebugInformation = true);

// But still protect sensitive data
set(dataSourcePassword = GetEnvironmentValue("DEV_DB_PASSWORD"));
```

### Production Security

```cfm
// Maximum security for production
set(allowEnvironmentSwitchViaUrl = false);
set(reloadPassword = GetEnvironmentValue("PROD_RELOAD_PASSWORD"));
set(showDebugInformation = false);
set(showErrorInformation = false);

// Enhanced security features
set(enableSecurityHeaders = true);
set(enableCSP = true); // Content Security Policy
set(enableHSTS = true); // HTTP Strict Transport Security
```

## Security Headers

### HTTP Security Headers

```cfm
// Content Security Policy
set(contentSecurityPolicy = "default-src 'self'; script-src 'self' 'unsafe-inline'");

// HTTP Strict Transport Security
set(httpStrictTransportSecurity = "max-age=31536000; includeSubDomains");

// X-Frame-Options
set(xFrameOptions = "DENY");

// X-Content-Type-Options
set(xContentTypeOptions = "nosniff");

// X-XSS-Protection
set(xXSSProtection = "1; mode=block");
```

## Encryption Configuration

### Data Encryption

```cfm
// Application-level encryption
set(encryptionEnabled = true);
set(encryptionAlgorithm = "AES");
set(encryptionKeyLength = 256);
set(encryptionKey = GetEnvironmentValue("ENCRYPTION_KEY"));

// Automatic field encryption
set(encryptedFields = "ssn,creditCard,password");
```

### Transport Encryption

```cfm
// Force HTTPS
set(forceHTTPS = true);
set(httpsPort = 443);
set(redirectToHTTPS = true);

// SSL/TLS configuration
set(sslMinimumVersion = "TLSv1.2");
set(sslCipherSuites = "ECDHE-ECDSA-AES256-GCM-SHA384,ECDHE-RSA-AES256-GCM-SHA384");
```

## Security Testing

### Security Validation

```cfm
// Security configuration testing
function validateSecurityConfiguration() {
    local.issues = [];

    // Check for hardcoded passwords
    if (Find("password", LCase(get("dataSourcePassword")))) {
        ArrayAppend(local.issues, "Hardcoded database password detected");
    }

    // Check debug settings in production
    if (get("environment") == "production" && get("showDebugInformation")) {
        ArrayAppend(local.issues, "Debug information enabled in production");
    }

    // Check reload password strength
    if (Len(get("reloadPassword")) < 8) {
        ArrayAppend(local.issues, "Weak reload password");
    }

    return local.issues;
}
```

### Security Audit

```cfm
// Regular security audit checks
function performSecurityAudit() {
    local.audit = {
        timestamp: Now(),
        environment: get("environment"),
        issues: []
    };

    // Check for common security misconfigurations
    local.audit.issues = validateSecurityConfiguration();

    // Log audit results
    WriteLog(
        file: "security-audit",
        text: SerializeJSON(local.audit),
        type: "INFORMATION"
    );

    return local.audit;
}
```

## Emergency Security Procedures

### Security Incident Response

```cfm
// Emergency security lockdown
function emergencyLockdown() {
    set(allowEnvironmentSwitchViaUrl = false);
    set(showDebugInformation = false);
    set(showErrorInformation = false);
    set(disableUserRegistration = true);
    set(enableMaintenanceMode = true);

    // Log the lockdown
    WriteLog(
        file: "security",
        text: "Emergency security lockdown activated",
        type: "ERROR"
    );
}
```

### Security Configuration Backup

```cfm
// Backup security configuration
function backupSecurityConfiguration() {
    local.securitySettings = {
        reloadPassword: get("reloadPassword"),
        showDebugInformation: get("showDebugInformation"),
        allowEnvironmentSwitchViaUrl: get("allowEnvironmentSwitchViaUrl"),
        csrfStore: get("csrfStore")
    };

    // Encrypt and store backup
    local.encryptedBackup = Encrypt(
        SerializeJSON(local.securitySettings),
        GetEnvironmentValue("BACKUP_ENCRYPTION_KEY"),
        "AES"
    );

    FileWrite(
        ExpandPath("/config/security-backup-" & DateFormat(Now(), "yyyymmdd") & ".enc"),
        local.encryptedBackup
    );
}
```