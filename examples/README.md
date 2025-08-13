# Wheels Examples

This directory contains example applications that demonstrate how to use the Wheels framework effectively.

## Available Examples

### Starter App (`starter-app/`)

A complete, production-ready starter application that showcases best practices for building applications with Wheels. This example includes:

- **Modern Architecture**: Clean separation of concerns with MVC pattern
- **Database Integration**: Complete model setup with migrations
- **RESTful API**: Example endpoints following REST conventions
- **Testing Suite**: Comprehensive test coverage with TestBox

#### Getting Started with Starter App

1. **Prerequisites**: Ensure you have CommandBox CLI installed
2. **Install Dependencies**:

   ```bash
   cd starter-app
   box install
   ```

3. **Start the Server**:

   ```bash
   box server start
   ```

4. **Access the Application**: Open <http://localhost:8081> in your browser

#### Key Features Demonstrateds

- Database migrations and seeding
- RESTful API endpoints
- Form handling and validation
- Authentication and authorization
- Asset pipeline (CSS/JS compilation)
- Error handling and logging
- Environment configuration
- Testing patterns and best practices

### Additional Examples

Looking for more examples? Check out our [documentation](https://wheels.dev/docs) for additional tutorials and guides.

## Contributing

Have an example you'd like to share? We welcome contributions! Please see our [contributing guidelines](../CONTRIBUTING.md) for details on how to submit your examples.
