# CSRF Protection

## Description
Cross-Site Request Forgery (CSRF) protection prevents unauthorized actions by verifying requests originate from your application.

## Key Points
- Use `protectsFromForgery()` to enable CSRF protection
- Generates unique tokens for each session
- Automatically validates tokens on non-GET requests
- Include tokens in all forms and AJAX requests
- Configure exception handling for invalid tokens

## Code Sample
```cfm
// Enable CSRF protection in Application Controller
component extends="Controller" {
    function config() {
        // Enable CSRF protection with exception handling
        protectsFromForgery(with="exception");

        // Or redirect on CSRF failure
        protectsFromForgery(with="redirect", redirectTo="login");

        // Protect only specific actions
        protectsFromForgery(only="create,update,delete");

        // Exclude specific actions (useful for APIs)
        protectsFromForgery(except="api");
    }
}

// Generate authenticity token in forms
#startFormTag(route="user", method="put")#
    #hiddenFieldTag("authenticityToken", authenticityToken())#
    <!-- form fields -->
#endFormTag()#

// Include CSRF meta tags in layout head
<head>
    #csrfMetaTags()#
    <!-- generates: -->
    <!-- <meta name="csrf-param" content="authenticityToken"> -->
    <!-- <meta name="csrf-token" content="[generated-token]"> -->
</head>

// AJAX requests with CSRF token
<script>
$.ajaxSetup({
    beforeSend: function(xhr, settings) {
        if (!/^(GET|HEAD|OPTIONS|TRACE)$/i.test(settings.type) && !this.crossDomain) {
            xhr.setRequestHeader("X-CSRF-Token", $('meta[name=csrf-token]').attr('content'));
        }
    }
});
</script>

// Manual token generation
component extends="Controller" {
    function config() {
        protectsFromForgery();
    }

    function create() {
        // Token automatically verified
        user = model("User").create(params.user);
        // ... rest of action
    }

    function apiEndpoint() {
        // Custom token validation
        if (!isValidToken(params.token)) {
            renderWith(data={error="Invalid token"}, status=403);
            return;
        }
        // ... api logic
    }

    private function isValidToken(required string token) {
        return arguments.token == authenticityToken();
    }
}
```

## Usage
1. Add `protectsFromForgery()` in controller's `config()` method
2. Include `#csrfMetaTags()#` in layout head section
3. Add authenticity tokens to all forms manually or automatically
4. Configure AJAX requests to include CSRF token in headers
5. Handle CSRF failures with appropriate error responses

## Related
- [HTTPS Detection](./https-detection.md)
- [Authentication Patterns](../patterns/authentication.md)
- [Form Helpers](../views/helpers/forms.md)

## Important Notes
- CSRF protection is disabled by default - must be explicitly enabled
- Only protects POST, PUT, PATCH, DELETE requests (not GET)
- API endpoints may need custom token handling
- Test with both successful and failed CSRF validation
- Use HTTPS in production for token security
- Tokens are session-specific and expire with session

## Configuration Options
- `with="exception"` - Throws CSRF exception on failure (default)
- `with="redirect"` - Redirects to specified route on failure
- `only="action1,action2"` - Protect only specified actions
- `except="action1,action2"` - Exclude specified actions from protection

## Security Best Practices
- Always enable CSRF protection for state-changing operations
- Use HTTPS to prevent token interception
- Don't include tokens in GET request URLs
- Regenerate tokens on authentication state changes
- Log CSRF violations for security monitoring