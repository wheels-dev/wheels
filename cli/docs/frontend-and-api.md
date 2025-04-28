# Frontend and API Development Commands

The Wheels CLI provides commands to help integrate modern frontend frameworks and build API endpoints in your application.

## Frontend Integration

Modern web applications often use JavaScript frontend frameworks. The Wheels CLI provides tools to scaffold and integrate popular frontend frameworks with your Wheels application.

### Generate Frontend

Scaffold and integrate modern frontend frameworks with Wheels.

#### Usage

```bash
wheels generate frontend --framework=[framework] [--path=app/assets/frontend] [--api=false]
```

#### Parameters

- `framework`: Frontend framework to use (react, vue, alpine) (required)
- `path`: Directory to install frontend (default: app/assets/frontend)
- `api`: Generate API endpoint for frontend (default: false)

#### Examples

```bash
# Generate a React frontend
wheels generate frontend --framework=react

# Generate a Vue.js frontend with API support
wheels generate frontend --framework=vue --api=true

# Generate an Alpine.js frontend in a custom directory
wheels generate frontend --framework=alpine --path=app/js/frontend
```

### What Gets Generated

The frontend generator creates:

1. **Project Structure**: Directory structure for the selected framework
2. **Dependencies**: package.json with appropriate dependencies
3. **Build Configuration**: Vite configuration for modern build process
4. **Asset Pipeline**: Integration helpers for including built assets in Wheels views
5. **Example Components**: Sample components to help you get started
6. **Optional API**: API endpoints if the `--api` flag is enabled

### Frontend Framework Options

#### React

When selecting React, the generator creates:

- React components with hooks
- React DOM setup
- CSS modules configuration
- Hot module replacement for development

#### Vue.js

When selecting Vue.js, the generator creates:

- Vue 3 components with Composition API
- Vue application setup
- Single-file component structure
- CSS scoping

#### Alpine.js

When selecting Alpine.js, the generator creates:

- Alpine.js directives and components
- Minimal build setup (Alpine.js is more lightweight)
- CSS integration

## API Development

Modern applications often need to expose data via APIs. The Wheels CLI provides tools to build RESTful API endpoints.

### Generate API Resource

Creates RESTful API controller and supporting files.

#### Usage

```bash
wheels generate api-resource [name] [--model=false] [--docs=false] [--auth=false]
```

#### Parameters

- `name`: Name of the API resource (singular or plural, required)
- `model`: Generate associated model (default: false)
- `docs`: Generate API documentation template (default: false)
- `auth`: Include authentication checks (default: false)

#### Examples

```bash
# Generate a basic API resource
wheels generate api-resource users

# Generate an API resource with a model and documentation
wheels generate api-resource posts --model=true --docs=true

# Generate an API resource with authentication
wheels generate api-resource products --auth=true
```

### What Gets Generated

The API generator creates:

1. **API Controller**: Controller with RESTful actions (index, show, create, update, delete)
2. **JSON Responses**: Configured for proper JSON content negotiation
3. **Optional Model**: Associated model if the `--model` flag is enabled
4. **Documentation**: API documentation template if the `--docs` flag is enabled
5. **Authentication**: Authentication checks if the `--auth` flag is enabled

### API Response Formats

The generated API endpoints return standardized JSON responses:

#### Success Response (200 OK)

```json
{
  "users": [
    {
      "id": 1,
      "name": "John Doe",
      "email": "john@example.com"
    }
  ]
}
```

#### Error Response (422 Unprocessable Entity)

```json
{
  "error": "Validation failed",
  "errors": {
    "email": ["Email is invalid", "Email is already taken"]
  }
}
```

### API Documentation

If you enable the `--docs` flag, the generator creates Markdown documentation for your API endpoints, including:

- Endpoint URLs
- Request parameters
- Response formats
- Authentication requirements
- Example requests and responses

## Integrating Frontend with API

When using both frontend and API generators together, you can create a modern application architecture:

```bash
# Generate an API for users
wheels generate api-resource users --model=true --docs=true

# Generate a React frontend that consumes the API
wheels generate frontend --framework=react --api=true
```

This combination creates:

1. A RESTful API for the specified resource
2. A React frontend configured to consume the API
3. Documentation for how they work together

## Best Practices

### Frontend Development

1. **Component Organization**: Keep components small and focused
2. **State Management**: Use appropriate state management for your framework
3. **API Integration**: Use fetch or axios for API requests
4. **Asset Pipeline**: Use the provided asset pipeline for production builds

### API Development

1. **RESTful Design**: Follow REST principles for URL structure and HTTP methods
2. **Versioning**: Consider versioning your APIs (e.g., /api/v1/users)
3. **Authentication**: Implement proper authentication for protected endpoints
4. **Validation**: Validate all input data before processing
5. **Documentation**: Keep API documentation up-to-date