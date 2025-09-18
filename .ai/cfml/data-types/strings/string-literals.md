# String Literals

## Overview
Strings in CFML store collections of characters and are backed by Java's immutable String class. They can be defined using single or double quotes and support various manipulation techniques.

## Syntax
```cfscript
stringVariable = "text content";
// or
stringVariable = 'text content';
```

## Examples

### Basic String Creation
```cfscript
name = "Luis";
message = 'Hello World!';
empty = "";
```

### String Interpolation
```cfscript
name = "Luis";
greeting = "Hello #name#, welcome!";
writeOutput(greeting); // Hello Luis, welcome!

// Complex expressions in interpolation
welcome = "Good morning #name#, today is #dateFormat(now(), 'mm/dd/yyyy')#";
```

### Character Extraction (Modern Engines)
```cfscript
name = "Luis";
firstChar = name[1];      // "L" (1-based indexing)
lastChar = name[-1];      // "s" (negative indexing from end)

// Range extraction (Adobe 2018+)
data = "Hello CFML. You Rock!";
substring = data[4:12];   // "lo CFML"
stepped = data[4:10:2];   // "l FL" (every 2nd character)
```

### String Concatenation
```cfscript
firstName = "Luis";
lastName = "Majano";

// Using & operator
fullName = firstName & " " & lastName;

// Using &= assignment operator
greeting = "Hello ";
greeting &= firstName;
greeting &= "!";
```

## Key Points
- Strings are **immutable** (Java String objects)
- Both single and double quotes work identically
- String indexes start at **1**, not 0
- Negative indexing available in modern engines
- Interpolation works with `#expression#` syntax
- Heavy concatenation should use StringBuilder for performance
- Case-insensitive language but string content preserves case

## Related Concepts
- [String Functions](string-functions.md)
- [String Interpolation](string-interpolation.md)
- [Variables](../variables.md)
- [Operators](../../syntax/operators.md)