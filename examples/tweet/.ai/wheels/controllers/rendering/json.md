# JSON Rendering

## Description
Render JSON responses for API endpoints and AJAX requests using Wheels' built-in serialization.

## Key Points
- Use `renderWith()` method for automatic format detection
- Use `provides()` in config to specify supported formats
- Automatic JSON serialization of objects and queries
- Support for custom serialization and error responses
- Content-type headers set automatically

## Code Sample
```cfm
component extends="Controller" {
    function config() {
        // Specify supported formats
        provides("html,json,xml");

        // JSON-only endpoints
        filters(through="setJsonFormat", only="api");
    }

    function index() {
        users = model("User").findAll();

        // Automatic format detection from URL or Accept header
        // /users.json or Accept: application/json
        renderWith(users);
    }

    function show() {
        user = model("User").findByKey(params.key);

        if (IsObject(user)) {
            renderWith(user);
        } else {
            // JSON error response
            renderWith(data={error: "User not found"}, status=404);
        }
    }

    function create() {
        user = model("User").new(params.user);

        if (user.save()) {
            // Return created object with 201 status
            renderWith(user, status=201);
        } else {
            // Return validation errors
            renderWith(data={errors: user.allErrors()}, status=422);
        }
    }

    // API-specific actions
    function api() {
        data = {
            version: "1.0",
            timestamp: Now(),
            users: model("User").findAll(select="id,firstName,lastName")
        };

        renderWith(data);
    }

    // Custom JSON formatting
    function customFormat() {
        users = model("User").findAll();
        formattedData = {
            success: true,
            count: users.recordCount,
            data: users
        };

        renderWith(formattedData);
    }

    private function setJsonFormat() {
        params.format = "json";
    }
}
```

## Usage
1. Add `provides("json")` to controller config
2. Use `renderWith(data)` for automatic format detection
3. Access via `.json` extension or Accept header
4. Include status codes for proper HTTP responses
5. Handle errors with appropriate JSON structure

## Related
- [Rendering Views](./views.md)
- [API Development](../../patterns/api-development.md)
- [Multiple Formats](../responding-with-multiple-formats.md)

## Important Notes
- `renderWith()` handles format detection automatically
- Status codes important for API consumers
- Use structured error responses with validation details
- JSON format available at `/action.json` or via Accept header
- Objects and queries serialized automatically