# Struct Creation in CFML

## Overview
CFML structures (similar to objects/dictionaries in other languages) are key-value collections that support multiple creation methods and types. Modern CFML offers literal syntax and various struct types for different use cases.

## Basic Struct Creation

### Literal Syntax (Modern Approach)
```cfscript
// Empty struct
var person = {};

// Struct with initial values
var user = {
    name: "John Doe",
    age: 30,
    email: "john@example.com",
    active: true
};

// Mixed data types
var mixed = {
    id: 1,
    data: ["a", "b", "c"],
    config: {theme: "dark", lang: "en"},
    callback: function() { return "hello"; }
};
```

### Traditional Function Syntax
```cfscript
// Empty struct using structNew()
var person = structNew();

// Populate after creation
person.name = "John Doe";
person["age"] = 30;
person.email = "john@example.com";
```

## Advanced Struct Types (CF2016+)

### Ordered Structs
```cfscript
// Ordered struct maintains insertion order
var orderedData = structNew("ordered");
orderedData.first = "A";
orderedData.second = "B";
orderedData.third = "C";

// Literal syntax for ordered struct
var orderedLiteral = [:]; // Empty ordered struct
var orderedWithData = [=]; // Alternative syntax

// With initial data (order preserved)
var config = [=];
config.database = "mydb";
config.username = "user";
config.password = "pass";
```

### Case-Sensitive Structs (CF2021+)
```cfscript
// Case-sensitive struct
var caseSensitive = structNew("casesensitive");
caseSensitive.Name = "John"; // Capital N
caseSensitive.name = "Jane"; // Lowercase n - different key

// Literal syntax
var csStruct = ${
    "FirstName": "John",
    "firstName": "Jane"  // Different from FirstName
};

// Ordered and case-sensitive
var orderedCS = structNew("ordered-casesensitive");
var orderedCSLiteral = $[=];
```

### Sorted Structs (CF2016 Update 3+)
```cfscript
// Text-based sorting
var textSorted = structNew("ordered", "text", "asc");
textSorted.zebra = "Z";
textSorted.apple = "A";
textSorted.banana = "B";
// Keys will be ordered: apple, banana, zebra

// Numeric sorting
var numericSorted = structNew("ordered", "numeric", "desc");
numericSorted["10"] = "ten";
numericSorted["2"] = "two";
numericSorted["100"] = "hundred";
// Keys ordered: 100, 10, 2

// Custom sorting with callback
var customSorted = structNew("ordered", function(a, b) {
    // Custom comparison logic
    return len(a) - len(b); // Sort by key length
});
```

## Dynamic Struct Creation

### From Arrays
```cfscript
// Create struct from parallel arrays
var keys = ["name", "age", "city"];
var values = ["John", 30, "NYC"];
var person = {};

for (var i = 1; i <= arrayLen(keys); i++) {
    person[keys[i]] = values[i];
}

// Using arrayEach with closure
var person2 = {};
keys.each(function(key, index) {
    person2[key] = values[index];
});
```

### From Query Data
```cfscript
// Convert query row to struct
var users = queryNew("id,name,email", "integer,varchar,varchar", [
    [1, "John", "john@example.com"],
    [2, "Jane", "jane@example.com"]
]);

// Single row to struct
var firstUser = {};
var columnList = users.columnList;
for (var col in listToArray(columnList)) {
    firstUser[col] = users[col][1];
}

// All rows to array of structs
var userStructs = [];
for (var row = 1; row <= users.recordCount; row++) {
    var userStruct = {};
    for (var col in listToArray(columnList)) {
        userStruct[col] = users[col][row];
    }
    arrayAppend(userStructs, userStruct);
}
```

## Nested Structures

### Deep Nesting
```cfscript
var application = {
    config: {
        database: {
            host: "localhost",
            port: 3306,
            credentials: {
                username: "user",
                password: "pass"
            }
        },
        cache: {
            enabled: true,
            ttl: 3600,
            providers: ["memory", "redis"]
        }
    },
    features: {
        authentication: true,
        reporting: false,
        api: {
            version: "2.0",
            endpoints: ["/users", "/orders", "/products"]
        }
    }
};

// Accessing nested values
var dbHost = application.config.database.host;
var apiVersion = application.features.api.version;
```

