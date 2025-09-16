# String Interpolation

## Overview
String interpolation in CFML allows embedding variable values and expressions directly within strings using hash (`#`) delimiters. This provides a clean way to build dynamic strings without concatenation.

## Syntax
```cfscript
string = "Text with #variableName# embedded";
string = "Expression result: #expression#";
```

## Examples

### Basic Variable Interpolation
```cfscript
name = "Luis";
age = 35;

// Simple variable interpolation
message = "Hello #name#, you are #age# years old.";
writeOutput(message); // Hello Luis, you are 35 years old.
```

### Expression Interpolation
```cfscript
firstName = "Luis";
lastName = "Majano";

// Function calls and expressions
welcome = "Welcome #firstName# #lastName# on #dateFormat(now(), 'mm/dd/yyyy')#";

// Mathematical expressions
price = 25.99;
tax = 0.08;
total = "Total cost: $#numberFormat(price * (1 + tax), '9.99')#";
```

### Complex Object Interpolation
```cfscript
user = {
    name: "Luis",
    email: "luis@ortus.com",
    active: true
};

// Structure access
info = "User: #user.name# (#user.email#) - Active: #user.active#";

// Array access
scores = [95, 87, 92];
report = "Best score: #scores[1]#, Average: #arrayAvg(scores)#";
```

### Conditional Interpolation
```cfscript
status = "active";
message = "User is #status == 'active' ? 'currently active' : 'inactive'#";

// Using safe navigation
user = { profile: { name: "Luis" } };
greeting = "Hello #user?.profile?.name ?: 'Guest'#";
```

### Nested Interpolation
```cfscript
template = "Hello #{variables.user.firstName}#";
dynamicVar = "user.firstName";
value = "Welcome #evaluate('variables.#dynamicVar#')#";
```

## Key Points
- Hash symbols (`#`) delimit interpolated expressions
- Any valid CFML expression can be interpolated
- Interpolation works in both single and double quotes
- Complex objects require proper syntax (dots, brackets)
- Functions can be called within interpolation
- Avoid redundant hashing: use `a = b` not `a = #b#`
- Performance: Simple concatenation may be faster for basic cases

## Common Patterns
```cfscript
// Date formatting
message = "Today is #dateFormat(now(), 'full')#";

// Conditional display
status = "Status: #isActive ? 'Online' : 'Offline'#";

// Number formatting
price = "Price: $#dollarFormat(cost)#";

// String manipulation
title = "Title: #ucase(productName)#";
```

## Best Practices
- Don't over-hash: `name = #firstName#` should be `name = firstName`
- Use for output and string building, not simple assignments
- Consider performance for complex expressions in loops
- Use safe navigation (`?.`) for potentially null objects

## Related Concepts
- [String Literals](string-literals.md)
- [String Functions](string-functions.md)
- [Variables](../variables.md)
- [Conditionals](../../control-flow/conditionals.md)