# Production Deployment Checklist for CFWheels Applications

## Description
Comprehensive checklist and guidelines for deploying CFWheels applications to production environments, ensuring security, performance, reliability, and maintainability.

## Key Points
- Production deployments require different configurations than development
- Security hardening is critical for production environments
- Performance optimization should be enabled in production
- Monitoring and logging must be properly configured
- Database migrations need careful handling in production
- Rollback procedures should be tested and documented

## Pre-Deployment Security Checklist

### 1. Environment Configuration
```cfm
<!-- /config/production/settings.cfm -->
<cfscript>
// Database Configuration
set(dataSourceName="myapp-prod");
set(dataSourceUserName="prod_user");
set(dataSourcePassword=getEnvironmentVariable("DB_PASSWORD")); // Never hardcode!

// Security Settings
set(showErrorInformation=false); // CRITICAL: Never show errors in production
set(sendEmailOnError=true);
set(errorEmailAddress="alerts@yourcompany.com");

// Performance Settings
set(cachePages=true);
set(cachePartials=true);
set(cacheQueries=true);
set(cacheActions=true);
set(cacheLayout=true);

// Session Security
set(cookieTimeout=30); // 30 minutes
set(sessionTimeout=createTimeSpan(0,0,30,0));
set(setClientCookies=true);
set(sessionStorage="cookie");

// HTTPS Configuration
set(forceSSL=true);
set(HTTPSRedirect=true);

// CSRF Protection (MANDATORY)
set(CSRFCookieName="_token");
set(CSRFCookieTimeout=createTimeSpan(0,2,0,0)); // 2 hours

// File Upload Security
set(maximumFileSize=5242880); // 5MB limit
set(allowedFileExtensions="jpg,jpeg,png,gif,pdf,doc,docx");

// Disable Development Features
set(reloadPassword=""); // Disable application reload
set(designMode=false);
set(showDebugInformation=false);
</cfscript>
```

### 2. Application.cfc Security Hardening
```cfm
component extends="Wheels" output="false" {

    // Application Settings
    this.name = "MyApp-Production";
    this.sessionManagement = true;
    this.sessionTimeout = createTimeSpan(0,0,30,0);
    this.setClientCookies = true;
    this.setDomainCookies = false;
    this.scriptProtect = "all"; // XSS protection
    this.enableRobustException = false; // Don't expose internal details

    // Security Headers
    this.secureJSON = true;
    this.secureJSONPrefix = "//";

    // Request Settings
    this.requestTimeout = 60; // 60 seconds
    this.enableNullSupport = false;

    function onApplicationStart() {
        // Initialize Wheels in production mode
        set(environment="production");

        // Load production configurations
        super.onApplicationStart();

        // Set security headers
        response.addHeader("X-Content-Type-Options", "nosniff");
        response.addHeader("X-Frame-Options", "DENY");
        response.addHeader("X-XSS-Protection", "1; mode=block");
        response.addHeader("Strict-Transport-Security", "max-age=31536000; includeSubDomains");

        // Content Security Policy
        local.csp = "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data:;";
        response.addHeader("Content-Security-Policy", local.csp);

        return true;
    }

    function onSessionStart() {
        // Regenerate session ID for security
        sessionRotate();

        // Set secure session variables
        session.startTime = now();
        session.ipAddress = cgi.remote_addr;
        session.userAgent = cgi.http_user_agent;
    }

    function onRequestStart(targetPage) {
        // Security validations
        if (structKeyExists(session, "ipAddress") && session.ipAddress != cgi.remote_addr) {
            sessionInvalidate();
            location(url="/sessions/new", addtoken=false);
        }

        // Rate limiting (basic implementation)
        if (this.requestCount++ > 1000) {
            writeOutput("Rate limit exceeded");
            abort;
        }

        super.onRequestStart(arguments.targetPage);
    }

    function onError(exception, eventname) {
        // Log errors securely
        writeLog(
            file="application_errors",
            text="Error: #exception.message# | Event: #arguments.eventname# | User: #session.user.id ?: 'anonymous'#",
            type="error"
        );

        // Send error notifications
        if (get("sendEmailOnError")) {
            try {
                sendEmail(
                    to=get("errorEmailAddress"),
                    from="noreply@yourapp.com",
                    subject="Production Error - #get('applicationName')#",
                    body="Error occurred at #now()#: #exception.message#"
                );
            } catch (emailError) {
                // Don't let email errors crash the application
                writeLog(file="email_errors", text=emailError.message, type="error");
            }
        }

        // Show generic error page
        include "/app/views/errors/500.cfm";
        abort;
    }
}
```

