# Conditionals

## Overview
Conditionals in CFML allow you to execute different code paths based on boolean conditions. CFML supports standard if/else statements, ternary operators, elvis operators, safe navigation, and switch statements for complex control flow.

## Syntax
```cfscript
if (condition) {
    // code
} else if (condition) {
    // code
} else {
    // code
}
```

## Examples

### Basic If/Else Statements
```cfscript
age = 25;

if (age < 18) {
    status = "Minor";
} else if (age >= 18 && age < 65) {
    status = "Adult";
} else {
    status = "Senior";
}
```

### Comparison Operators
```cfscript
a = 10;
b = 5;

// Standard operators
if (a == b)    // equal
if (a != b)    // not equal
if (a > b)     // greater than
if (a >= b)    // greater than or equal
if (a < b)     // less than
if (a <= b)    // less than or equal

// CFML alternative operators
if (a EQ b)    // equal
if (a NEQ b)   // not equal
if (a GT b)    // greater than
if (a GTE b)   // greater than or equal
if (a LT b)    // less than
if (a LTE b)   // less than or equal
```

### Boolean Evaluations
```cfscript
// Arrays, structures, strings
items = [1, 2, 3];
if (isArray(items)) {
    // Process array
}

person = { name: "Luis", age: 35 };
if (person.keyExists("email")) {
    // Process email
}

// Numeric boolean evaluation
if (1)  // true
if (0)  // false
if (-5) // true
```

### Ternary Operator
```cfscript
// Basic ternary
age = 20;
category = (age >= 18) ? "Adult" : "Minor";

// Chained ternary
status = (score >= 90) ? "A" :
         (score >= 80) ? "B" :
         (score >= 70) ? "C" : "F";

// With function calls
message = (isUserActive) ? getWelcomeMessage() : getInactiveMessage();
```

### Elvis Operator (Null Coalescing)
```cfscript
// Assign default if null or undefined
userName = form.username ?: "Anonymous";
displayName = user.displayName ?: user.firstName ?: "Guest";

// With safe navigation
email = user?.profile?.email ?: "no-email@domain.com";
```

### Safe Navigation Operator
```cfscript
user = {
    profile: {
        name: "Luis",
        contacts: {
            email: "luis@ortus.com"
        }
    }
};

// Safe navigation prevents key-not-exists errors
name = user?.profile?.name;              // "Luis"
phone = user?.profile?.contacts?.phone;  // undefined (no error)
city = user?.address?.city ?: "Unknown"; // "Unknown"

// Complex navigation
result = data?.results?.items?[1]?.title ?: "No title";
```

### Switch Statements
```cfscript
city = "Miami";

switch (city) {
    case "New York":
        region = "East Coast";
        break;

    case "Los Angeles":
        region = "West Coast";
        break;

    case "Miami": case "Tampa": {
        region = "Florida";
        break;
    }

    default:
        region = "Unknown";
}
```

### Complex Conditional Logic
```cfscript
function processUser(required user) {
    // Multiple conditions with logical operators
    if (user.isActive && user.hasPermission("admin") || user.isSuperUser) {
        return processAdminUser(user);
    }

    // Nested conditions
    if (user.subscription) {
        if (user.subscription.isPremium) {
            return processPremiumUser(user);
        } else if (user.subscription.isValid()) {
            return processStandardUser(user);
        }
    }

    return processGuestUser(user);
}
```

### Validation Patterns
```cfscript
function validateUser(required struct userData) {
    // Guard clauses for early returns
    if (!structKeyExists(userData, "email")) {
        throw("Email is required");
    }

    if (!isValidEmail(userData.email)) {
        throw("Invalid email format");
    }

    // Combined validation
    if (len(trim(userData.password ?: "")) < 8) {
        throw("Password must be at least 8 characters");
    }

    return true;
}
```

## Key Points
- **Truthy values**: All numbers except 0, non-empty strings, arrays, structures
- **Falsy values**: 0, empty string, null, undefined
- Elvis operator (`?:`) provides null-safe default assignment
- Safe navigation (`?.`) prevents "key not exists" exceptions
- Switch statements only evaluate single expressions, not multiple conditions
- Use guard clauses for early returns to reduce nesting
- Logical operators: `&&` (AND), `||` (OR), `!` (NOT)

## Best Practices
- Use guard clauses to reduce nesting levels
- Prefer explicit comparisons over truthy/falsy evaluation for clarity
- Use safe navigation with elvis operator for robust null handling
- Keep conditional logic simple and readable
- Consider extracting complex conditions into named functions
- Use switch statements for multiple discrete value comparisons

## Common Patterns
```cfscript
// Guard clause pattern
if (!isValid(input)) {
    return;
}

// Null-safe access pattern
value = data?.nested?.property ?: defaultValue;

// Validation pattern
if (!isDefined("form.username") || !len(trim(form.username))) {
    errors.append("Username is required");
}
```

## Related Concepts
- [Loops](loops.md)
- [Exception Handling](exception-handling.md)
- [Variables](../data-types/variables.md)
- [Operators](../syntax/operators.md)