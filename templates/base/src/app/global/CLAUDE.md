# CLAUDE.md - Global Functions

This file provides guidance to Claude Code (claude.ai/code) when working with Wheels global functions.

## Overview

The `/app/global/` folder contains application-wide functions that are automatically available throughout your entire Wheels application. This is the Wheels equivalent of adding functions to `Application.cfc` in traditional CFML applications.

**Why Use Global Functions:**
- Make utility functions available in controllers, views, and models
- Create application-specific helper functions
- Extend Wheels functionality with custom functions
- Keep helper code organized and reusable
- Avoid code duplication across your application

## File Structure

The global folder contains:
- **functions.cfm**: The main file for global function definitions
- Functions defined here are automatically available everywhere in your application
- No need to include or import - Wheels handles this automatically

### Organizing Functions with Includes

For larger applications, you can organize functions into separate files and include them in `functions.cfm`:

```
/app/global/
├── functions.cfm              # Main functions file (includes others)
├── string-utilities.cfm       # String manipulation functions
├── date-utilities.cfm         # Date/time functions
├── validation-utilities.cfm   # Validation functions
├── security-utilities.cfm     # Security-related functions
├── array-utilities.cfm        # Array/collection functions
├── application-helpers.cfm    # App-specific helper functions
└── debug-utilities.cfm        # Development/debugging functions
```

**Main functions.cfm structure:**
```cfm
<cfscript>
// Main global functions file - includes categorized function files
// This keeps the codebase organized and maintainable

// Include string manipulation utilities
include "string-utilities.cfm";

// Include date and time utilities  
include "date-utilities.cfm";

// Include validation functions
include "validation-utilities.cfm";

// Include security-related functions
include "security-utilities.cfm";

// Include array and collection utilities
include "array-utilities.cfm";

// Include application-specific helpers
include "application-helpers.cfm";

// Include debug utilities (only in development)
if (get("environment") == "development") {
    include "debug-utilities.cfm";
}

// You can also include functions directly in this file
// for small utilities or functions that don't fit other categories

/**
 * Quick utility function that doesn't warrant its own file
 */
function quickHelper() {
    return "This is a simple helper function";
}
</cfscript>
```

### Example Categorized Files

#### string-utilities.cfm
```cfm
<cfscript>
/**
 * String manipulation and formatting functions
 */

/**
 * Create a URL-friendly slug from text
 */
function slugify(required string text) {
    local.result = lcase(trim(arguments.text));
    local.result = reReplace(local.result, "[^a-z0-9\s]", " ", "all");
    local.result = reReplace(local.result, "\s+", " ", "all");
    local.result = replace(local.result, " ", "-", "all");
    local.result = reReplace(local.result, "^-+|-+$", "", "all");
    return local.result;
}

/**
 * Truncate text to specified length with ellipsis
 */
function truncate(required string text, numeric length = 100, string suffix = "...") {
    if (len(arguments.text) <= arguments.length) {
        return arguments.text;
    }
    
    local.truncated = left(arguments.text, arguments.length - len(arguments.suffix));
    local.lastSpace = find(" ", reverse(local.truncated));
    if (local.lastSpace > 0 && local.lastSpace < 20) {
        local.truncated = left(local.truncated, len(local.truncated) - local.lastSpace + 1);
    }
    
    return local.truncated & arguments.suffix;
}

/**
 * Convert text to title case
 */
function titleCase(required string text) {
    local.words = listToArray(arguments.text, " ");
    local.result = [];
    
    for (local.word in local.words) {
        if (len(local.word) > 0) {
            arrayAppend(local.result, ucase(left(local.word, 1)) & lcase(right(local.word, len(local.word) - 1)));
        }
    }
    
    return arrayToList(local.result, " ");
}
</cfscript>
```

#### validation-utilities.cfm
```cfm
<cfscript>
/**
 * Validation and data checking functions
 */

/**
 * Validate email format
 */
function isValidEmail(required string email) {
    local.emailPattern = "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$";
    return reFindNoCase(local.emailPattern, arguments.email) > 0;
}

/**
 * Validate phone number format
 */
function isValidPhone(required string phone, string country = "US") {
    local.cleanPhone = reReplace(arguments.phone, "[^0-9]", "", "all");
    
    switch (arguments.country) {
        case "US":
            return len(local.cleanPhone) == 10 || (len(local.cleanPhone) == 11 && left(local.cleanPhone, 1) == "1");
        case "UK":
            return len(local.cleanPhone) >= 10 && len(local.cleanPhone) <= 11;
        default:
            return len(local.cleanPhone) >= 7 && len(local.cleanPhone) <= 15;
    }
}

/**
 * Validate password strength
 */
function validatePassword(required string password, numeric minLength = 8, boolean requireSpecial = true) {
    local.result = {valid: true, score: 0, requirements: []};
    
    if (len(arguments.password) < arguments.minLength) {
        local.result.valid = false;
        arrayAppend(local.result.requirements, "At least #arguments.minLength# characters");
    } else {
        local.result.score += 1;
    }
    
    // Additional validation logic...
    return local.result;
}
</cfscript>
```