## Database Production Configuration

### 1. Database Connection Security
```cfm
<!-- Use environment variables for sensitive data -->
<cfscript>
// Production database settings
set(dataSourceName=getEnvironmentVariable("DB_NAME"));
set(dataSourceUserName=getEnvironmentVariable("DB_USER"));
set(dataSourcePassword=getEnvironmentVariable("DB_PASSWORD"));
set(dataSourceHost=getEnvironmentVariable("DB_HOST"));
set(dataSourcePort=getEnvironmentVariable("DB_PORT") ?: "3306");

// Connection pool settings for production
set(dataSourceConnectionString="jdbc:mysql://#get('dataSourceHost')#:#get('dataSourcePort')#/#get('dataSourceName')#?useSSL=true&requireSSL=true&verifyServerCertificate=true");

// Connection pool optimization
set(dataSourceClass="com.mysql.cj.jdbc.Driver");
set(connectionTimeout=30);
set(loginTimeout=30);
set(maxConnections=50);
set(minConnections=5);
</cfscript>
```

### 2. Migration Deployment Strategy
```bash
#!/bin/bash
# production-migration-deploy.sh

# Set strict error handling
set -euo pipefail

echo "🚀 Starting production migration deployment..."

# 1. Backup database before migrations
echo "📦 Creating database backup..."
mysqldump -h $DB_HOST -u $DB_USER -p$DB_PASSWORD $DB_NAME > backup_$(date +%Y%m%d_%H%M%S).sql

# 2. Run migrations with error handling
echo "🔄 Running database migrations..."
if ! wheels dbmigrate latest; then
    echo "❌ Migration failed! Rolling back..."
    # Restore from backup
    mysql -h $DB_HOST -u $DB_USER -p$DB_PASSWORD $DB_NAME < backup_$(date +%Y%m%d_%H%M%S).sql
    exit 1
fi

# 3. Verify migration success
echo "✅ Verifying migration success..."
wheels dbmigrate info

echo "✅ Migration deployment completed successfully!"
```

## Web Server Configuration

### 1. Apache Configuration (.htaccess)
```apache
# Production .htaccess for CFWheels
RewriteEngine On

# Force HTTPS
RewriteCond %{HTTPS} off
RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]

# Security Headers
<IfModule mod_headers.c>
    Header always set X-Content-Type-Options nosniff
    Header always set X-Frame-Options DENY
    Header always set X-XSS-Protection "1; mode=block"
    Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"
    Header always set Content-Security-Policy "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'"
    Header always set Referrer-Policy "strict-origin-when-cross-origin"
    Header always set Permissions-Policy "geolocation=(), microphone=(), camera=()"
</IfModule>

# Hide sensitive files
<Files ".env">
    Order allow,deny
    Deny from all
</Files>

<Files "*.log">
    Order allow,deny
    Deny from all
</Files>

# Cache static assets
<IfModule mod_expires.c>
    ExpiresActive On
    ExpiresByType text/css "access plus 1 month"
    ExpiresByType application/javascript "access plus 1 month"
    ExpiresByType image/png "access plus 1 year"
    ExpiresByType image/jpg "access plus 1 year"
    ExpiresByType image/jpeg "access plus 1 year"
    ExpiresByType image/gif "access plus 1 year"
</IfModule>

# Enable compression
<IfModule mod_deflate.c>
    AddOutputFilterByType DEFLATE text/html text/plain text/xml text/css text/javascript application/javascript
</IfModule>

# CFWheels URL Rewriting
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule ^(.*)$ index.cfm/$1 [QSA,L]
```

