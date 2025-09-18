# Testing Views

## View Helper Testing

### Basic View Testing

```cfm
<!--- In test files --->
component extends="BaseSpec" {
    function run() {
        describe("User view", function() {
            beforeEach(function() {
                user = model("user").new(name="John Doe", email="john@example.com");
            });

            it("should display user information", function() {
                result = includePartial(partial="user", user=user);
                expect(result).toInclude("John Doe");
                expect(result).toInclude("john@example.com");
            });
        });
    }
}
```

### Testing Partials

```cfm
component extends="wheels.Test" {

    function setup() {
        super.setup();
        user = model("User").create(
            firstname="John",
            lastname="Doe",
            email="john@example.com"
        );
    }

    function testUserCardPartial() {
        // Test partial rendering
        result = includePartial(partial="userCard", user=user, showActions=true);

        // Assertions
        assert("Find('John Doe', result) GT 0");
        assert("Find('john@example.com', result) GT 0");
        assert("Find('btn', result) GT 0"); // Should include action buttons
    }

    function testUserCardPartialWithoutActions() {
        result = includePartial(partial="userCard", user=user, showActions=false);

        // Should not include action buttons
        assert("Find('btn', result) EQ 0");
    }

    function testUserListPartial() {
        // Create additional test users
        user2 = model("User").create(
            firstname="Jane",
            lastname="Smith",
            email="jane@example.com"
        );

        users = model("User").findAll(where="id IN (#user.id#, #user2.id#)");
        result = includePartial(partial="userList", users=users);

        assert("Find('John Doe', result) GT 0");
        assert("Find('Jane Smith', result) GT 0");
    }

    function teardown() {
        // Clean up test data
        model("User").deleteAll(where="email LIKE '%@example.com'");
        super.teardown();
    }
}
```

### Testing Form Helpers

```cfm
component extends="wheels.Test" {

    function setup() {
        super.setup();
        user = model("User").new();
    }

    function testFormGeneration() {
        // Test form rendering
        params.controller = "users";
        params.action = "create";

        formContent = startFormTag(route="users") &
                     textField(objectName="user", property="name") &
                     endFormTag();

        // Check form structure
        assert("Find('<form', formContent) GT 0");
        assert("Find('action=""/users""', formContent) GT 0");
        assert("Find('method=""post""', formContent) GT 0");
        assert("Find('name=""user[name]""', formContent) GT 0");
    }

    function testFormWithErrors() {
        // Create user with validation errors
        user.firstname = "";
        user.email = "invalid-email";
        user.valid(); // Trigger validation

        errorContent = errorMessagesFor("user");

        assert("Len(errorContent) GT 0");
        assert("Find('error', errorContent) GT 0");
    }

    function testFormFieldValidation() {
        // Test individual field error display
        user.email = "invalid-email";
        user.valid();

        fieldError = errorMessageOn(objectName="user", property="email");

        assert("Len(fieldError) GT 0");
        assert("Find('email', LCase(fieldError)) GT 0");
    }
}
```

### Testing View Helpers

```cfm
component extends="wheels.Test" {

    function testLinkToHelper() {
        // Test link generation
        link = linkTo(text="Home", route="root");

        assert("Find('<a', link) GT 0");
        assert("Find('href=""/"', link) GT 0");
        assert("Find('>Home<', link) GT 0");
    }

    function testLinkToWithKey() {
        link = linkTo(text="User Profile", route="user", key=123);

        assert("Find('href=""/users/123""', link) GT 0");
    }

    function testImageTag() {
        image = imageTag(source="logo.png", alt="Company Logo");

        assert("Find('<img', image) GT 0");
        assert("Find('src=""/images/logo.png""', image) GT 0");
        assert("Find('alt=""Company Logo""', image) GT 0");
    }

    function testCustomHelpers() {
        // Test custom helper functions
        include "/app/views/helpers.cfm";

        // Test currency formatting
        formatted = formatCurrency(1234.56);
        assert("formatted EQ '$1,234.56'");

        // Test time ago helper
        pastDate = DateAdd("h", -2, Now());
        timeAgo = timeAgo(pastDate);
        assert("Find('2 hours ago', timeAgo) GT 0");
    }
}
```

### Integration Testing with Controllers

