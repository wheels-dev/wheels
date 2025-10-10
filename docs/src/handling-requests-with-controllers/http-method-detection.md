---
description: >-
  Detect HTTP request methods and AJAX requests for implementing REST APIs,
  conditional logic, and request-specific handling in Wheels.
---

# HTTP Method Detection

## Overview

Wheels provides comprehensive HTTP method detection functions that allow you to build REST APIs, implement conditional logic, and handle different request types appropriately in your controllers.

## Available Methods

### HTTP Method Detection
- `isGet()` - Detects GET requests
- `isPost()` - Detects POST requests
- `isPut()` - Detects PUT requests
- `isPatch()` - Detects PATCH requests
- `isDelete()` - Detects DELETE requests
- `isHead()` - Detects HEAD requests
- `isOptions()` - Detects OPTIONS requests

### AJAX Detection
- `isAjax()` - Detects AJAX/XMLHttpRequest calls

### Security Detection
- `isSecure()` - Detects HTTPS requests

## Basic Usage

### Simple Method Detection
```cfm
component extends="Controller" {
    function handleRequest() {
        if (isGet()) {
            // Handle GET request - show data
            users = model("User").findAll();

        } else if (isPost()) {
            // Handle POST request - create data
            user = model("User").create(params.user);

        } else if (isPut()) {
            // Handle PUT request - update data
            user = model("User").updateByKey(params.key, params.user);

        } else if (isDelete()) {
            // Handle DELETE request - remove data
            model("User").deleteByKey(params.key);

        } else {
            // Handle unsupported methods
            renderWith(data={error="Method not allowed"}, status=405);
        }
    }
}
```

### AJAX vs Traditional Requests
```cfm
function update() {
    user = model("User").findByKey(params.key);

    if (user.update(params.user)) {
        if (isAjax()) {
            // AJAX response - return JSON
            renderWith(data={
                success=true,
                user=user,
                message="User updated successfully"
            });
        } else {
            // Traditional form - redirect with flash
            flashInsert(success="User updated successfully");
            redirectTo(route="user", key=user.id);
        }
    } else {
        if (isAjax()) {
            // AJAX error response
            renderWith(data={
                success=false,
                errors=user.allErrors()
            }, status=422);
        } else {
            // Traditional form - re-render with errors
            renderView(action="edit");
        }
    }
}
```

## REST API Development

### RESTful Controller Action
```cfm
component extends="Controller" {
    function config() {
        // Enable JSON responses
        provides("json,html");

        // Add authentication for state-changing operations
        filters(through="authenticate", except="index,show");

        // CSRF protection for non-GET requests
        protectsFromForgery(except="api");
    }

    function resource() {
        // RESTful endpoint supporting multiple HTTP methods
        switch(true) {
            case isGet():
                handleGet();
                break;
            case isPost():
                handlePost();
                break;
            case isPut():
                handlePut();
                break;
            case isPatch():
                handlePatch();
                break;
            case isDelete():
                handleDelete();
                break;
            case isHead():
                handleHead();
                break;
            case isOptions():
                handleOptions();
                break;
            default:
                renderWith(data={error="Method not allowed"}, status=405);
        }
    }

    private function handleGet() {
        if (structKeyExists(params, "key")) {
            // GET /resource/123 - Show single resource
            resource = model("Resource").findByKey(params.key);
            if (IsObject(resource)) {
                renderWith(data={resource=resource});
            } else {
                renderWith(data={error="Resource not found"}, status=404);
            }
        } else {
            // GET /resource - List resources
            resources = model("Resource").findAll(
                order="createdAt DESC",
                page=params.page ?: 1,
                perPage=params.perPage ?: 25
            );
            renderWith(data={
                resources=resources,
                pagination=pagination()
            });
        }
    }

    private function handlePost() {
        // POST /resource - Create new resource
        resource = model("Resource").create(params.resource);

        if (resource.valid()) {
            renderWith(data={
                resource=resource,
                message="Resource created successfully"
            }, status=201);
        } else {
            renderWith(data={
                errors=resource.allErrors(),
                message="Failed to create resource"
            }, status=422);
        }
    }

    private function handlePut() {
        // PUT /resource/123 - Full update
        resource = model("Resource").findByKey(params.key);

        if (IsObject(resource)) {
            if (resource.update(params.resource)) {
                renderWith(data={
                    resource=resource,
                    message="Resource updated successfully"
                });
            } else {
                renderWith(data={
                    errors=resource.allErrors(),
                    message="Failed to update resource"
                }, status=422);
            }
        } else {
            renderWith(data={error="Resource not found"}, status=404);
        }
    }

    private function handlePatch() {
        // PATCH /resource/123 - Partial update
        resource = model("Resource").findByKey(params.key);

        if (IsObject(resource)) {
            // Only update provided fields
            updateData = {};
            allowedFields = "name,description,status,category";

            for (field in ListToArray(allowedFields)) {
                if (structKeyExists(params.resource, field)) {
                    updateData[field] = params.resource[field];
                }
            }

            if (resource.update(updateData)) {
                renderWith(data={
                    resource=resource,
                    message="Resource updated successfully"
                });
            } else {
                renderWith(data={
                    errors=resource.allErrors(),
                    message="Failed to update resource"
                }, status=422);
            }
        } else {
            renderWith(data={error="Resource not found"}, status=404);
        }
    }

    private function handleDelete() {
        // DELETE /resource/123 - Remove resource
        resource = model("Resource").findByKey(params.key);

        if (IsObject(resource)) {
            resource.delete();
            renderWith(data={
                message="Resource deleted successfully"
            }, status=204);
        } else {
            renderWith(data={error="Resource not found"}, status=404);
        }
    }

    private function handleHead() {
        // HEAD /resource/123 - Check if resource exists
        resource = model("Resource").findByKey(params.key);
        local.status = IsObject(resource) ? 200 : 404;

        cfheader(statusCode=local.status);
        abort;
    }

    private function handleOptions() {
        // OPTIONS /resource - Return allowed methods
        cfheader(name="Allow", value="GET,POST,PUT,PATCH,DELETE,HEAD,OPTIONS");
        cfheader(name="Access-Control-Allow-Methods", value="GET,POST,PUT,PATCH,DELETE,HEAD,OPTIONS");
        cfheader(name="Access-Control-Allow-Headers", value="Content-Type,Authorization,X-Requested-With");

        renderWith(data={
            methods=["GET","POST","PUT","PATCH","DELETE","HEAD","OPTIONS"],
            description="Resource endpoint methods"
        });
    }
}
```

