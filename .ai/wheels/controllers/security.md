# Controller Security

## Description
Comprehensive guide to securing CFWheels controllers including parameter verification, CSRF protection, authentication patterns, input validation, and security best practices.

## Parameter Verification

Parameter verification ensures that required parameters are present and of the correct type before actions are executed.

### Basic Parameter Verification
```cfm
function config() {
    super.config();

    // Verify required parameters
    verifies(
        except="index,new,create",
        params="key",
        paramsTypes="integer",
        handler="objectNotFound"
    );

    // Multiple parameter verification
    verifies(
        only="create,update",
        params="product.name,product.price",
        handler="invalidProduct"
    );
}

function objectNotFound() {
    redirectTo(action="index", error="Record not found");
}

function invalidProduct() {
    flashInsert(error="Invalid product data");
    redirectTo(action="new");
}
```

### Advanced Parameter Verification
```cfm
function config() {
    super.config();

    // Verify multiple parameters with specific types
    verifies(
        only="show,edit,update,delete",
        params="key",
        paramsTypes="integer",
        handler="handleMissingKey"
    );

    // Verify nested parameters
    verifies(
        only="create,update",
        params="product.categoryId,product.price",
        paramsTypes="integer,numeric",
        handler="handleInvalidData"
    );

    // Custom verification with conditions
    verifies(
        only="adminAction",
        handler="requireAdminAccess"
    );
}

private function handleMissingKey() {
    if (params.format == "json") {
        renderWith(data={error: "Invalid or missing ID"}, status=400);
    } else {
        redirectTo(action="index", error="Invalid record ID");
    }
}

private function handleInvalidData() {
    flashInsert(error="Required product information is missing or invalid");
    redirectTo(action="new");
}

private function requireAdminAccess() {
    if (!session.user.isAdmin()) {
        redirectTo(back=true, error="Admin access required");
    }
}
```

### Custom Parameter Validation
```cfm
function config() {
    super.config();

    // Custom validation logic
    verifies(only="transfer", handler="validateTransferParams");
    verifies(only="upload", handler="validateFileUpload");
}

private function validateTransferParams() {
    // Validate transfer amount
    if (!IsNumeric(params.amount ?: "") || params.amount <= 0) {
        redirectTo(back=true, error="Invalid transfer amount");
    }

    // Validate account IDs
    if (!IsNumeric(params.fromAccountId ?: "") || !IsNumeric(params.toAccountId ?: "")) {
        redirectTo(back=true, error="Invalid account information");
    }

    // Prevent self-transfer
    if (params.fromAccountId == params.toAccountId) {
        redirectTo(back=true, error="Cannot transfer to the same account");
    }
}

private function validateFileUpload() {
    local.uploadData = getHttpRequestData();

    if (!StructKeyExists(form, "uploadFile") || !len(form.uploadFile)) {
        redirectTo(back=true, error="No file selected for upload");
    }

    // Check file size (example: 10MB limit)
    if (len(local.uploadData.content) > 10485760) {
        redirectTo(back=true, error="File size too large (maximum 10MB)");
    }
}
```

## CSRF Protection

Cross-Site Request Forgery (CSRF) protection prevents malicious sites from performing actions on behalf of authenticated users.

### Basic CSRF Protection
```cfm
function config() {
    super.config();

    // CSRF protection (enabled by default in base Controller.cfc)
    protectsFromForgery();

    // Exclude specific actions from CSRF
    protectsFromForgery(except="webhook,api");
}
```

### Advanced CSRF Configuration
```cfm
function config() {
    super.config();

    // CSRF protection with custom settings
    protectsFromForgery(
        with="exception",  // Throw exception on CSRF failure
        only="create,update,delete"  // Only protect state-changing actions
    );
}

// Custom CSRF failure handler
function handleCsrfFailure() {
    if (params.format == "json") {
        renderWith(
            data={error: "CSRF token invalid or missing"},
            status=403
        );
    } else {
        flashInsert(error="Security token invalid. Please try again.");
        redirectTo(back=true);
    }
}
```

