# Testing Views with TestBox BDD

## Modern View Testing with TestBox 5

### BDD View Testing Structure

```cfm
// tests/specs/views/UserViewSpec.cfc
component extends="wheels.Testbox" {

    function run() {
        describe("User View Components", () => {

            beforeEach(() => {
                variables.testUser = model("User").create({
                    firstname: "John",
                    lastname: "Doe",
                    email: "john@example.com"
                });
            });

            afterEach(() => {
                if (structKeyExists(variables, "testUser") && isObject(variables.testUser)) {
                    variables.testUser.delete();
                }
            });

            it("should display user information correctly", () => {
                var result = includePartial(partial="user", user=variables.testUser);
                expect(result).toInclude("John Doe");
                expect(result).toInclude("john@example.com");
            });

        });
    }
}
```

### Testing Partials with BDD

```cfm
component extends="wheels.Testbox" {

    function run() {
        describe("User Card Partial", () => {

            beforeEach(() => {
                variables.testUser = model("User").create({
                    firstname: "John",
                    lastname: "Doe",
                    email: "john@example.com"
                });
            });

            afterEach(() => {
                if (structKeyExists(variables, "testUser") && isObject(variables.testUser)) {
                    variables.testUser.delete();
                }
            });

            it("should render user card with actions", () => {
                var result = includePartial(
                    partial="userCard",
                    user=variables.testUser,
                    showActions=true
                );

                expect(result).toInclude("John Doe");
                expect(result).toInclude("john@example.com");
                expect(result).toInclude("btn"); // Should include action buttons
            });

            it("should render user card without actions when disabled", () => {
                var result = includePartial(
                    partial="userCard",
                    user=variables.testUser,
                    showActions=false
                );

                expect(result).notToInclude("btn"); // Should not include action buttons
            });

            it("should render user list with multiple users", () => {
                var user2 = model("User").create({
                    firstname: "Jane",
                    lastname: "Smith",
                    email: "jane@example.com"
                });

                var users = model("User").findAll(
                    where="id IN (#variables.testUser.id#, #user2.id#)"
                );
                var result = includePartial(partial="userList", users=users);

                expect(result).toInclude("John Doe");
                expect(result).toInclude("Jane Smith");

                // Clean up additional user
                user2.delete();
            });

        });
    }
}
```

### Testing Form Helpers with BDD

```cfm
component extends="wheels.Testbox" {

    function run() {
        describe("Form Helper Testing", () => {

            beforeEach(() => {
                variables.testUser = model("User").new();
            });

            it("should generate proper form structure", () => {
                params.controller = "users";
                params.action = "create";

                var formContent = startFormTag(route="users") &
                                 textField(objectName="user", property="name") &
                                 endFormTag();

                expect(formContent).toInclude("<form");
                expect(formContent).toInclude('action="/users"');
                expect(formContent).toInclude('method="post"');
                expect(formContent).toInclude('name="user[name]"');
            });

            it("should display validation errors", () => {
                // Create user with validation errors
                variables.testUser.firstname = "";
                variables.testUser.email = "invalid-email";
                variables.testUser.valid(); // Trigger validation

                var errorContent = errorMessagesFor("user");

                expect(len(errorContent)).toBeGT(0);
                expect(errorContent).toInclude("error");
            });

            it("should display individual field errors", () => {
                variables.testUser.email = "invalid-email";
                variables.testUser.valid();

                var fieldError = errorMessageOn(objectName="user", property="email");

                expect(len(fieldError)).toBeGT(0);
                expect(lCase(fieldError)).toInclude("email");
            });

        });
    }
}
```

### Testing View Helpers with BDD

```cfm
component extends="wheels.Testbox" {

    function run() {
        describe("View Helper Functions", () => {

            it("should generate proper link tags", () => {
                var link = linkTo(text="Home", route="root");

                expect(link).toInclude("<a");
                expect(link).toInclude('href="/"');
                expect(link).toInclude(">Home<");
            });

            it("should generate links with parameters", () => {
                var link = linkTo(text="User Profile", route="user", key=123);

                expect(link).toInclude('href="/users/123"');
            });

            it("should generate proper image tags", () => {
                var image = imageTag(source="logo.png", alt="Company Logo");

                expect(image).toInclude("<img");
                expect(image).toInclude('src="/images/logo.png"');
                expect(image).toInclude('alt="Company Logo"');
            });

            it("should work with custom helper functions", () => {
                // Test custom helper functions
                include "/app/views/helpers.cfm";

                // Test currency formatting
                var formatted = formatCurrency(1234.56);
                expect(formatted).toBe("$1,234.56");

                // Test time ago helper
                var pastDate = dateAdd("h", -2, now());
                var timeAgoResult = timeAgo(pastDate);
                expect(timeAgoResult).toInclude("2 hours ago");
            });

        });
    }
}
```

### Integration Testing with Controllers using BDD

```cfm
component extends="wheels.Testbox" {

    function run() {
        describe("View Integration Testing", () => {

            beforeEach(() => {
                variables.testUser = model("User").create({
                    firstname: "John",
                    lastname: "Doe",
                    email: "john@example.com"
                });
            });

            afterEach(() => {
                if (structKeyExists(variables, "testUser") && isObject(variables.testUser)) {
                    variables.testUser.delete();
                }
            });

            it("should render user show view correctly", () => {
                // Test using HTTP request approach
                cfhttp(
                    url="http://localhost:8080/users/" & variables.testUser.id,
                    method="GET",
                    result="response"
                );

                expect(response.status_code).toBe(200);
                expect(response.filecontent).toInclude("John Doe");
                expect(response.filecontent).toInclude("john@example.com");
            });

            it("should render user index view with list", () => {
                cfhttp(
                    url="http://localhost:8080/users",
                    method="GET",
                    result="response"
                );

                expect(response.status_code).toBe(200);
                expect(response.filecontent).toInclude("John Doe");
                expect(response.filecontent).toInclude("table"); // User list table
            });

        });
    }
}
```