### 2. Nginx Configuration
```nginx
# Production Nginx configuration for CFWheels
server {
    listen 443 ssl http2;
    server_name yourapp.com www.yourapp.com;

    # SSL Configuration
    ssl_certificate /path/to/ssl/cert.pem;
    ssl_certificate_key /path/to/ssl/private.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;

    root /path/to/wheels/app/public;
    index index.cfm;

    # Security Headers
    add_header X-Content-Type-Options nosniff;
    add_header X-Frame-Options DENY;
    add_header X-XSS-Protection "1; mode=block";
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains";
    add_header Content-Security-Policy "default-src 'self'; script-src 'self'";

    # Static file caching
    location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Hide sensitive files
    location ~ /\. {
        deny all;
    }

    location ~ \.(log|env)$ {
        deny all;
    }

    # CFWheels URL rewriting
    location / {
        try_files $uri $uri/ @rewrite;
    }

    location @rewrite {
        rewrite ^/(.*)$ /index.cfm/$1 last;
    }

    # CFM file processing
    location ~ \.cfm {
        include fastcgi_params;
        fastcgi_pass 127.0.0.1:8016; # Adjust for your ColdFusion connector
        fastcgi_index index.cfm;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }
}

# Redirect HTTP to HTTPS
server {
    listen 80;
    server_name yourapp.com www.yourapp.com;
    return 301 https://$server_name$request_uri;
}
```

## Environment Variables and Secrets Management

### 1. Environment Variables (.env.production)
```bash
# Database Configuration
DB_NAME=myapp_production
DB_USER=prod_user
DB_PASSWORD=secure_random_password_here
DB_HOST=your-db-server.com
DB_PORT=3306

# Application Configuration
APP_NAME=MyApp
APP_ENV=production
APP_URL=https://yourapp.com
APP_DEBUG=false

# Mail Configuration
MAIL_HOST=smtp.yourprovider.com
MAIL_PORT=587
MAIL_USERNAME=your-smtp-username
MAIL_PASSWORD=your-smtp-password
MAIL_ENCRYPTION=tls

# Security Keys
SECRET_KEY=your-very-long-random-secret-key
CSRF_KEY=another-random-key-for-csrf
SESSION_KEY=session-encryption-key

# Third-party Services
AWS_ACCESS_KEY_ID=your-aws-access-key
AWS_SECRET_ACCESS_KEY=your-aws-secret-key
S3_BUCKET=your-s3-bucket

# Monitoring
SENTRY_DSN=your-sentry-dsn
DATADOG_API_KEY=your-datadog-key

# Cache Configuration
REDIS_URL=redis://your-redis-server:6379
MEMCACHED_SERVERS=your-memcached-server:11211
```

### 2. Secrets Loading Utility
```cfm
<!-- /app/lib/SecretsManager.cfc -->
<cfscript>
component {

    public function loadProductionSecrets() {
        local.envFile = expandPath("/.env.production");

        if (!fileExists(envFile)) {
            throw(message="Production environment file not found", type="security");
        }

        local.envContent = fileRead(envFile);
        local.lines = listToArray(envContent, chr(10));

        for (local.line in lines) {
            if (len(trim(line)) && !line.startsWith("#")) {
                local.parts = listToArray(line, "=", false, 2);
                if (arrayLen(parts) == 2) {
                    local.key = trim(parts[1]);
                    local.value = trim(parts[2]);

                    // Set as system property for security
                    system.setProperty(key, value);
                }
            }
        }
    }

    public function getSecret(required string key, string defaultValue="") {
        // Try system property first (most secure)
        local.value = system.getProperty(arguments.key);

        if (!isNull(value) && len(value)) {
            return value;
        }

        // Fallback to environment variable
        local.envValue = getEnvironmentVariable(arguments.key);
        if (len(envValue)) {
            return envValue;
        }

        // Return default if provided
        if (len(arguments.defaultValue)) {
            return arguments.defaultValue;
        }

        throw(message="Secret not found: #arguments.key#", type="security");
    }

    public function validateRequiredSecrets() {
        local.requiredSecrets = [
            "DB_PASSWORD",
            "SECRET_KEY",
            "CSRF_KEY"
        ];

        local.missing = [];

        for (local.secret in requiredSecrets) {
            try {
                this.getSecret(secret);
            } catch (any e) {
                arrayAppend(missing, secret);
            }
        }

        if (arrayLen(missing)) {
            throw(
                message="Missing required production secrets: #arrayToList(missing)#",
                type="security"
            );
        }

        return true;
    }
}
</cfscript>
```