### CSRF Token Usage in Views
```cfm
<!-- Include CSRF meta tags in layout -->
#csrfMetaTags()#

<!-- Use in forms -->
#startFormTag(route="product", method="post")#
    #hiddenFieldTag("authenticityToken", authenticityToken())#
    <!-- form fields -->
#endFormTag()#

<!-- AJAX requests -->
<script>
    // Get CSRF token from meta tag
    var csrfToken = $('meta[name="csrf-token"]').attr('content');

    $.ajaxSetup({
        beforeSend: function(xhr) {
            xhr.setRequestHeader('X-CSRF-Token', csrfToken);
        }
    });
</script>
```

## Authentication Patterns

### Session-Based Authentication
```cfm
function config() {
    super.config();

    // Require authentication for all actions except public ones
    filters(through="requireAuth", except="index,show");
}

private function requireAuth() {
    if (!StructKeyExists(session, "userId") || !IsNumeric(session.userId)) {
        // Store intended destination
        session.returnTo = cgi.request_url;
        redirectTo(controller="sessions", action="new", error="Please log in to continue");
    }
}

private function loadCurrentUser() {
    if (StructKeyExists(session, "userId")) {
        currentUser = model("User").findByKey(session.userId);
        if (!IsObject(currentUser)) {
            StructDelete(session, "userId");
            redirectTo(controller="sessions", action="new", error="Invalid session");
        }
    }
}
```

### Enhanced Session Security
```cfm
function config() {
    super.config();
    filters(through="validateSession");
}

private function validateSession() {
    if (!StructKeyExists(session, "userId")) {
        return; // Not authenticated, skip validation
    }

    // Check session timeout
    if (StructKeyExists(session, "lastActivity")) {
        local.sessionTimeout = 30; // 30 minutes
        if (dateDiff("n", session.lastActivity, now()) > local.sessionTimeout) {
            StructClear(session);
            flashInsert(error="Your session has expired. Please log in again.");
            redirectTo(controller="sessions", action="new");
            return;
        }
    }

    // Validate session fingerprint
    local.currentFingerprint = hash(cgi.remote_addr & cgi.http_user_agent, "SHA-256");
    if (StructKeyExists(session, "fingerprint") && session.fingerprint != local.currentFingerprint) {
        StructClear(session);
        flashInsert(error="Security alert: Session invalidated due to suspicious activity.");
        redirectTo(controller="sessions", action="new");
        return;
    }

    // Update last activity and fingerprint
    session.lastActivity = now();
    session.fingerprint = local.currentFingerprint;
}
```

### Two-Factor Authentication
```cfm
function config() {
    super.config();
    filters(through="requireTwoFactor", only="sensitive,admin");
}

private function requireTwoFactor() {
    if (!StructKeyExists(session, "twoFactorVerified") || !session.twoFactorVerified) {
        session.returnTo = cgi.request_url;
        redirectTo(controller="auth", action="twoFactor", error="Two-factor authentication required");
    }

    // Check if 2FA verification is still valid (expire after 30 minutes)
    if (StructKeyExists(session, "twoFactorVerifiedAt")) {
        if (dateDiff("n", session.twoFactorVerifiedAt, now()) > 30) {
            session.twoFactorVerified = false;
            StructDelete(session, "twoFactorVerifiedAt");
            redirectTo(controller="auth", action="twoFactor", error="Two-factor authentication expired");
        }
    }
}
```

## Authorization and Permissions

### Role-Based Access Control
```cfm
function config() {
    super.config();
    filters(through="checkRole", role="admin", only="admin,manage");
    filters(through="checkRole", role="moderator", only="moderate,review");
}

private function checkRole(role = "user") {
    if (!currentUser.hasRole(arguments.role)) {
        if (params.format == "json") {
            renderWith(data={error: "Insufficient permissions"}, status=403);
        } else {
            redirectTo(back=true, error="You don't have permission to access this page");
        }
    }
}
```

### Permission-Based Access Control
```cfm
function config() {
    super.config();
    filters(through="requirePermission", permission="posts.create", only="new,create");
    filters(through="requirePermission", permission="posts.edit", only="edit,update");
    filters(through="requirePermission", permission="posts.delete", only="delete");
}

private function requirePermission(permission = "") {
    if (!currentUser.hasPermission(arguments.permission)) {
        // Log unauthorized access attempt
        logUnauthorizedAccess(arguments.permission);

        if (params.format == "json") {
            renderWith(data={error: "Access denied"}, status=403);
        } else {
            redirectTo(back=true, error="You don't have permission to perform this action");
        }
    }
}

private function logUnauthorizedAccess(required string permission) {
    writeLog(
        file="security",
        text="Unauthorized access attempt: User #currentUser.id# tried to access permission '#arguments.permission#' from IP #cgi.remote_addr#"
    );
}
```

