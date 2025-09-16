# Loops in CFML

## Overview
CFML provides several loop constructs for iterating over data and executing repetitive tasks. Modern CFScript syntax is preferred for its readability and consistency with other programming languages.

## For Loops

### Basic For Loop
```cfscript
// Traditional for loop
for (var i = 1; i <= 10; i++) {
    writeOutput("Number: " & i & "<br>");
}

// Countdown loop
for (var i = 10; i >= 1; i--) {
    writeOutput("Countdown: " & i & "<br>");
}

// Custom step
for (var i = 0; i <= 100; i += 10) {
    writeOutput("Step: " & i & "<br>");
}
```

### For-In Loops

#### Array Iteration (CF9.0.1+)
```cfscript
var fruits = ["apple", "banana", "cherry", "date"];

// Iterate over values
for (var fruit in fruits) {
    writeOutput("Fruit: " & fruit & "<br>");
}

// Access array index within loop (CF10+)
for (var fruit in fruits) {
    writeOutput("Index " & arrayFind(fruits, fruit) & ": " & fruit & "<br>");
}
```

#### Struct Iteration
```cfscript
var person = {
    name: "John",
    age: 30,
    city: "New York"
};

// Iterate over keys
for (var key in person) {
    writeOutput(key & ": " & person[key] & "<br>");
}
```

#### List Iteration (CF10+)
```cfscript
var csvData = "apple,banana,cherry,date";

// Iterate over list items
for (var item in csvData) {
    writeOutput("Item: " & item & "<br>");
}

// Custom delimiter
var pipeData = "red|green|blue";
for (var color in listToArray(pipeData, "|")) {
    writeOutput("Color: " & color & "<br>");
}
```

#### Query Iteration (CF10+)
```cfscript
var users = queryNew("name,email,active", "varchar,varchar,bit", [
    ["John Doe", "john@example.com", true],
    ["Jane Smith", "jane@example.com", false],
    ["Bob Johnson", "bob@example.com", true]
]);

// Iterate over query rows
for (var row in users) {
    writeOutput("User: " & row.name & " (" & row.email & ")<br>");
    // users.currentRow is available for current row number
}
```

## While Loops

### Basic While Loop
```cfscript
var counter = 1;

while (counter <= 5) {
    writeOutput("Counter: " & counter & "<br>");
    counter++;
}
```

### Conditional While Loop
```cfscript
var userInput = "";
var attempts = 0;
var maxAttempts = 3;

while (isEmpty(userInput) && attempts < maxAttempts) {
    userInput = trim(form.userInput ?: "");
    attempts++;

    if (isEmpty(userInput)) {
        writeOutput("Please provide valid input. Attempt " & attempts & "<br>");
    }
}
```

## Advanced Loop Patterns

### Loop Control Statements

#### Break Statement
```cfscript
var numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];

for (var num in numbers) {
    if (num > 5) {
        break; // Exit loop when number exceeds 5
    }
    writeOutput(num & " ");
}
// Output: 1 2 3 4 5
```

#### Continue Statement
```cfscript
var numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];

for (var num in numbers) {
    if (num % 2 == 0) {
        continue; // Skip even numbers
    }
    writeOutput(num & " ");
}
// Output: 1 3 5 7 9
```

### Query Loops with Grouping (CF10+)

#### Basic Query Grouping
```cfscript
var salesData = queryNew("region,salesperson,amount", "varchar,varchar,numeric", [
    ["North", "John", 1000],
    ["North", "Jane", 1500],
    ["South", "Bob", 2000],
    ["South", "Alice", 1200],
    ["South", "Charlie", 1800]
]);

// Group by region using cfloop
cfloop(query=salesData, group="region") {
    writeOutput("<h3>Region: " & region & "</h3>");

    // Inner loop for items within group
    cfloop() {
        writeOutput("&nbsp;&nbsp;" & salesperson & ": $" & numberFormat(amount) & "<br>");
    }
}
```

### File Processing Loops

#### Read File Line by Line
```cfscript
var filePath = expandPath("./data.txt");

if (fileExists(filePath)) {
    cfloop(file=filePath, index="line") {
        // Process each line
        if (len(trim(line))) {
            writeOutput("Line: " & line & "<br>");
        }
    }
}
```

