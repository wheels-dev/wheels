# wheels generate test

Generate test files for models, controllers, views, and other components using TestBox BDD syntax.

## Synopsis

```bash
wheels generate test [type] [target] [options]
wheels g test [type] [target] [options]
```

## Description

The `wheels generate test` command creates test files for various components of your Wheels application. It generates comprehensive test scaffolding with TestBox BDD syntax and includes common test patterns to get you started.

## Arguments

| Argument | Description | Default |
|----------|-------------|---------|
| `type` | Type of test: `model`, `controller`, `view`, `unit`, `integration`, `api` | Required |
| `target` | Name of the component/object to test | Required |

## Options

| Option | Description | Default |
|--------|-------------|---------|
| `--name` | Name of the view (required for view tests) | `""` |
| `--crud` | Generate CRUD test methods | `false` |
| `--mock` | Generate mock objects and stubs | `false` |
| `--factory` | Generate factory examples for test data | `false` |
| `--open` | Open the created file in default editor | `false` |

## Examples

### Model Test
```bash
wheels generate test model Product
```

Creates `/tests/specs/unit/models/ProductSpec.cfc` with TestBox BDD syntax:

```cfc
component extends="wheels.Testbox" {

    function run() {

        describe("Product Model", () => {

            beforeEach(() => {
                variables.product = model("Product").new();
            });

            describe("Validations", () => {
                it("should validate required fields", () => {
                    expect(product.valid()).toBeFalse();
                    // Add specific field validations here
                });
            });

            describe("Associations", () => {
                // Test your model associations here
                it("should have expected associations", () => {
                    // Example: expect(product).toHaveMethod("orders");
                });
            });

            describe("Methods", () => {
                // Test custom model methods here
            });

        });
    }
}
```

### Controller Test
```bash
wheels generate test controller Products
```

Creates `/tests/specs/integration/controllers/ProductsControllerSpec.cfc` with TestBox BDD syntax.

### View Test
```bash
wheels generate test view products --name=index
```

Creates `/tests/specs/unit/views/products/indexViewSpec.cfc` with TestBox BDD syntax.

### CRUD Tests
```bash
wheels generate test controller Products --crud
```

Generates complete CRUD test methods using TestBox BDD syntax with describe/it blocks for index, show, create, update, and delete actions.

### Unit Test
```bash
wheels generate test unit UserService
```

Creates `/tests/specs/unit/helpers/UserServiceSpec.cfc` for testing service layer components.

### Integration Test
```bash
wheels generate test integration OrderWorkflow --factory
```

Creates `/tests/specs/integration/workflows/OrderWorkflowIntegrationSpec.cfc` with end-to-end workflow testing.

### API Test
```bash
wheels generate test api Users --crud --mock
```

Creates `/tests/specs/integration/api/UsersAPISpec.cfc` with API endpoint testing including authentication, CRUD operations, and error handling.

### Mock Objects
```bash
wheels generate test controller Users --mock
```

Adds mock object setup to controller tests for external service dependencies.

### Factory Support
```bash
wheels generate test model Product --factory --crud
```

Generates test with factory pattern for creating test data objects.

## Running Tests

Run the generated tests using the TestBox test runner:

```bash
wheels test run
```

Or run specific test files:

```bash
wheels test run --testBundles=ProductSpec
```

## Test Types

The command generates different test structures based on the type:

| Type | Location | Purpose |
|------|----------|---------|
| `model` | `/tests/specs/unit/models/` | Model validations, associations, methods |
| `controller` | `/tests/specs/integration/controllers/` | Controller actions, filters, authentication |
| `view` | `/tests/specs/unit/views/` | Template rendering, data display |
| `unit` | `/tests/specs/unit/helpers/` | Service classes, utility functions |
| `integration` | `/tests/specs/integration/workflows/` | End-to-end user workflows |
| `api` | `/tests/specs/integration/api/` | API endpoints, authentication, JSON responses |

## Generated Test Features

- **TestBox BDD Syntax**: Modern `describe()` and `it()` syntax
- **Automatic Setup/Teardown**: `beforeEach()` and `afterEach()` hooks
- **CRUD Operations**: Complete create, read, update, delete test cases
- **Mock Objects**: Stubs for external dependencies
- **Factory Support**: Test data creation patterns
- **Error Handling**: Validation and edge case testing

## See Also

- [wheels test run](../test/test-run.md) - Run tests
- [Testing Guide](../../../working-with-wheels/testing-your-application.md) - Testing documentation