#### date-utilities.cfm
```cfm
<cfscript>
/**
 * Date and time manipulation functions
 */

/**
 * Format date in a user-friendly way
 */
function formatDate(required date date, string format = "medium") {
    switch (arguments.format) {
        case "short":
            return dateFormat(arguments.date, "m/d/yyyy");
        case "medium":
            return dateFormat(arguments.date, "mmm d, yyyy");
        case "long":
            return dateFormat(arguments.date, "mmmm d, yyyy");
        case "relative":
            return timeAgoInWords(arguments.date);
        default:
            return dateFormat(arguments.date, arguments.format);
    }
}

/**
 * Check if date is weekend
 */
function isWeekend(date date = now()) {
    local.dayOfWeek = dayOfWeek(arguments.date);
    return local.dayOfWeek == 1 || local.dayOfWeek == 7;
}

/**
 * Get business days between two dates
 */
function businessDaysBetween(required date startDate, required date endDate) {
    local.totalDays = dateDiff("d", arguments.startDate, arguments.endDate);
    local.businessDays = 0;
    
    for (local.i = 0; local.i <= local.totalDays; local.i++) {
        local.currentDate = dateAdd("d", local.i, arguments.startDate);
        if (!isWeekend(local.currentDate)) {
            local.businessDays++;
        }
    }
    
    return local.businessDays;
}
</cfscript>
```

#### application-helpers.cfm
```cfm
<cfscript>
/**
 * Application-specific helper functions
 */

/**
 * Get current logged-in user
 */
function getCurrentUser() {
    if (structKeyExists(session, "userId") && isNumeric(session.userId)) {
        return model("User").findByKey(session.userId);
    }
    return "";
}

/**
 * Check if user is logged in
 */
function isLoggedIn() {
    return structKeyExists(session, "userId") && isNumeric(session.userId);
}

/**
 * Check if user has specific permission
 */
function hasPermission(required string permission, numeric userId = 0) {
    if (!arguments.userId && structKeyExists(session, "userId")) {
        arguments.userId = session.userId;
    }
    
    if (!arguments.userId) {
        return false;
    }
    
    if (structKeyExists(session, "permissions")) {
        return listFindNoCase(session.permissions, arguments.permission) > 0;
    }
    
    return false;
}

/**
 * Format currency for display
 */
function formatCurrency(required numeric value, string currency = "USD") {
    switch (arguments.currency) {
        case "USD":
            return dollarFormat(arguments.value);
        case "EUR":
            return "€#numberFormat(arguments.value, '9,999.99')#";
        case "GBP":
            return "£#numberFormat(arguments.value, '9,999.99')#";
        default:
            return "#arguments.currency# #numberFormat(arguments.value, '9,999.99')#";
    }
}

/**
 * Log application events
 */
function logEvent(required string message, string level = "info", string category = "application") {
    local.logMessage = "[#ucase(arguments.level)#] #arguments.message#";
    
    if (get("environment") == "development") {
        local.logMessage &= " | URL: #cgi.script_name##cgi.path_info#";
        if (structKeyExists(session, "userId")) {
            local.logMessage &= " | User: #session.userId#";
        }
    }
    
    writeLog(
        file = arguments.category,
        text = local.logMessage,
        type = arguments.level == "error" ? "error" : "information"
    );
}
</cfscript>
```

#### debug-utilities.cfm
```cfm
<cfscript>
/**
 * Development and debugging helper functions
 * These are only loaded in development environment
 */

/**
 * Pretty print variable for debugging (development only)
 */
function dd(required any var, string label = "Debug") {
    writeOutput("
        <div style='background: ##f8f9fa; border: 1px solid ##dee2e6; margin: 10px; padding: 15px; font-family: monospace;'>
            <strong>#arguments.label#:</strong><br>
            <cfdump var='#arguments.var#' format='html' />
        </div>
    ");
}

/**
 * Start performance timer
 */
function startTimer(string label = "Execution") {
    local.startTime = getTickCount();
    logEvent("Timer started: #arguments.label#", "debug", "performance");
    
    return {
        label: arguments.label,
        startTime: local.startTime
    };
}

/**
 * End performance timer
 */
function endTimer(required struct timer) {
    local.endTime = getTickCount();
    local.duration = local.endTime - arguments.timer.startTime;
    logEvent("Timer ended: #arguments.timer.label# - Duration: #local.duration#ms", "debug", "performance");
    return local.duration;
}

/**
 * Get memory usage information
 */
function getMemoryUsage() {
    try {
        local.runtime = createObject("java", "java.lang.Runtime").getRuntime();
        local.totalMemory = local.runtime.totalMemory();
        local.freeMemory = local.runtime.freeMemory();
        local.usedMemory = local.totalMemory - local.freeMemory;
        
        return {
            total: formatFileSize(local.totalMemory),
            free: formatFileSize(local.freeMemory),
            used: formatFileSize(local.usedMemory),
            totalBytes: local.totalMemory,
            freeBytes: local.freeMemory,
            usedBytes: local.usedMemory
        };
    } catch (any e) {
        return {error: "Memory info not available"};
    }
}
</cfscript>
```

