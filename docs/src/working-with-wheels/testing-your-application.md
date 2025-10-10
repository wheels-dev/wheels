# Testing Your Application

This guide provides comprehensive instructions for testing your Wheels 3.0 application using TestBox 6. Wheels 3.0 now includes TestBox integration as an enabled option, moving beyond the legacy RocketUnit framework. TestBox is already included in your installation through box.json dependency management.

## Overview

TestBox 65 is a next-generation testing framework for ColdFusion (CFML) based on BDD (Behavior Driven Development) and TDD (Test Driven Development), providing a clean, obvious syntax for writing tests. It serves as a comprehensive testing engine with multi-format output capabilities and database testing support.

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

For a complete list of features, see the [TestBox Features documentation](https://testbox.ortusbooks.com/v6.x/getting-started/overview).

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
│   ├── _assets/
│   ├── specs/
│   │   ├── controllers/
│   │   │   ├── ExampleControllerSpec.cfc
│   │   │   ├── PostControllerSpec.cfc
│   │   │   └── [Other Controller Tests]
│   │   └── functions/
│   │       └── ExampleSpec.cfc
│   ├── populate.cfm
│   ├── routes.cfm
│   └── runner.cfm
```

**Note**: By default, TestBox runs tests located in the `tests/specs/` directory, unless configured otherwise.

## TestBox Test Runner Configuration

### Main Test Runner

Update `tests/runner.cfm`:

For detailed information on TestBox runners and configuration options, refer to the [TestBox Runners documentation](https://testbox.ortusbooks.com/v6.x/getting-started/running-tests).

```cfscript
<!--- TestBox Test Runner for Wheels 3.0 --->
<cfsetting requestTimeOut="1800">
<cfscript>
    testBox = new testbox.system.TestBox(directory="tests.specs")

    setTestboxEnvironment()

    if (!structKeyExists(url, "format") || url.format eq "html") {
        result = testBox.run(
            reporter = "testbox.system.reports.JSONReporter"
        );
    }
    else if(url.format eq "json"){
        result = testBox.run(
            reporter = "testbox.system.reports.JSONReporter"
        );
        cfcontent(type="application/json");
        cfheader(name="Access-Control-Allow-Origin", value="*");
        DeJsonResult = DeserializeJSON(result);
        if (DeJsonResult.totalFail > 0 || DeJsonResult.totalError > 0) {
            cfheader(statustext="Expectation Failed", statuscode=417);
        } else {
            cfheader(statustext="OK", statuscode=200);
        }
        // Check if 'only' parameter is provided in the URL
        if (structKeyExists(url, "only") && url.only eq "failure,error") {
            allBundles = DeJsonResult.bundleStats;
            if(DeJsonResult.totalFail > 0 || DeJsonResult.totalError > 0){  

                // Filter test results
                filteredBundles = [];
                
                for (bundle in DeJsonResult.bundleStats) {
                    if (bundle.totalError > 0 || bundle.totalFail > 0) {
                        filteredSuites = [];
                
                        for (suite in bundle.suiteStats) {
                            if (suite.totalError > 0 || suite.totalFail > 0) {
                                filteredSpecs = [];
                
                                for (spec in suite.specStats) {
                                    if (spec.status eq "Error" || spec.status eq "Failed") {
                                        arrayAppend(filteredSpecs, spec);
                                    }
                                }
                
                                if (arrayLen(filteredSpecs) > 0) {
                                    suite.specStats = filteredSpecs;
                                    arrayAppend(filteredSuites, suite);
                                }
                            }
                        }
                
                        if (arrayLen(filteredSuites) > 0) {
                            bundle.suiteStats = filteredSuites;
                            arrayAppend(filteredBundles, bundle);
                        }
                    }
                }
            
                DeJsonResult.bundleStats = filteredBundles;
                // Update the result with filtered data

                count = 1;
                for(bundle in allBundles){
                    writeOutput("Bundle: #bundle.name##Chr(13)##Chr(10)#")
                    writeOutput("CFML Engine: #DeJsonResult.CFMLEngine# #DeJsonResult.CFMLEngineVersion##Chr(13)##Chr(10)#")
                    writeOutput("Duration: #bundle.totalDuration#ms#Chr(13)##Chr(10)#")
                    writeOutput("Labels: #ArrayToList(DeJsonResult.labels, ', ')##Chr(13)##Chr(10)#")
                    writeOutput("╔═══════════════════════════════════════════════════════════╗#Chr(13)##Chr(10)#║ Suites  ║ Specs   ║ Passed  ║ Failed  ║ Errored ║ Skipped ║#Chr(13)##Chr(10)#╠═══════════════════════════════════════════════════════════╣#Chr(13)##Chr(10)#║ #NumberFormat(bundle.totalSuites,'999')#     ║ #NumberFormat(bundle.totalSpecs,'999')#     ║ #NumberFormat(bundle.totalPass,'999')#     ║ #NumberFormat(bundle.totalFail,'999')#     ║ #NumberFormat(bundle.totalError,'999')#     ║ #NumberFormat(bundle.totalSkipped,'999')#     ║#Chr(13)##Chr(10)#╚═══════════════════════════════════════════════════════════╝#Chr(13)##Chr(10)##Chr(13)##Chr(10)#")
                    if(bundle.totalFail > 0 || bundle.totalError > 0){
                        for(suite in DeJsonResult.bundleStats[count].suiteStats){
                            writeOutput("Suite with Error or Failure: #suite.name##Chr(13)##Chr(10)##Chr(13)##Chr(10)#")
                            for(spec in suite.specStats){
                                writeOutput("       Spec Name: #spec.name##Chr(13)##Chr(10)#")
                                writeOutput("       Error Message: #spec.failMessage##Chr(13)##Chr(10)#")
                                writeOutput("       Error Detail: #spec.failDetail##Chr(13)##Chr(10)##Chr(13)##Chr(10)##Chr(13)##Chr(10)#")
                            }
                        }
                        count += 1;
                    }
                    writeOutput("#Chr(13)##Chr(10)##Chr(13)##Chr(10)##Chr(13)##Chr(10)#")
                }
                
            }else{
                for(bundle in DeJsonResult.bundleStats){
                    writeOutput("Bundle: #bundle.name##Chr(13)##Chr(10)#")
                    writeOutput("CFML Engine: #DeJsonResult.CFMLEngine# #DeJsonResult.CFMLEngineVersion##Chr(13)##Chr(10)#")
                    writeOutput("Duration: #bundle.totalDuration#ms#Chr(13)##Chr(10)#")
                    writeOutput("Labels: #ArrayToList(DeJsonResult.labels, ', ')##Chr(13)##Chr(10)#")
                    writeOutput("╔═══════════════════════════════════════════════════════════╗#Chr(13)##Chr(10)#║ Suites  ║ Specs   ║ Passed  ║ Failed  ║ Errored ║ Skipped ║#Chr(13)##Chr(10)#╠═══════════════════════════════════════════════════════════╣#Chr(13)##Chr(10)#║ #NumberFormat(bundle.totalSuites,'999')#     ║ #NumberFormat(bundle.totalSpecs,'999')#     ║ #NumberFormat(bundle.totalPass,'999')#     ║ #NumberFormat(bundle.totalFail,'999')#     ║ #NumberFormat(bundle.totalError,'999')#     ║ #NumberFormat(bundle.totalSkipped,'999')#     ║#Chr(13)##Chr(10)#╚═══════════════════════════════════════════════════════════╝#Chr(13)##Chr(10)##Chr(13)##Chr(10)##Chr(13)##Chr(10)#")
                }
            }
        }else{
            writeOutput(result)
        }
    }
    else if (url.format eq "txt") {
        result = testBox.run(
            reporter = "testbox.system.reports.TextReporter"
        )        
        cfcontent(type="text/plain");
        writeOutput(result)
    }
    else if(url.format eq "junit"){
        result = testBox.run(
            reporter = "testbox.system.reports.ANTJUnitReporter"
        )
        cfcontent(type="text/xml");
        writeOutput(result)
    }
    // reset the original environment
    application.wheels = application.$$$wheels
    structDelete(application, "$$$wheels")
    if(!structKeyExists(url, "format") || url.format eq "html"){
        // Use our html template
        type = "App";
        include "/wheels/tests_testbox/html.cfm";
    }

    private function setTestboxEnvironment() {
        // creating backup for original environment
        application.$$$wheels = Duplicate(application.wheels)

        // load testbox routes
        application.wo.$include(template = "/tests/routes.cfm")
        application.wo.$setNamedRoutePositions()

        local.AssetPath = "/tests/_assets/"
        
        application.wo.set(rewriteFile = "index.cfm")
        application.wo.set(controllerPath = local.AssetPath & "controllers")
        application.wo.set(viewPath = local.AssetPath & "views")
        application.wo.set(modelPath = local.AssetPath & "models")
        application.wo.set(wheelsComponentPath = "/wheels")

        /* turn off default validations for testing */
        application.wheels.automaticValidations = false
        application.wheels.assetQueryString = false
        application.wheels.assetPaths = false

        /* redirections should always delay when testing */
        application.wheels.functions.redirectTo.delay = true

        /* turn off transactions by default */
        application.wheels.transactionMode = "none"

        /* turn off request query caching */
        application.wheels.cacheQueriesDuringRequest = false

        // CSRF
        application.wheels.csrfCookieName = "_wheels_test_authenticity"
        application.wheels.csrfCookieEncryptionAlgorithm = "AES"
        application.wheels.csrfCookieEncryptionSecretKey = GenerateSecretKey("AES")
        application.wheels.csrfCookieEncryptionEncoding = "Base64"

        // Setup CSRF token and cookie. The cookie can always be in place, even when the session-based CSRF storage is being
        // tested.
        dummyController = application.wo.controller("dummy")
        csrfToken = dummyController.$generateCookieAuthenticityToken()

        cookie[application.wheels.csrfCookieName] = Encrypt(
            SerializeJSON({authenticityToken = csrfToken}),
            application.wheels.csrfCookieEncryptionSecretKey,
            application.wheels.csrfCookieEncryptionAlgorithm,
            application.wheels.csrfCookieEncryptionEncoding
        )
        if(structKeyExists(url, "db") && listFind("mysql,sqlserver,postgres,h2", url.db)){
            application.wheels.dataSourceName = "wheelstestdb_" & url.db;
        } else if (application.wheels.coreTestDataSourceName eq "|datasourceName|") {
            application.wheels.dataSourceName = "wheelstestdb"; 
        } else {
            application.wheels.dataSourceName = application.wheels.coreTestDataSourceName;
        }
        application.testenv.db = application.wo.$dbinfo(datasource = application.wheels.dataSourceName, type = "version")

        local.populate = StructKeyExists(url, "populate") ? url.populate : true
        if (local.populate) {
            include "populate.cfm"
        }
    }
</cfscript>
```

### Test Data Population

Update `tests/populate.cfm` for test database setup:

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

TestBox 6 test bundles should extend `wheels.Testbox` and use BDD syntax with `describe()`, `it()`, and `expect()`.

For comprehensive information on TestBox BDD syntax and expectations, see the [TestBox BDD documentation](https://testbox.ortusbooks.com/v6.x/getting-started/testbox-bdd-primer) and [TestBox Expectations documentation](https://testbox.ortusbooks.com/v6.x/getting-started/testbox-bdd-primer/expectations).

### Example Controller Testing

Create `tests/specs/controllers/ExampleControllerSpec.cfc`:

```cfscript
component extends="wheels.Testbox" {
    
    function beforeAll() {
        variables.baseUrl = "http://localhost:8080";
        variables.home = variables.baseUrl & "/";
    }
    
    function run() {
        describe("Front Page Functions Tests", () => {
            
            it("should return 200 status code for home page", () => {
                cfhttp(url=variables.home, method="GET", result="response");
                expect(response.status_code).toBe(200);
                expect(response.responseheader.status_code).toBe(200);
            });
            
            it("should contain expected home page content", () => {
                cfhttp(url=variables.home, method="GET", result="response");
                expect(response.filecontent).toInclude("<title>");
                expect(response.filecontent).toInclude("html");
            });
            
            it("should have proper content type", () => {
                cfhttp(url=variables.home, method="GET", result="response");
                expect(response.responseheader["Content-Type"]).toInclude("text/html");
            });
            
        });
    }
}
```

### API Controller Testing

Create `tests/specs/controllers/ApiControllerSpec.cfc`:

```cfscript
component extends="wheels.Testbox" {
    
    function beforeAll() {
        variables.baseUrl = "http://localhost:8080";
        variables.apiUrl = variables.baseUrl & "/api";
    }
    
    function run() {
            
        describe("GET /api/users", () => {

            beforeEach(() => {
                // Set up API authentication if needed
                variables.headers = {
                    "Content-Type": "application/json",
                    "Accept": "application/json"
                };
            });
            
            it("should return JSON response with 200 status", () => {
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
        
        describe("POST /api/users", () => {
            
            it("should create new user with valid data", () => {
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
    }
}
```

### Authentication Controller Testing

Create `tests/specs/controllers/AuthenticationControllerSpec.cfc`:

```cfscript
component extends="wheels.Testbox" {
    
    function beforeAll() {
        variables.baseUrl = "http://localhost:8080";
        variables.authUrl = variables.baseUrl & "/auth";
    }
    
    function run() {

		describe("Login Flow", () => {

			beforeEach(() => {
				// Create test user for authentication tests
				variables.testUser = {
					username: "authtest",
					email: "authtest@example.com",
					password: "password123"
				};
			});
			
			it("should display login page", () => {
				cfhttp(url=variables.authUrl & "/login", method="GET", result="response");
				expect(response.status_code).toBe(200);
				expect(response.filecontent).toInclude("login");
			});
			
			it("should authenticate valid user", () => {
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
			
			it("should reject invalid credentials", () => {
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
            
		describe("Logout Flow", () => {
			
			it("should logout user successfully", () => {
				cfhttp(url=variables.authUrl & "/logout", method="POST", result="response") {
					cfhttpparam(type="formfield", name="csrf_token", value=session.csrf_token);
				}
				
				expect(response.status_code).toBe(302);
			});
			
		});
    }
}
```

### Post Controller Testing

Create `tests/specs/controllers/PostControllerSpec.cfc`:

```cfscript
component extends="wheels.Testbox" {
    
    function beforeAll() {
        variables.baseUrl = "http://localhost:8080";
        variables.blogUrl = variables.baseUrl & "/blog";
    }
    
    function run() {
            
        describe("Blog Index", () => {
            
            it("should display blog posts list", () => {
                cfhttp(url=variables.blogUrl, method="GET", result="response");
                expect(response.status_code).toBe(200);
                expect(response.filecontent).toInclude("blog");
            });
            
        });
        
        describe("Individual Blog Post", () => {
            
            it("should display specific blog post", () => {
                cfhttp(url=variables.blogUrl & "/1", method="GET", result="response");
                // Either 200 (post exists) or 404 (post doesn't exist)
                expect([200, 404]).toInclude(response.status_code);
            });
            
        });
        
        describe("Blog Post Creation", () => {
            
            it("should create new blog post with valid data", () => {
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
        
    }
}
```

## Writing Function Tests

For detailed information on testing functions and utility methods, refer to the [TestBox Unit Testing documentation](https://testbox.ortusbooks.com/v6.x/getting-started/testbox-xunit-primer).

### Example Function Testing

Create `tests/specs/functions/ExampleSpec.cfc`:

```cfscript
component extends="wheels.Testbox" {
    
    function run() {
            
        describe("String Helper Functions", () => {
            
            it("should strip spaces correctly", () => {
                var result = stripSpaces(" hello world ");
                expect(result).toBe("helloworld");
            });
            
            it("should format currency properly", () => {
                var result = formatCurrency(1234.56);
                expect(result).toInclude("$");
                expect(result).toInclude("1,234.56");
            });
            
        });
        
        describe("Date Helper Functions", () => {
            
            it("should format date correctly", () => {
                var testDate = createDate(2024, 1, 15);
                var result = formatDisplayDate(testDate);
                expect(result).toInclude("Jan");
                expect(result).toInclude("15");
                expect(result).toInclude("2024");
            });
            
        });
        
        describe("Validation Functions", () => {
            
            it("should validate email addresses", () => {
                expect(isValidEmail("test@example.com")).toBeTrue();
                expect(isValidEmail("invalid-email")).toBeFalse();
                expect(isValidEmail("")).toBeFalse();
            });
            
            it("should validate phone numbers", () => {
                expect(isValidPhone("(555) 123-4567")).toBeTrue();
                expect(isValidPhone("555-123-4567")).toBeTrue();
                expect(isValidPhone("invalid")).toBeFalse();
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

```
# HTML Interface (default)
http://localhost:8080/wheels/app/tests

# JSON Output (for CI/CD)
http://localhost:8080/wheels/app/tests?format=json

# Plain Text Output
http://localhost:8080/wheels/app/tests?format=txt
```

For more information on running tests and available formats, see the [TestBox Web Runner documentation](https://testbox.ortusbooks.com/v6.x/getting-started/running-tests/test-runner).

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

For detailed guidance on what to test and testing strategies, see the [TestBox Testing Code Coverage documentation](https://testbox.ortusbooks.com/v6.x/digging-deeper/introduction).

## Best Practices

For comprehensive testing best practices and advanced techniques, refer to the [TestBox Testing documentation](https://testbox.ortusbooks.com/v6.x/digging-deeper/life-cycle-methods).

{% hint style="info" %}
**Naming Convention for Test Specs**

Always name your test specs with `Test` or `Spec` in their filename, otherwise TestBox 6 won’t detect and run them.
{% endhint %}

---

## Legacy RocketUnit Testing Framework

> **Note**: This section documents the legacy RocketUnit testing framework used in earlier Wheels versions. For new Wheels 3.0 applications, use the TestBox approach documented above. This information is maintained for reference and migration purposes.

## Legacy RocketUnit Overview

Prior to Wheels 3.0, the framework used RocketUnit as its testing infrastructure. RocketUnit was a comprehensive testing framework that provided both unit testing and integration testing capabilities specifically tailored for Wheels applications.

At some point, your code is going to break. Upgrades, feature enhancements, and bug fixes are all part of the development lifecycle. Quite often with deadlines, you don't have the time to test the functionality of your entire application with every change you make.

The problem is that today's fix could be tomorrow's bug. What if there were an automated way of checking if that change you're making is going to break something? That's where writing tests for your application can be invaluable.

### Legacy RocketUnit Features

RocketUnit provided a complete testing solution with the following features:

- **Unit Testing**: Testing individual functions and methods in isolation
- **Integration Testing**: Testing complete request flows and component interactions
- **Assertion Library**: Comprehensive set of assertion methods for validation
- **Test Lifecycle Management**: Setup and teardown methods for test preparation
- **Package Organization**: Hierarchical test organization and execution
- **Multiple Output Formats**: HTML, text, and custom reporting formats
- **Database Testing Support**: Built-in database seeding and cleanup capabilities

### Legacy Directory Structure

The legacy RocketUnit testing framework used a specific directory structure within your Wheels application:

```
your-app/
├── tests/
│   ├── Test.cfc                 # Parent test component (extends wheels.Test)
│   ├── functions/               # Function-level unit tests
│   │   └── Example.cfc         # Example function tests
│   └── requests/               # Integration tests for request flows
│       └── Example.cfc         # Example request tests
└── wheels/
    ├── Test.cfc                # Core testing framework component
    └── test/
        └── functions.cfm       # Testing framework implementation
```

### Legacy Test Components

#### 1. tests/Test.cfc - Parent Test Component

This was the base component that all test components should extend:

```cfscript
component extends="wheels.Test" hint="I am the parent test." {
    
    function beforeAll() {
        // Executes once before the test suite runs
    }
    
    function setup() {
        // Executes before every test case
    }
    
    function teardown() {
        // Executes after every test case
    }
    
    function afterAll() {
        // Executes once after the test suite runs
    }
}
```

**Key Features:**

- **Lifecycle Methods**: Provided complete test lifecycle management
- **Framework Integration**: Extended wheels.Test for full framework integration
- **Documentation Support**: Included section and category metadata

#### 2. tests/functions/Example.cfc - Function Testing

Example test file for testing controller, model, and global functions:

```cfscript
component extends="app.tests.Test" hint="I am an example test for functions." {
    
    function packageSetup() {
        // Executes once before this package's first test case
    }
    
    function packageTeardown() {
        // Executes once after this package's last test case
    }
    
    function testExample() {
        // Example test with simple assertion
        assert('true');
    }
}
```

**Key Features:**

- **Package-level Lifecycle**: Setup and teardown for entire test packages
- **Unit Testing Focus**: Designed for testing individual functions in isolation
- **Simple Assertions**: Used basic assert() statements for validation

#### 3. tests/requests/Example.cfc - Integration Testing

Example test file for integration testing where controllers, models, and other components work together:

```cfscript
component extends="app.tests.Test" hint="I am an example test for requests." {
    
    function packageSetup() {
        // Setup for integration test package
    }
    
    function packageTeardown() {
        // Cleanup for integration test package
    }
    
    function testRequestFlow() {
        // Test complete request processing
        assert('true');
    }
}
```

**Key Features:**

- **Integration Testing**: Tested complete request flows and component interactions
- **Request Context**: Simulated full HTTP request/response cycles
- **Component Interaction**: Validated how controllers, models, and views worked together

### Legacy Core Testing Framework

#### wheels/Test.cfc - Core Testing Component

The core testing framework component provided all testing functionality:

```cfscript
component hint="I am the testing framework for Wheels applications." {
    
    public any function $runTest() {
        // Main test execution method
    }
    
    public void function assert(required any expression) {
        // Basic assertion method
    }
    
    public void function fail(string message = "") {
        // Explicit test failure
    }
    
    public any function debug(required any expression) {
        // Debug expression evaluation
    }
    
    public string function raised(required any expression) {
        // Error catching and type return
    }
}
```

#### wheels/test/functions.cfm - Framework Implementation

The comprehensive testing framework implementation included:

**Assertion Functions:**

- `assert(expression)` - Evaluated expressions and recorded failures
- `fail(message)` - Explicitly failed tests with custom messages
- `debug(expression)` - Examined expressions during testing
- `raised(expression)` - Caught and returned error types

### Legacy Testing Philosophy and Structure

The RocketUnit framework followed these organizational principles:

#### Test Packages

Collections of test cases organized in directories, allowing for:

- Logical grouping of related tests
- Package-level setup and teardown
- Hierarchical test execution
- Modular test organization

#### Test Cases

Components containing multiple tests for specific functionality:

- Focused on single areas of functionality
- Contained multiple related test methods
- Provided component-level lifecycle management
- Extended the base Test component

#### Tests

Methods starting with "test" that contained assertions:

- Named with descriptive test names (e.g., `testUserValidation()`)
- Contained one or more assertion statements
- Focused on specific behaviors or outcomes
- Used simple assertion syntax

#### Assertions

Statements that should evaluate to true for tests to pass:

- `assert(expression)` - Basic true/false validation
- `fail(message)` - Explicit test failure with custom message
- `debug(expression)` - Expression evaluation for debugging
- `raised(expression)` - Error handling and type checking

### Legacy Test Execution and Management

#### Running Tests

The RocketUnit framework supported multiple execution patterns:

**Entire Test Packages:**

```
# Run all tests in functions package
http://localhost:8080/wheels/packages/app?package=functions

# Run all tests in requests package  
http://localhost:8080/wheels/packages/app?package=requests
```

**Specific Test Cases:**

```
# Run specific test component
http://localhost:8080/wheels/packages/app?package=functions&test=Example

# Run individual test method
http://localhost:8080/wheels/packages/app?package=functions&test=Example&method=testExample
```

**With Filtering Options:**

```
# Run tests with specific labels
http://localhost:8080/wheels/packages/app?labels=unit,fast

# Exclude slow tests
http://localhost:8080/wheels/packages/app?exclude=slow,integration
```

#### Test Types Supported

The framework supported different categories of tests:

**Core Tests**: Framework-level tests for Wheels components
**App Tests**: Application-specific tests for your code
**Plugin Tests**: Tests for Wheels plugins and extensions

#### Advanced Legacy Features

**Database Seeding Capabilities:**

- Automatic test database population
- Data cleanup between tests
- Transaction-based test isolation
- Custom seeding scripts

**Test Environment Initialization:**

- Isolated test environment setup
- Configuration override capabilities
- Mock service integration
- Resource allocation and cleanup

**Debugging and Output Formatting:**

- Detailed test execution reports
- Error stack traces and debugging info
- Performance timing information
- Custom output formatters

**Error Handling and Reporting:**

- Comprehensive error capture
- Test failure analysis
- Exception type categorization
- Detailed failure reporting

### Legacy Usage Patterns

#### Test Organization Structure

```
tests/functions/     # Unit testing individual functions
tests/requests/     # Integration testing request flows
tests/models/       # Model-specific testing (optional)
tests/controllers/  # Controller-specific testing (optional)
```

#### Lifecycle Management Hierarchy

1. **Suite Level**: `beforeAll()` and `afterAll()` for entire test suite
2. **Package Level**: `packageSetup()` and `packageTeardown()` for test packages  
3. **Test Case Level**: `setup()` and `teardown()` for individual test cases

#### Example Legacy Test Structure

```cfscript
component extends="app.tests.Test" {
    
    function packageSetup() {
        variables.testData = {
            user: { username: "testuser", email: "test@example.com" }
        };
    }
    
    function setup() {
        variables.testUser = model("User").create(variables.testData.user);
    }
    
    function testUserCreation() {
        assert('StructKeyExists(variables, "testUser")');
        assert('variables.testUser.persisted()');
        assert('variables.testUser.username eq "testuser"');
    }
    
    function testUserValidation() {
        invalidUser = model("User").new({username: "", email: "invalid"});
        assert('NOT invalidUser.valid()');
        assert('invalidUser.hasErrors()');
    }
    
    function teardown() {
        if (StructKeyExists(variables, "testUser")) {
            variables.testUser.delete();
        }
    }
    
    function packageTeardown() {
        // Cleanup package-level resources
    }
}
```

### Legacy Framework Integration

The RocketUnit framework was tightly integrated with the Wheels framework, providing:

**Model Testing Integration:**

- Automatic database transaction management
- Model validation testing helpers
- Relationship testing utilities
- Database seeding and cleanup

**Controller Testing Integration:**

- Request simulation capabilities
- Response validation helpers
- Session and cookie management
- Route testing functionality

**View Testing Integration:**

- Template rendering validation
- Output content verification
- Helper function testing
- Layout and partial testing

### Migration from Legacy RocketUnit to TestBox

When migrating from the legacy RocketUnit system to TestBox 6, consider the following mapping:

#### Syntax Migration

- `assert(expression)` → `expect(result).toBeTrue()`
- `fail(message)` → `fail(message)` (same syntax)
- `debug(expression)` → `debug(expression)` (same syntax)
- Test methods → Wrapped in `describe()` and `it()` blocks

#### Structure Migration

- `tests/functions/` → `tests/specs/functions/`
- `tests/requests/` → `tests/specs/controllers/`
- Component extensions change from `app.tests.Test` to `wheels.Testbox`
- File names changed to include `Spec` or `Test` to align with TestBox 6 naming requirements

#### Lifecycle Migration

- `packageSetup()` → `beforeAll()` in describe block
- `packageTeardown()` → `afterAll()` in describe block
- `setup()` → `beforeEach()` in describe block  
- `teardown()` → `afterEach()` in describe block

### Legacy Reference and Historical Context

The RocketUnit framework served the Wheels community well for many years, providing a solid foundation for test-driven development in CFML applications. While TestBox now provides more modern BDD/TDD capabilities, understanding the legacy system helps with:

- **Migration Planning**: Understanding existing test structures for conversion
- **Historical Context**: Appreciating the evolution of CFML testing frameworks
- **Legacy Maintenance**: Supporting older Wheels applications still using RocketUnit
- **Framework Archaeology**: Understanding the testing heritage of the Wheels framework

The comprehensive testing infrastructure provided by RocketUnit established many of the testing patterns and practices that continue in the modern TestBox implementation, ensuring continuity and familiarity for developers transitioning between the frameworks.

---

This comprehensive testing approach ensures your Wheels 3.0 application is thoroughly validated across all components, provides multi-format output for different environments, and supports various database configurations for complete coverage while maintaining reference information for legacy RocketUnit systems.

## Running Legacy RocketUnit Tests in Wheels 3.0

If you already have application-level tests written with RocketUnit in a Wheels 2.x app, you don’t need to rewrite them immediately when upgrading to Wheels 3.0. Wheels 3.0 still provides backward compatibility for running RocketUnit tests alongside TestBox.
To run your existing RocketUnit tests:

1. Copy the entire contents of that `tests/` folder.
2. Paste the copied folder into your Wheels 3.0 application under `tests/RocketUnit/`.
3. Run the legacy tests by visiting the RocketUnit runner in your browser:
http://localhost:8080/wheels/legacy/app/tests


This approach lets you continue running your legacy RocketUnit test suite unchanged inside a Wheels 3.0 project while you gradually migrate to TestBox. It’s particularly useful for teams upgrading large applications where a complete migration cannot be done in one step.