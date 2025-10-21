# Numeric Basics

## Overview
CFML supports two primary numeric types: integers (whole numbers) and floats (decimal numbers). Internally backed by Java's Integer and Double classes, with different storage behaviors between CFML engines.

## Syntax
```cfscript
integerValue = 123;
floatValue = 123.45;
```

## Examples

### Basic Number Assignment
```cfscript
age = 35;                    // integer
price = 25.99;               // float
temperature = -10;           // negative integer
percentage = 0.75;           // decimal between 0 and 1
```

### Mathematical Operations
```cfscript
a = 10;
b = 3;

sum = a + b;        // 13
difference = a - b; // 7
product = a * b;    // 30
quotient = a / b;   // 3.33333...
remainder = a % b;  // 1 (modulo)
power = a ^ b;      // 1000 (exponent)
```

### Type-Safe Function Parameters
```cfscript
numeric function add(numeric a, numeric b) {
    return a + b;
}

result = add(10, 20); // 30
```

### Numeric Validation and Conversion
```cfscript
// Check if value is numeric
isNumeric(123);        // true
isNumeric("123");      // true
isNumeric("abc");      // false
isNumeric("123.45");   // true

// Convert to numeric
toNumeric("123");      // 123
toNumeric("FF", "hex"); // 255
toNumeric("1010", "bin"); // 10

// Parse numbers from strings
parseNumber("$1,234.56"); // 1234.56
```

### Precision Handling
```cfscript
// Standard precision issues
result = 0.1 + 0.2; // 0.30000000000000004

// Use precisionEvaluate for exact decimal math
preciseResult = precisionEvaluate(0.1 + 0.2); // 0.3

// Currency calculations
price = 29.99;
tax = precisionEvaluate(price * 0.08);
total = precisionEvaluate(price + tax);
```

### Common Math Functions
```cfscript
number = -15.67;

abs(number);        // 15.67 (absolute value)
ceiling(number);    // -15 (round up)
floor(number);      // -16 (round down)
round(number);      // -16 (round to nearest)
int(number);        // -15 (truncate decimals)

// Advanced math
sqr(25);           // 5 (square root)
sin(90);           // sine function
cos(0);            // cosine function
pi();              // 3.141592653589793
```

### Random Numbers
```cfscript
// Random float between 0 and 1
randomFloat = rand();

// Random integer in range
randomInt = randRange(1, 100);

// Seed the random generator
randomize(12345);
```

## Key Points
- **Lucee**: All numbers stored as Double
- **Adobe**: Integers as Integer, floats as Double
- Automatic type conversion between integers and floats
- Use `precisionEvaluate()` for exact decimal arithmetic
- CFML is dynamically typed - no explicit type declaration needed
- Functions accept generic `numeric` type parameter

## Numeric Limits
- **Integer**: -2,147,483,648 to 2,147,483,647 (32-bit)
- **Double**: 64-bit floating point with ~15-16 decimal digit precision

## Performance Considerations
- Integer operations are generally faster than float operations
- Use appropriate numeric types for your use case
- Consider memory usage for large numeric datasets
- `precisionEvaluate()` has performance overhead

## Related Concepts
- [Mathematical Operators](../../syntax/operators.md)
- [Variables](../variables.md)
- [Type Conversion](../../best-practices/type-handling.md)
- [Precision Math](../../advanced/precision-calculations.md)