## Performance Optimization

### 1. Caching Configuration
```cfm
<!-- Production caching settings -->
<cfscript>
// Enable all caching in production
set(cachePages=true);
set(cachePartials=true);
set(cacheActions=true);
set(cacheQueries=true);
set(cacheLayout=true);

// Cache duration settings
set(defaultCacheTime=60); // 60 minutes default
set(queryCacheTime=30);   // 30 minutes for queries
set(partialCacheTime=120); // 2 hours for partials

// Cache storage configuration
if (getEnvironmentVariable("REDIS_URL")) {
    set(cacheStorage="redis");
    set(cacheConnectionString=getEnvironmentVariable("REDIS_URL"));
} else {
    set(cacheStorage="memory");
}
</cfscript>
```

### 2. Database Connection Pooling
```cfm
<cfscript>
// Production database connection settings
set(dataSourceName=getSecret("DB_NAME"));
set(dataSourceUserName=getSecret("DB_USER"));
set(dataSourcePassword=getSecret("DB_PASSWORD"));

// Connection pooling for high traffic
set(dataSourceMaxConnections=100);
set(dataSourceMinConnections=10);
set(dataSourceTimeout=30);
set(dataSourceMaxIdle=300); // 5 minutes
set(dataSourceValidationQuery="SELECT 1");
set(dataSourceTestOnBorrow=true);
set(dataSourceTestWhileIdle=true);
</cfscript>
```

## Monitoring and Logging

### 1. Application Monitoring
```cfm
<!-- /app/lib/ApplicationMonitor.cfc -->
<cfscript>
component {

    public function logPerformanceMetrics(required string action, required numeric duration) {
        local.logData = {
            timestamp: now(),
            action: arguments.action,
            duration: arguments.duration,
            memory: getMemoryUsage(),
            sessionId: session.sessionId ?: "anonymous"
        };

        writeLog(
            file="performance",
            text=serializeJSON(logData),
            type="information"
        );

        // Alert if performance is poor
        if (arguments.duration > 5000) { // 5 seconds
            this.sendPerformanceAlert(logData);
        }
    }

    public function logSecurityEvent(required string event, required string details) {
        local.securityLog = {
            timestamp: now(),
            event: arguments.event,
            details: arguments.details,
            ipAddress: cgi.remote_addr,
            userAgent: cgi.http_user_agent,
            userId: session.user.id ?: "anonymous"
        };

        writeLog(
            file="security",
            text=serializeJSON(securityLog),
            type="warning"
        );

        // Send immediate alert for critical security events
        local.criticalEvents = ["login_attempt_failed", "unauthorized_access", "csrf_violation"];
        if (arrayFind(criticalEvents, arguments.event)) {
            this.sendSecurityAlert(securityLog);
        }
    }

    public function healthCheck() {
        local.health = {
            status: "healthy",
            timestamp: now(),
            database: this.checkDatabaseHealth(),
            memory: this.getMemoryStatus(),
            disk: this.getDiskSpace(),
            version: get("version")
        };

        if (health.database.status != "ok" || health.memory.usage > 80) {
            health.status = "unhealthy";
        }

        return health;
    }

    private function checkDatabaseHealth() {
        try {
            local.result = queryExecute("SELECT 1 as test", {}, {datasource: get("dataSourceName")});
            return {status: "ok", responseTime: getTickCount()};
        } catch (any e) {
            return {status: "error", error: e.message};
        }
    }
}
</cfscript>
```

### 2. Health Check Endpoint
```cfm
<!-- /app/controllers/Health.cfc -->
<cfscript>
component extends="Controller" {

    function config() {
        // Only allow health checks from localhost or monitoring IPs
        filters(through="restrictHealthCheck");
    }

    function index() {
        local.monitor = new lib.ApplicationMonitor();
        local.healthData = monitor.healthCheck();

        // Set appropriate HTTP status
        if (healthData.status == "unhealthy") {
            response.setStatus(503, "Service Unavailable");
        }

        renderText(text=serializeJSON(healthData), status=healthData.status == "healthy" ? 200 : 503);
    }

    private function restrictHealthCheck() {
        local.allowedIPs = ["127.0.0.1", "::1"]; // Add your monitoring server IPs

        if (!arrayFind(allowedIPs, cgi.remote_addr)) {
            renderText(text="Forbidden", status=403);
        }
    }
}
</cfscript>
```

