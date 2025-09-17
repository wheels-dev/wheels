# Array Methods

## Overview
CFML provides extensive array manipulation capabilities through both traditional functions and member functions. Member functions offer better readability and method chaining for modern development.

## Syntax
```cfscript
// Traditional function syntax
result = arrayFunction(array, parameters);

// Member function syntax (preferred)
result = array.methodName(parameters);
```

## Examples

### Basic Array Operations
```cfscript
meals = ["Breakfast", "Lunch", "Dinner"];

// Get array length
size = meals.len();              // 3
size = arrayLen(meals);          // 3

// Add elements
meals.append("Dessert");         // ["Breakfast", "Lunch", "Dinner", "Dessert"]
meals.prepend("Snack");          // ["Snack", "Breakfast", "Lunch", "Dinner", "Dessert"]

// Insert at specific position
meals.insertAt(2, "Brunch");     // Insert at index 2
```

### Array Modification
```cfscript
numbers = [3, 1, 4, 1, 5];

// Sort array
numbers.sort("numeric");         // [1, 1, 3, 4, 5]
numbers.sort("numeric", "desc"); // [5, 4, 3, 1, 1]

// Remove elements
numbers.delete(1);               // Remove value 1 (first occurrence)
numbers.deleteAt(3);             // Remove element at index 3
numbers.clear();                 // Remove all elements
```

### Array Searching and Validation
```cfscript
fruits = ["apple", "banana", "cherry"];

// Find elements
index = fruits.find("banana");           // 2
index = fruits.findNoCase("APPLE");      // 1

// Check existence
exists = fruits.contains("cherry");       // true
exists = fruits.containsNoCase("APPLE"); // true

// Check if empty
isEmpty = fruits.isEmpty();              // false
```

### Functional Array Operations
```cfscript
numbers = [1, 2, 3, 4, 5];

// Map - transform each element
doubled = numbers.map(function(item) {
    return item * 2;
}); // [2, 4, 6, 8, 10]

// Filter - select elements matching criteria
evens = numbers.filter(function(item) {
    return item % 2 == 0;
}); // [2, 4]

// Reduce - aggregate to single value
sum = numbers.reduce(function(total, item) {
    return total + item;
}, 0); // 15

// Each - iterate with side effects
numbers.each(function(item, index) {
    writeOutput("Item #index#: #item#");
});
```

### Array Slicing and Manipulation
```cfscript
data = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];

// Get slice (traditional)
subset = data.slice(3, 6);       // [3, 4, 5, 6]

// Array slicing with literal syntax (Adobe)
subset = data[3:6];              // [3, 4, 5, 6]
subset = data[1:-1:2];           // [1, 3, 5, 7, 9] (every 2nd element)
subset = data[-3:-1];            // [8, 9, 10] (last 3 elements)
```

### Array Conversion
```cfscript
numbers = [1, 2, 3, 4, 5];

// Convert to list
numberList = numbers.toList();           // "1,2,3,4,5"
numberList = numbers.toList("|");        // "1|2|3|4|5"

// Get string representation
arrayString = numbers.toString();        // "[1, 2, 3, 4, 5]"
```

### Advanced Array Operations
```cfscript
// Reverse array
numbers.reverse();

// Get unique values
duplicates = [1, 2, 2, 3, 3, 3];
unique = duplicates.filter(function(item, index, array) {
    return array.find(item) == index;
});

// Flatten nested arrays (custom function needed)
nested = [[1, 2], [3, 4], [5]];
// Would need custom implementation

// Array concatenation
arr1 = [1, 2, 3];
arr2 = [4, 5, 6];
combined = arr1.merge(arr2);     // [1, 2, 3, 4, 5, 6]
```

## Key Points
- Member functions support method chaining: `array.sort().reverse()`
- Array operations typically return new arrays (immutable style)
- Functional methods (`map`, `filter`, `reduce`) follow functional programming patterns
- Index operations are 1-based, not 0-based
- Negative indexing supported in modern engines
- Type-specific operations available for typed arrays

## Common Methods Reference
- **Size**: `len()`, `size()`, `isEmpty()`
- **Add/Remove**: `append()`, `prepend()`, `insertAt()`, `delete()`, `deleteAt()`, `clear()`
- **Search**: `find()`, `findNoCase()`, `contains()`, `containsNoCase()`
- **Transform**: `map()`, `filter()`, `reduce()`, `sort()`, `reverse()`
- **Convert**: `toList()`, `toString()`, `slice()`

## Related Concepts
- [Array Creation](array-creation.md)
- [Array Iteration](array-iteration.md)
- [Closures](../../advanced/closures.md)
- [Functional Programming](../../best-practices/functional-patterns.md)