# Array Iteration

## Overview
CFML provides multiple ways to iterate over arrays: traditional for loops, modern for-in loops, functional each() methods, and multi-threaded parallel processing. Each approach has different use cases and performance characteristics.

## Syntax
```cfscript
// For-in loop (modern)
for (var item in array) { }

// Traditional for loop
for (var i = 1; i <= array.len(); i++) { }

// Functional each()
array.each(function(item, index) { });
```

## Examples

### Modern For-In Loop (Recommended)
```cfscript
meals = ["Breakfast", "Lunch", "Dinner"];

for (var meal in meals) {
    writeOutput("I will have: #meal#");
}
```

### Traditional Index-Based Loop
```cfscript
meals = ["Breakfast", "Lunch", "Dinner"];

for (var i = 1; i <= meals.len(); i++) {
    writeOutput("Meal #i#: #meals[i]#");
}
```

### Functional Each() Method
```cfscript
meals = ["Breakfast", "Lunch", "Dinner"];

meals.each(function(element, index) {
    writeOutput("Index #index#: #element#");
});

// With arrow function syntax (modern engines)
meals.each((element, index) => {
    writeOutput("Index #index#: #element#");
});
```

### Loop with CFML Loop Construct
```cfscript
meals = ["Breakfast", "Lunch", "Dinner"];

cfloop(from=1, to=meals.len(), index="i") {
    writeOutput("Meal: #meals[i]#");
}

cfloop(array=meals, index="i", item="meal") {
    writeOutput("Index #i#: #meal#");
}
```

### Multi-Threaded Parallel Processing
```cfscript
largeArray = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];

// Parallel processing with each()
largeArray.each(function(item) {
    // Simulate heavy processing
    sleep(100);
    writeOutput("Processed: #item#");
}, true, 4); // parallel=true, maxThreads=4

// Traditional parallel syntax
arrayEach(largeArray, function(item) {
    processHeavyTask(item);
}, true, 4);
```

### Iteration with Break/Continue Logic
```cfscript
numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];

// Using traditional for loop for early exit
for (var i = 1; i <= numbers.len(); i++) {
    if (numbers[i] == 5) {
        break; // Exit loop
    }
    if (numbers[i] % 2 == 0) {
        continue; // Skip even numbers
    }
    writeOutput(numbers[i]);
}
```

### Nested Array Iteration
```cfscript
matrix = [
    [1, 2, 3],
    [4, 5, 6],
    [7, 8, 9]
];

// Nested for-in loops
for (var row in matrix) {
    for (var cell in row) {
        writeOutput("Cell value: #cell#");
    }
}

// Index-based nested iteration
for (var i = 1; i <= matrix.len(); i++) {
    for (var j = 1; j <= matrix[i].len(); j++) {
        writeOutput("matrix[#i#][#j#] = #matrix[i][j]#");
    }
}
```

### Functional Iteration Patterns
```cfscript
products = [
    {name: "Laptop", price: 999},
    {name: "Mouse", price: 25},
    {name: "Keyboard", price: 75}
];

// Process each item functionally
products.each(function(product, index) {
    var tax = product.price * 0.08;
    writeOutput("#product.name#: $#product.price# (Tax: $#tax#)");
});

// Chain with other functional methods
expensiveProducts = products
    .filter((product) => product.price > 50)
    .each((product) => writeOutput("Expensive: #product.name#"));
```

## Key Points
- **For-in loops** are most readable and efficient for simple iteration
- **Traditional for loops** allow index access and break/continue control
- **each() method** enables functional programming patterns and chaining
- **Parallel processing** can improve performance but adds complexity
- **Thread safety** is crucial when using parallel iteration
- **Performance**: For-in loops are generally fastest for simple cases

## Performance Considerations
- For-in loops: Fastest for simple iteration
- Traditional for loops: Good when index is needed
- each() method: Slight overhead but enables chaining
- Parallel processing: Only beneficial for CPU-intensive operations
- Avoid parallel processing overhead for simple operations

## Multi-Threading Warnings
- Ensure proper variable scoping (`var` keyword)
- Use appropriate locking for shared resources
- Thread exceptions may not be visible
- Consider ColdBox Futures for advanced parallel processing

## Related Concepts
- [Array Creation](array-creation.md)
- [Array Methods](array-methods.md)
- [Closures](../../advanced/closures.md)
- [Threading](../../advanced/threading.md)
- [Control Flow](../../control-flow/loops.md)