## Deployment Validation Checklist

### Pre-Deployment Testing
- [ ] ✅ All tests pass in staging environment
- [ ] ✅ Performance benchmarks meet requirements
- [ ] ✅ Security scan shows no critical vulnerabilities
- [ ] ✅ Database migrations tested and verified
- [ ] ✅ SSL certificate is valid and properly configured
- [ ] ✅ Environment variables are set correctly
- [ ] ✅ Monitoring and alerting are configured
- [ ] ✅ Backup procedures are tested and working
- [ ] ✅ Rollback procedures are documented and tested

### Post-Deployment Verification
- [ ] ✅ Application starts successfully
- [ ] ✅ Health check endpoint returns 200 OK
- [ ] ✅ Database connections are working
- [ ] ✅ User authentication is functional
- [ ] ✅ Critical user flows work correctly
- [ ] ✅ Performance metrics are within acceptable ranges
- [ ] ✅ Error rates are normal
- [ ] ✅ Log files are being written correctly
- [ ] ✅ Monitoring alerts are not firing

### Production Deployment Script
```bash
#!/bin/bash
# production-deploy.sh

set -euo pipefail

echo "🚀 Starting production deployment..."

# 1. Pre-deployment checks
echo "🔍 Running pre-deployment checks..."
./scripts/pre-deployment-checks.sh

# 2. Backup current version
echo "📦 Creating backup..."
cp -r /var/www/myapp /var/www/myapp-backup-$(date +%Y%m%d_%H%M%S)

# 3. Deploy new version
echo "📋 Deploying new version..."
git pull origin main
composer install --no-dev --optimize-autoloader

# 4. Run database migrations
echo "🔄 Running database migrations..."
./scripts/production-migration-deploy.sh

# 5. Clear caches
echo "🧹 Clearing application caches..."
rm -rf /tmp/coldfusion/cache/*
rm -rf /var/www/myapp/tmp/cache/*

# 6. Restart services
echo "🔄 Restarting services..."
sudo systemctl restart coldfusion
sudo systemctl restart nginx

# 7. Wait for services to start
echo "⏳ Waiting for services to start..."
sleep 30

# 8. Run health checks
echo "🏥 Running health checks..."
if ! curl -f -s http://localhost/health > /dev/null; then
    echo "❌ Health check failed! Rolling back..."
    ./scripts/rollback.sh
    exit 1
fi

# 9. Run smoke tests
echo "💨 Running smoke tests..."
./scripts/smoke-tests.sh

echo "✅ Production deployment completed successfully!"

# 10. Send notification
echo "📧 Sending deployment notification..."
./scripts/notify-deployment.sh "success"
```

## Rollback Procedures

### Automated Rollback Script
```bash
#!/bin/bash
# rollback.sh

set -euo pipefail

echo "⚠️ Starting emergency rollback..."

# 1. Stop current services
sudo systemctl stop nginx
sudo systemctl stop coldfusion

# 2. Restore previous version
BACKUP_DIR=$(ls -t /var/www/myapp-backup-* | head -n 1)
echo "📦 Restoring from backup: $BACKUP_DIR"

rm -rf /var/www/myapp
mv "$BACKUP_DIR" /var/www/myapp

# 3. Restore database if needed
if [[ -f "database-rollback.sql" ]]; then
    echo "🔄 Rolling back database..."
    mysql -h $DB_HOST -u $DB_USER -p$DB_PASSWORD $DB_NAME < database-rollback.sql
fi

# 4. Restart services
sudo systemctl start coldfusion
sudo systemctl start nginx

# 5. Verify rollback
echo "🏥 Verifying rollback..."
sleep 30

if curl -f -s http://localhost/health > /dev/null; then
    echo "✅ Rollback completed successfully!"
else
    echo "❌ Rollback verification failed!"
    exit 1
fi

echo "📧 Sending rollback notification..."
./scripts/notify-deployment.sh "rollback"
```

This comprehensive production deployment checklist ensures that CFWheels applications are deployed securely, performantly, and reliably to production environments with proper monitoring and rollback capabilities.