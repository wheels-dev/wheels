# HTTP Method Detection

## Description
Detect HTTP request methods and AJAX requests for implementing conditional logic, REST API endpoints, and request-specific handling.

## Key Points
- Use `isGet()`, `isPost()`, `isPut()`, `isPatch()`, `isDelete()`, `isHead()` for HTTP method detection
- Use `isAjax()` to detect AJAX/XMLHttpRequest calls
- Implement REST-like behavior in single controller actions
- Conditional processing based on request type
- API endpoint method validation

## Code Sample
```cfm
component extends="Controller" {
    function config() {
        // Method-specific filters
        filters(through="requirePOST", only="create,update,delete");
        filters(through="allowAjaxOnly", only="quickUpdate,liveSearch");
    }

    // REST-like action handling multiple HTTP methods
    function user() {
        if (isGet()) {
            // GET /users/123 - Show user
            user = model("User").findByKey(params.key);
            if (!IsObject(user)) {
                renderView(template="errors/404");
                return;
            }

        } else if (isPut() || isPatch()) {
            // PUT/PATCH /users/123 - Update user
            user = model("User").findByKey(params.key);
            if (IsObject(user) && user.update(params.user)) {
                if (isAjax()) {
                    renderWith(data={success=true, user=user});
                } else {
                    flashInsert(success="User updated successfully");
                    redirectTo(route="user", key=user.id);
                }
            } else {
                if (isAjax()) {
                    renderWith(data={success=false, errors=user.allErrors()});
                } else {
                    renderView(action="edit");
                }
            }

        } else if (isDelete()) {
            // DELETE /users/123 - Delete user
            user = model("User").findByKey(params.key);
            if (IsObject(user) && user.delete()) {
                if (isAjax()) {
                    renderWith(data={success=true});
                } else {
                    flashInsert(success="User deleted successfully");
                    redirectTo(action="index");
                }
            }

        } else {
            // Method not allowed
            if (isAjax()) {
                renderWith(data={error="Method not allowed"}, status=405);
            } else {
                flashInsert(error="Invalid request method");
                redirectTo(action="index");
            }
        }
    }

    // AJAX-specific actions
    function liveSearch() {
        if (!isAjax()) {
            renderWith(data={error="AJAX requests only"}, status=400);
            return;
        }

        local.query = params.q ?: "";
        if (Len(local.query) >= 3) {
            results = model("User").findAll(
                where="firstName LIKE '%#local.query#%' OR lastName LIKE '%#local.query#%'",
                select="id,firstName,lastName,email",
                maxRows=10
            );
        } else {
            results = QueryNew("id,firstName,lastName,email");
        }

        renderWith(data={results=results}, format="json");
    }

    // Quick AJAX update
    function quickUpdate() {
        if (!isAjax() || !isPost()) {
            renderWith(data={error="AJAX POST requests only"}, status=400);
            return;
        }

        user = model("User").findByKey(params.key);
        if (IsObject(user)) {
            // Update single field
            local.field = params.field;
            local.value = params.value;

            if (ListFindNoCase("firstName,lastName,email,active", local.field)) {
                user.update(#local.field#=local.value);

                if (user.valid()) {
                    renderWith(data={
                        success=true,
                        message="Updated successfully",
                        value=user[local.field]
                    });
                } else {
                    renderWith(data={
                        success=false,
                        errors=user.allErrors()
                    });
                }
            } else {
                renderWith(data={error="Field not allowed"}, status=400);
            }
        } else {
            renderWith(data={error="User not found"}, status=404);
        }
    }

    // API endpoint with method validation
    function api() {
        // Set JSON content type for all API responses
        if (isAjax() || Accept() contains "application/json") {
            provides("json");
        }

        if (isGet()) {
            // GET /api - List resources
            users = model("User").findAll(
                select="id,firstName,lastName,email,createdAt",
                order="createdAt DESC"
            );
            renderWith(data={users=users});

        } else if (isPost()) {
            // POST /api - Create resource
            user = model("User").create(params.user);

            if (user.valid()) {
                renderWith(data={user=user}, status=201);
            } else {
                renderWith(data={errors=user.allErrors()}, status=422);
            }

        } else if (isPut()) {
            // PUT /api/123 - Update resource
            user = model("User").findByKey(params.key);

            if (IsObject(user)) {
                if (user.update(params.user)) {
                    renderWith(data={user=user});
                } else {
                    renderWith(data={errors=user.allErrors()}, status=422);
                }
            } else {
                renderWith(data={error="User not found"}, status=404);
            }

        } else if (isDelete()) {
            // DELETE /api/123 - Delete resource
            user = model("User").findByKey(params.key);

            if (IsObject(user)) {
                user.delete();
                renderWith(data={success=true}, status=204);
            } else {
                renderWith(data={error="User not found"}, status=404);
            }

        } else if (isHead()) {
            // HEAD /api/123 - Check resource existence
            user = model("User").findByKey(params.key);
            local.status = IsObject(user) ? 200 : 404;

            cfheader(statusCode=local.status);
            abort;

        } else {
            // Method not allowed
            renderWith(data={error="Method not allowed"}, status=405);
        }
    }

    // Form handling with method detection
    function contact() {
        if (isGet()) {
            // Show contact form
            contact = model("Contact").new();

        } else if (isPost()) {
            // Process contact form
            contact = model("Contact").create(params.contact);

            if (contact.valid()) {
                // Send email
                sendEmail(
                    to="support@example.com",
                    subject="Contact Form: #contact.subject#",
                    template="contact/inquiry",
                    contact=contact
                );

                if (isAjax()) {
                    renderWith(data={success=true, message="Message sent successfully"});
                } else {
                    flashInsert(success="Thank you! Your message has been sent.");
                    redirectTo(action="new");
                }
            } else {
                if (isAjax()) {
                    renderWith(data={success=false, errors=contact.allErrors()});
                } else {
                    renderView(action="new");
                }
            }
        }
    }

    // Filter methods
    private function requirePOST() {
        if (!isPost()) {
            flashInsert(error="Invalid request method");
            redirectTo(action="index");
        }
    }

    private function allowAjaxOnly() {
        if (!isAjax()) {
            flashInsert(error="This action requires AJAX");
            redirectTo(action="index");
        }
    }

    // Content negotiation helper
    private function detectFormat() {
        if (isAjax() || cgi.http_accept contains "application/json") {
            return "json";
        } else if (cgi.http_accept contains "application/xml") {
            return "xml";
        } else {
            return "html";
        }
    }
}

// Advanced API controller
component extends="Controller" {
    function config() {
        // Enable method override for HTML forms
        filters(through="enableMethodOverride");
        provides("json,xml,html");
    }

    function resource() {
        local.format = detectFormat();

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
            default:
                renderWith(data={error="Method not supported"}, status=405);
        }
    }

    private function handleGet() {
        if (StructKeyExists(params, "key")) {
            // Show single resource
            resource = model("Resource").findByKey(params.key);
            renderWith(data={resource=resource});
        } else {
            // List resources
            resources = model("Resource").findAll();
            renderWith(data={resources=resources});
        }
    }

    private function handlePost() {
        resource = model("Resource").create(params.resource);

        if (resource.valid()) {
            renderWith(data={resource=resource}, status=201);
        } else {
            renderWith(data={errors=resource.allErrors()}, status=422);
        }
    }

    // Method override for HTML forms (which only support GET/POST)
    private function enableMethodOverride() {
        if (StructKeyExists(params, "_method") && isPost()) {
            // Override request method based on _method parameter
            request.wheels.originalMethod = cgi.request_method;

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

## Usage
1. Use method detection functions in controller actions for conditional logic
2. Implement REST-like endpoints that handle multiple HTTP methods
3. Create AJAX-specific actions with `isAjax()` validation
4. Build API endpoints with proper HTTP method support
5. Use filters to enforce method requirements

## Available Methods
- `isGet()` - Returns true if request method is GET
- `isPost()` - Returns true if request method is POST
- `isPut()` - Returns true if request method is PUT
- `isPatch()` - Returns true if request method is PATCH
- `isDelete()` - Returns true if request method is DELETE
- `isHead()` - Returns true if request method is HEAD
- `isAjax()` - Returns true if request is XMLHttpRequest (AJAX)

## Related
- [RESTful Resources](../core-concepts/routing/resources.md)
- [Rendering JSON](./rendering/json.md)
- [Controller Filters](./filters/before-after.md)

## Important Notes
- All methods return boolean true/false values
- `isAjax()` checks for XMLHttpRequest header
- Method detection works with method override techniques
- Use appropriate HTTP status codes in responses
- Consider security implications of method-based logic

## Common Patterns

### REST API Controller
```cfm
function restAction() {
    // Route: /api/users/123
    switch(true) {
        case isGet():
            renderWith(data=model("User").findByKey(params.key));
            break;
        case isPut():
            user = model("User").updateByKey(params.key, params.user);
            renderWith(data=user);
            break;
        case isDelete():
            model("User").deleteByKey(params.key);
            renderWith(data={success=true}, status=204);
            break;
        default:
            renderWith(data={error="Method not allowed"}, status=405);
    }
}
```

### Progressive Enhancement
```cfm
function update() {
    user = model("User").findByKey(params.key);

    if (user.update(params.user)) {
        if (isAjax()) {
            // AJAX response
            renderWith(data={success=true, user=user});
        } else {
            // Traditional form response
            flashInsert(success="User updated");
            redirectTo(route="user", key=user.id);
        }
    } else {
        if (isAjax()) {
            renderWith(data={success=false, errors=user.allErrors()});
        } else {
            renderView(action="edit");
        }
    }
}
```

### API Versioning
```cfm
function api() {
    local.version = getAPIVersion();

    if (isGet()) {
        switch(local.version) {
            case "v1":
                renderWith(data=getLegacyData());
                break;
            case "v2":
                renderWith(data=getEnhancedData());
                break;
            default:
                renderWith(data={error="API version not supported"}, status=400);
        }
    }
}
```

## Security Considerations
- Validate HTTP methods for sensitive operations
- Use CSRF protection for state-changing methods (POST, PUT, DELETE)
- Implement proper authentication for API endpoints
- Consider rate limiting for different request types
- Log suspicious method usage patterns