# TestBox Integration Optimization for CFWheels 3.0

## Executive Summary

CFWheels 3.0 is transitioning from RocketUnit to TestBox as its testing framework. This document analyzes the current integration state and provides actionable recommendations to optimize the testing experience for developers, making it more enjoyable, efficient, and maintainable.

## Current State Analysis

### 1. Mixed Testing Paradigms
The codebase currently shows a hybrid approach:
- Legacy tests extend `tests.Test` which inherits from `wheels.Test` (RocketUnit wrapper)
- Tests use RocketUnit-style `assert()` methods instead of TestBox's BDD syntax
- TestBox is installed but underutilized
- Separate directory structures for old and new tests

### 2. Directory Structure Issues
```
tests/
├── Test.cfc (RocketUnit base)
├── functions/ (RocketUnit tests)
├── requests/ (RocketUnit tests)
└── Testbox/
    ├── runner.cfm
    └── specs/
        └── api/ (TestBox tests)
```

This dual structure creates confusion and inconsistency.

### 3. Limited TestBox Feature Usage
- No use of TestBox's BDD syntax (`describe`, `it`, `expect`)
- Missing lifecycle hooks (`beforeEach`, `afterEach`)
- No test suites or spec organization
- Limited reporter usage

## Optimization Recommendations

### 1. Unified Test Structure

#### Recommended Directory Layout
```
tests/
├── BaseSpec.cfc (New TestBox base class)
├── runner.cfm (TestBox runner)
├── specs/
│   ├── unit/
│   │   ├── models/
│   │   ├── helpers/
│   │   └── libraries/
│   ├── integration/
│   │   ├── controllers/
│   │   ├── routing/
│   │   └── api/
│   └── functional/
│       ├── features/
│       └── workflows/
├── fixtures/
│   ├── data/
│   └── mocks/
└── support/
    ├── factories/
    └── helpers/
```

### 2. Enhanced Base Test Class

Create a new `BaseSpec.cfc` that bridges Wheels and TestBox:

```cfc
component extends="testbox.system.BaseSpec" {
    
    // Wheels application reference
    property name="app" inject="wirebox:CFWheels";
    
    function beforeAll() {
        // Store original application state
        variables.originalApplication = duplicate(application);
        
        // Set testing mode
        request.isTestingMode = true;
        
        // Initialize test database if needed
        if (structKeyExists(url, "resetdb") && url.resetdb) {
            resetTestDatabase();
        }
    }
    
    function afterAll() {
        // Restore original application state
        application = variables.originalApplication;
        request.isTestingMode = false;
    }
    
    function aroundEach(spec) {
        // Start transaction
        transaction {
            try {
                // Run the spec
                arguments.spec();
            } catch (any e) {
                transaction action="rollback";
                rethrow;
            }
            // Always rollback to keep tests isolated
            transaction action="rollback";
        }
    }
    
    // Wheels-specific helpers
    function controller(required string name) {
        return application.wo.controller(arguments.name);
    }
    
    function model(required string name) {
        return application.wo.model(arguments.name);
    }
    
    function params(struct params = {}) {
        request.wheels.params = arguments.params;
        return request.wheels.params;
    }
    
    // Authentication helpers
    function loginAs(required numeric userId) {
        var user = model("User").findByKey(arguments.userId);
        session.user = {
            id: user.id,
            properties: user.properties()
        };
        return user;
    }
    
    function logout() {
        structDelete(session, "user");
    }
    
    // Request helpers
    function processRequest(
        required string route,
        string method = "GET",
        struct params = {},
        struct headers = {}
    ) {
        var result = {};
        
        // Set up request context
        cgi.request_method = arguments.method;
        
        // Merge params
        structAppend(form, arguments.params);
        structAppend(url, arguments.params);
        
        // Process through Wheels
        savecontent variable="result.output" {
            result.controller = application.wo.dispatch(argumentCollection=arguments);
        }
        
        return result;
    }
    
    // Factory helpers
    function create(required string factoryName, struct attributes = {}) {
        return application.factories.create(arguments.factoryName, arguments.attributes);
    }
    
    function build(required string factoryName, struct attributes = {}) {
        return application.factories.build(arguments.factoryName, arguments.attributes);
    }
}
```

### 3. Migration Strategy

#### A. Assertion Mapping Helper
Create a migration helper to convert RocketUnit assertions to TestBox:

```cfc
// MigrationHelper.cfc
component {
    
    function migrateTestFile(required string filePath) {
        var content = fileRead(arguments.filePath);
        
        // Replace extends
        content = replace(content, 'extends="tests.Test"', 'extends="tests.BaseSpec"', "all");
        
        // Wrap test methods in describe/it blocks
        content = reFindReplace(content, 
            'function\s+(Test_[^(]+)\s*\([^)]*\)\s*{([^}]+)}',
            'describe("\1", () => {
                it("should pass", () => {\2
                });
            });'
        );
        
        // Convert assertions
        var mappings = [
            {from: 'assert\("([^"]+)"\)', to: 'expect(\1).toBeTrue()'},
            {from: 'assert\("!([^"]+)"\)', to: 'expect(\1).toBeFalse()'},
            {from: 'assert\("([^"]+)\s*==\s*([^"]+)"\)', to: 'expect(\1).toBe(\2)'},
            {from: 'assert\("structKeyExists\(([^,]+),\s*''([^'']+)''\)"\)', to: 'expect(\1).toHaveKey("\2")'}
        ];
        
        for (var mapping in mappings) {
            content = reReplace(content, mapping.from, mapping.to, "all");
        }
        
        return content;
    }
}
```

#### B. Gradual Migration Approach
1. Create new TestBox tests alongside existing ones
2. Run both test suites during transition
3. Migrate one test file at a time
4. Remove old tests once migrated and verified

### 4. Developer Experience Improvements

#### A. Test Generators
Add Wheels CLI commands for test generation:

```bash
# Generate model test
wheels generate test model User

# Generate controller test  
wheels generate test controller Admin.Users

# Generate integration test
wheels generate test integration UserRegistration
```

Example generated test:

```cfc
component extends="tests.BaseSpec" {
    
    describe("User Model", () => {
        
        beforeEach(() => {
            variables.user = model("User").new();
        });
        
        describe("Validations", () => {
            it("requires email", () => {
                user.email = "";
                expect(user.valid()).toBeFalse();
                expect(user.errors()).toHaveKey("email");
            });
            
            it("validates email format", () => {
                user.email = "invalid-email";
                expect(user.valid()).toBeFalse();
            });
        });
        
        describe("Associations", () => {
            it("has many roles", () => {
                expect(user).toHaveMethod("roles");
            });
        });
        
        describe("Methods", () => {
            it("generates full name", () => {
                user.firstName = "John";
                user.lastName = "Doe";
                expect(user.fullName()).toBe("John Doe");
            });
        });
    });
}
```

#### B. VS Code Integration
Create `.vscode/cfwheels-test.code-snippets`:

```json
{
    "TestBox Spec": {
        "prefix": "tbspec",
        "body": [
            "component extends=\"tests.BaseSpec\" {",
            "\t",
            "\tdescribe(\"${1:Feature}\", () => {",
            "\t\t",
            "\t\tbeforeEach(() => {",
            "\t\t\t${2:// Setup}",
            "\t\t});",
            "\t\t",
            "\t\tit(\"${3:should do something}\", () => {",
            "\t\t\t${4:// Test implementation}",
            "\t\t\texpect(${5:actual}).toBe(${6:expected});",
            "\t\t});",
            "\t});",
            "}"
        ]
    },
    "Model Test": {
        "prefix": "tbmodel",
        "body": [
            "describe(\"${1:Model} Model\", () => {",
            "\t",
            "\tbeforeEach(() => {",
            "\t\tvariables.${2:model} = model(\"${1}\").new();",
            "\t});",
            "\t",
            "\tdescribe(\"Validations\", () => {",
            "\t\tit(\"validates required fields\", () => {",
            "\t\t\texpect(${2:model}.valid()).toBeFalse();",
            "\t\t});",
            "\t});",
            "});"
        ]
    }
}
```

#### C. Watch Mode for TDD
Add to `box.json` scripts:

```json
{
    "scripts": {
        "test": "testbox run",
        "test:watch": "testbox watch",
        "test:unit": "testbox run --directory=tests/specs/unit",
        "test:integration": "testbox run --directory=tests/specs/integration",
        "test:coverage": "testbox run --coverage --coverageReporter=html"
    }
}
```

### 5. CI/CD Integration

#### A. GitHub Actions Configuration
```yaml
name: Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        cfengine: ["lucee@5", "lucee@6", "adobe@2018", "adobe@2021"]
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup CommandBox
        uses: Ortus-Solutions/setup-commandbox@v2
        
      - name: Install Dependencies
        run: box install
        
      - name: Start Server
        run: box server start cfengine=${{ matrix.cfengine }}
        
      - name: Run Tests
        run: box testbox run --reporter=junit --outputFile=test-results.xml
        
      - name: Upload Test Results
        uses: actions/upload-artifact@v3
        with:
          name: test-results-${{ matrix.cfengine }}
          path: test-results.xml
```

