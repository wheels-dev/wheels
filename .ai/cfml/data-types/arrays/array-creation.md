# Array Creation

## Overview
CFML arrays are dynamic, 1-indexed collections that can grow and shrink at runtime. They can be created using literal syntax or constructor functions, and support both typed and untyped variants.

## Syntax
```cfscript
// Literal syntax
array = [element1, element2, element3];

// Constructor function
array = arrayNew(dimensions);
```

## Examples

### Basic Array Creation
```cfscript
// Empty array
meals = [];

// Array with initial values
meals = ["Breakfast", "Lunch", "Dinner"];

// Mixed types (dynamic arrays)
mixed = [1, "hello", true, now()];
```

### Multi-Dimensional Arrays
```cfscript
// 2D array (grid/matrix)
grid = arrayNew(2);
grid[1][1] = "Hammer";
grid[1][2] = "Nail";
grid[2][1] = "Screwdriver";
grid[2][2] = "Screw";

// 3D array
cube = arrayNew(3);
cube[1][1][1] = "value";
```

### Typed Arrays (Adobe Engines)
```cfscript
// Typed array creation (Adobe syntax)
stringArray = arrayNew["String"](1);
numericArray = arrayNew["Numeric"](1);
userArray = arrayNew["User"](1);

// Literal typed syntax (Adobe)
strings = ["String"]["word1", "word2", "word3"];
```

### Typed Arrays (Lucee Engines)
```cfscript
// Lucee syntax for typed arrays
stringArray = arrayNew(1, "String");
numericArray = arrayNew(1, "Numeric");
userArray = arrayNew(1, "User");

// Synchronized arrays (thread-safe)
syncArray = arrayNew(1, "String", true);
```

### Array Population
```cfscript
// Add elements after creation
meals = [];
meals.append("Breakfast");
meals.append("Lunch");
meals.append("Dinner");

// Using array functions
arrayAppend(meals, "Dessert");

// Direct assignment
meals[5] = "Snack";
```

## Key Points
- Arrays start at index **1**, not 0
- CFML supports up to 3-dimensional arrays
- Arrays are dynamic and can grow/shrink at runtime
- **Adobe**: Arrays passed by value by default
- **Lucee**: Arrays passed by reference by default
- Typed arrays enforce data types with automatic casting
- Synchronized arrays are thread-safe but ~93% slower

## Array Types (for Typed Arrays)
- Array
- Binary
- Boolean
- Component
- CFC by Name/SubType
- Date/Datetime
- Function
- Numeric
- Query
- String
- Struct

## Performance Considerations
- Unsynchronized arrays are ~93% faster
- Pre-sizing arrays can improve performance
- Typed arrays provide type safety with casting overhead
- Consider using ArrayList for Java interop scenarios

## Related Concepts
- [Array Methods](array-methods.md)
- [Array Iteration](array-iteration.md)
- [Variables](../variables.md)
- [Threading](../../advanced/threading.md)