### Testing AJAX Responses with BDD

```cfm
component extends="wheels.Testbox" {

    function run() {
        describe("AJAX Response Testing", () => {

            beforeEach(() => {
                variables.testUser = model("User").create({
                    firstname: "John",
                    lastname: "Doe",
                    email: "john@example.com"
                });
            });

            afterEach(() => {
                if (structKeyExists(variables, "testUser") && isObject(variables.testUser)) {
                    variables.testUser.delete();
                }
            });

            it("should return proper JSON response", () => {
                cfhttp(
                    url="http://localhost:8080/users/" & variables.testUser.id,
                    method="GET",
                    result="response"
                ) {
                    cfhttpparam(type="header", name="Accept", value="application/json");
                    cfhttpparam(type="header", name="X-Requested-With", value="XMLHttpRequest");
                }

                expect(response.status_code).toBe(200);
                expect(isJSON(response.filecontent)).toBeTrue();

                var parsedJson = deserializeJSON(response.filecontent);
                expect(parsedJson.user.firstname).toBe("John");
                expect(parsedJson.user.email).toBe("john@example.com");
            });

        });
    }
}
```

### Testing Flash Messages with BDD

```cfm
component extends="wheels.Testbox" {

    function run() {
        describe("Flash Message Display", () => {

            it("should display success flash messages", () => {
                // Set flash message
                flashInsert(success="User created successfully!");

                // Render flash messages
                var flashContent = flashMessages();

                expect(flashContent).toInclude("success");
                expect(flashContent).toInclude("User created successfully!");
            });

            it("should display multiple flash messages", () => {
                flashInsert(success="User created successfully!");
                flashInsert(error="Email validation failed");

                var flashContent = flashMessages();

                expect(flashContent).toInclude("success");
                expect(flashContent).toInclude("error");
                expect(flashContent).toInclude("User created successfully!");
                expect(flashContent).toInclude("Email validation failed");
            });

        });
    }
}
```

## TestBox BDD Best Practices for View Testing

### 1. Test Isolation with BDD Lifecycle

```cfm
describe("View Component Tests", () => {

    beforeEach(() => {
        // Setup fresh data for each test
        variables.testUser = model("User").new({
            firstname: "Test",
            lastname: "User"
        });
    });

    afterEach(() => {
        // Clean up after each test
        if (structKeyExists(variables, "testUser") &&
            isObject(variables.testUser) &&
            variables.testUser.isPersisted()) {
            variables.testUser.delete();
        }
    });

});
```

### 2. BDD Test Data Management

```cfm
// Use helper functions for consistent test data
function createTestUser(struct attributes = {}) {
    var defaultAttributes = {
        firstname: "Test",
        lastname: "User",
        email: "test_" & createUUID() & "@example.com"
    };

    structAppend(defaultAttributes, arguments.attributes, true);

    return model("User").create(defaultAttributes);
}
```

### 3. Testing Edge Cases with BDD

```cfm
describe("Edge Case Handling", () => {

    it("should handle empty data gracefully", () => {
        var emptyUsers = queryNew("id,firstname,lastname,email");
        var content = includePartial(partial="userList", users=emptyUsers);

        expect(content).toInclude("No users found");
    });

    it("should handle large data sets with acceptable performance", () => {
        // Create test users
        for (var i = 1; i <= 100; i++) {
            model("User").create({
                firstname: "User",
                lastname: "#i#",
                email: "user#i#_" & createUUID() & "@example.com"
            });
        }

        var users = model("User").findAll(where="email LIKE '%@example.com'");
        var startTime = getTickCount();

        var content = includePartial(partial="userList", users=users);

        var executionTime = getTickCount() - startTime;

        // Assert reasonable performance
        expect(executionTime).toBeLT(1000); // Less than 1 second

        // Clean up test data
        model("User").deleteAll(where="email LIKE '%@example.com'");
    });

});
```

### 4. Mock External Dependencies with MockBox

```cfm
describe("External Service Integration", () => {

    beforeEach(() => {
        // Create mock weather service
        variables.mockWeatherService = createMock("WeatherService");
        variables.mockWeatherService.$(
            method="getCurrentWeather",
            returns={
                temperature: 72,
                condition: "Sunny"
            }
        );

        // Inject mock into application scope
        application.weatherService = variables.mockWeatherService;
    });

    it("should display weather information from external service", () => {
        var content = includePartial(partial="weatherWidget");

        expect(content).toInclude("72");
        expect(content).toInclude("Sunny");
        expect(variables.mockWeatherService.$once("getCurrentWeather")).toBeTrue();
    });

});
```

## Modern TestBox Resources

For comprehensive TestBox 5 documentation:
- [TestBox BDD Documentation](https://testbox.ortusbooks.com/v5.x/getting-started/testbox-bdd-primer)
- [TestBox Expectations](https://testbox.ortusbooks.com/v5.x/getting-started/testbox-bdd-primer/expectations)
- [MockBox Documentation](https://testbox.ortusbooks.com/v5.x/mocking/mockbox)
- [TestBox Life-cycle Methods](https://testbox.ortusbooks.com/v5.x/digging-deeper/life-cycle-methods)

## Related Documentation
- [View Architecture](./architecture.md)
- [View Helpers](./helpers.md)
- [Controller Testing](../controllers/testing.md)
- [Model Testing](../models/testing.md)