## Advanced Patterns

### Progressive Enhancement
```cfm
function create() {
    contact = model("Contact").create(params.contact);

    if (contact.valid()) {
        // Send confirmation email
        sendEmail(
            to=contact.email,
            subject="Thank you for contacting us",
            template="contact/confirmation"
        );

        if (isAjax()) {
            // AJAX: Return success data
            renderWith(data={
                success=true,
                message="Thank you! We'll be in touch soon.",
                contact={
                    id=contact.id,
                    name=contact.name,
                    submittedAt=contact.createdAt
                }
            });
        } else {
            // Traditional: Redirect with success message
            flashInsert(success="Thank you! We'll be in touch soon.");
            redirectTo(action="success");
        }
    } else {
        if (isAjax()) {
            // AJAX: Return validation errors
            renderWith(data={
                success=false,
                errors=contact.allErrors(),
                message="Please correct the errors below."
            }, status=422);
        } else {
            // Traditional: Re-render form with errors
            renderView(action="new");
        }
    }
}
```

### API Version Handling
```cfm
function api() {
    local.apiVersion = getAPIVersion(); // Custom function
    local.responseData = {};

    if (isGet()) {
        switch(local.apiVersion) {
            case "v1":
                local.responseData = getLegacyUserData();
                break;
            case "v2":
                local.responseData = getEnhancedUserData();
                break;
            default:
                renderWith(data={error="API version not supported"}, status=400);
                return;
        }

        renderWith(data=local.responseData);

    } else if (isPost()) {
        // Handle version-specific creation
        switch(local.apiVersion) {
            case "v1":
                result = createUserV1(params);
                break;
            case "v2":
                result = createUserV2(params);
                break;
            default:
                renderWith(data={error="API version not supported"}, status=400);
                return;
        }

        renderWith(data=result, status=201);
    }
}
```

### Method Override Support
```cfm
component extends="Controller" {
    function config() {
        // Enable method override for HTML forms
        filters(through="enableMethodOverride");
    }

    private function enableMethodOverride() {
        // HTML forms can only POST, but we can override the method
        if (isPost() && structKeyExists(params, "_method")) {
            switch(LCase(params._method)) {
                case "put":
                    request.wheels.requestMethod = "PUT";
                    break;
                case "patch":
                    request.wheels.requestMethod = "PATCH";
                    break;
                case "delete":
                    request.wheels.requestMethod = "DELETE";
                    break;
            }
        }
    }
}
```

## Security Considerations

