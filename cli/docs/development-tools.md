# Development Tools

The Wheels CLI provides a comprehensive set of tools to speed up the development process by generating code for common components.

## Generate Controller

Generates a controller with optional actions.

### Usage

```bash
wheels generate controller [name] [actions]
```

### Parameters

- `name`: Name of the controller (required)
- `actions`: Comma-delimited list of actions to generate (optional)

### Examples

```bash
# Generate a basic controller
wheels generate controller users

# Generate a controller with specific actions
wheels generate controller users index,show,create,update,delete
```

## Generate Model

Generates a model with optional properties.

### Usage

```bash
wheels generate model [name] [properties]
```

### Parameters

- `name`: Name of the model (required)
- `properties`: Comma-delimited list of properties to generate (optional)

### Examples

```bash
# Generate a basic model
wheels generate model user

# Generate a model with specific properties
wheels generate model user firstName:string,lastName:string,email:string,isAdmin:boolean
```

## Generate View

Generates a view for a specific controller action.

### Usage

```bash
wheels generate view [controller] [action]
```

### Parameters

- `controller`: Name of the controller (required)
- `action`: Name of the action (required)

### Examples

```bash
# Generate a view for a specific controller action
wheels generate view users show
```

## Generate Property

Generates a property for an existing model.

### Usage

```bash
wheels generate property [name] [type] [default] [null] [limit] [model]
```

### Parameters

- `name`: Name of the property (required)
- `type`: Data type of the property (string, text, integer, float, boolean, date, datetime, time)
- `default`: Default value for the property
- `null`: Allow NULL values (true/false)
- `limit`: Character limit for the property
- `model`: Model to add the property to

### Examples

```bash
# Generate a simple property
wheels generate property email string model=user

# Generate a property with constraints
wheels generate property age integer default=18 null=false model=user
```

## Generate API Resource

Creates RESTful API controller and supporting files.

### Usage

```bash
wheels generate api-resource [name] [--model=false] [--docs=false] [--auth=false]
```

### Parameters

- `name`: Name of the API resource (singular or plural, required)
- `model`: Generate associated model (default: false)
- `docs`: Generate API documentation template (default: false)
- `auth`: Include authentication checks (default: false)

### Examples

```bash
# Generate a basic API resource
wheels generate api-resource users

# Generate an API resource with a model and documentation
wheels generate api-resource posts --model=true --docs=true

# Generate an API resource with authentication
wheels generate api-resource products --auth=true
```

## Generate Frontend

Scaffold and integrate modern frontend frameworks with Wheels.

### Usage

```bash
wheels generate frontend --framework=[framework] [--path=app/assets/frontend] [--api=false]
```

### Parameters

- `framework`: Frontend framework to use (react, vue, alpine) (required)
- `path`: Directory to install frontend (default: app/assets/frontend)
- `api`: Generate API endpoint for frontend (default: false)

### Examples

```bash
# Generate a React frontend
wheels generate frontend --framework=react

# Generate a Vue.js frontend with API support
wheels generate frontend --framework=vue --api=true

# Generate an Alpine.js frontend in a custom directory
wheels generate frontend --framework=alpine --path=app/js/frontend
```

## Scaffold

Generates complete CRUD functionality for a resource, including model, controller, views, and routes.

### Usage

```bash
wheels scaffold [name] [properties]
```

### Parameters

- `name`: Name of the resource (required)
- `properties`: Comma-delimited list of properties to generate (optional)

### Examples

```bash
# Generate a basic scaffold
wheels scaffold user

# Generate a scaffold with specific properties
wheels scaffold post title:string,body:text,published:boolean,publishedAt:datetime
```

## Notes

### Property Types

When specifying properties, the following types are supported:

- `string`: Short text
- `text`: Long text
- `integer`: Whole numbers
- `float`: Decimal numbers
- `boolean`: True/false values
- `date`: Date only
- `datetime`: Date and time
- `time`: Time only
- `timestamp`: Date and time with timezone
- `binary`: Binary data
- `uuid`: Universally unique identifier

### API Resource Generation

The API resource generation creates:

1. A controller with RESTful actions (index, show, create, update, delete)
2. An optional model if requested
3. Optional API documentation in Markdown format
4. Optional authentication hooks if requested

### Frontend Integration

The frontend integration provides:

1. Project structure for the selected framework
2. Package.json with appropriate dependencies
3. Vite build configuration
4. Integration helpers for including the frontend in Wheels views
5. Sample application structure