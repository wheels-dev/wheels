# Component Properties

## Overview
Properties in CFML components define the data/attributes that objects can hold. With `accessors="true"`, they automatically generate getter and setter methods. Properties support typing, defaults, and can be configured for web services and ORM mapping.

## Syntax
```cfscript
property [attributes] name="propertyName" [type="dataType"] [default="defaultValue"];
```

## Examples

### Basic Property Definitions
```cfscript
component accessors="true" {

    property name="firstName" default="";
    property name="lastName" default="";
    property name="age" type="numeric" default="0";
    property name="addresses" type="array";
    property name="isActive" type="boolean" default="true";
}
```

### Typed Properties
```cfscript
component accessors="true" {

    property name="id" type="string";
    property name="score" type="numeric";
    property name="birthDate" type="date";
    property name="tags" type="array";
    property name="metadata" type="struct";
    property name="user" type="User"; // Custom component type
}
```

### Property Attributes
```cfscript
component accessors="true" {

    // Control getter/setter generation
    property name="readOnly" getter="true" setter="false";
    property name="writeOnly" getter="false" setter="true";

    // Property validation
    property name="email" type="string" required="true";
    property name="status" type="string" validate="regex"
             pattern="^(active|inactive|pending)$";
}
```

### Annotation-Based Properties
```cfscript
component accessors="true" {

    /**
     * The user's age
     * @type numeric
     * @default 0
     * @required false
     */
    property name="age";

    /**
     * User's email address
     * @type string
     * @validate email
     */
    property name="email";
}
```

### Property Usage with Accessors
```cfscript
component accessors="true" {
    property name="firstName";
    property name="lastName";

    function getFullName() {
        return getFirstName() & " " & getLastName();
    }
}

// Usage
user = new User();
user.setFirstName("Luis");
user.setLastName("Majano");

fullName = user.getFullName(); // "Luis Majano"
```

### Manual Property Implementation
```cfscript
component {

    property name="value";

    // Custom getter with validation
    function getValue() {
        if (!structKeyExists(variables, "value")) {
            throw("Value not initialized");
        }
        return variables.value;
    }

    // Custom setter with validation
    function setValue(required newValue) {
        if (isNull(arguments.newValue) || arguments.newValue == "") {
            throw("Value cannot be null or empty");
        }
        variables.value = arguments.newValue;
        return this;
    }
}
```

### ORM Entity Properties
```cfscript
component persistent="true" table="users" accessors="true" {

    property name="id" fieldtype="id" generator="increment";
    property name="username" column="user_name" length="50" notnull="true";
    property name="email" ormtype="string" length="100" unique="true";
    property name="createdDate" ormtype="timestamp" default="now()";

    // Relationships
    property name="profile" fieldtype="one-to-one" cfc="UserProfile";
    property name="orders" fieldtype="one-to-many" cfc="Order" fkcolumn="user_id";
}
```

### Lazy Loading Properties
```cfscript
component accessors="true" {

    property name="expensiveData" lazy="true";

    function getExpensiveData() {
        if (!structKeyExists(variables, "expensiveData")) {
            // Lazy load expensive computation
            variables.expensiveData = performExpensiveCalculation();
        }
        return variables.expensiveData;
    }
}
```

## Key Points
- Properties are stored in the `variables` scope by default
- `accessors="true"` auto-generates `get{PropertyName}()` and `set{PropertyName}()` methods
- Property names are case-insensitive but conventionally camelCase
- Default values are assigned during object creation
- Properties support full type validation and conversion
- Can be configured for ORM persistence and web service exposure

## Common Property Attributes
- `type` - Data type (string, numeric, boolean, array, struct, component name)
- `default` - Default value when object is created
- `getter` - Generate getter method (true/false)
- `setter` - Generate setter method (true/false)
- `required` - Property must have value
- `validate` - Validation type (email, regex, range, etc.)

## ORM-Specific Attributes
- `fieldtype` - ORM field type (id, column, one-to-one, one-to-many, etc.)
- `column` - Database column name
- `ormtype` - Hibernate type mapping
- `length` - Maximum field length
- `notnull` - Database not-null constraint

## Best Practices
- Use meaningful property names that describe the data
- Provide appropriate default values
- Use typing for better code documentation and validation
- Consider lazy loading for expensive properties
- Document properties with JavaDoc comments
- Use ORM annotations for database-mapped entities

## Related Concepts
- [Component Basics](component-basics.md)
- [Functions](functions.md)
- [Variable Scopes](../data-types/variable-scopes.md)
- [ORM Basics](../database/orm-basics.md)