### Benefits of Organized Structure

**Maintainability:**
- Functions are grouped by purpose making them easier to find and maintain
- Each file has a single responsibility
- Easier to test specific categories of functions

**Performance:**
- Conditional loading (e.g., debug utilities only in development)
- Smaller individual files are easier to work with
- Better IDE/editor performance with focused files

**Team Collaboration:**
- Different team members can work on different utility categories
- Clearer code ownership and responsibility
- Easier code reviews with focused changes

**Environment Control:**
- Load different functions based on environment
- Skip heavy utilities in production
- Include development-specific helpers only when needed

## Basic Global Functions Template

The `/app/global/functions.cfm` file uses CFScript for function definitions:

```cfm
<cfscript>
// Place functions here that should be available globally in your application.

/**
 * Format currency with proper symbols and formatting
 * @value The numeric value to format
 * @currency The currency code (USD, EUR, etc.)
 * @return Formatted currency string
 */
function formatCurrency(required numeric value, string currency = "USD") {
    switch (arguments.currency) {
        case "USD":
            return dollarFormat(arguments.value);
        case "EUR":
            return "€#numberFormat(arguments.value, '9,999.99')#";
        case "GBP":
            return "£#numberFormat(arguments.value, '9,999.99')#";
        default:
            return "#arguments.currency# #numberFormat(arguments.value, '9,999.99')#";
    }
}

/**
 * Check if current environment is production
 * @return Boolean indicating if in production
 */
function isProduction() {
    return get("environment") == "production";
}

/**
 * Check if current environment is development
 * @return Boolean indicating if in development
 */
function isDevelopment() {
    return get("environment") == "development";
}

/**
 * Get application version from settings or default
 * @return Application version string
 */
function appVersion() {
    return get("applicationVersion", "1.0.0");
}
</cfscript>
```

## Categories of Global Functions

### String Utilities

```cfm
<cfscript>
/**
 * Create a URL-friendly slug from text
 * @text The text to convert to a slug
 * @return URL-friendly slug
 */
function slugify(required string text) {
    local.result = lcase(trim(arguments.text));
    // Replace special characters with spaces
    local.result = reReplace(local.result, "[^a-z0-9\s]", " ", "all");
    // Replace multiple spaces with single spaces
    local.result = reReplace(local.result, "\s+", " ", "all");
    // Replace spaces with hyphens
    local.result = replace(local.result, " ", "-", "all");
    // Remove leading/trailing hyphens
    local.result = reReplace(local.result, "^-+|-+$", "", "all");
    return local.result;
}

/**
 * Truncate text to specified length with ellipsis
 * @text The text to truncate
 * @length Maximum length (default 100)
 * @suffix Suffix to append when truncated (default "...")
 * @return Truncated text
 */
function truncate(required string text, numeric length = 100, string suffix = "...") {
    if (len(arguments.text) <= arguments.length) {
        return arguments.text;
    }
    
    local.truncated = left(arguments.text, arguments.length - len(arguments.suffix));
    
    // Try to break at word boundary
    local.lastSpace = find(" ", reverse(local.truncated));
    if (local.lastSpace > 0 && local.lastSpace < 20) {
        local.truncated = left(local.truncated, len(local.truncated) - local.lastSpace + 1);
    }
    
    return local.truncated & arguments.suffix;
}

/**
 * Convert text to title case
 * @text The text to convert
 * @return Title case text
 */
function titleCase(required string text) {
    local.words = listToArray(arguments.text, " ");
    local.result = [];
    
    for (local.word in local.words) {
        if (len(local.word) > 0) {
            arrayAppend(local.result, ucase(left(local.word, 1)) & lcase(right(local.word, len(local.word) - 1)));
        }
    }
    
    return arrayToList(local.result, " ");
}

/**
 * Generate random string of specified length
 * @length Length of random string (default 16)
 * @chars Character set to use (default alphanumeric)
 * @return Random string
 */
function randomString(numeric length = 16, string chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789") {
    local.result = "";
    local.charsLength = len(arguments.chars);
    
    for (local.i = 1; local.i <= arguments.length; local.i++) {
        local.randomIndex = randRange(1, local.charsLength);
        local.result &= mid(arguments.chars, local.randomIndex, 1);
    }
    
    return local.result;
}

/**
 * Check if string is valid email format
 * @email Email address to validate
 * @return Boolean indicating validity
 */
function isValidEmail(required string email) {
    local.emailPattern = "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$";
    return reFindNoCase(local.emailPattern, arguments.email) > 0;
}
</cfscript>
```

### Date and Time Utilities

