# Variables

## Overview
CFML variables are dynamic pointers to data that can hold any value type. They don't require type declaration and can change types at runtime. Variables are case-insensitive but best practice is to maintain consistent casing.

## Syntax
```cfscript
variableName = value;
```

## Examples

### Basic Variable Assignment
```cfscript
a = "string";           // string
b = now();             // datetime
c = 123;               // integer
d = 1.34;              // float
f = false;             // boolean
```

### Dynamic Typing
```cfscript
a = "Hello Luis";      // string
a = [1,2,3];          // now it's an array
a = { name: "Luis" };  // now it's a structure
```

### Variable Interpolation
```cfscript
name = "Luis";
greeting = "Hello #name#, how are you?";
writeOutput(greeting);
```

### Variable Existence Checking
```cfscript
// Using isDefined() - variable name in quotes
if (isDefined("myVariable")) {
    writeOutput(myVariable);
}

// Using isNull() - variable NOT in quotes
if (!isNull(myVariable)) {
    writeOutput(myVariable);
}

// Using structKeyExists()
if (structKeyExists(variables, "myVariable")) {
    writeOutput(myVariable);
}
```

## Key Points
- Variables are dynamically typed and can change types at runtime
- Case-insensitive but consistent casing is recommended
- Assignments evaluate from right to left
- String interpolation uses `#variableName#` syntax
- Semi-colons are optional in modern engines
- All variables are stored in scopes (structures/hash maps)
- CFML provides type validation functions (`isArray()`, `isString()`, etc.)

## Related Concepts
- [Variable Scopes](variable-scopes.md)
- [Strings](strings/string-literals.md)
- [Arrays](arrays/array-creation.md)
- [Structures](structures/structure-basics.md)