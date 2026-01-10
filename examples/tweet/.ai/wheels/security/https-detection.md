# HTTPS Detection

## Description
Detect whether the current request is using secure HTTPS protocol for implementing security policies and conditional logic.

## Key Points
- Use `isSecure()` to check if current request uses HTTPS
- Returns boolean true/false
- Useful for enforcing HTTPS requirements
- Can redirect HTTP to HTTPS automatically
- Essential for security-sensitive operations

## Code Sample
```cfm
component extends="Controller" {
    function config() {
        // Force HTTPS for all actions
        filters(through="requireHTTPS");

        // Or force HTTPS for specific actions only
        filters(through="requireHTTPS", only="login,register,checkout");
    }

    function login() {
        // Check if connection is secure
        if (!isSecure()) {
            flashInsert(error="Secure connection required for login");
            redirectTo(protocol="https", controller="sessions", action="new");
            return;
        }

        // Login logic continues...
        user = model("User").new();
    }

    function checkout() {
        // Ensure secure connection for payment processing
        if (!isSecure()) {
            flashInsert(error="Secure connection required for checkout");
            redirectTo(protocol="https");
            return;
        }

        // Payment processing logic...
        order = model("Order").findByKey(params.key);
    }

    // Conditional content based on security
    function dashboard() {
        users = model("User").findAll();
        showSensitiveData = isSecure();

        if (showSensitiveData) {
            adminStats = getAdminStatistics();
        }
    }

    private function requireHTTPS() {
        if (!isSecure()) {
            // Redirect to HTTPS version of current URL
            redirectTo(protocol="https");
        }
    }

    // API endpoint with security requirements
    function apiEndpoint() {
        if (!isSecure()) {
            renderWith(
                data={error="HTTPS required for API access"},
                status=426  // Upgrade Required
            );
            return;
        }

        // Secure API logic...
        data = model("ApiData").findSecure();
        renderWith(data=data);
    }

    // Mixed content handling
    function embedWidget() {
        protocol = isSecure() ? "https" : "http";
        widgetUrl = "#protocol#://widgets.example.com/embed.js";

        // Pass protocol-appropriate URL to view
    }
}

// View usage
<cfif isSecure()>
    <div class="secure-notice">
        <i class="lock-icon"></i>
        Secure Connection Active
    </div>
<cfelse>
    <div class="insecure-warning">
        <i class="warning-icon"></i>
        <a href="https://#cgi.server_name##cgi.request_url#">
            Switch to Secure Connection
        </a>
    </div>
</cfif>

// Environment-specific HTTPS enforcement
component extends="Controller" {
    function config() {
        // Only enforce HTTPS in production
        if (get("environment") == "production") {
            filters(through="requireHTTPS");
        }
    }

    private function requireHTTPS() {
        if (!isSecure() && get("environment") == "production") {
            redirectTo(protocol="https");
        }
    }
}
```

## Usage
1. Call `isSecure()` to check if current request uses HTTPS
2. Use in filters to enforce HTTPS requirements
3. Implement conditional logic based on connection security
4. Redirect HTTP requests to HTTPS when needed
5. Display security indicators in views

## Related
- [CSRF Protection](./csrf-protection.md)
- [Controller Filters](../controllers/filters/before-after.md)
- [Redirects](../controllers/rendering/redirects.md)

## Important Notes
- Returns `false` for HTTP connections (port 80)
- Returns `true` for HTTPS connections (port 443)
- Works behind load balancers and reverse proxies
- Consider proxy headers (X-Forwarded-Proto) in deployment
- Test both HTTP and HTTPS scenarios during development

## Common Patterns

### Force HTTPS Filter
```cfm
private function requireHTTPS() {
    if (!isSecure()) {
        local.httpsUrl = "https://" & cgi.server_name & cgi.request_url;
        if (len(cgi.query_string)) {
            local.httpsUrl &= "?" & cgi.query_string;
        }
        location(url=local.httpsUrl, addtoken=false);
    }
}
```

### Conditional Security Features
```cfm
function config() {
    if (isSecure()) {
        // Enable secure features only over HTTPS
        protectsFromForgery();
        set(secureCookies=true);
    }
}
```

### Mixed Content Prevention
```cfm
function loadExternalScript() {
    protocol = isSecure() ? "https" : "http";
    scriptUrl = "#protocol#://cdn.example.com/script.js";
    // Use protocol-matched URLs to prevent mixed content warnings
}
```

## Security Best Practices
- Always use HTTPS for authentication and sensitive data
- Redirect HTTP to HTTPS for secure pages
- Use Strict Transport Security (HSTS) headers
- Never downgrade from HTTPS to HTTP
- Test HTTPS enforcement in staging environments
- Consider HTTP/2 benefits with HTTPS