```cfm
<cfscript>
/**
 * Format date in a user-friendly way
 * @date Date to format
 * @format Format style: short, medium, long, relative
 * @return Formatted date string
 */
function formatDate(required date date, string format = "medium") {
    switch (arguments.format) {
        case "short":
            return dateFormat(arguments.date, "m/d/yyyy");
        case "medium":
            return dateFormat(arguments.date, "mmm d, yyyy");
        case "long":
            return dateFormat(arguments.date, "mmmm d, yyyy");
        case "relative":
            return timeAgoInWords(arguments.date);
        default:
            return dateFormat(arguments.date, arguments.format);
    }
}

/**
 * Format time in user-friendly way
 * @time Time to format
 * @format Format style: 12hour, 24hour, short
 * @return Formatted time string
 */
function formatTime(required date time, string format = "12hour") {
    switch (arguments.format) {
        case "12hour":
            return timeFormat(arguments.time, "h:mm tt");
        case "24hour":
            return timeFormat(arguments.time, "HH:mm");
        case "short":
            return timeFormat(arguments.time, "h:mm");
        default:
            return timeFormat(arguments.time, arguments.format);
    }
}

/**
 * Get start of day for given date
 * @date Date to get start of day for (default now)
 * @return Date with time set to 00:00:00
 */
function startOfDay(date date = now()) {
    return createDateTime(
        year(arguments.date),
        month(arguments.date),
        day(arguments.date),
        0, 0, 0
    );
}

/**
 * Get end of day for given date
 * @date Date to get end of day for (default now)
 * @return Date with time set to 23:59:59
 */
function endOfDay(date date = now()) {
    return createDateTime(
        year(arguments.date),
        month(arguments.date),
        day(arguments.date),
        23, 59, 59
    );
}

/**
 * Check if date is weekend
 * @date Date to check (default now)
 * @return Boolean indicating if weekend
 */
function isWeekend(date date = now()) {
    local.dayOfWeek = dayOfWeek(arguments.date);
    return local.dayOfWeek == 1 || local.dayOfWeek == 7; // Sunday = 1, Saturday = 7
}

/**
 * Get business days between two dates
 * @startDate Start date
 * @endDate End date
 * @return Number of business days
 */
function businessDaysBetween(required date startDate, required date endDate) {
    local.totalDays = dateDiff("d", arguments.startDate, arguments.endDate);
    local.businessDays = 0;
    
    for (local.i = 0; local.i <= local.totalDays; local.i++) {
        local.currentDate = dateAdd("d", local.i, arguments.startDate);
        if (!isWeekend(local.currentDate)) {
            local.businessDays++;
        }
    }
    
    return local.businessDays;
}
</cfscript>
```

### Validation Utilities

```cfm
<cfscript>
/**
 * Validate phone number format
 * @phone Phone number to validate
 * @country Country format (US, UK, etc.)
 * @return Boolean indicating validity
 */
function isValidPhone(required string phone, string country = "US") {
    // Remove non-numeric characters
    local.cleanPhone = reReplace(arguments.phone, "[^0-9]", "", "all");
    
    switch (arguments.country) {
        case "US":
            return len(local.cleanPhone) == 10 || (len(local.cleanPhone) == 11 && left(local.cleanPhone, 1) == "1");
        case "UK":
            return len(local.cleanPhone) >= 10 && len(local.cleanPhone) <= 11;
        default:
            return len(local.cleanPhone) >= 7 && len(local.cleanPhone) <= 15;
    }
}

/**
 * Validate credit card number using Luhn algorithm
 * @cardNumber Credit card number to validate
 * @return Boolean indicating validity
 */
function isValidCreditCard(required string cardNumber) {
    // Remove spaces and hyphens
    local.cleanNumber = reReplace(arguments.cardNumber, "[\s-]", "", "all");
    
    // Check if all digits
    if (!reFind("^[0-9]+$", local.cleanNumber)) {
        return false;
    }
    
    // Check length (13-19 digits)
    if (len(local.cleanNumber) < 13 || len(local.cleanNumber) > 19) {
        return false;
    }
    
    // Luhn algorithm
    local.sum = 0;
    local.isEven = false;
    
    for (local.i = len(local.cleanNumber); local.i >= 1; local.i--) {
        local.digit = val(mid(local.cleanNumber, local.i, 1));
        
        if (local.isEven) {
            local.digit *= 2;
            if (local.digit > 9) {
                local.digit -= 9;
            }
        }
        
        local.sum += local.digit;
        local.isEven = !local.isEven;
    }
    
    return local.sum % 10 == 0;
}

/**
 * Validate URL format
 * @url URL to validate
 * @allowLocal Allow localhost URLs (default false)
 * @return Boolean indicating validity
 */
function isValidUrl(required string url, boolean allowLocal = false) {
    // Basic URL pattern
    local.urlPattern = "^https?://[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}(/.*)?$";
    
    if (arguments.allowLocal) {
        local.urlPattern = "^https?://[a-zA-Z0-9.-]+(:[0-9]+)?(/.*)?$";
    }
    
    return reFindNoCase(local.urlPattern, arguments.url) > 0;
}

/**
 * Validate password strength
 * @password Password to validate
 * @minLength Minimum length (default 8)
 * @requireSpecial Require special characters (default true)
 * @return Struct with valid flag and strength score
 */
function validatePassword(required string password, numeric minLength = 8, boolean requireSpecial = true) {
    local.result = {
        valid: true,
        score: 0,
        requirements: []
    };
    
    // Length check
    if (len(arguments.password) < arguments.minLength) {
        local.result.valid = false;
        arrayAppend(local.result.requirements, "At least #arguments.minLength# characters");
    } else {
        local.result.score += 1;
    }
    
    // Lowercase letter
    if (!reFindNoCase("[a-z]", arguments.password)) {
        local.result.valid = false;
        arrayAppend(local.result.requirements, "At least one lowercase letter");
    } else {
        local.result.score += 1;
    }
    
    // Uppercase letter
    if (!reFindNoCase("[A-Z]", arguments.password)) {
        local.result.valid = false;
        arrayAppend(local.result.requirements, "At least one uppercase letter");
    } else {
        local.result.score += 1;
    }
    
    // Number
    if (!reFindNoCase("[0-9]", arguments.password)) {
        local.result.valid = false;
        arrayAppend(local.result.requirements, "At least one number");
    } else {
        local.result.score += 1;
    }
    
    // Special character
    if (arguments.requireSpecial && !reFindNoCase("[^a-zA-Z0-9]", arguments.password)) {
        local.result.valid = false;
        arrayAppend(local.result.requirements, "At least one special character");
    } else if (reFindNoCase("[^a-zA-Z0-9]", arguments.password)) {
        local.result.score += 1;
    }
    
    return local.result;
}
</cfscript>
```

