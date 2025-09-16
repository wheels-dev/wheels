# Structure Basics

## Overview
Structures in CFML are unordered collections of key-value pairs, similar to dictionaries or hash maps. They're based on Java's Map interface and provide flexible data storage with various specialized types for different use cases.

## Syntax
```cfscript
// Literal syntax
structure = { key1: value1, key2: value2 };

// Constructor function
structure = structNew([type]);
```

## Examples

### Basic Structure Creation
```cfscript
// Empty structure
person = {};

// Structure with initial values
person = {
    name: "Luis",
    age: 35,
    active: true
};

// Case-sensitive keys (quoted)
person = {
    "firstName": "Luis",
    "lastName": "Majano",
    "isActive": true
};
```

### Value Access Methods
```cfscript
person = { name: "Luis", age: 35 };

// Dot notation (converts to uppercase)
name = person.name;
age = person.age;

// Array notation (preserves case)
name = person["name"];
age = person["age"];

// Using structFind()
name = person.find("name");
name = structFind(person, "name");
```

### Adding and Modifying Values
```cfscript
person = { name: "Luis" };

// Add new keys
person.age = 35;
person["email"] = "luis@ortus.com";

// Update existing values
person.age = 36;
person["age"] = 37;

// Using struct functions
person.insert("city", "Boston");
person.update("city", "Miami");
structInsert(person, "country", "USA");
```

### Safe Navigation
```cfscript
user = { profile: { name: "Luis" } };

// Safe navigation to avoid errors
name = user?.profile?.name;           // "Luis"
email = user?.profile?.email;         // null (no error)
email = user?.profile?.email ?: "N/A"; // "N/A" (with default)
```

### Structure Types
```cfscript
// Case-sensitive structure
sensitiveStruct = structNew("casesensitive");
sensitiveStruct["Name"] = "Luis";
sensitiveStruct["name"] = "Maria"; // Different from "Name"

// Ordered structure (maintains insertion order)
orderedStruct = structNew("ordered");
orderedStruct = [:]; // literal syntax

// Adobe case-sensitive literal syntax
caseStruct = ${ Name: "Luis" };
```

## Key Points
- Keys are case-insensitive by default (stored uppercase)
- Use quoted keys to preserve exact casing
- Array notation preserves case, dot notation does not
- Structures are passed by reference to functions
- Unordered by default (except ordered/linked types)
- Based on Java's Map interface

## Common Structure Types
- `normal` - Standard case-insensitive structure
- `casesensitive` - Keys are case-sensitive
- `ordered`/`linked` - Maintains insertion order
- `ordered-casesensitive` - Both ordered and case-sensitive
- `soft` - Lucee only: soft references for memory management
- `synchronized` - Lucee only: thread-safe operations
- `weak` - Lucee only: weak references

## Related Concepts
- [Structure Methods](structure-methods.md)
- [Structure Iteration](structure-iteration.md)
- [Variables](../variables.md)
- [Variable Scopes](../variable-scopes.md)