### Method-Based Security
```cfm
component extends="Controller" {
    function config() {
        // Require POST for state-changing operations
        filters(through="requirePost", only="create,update,delete");

        // Require HTTPS for sensitive operations
        filters(through="requireSecure", only="login,payment,admin");

        // CSRF protection for non-GET requests
        protectsFromForgery();
    }

    private function requirePost() {
        if (!isPost()) {
            flashInsert(error="Invalid request method");
            redirectTo(action="index");
        }
    }

    private function requireSecure() {
        if (!isSecure()) {
            flashInsert(error="Secure connection required");
            redirectTo(protocol="https");
        }
    }
}
```

### Rate Limiting by Method
```cfm
private function applyRateLimit() {
    local.clientIP = cgi.remote_addr;
    local.rateKey = local.clientIP & "_" & cgi.request_method;

    // Different limits for different methods
    local.limits = {
        "GET": 100,     // 100 GET requests per minute
        "POST": 20,     // 20 POST requests per minute
        "PUT": 10,      // 10 PUT requests per minute
        "DELETE": 5     // 5 DELETE requests per minute
    };

    local.currentMethod = UCase(cgi.request_method);
    local.limit = local.limits[local.currentMethod] ?: 50;

    if (isRateLimitExceeded(local.rateKey, local.limit)) {
        renderWith(data={error="Rate limit exceeded"}, status=429);
        abort;
    }
}
```

## Filters and Method Detection

### Method-Specific Filters
```cfm
component extends="Controller" {
    function config() {
        // Apply different filters based on HTTP method
        filters(through="logGETRequests", only=getActionsForMethod("GET"));
        filters(through="validatePOSTData", only=getActionsForMethod("POST"));
        filters(through="authenticateStateChanges", except=getActionsForMethod("GET"));
    }

    private function getActionsForMethod(required string method) {
        local.methodActions = {
            "GET": "index,show,new,edit",
            "POST": "create,search,contact",
            "PUT": "update",
            "DELETE": "delete"
        };

        return local.methodActions[arguments.method] ?: "";
    }

    private function logGETRequests() {
        if (isGet()) {
            WriteLog(file="access", text="GET request to #cgi.request_url# from #cgi.remote_addr#");
        }
    }

    private function validatePOSTData() {
        if (isPost() && !structKeyExists(params, "authenticityToken")) {
            renderWith(data={error="Missing authenticity token"}, status=403);
        }
    }

    private function authenticateStateChanges() {
        if (isPost() || isPut() || isPatch() || isDelete()) {
            if (!session.authenticated) {
                renderWith(data={error="Authentication required"}, status=401);
            }
        }
    }
}
```

## Testing HTTP Methods

### Controller Tests
```cfm
component extends="wheels.Test" {
    function testHTTPMethods() {
        // Test GET request
        local.result = processRequest(controller="api", action="users", method="GET");
        assert("IsJSON(local.result.response)");

        // Test POST request
        local.result = processRequest(
            controller="api",
            action="users",
            method="POST",
            params={user={name="Test User", email="test@example.com"}}
        );
        assert("local.result.statusCode == 201");

        // Test PUT request
        local.result = processRequest(
            controller="api",
            action="users",
            method="PUT",
            key=1,
            params={user={name="Updated User"}}
        );
        assert("local.result.statusCode == 200");

        // Test DELETE request
        local.result = processRequest(
            controller="api",
            action="users",
            method="DELETE",
            key=1
        );
        assert("local.result.statusCode == 204");
    }

    function testAjaxDetection() {
        // Test AJAX request
        local.result = processRequest(
            controller="users",
            action="quickUpdate",
            ajax=true,
            params={field="status", value="active"}
        );

        local.response = DeserializeJSON(local.result.response);
        assert("local.response.success");
    }
}
```

## Related Topics

- [Request Handling](./request-handling.md)
- [Rendering Content](./rendering-content.md)
- [CORS Requests](./cors-requests.md)
- [Verification](./verification.md)

## Best Practices

1. **Use Appropriate Methods**: Follow HTTP semantics (GET for reading, POST for creating, etc.)
2. **Implement CORS**: Handle OPTIONS requests properly for AJAX APIs
3. **Progressive Enhancement**: Support both AJAX and traditional form submissions
4. **Security First**: Use HTTPS detection and CSRF protection
5. **Method Override**: Support method override for HTML forms
6. **Consistent Responses**: Return appropriate HTTP status codes
7. **Rate Limiting**: Implement different limits for different methods
8. **Testing**: Test all supported HTTP methods thoroughly