### Safe Navigation
```cfscript
function getNestedValue(struct, path, defaultValue = "") {
    var current = struct;
    var keys = listToArray(path, ".");

    for (var key in keys) {
        if (isStruct(current) && structKeyExists(current, key)) {
            current = current[key];
        } else {
            return defaultValue;
        }
    }

    return current;
}

// Usage
var dbPort = getNestedValue(application, "config.database.port", 3306);
var invalidPath = getNestedValue(application, "config.nonexistent.value", "default");
```

## Struct Factories

### Configuration Builder
```cfscript
function createConfig(environment = "production") {
    var baseConfig = {
        appName: "MyApp",
        version: "1.0",
        debug: false
    };

    var envConfigs = {
        development: {
            debug: true,
            database: "dev_db",
            logLevel: "DEBUG"
        },
        testing: {
            debug: true,
            database: "test_db",
            logLevel: "INFO"
        },
        production: {
            debug: false,
            database: "prod_db",
            logLevel: "ERROR"
        }
    };

    // Merge base config with environment-specific config
    if (structKeyExists(envConfigs, environment)) {
        structAppend(baseConfig, envConfigs[environment]);
    }

    return baseConfig;
}

var devConfig = createConfig("development");
var prodConfig = createConfig("production");
```

### Object Factory Pattern
```cfscript
function createUser(name, email, role = "user") {
    return {
        id: createUUID(),
        name: arguments.name,
        email: arguments.email,
        role: arguments.role,
        createdAt: now(),
        isActive: true,

        // Methods as struct properties
        getName: function() {
            return this.name;
        },

        isAdmin: function() {
            return this.role == "admin";
        },

        toJSON: function() {
            return serializeJSON(this);
        }
    };
}

var admin = createUser("John Admin", "admin@example.com", "admin");
var regularUser = createUser("Jane User", "jane@example.com");
```

## Advanced Patterns

### Immutable Struct Pattern
```cfscript
function createImmutableStruct(data) {
    var immutable = duplicate(data);

    // Add helper methods that return new instances
    immutable.set = function(key, value) {
        var newStruct = duplicate(this);
        newStruct[key] = value;
        return createImmutableStruct(newStruct);
    };

    immutable.get = function(key, defaultValue = "") {
        return structKeyExists(this, key) ? this[key] : defaultValue;
    };

    immutable.keys = function() {
        return structKeyArray(this);
    };

    return immutable;
}

var original = createImmutableStruct({name: "John", age: 30});
var updated = original.set("age", 31); // Returns new instance
// original remains unchanged
```

### Struct Validation
```cfscript
function createValidatedStruct(schema, data = {}) {
    var validated = {};

    for (var field in schema) {
        var fieldDef = schema[field];
        var value = structKeyExists(data, field) ? data[field] : fieldDef.default;

        // Type validation
        if (structKeyExists(fieldDef, "type")) {
            if (fieldDef.type == "string" && !isSimpleValue(value)) {
                throw("Field '#field#' must be a string");
            } else if (fieldDef.type == "numeric" && !isNumeric(value)) {
                throw("Field '#field#' must be numeric");
            } else if (fieldDef.type == "boolean" && !isBoolean(value)) {
                throw("Field '#field#' must be boolean");
            }
        }

        // Required validation
        if (structKeyExists(fieldDef, "required") && fieldDef.required && isEmpty(value)) {
            throw("Field '#field#' is required");
        }

        validated[field] = value;
    }

    return validated;
}

// Usage
var userSchema = {
    name: {type: "string", required: true},
    age: {type: "numeric", default: 0},
    active: {type: "boolean", default: true}
};

var validUser = createValidatedStruct(userSchema, {
    name: "John",
    age: 30
});
```

## Key Points

- Use literal syntax `{}` for modern CFML development
- Struct keys are case-insensitive by default (except case-sensitive types)
- Use `structNew("ordered")` or `[:]` for ordered structs
- Case-sensitive structs available in CF2021+ with `${}` syntax
- Structs are passed by reference
- Use `structKeyExists()` to safely check for key existence
- Member functions available on structs (CF11+)
- Sorted structs can use custom callback functions for ordering

## Related Concepts

- [Struct Methods](struct-methods.md)
- [Array Creation](../arrays/array-creation.md)
- [Variables Scope](../scopes/variables-scope.md)
- [Object-Oriented Programming](../../components/component-basics.md)