### Array and Collection Utilities

```cfm
<cfscript>
/**
 * Flatten a multi-dimensional array
 * @array Array to flatten
 * @return Flattened array
 */
function flattenArray(required array array) {
    local.result = [];
    
    for (local.item in arguments.array) {
        if (isArray(local.item)) {
            local.flattened = flattenArray(local.item);
            for (local.subItem in local.flattened) {
                arrayAppend(local.result, local.subItem);
            }
        } else {
            arrayAppend(local.result, local.item);
        }
    }
    
    return local.result;
}

/**
 * Get unique values from array
 * @array Array to get unique values from
 * @return Array with unique values only
 */
function uniqueArray(required array array) {
    local.result = [];
    local.seen = {};
    
    for (local.item in arguments.array) {
        local.key = isSimpleValue(local.item) ? local.item : hash(serializeJSON(local.item));
        
        if (!structKeyExists(local.seen, local.key)) {
            arrayAppend(local.result, local.item);
            local.seen[local.key] = true;
        }
    }
    
    return local.result;
}

/**
 * Chunk array into smaller arrays of specified size
 * @array Array to chunk
 * @size Size of each chunk
 * @return Array of arrays
 */
function chunkArray(required array array, required numeric size) {
    local.result = [];
    local.chunk = [];
    
    for (local.i = 1; local.i <= arrayLen(arguments.array); local.i++) {
        arrayAppend(local.chunk, arguments.array[local.i]);
        
        if (arrayLen(local.chunk) == arguments.size || local.i == arrayLen(arguments.array)) {
            arrayAppend(local.result, duplicate(local.chunk));
            local.chunk = [];
        }
    }
    
    return local.result;
}

/**
 * Pluck specific key from array of structs
 * @array Array of structs
 * @key Key to pluck from each struct
 * @return Array of values for specified key
 */
function pluckFromArray(required array array, required string key) {
    local.result = [];
    
    for (local.item in arguments.array) {
        if (isStruct(local.item) && structKeyExists(local.item, arguments.key)) {
            arrayAppend(local.result, local.item[arguments.key]);
        }
    }
    
    return local.result;
}

/**
 * Group array of structs by specified key
 * @array Array of structs to group
 * @key Key to group by
 * @return Struct with grouped arrays
 */
function groupArrayBy(required array array, required string key) {
    local.result = {};
    
    for (local.item in arguments.array) {
        if (isStruct(local.item) && structKeyExists(local.item, arguments.key)) {
            local.groupKey = local.item[arguments.key];
            
            if (!structKeyExists(local.result, local.groupKey)) {
                local.result[local.groupKey] = [];
            }
            
            arrayAppend(local.result[local.groupKey], local.item);
        }
    }
    
    return local.result;
}
</cfscript>
```

### Security and Sanitization Utilities