```cfm
component extends="wheels.Test" {

    function setup() {
        super.setup();
        user = model("User").create(
            firstname="John",
            lastname="Doe",
            email="john@example.com"
        );
    }

    function testUserShowView() {
        // Simulate controller action
        params = {
            controller = "users",
            action = "show",
            key = user.id
        };

        controller = controller("users", params);
        controller.show();

        // Test that view variables are set
        assert("IsDefined('controller.user')");
        assert("controller.user.id EQ #user.id#");

        // Render the view
        content = renderView(controller="users", action="show");

        // Test rendered content
        assert("Find('John Doe', content) GT 0");
        assert("Find('john@example.com', content) GT 0");
    }

    function testUserIndexView() {
        params = {
            controller = "users",
            action = "index"
        };

        controller = controller("users", params);
        controller.index();

        content = renderView(controller="users", action="index");

        // Should contain user list
        assert("Find('John Doe', content) GT 0");
        assert("Find('table', content) GT 0");
    }

    function teardown() {
        model("User").deleteAll(where="email = 'john@example.com'");
        super.teardown();
    }
}
```

### Testing AJAX Responses

```cfm
component extends="wheels.Test" {

    function testAjaxPartialResponse() {
        user = model("User").create(
            firstname="John",
            lastname="Doe",
            email="john@example.com"
        );

        // Simulate AJAX request
        params = {
            controller = "users",
            action = "show",
            key = user.id,
            format = "json"
        };

        controller = controller("users", params);
        controller.show();

        // Test JSON response
        jsonContent = renderView(controller="users", action="show", template="show.json");

        assert("IsJSON(jsonContent)");

        parsedJson = DeserializeJSON(jsonContent);
        assert("parsedJson.user.firstname EQ 'John'");
        assert("parsedJson.user.email EQ 'john@example.com'");
    }
}
```

### Testing Flash Messages

```cfm
component extends="wheels.Test" {

    function testFlashMessageDisplay() {
        // Set flash message
        flashInsert(success="User created successfully!");

        // Render flash messages
        flashContent = flashMessages();

        assert("Find('success', flashContent) GT 0");
        assert("Find('User created successfully!', flashContent) GT 0");
    }

    function testMultipleFlashMessages() {
        flashInsert(success="User created successfully!");
        flashInsert(error="Email validation failed");

        flashContent = flashMessages();

        assert("Find('success', flashContent) GT 0");
        assert("Find('error', flashContent) GT 0");
        assert("Find('User created successfully!', flashContent) GT 0");
        assert("Find('Email validation failed', flashContent) GT 0");
    }
}
```

## Testing Best Practices

### 1. Test Isolation

```cfm
// Each test should be independent
function beforeEach() {
    // Setup fresh data for each test
    testUser = model("User").new(firstname="Test", lastname="User");
}

function afterEach() {
    // Clean up after each test
    if (IsObject(testUser) && testUser.isPersisted()) {
        testUser.delete();
    }
}
```

### 2. Test Data Management

```cfm
// Use factories or fixtures for consistent test data
function createTestUser(struct attributes = {}) {
    local.defaultAttributes = {
        firstname = "Test",
        lastname = "User",
        email = "test@example.com"
    };

    StructAppend(local.defaultAttributes, arguments.attributes, true);

    return model("User").create(local.defaultAttributes);
}
```

### 3. Testing Edge Cases

```cfm
function testEmptyQueryDisplay() {
    // Test view behavior with no data
    emptyUsers = QueryNew("id,firstname,lastname,email");

    content = includePartial(partial="userList", users=emptyUsers);

    assert("Find('No users found', content) GT 0");
}

function testLargeDataSets() {
    // Test performance with large datasets
    // Create 100 test users
    for (i = 1; i <= 100; i++) {
        model("User").create(
            firstname="User",
            lastname="#i#",
            email="user#i#@example.com"
        );
    }

    users = model("User").findAll(where="email LIKE '%@example.com'");
    startTime = getTickCount();

    content = includePartial(partial="userList", users=users);

    executionTime = getTickCount() - startTime;

    // Assert reasonable performance
    assert("executionTime LT 1000"); // Less than 1 second
}
```

### 4. Mock External Dependencies

```cfm
function testViewWithExternalService() {
    // Mock external service calls
    mockWeatherService = {
        getCurrentWeather = function() {
            return {
                temperature = 72,
                condition = "Sunny"
            };
        }
    };

    // Inject mock into application scope for testing
    application.weatherService = mockWeatherService;

    content = includePartial(partial="weatherWidget");

    assert("Find('72', content) GT 0");
    assert("Find('Sunny', content) GT 0");
}