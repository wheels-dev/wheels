# Wheels CLI Test Suite

This directory contains the comprehensive test suite for the Wheels CLI module.

## Structure

```
tests/
├── Application.cfc         # Test application configuration
├── BaseTestCase.cfc       # Base test class with utilities
├── AllTests.cfc          # Main test suite runner
├── test-runner.cfm       # Web-based test runner
├── specs/               # Test specifications
│   ├── commands/       # Unit tests for commands
│   ├── services/       # Unit tests for services
│   └── integration/    # Integration tests
├── mocks/              # Mock objects for testing
└── helpers/            # Test helper utilities
```

## Running Tests

### Command Line

```bash
# Run all tests
box testbox run

# Run specific directory
box testbox run --directory=tests.specs.commands

# Run specific test bundle
box testbox run --testBundles=tests.specs.commands.create.ModelCommandSpec

# Run with coverage
box testbox run --coverage --coverageReporter=html
```

### Browser

Navigate to: `http://localhost:8080/tests/test-runner.cfm`

Options:
- `?directory=tests.specs.services` - Run only service tests
- `?reporter=json` - Get JSON output
- `?reporter=junit` - Get JUnit XML output

### Watch Mode

```bash
# Watch for changes and re-run tests
box testbox watch
```

## Writing Tests

### Command Tests

Create a test spec extending `BaseTestCase`:

```cfc
component extends="tests.BaseTestCase" {
    
    function beforeAll() {
        super.beforeAll();
        variables.commandPath = "create model";
    }
    
    function run() {
        describe("wheels create model", function() {
            
            beforeEach(function() {
                createTestProject();
            });
            
            it("should create a model file", function() {
                var result = executeCommand(commandPath, {
                    name = "User"
                });
                
                expect(result.success).toBeTrue();
                assertFileCreated("app/models/User.cfc");
            });
        });
    }
}
```

### Service Tests

Test services directly:

```cfc
component extends="tests.BaseTestCase" {
    
    function beforeAll() {
        super.beforeAll();
        variables.service = createObject("component", "models.MyService").init();
    }
    
    function run() {
        describe("MyService", function() {
            it("should perform operation", function() {
                var result = variables.service.doSomething();
                expect(result).toBeTrue();
            });
        });
    }
}
```

### Integration Tests

Test complete workflows:

```cfc
component extends="tests.BaseTestCase" {
    
    function run() {
        describe("Complete Workflow", function() {
            it("should create app and scaffold", function() {
                executeCommand("create app", {name = "testapp"});
                directoryChange(getTempDir() & "testapp");
                
                executeCommand("create scaffold", {
                    name = "Product",
                    attributes = "name:string,price:decimal"
                });
                
                assertFileCreated("app/models/Product.cfc");
                assertFileCreated("app/controllers/Products.cfc");
            });
        });
    }
}
```

## Test Utilities

### BaseTestCase Methods

- `executeCommand(command, params)` - Execute a CLI command
- `createTestProject(path)` - Create minimal project structure
- `assertFileCreated(path)` - Assert file exists
- `assertDirectoryCreated(path)` - Assert directory exists
- `assertOutputContains(text)` - Assert output contains text
- `assertOutputMatches(pattern)` - Assert output matches regex
- `mockUserInput(inputs)` - Mock user input for prompts
- `getOutput()` - Get captured output as string
- `getTempDir()` - Get temporary test directory

### Mock Objects

The test suite includes mocks for:
- WireBox (dependency injection)
- Print utilities (output capture)
- File system operations
- User input
- Command execution

### Test Helpers

Available helpers in `tests/helpers/TestHelpers.cfc`:
- `createMinimalProject()` - Create minimal project
- `createTestModel()` - Create test model file
- `createTestController()` - Create test controller
- `createTestMigration()` - Create test migration
- `waitForFile()` - Wait for async file creation
- `assertFileContainsAll()` - Assert file contains multiple strings

## Coverage

Generate coverage reports:

```bash
# HTML report
box testbox run --coverage --coverageReporter=html --coverageOutputDir=tests/coverage

# SonarQube report
box testbox run --coverage --coverageReporter=sonarqube
```

## Best Practices

1. **Isolation**: Each test should be independent
2. **Cleanup**: Use `beforeEach`/`afterEach` for setup/teardown
3. **Mocking**: Use provided mocks to avoid external dependencies
4. **Assertions**: Use descriptive assertion messages
5. **Organization**: Group related tests with `describe` blocks
6. **Performance**: Use `createTestProject()` for faster setup
7. **Debugging**: Use `debug()` to output values during test runs

## Troubleshooting

### Tests failing with "directory not found"
Ensure `beforeEach()` calls `createTestProject()`

### Mock not working
Check that command is properly injected with mocks in `injectMocks()`

### Output not captured
Ensure command uses `print` utilities, not direct `writeOutput()`

### File assertions failing
Use `getTempDir()` for proper path resolution