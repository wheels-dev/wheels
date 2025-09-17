# String Functions

## Overview
CFML provides extensive built-in functions for string manipulation, including length calculation, trimming, replacement, and extraction. These functions can be used as traditional functions or member functions.

## Syntax
```cfscript
// Traditional function syntax
result = functionName(string, parameters);

// Member function syntax (modern)
result = string.functionName(parameters);
```

## Examples

### Length and Trimming
```cfscript
message = " Hello World ";

// Get string length
length = len(message);        // 13
length = message.len();       // 13

// Trim whitespace
cleaned = trim(message);      // "Hello World"
cleaned = message.trim();     // "Hello World"

// Left and right trimming
leftTrim = ltrim(message);    // "Hello World "
rightTrim = rtrim(message);   // " Hello World"
```

### String Replacement
```cfscript
text = "Hello World";

// Replace first occurrence
result = replace(text, "l", "L");           // "HeLlo World"

// Replace all occurrences
result = replace(text, "l", "L", "ALL");    // "HeLLo WorLd"

// Case-insensitive replacement
result = replaceNoCase(text, "HELLO", "Hi", "ALL");

// Regular expression replacement
cleaned = reReplace("test 123!", "[^a-z0-9]", "", "ALL");
```

### Substring Operations
```cfscript
data = "Welcome to CFML";

// Extract substring
part = mid(data, 4, 5);       // "come "
part = data[4:8];             // "come" (range syntax)

// Remove characters
result = removeChars(data, 2, 5);  // "e to CFML"
```

### List Operations
```cfscript
// Convert string to array
names = "Luis,Maria,Carlos,Ana";
nameArray = names.listToArray();
nameArray = listToArray(names, ",");

// Multi-character delimiter
data = "item1,|item2,|item3";
items = listToArray(data, ",|", false, true);
```

### Case Conversion
```cfscript
text = "Hello World";

uppercase = ucase(text);      // "HELLO WORLD"
lowercase = lcase(text);      // "hello world"

uppercase = text.ucase();     // Member function
lowercase = text.lcase();     // Member function
```

### String Validation
```cfscript
// Check if string is numeric
isNumeric("123");         // true
isNumeric("abc");         // false

// Check if empty
len(trim(myString)) == 0; // empty check pattern
```

## Key Points
- Member functions provide better readability and chaining capability
- String operations return new strings (immutable nature)
- Functions are case-insensitive but preserve case in results
- Regular expressions supported with `RE` prefixed functions
- List functions treat strings as delimited lists
- Performance: Use StringBuilder for heavy concatenation operations

## Common Functions Reference
- `len()` - String length
- `trim()`, `ltrim()`, `rtrim()` - Whitespace removal
- `replace()`, `replaceNoCase()` - Text replacement
- `mid()` - Substring extraction
- `ucase()`, `lcase()` - Case conversion
- `listToArray()` - List to array conversion
- `find()`, `findNoCase()` - String searching
- `reverse()` - String reversal

## Related Concepts
- [String Literals](string-literals.md)
- [String Interpolation](string-interpolation.md)
- [Arrays](../arrays/array-methods.md)
- [Regular Expressions](../../advanced/regex-patterns.md)