### Resource Ownership
```cfm
function config() {
    super.config();
    filters(through="loadResource", only="show,edit,update,delete");
    filters(through="checkOwnership", only="edit,update,delete");
}

private function loadResource() {
    post = model("Post").findByKey(params.key);
    if (!IsObject(post)) {
        redirectTo(action="index", error="Post not found");
    }
}

private function checkOwnership() {
    // Allow access if user owns the resource or is admin
    if (post.authorId != currentUser.id && !currentUser.isAdmin()) {
        if (params.format == "json") {
            renderWith(data={error: "You can only modify your own posts"}, status=403);
        } else {
            redirectTo(back=true, error="You can only modify your own posts");
        }
    }
}
```

## Input Validation and Sanitization

### Input Sanitization
```cfm
function config() {
    super.config();
    filters(through="sanitizeInput", only="create,update");
}

private function sanitizeInput() {
    if (StructKeyExists(params, "product")) {
        // Sanitize string inputs
        for (local.key in params.product) {
            if (IsSimpleValue(params.product[local.key])) {
                // Remove potentially harmful content
                params.product[local.key] = htmlEditFormat(trim(params.product[local.key]));

                // Remove script tags and javascript
                params.product[local.key] = reReplace(
                    params.product[local.key],
                    "<script[^>]*>.*?</script>",
                    "",
                    "all"
                );
                params.product[local.key] = reReplace(
                    params.product[local.key],
                    "javascript:",
                    "",
                    "all"
                );
            }
        }
    }
}
```

### SQL Injection Prevention
```cfm
function search() {
    // Use parameterized queries for user input
    if (len(params.q ?: "")) {
        products = model("Product").findAll(
            where="name LIKE :search OR description LIKE :search",
            params={search: "%#params.q#%"},
            order="name"
        );
    } else {
        products = model("Product").findAll(order="name");
    }
}

function advancedSearch() {
    local.where = "";
    local.params = {};

    // Build parameterized where clause
    if (len(params.name ?: "")) {
        local.where = "name LIKE :name";
        local.params.name = "%#params.name#%";
    }

    if (IsNumeric(params.categoryId ?: "")) {
        if (len(local.where)) {
            local.where &= " AND ";
        }
        local.where &= "categoryId = :categoryId";
        local.params.categoryId = params.categoryId;
    }

    products = model("Product").findAll(
        where=local.where,
        params=local.params
    );
}
```

### File Upload Security
```cfm
function upload() {
    if (!StructKeyExists(form, "uploadFile") || !len(form.uploadFile)) {
        redirectTo(back=true, error="No file selected");
        return;
    }

    local.uploadResult = handleSecureUpload();

    if (local.uploadResult.success) {
        redirectTo(action="show", key=params.key, success="File uploaded successfully");
    } else {
        redirectTo(back=true, error=local.uploadResult.error);
    }
}

private function handleSecureUpload() {
    try {
        // Configure secure upload directory
        local.uploadPath = expandPath("/uploads/secure/");

        if (!directoryExists(local.uploadPath)) {
            directoryCreate(local.uploadPath);
        }

        // Perform upload
        local.uploadResult = fileUpload(
            destination=local.uploadPath,
            fileField="uploadFile",
            nameConflict="makeunique"
        );

        // Validate file type
        local.allowedTypes = "jpg,jpeg,png,gif,pdf,doc,docx";
        if (!listFindNoCase(local.allowedTypes, local.uploadResult.clientFileExt)) {
            fileDelete(local.uploadResult.serverDirectory & local.uploadResult.serverFile);
            return {success: false, error: "File type not allowed"};
        }

        // Validate file size (10MB limit)
        if (local.uploadResult.fileSize > 10485760) {
            fileDelete(local.uploadResult.serverDirectory & local.uploadResult.serverFile);
            return {success: false, error: "File size too large (maximum 10MB)"};
        }

        // Scan for malicious content (basic check)
        local.fileContent = fileRead(local.uploadResult.serverDirectory & local.uploadResult.serverFile);
        if (reFindNoCase("<script|javascript:|vbscript:", local.fileContent)) {
            fileDelete(local.uploadResult.serverDirectory & local.uploadResult.serverFile);
            return {success: false, error: "File contains potentially malicious content"};
        }

        return {
            success: true,
            filePath: "/uploads/secure/" & local.uploadResult.serverFile,
            originalName: local.uploadResult.clientFile
        };

    } catch (any e) {
        return {success: false, error: "Upload failed: " & e.message};
    }
}
```

