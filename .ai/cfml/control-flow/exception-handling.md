# Exception Handling

## Overview
CFML provides comprehensive exception handling through try/catch/finally blocks, custom exception throwing, and built-in exception types. Proper exception handling enables graceful error recovery and robust application behavior.

## Syntax
```cfscript
try {
    // code that might throw exception
} catch (exceptionType variableName) {
    // handle specific exception type
} catch (any e) {
    // handle any remaining exceptions
} finally {
    // cleanup code that always runs
}
```

## Examples

### Basic Try/Catch/Finally
```cfscript
try {
    result = 10 / 0; // Will throw division by zero
    writeOutput("Result: " & result);
} catch (any e) {
    writeOutput("Error occurred: " & e.message);
} finally {
    writeOutput("Cleanup code runs regardless");
}
```

### Multiple Exception Types
```cfscript
try {
    qResult = queryExecute("SELECT * FROM users WHERE id = ?", [userID]);
    userData = processUserData(qResult);
} catch (database e) {
    writeLog("Database error: " & e.message);
    // Handle database-specific issues
} catch (expression e) {
    writeLog("Expression error: " & e.detail);
    // Handle parsing/evaluation errors
} catch (any e) {
    writeLog("Unexpected error: " & e.message);
    // Handle all other exceptions
}
```

### Custom Exception Throwing
```cfscript
function validateUser(required struct userData) {
    if (!structKeyExists(userData, "email")) {
        throw(
            type = "ValidationError",
            message = "Email is required",
            detail = "User data must include email address",
            errorCode = "USER_001"
        );
    }

    if (!isValidEmail(userData.email)) {
        throw(
            type = "ValidationError",
            message = "Invalid email format",
            detail = "Email address format is not valid: " & userData.email,
            errorCode = "USER_002"
        );
    }

    return true;
}

// Usage
try {
    validateUser({ name: "John" }); // Missing email
} catch (ValidationError e) {
    writeOutput("Validation failed: " & e.message);
    writeOutput("Error code: " & e.errorCode);
}
```

### Rethrowing Exceptions
```cfscript
function processUserData(required userData) {
    try {
        // Attempt processing
        result = complexDataProcessing(userData);
        return result;
    } catch (any e) {
        // Log the error for debugging
        writeLog("Processing failed for user: " & userData.id);
        writeLog("Error: " & e.message);

        // Re-throw to let caller handle
        rethrow;
    }
}
```

### Exception Information Access
```cfscript
try {
    riskyOperation();
} catch (any e) {
    // Access exception properties
    writeOutput("Type: " & e.type);
    writeOutput("Message: " & e.message);
    writeOutput("Detail: " & e.detail);
    writeOutput("Error Code: " & e.errorCode);
    writeOutput("Extended Info: " & e.extendedInfo);

    // Stack trace information
    if (structKeyExists(e, "stackTrace")) {
        writeOutput("Stack Trace: " & e.stackTrace);
    }
}
```

### Resource Management Pattern
```cfscript
function processFile(required string filePath) {
    var fileHandle = "";

    try {
        fileHandle = fileOpen(filePath, "read");

        while (!fileIsEOF(fileHandle)) {
            line = fileReadLine(fileHandle);
            processLine(line);
        }

        return "File processed successfully";
    } catch (any e) {
        throw(
            message = "File processing failed",
            detail = "Error processing file: " & filePath,
            extendedInfo = e.message
        );
    } finally {
        // Ensure file is always closed
        if (isObject(fileHandle)) {
            fileClose(fileHandle);
        }
    }
}
```

### Nested Exception Handling
```cfscript
function complexOperation(data) {
    try {
        // Outer operation
        validateInput(data);

        try {
            // Inner operation that might fail
            result = performCalculation(data);
        } catch (MathError e) {
            // Handle math-specific errors
            result = getDefaultCalculationResult();
            writeLog("Using default calculation due to: " & e.message);
        }

        return processResult(result);
    } catch (ValidationError e) {
        throw(
            type = "ProcessingError",
            message = "Input validation failed",
            detail = e.message
        );
    } catch (any e) {
        // Log and wrap unexpected errors
        writeLog("Unexpected error in complexOperation: " & e.message);
        throw(
            type = "SystemError",
            message = "System error occurred",
            detail = "Contact administrator"
        );
    }
}
```

### Exception Factory Pattern
```cfscript
component {

    public function createValidationException(required message, code = "VALIDATION_ERROR") {
        throw(
            type = "ValidationError",
            message = arguments.message,
            errorCode = arguments.code,
            detail = "Data validation failed"
        );
    }

    public function createDatabaseException(required message, query = "") {
        throw(
            type = "DatabaseError",
            message = arguments.message,
            detail = "Database operation failed",
            extendedInfo = arguments.query
        );
    }
}

// Usage
errorFactory = new ErrorFactory();

try {
    if (age < 0) {
        errorFactory.createValidationException("Age cannot be negative", "AGE_001");
    }
} catch (ValidationError e) {
    handleValidationError(e);
}
```

## Built-in Exception Types
- `application` - Application-level exceptions
- `database` - Database operation errors
- `template` - CFML template errors
- `security` - Security-related errors
- `object` - Object instantiation/method errors
- `missingInclude` - Missing include file errors
- `expression` - Expression evaluation errors
- `lock` - Lock operation errors
- `any` - Catches all exception types

## Exception Object Properties
- `type` - Exception type/category
- `message` - Brief error description
- `detail` - Detailed error information
- `errorCode` - Custom error code
- `extendedInfo` - Additional custom information
- `stackTrace` - Call stack information

## Best Practices
- **Catch specific types first**, then general types
- **Always include finally blocks** for cleanup
- **Log exceptions appropriately** for debugging
- **Don't catch and ignore** - handle or rethrow
- **Use custom exception types** for business logic errors
- **Provide meaningful error messages** for users
- **Clean up resources** in finally blocks
- **Rethrow when appropriate** to maintain error context

## Error Recovery Patterns
```cfscript
// Retry pattern
function reliableOperation(data, maxRetries = 3) {
    for (var attempt = 1; attempt <= maxRetries; attempt++) {
        try {
            return performOperation(data);
        } catch (TemporaryError e) {
            if (attempt == maxRetries) {
                rethrow;
            }
            sleep(attempt * 1000); // Exponential backoff
        }
    }
}

// Fallback pattern
function getDataWithFallback(id) {
    try {
        return getPrimaryData(id);
    } catch (any e) {
        try {
            return getBackupData(id);
        } catch (any fallbackError) {
            return getDefaultData();
        }
    }
}
```

## Related Concepts
- [Conditionals](conditionals.md)
- [Logging](../advanced/logging.md)
- [Application Configuration](../advanced/application-cfc.md)
- [Best Practices](../best-practices/error-handling.md)