```cfm
<cfscript>
/**
 * Sanitize HTML content
 * @html HTML content to sanitize
 * @allowedTags Comma-separated list of allowed tags
 * @return Sanitized HTML
 */
function sanitizeHtml(required string html, string allowedTags = "p,br,strong,em,ul,ol,li,a") {
    local.result = arguments.html;
    
    // Convert allowed tags list to array
    local.allowed = listToArray(lcase(arguments.allowedTags));
    
    // Remove all script tags and their content
    local.result = reReplaceNoCase(local.result, "<script[^>]*>.*?</script>", "", "all");
    
    // Remove all style tags and their content
    local.result = reReplaceNoCase(local.result, "<style[^>]*>.*?</style>", "", "all");
    
    // Remove dangerous attributes
    local.dangerousAttrs = "javascript:|vbscript:|onload|onerror|onclick|onmouseover|onfocus|onblur";
    local.result = reReplaceNoCase(local.result, "#local.dangerousAttrs#[^>]*", "", "all");
    
    // For simplicity, this is a basic implementation
    // In production, consider using a more robust HTML sanitizer
    return local.result;
}

/**
 * Generate secure random token
 * @length Length of token (default 32)
 * @return Secure random token
 */
function generateSecureToken(numeric length = 32) {
    local.bytes = [];
    
    for (local.i = 1; local.i <= arguments.length; local.i++) {
        arrayAppend(local.bytes, randRange(0, 255));
    }
    
    return lcase(hash(arrayToList(local.bytes), "SHA-256")).left(arguments.length);
}

/**
 * Hash password with salt
 * @password Plain text password
 * @salt Optional salt (generated if not provided)
 * @return Struct with hash and salt
 */
function hashPassword(required string password, string salt = "") {
    if (!len(arguments.salt)) {
        arguments.salt = generateSecureToken(16);
    }
    
    local.hash = hash(arguments.password & arguments.salt, "SHA-256");
    
    return {
        hash: local.hash,
        salt: arguments.salt
    };
}

/**
 * Verify password against hash
 * @password Plain text password to verify
 * @hash Stored hash
 * @salt Stored salt
 * @return Boolean indicating if password matches
 */
function verifyPassword(required string password, required string hash, required string salt) {
    local.testHash = hash(arguments.password & arguments.salt, "SHA-256");
    return local.testHash == arguments.hash;
}

/**
 * Get client IP address (handles proxies)
 * @return Client IP address
 */
function getClientIP() {
    // Check for shared internet/proxy
    if (structKeyExists(cgi, "http_client_ip") && len(cgi.http_client_ip)) {
        return cgi.http_client_ip;
    }
    
    // Check for IP passed from proxy
    if (structKeyExists(cgi, "http_x_forwarded_for") && len(cgi.http_x_forwarded_for)) {
        // Can contain multiple IPs, get the first one
        return listFirst(cgi.http_x_forwarded_for);
    }
    
    // Check for IP from remote address
    if (structKeyExists(cgi, "http_x_forwarded") && len(cgi.http_x_forwarded)) {
        return cgi.http_x_forwarded;
    }
    
    // Check for IP from cluster
    if (structKeyExists(cgi, "http_forwarded_for") && len(cgi.http_forwarded_for)) {
        return cgi.http_forwarded_for;
    }
    
    // Standard remote address
    return cgi.remote_addr ?: "0.0.0.0";
}
</cfscript>
```

### Application-Specific Utilities

```cfm
<cfscript>
/**
 * Log application events
 * @message Log message
 * @level Log level (info, warn, error, debug)
 * @category Log category/file name
 */
function logEvent(required string message, string level = "info", string category = "application") {
    local.logMessage = "[#ucase(arguments.level)#] #arguments.message#";
    
    if (isDevelopment()) {
        local.logMessage &= " | URL: #cgi.script_name##cgi.path_info#";
        if (structKeyExists(session, "userId")) {
            local.logMessage &= " | User: #session.userId#";
        }
    }
    
    writeLog(
        file = arguments.category,
        text = local.logMessage,
        type = arguments.level == "error" ? "error" : "information"
    );
}

/**
 * Send notification email
 * @to Recipient email
 * @subject Email subject
 * @message Email message
 * @from Sender email (optional)
 * @return Boolean indicating success
 */
function sendNotification(required string to, required string subject, required string message, string from = "") {
    if (!len(arguments.from)) {
        arguments.from = get("notificationEmail", "noreply@#cgi.server_name#");
    }
    
    try {
        mail(
            to = arguments.to,
            from = arguments.from,
            subject = arguments.subject,
            body = arguments.message,
            type = "html"
        );
        
        logEvent("Email sent to #arguments.to#: #arguments.subject#");
        return true;
        
    } catch (any e) {
        logEvent("Email failed to #arguments.to#: #e.message#", "error");
        return false;
    }
}

/**
 * Get configuration value with default
 * @key Configuration key
 * @defaultValue Default value if key doesn't exist
 * @return Configuration value or default
 */
function config(required string key, any defaultValue = "") {
    try {
        return get(arguments.key);
    } catch (any e) {
        return arguments.defaultValue;
    }
}

/**
 * Check if user has permission
 * @permission Permission to check
 * @userId User ID (default current session user)
 * @return Boolean indicating if user has permission
 */
function hasPermission(required string permission, numeric userId = 0) {
    if (!arguments.userId && structKeyExists(session, "userId")) {
        arguments.userId = session.userId;
    }
    
    if (!arguments.userId) {
        return false;
    }
    
    // This would typically check against a database
    // For example purposes, using simple session check
    if (structKeyExists(session, "permissions")) {
        return listFindNoCase(session.permissions, arguments.permission) > 0;
    }
    
    return false;
}

/**
 * Format file size in human readable format
 * @bytes File size in bytes
 * @precision Decimal places (default 2)
 * @return Formatted file size string
 */
function formatFileSize(required numeric bytes, numeric precision = 2) {
    local.units = ["B", "KB", "MB", "GB", "TB"];
    local.size = arguments.bytes;
    local.unitIndex = 1;
    
    while (local.size >= 1024 && local.unitIndex < arrayLen(local.units)) {
        local.size /= 1024;
        local.unitIndex++;
    }
    
    if (local.unitIndex == 1) {
        return "#local.size# #local.units[local.unitIndex]#";
    } else {
        return "#numberFormat(local.size, "9999.#repeatString('0', arguments.precision)#")# #local.units[local.unitIndex]#";
    }
}
</cfscript>
```