## SSL/TLS Enforcement

### Force HTTPS
```cfm
function config() {
    super.config();

    // Force HTTPS in production
    if (application.environment == "production") {
        filters(through="requireSSL");
    }
}

private function requireSSL() {
    if (!StructKeyExists(cgi, "https") || !cgi.https) {
        local.secureUrl = "https://" & cgi.server_name;
        if (cgi.server_port != 443) {
            local.secureUrl &= ":" & cgi.server_port;
        }
        local.secureUrl &= cgi.script_name;
        if (len(cgi.query_string)) {
            local.secureUrl &= "?" & cgi.query_string;
        }

        location(url=local.secureUrl, addToken=false);
    }
}
```

### Secure Headers
```cfm
function config() {
    super.config();
    filters(through="setSecurityHeaders");
}

private function setSecurityHeaders() {
    // Prevent clickjacking
    header name="X-Frame-Options" value="DENY";

    // XSS protection
    header name="X-XSS-Protection" value="1; mode=block";

    // Content type sniffing protection
    header name="X-Content-Type-Options" value="nosniff";

    // Referrer policy
    header name="Referrer-Policy" value="strict-origin-when-cross-origin";

    // Content Security Policy (basic)
    header name="Content-Security-Policy" value="default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'";

    // HTTP Strict Transport Security (HTTPS only)
    if (StructKeyExists(cgi, "https") && cgi.https) {
        header name="Strict-Transport-Security" value="max-age=31536000; includeSubDomains";
    }
}
```

## API Security

### API Authentication
```cfm
function config() {
    super.config();
    provides("json");
    filters(through="authenticateApiRequest");
}

private function authenticateApiRequest() {
    local.authHeader = getHttpRequestData().headers["Authorization"] ?: "";

    if (!len(local.authHeader)) {
        renderWith(data={error: "Authentication required"}, status=401);
        return;
    }

    // Support Bearer token or API key
    if (reFindNoCase("^Bearer\s+", local.authHeader)) {
        local.token = reReplace(local.authHeader, "^Bearer\s+", "", "one");
        local.user = validateBearerToken(local.token);
    } else {
        local.apiKey = local.authHeader;
        local.user = validateApiKey(local.apiKey);
    }

    if (!IsObject(local.user)) {
        renderWith(data={error: "Invalid credentials"}, status=401);
        return;
    }

    variables.currentUser = local.user;
}

private function validateBearerToken(required string token) {
    return model("User").findOne(
        where="apiToken = :token AND tokenExpiresAt > :now",
        params={
            token: arguments.token,
            now: now()
        }
    );
}

private function validateApiKey(required string apiKey) {
    return model("ApiClient").findOne(
        where="apiKey = :key AND isActive = 1",
        params={key: arguments.apiKey}
    );
}
```

### Rate Limiting for Security
```cfm
function config() {
    super.config();
    filters(through="rateLimitingSecurity");
}

private function rateLimitingSecurity() {
    local.clientIP = cgi.remote_addr;
    local.cacheKey = "rate_limit_security_#local.clientIP#";
    local.attempts = cacheGet(local.cacheKey) ?: 0;
    local.limit = 60; // 60 requests per minute per IP

    if (local.attempts >= local.limit) {
        // Log potential abuse
        writeLog(
            file="security",
            text="Rate limit exceeded for IP #local.clientIP# - possible abuse attempt"
        );

        if (params.format == "json") {
            renderWith(data={error: "Rate limit exceeded"}, status=429);
        } else {
            renderText("Rate limit exceeded. Please try again later.", status=429);
        }
        return;
    }

    // Increment counter
    cachePut(local.cacheKey, local.attempts + 1, createTimeSpan(0, 0, 1, 0)); // 1 minute
}
```

