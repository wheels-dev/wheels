# Modern CFML Patterns

## Overview
Modern CFML development emphasizes script syntax, functional programming patterns, component-based architecture, and best practices that align with contemporary software development principles.

## Key Principles
- Prefer script syntax over tag-based syntax for business logic
- Use functional programming patterns where appropriate
- Follow object-oriented principles (encapsulation, inheritance, composition)
- Implement dependency injection for loose coupling
- Write testable, maintainable code

## Examples

### Script vs Tag Syntax
```cfscript
// MODERN: Script syntax (preferred)
component accessors="true" {

    property name="userService" inject="UserService";

    function getUsers(filters = {}) {
        if (!structKeyExists(filters, "active")) {
            filters.active = true;
        }

        return userService.findAll(filters);
    }
}

// LEGACY: Tag syntax (avoid for business logic)
<cfcomponent>
    <cffunction name="getUsers">
        <cfargument name="filters" default="#{}#">

        <cfif NOT structKeyExists(arguments.filters, "active")>
            <cfset arguments.filters.active = true>
        </cfif>

        <cfreturn variables.userService.findAll(arguments.filters)>
    </cffunction>
</cfcomponent>
```

### Functional Programming Patterns
```cfscript
// MODERN: Functional approach
function processOrderData(orders) {
    return orders
        .filter((order) => order.isValid)
        .map((order) => order.calculateTotal())
        .reduce((sum, total) => sum + total, 0);
}

// Use closures for configuration
function createValidator(rules) {
    return function(data) {
        return rules.every((rule) => rule(data));
    };
}

emailValidator = createValidator([
    (data) => structKeyExists(data, "email"),
    (data) => len(data.email) > 0,
    (data) => find("@", data.email) > 0
]);
```

### Component-Based Architecture
```cfscript
// MODERN: Single Responsibility Principle
component singleton {

    property name="logger" inject="Logger";
    property name="validator" inject="DataValidator";

    function processUser(required userData) {
        // Validate input
        if (!validator.isValid(userData)) {
            throw("Invalid user data");
        }

        // Log activity
        logger.info("Processing user: " & userData.id);

        // Delegate to specialized services
        var user = userFactory.create(userData);
        var result = userRepository.save(user);

        return result;
    }
}
```

### Dependency Injection Pattern
```cfscript
// MODERN: Constructor injection
component accessors="true" {

    property name="userRepository";
    property name="emailService";
    property name="logger";

    function init(
        required userRepository,
        required emailService,
        required logger
    ) {
        variables.userRepository = arguments.userRepository;
        variables.emailService = arguments.emailService;
        variables.logger = arguments.logger;

        return this;
    }

    function createUser(userData) {
        try {
            var user = userRepository.create(userData);
            emailService.sendWelcomeEmail(user);
            logger.info("User created: " & user.getId());
            return user;
        } catch (any e) {
            logger.error("User creation failed", e);
            rethrow;
        }
    }
}
```

### Error Handling Best Practices
```cfscript
// MODERN: Comprehensive error handling
component {

    function processPayment(paymentData) {
        try {
            // Validate input
            validatePaymentData(paymentData);

            // Process payment
            var result = paymentGateway.charge(paymentData);

            // Log success
            auditLogger.logPayment(result);

            return {
                success: true,
                transactionId: result.id,
                message: "Payment processed successfully"
            };

        } catch (ValidationError e) {
            return {
                success: false,
                error: "validation",
                message: e.message
            };
        } catch (PaymentError e) {
            return {
                success: false,
                error: "payment",
                message: "Payment processing failed"
            };
        } catch (any e) {
            logger.error("Unexpected payment error", e);
            return {
                success: false,
                error: "system",
                message: "System error occurred"
            };
        }
    }
}
```

### Configuration Management
```cfscript
// MODERN: Environment-based configuration
component singleton {

    property name="config";

    function init() {
        loadConfiguration();
        return this;
    }

    private function loadConfiguration() {
        variables.config = {
            database: {
                host: getSystemSetting("DB_HOST", "localhost"),
                port: getSystemSetting("DB_PORT", "3306"),
                database: getSystemSetting("DB_NAME", "myapp"),
                username: getSystemSetting("DB_USER", ""),
                password: getSystemSetting("DB_PASSWORD", "")
            },
            cache: {
                provider: getSystemSetting("CACHE_PROVIDER", "memory"),
                ttl: val(getSystemSetting("CACHE_TTL", "3600"))
            },
            logging: {
                level: getSystemSetting("LOG_LEVEL", "INFO"),
                file: getSystemSetting("LOG_FILE", "application.log")
            }
        };
    }

    function get(required string key, defaultValue = "") {
        return structFindKey(variables.config, arguments.key)?[1].value ?: arguments.defaultValue;
    }
}
```

