# Variable Scopes

## Overview
CFML organizes variables into different scopes based on context and persistence requirements. All scopes are implemented as structures (hash maps) for key-value storage. Understanding scopes is crucial for performance and avoiding variable conflicts.

## Syntax
```cfscript
scopeName.variableName = value;
// or unscoped (searches scope chain)
variableName = value;
```

## Examples

### Persistence Scopes
```cfscript
// Application-wide variables
application.appName = "MyApp";

// Session-specific variables
session.userID = 12345;

// Single request variables
request.startTime = now();

// Client storage (cookies/database)
client.userPreferences = "dark_mode";

// Server RAM storage
server.startupTime = now();
```

### Component Scopes
```cfscript
component {

    // Private scope - internal to CFC only
    variables.privateData = "secret";

    // Public scope - accessible from outside
    this.publicData = "visible";

    function myMethod() {
        // Function-local scope
        var localVar = "function only";
        local.anotherLocal = "also local";

        // Access arguments
        return arguments.param1;
    }
}
```

### Template Scopes
```cfscript
// Default scope for variables
variables.myVar = "hello";

// Same as above (variables is default)
myVar = "hello";

// Form and URL scopes
echo("Form field: " & form.username);
echo("URL param: " & url.action);
```

### Explicit Scoping Best Practice
```cfscript
// BAD - unscoped variable lookup is slow
myVar = "hello";

// GOOD - explicit scoping is faster
variables.myVar = "hello";

// GOOD - accessing form data
if (structKeyExists(form, "username")) {
    variables.username = form.username;
}
```

## Key Points
- **Performance**: Explicit scoping improves performance by avoiding scope chain lookup
- **Variables scope**: Default scope for variable assignments
- **Case-insensitive**: All scope names are case-insensitive
- **Scope chain**: Unscoped variables search in specific order (Local → Arguments → Thread → Variables → CGI → URL → Form → Cookie → Client)
- **Memory references**: Structures are passed by reference, not value
- **Thread safety**: Most scopes are not thread-safe by default

## Scope Search Order (Unscoped Variables)
1. Local (function-local only)
2. Arguments
3. Thread local (inside threads only)
4. Query (in query loops)
5. Thread
6. Variables
7. CGI
8. CFFILE
9. URL
10. Form
11. Cookie
12. Client

## Related Concepts
- [Variables](variables.md)
- [Functions](../components/functions.md)
- [Components](../components/component-basics.md)
- [Threading](../advanced/threading.md)