#### Read File by Characters
```cfscript
var filePath = expandPath("./config.txt");

cfloop(file=filePath, index="chars", characters=16, charset="UTF-8") {
    // Process file in 16-character chunks
    processChunk(chars);
}
```

## Date/Time Loops

### Date Range Iteration
```cfscript
var startDate = createDate(2024, 1, 1);
var endDate = createDate(2024, 1, 7);

for (var currentDate = startDate;
     dateCompare(currentDate, endDate, "d") <= 0;
     currentDate = dateAdd("d", 1, currentDate)) {

    writeOutput("Date: " & dateFormat(currentDate, "yyyy-mm-dd") & "<br>");
}
```

### Time-based Processing
```cfscript
var startTime = createTime(9, 0, 0);  // 9:00 AM
var endTime = createTime(17, 0, 0);   // 5:00 PM
var intervalMinutes = 30;

for (var currentTime = startTime;
     timeFormat(currentTime, "HH:mm") <= timeFormat(endTime, "HH:mm");
     currentTime = dateAdd("n", intervalMinutes, currentTime)) {

    writeOutput("Time Slot: " & timeFormat(currentTime, "h:mm tt") & "<br>");
}
```

## Tag-Based Loop Syntax (Legacy)

### Basic Tag Loops
```cfml
<!--- For loop --->
<cfloop from="1" to="10" index="i">
    <cfoutput>Number: #i#<br></cfoutput>
</cfloop>

<!--- Array loop --->
<cfset fruits = ["apple", "banana", "cherry"]>
<cfloop array="#fruits#" item="fruit">
    <cfoutput>Fruit: #fruit#<br></cfoutput>
</cfloop>

<!--- Struct loop --->
<cfset person = {name: "John", age: 30}>
<cfloop collection="#person#" item="key">
    <cfoutput>#key#: #person[key]#<br></cfoutput>
</cfloop>

<!--- List loop --->
<cfset colors = "red,green,blue">
<cfloop list="#colors#" item="color">
    <cfoutput>Color: #color#<br></cfoutput>
</cfloop>
```

## Modern Functional Approaches

### Array Each (Alternative to Loops)
```cfscript
var numbers = [1, 2, 3, 4, 5];

// Using arrayEach instead of for loop
arrayEach(numbers, function(num, index) {
    writeOutput("Index " & index & ": " & num & "<br>");
});

// Member function syntax
numbers.each(function(num, index) {
    writeOutput("Number: " & num & " at position " & index & "<br>");
});
```

### Struct Each
```cfscript
var settings = {
    theme: "dark",
    language: "en",
    notifications: true
};

// Iterate using structEach
structEach(settings, function(key, value) {
    writeOutput(key & " = " & value & "<br>");
});

// Member function
settings.each(function(key, value) {
    writeOutput("Setting: " & key & " -> " & value & "<br>");
});
```

## Performance Considerations

### Loop Optimization
```cfscript
var items = getDataFromDatabase(); // Assume large dataset

// Inefficient: Calculate length on each iteration
for (var i = 1; i <= arrayLen(items); i++) {
    processItem(items[i]);
}

// Better: Cache length calculation
var itemCount = arrayLen(items);
for (var i = 1; i <= itemCount; i++) {
    processItem(items[i]);
}

// Best: Use for-in loop for cleaner code
for (var item in items) {
    processItem(item);
}
```

## Error Handling in Loops

### Safe Loop Iteration
```cfscript
var data = [1, "invalid", 3, null, 5];

for (var item in data) {
    try {
        if (isNull(item)) {
            continue;
        }

        if (isNumeric(item)) {
            var result = item * 2;
            writeOutput("Result: " & result & "<br>");
        }
    } catch (any e) {
        writeLog("Error processing item: " & e.message);
        continue; // Continue with next item
    }
}
```

## Key Points

- Use CFScript syntax for modern loop constructs
- For-in loops are available for arrays, structs, lists, and queries
- `break` and `continue` statements control loop execution
- CF10+ supports query grouping with `cfloop`
- Consider functional approaches (`each`, `map`, `filter`) for data processing
- Always handle potential errors in loops processing external data
- Cache array lengths and expensive calculations outside loops

## Related Concepts

- [Conditionals](conditionals.md)
- [Array Methods](../data-types/arrays/array-methods.md)
- [Query Processing](../database/query-basics.md)
- [Exception Handling](exception-handling.md)