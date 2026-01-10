# Component Functions

## Overview
Functions (methods) in CFML components define the behavior and actions objects can perform. They support various access modifiers, return types, dynamic arguments, and can be manipulated at runtime due to CFML's dynamic nature.

## Syntax
```cfscript
[access] [modifier] [returnType] function functionName([arguments]) {
    // function body
    [return value;]
}
```

## Examples

### Basic Function Definitions
```cfscript
component {

    function hello() {
        return "Hello, World!";
    }

    public string function greet(required string name) {
        return "Hello, #arguments.name#!";
    }

    private void function logMessage(required string message) {
        writeLog(arguments.message);
    }
}
```

### Function Access Modifiers
```cfscript
component {

    // Public - accessible from outside
    public function publicMethod() {
        return "accessible everywhere";
    }

    // Private - internal access only
    private function privateMethod() {
        return "internal only";
    }

    // Package - same package access
    package function packageMethod() {
        return "package level access";
    }

    // Remote - accessible via web services/REST
    remote function remoteMethod() {
        return "web service accessible";
    }
}
```

### Function Modifiers
```cfscript
component {

    // Static function (Lucee, Adobe 2021+)
    public static function createInstance(required name) {
        return new User(arguments.name);
    }

    // Final function (cannot be overridden)
    public final function getId() {
        return variables.id;
    }

    // Abstract function (must be implemented by subclasses)
    public abstract function processData();
}
```

### Dynamic Arguments
```cfscript
component {

    // Function accepts any number of arguments
    function flexibleFunction() {
        writeDump(arguments); // All passed arguments

        for (var key in arguments) {
            writeOutput("Arg #key#: #arguments[key]#");
        }
    }

    // Named and positional argument support
    function calculate(required numeric a, required numeric b) {
        return a + b;
    }
}

// Usage examples
obj = new MyComponent();

// Positional arguments
result = obj.calculate(10, 20);

// Named arguments
result = obj.calculate(a=10, b=20);

// Argument collection (struct)
args = {a: 10, b: 20};
result = obj.calculate(argumentCollection=args);

// Argument collection (array)
args = [10, 20];
result = obj.calculate(argumentCollection=args);
```

### Function Return Types and Documentation
```cfscript
component {

    /**
     * Calculates user's age based on birth date
     *
     * @birthDate The user's birth date
     * @return The calculated age in years
     */
    public numeric function calculateAge(required date birthDate) {
        var today = now();
        return dateDiff("yyyy", arguments.birthDate, today);
    }

    /**
     * Validates email address format
     *
     * @email Email address to validate
     * @return True if valid, false otherwise
     */
    public boolean function isValidEmail(required string email) {
        return reFindNoCase("^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$", arguments.email);
    }
}
```

### Function Scoping and Local Variables
```cfscript
component {

    function processData(required array data) {
        // Always var scope local variables
        var result = [];
        var i = 0;

        // Alternative local scope syntax
        local.processedCount = 0;
        local.errors = [];

        for (var item in arguments.data) {
            try {
                var processed = processItem(item);
                result.append(processed);
                local.processedCount++;
            }
            catch (any e) {
                local.errors.append(e.message);
            }
        }

        return {
            results: result,
            count: local.processedCount,
            errors: local.errors
        };
    }
}
```

### Method Chaining
```cfscript
component {

    property name="value";

    function setValue(required val) {
        variables.value = arguments.val;
        return this; // Enable chaining
    }

    function transform(required func) {
        variables.value = func(variables.value);
        return this;
    }

    function getValue() {
        return variables.value;
    }
}

// Chainable usage
result = obj
    .setValue("hello world")
    .transform(function(str) { return ucase(str); })
    .transform(function(str) { return reverse(str); })
    .getValue();
```

### Function Metadata and Attributes
```cfscript
component {

    /**
     * Custom web service method
     *
     * @output false
     * @returnFormat JSON
     * @httpMethod POST
     */
    remote function getData() description="Retrieves user data" {
        return getUserData();
    }

    // Using annotation-based metadata
    /**
     * Process payment
     * @secure true
     * @audit true
     * @returnFormat JSON
     */
    function processPayment(required amount) {
        // Implementation
    }
}
```

## Key Points
- Functions are **first-class objects** - can be manipulated at runtime
- Access determines scope placement: public/remote go in `this` and `variables`, private/package only in `variables`
- Dynamic language allows runtime function injection, removal, and renaming
- All functions default to `any` return type and `public` access
- Local variables must be var scoped to avoid memory leaks
- Arguments can be accessed positionally, by name, or via collections

## Function Access Scope Placement
- **Public/Remote**: Placed in both `this` and `variables` scopes
- **Private/Package**: Placed only in `variables` scope
- This enables dynamic runtime manipulation of object behavior

## Variable Scope Chain (for unscoped variables in functions)
1. Local (function-local)
2. Arguments
3. Thread local (in threads only)
4. Query (in query loops)
5. Thread
6. Variables
7. CGI, CFFILE, URL, Form, Cookie, Client

## Best Practices
- Always use explicit return types for better documentation
- Var scope all local variables to prevent memory leaks
- Use meaningful function names and parameter names
- Document functions with JavaDoc syntax
- Validate input arguments appropriately
- Use access modifiers to enforce encapsulation
- Return `this` from setters to enable method chaining

## Related Concepts
- [Component Basics](component-basics.md)
- [Properties](properties.md)
- [Variable Scopes](../data-types/variable-scopes.md)
- [Inheritance](inheritance.md)
- [Static Methods](static-methods.md)