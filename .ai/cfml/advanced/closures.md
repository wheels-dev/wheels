# Closures

## Overview
Closures in CFML are functions that have access to variables in their lexical environment. They enable functional programming patterns, delayed execution, and powerful abstractions. Closures retain references to their surrounding scope even after the outer function has finished executing.

## Syntax
```cfscript
// Anonymous closure assigned to variable
var closure = function(params) { return result; };

// Arrow function syntax (modern engines)
var arrowClosure = (params) => result;
```

## Examples

### Basic Closure with Lexical Scope Access
```cfscript
function createGreeter() {
    var greeting = "Hello";

    // Closure has access to 'greeting' variable
    var greeterClosure = function(name) {
        return greeting & ", " & name & "!";
    };

    return greeterClosure;
}

greet = createGreeter();
message = greet("Luis"); // "Hello, Luis!"
```

### Higher-Order Functions
```cfscript
function makeAdder(required numeric x) {
    return function(required numeric y) {
        return x + y; // 'x' from outer scope
    };
}

addFive = makeAdder(5);
result = addFive(10); // 15

// Create multiple specialized functions
addOne = makeAdder(1);
addTen = makeAdder(10);
```

### Functional Array Operations
```cfscript
products = [
    { name: "Laptop", price: 999, category: "electronics" },
    { name: "Book", price: 25, category: "media" },
    { name: "Mouse", price: 45, category: "electronics" }
];

// Filter using closure
expensiveItems = products.filter(function(item) {
    return item.price > 50;
});

// Map with closure
productNames = products.map(function(item) {
    return item.name;
});

// Reduce with closure
totalValue = products.reduce(function(sum, item) {
    return sum + item.price;
}, 0);
```

### Event Handler Pattern
```cfscript
function createEventHandler(eventType) {
    var timestamp = now();

    return function(data) {
        writeLog("Event: #eventType# at #timestamp#");
        writeLog("Data: #serializeJSON(data)#");
        // Process event data
    };
}

clickHandler = createEventHandler("click");
submitHandler = createEventHandler("submit");

// Later use
clickHandler({ x: 100, y: 200 });
```

### Arrow Functions (Modern Syntax)
```cfscript
// Simple arrow function
square = (x) => x * x;

// Multi-parameter arrow function
add = (x, y) => x + y;

// Complex arrow function with block body
processUser = (user) => {
    if (user.isActive) {
        return user.name.toUpperCase();
    } else {
        return "Inactive: " & user.name;
    }
};

// Array operations with arrow functions
numbers = [1, 2, 3, 4, 5];
doubled = numbers.map((n) => n * 2);
evens = numbers.filter((n) => n % 2 == 0);
```

### Closure Scope Demonstration
```cfscript
function outerFunction(outerParam) {
    var outerVar = "outer";

    function innerFunction(innerParam) {
        var innerVar = "inner";

        // Closure has access to all scopes
        return function(closureParam) {
            return outerParam & " " & outerVar & " " & innerParam & " " & innerVar & " " & closureParam;
        };
    }

    return innerFunction("middle");
}

myClosure = outerFunction("first");
result = myClosure("last"); // "first outer middle inner last"
```

### Practical: Configuration Builder Pattern
```cfscript
function createConfigBuilder() {
    var config = {};

    return {
        setDatabase: function(dsn) {
            config.database = dsn;
            return this; // Enable chaining
        },

        setCache: function(provider) {
            config.cache = provider;
            return this;
        },

        setTimeout: function(seconds) {
            config.timeout = seconds;
            return this;
        },

        build: function() {
            return duplicate(config); // Return copy
        }
    };
}

// Usage with method chaining
appConfig = createConfigBuilder()
    .setDatabase("myDB")
    .setCache("redis")
    .setTimeout(30)
    .build();
```

### Delayed Execution Pattern
```cfscript
function createValidator() {
    var rules = [];

    return {
        addRule: function(ruleFn) {
            rules.append(ruleFn);
            return this;
        },

        validate: function(data) {
            for (var rule in rules) {
                if (!rule(data)) {
                    return false;
                }
            }
            return true;
        }
    };
}

// Setup validation rules
validator = createValidator()
    .addRule(function(data) { return structKeyExists(data, "email"); })
    .addRule(function(data) { return len(data.email) > 0; })
    .addRule(function(data) { return find("@", data.email); });

// Later validation
isValid = validator.validate({ email: "user@domain.com" });
```

## Key Points
- Closures retain access to their lexical environment
- Variables from outer scopes are "captured" by reference
- Enable functional programming patterns (map, filter, reduce)
- Perfect for event handlers and callback functions
- Arrow functions provide concise syntax (Lucee/Adobe 2018+)
- Useful for creating specialized functions and configuration builders

## Closure Scope Chain
1. Closure's local scope
2. Closure's arguments scope
3. Outer function's local scope
4. Owner function's local scope
5. ColdFusion built-in scopes

## Common Use Cases
- **Event Handlers**: Capture context for event processing
- **Functional Programming**: Array transformations and filtering
- **Factory Functions**: Create specialized function instances
- **Configuration**: Build objects with captured settings
- **Partial Application**: Create functions with pre-filled parameters

## Performance Considerations
- Closures maintain references to outer scope variables
- Can prevent garbage collection of outer scope
- Use sparingly in memory-constrained environments
- Arrow functions may have slight performance benefits

## Related Concepts
- [Functions](../components/functions.md)
- [Array Methods](../data-types/arrays/array-methods.md)
- [Functional Programming](../best-practices/functional-patterns.md)
- [Variable Scopes](../data-types/variable-scopes.md)