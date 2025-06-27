# Wheels Framework Examples

This directory contains example applications demonstrating common patterns and best practices for building applications with the Wheels framework.

## Examples

### 1. Blog Application (`/blog-app`)
A complete blog application demonstrating:
- User authentication and authorization
- CRUD operations for posts and comments
- Model associations (User hasMany Posts, Post hasMany Comments)
- Form handling and validation
- Pagination and search functionality
- File uploads for featured images

### 2. API Example (`/api-example`)
A RESTful API implementation showing:
- Token-based authentication
- JSON request/response handling
- API versioning
- Rate limiting
- Error handling and status codes
- OpenAPI/Swagger documentation

### 3. Authentication System (`/authentication`)
A complete authentication system featuring:
- User registration with email confirmation
- Login/logout functionality
- Password reset via email
- Remember me functionality
- OAuth integration examples
- Two-factor authentication

## Running the Examples

Each example includes its own README with specific setup instructions. You have two options:

### Option 1: Using Docker (Recommended for Testing)

The easiest way to test examples is using Docker containers:

1. Navigate to the example directory: `cd examples/blog-app`
2. Run with Wheels CLI: `wheels docker:test`
   - Or specify engine/database: `wheels docker:test --engine=adobe@2021 --db=mysql`
   - Use `--port=8081` to change the default port (8080)
3. Access the application at http://localhost:8080

**Without Wheels CLI:**
```bash
cd examples/blog-app
../../tools/docker/test-template.sh --engine=lucee@6 --db=postgres
```

**Docker Commands:**
- View logs: `wheels docker:test:logs --follow`
- Stop containers: `wheels docker:test:stop`
- Clean up: `wheels docker:test:clean`

### Option 2: Traditional Setup

1. Navigate to the example directory
2. Copy the example to your workspace: `cp -r examples/blog-app ../workspace/`
3. Install dependencies: `box install`
4. Configure your database in `config/settings.cfm`
5. Run migrations: `wheels dbmigrate latest`
6. Start the server: `server start`

## Learning Path

1. **Start with Authentication**: Learn the basics of user management
2. **Move to Blog App**: Understand CRUD operations and associations
3. **Explore the API**: Learn about building RESTful services

## Contributing

Feel free to submit additional examples via pull requests. Examples should:
- Demonstrate best practices
- Include comprehensive comments
- Have complete test coverage
- Include setup documentation