## Logging and Monitoring

### Security Event Logging
```cfm
function config() {
    super.config();
    filters(through="logSecurityEvents", type="after");
}

private function logSecurityEvents() {
    local.securityEvents = [
        "login", "logout", "password_change", "account_lock",
        "failed_login", "admin_access", "permission_denied"
    ];

    if (listFindNoCase(local.securityEvents, params.action)) {
        local.logData = {
            event = params.action,
            userId = currentUser.id ?: 0,
            ip = cgi.remote_addr,
            userAgent = cgi.http_user_agent ?: "",
            timestamp = now(),
            details = {
                controller = params.controller,
                success = !hasRedirected() || flashKeyExists("success")
            }
        };

        writeLog(
            file="security",
            text=serializeJSON(local.logData)
        );
    }
}
```

### Failed Login Attempt Tracking
```cfm
function trackFailedLogin() {
    local.ip = cgi.remote_addr;
    local.cacheKey = "failed_login_#local.ip#";
    local.attempts = cacheGet(local.cacheKey) ?: 0;

    local.attempts++;
    cachePut(local.cacheKey, local.attempts, createTimeSpan(0, 1, 0, 0)); // 1 hour

    // Log failed attempt
    writeLog(
        file="security",
        text="Failed login attempt #local.attempts# from IP #local.ip# for email: #params.email#"
    );

    // Block IP after 10 failed attempts
    if (local.attempts >= 10) {
        writeLog(
            file="security",
            text="IP #local.ip# blocked due to excessive failed login attempts"
        );

        // Add to blocked IPs cache
        cachePut("blocked_ip_#local.ip#", true, createTimeSpan(0, 24, 0, 0)); // 24 hours

        renderText("IP temporarily blocked due to excessive failed login attempts", status=403);
        return;
    }
}
```

## Testing Security

### Security Testing Patterns
```cfm
// In test file
function testRequiresAuthentication() {
    // Test without authentication
    params = {controller: "products", action: "edit", key: 1};
    result = processAction(params);

    // Should redirect to login
    assert("IsRedirect()");
    assert("result.location CONTAINS 'sessions'");
}

function testCSRFProtection() {
    // Test POST without CSRF token
    params = {
        controller: "products",
        action: "create",
        product: {name: "Test"}
    };

    // Should fail due to missing CSRF token
    expectException("CSRFTokenMissing");
    processAction(params);
}

function testPermissionDenied() {
    // Set up non-admin user
    session.userId = createTestUser(role="user").id;

    params = {controller: "admin", action: "index"};
    result = processAction(params);

    // Should redirect with error
    assert("IsRedirect()");
    assert("flashKeyExists('error')");
}
```

## Best Practices

### 1. Defense in Depth
```cfm
// Multiple layers of security
function config() {
    super.config();

    // Layer 1: HTTPS enforcement
    filters(through="requireSSL");

    // Layer 2: Authentication
    filters(through="requireAuth");

    // Layer 3: Authorization
    filters(through="checkPermissions");

    // Layer 4: Input validation
    filters(through="validateInput");

    // Layer 5: CSRF protection
    protectsFromForgery();
}
```

### 2. Secure by Default
```cfm
// Deny access by default, allow explicitly
function config() {
    super.config();

    // Require authentication for all actions
    filters(through="requireAuth");

    // Only allow specific public actions
    filters(through="requireAuth", except="index,show");
}
```

### 3. Logging and Monitoring
```cfm
// Log all security-relevant events
private function logSecurityEvent(required string event, struct details = {}) {
    local.logEntry = {
        event = arguments.event,
        timestamp = now(),
        ip = cgi.remote_addr,
        userAgent = cgi.http_user_agent ?: "",
        userId = currentUser.id ?: 0,
        details = arguments.details
    };

    writeLog(
        file="security",
        text=serializeJSON(local.logEntry)
    );
}
```

### 4. Regular Security Updates
```cfm
// Keep framework and dependencies updated
// Monitor security advisories
// Implement security patches promptly
// Regular security audits and penetration testing
```

## Related Documentation
- [Controller Architecture](./architecture.md)
- [Controller Filters](./filters.md)
- [API Controllers](./api.md)
- [Authentication Patterns](../security/authentication.md)
- [Input Validation](../security/validation.md)