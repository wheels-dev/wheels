# Testing Your Application

This guide provides comprehensive instructions for testing your Wheels 3.0 application using TestBox 5. Wheels 3.0 now includes TestBox integration as an enabled option, moving beyond the legacy RocketUnit framework. TestBox is already included in your installation through box.json dependency management.

## Overview

TestBox 5 is a next-generation testing framework for ColdFusion (CFML) based on BDD (Behavior Driven Development) and TDD (Test Driven Development), providing a clean, obvious syntax for writing tests. It serves as a comprehensive testing engine with multi-format output capabilities and database testing support.

For comprehensive TestBox documentation, refer to the [official TestBox documentation](https://testbox.ortusbooks.com/).

### TestBox Features

- BDD style or xUnit style testing
- Testing life-cycle methods
- MockBox integration for mocking and stubbing
- Extensible reporters (JSON, XML, JUnit XML, Text, Console, TAP, HTML)
- Asynchronous testing
- Multi-suite capabilities
- Test skipping and labels
- Code coverage via FusionReactor

For a complete list of features, see the [TestBox Features documentation](https://testbox.ortusbooks.com/v5.x/overview/features).

## Project Directory Structure

Based on real Wheels 3.0 projects, your test structure should be organized as follows:

```
your-app/
├── app/
│   ├── controllers/
│   ├── models/
│   └── views/
├── config/
├── public/
├── tests/
│   └── Testbox/
│       ├── specs/
│       │   ├── controllers/
│       │   │   ├── ExampleControllerSpec.cfc
│       │   │   ├── PostControllerSpec.cfc
│       │   │   └── [Other Controller Tests]
│       │   └── functions/
│       │       └── ExampleSpec.cfc
│       ├── _assets/
│       ├── runner.cfm
│       └── populate.cfm
```

**Note**: The directory uses `tests/Testbox/` (capital T) as shown in real implementations, not the lowercase `testbox`.

## TestBox Test Runner Configuration

### Main Test Runner

Update `tests/Testbox/runner.cfm`:

For detailed information on TestBox runners and configuration options, refer to the [TestBox Runners documentation](https://testbox.ortusbooks.com/v5.x/getting-started/running-tests).

```cfscript
<!--- TestBox Test Runner for Wheels 3.0 --->
<cfscript>
    // Environment backup and configuration
    backupApplicationScope = duplicate(application);
    
    // URL parameters for test configuration
    param name="url.format" default="html";          // json, txt, junit, html
    param name="url.db" default="";                  // mysql, sqlserver, postgres, h2
    param name="url.populate" default="false";       // populate test data
    param name="url.reporter" default="simple";
    param name="url.directory" default="tests.Testbox.specs";
    param name="url.recurse" default="true";
    param name="url.bundles" default="";
    param name="url.labels" default="";
    param name="url.excludes" default="";
    
    // Database configuration for testing
    if (len(url.db)) {
        switch(url.db) {
            case "mysql":
                application.wheels.dataSourceName = "wheelstestdb_mysql";
                break;
            case "sqlserver":
                application.wheels.dataSourceName = "wheelstestdb_sqlserver"; 
                break;
            case "postgres":
                application.wheels.dataSourceName = "wheelstestdb_postgres";
                break;
            case "h2":
                application.wheels.dataSourceName = "wheelstestdb_h2";
                break;
        }
    }
    
    // Populate test database if requested
    if (url.populate) {
        include "populate.cfm";
    }
    
    // CSRF token handling for security testing
    if (!structKeyExists(session, "csrf_token")) {
        session.csrf_token = createUUID();
    }
    
    // Configure test paths
    request.wheels.testControllerPath = "/app/controllers/";
    request.wheels.testViewPath = "/app/views/";
    request.wheels.testModelPath = "/app/models/";
    request.wheels.testAssetPath = "/tests/Testbox/_assets/";
</cfscript>

<!--- Output format handling --->
<cfswitch expression="#url.format#">
    <cfcase value="json">
        <cfheader name="Content-Type" value="application/json">
        <cfinclude template="/testbox/system/runners/JSONRunner.cfm">
    </cfcase>
    <cfcase value="txt">
        <cfheader name="Content-Type" value="text/plain">
        <cfinclude template="/testbox/system/runners/TextRunner.cfm">
    </cfcase>
    <cfcase value="junit">
        <cfheader name="Content-Type" value="application/xml">
        <cfinclude template="/testbox/system/runners/JUnitRunner.cfm">
    </cfcase>
    <cfdefaultcase>
        <!--- HTML Runner (default) --->
        <cfinclude template="/testbox/system/runners/HTMLRunner.cfm">
    </cfdefaultcase>
</cfswitch>

<cfscript>
    // Restore original application state after tests
    application = backupApplicationScope;
</cfscript>
```

### Test Data Population

Update `tests/Testbox/populate.cfm` for test database setup:

```cfscript
<cfscript>
    // Populate test database with sample data
    try {
        // Create test users
        testUser = model("User").create({
            username: "testuser",
            email: "test@example.com",
            password: "password123",
            firstName: "Test",
            lastName: "User"
        });
        
        // Create test blog posts
        testPost = model("Post").create({
            title: "Test Blog Post",
            content: "This is a test blog post content.",
            userId: testUser.id,
            published: true
        });
        
        // Create test community content
        testCommunityPost = model("CommunityPost").create({
            title: "Test Community Post",
            content: "Community test content",
            userId: testUser.id
        });
        
        writeOutput("Test data populated successfully.<br>");
        
    } catch (any e) {
        writeOutput("Error populating test data: " & e.message & "<br>");
    }
</cfscript>
```

## Writing Controller Tests

TestBox 5 test bundles should extend `testbox.system.BaseSpec` and use BDD syntax with `describe()`, `it()`, and `expect()`.

For comprehensive information on TestBox BDD syntax and expectations, see the [TestBox BDD documentation](https://testbox.ortusbooks.com/v5.x/getting-started/testbox-bdd-primer) and [TestBox Expectations documentation](https://testbox.ortusbooks.com/v5.x/getting-started/testbox-bdd-primer/expectations).

### Example Controller Testing

Create `tests/Testbox/specs/controllers/ExampleControllerSpec.cfc`:

```cfscript
component extends="testbox.system.BaseSpec" {
    
    function beforeAll() {
        variables.baseUrl = "http://localhost:8080";
        variables.home = variables.baseUrl & "/";
    }
    
    function run() {
        describe("Front Page Functions Tests", function() {
            
            it("should return 200 status code for home page", function() {
                cfhttp(url=variables.home, method="GET", result="response");
                expect(response.status_code).toBe(200);
                expect(response.responseheader.status_code).toBe(200);
            });
            
            it("should contain expected home page content", function() {
                cfhttp(url=variables.home, method="GET", result="response");
                expect(response.filecontent).toInclude("<title>");
                expect(response.filecontent).toInclude("html");
            });
            
            it("should have proper content type", function() {
                cfhttp(url=variables.home, method="GET", result="response");
                expect(response.responseheader["Content-Type"]).toInclude("text/html");
            });
            
        });
    }
}
```

### API Controller Testing

Create `tests/Testbox/specs/controllers/ApiControllerSpec.cfc`:

```cfscript
component extends="testbox.system.BaseSpec" {
    
    function beforeAll() {
        variables.baseUrl = "http://localhost:8080";
        variables.apiUrl = variables.baseUrl & "/api";
    }
    
    function run() {
        describe("API Controller Tests", function() {
            
            beforeEach(function() {
                // Set up API authentication if needed
                variables.headers = {
                    "Content-Type": "application/json",
                    "Accept": "application/json"
                };
            });
            
            describe("GET /api/users", function() {
                
                it("should return JSON response with 200 status", function() {
                    cfhttp(
                        url=variables.apiUrl & "/users",
                        method="GET",
                        result="response"
                    ) {
                        cfhttpparam(type="header", name="Content-Type", value="application/json");
                        cfhttpparam(type="header", name="Accept", value="application/json");
                    }
                    
                    expect(response.status_code).toBe(200);
                    
                    // Parse JSON response
                    var jsonResponse = deserializeJSON(response.filecontent);
                    expect(jsonResponse).toBeStruct();
                    expect(jsonResponse).toHaveKey("data");
                });
                
            });
            
            describe("POST /api/users", function() {
                
                it("should create new user with valid data", function() {
                    var userData = {
                        username: "apitest_#createUUID()#",
                        email: "apitest@example.com",
                        password: "password123"
                    };
                    
                    cfhttp(
                        url=variables.apiUrl & "/users",
                        method="POST",
                        result="response"
                    ) {
                        cfhttpparam(type="header", name="Content-Type", value="application/json");
                        cfhttpparam(type="body", value=serializeJSON(userData));
                    }
                    
                    expect(response.status_code).toBe(201);
                    
                    var jsonResponse = deserializeJSON(response.filecontent);
                    expect(jsonResponse.data.username).toBe(userData.username);
                });
                
            });
            
        });
    }
}
```

### Authentication Controller Testing

Create `tests/Testbox/specs/controllers/AuthenticationControllerSpec.cfc`:

```cfscript
component extends="testbox.system.BaseSpec" {
    
    function beforeAll() {
        variables.baseUrl = "http://localhost:8080";
        variables.authUrl = variables.baseUrl & "/auth";
    }
    
    function run() {
        describe("Authentication Controller Tests", function() {
            
            beforeEach(function() {
                // Create test user for authentication tests
                variables.testUser = {
                    username: "authtest",
                    email: "authtest@example.com",
                    password: "password123"
                };
            });
            
            describe("Login Flow", function() {
                
                it("should display login page", function() {
                    cfhttp(url=variables.authUrl & "/login", method="GET", result="response");
                    expect(response.status_code).toBe(200);
                    expect(response.filecontent).toInclude("login");
                });
                
                it("should authenticate valid user", function() {
                    cfhttp(
                        url=variables.authUrl & "/login",
                        method="POST",
                        result="response"
                    ) {
                        cfhttpparam(type="formfield", name="username", value=variables.testUser.username);
                        cfhttpparam(type="formfield", name="password", value=variables.testUser.password);
                        cfhttpparam(type="formfield", name="csrf_token", value=session.csrf_token);
                    }
                    
                    // Should redirect after successful login
                    expect(response.status_code).toBe(302);
                    expect(response.responseheader).toHaveKey("Location");
                });
                
                it("should reject invalid credentials", function() {
                    cfhttp(
                        url=variables.authUrl & "/login", 
                        method="POST",
                        result="response"
                    ) {
                        cfhttpparam(type="formfield", name="username", value="invalid");
                        cfhttpparam(type="formfield", name="password", value="invalid");
                        cfhttpparam(type="formfield", name="csrf_token", value=session.csrf_token);
                    }
                    
                    expect(response.status_code).toBe(200);
                    expect(response.filecontent).toInclude("error");
                });
                
            });
            
            describe("Logout Flow", function() {
                
                it("should logout user successfully", function() {
                    cfhttp(url=variables.authUrl & "/logout", method="POST", result="response") {
                        cfhttpparam(type="formfield", name="csrf_token", value=session.csrf_token);
                    }
                    
                    expect(response.status_code).toBe(302);
                });
                
            });
            
        });
    }
}
```

### Post Controller Testing

Create `tests/Testbox/specs/controllers/PostControllerSpec.cfc`:

```cfscript
component extends="testbox.system.BaseSpec" {
    
    function beforeAll() {
        variables.baseUrl = "http://localhost:8080";
        variables.blogUrl = variables.baseUrl & "/blog";
    }
    
    function run() {
        describe("Post Controller Tests", function() {
            
            describe("Blog Index", function() {
                
                it("should display blog posts list", function() {
                    cfhttp(url=variables.blogUrl, method="GET", result="response");
                    expect(response.status_code).toBe(200);
                    expect(response.filecontent).toInclude("blog");
                });
                
            });
            
            describe("Individual Blog Post", function() {
                
                it("should display specific blog post", function() {
                    cfhttp(url=variables.blogUrl & "/1", method="GET", result="response");
                    // Either 200 (post exists) or 404 (post doesn't exist)
                    expect([200, 404]).toInclude(response.status_code);
                });
                
            });
            
            describe("Blog Post Creation", function() {
                
                it("should create new blog post with valid data", function() {
                    var postData = {
                        title: "Test Blog Post",
                        content: "This is test content for the blog post.",
                        published: true
                    };
                    
                    cfhttp(
                        url=variables.blogUrl & "/create",
                        method="POST",
                        result="response"
                    ) {
                        cfhttpparam(type="formfield", name="title", value=postData.title);
                        cfhttpparam(type="formfield", name="content", value=postData.content);
                        cfhttpparam(type="formfield", name="published", value=postData.published);
                        cfhttpparam(type="formfield", name="csrf_token", value=session.csrf_token);
                    }
                    
                    // Should redirect after successful creation
                    expect([201, 302]).toInclude(response.status_code);
                });
                
            });
            
        });
    }
}
```

## Writing Function Tests

For detailed information on testing functions and utility methods, refer to the [TestBox Unit Testing documentation](https://testbox.ortusbooks.com/v5.x/getting-started/testbox-xunit-primer).

### Example Function Testing

Create `tests/Testbox/specs/functions/ExampleSpec.cfc`:

```cfscript
component extends="testbox.system.BaseSpec" {
    
    function run() {
        describe("Utility Functions Tests", function() {
            
            describe("String Helper Functions", function() {
                
                it("should strip spaces correctly", function() {
                    var result = stripSpaces(" hello world ");
                    expect(result).toBe("helloworld");
                });
                
                it("should format currency properly", function() {
                    var result = formatCurrency(1234.56);
                    expect(result).toInclude("$");
                    expect(result).toInclude("1,234.56");
                });
                
            });
            
            describe("Date Helper Functions", function() {
                
                it("should format date correctly", function() {
                    var testDate = createDate(2024, 1, 15);
                    var result = formatDisplayDate(testDate);
                    expect(result).toInclude("Jan");
                    expect(result).toInclude("15");
                    expect(result).toInclude("2024");
                });
                
            });
            
            describe("Validation Functions", function() {
                
                it("should validate email addresses", function() {
                    expect(isValidEmail("test@example.com")).toBeTrue();
                    expect(isValidEmail("invalid-email")).toBeFalse();
                    expect(isValidEmail("")).toBeFalse();
                });
                
                it("should validate phone numbers", function() {
                    expect(isValidPhone("(555) 123-4567")).toBeTrue();
                    expect(isValidPhone("555-123-4567")).toBeTrue();
                    expect(isValidPhone("invalid")).toBeFalse();
                });
                
            });
            
        });
    }
}
```

## Running Your Tests

### Wheels 3.0 Test URL Structure

Wheels 3.0 provides convenient URL routing for both TestBox and legacy testing:

**TestBox Testing URLs:**
```
# Run your application TestBox tests
http://localhost:8080/wheels/app/tests

# Run Wheels core framework TestBox tests  
http://localhost:8080/wheels/core/tests
```

**Legacy Testing URLs (RocketUnit):**
```
# Run your application legacy tests
http://localhost:8080/wheels/legacy/app/tests

# Run Wheels core framework legacy tests
http://localhost:8080/wheels/legacy/core/tests
```

### Web Interface Access

Access your TestBox tests through multiple formats:

For more information on running tests and available formats, see the [TestBox Web Runner documentation](https://testbox.ortusbooks.com/v5.x/getting-started/running-tests/test-runner).

```
# HTML Interface (default)
http://localhost:8080/wheels/app/tests

# JSON Output (for CI/CD)
http://localhost:8080/wheels/app/tests?format=json

# Plain Text Output
http://localhost:8080/wheels/app/tests?format=txt
```

### Framework Core Testing

You can also run tests for the Wheels framework itself:

```
# Run Wheels core TestBox tests
http://localhost:8080/wheels/core/tests

# Run Wheels core legacy tests  
http://localhost:8080/wheels/legacy/core/tests
```

### Advanced URL Parameters

Customize your test runs using the convenient URLs:

For a complete list of URL parameters and advanced configuration options, refer to the [TestBox Runner Configuration documentation](https://testbox.ortusbooks.com/v5.x/getting-started/running-tests/test-runner).

```
# Run specific test bundles
http://localhost:8080/wheels/app/tests?bundles=HomeControllerSpec,ApiControllerSpec

# Run tests with specific labels
http://localhost:8080/wheels/app/tests?labels=integration,api

# Exclude certain tests
http://localhost:8080/wheels/app/tests?excludes=slow,external

# Combine parameters
http://localhost:8080/wheels/app/tests?format=json&db=mysql&populate=true&bundles=ApiControllerSpec
```

## Test Coverage Areas

Your test suite should provide comprehensive coverage for:

### HTTP Response Testing
- Status codes (200, 404, 500, 302, etc.)
- Response headers (Content-Type, Location, etc.)
- Response content validation
- Redirect behavior

### Controller Functionality
- Page rendering and templates
- Form processing and validation
- Authentication and authorization
- API endpoints and JSON responses
- CRUD operations
- Error handling

### Database Operations
- Model creation and updates
- Data validation and constraints
- Relationships and associations
- Transaction handling
- Data integrity

### Security Features
- CSRF token validation
- Authentication flows
- Authorization checks
- Input sanitization
- SQL injection prevention

### Business Logic
- Utility functions
- Helper methods
- Date and string formatting
- Validation rules
- Custom algorithms

For detailed guidance on what to test and testing strategies, see the [TestBox Testing Code Coverage documentation](https://testbox.ortusbooks.com/v5.x/digging-deeper/introduction).

## Best Practices

For comprehensive testing best practices and advanced techniques, refer to the [TestBox Testing documentation](https://testbox.ortusbooks.com/v5.x/digging-deeper/life-cycle-methods).

---

## Legacy Testing Documentation

> **Note**: This section contains legacy testing information from previous Wheels versions. For new Wheels 3.0 applications, use the TestBox approach documented above.

## Legacy Testing Overview

At some point, your code is going to break. Upgrades, feature enhancements, and bug fixes are all part of the development lifecycle. Quite often with deadlines, you don't have the time to test the functionality of your entire application with every change you make.

The problem is that today's fix could be tomorrow's bug. What if there were an automated way of checking if that change you're making is going to break something? That's where writing tests for your application can be invaluable.

For testing your application in previous Wheels versions, we used TestBox as the testing framework. TestBox comes bundled with Wheels and provides a modern BDD (Behavior Driven Development) testing experience.

### Legacy Test Framework Features

TestBox is a powerful testing framework that provides:

- BDD and xUnit style testing syntax
- Built-in assertions and expectations library
- MockBox for mocking and stubbing
- Code coverage reporting
- Parallel test execution
- Multiple output formats (HTML, JSON, JUnit, TAP)

Wheels extends TestBox with framework-specific features through the `BaseSpec.cfc` class, providing helpers for testing models, controllers, and views.

### Legacy Directory Structure

In legacy Wheels testing, tests resided in the `tests/` directory off the root of your application. The recommended directory structure was:

```
tests/
├── BaseSpec.cfc          # Base test class with Wheels helpers
├── runner.cfm            # Web-based test runner
├── specs/                # Test specifications
│   ├── unit/            # Isolated unit tests
│   ├── integration/     # Integration tests
│   └── functional/      # End-to-end tests
├── fixtures/            # Test data and fixtures
└── support/             # Test utilities
    └── factories/       # Test data factories
```

### Legacy Test Writing Syntax

All test components should extend the `tests.BaseSpec` component (which extends TestBox's BaseSpec):

```java
component extends="tests.BaseSpec" {
    // your tests here
}
```

The Wheels BaseSpec provided additional helpers for testing:
- **Transaction rollback**: All tests run in transactions that automatically roll back
- **Model helpers**: `model()`, `create()`, `build()`, `createList()`
- **Controller helpers**: `controller()`, `processRequest()`, `apiRequest()`
- **Authentication helpers**: `loginAs()`, `logout()`, `isLoggedIn()`
- **Assertion helpers**: `assertHasErrors()`, `assertFieldValueEquals()`

You could write a test method with the following syntax:

```java
it("Result is True", () => {
  result = true
	expect(result).toBeTrue()
})
```

You also had to write your test methods inside the describe method like the following:

```java
describe("Tests that return True", () => {
  it("Result is True", () => {
    result = true
    expect(result).toBeTrue()
  })
})
```

### Legacy Setup & Teardown

When writing a group of tests, it was common for there to be some duplicate code, global configuration, and/or cleanup needs that needed to be run before or after each test. In order to keep things DRY (Don't Repeat Yourself), the TestBox offered 2 special methods that you could optionally use to handle such configuration.

`beforeEach(() => {})`: Used to initialize or override any variables or execute any code that needs to be run _before each_ test.

`afterEach(() => {})`: Used to clean up any variables or execute any code that needs to be ran _after each_ test.

### Legacy Model Testing

The first part of your application that you would test against were your models because this is where all the business logic of your application lives. Here's an example of testing a model:

```java
component extends="Model" {
  public void function config() {
    validate("checkUsernameDoesNotStartWithNumber")
    beforeSave("sanitizeEmail");
  }

  private void function checkUsernameDoesNotStartWithNumber() {
    if (IsNumeric(Left(this.username, 1))) {
        addError(
        property="username",
        message="Username cannot start with a number."
      );
    }
  }

  private void function sanitizeEmail() {
      this.email = Trim(LCase(this.email));
  }
}
```

### Legacy Controller Testing

Legacy controller testing involved using the `processRequest()` function to simulate HTTP requests and examine the response. Controllers needed special handling for redirects:

```javascript
component extends="Controller" {
  public void function index() {
    users = model("user").findAll()
  }

  public any function create() {
    user = model("user").new(params.user)
    if (user.save()) {
      flashInsert(success="The user was created successfully.")
      return redirectTo(action="index")  // Notice the return here
    }
    else {
      flashInsert(error="There was a problem creating the user.")
      renderView(action="new")
    }
  }
}
```

### Legacy Command Line Testing

Earlier versions provided command line testing through various methods:

```bash
# Run all tests
wheels test run

# Run specific directory
wheels test run --directory=tests/specs/unit

# Watch mode for TDD
wheels test run --watch

# Run with coverage
wheels test run --coverage
```

### Legacy TestBox CLI

```bash
# Run all tests
box testbox run

# Run specific directory
box testbox run --directory=tests/specs/unit

# Watch mode
box testbox watch

# With coverage
box testbox run --coverage --coverageReporter=html
```

### Legacy Migration Tools

If you had existing RocketUnit tests, there were migration tools available:

```bash
# Migrate a single file
wheels test migrate path/to/test.cfc

# Migrate all tests
wheels test migrate tests --recursive

# Preview changes without modifying files
wheels test migrate tests --dry-run
```

### Legacy Docker Testing

Legacy versions provided Docker-based testing environments that allowed running tests across multiple CFML engines and databases simultaneously.

#### Legacy TestUI

```bash
# From the Wheels root directory
docker compose --profile ui up -d
```

Then navigate to http://localhost:3000 to access the TestUI.

### Legacy Additional Techniques

Legacy testing included various helper techniques:

1. Put your helper functions in your `/tests/Testbox/Test.cfc`.
2. Create `helpers.cfm` files in test directories.
3. Put package-specific helper functions in the same package as the tests.

### Legacy Learn By Example

The Wheels core used TestBox for its unit test suite and contained a wealth of useful examples in the [`tests` folder](https://github.com/wheels-dev/wheels/tree/develop/tests) of the Wheels git repo.

---

This comprehensive testing approach ensures your Wheels 3.0 application is thoroughly validated across all components, provides multi-format output for different environments, and supports various database configurations for complete coverage.