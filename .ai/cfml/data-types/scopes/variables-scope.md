# Variables Scope in CFML

## Overview
The `variables` scope is the default scope in CFML. Variables declared without an explicit scope prefix are automatically assigned to the `variables` scope. Understanding variable scoping is crucial for proper CFML development.

## Basic Variable Declaration

### Implicit Variables Scope
```cfscript
// These are equivalent
myVariable = "Hello World";
variables.myVariable = "Hello World";

// Both create a variable in the variables scope
writeOutput(myVariable);           // Hello World
writeOutput(variables.myVariable); // Hello World
```

### Tag-based Declaration
```cfml
<!--- These are equivalent --->
<cfset myVariable = "Hello World">
<cfset variables.myVariable = "Hello World">

<!--- Both can be referenced without scope prefix --->
<cfoutput>#myVariable#</cfoutput>
<cfoutput>#variables.myVariable#</cfoutput>
```

## Scope Characteristics

### Local to Template/Component
```cfscript
// In a .cfm file
variables.pageTitle = "Home Page";
variables.userData = {name: "John", age: 30};

// These variables are only accessible within this template
function displayUserInfo() {
    // Can access variables scope from within functions in same component
    writeOutput("User: " & variables.userData.name);
}
```

### Component Variables Scope
```cfscript
component {
    // Variables scope in components
    variables.componentName = "UserService";
    variables.version = "1.0";

    function init() {
        variables.initialized = true;
        return this;
    }

    function getName() {
        // Functions can access variables scope
        return variables.componentName;
    }

    function processUser(userData) {
        // Local variables within function (implicit variables scope)
        processedData = processUserData(userData);

        // This creates variables.processedData accessible to other functions
        return processedData;
    }

    function getProcessedData() {
        // Can access processedData from other function
        return variables.processedData ?: {};
    }
}
```

## Function-Level Scoping

### Local vs Variables Scope
```cfscript
component {
    variables.componentData = "component level";

    function demonstrateScoping() {
        // Without 'var' or 'local' - goes to variables scope
        unscoped = "accessible to other functions";

        // With 'var' - local to this function only
        var localVar = "only in this function";

        // With 'local' prefix - also local to this function
        local.anotherLocal = "also only in this function";

        // Variables scope - explicit
        variables.componentLevel = "accessible to all functions";
    }

    function accessTest() {
        // Can access unscoped and variables.componentLevel
        writeOutput(variables.unscoped);        // Works
        writeOutput(variables.componentLevel);  // Works

        // Cannot access localVar or local.anotherLocal
        // These would cause errors or be undefined
    }
}
```

### Best Practice for Local Variables
```cfscript
function processData(inputData) {
    // Always use 'var' for function-local variables
    var result = {};
    var errorCount = 0;
    var processedItems = [];

    // Process data without affecting variables scope
    for (var item in inputData) {
        var processedItem = processItem(item);
        if (processedItem.success) {
            arrayAppend(processedItems, processedItem.data);
        } else {
            errorCount++;
        }
    }

    result.items = processedItems;
    result.errorCount = errorCount;

    return result;
}
```

## Scope Visibility Rules

### Within Components
```cfscript
component {
    variables.publicData = "available to all functions";

    function functionA() {
        variables.sharedData = "set in function A";
        var privateData = "only in function A";
    }

    function functionB() {
        // Can access sharedData set in functionA
        if (structKeyExists(variables, "sharedData")) {
            writeOutput(variables.sharedData); // Works
        }

        // Cannot access privateData from functionA
        // This would be undefined
    }

    function getComponentState() {
        // Return all variables scope data
        return variables;
    }
}
```

### External Access Restrictions
```cfscript
// In main template or other component
var userService = new UserService();

// Cannot directly access variables scope from outside
// This would cause an error:
// userService.variables.someData

// Must use public methods to access data
var componentName = userService.getName(); // Allowed
```

## Common Patterns

### Component Initialization
```cfscript
component {
    // Set default values in variables scope
    variables.initialized = false;
    variables.settings = {};
    variables.dataCache = {};

    function init(settings = {}) {
        variables.settings = arguments.settings;
        variables.initialized = true;
        variables.dataCache = {};

        return this;
    }

    function isInitialized() {
        return variables.initialized;
    }

    function getSetting(key, defaultValue = "") {
        return structKeyExists(variables.settings, key) ?
            variables.settings[key] : defaultValue;
    }
}
```

### Shared Utilities
```cfscript
component {
    // Shared utility functions and data
    variables.utils = {
        formatCurrency: function(amount) {
            return dollarFormat(amount);
        },
        formatDate: function(date) {
            return dateFormat(date, "mm/dd/yyyy");
        }
    };

    variables.constants = {
        MAX_ITEMS: 100,
        DEFAULT_TIMEOUT: 30,
        API_VERSION: "1.0"
    };

    function formatUserData(userData) {
        var formatted = {};
        formatted.displayName = userData.firstName & " " & userData.lastName;
        formatted.salary = variables.utils.formatCurrency(userData.salary);
        formatted.hireDate = variables.utils.formatDate(userData.hireDate);

        return formatted;
    }
}
```

## Advanced Scoping Scenarios

### Mixing Scopes Safely
```cfscript
component {
    variables.componentId = createUUID();
    variables.metrics = {
        callCount: 0,
        errorCount: 0
    };

    function publicMethod(data) {
        // Increment call counter (variables scope)
        variables.metrics.callCount++;

        // Local processing variables
        var result = {};
        var hasErrors = false;

        try {
            // Use local variables for processing
            var processedData = processBusinessLogic(data);
            result.success = true;
            result.data = processedData;

        } catch (any e) {
            // Update component-level error tracking
            variables.metrics.errorCount++;
            result.success = false;
            result.error = e.message;
            hasErrors = true;
        }

        return result;
    }

    function getMetrics() {
        // Return copy to prevent external modification
        return duplicate(variables.metrics);
    }
}
```

### Dynamic Variable Creation
```cfscript
component {
    function setDynamicProperty(key, value) {
        // Dynamically create variables scope properties
        variables[key] = value;
    }

    function getDynamicProperty(key, defaultValue = "") {
        return structKeyExists(variables, key) ?
            variables[key] : defaultValue;
    }

    function getAllProperties() {
        // Return all variables scope content
        var result = {};
        for (var key in variables) {
            // Skip functions and system properties
            if (!isCustomFunction(variables[key])) {
                result[key] = variables[key];
            }
        }
        return result;
    }
}
```

## Memory and Performance Considerations

### Cleanup Pattern
```cfscript
component {
    variables.largeDataSet = [];
    variables.cacheData = {};

    function cleanup() {
        // Clear large data structures
        variables.largeDataSet = [];
        variables.cacheData = {};

        // Set references to null for garbage collection
        variables.expensiveObject = javaCast("null", "");
    }

    function onApplicationEnd() {
        cleanup();
    }
}
```

## Key Points

- `variables` is the default scope in CFML
- Variables in `variables` scope are accessible to all functions within the same component/template
- Use `var` keyword for function-local variables to avoid scope pollution
- Variables scope is not accessible from outside the component
- Each component instance has its own `variables` scope
- Functions can read and modify variables scope data
- Always initialize variables scope properties in components
- Use proper scoping to prevent variable conflicts and memory leaks

## Related Concepts

- [Application Scope](application-scope.md)
- [Local Scope](local-scope.md)
- [Component Basics](../../components/component-basics.md)
- [Functions](../../components/functions.md)