### Debug and Development Utilities

```cfm
<cfscript>
/**
 * Pretty print variable for debugging
 * @var Variable to debug
 * @label Optional label for the debug output
 */
function dd(required any var, string label = "Debug") {
    if (isDevelopment()) {
        writeOutput("
            <div style='background: ##f8f9fa; border: 1px solid ##dee2e6; margin: 10px; padding: 15px; font-family: monospace;'>
                <strong>#arguments.label#:</strong><br>
                <cfdump var='#arguments.var#' format='html' />
            </div>
        ");
    }
}

/**
 * Log execution time of a code block
 * @label Label for the timing
 * @return Start time for ending the timer
 */
function startTimer(string label = "Execution") {
    local.startTime = getTickCount();
    
    if (isDevelopment()) {
        logEvent("Timer started: #arguments.label#", "debug", "performance");
    }
    
    return {
        label: arguments.label,
        startTime: local.startTime
    };
}

/**
 * End timer and log execution time
 * @timer Timer object from startTimer()
 */
function endTimer(required struct timer) {
    local.endTime = getTickCount();
    local.duration = local.endTime - arguments.timer.startTime;
    
    if (isDevelopment()) {
        logEvent("Timer ended: #arguments.timer.label# - Duration: #local.duration#ms", "debug", "performance");
    }
    
    return local.duration;
}

/**
 * Memory usage helper for debugging
 * @return Memory usage information
 */
function getMemoryUsage() {
    if (isDevelopment()) {
        try {
            local.runtime = createObject("java", "java.lang.Runtime").getRuntime();
            local.totalMemory = local.runtime.totalMemory();
            local.freeMemory = local.runtime.freeMemory();
            local.usedMemory = local.totalMemory - local.freeMemory;
            
            return {
                total: formatFileSize(local.totalMemory),
                free: formatFileSize(local.freeMemory),
                used: formatFileSize(local.usedMemory),
                totalBytes: local.totalMemory,
                freeBytes: local.freeMemory,
                usedBytes: local.usedMemory
            };
        } catch (any e) {
            return {error: "Memory info not available"};
        }
    }
    
    return {message: "Memory info only available in development"};
}
</cfscript>
```

## Usage Examples

### In Controllers

```cfm
component extends="Controller" {

    function create() {
        // Use global validation function
        if (!isValidEmail(params.user.email)) {
            flashInsert(error="Please provide a valid email address");
            renderView(action="new");
            return;
        }
        
        // Use global password validation
        local.passwordCheck = validatePassword(params.user.password);
        if (!local.passwordCheck.valid) {
            flashInsert(error="Password requirements: #arrayToList(local.passwordCheck.requirements, ', ')#");
            renderView(action="new");
            return;
        }
        
        // Use global logging
        logEvent("New user registration attempt: #params.user.email#");
        
        // Continue with user creation...
    }

    function show() {
        user = model("User").findByKey(params.key);
        
        // Use global date formatting
        user.formattedJoinDate = formatDate(user.createdAt, "long");
        user.joinedAgo = formatDate(user.createdAt, "relative");
    }
}
```

### In Views

```cfm
<cfoutput>
    <div class="user-profile">
        <h1>#titleCase(user.fullName)#</h1>
        <p>Joined: #formatDate(user.createdAt, "relative")#</p>
        <p>Email: #user.email#</p>
        
        <cfif hasPermission("users.edit")>
            <p><a href="/users/#user.id#/edit">Edit User</a></p>
        </cfif>
        
        <div class="user-bio">
            #truncate(user.biography, 200)#
        </div>
        
        <div class="metadata">
            <small>Profile slug: #slugify(user.fullName)#</small>
        </div>
    </div>
</cfoutput>
```

### In Models

```cfm
component extends="Model" {

    function config() {
        super.config();
        
        // Use global validation in model validations
        validatesFormatOf(property="email", with=isValidEmail, message="Please enter a valid email address");
        
        // Custom validation using global function
        validates(property="password", method="validatePasswordStrength");
    }
    
    private function validatePasswordStrength() {
        local.validation = validatePassword(this.password);
        
        if (!local.validation.valid) {
            addError(property="password", message="Password must meet requirements: #arrayToList(local.validation.requirements, ', ')#");
        }
    }
    
    function beforeSave() {
        // Use global function to generate slug
        if (hasChanged("title")) {
            this.slug = slugify(this.title);
        }
    }
}
```

## Best Practices

### 1. Use Descriptive Function Names
```cfm
<cfscript>
// Good - clear purpose
function formatCurrency(amount, currency) { }
function isValidEmail(email) { }
function generateSecureToken(length) { }

// Avoid - unclear purpose  
function format(data) { }
function check(value) { }
function generate() { }
</cfscript>
```

