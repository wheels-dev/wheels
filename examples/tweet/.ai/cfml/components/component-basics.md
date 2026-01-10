# Component Basics

## Overview
Components (CFCs) are CFML's object-oriented constructs that combine data (properties) and behavior (methods). They support inheritance, interfaces, encapsulation, and can be used for web services, ORM entities, and dependency injection.

## Syntax
```cfscript
component [attributes] {
    // properties
    // methods
    // constructor
}
```

## Examples

### Basic Component Structure
```cfscript
/**
 * I represent a user in the system
 * @author Luis Majano
 */
component accessors="true" {

    /**
     * The name of the user
     */
    property name="name";

    /**
     * The age of the user
     */
    property name="age" type="numeric";

    /**
     * Constructor
     */
    function init(required name) {
        variables.name = arguments.name;
        return this;
    }

    function run() {
        // run baby, run!
    }
}
```

### Creating Component Instances
```cfscript
// Using 'new' keyword (calls init() automatically)
user = new User(name="Luis");

// Using createObject() (must call init() manually)
user = createObject("component", "User").init(name="Luis");

// Execute methods
user.run();
```

### Component Scopes
```cfscript
component {

    // Pseudo-constructor: executes when object is created
    this.createdAt = now();
    variables.privateData = "secret";

    function init() {
        // Constructor method
        variables.initialized = true;
        return this;
    }

    function publicMethod() {
        // Accessible from outside (this & variables scope)
        return "public";
    }

    private function privateMethod() {
        // Only accessible internally (variables scope only)
        return "private";
    }
}
```

### Component Attributes
```cfscript
// Multiple attributes
component accessors="true"
         serializable="false"
         extends="BaseUser"
         implements="IUser" {

    property name="firstName";
    property name="lastName";
}

// Interface implementation
component implements="cachebox.system.cache.ICacheProvider" {
    // Must implement interface methods
}
```

### Annotation-Based Attributes
```cfscript
/**
 * My User Component
 * @extends BaseUser
 * @accessors true
 * @serializable true
 */
component {

    /**
     * User's first name
     * @type string
     * @default ""
     */
    property name="firstName";
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

    function getValue() {
        return variables.value;
    }
}

// Usage with chaining
obj = new MyClass()
    .setValue("hello")
    .setValue("world");
```

## Key Points
- Components are blueprints for objects (classes)
- Support single inheritance via `extends` attribute
- Can implement multiple interfaces
- **this scope**: Public visibility (external access)
- **variables scope**: Private visibility (internal only)
- **static scope**: Class-level variables/methods (Lucee only)
- Pseudo-constructor executes before init() method
- Components are first-class objects in CFML

## Common Attributes
- `accessors` - Auto-generate getters/setters for properties
- `extends` - Inherit from another component
- `implements` - Implement one or more interfaces
- `persistent` - Make component a Hibernate ORM entity
- `serializable` - Allow serialization to string/binary format
- `output` - Allow output to response stream

## Component Lifecycle
1. `new` or `createObject()` called
2. Pseudo-constructor executes
3. `init()` method called automatically (if using `new`)
4. Object ready for use

## Best Practices
- Always provide a constructor (`init()` method)
- Use `accessors="true"` for automatic property methods
- Document components and methods with JavaDoc syntax
- Follow single responsibility principle
- Use dependency injection for loose coupling
- Prefer composition over inheritance

## Related Concepts
- [Properties](properties.md)
- [Functions](functions.md)
- [Inheritance](inheritance.md)
- [Interfaces](interfaces.md)
- [Static Methods](static-methods.md)