### Testing-Friendly Design
```cfscript
// MODERN: Testable component design
component {

    property name="httpService" inject="HttpService";
    property name="cacheService" inject="CacheService";

    function getUserData(required numeric userID) {
        // Check cache first
        var cacheKey = "user_" & arguments.userID;
        var cachedData = cacheService.get(cacheKey);

        if (!isNull(cachedData)) {
            return cachedData;
        }

        // Fetch from API
        var userData = httpService.get("/api/users/" & arguments.userID);

        // Cache for future use
        cacheService.set(cacheKey, userData, 300); // 5 minutes

        return userData;
    }
}
```

### Fluent Interface Pattern
```cfscript
// MODERN: Method chaining for readable APIs
component {

    property name="query" default="";
    property name="params" default="[]";

    function select(columns) {
        variables.query = "SELECT " & arguments.columns;
        return this;
    }

    function from(table) {
        variables.query &= " FROM " & arguments.table;
        return this;
    }

    function where(condition, value) {
        variables.query &= " WHERE " & arguments.condition;
        variables.params.append(arguments.value);
        return this;
    }

    function execute() {
        return queryExecute(variables.query, variables.params);
    }
}

// Usage
results = queryBuilder
    .select("id, name, email")
    .from("users")
    .where("active = ?", true)
    .execute();
```

### Resource Management
```cfscript
// MODERN: Using try/finally for resource cleanup
function processFileWithCleanup(filePath) {
    var fileHandle = "";

    try {
        fileHandle = fileOpen(filePath, "read");

        var results = [];
        while (!fileIsEOF(fileHandle)) {
            var line = fileReadLine(fileHandle);
            results.append(processLine(line));
        }

        return results;
    } finally {
        // Always cleanup resources
        if (isObject(fileHandle)) {
            fileClose(fileHandle);
        }
    }
}
```

## Modern Development Practices

### 1. Variable Scoping
```cfscript
// MODERN: Explicit scoping
function processData(data) {
    var result = [];  // Explicitly scoped

    for (var item in arguments.data) {
        var processed = transformItem(item);  // Local scope
        result.append(processed);
    }

    return result;
}
```

### 2. Type Hinting
```cfscript
// MODERN: Use type hints for clarity
public User function createUser(
    required string email,
    required string firstName,
    required string lastName,
    boolean active = true
) {
    return new User(arguments.email, arguments.firstName, arguments.lastName, arguments.active);
}
```

### 3. Null Safety
```cfscript
// MODERN: Safe navigation and null handling
function getUserDisplayName(user) {
    return user?.profile?.displayName
        ?: user?.firstName & " " & user?.lastName
        ?: user?.email
        ?: "Unknown User";
}
```

### 4. Configuration Over Convention
```cfscript
// MODERN: Configurable behavior
component {

    function init(config = {}) {
        variables.config = {
            timeout: config.timeout ?: 30,
            retries: config.retries ?: 3,
            cache: config.cache ?: true
        };
        return this;
    }
}
```

## Anti-Patterns to Avoid

### 1. God Objects
```cfscript
// AVOID: Single component doing everything
component {
    function processUser() { /* 200+ lines */ }
    function sendEmails() { /* 100+ lines */ }
    function generateReports() { /* 150+ lines */ }
    function handlePayments() { /* 300+ lines */ }
}
```

### 2. Hard-coded Dependencies
```cfscript
// AVOID: Hard-coded dependencies
component {
    function processOrder() {
        var paymentService = new PaymentService();  // Hard-coded!
        var emailService = new EmailService();      // Hard-coded!
    }
}
```

### 3. Mixed Concerns
```cfscript
// AVOID: Business logic mixed with presentation
function getUserList() {
    var users = queryExecute("SELECT * FROM users");
    var html = "<table>";
    for (var user in users) {
        html &= "<tr><td>" & user.name & "</td></tr>";  // Presentation logic!
    }
    html &= "</table>";
    return html;
}
```

## Key Takeaways
- **Script syntax** for business logic components
- **Functional patterns** for data transformation
- **Dependency injection** for loose coupling
- **Explicit scoping** for performance and clarity
- **Type hints** for better documentation
- **Error handling** with specific catch blocks
- **Resource cleanup** in finally blocks
- **Environment-based** configuration

## Related Concepts
- [Component Basics](../components/component-basics.md)
- [Functions](../components/functions.md)
- [Exception Handling](../control-flow/exception-handling.md)
- [Closures](../advanced/closures.md)