### 2. Include Comprehensive Documentation
```cfm
<cfscript>
/**
 * Calculate distance between two geographic points
 * Uses the Haversine formula for great-circle distance
 * @lat1 Latitude of first point
 * @lon1 Longitude of first point  
 * @lat2 Latitude of second point
 * @lon2 Longitude of second point
 * @unit Unit of measurement: miles, kilometers (default miles)
 * @return Distance between points in specified unit
 * @example distance = calculateDistance(40.7128, -74.0060, 34.0522, -118.2437, "miles")
 */
function calculateDistance(required numeric lat1, required numeric lon1, required numeric lat2, required numeric lon2, string unit = "miles") {
    // Implementation here...
}
</cfscript>
```

### 3. Handle Errors Gracefully
```cfm
<cfscript>
function safeFunction(required any input) {
    try {
        // Potentially risky operation
        return processInput(arguments.input);
    } catch (any e) {
        // Log error in development
        if (isDevelopment()) {
            logEvent("Error in safeFunction: #e.message#", "error");
        }
        
        // Return safe default
        return "";
    }
}
</cfscript>
```

### 4. Consider Performance
```cfm
<cfscript>
// Cache expensive operations at application scope
function getCountryList() {
    if (!structKeyExists(application, "countryList")) {
        application.countryList = model("Country").findAll(
            select="id,name,code",
            order="name",
            cache=true
        );
    }
    
    return application.countryList;
}

// Avoid repeated complex operations
function optimizedFunction(data) {
    // Pre-calculate once instead of in loop
    local.processedData = preprocessData(arguments.data);
    
    local.result = [];
    for (local.item in arguments.data) {
        // Use pre-calculated data
        arrayAppend(local.result, processItem(local.item, local.processedData));
    }
    
    return local.result;
}
</cfscript>
```

### 5. Environment-Aware Functions
```cfm
<cfscript>
function debugLog(message) {
    if (isDevelopment()) {
        writeLog(file="debug", text=arguments.message);
        
        // Also output to browser in development
        writeOutput("<!-- DEBUG: #arguments.message# -->");
    }
}

function getApiUrl(endpoint) {
    local.baseUrl = isProduction() ? 
        "https://api.mycompany.com" : 
        "https://api-staging.mycompany.com";
        
    return local.baseUrl & "/" & arguments.endpoint;
}
</cfscript>
```

## Testing Global Functions

You can test global functions in your test suite:

```cfm
// /tests/specs/GlobalFunctionsTest.cfc
component extends="tests.BaseTest" {

    function testSlugify() {
        local.result = slugify("Hello World! This is a Test.");
        assert("local.result == 'hello-world-this-is-a-test'");
    }
    
    function testFormatCurrency() {
        local.usd = formatCurrency(1234.56, "USD");
        local.eur = formatCurrency(1234.56, "EUR");
        
        assert("local.usd == '$1,234.56'");
        assert("find('€', local.eur) > 0");
    }
    
    function testValidatePassword() {
        local.weak = validatePassword("123");
        local.strong = validatePassword("MyStr0ng!Pass");
        
        assert("!local.weak.valid");
        assert("local.strong.valid");
        assert("local.strong.score >= 4");
    }
    
    function testTruncate() {
        local.text = "This is a very long piece of text that should be truncated";
        local.result = truncate(local.text, 20);
        
        assert("len(local.result) <= 23"); // 20 + "..."
        assert("right(local.result, 3) == '...'");
    }
}
```

## Integration with Wheels Framework

### Accessing Wheels Functions
Your global functions have access to all Wheels framework functions:

```cfm
<cfscript>
function getCurrentUser() {
    if (structKeyExists(session, "userId")) {
        return model("User").findByKey(session.userId);
    }
    return "";
}

function redirectToLogin(message = "Please log in to continue") {
    flashInsert(error=arguments.message);
    redirectTo(controller="sessions", action="new");
}

function isLoggedIn() {
    return structKeyExists(session, "userId") && isNumeric(session.userId);
}
</cfscript>
```

### Using Configuration Settings
```cfm
<cfscript>
function getAppSetting(key, defaultValue = "") {
    try {
        return get(arguments.key);
    } catch (any e) {
        return arguments.defaultValue;
    }
}

function isFeatureEnabled(feature) {
    return getAppSetting("features.#arguments.feature#", false);
}
</cfscript>
```

## Important Notes

- **Automatic availability**: Functions in `functions.cfm` are automatically available everywhere
- **No imports needed**: Unlike traditional includes, no `cfinclude` required
- **Performance**: Functions are loaded once at application start
- **Scope**: Functions have access to all Wheels framework functions and settings
- **Testing**: Global functions can and should be unit tested
- **Documentation**: Use proper JavaDoc-style comments for function documentation
- **Error handling**: Always include appropriate error handling
- **Environment awareness**: Consider different behavior for different environments

Global functions provide a powerful way to extend your Wheels application with reusable, application-wide functionality while maintaining clean separation of concerns.