#### B. Parallel Test Execution
Configure TestBox for parallel execution:

```cfc
// tests/runner.cfm
testbox = new testbox.system.TestBox(
    directory = "tests.specs",
    recurse = true,
    bundles = "",
    labels = "",
    options = {
        parallel = true,
        maxThreads = 4
    }
);
```

### 6. Testing Patterns Cookbook

#### A. Testing Controllers
```cfc
describe("UsersController", () => {
    
    beforeEach(() => {
        variables.controller = controller("Users");
        loginAs(1); // Admin user
    });
    
    describe("index action", () => {
        it("returns list of users", () => {
            var result = processRequest(route="users", method="GET");
            expect(result.controller.users).toBeArray();
            expect(arrayLen(result.controller.users)).toBeGT(0);
        });
        
        it("paginates results", () => {
            var result = processRequest(
                route="users", 
                method="GET",
                params={page: 2, perPage: 10}
            );
            expect(result.controller.pagination.currentPage).toBe(2);
        });
    });
});
```

#### B. Testing Models with Factories
```cfc
describe("SalesOrder", () => {
    
    it("calculates total from line items", () => {
        var order = create("salesOrder", {
            lineItems: [
                build("lineItem", {quantity: 2, unitPrice: 10}),
                build("lineItem", {quantity: 1, unitPrice: 15})
            ]
        });
        
        expect(order.calculateTotal()).toBe(35);
    });
    
    it("validates customer association", () => {
        var order = build("salesOrder", {customerID: ""});
        expect(order.valid()).toBeFalse();
        expect(order.errors()).toHaveKey("customerID");
    });
});
```

#### C. Testing API Endpoints
```cfc
describe("API v1 Sales Orders", () => {
    
    beforeEach(() => {
        variables.apiKey = create("apiKey");
        variables.headers = {
            "Authorization": "Bearer #apiKey.key#:#apiKey.secret#"
        };
    });
    
    it("creates sales order", () => {
        var payload = {
            customer_id: create("customer").id,
            line_items: [{
                part_number: "TEST-001",
                quantity: 5,
                unit_price: 10.99
            }]
        };
        
        var result = processRequest(
            route = "api.v1.salesOrders",
            method = "POST",
            params = {body: serializeJSON(payload)},
            headers = variables.headers
        );
        
        var response = deserializeJSON(result.output);
        expect(response.success).toBeTrue();
        expect(response.data).toHaveKey("id");
    });
});
```

### 7. Performance Optimization

#### A. Test Data Management
```cfc
component {
    
    // Shared test data loaded once
    function setupTestData() {
        if (!structKeyExists(application, "testData")) {
            application.testData = {
                users: queryExecute("SELECT * FROM users WHERE email LIKE '%test%'"),
                products: queryExecute("SELECT TOP 10 * FROM products")
            };
        }
    }
    
    // Fast data cleanup
    function cleanupTestData() {
        queryExecute("DELETE FROM sales_orders WHERE notes LIKE '%[TEST]%'");
        queryExecute("DELETE FROM users WHERE email LIKE '%test_%@example.com'");
    }
}
```

#### B. Smart Test Execution
```cfc
// Only run affected tests based on changed files
component {
    function getAffectedTests(changedFiles) {
        var tests = [];
        
        for (var file in arguments.changedFiles) {
            if (file contains "/models/") {
                arrayAppend(tests, "tests/specs/unit/models/#getFileFromPath(file)#");
            } else if (file contains "/controllers/") {
                arrayAppend(tests, "tests/specs/integration/controllers/#getFileFromPath(file)#");
            }
        }
        
        return tests;
    }
}
```

## Implementation Roadmap

### Phase 1: Foundation (Week 1-2)
1. Create new BaseSpec.cfc with Wheels integration
2. Set up new directory structure
3. Create first TestBox test as example
4. Document migration guide

### Phase 2: Tooling (Week 3-4)
1. Implement test generators
2. Add VS Code snippets
3. Configure watch mode
4. Set up CI pipeline

### Phase 3: Migration (Week 5-8)
1. Run migration helper on existing tests
2. Review and fix migrated tests
3. Update team on new patterns
4. Create video tutorials

### Phase 4: Optimization (Week 9-10)
1. Implement parallel execution
2. Add coverage reporting
3. Optimize test data management
4. Performance profiling

## Conclusion

By following these recommendations, CFWheels 3.0 can provide a modern, enjoyable testing experience that:
- Leverages TestBox's full capabilities
- Maintains backward compatibility during transition
- Improves developer productivity
- Ensures consistent test patterns
- Enables better CI/CD integration

The key is gradual adoption with clear migration paths and comprehensive tooling support.