# CLAUDE.md - Events

This file provides guidance to Claude Code (claude.ai/code) when working with Wheels application events.

## Overview

The `/app/events/` folder contains event handler files that respond to standard CFML application lifecycle events and custom Wheels events. These files allow you to execute custom code at specific points in your application's lifecycle without modifying the core framework files.

**Why Use Events:**
- Safely add custom logic to application lifecycle events
- Keep framework files untouched for easier upgrades
- Centralize application-wide functionality
- Handle errors, maintenance mode, and missing templates gracefully
- Support multiple response formats (HTML, JSON, XML)

## Event File Structure

Event files are stored in this directory (`/app/events/`) and follow these conventions:
- **File naming**: Lowercase with `.cfm` extension (e.g., `onapplicationstart.cfm`)
- **Content**: Can contain CFML tags, CFScript, or HTML
- **Scope**: Have access to all application scopes and framework functions
- **Execution**: Called automatically by Wheels at appropriate lifecycle points

## Standard CFML Application Events

### Application Lifecycle Events

#### onApplicationStart.cfm
Executed once when the application starts (first request or after restart).

```cfm
<cfscript>
// Place code here that should be executed on the "onApplicationStart" event.

// Examples of common application startup tasks:
// - Initialize application-wide variables
// - Set up caching
// - Load configuration data
// - Initialize external services

// Set application-wide constants
application.appVersion = "1.2.3";
application.startTime = Now();

// Initialize external services
try {
    // Connect to external APIs
    application.paymentGateway = createObject("component", "services.PaymentGateway").init();
} catch (any e) {
    // Log startup errors
    writeLog(file="application", text="Failed to initialize payment gateway: #e.message#");
}

// Load lookup data
application.countries = model("Country").findAll(cache=true, order="name");
application.timezones = model("Timezone").findAll(cache=true, order="displayName");
</cfscript>
```

#### onApplicationEnd.cfm
Executed when the application ends (server shutdown or application timeout).

```cfm
<cfscript>
// Place code here that should be executed on the "onApplicationEnd" event.

// Examples of common application shutdown tasks:
// - Clean up resources
// - Save state information
// - Close connections
// - Log shutdown information

// Log application shutdown
writeLog(file="application", text="Application shutting down. Uptime: #DateDiff('n', application.startTime, Now())# minutes");

// Clean up resources
if (StructKeyExists(application, "paymentGateway")) {
    application.paymentGateway.cleanup();
}

// Save any pending data
if (StructKeyExists(application, "pendingData")) {
    model("DataQueue").bulkSave(application.pendingData);
}
</cfscript>
```

### Request Lifecycle Events

#### onRequestStart.cfm
Executed at the beginning of every request, before any controller processing.

```cfm
<cfscript>
// Place code here that should be executed on the "onRequestStart" event.

// Examples of common request startup tasks:
// - Set request-wide variables
// - Log request information
// - Check authentication
// - Initialize request tracking

// Set request start time for performance monitoring
request.startTime = getTickCount();

// Log requests in development
if (get("environment") == "development") {
    writeLog(file="requests", text="Request: #cgi.request_method# #cgi.path_info# from #cgi.remote_addr#");
}

// Set common request variables
request.userAgent = cgi.http_user_agent;
request.isAjax = (StructKeyExists(cgi, "http_x_requested_with") && cgi.http_x_requested_with == "XMLHttpRequest");
request.isMobile = reFindNoCase("(iPhone|iPad|Android|Mobile)", cgi.http_user_agent);

// Global authentication check for admin areas
if (REFindNoCase("^/admin/", cgi.path_info) && !StructKeyExists(session, "isAdmin")) {
    // Redirect to login - this will interrupt normal request processing
    location(url="/admin/login?returnTo=#URLEncodedFormat(cgi.query_string)#", addToken=false);
}

// Initialize request-specific services
request.logger = createObject("component", "services.RequestLogger").init();
</cfscript>
```

#### onRequestEnd.cfm
Executed at the end of every request, after all controller and view processing.

```cfm
<cfscript>
// Place code here that should be executed on the "onRequestEnd" event.

// Examples of common request cleanup tasks:
// - Log request completion
// - Clean up temporary variables
// - Perform analytics tracking
// - Save request metrics

// Calculate request processing time
if (StructKeyExists(request, "startTime")) {
    local.processingTime = getTickCount() - request.startTime;
    
    // Log slow requests
    if (local.processingTime > 1000) { // More than 1 second
        writeLog(
            file="performance", 
            text="Slow request: #cgi.path_info# took #local.processingTime#ms"
        );
    }
    
    // Store metrics
    if (StructKeyExists(request, "logger")) {
        request.logger.recordMetrics(processingTime=local.processingTime);
    }
}

// Clean up request-specific variables
StructDelete(request, "tempData", false);
StructDelete(request, "processingFlags", false);

// Analytics tracking (non-blocking)
if (get("environment") == "production") {
    try {
        // Track page views
        model("Analytics").recordPageView(
            url=cgi.path_info,
            userAgent=cgi.http_user_agent,
            referrer=cgi.http_referer ?: ""
        );
    } catch (any e) {
        // Don't let analytics errors affect the user experience
        writeLog(file="analytics", text="Analytics tracking failed: #e.message#");
    }
}
</cfscript>
```

### Session Events

#### onSessionStart.cfm
Executed when a new user session is created.

```cfm
<cfscript>
// Place code here that should be executed on the "onSessionStart" event.

// Examples of common session initialization tasks:
// - Set default session variables
// - Initialize user preferences
// - Log new sessions
// - Set up session tracking

// Initialize default session variables
session.preferences = {
    theme: "default",
    language: "en",
    timezone: "UTC",
    itemsPerPage: 25
};

// Track new sessions
session.startedAt = Now();
session.sessionId = CreateUUID();

// Initialize shopping cart for e-commerce
session.cart = {
    items: [],
    total: 0,
    currency: "USD"
};

// Log new session (for analytics)
writeLog(
    file="sessions", 
    text="New session started: #session.sessionId# from #cgi.remote_addr#"
);

// Check for returning user (via cookies)
if (StructKeyExists(cookie, "returning_user")) {
    session.isReturningUser = true;
    // Load user preferences from database
    if (StructKeyExists(cookie, "user_prefs")) {
        try {
            local.savedPrefs = deserializeJSON(cookie.user_prefs);
            StructAppend(session.preferences, local.savedPrefs, true);
        } catch (any e) {
            // Invalid cookie data, ignore
        }
    }
} else {
    session.isReturningUser = false;
    // Set returning user cookie (expires in 30 days)
    header name="Set-Cookie" value="returning_user=true; Path=/; Max-Age=#86400*30#";
}
</cfscript>
```

#### onSessionEnd.cfm
Executed when a user session expires or is terminated.

```cfm
<cfscript>
// Place code here that should be executed on the "onSessionEnd" event.
// Note: This event has limited access to scopes - only arguments.sessionScope and arguments.applicationScope

// Examples of common session cleanup tasks:
// - Save session data
// - Log session duration
// - Clean up temporary files
// - Update user statistics

// Calculate session duration
if (StructKeyExists(arguments.sessionScope, "startedAt")) {
    local.sessionDuration = DateDiff("n", arguments.sessionScope.startedAt, Now());
    
    // Log session end with duration
    writeLog(
        file="sessions", 
        text="Session ended: #arguments.sessionScope.sessionId# duration: #local.sessionDuration# minutes"
    );
}

// Save abandoned cart data for recovery
if (StructKeyExists(arguments.sessionScope, "cart") && ArrayLen(arguments.sessionScope.cart.items)) {
    try {
        // Save to database for cart recovery emails
        queryExecute("
            INSERT INTO abandoned_carts (session_id, cart_data, created_at)
            VALUES (?, ?, ?)
        ", [
            arguments.sessionScope.sessionId,
            serializeJSON(arguments.sessionScope.cart),
            Now()
        ]);
    } catch (any e) {
        writeLog(file="errors", text="Failed to save abandoned cart: #e.message#");
    }
}

// Update user session statistics
if (StructKeyExists(arguments.sessionScope, "userId")) {
    try {
        queryExecute("
            UPDATE users 
            SET last_session_duration = ?,
                last_activity = ?
            WHERE id = ?
        ", [
            local.sessionDuration,
            Now(),
            arguments.sessionScope.userId
        ]);
    } catch (any e) {
        writeLog(file="errors", text="Failed to update user session stats: #e.message#");
    }
}
</cfscript>
```

#### onAbort.cfm
Executed when a request is aborted (cfabort, abort(), or similar).

```cfm
<cfscript>
// Place code here that should be executed on the "onAbort" event.

// Examples of abort handling:
// - Log abort reasons
// - Clean up resources
// - Save partial data
// - Notify administrators of unexpected aborts

// Log the abort
local.abortReason = "Request aborted";
if (StructKeyExists(arguments, "exception")) {
    local.abortReason &= ": " & arguments.exception.message;
}

writeLog(
    file="aborts", 
    text="#local.abortReason# - URL: #cgi.path_info# - User: #session.userId ?: 'anonymous'#"
);

// Clean up any open resources
if (StructKeyExists(request, "openConnections")) {
    for (local.conn in request.openConnections) {
        try {
            local.conn.close();
        } catch (any e) {
            // Ignore cleanup errors
        }
    }
}

// Save partial form data if available
if (StructKeyExists(form, "autosave") && form.autosave == "true") {
    try {
        model("FormDraft").save(
            sessionId = session.sessionId,
            formData = serializeJSON(form),
            url = cgi.path_info
        );
    } catch (any e) {
        // Ignore save errors during abort
    }
}
</cfscript>
```

## Custom Wheels Events

### Error Handling Events

#### onerror.cfm
Displayed when an error occurs and `showErrorInformation` is set to false (typically in production).

```cfm
<!--- Place HTML here that should be displayed when an error is encountered while running in "production" mode. --->

<!--- 
Access error information via arguments.exception:
- arguments.exception.message
- arguments.exception.detail
- arguments.exception.type
- arguments.exception.stackTrace
--->

<cfsilent>
    <!--- Log the error for debugging --->
    <cfset local.errorInfo = {
        message: arguments.exception.message ?: "Unknown error",
        detail: arguments.exception.detail ?: "",
        type: arguments.exception.type ?: "Application",
        url: cgi.path_info,
        userAgent: cgi.http_user_agent,
        timestamp: Now()
    } />
    
    <!--- Log to file --->
    <cflog file="application_errors" text="Error: #serializeJSON(local.errorInfo)#" />
    
    <!--- Email critical errors --->
    <cfif get("sendEmailOnError") AND len(get("errorEmailAddress"))>
        <cfmail 
            to="#get('errorEmailAddress')#"
            from="noreply@#cgi.server_name#"
            subject="#get('errorEmailSubject')# - #cgi.server_name#"
            type="html">
            <h2>Application Error</h2>
            <p><strong>URL:</strong> #local.errorInfo.url#</p>
            <p><strong>Message:</strong> #local.errorInfo.message#</p>
            <p><strong>Detail:</strong> #local.errorInfo.detail#</p>
            <p><strong>Type:</strong> #local.errorInfo.type#</p>
            <p><strong>Time:</strong> #local.errorInfo.timestamp#</p>
            <p><strong>User Agent:</strong> #local.errorInfo.userAgent#</p>
        </cfmail>
    </cfif>
</cfsilent>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Error - #get('applicationName')#</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            margin: 0;
            padding: 40px 20px;
            background-color: #f5f5f5;
            color: #333;
        }
        .container {
            max-width: 600px;
            margin: 0 auto;
            background: white;
            padding: 40px;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        .error-icon {
            font-size: 48px;
            color: #e74c3c;
            margin-bottom: 20px;
        }
        h1 {
            color: #e74c3c;
            font-size: 28px;
            margin: 0 0 20px 0;
        }
        p {
            line-height: 1.6;
            margin-bottom: 20px;
        }
        .actions {
            margin-top: 30px;
        }
        .btn {
            display: inline-block;
            padding: 10px 20px;
            background-color: #3498db;
            color: white;
            text-decoration: none;
            border-radius: 4px;
            margin-right: 10px;
        }
        .btn:hover {
            background-color: #2980b9;
        }
        .error-id {
            font-size: 12px;
            color: #666;
            margin-top: 30px;
            padding: 10px;
            background: #f8f9fa;
            border-radius: 4px;
            font-family: monospace;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="error-icon">⚠️</div>
        <h1>Oops! Something went wrong</h1>
        <p>
            We apologize for the inconvenience. An unexpected error has occurred 
            while processing your request.
        </p>
        <p>
            Our technical team has been notified and is working to resolve this issue. 
            Please try again in a few minutes.
        </p>
        
        <div class="actions">
            <a href="javascript:history.back()" class="btn">Go Back</a>
            <a href="/" class="btn">Home Page</a>
        </div>
        
        <div class="error-id">
            Error ID: #CreateUUID()# | Time: #DateFormat(Now(), "yyyy-mm-dd")# #TimeFormat(Now(), "HH:mm:ss")#
        </div>
    </div>
</body>
</html>
```

#### onerror.json.cfm
JSON error response for API requests when `showErrorInformation` is false.

```cfm
<cfsilent>
    <!--- Place JSON error response here that should be displayed when an error is encountered while running in "production" mode. --->
    
    <!--- Log the error --->
    <cfset local.errorId = CreateUUID() />
    <cfset local.timestamp = DateFormat(Now(), "yyyy-mm-dd") & "T" & TimeFormat(Now(), "HH:mm:ss") & "Z" />
    
    <cflog file="api_errors" text="API Error #local.errorId#: #arguments.exception.message# - URL: #cgi.path_info#" />
    
    <!--- Determine appropriate status code based on error type --->
    <cfset local.statusCode = 500 />
    <cfif StructKeyExists(arguments.exception, "errorCode")>
        <cfswitch expression="#arguments.exception.errorCode#">
            <cfcase value="404">
                <cfset local.statusCode = 404 />
            </cfcase>
            <cfcase value="400,401,403,422">
                <cfset local.statusCode = arguments.exception.errorCode />
            </cfcase>
        </cfswitch>
    </cfif>
    
    <!--- Set appropriate HTTP status --->
    <cfheader statuscode="#local.statusCode#" statustext="Error" />
    <cfcontent type="application/json" />
    
    <cfset local.errorResponse = {
        "error": true,
        "message": "Internal Server Error",
        "statusCode": local.statusCode,
        "timestamp": local.timestamp,
        "errorId": local.errorId
    } />
    
    <!--- Add more specific error information for common cases --->
    <cfif local.statusCode == 404>
        <cfset local.errorResponse.message = "Not Found" />
        <cfset local.errorResponse.description = "The requested resource could not be found" />
    <cfelseif local.statusCode == 401>
        <cfset local.errorResponse.message = "Unauthorized" />
        <cfset local.errorResponse.description = "Authentication required" />
    <cfelseif local.statusCode == 403>
        <cfset local.errorResponse.message = "Forbidden" />
        <cfset local.errorResponse.description = "Access denied" />
    <cfelseif local.statusCode == 422>
        <cfset local.errorResponse.message = "Unprocessable Entity" />
        <cfset local.errorResponse.description = "Validation failed" />
    </cfif>
</cfsilent><cfoutput>#SerializeJSON(local.errorResponse)#</cfoutput>
```

#### onerror.xml.cfm  
XML error response for XML API requests when `showErrorInformation` is false.

```cfm
<cfsilent>
    <!--- Place XML error response here that should be displayed when an error is encountered while running in "production" mode. --->
    
    <cfset local.errorId = CreateUUID() />
    <cfset local.timestamp = DateFormat(Now(), "yyyy-mm-dd") & "T" & TimeFormat(Now(), "HH:mm:ss") & "Z" />
    
    <!--- Log the error --->
    <cflog file="api_errors" text="XML API Error #local.errorId#: #arguments.exception.message# - URL: #cgi.path_info#" />
    
    <!--- Set content type and status --->
    <cfcontent type="text/xml" />
    <cfheader statuscode="500" statustext="Internal Server Error" />
</cfsilent><cfoutput><?xml version="1.0" encoding="UTF-8"?>
<error>
    <message>Internal Server Error</message>
    <statusCode>500</statusCode>
    <timestamp>#local.timestamp#</timestamp>
    <errorId>#local.errorId#</errorId>
    <description>An unexpected error occurred while processing your request</description>
</error></cfoutput>
```

### Missing Template Event

#### onmissingtemplate.cfm
Displayed when a controller or action cannot be found (404 errors).

```cfm
<!--- Place HTML here that should be displayed when a file is not found while running in "production" mode. --->

<cfsilent>
    <!--- Log the 404 for analysis --->
    <cfset local.missingInfo = {
        url: cgi.path_info,
        queryString: cgi.query_string,
        referrer: cgi.http_referer ?: "",
        userAgent: cgi.http_user_agent,
        timestamp: Now()
    } />
    
    <cflog file="missing_templates" text="404: #serializeJSON(local.missingInfo)#" />
    
    <!--- Set proper 404 status --->
    <cfheader statuscode="404" statustext="Not Found" />
    
    <!--- Suggest similar pages --->
    <cfset local.suggestions = [] />
    <cftry>
        <!--- Basic suggestion logic - could be enhanced with search functionality --->
        <cfset local.path = listFirst(cgi.path_info, "/") />
        <cfif len(local.path)>
            <cfset arrayAppend(local.suggestions, "/") />
            <cfset arrayAppend(local.suggestions, "/#local.path#") />
        </cfif>
        <cfcatch>
            <!--- Ignore errors in suggestion generation --->
        </cfcatch>
    </cftry>
</cfsilent>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Page Not Found - #get('applicationName')#</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            margin: 0;
            padding: 40px 20px;
            background-color: #f5f5f5;
            color: #333;
        }
        .container {
            max-width: 600px;
            margin: 0 auto;
            background: white;
            padding: 40px;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        .error-code {
            font-size: 72px;
            font-weight: bold;
            color: #3498db;
            margin-bottom: 20px;
            text-align: center;
        }
        h1 {
            color: #2c3e50;
            font-size: 28px;
            margin: 0 0 20px 0;
            text-align: center;
        }
        p {
            line-height: 1.6;
            margin-bottom: 20px;
            text-align: center;
        }
        .suggestions {
            margin: 30px 0;
            padding: 20px;
            background: #f8f9fa;
            border-radius: 4px;
        }
        .suggestions h3 {
            margin: 0 0 15px 0;
            color: #2c3e50;
        }
        .suggestions ul {
            margin: 0;
            padding-left: 20px;
        }
        .suggestions li {
            margin-bottom: 10px;
        }
        .suggestions a {
            color: #3498db;
            text-decoration: none;
        }
        .suggestions a:hover {
            text-decoration: underline;
        }
        .actions {
            text-align: center;
            margin-top: 30px;
        }
        .btn {
            display: inline-block;
            padding: 12px 24px;
            background-color: #3498db;
            color: white;
            text-decoration: none;
            border-radius: 4px;
            margin: 0 10px;
            font-weight: 500;
        }
        .btn:hover {
            background-color: #2980b9;
        }
        .btn.secondary {
            background-color: #95a5a6;
        }
        .btn.secondary:hover {
            background-color: #7f8c8d;
        }
        .search-box {
            margin: 20px 0;
            text-align: center;
        }
        .search-box input {
            padding: 10px 15px;
            font-size: 16px;
            border: 2px solid #bdc3c7;
            border-radius: 25px;
            width: 250px;
            outline: none;
        }
        .search-box input:focus {
            border-color: #3498db;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="error-code">404</div>
        <h1>Page Not Found</h1>
        <p>
            Sorry, the page you're looking for doesn't exist. It may have been moved, 
            deleted, or you may have typed the address incorrectly.
        </p>
        
        <cfif arrayLen(local.suggestions)>
            <div class="suggestions">
                <h3>Try these pages instead:</h3>
                <ul>
                    <cfloop array="#local.suggestions#" index="suggestion">
                        <li><a href="#suggestion#">#suggestion#</a></li>
                    </cfloop>
                </ul>
            </div>
        </cfif>
        
        <div class="search-box">
            <form action="/search" method="get">
                <input type="text" name="q" placeholder="Search our site..." />
            </form>
        </div>
        
        <div class="actions">
            <a href="javascript:history.back()" class="btn secondary">Go Back</a>
            <a href="/" class="btn">Home Page</a>
        </div>
    </div>
</body>
</html>
```

### Maintenance Mode Event

#### onmaintenance.cfm
Displayed when the application is in maintenance mode.

```cfm
<!--- Place HTML here that should be displayed when the application is running in "maintenance" mode. --->

<cfsilent>
    <!--- Set appropriate HTTP status --->
    <cfheader statuscode="503" statustext="Service Unavailable" />
    <cfheader name="Retry-After" value="3600" />
    
    <!--- Check for maintenance bypass (for administrators) --->
    <cfset local.showBypass = false />
    <cfif StructKeyExists(url, "bypass") AND get("environment") NEQ "production">
        <cfset local.showBypass = true />
    </cfif>
</cfsilent>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Maintenance - #get('applicationName')#</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            margin: 0;
            padding: 0;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .container {
            text-align: center;
            padding: 40px;
            background: rgba(255, 255, 255, 0.1);
            border-radius: 15px;
            backdrop-filter: blur(10px);
            border: 1px solid rgba(255, 255, 255, 0.2);
            max-width: 600px;
            margin: 20px;
        }
        .maintenance-icon {
            font-size: 64px;
            margin-bottom: 30px;
            opacity: 0.9;
        }
        h1 {
            font-size: 36px;
            margin: 0 0 20px 0;
            font-weight: 300;
        }
        p {
            font-size: 18px;
            line-height: 1.6;
            margin-bottom: 30px;
            opacity: 0.9;
        }
        .status {
            background: rgba(255, 255, 255, 0.15);
            padding: 20px;
            border-radius: 10px;
            margin: 30px 0;
        }
        .status h3 {
            margin: 0 0 15px 0;
            font-size: 20px;
        }
        .progress-bar {
            background: rgba(255, 255, 255, 0.2);
            border-radius: 10px;
            height: 6px;
            overflow: hidden;
            margin: 15px 0;
        }
        .progress-fill {
            background: #4CAF50;
            height: 100%;
            width: 65%;
            border-radius: 10px;
            animation: pulse 2s infinite;
        }
        @keyframes pulse {
            0% { opacity: 1; }
            50% { opacity: 0.7; }
            100% { opacity: 1; }
        }
        .eta {
            font-size: 14px;
            opacity: 0.8;
        }
        .social-links {
            margin-top: 30px;
        }
        .social-links a {
            color: white;
            font-size: 24px;
            margin: 0 10px;
            text-decoration: none;
            opacity: 0.7;
            transition: opacity 0.3s;
        }
        .social-links a:hover {
            opacity: 1;
        }
        .bypass {
            margin-top: 20px;
            padding: 10px;
            background: rgba(255, 255, 255, 0.1);
            border-radius: 5px;
            font-size: 14px;
        }
        .bypass a {
            color: #ffeb3b;
            text-decoration: none;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="maintenance-icon">🔧</div>
        <h1>Under Maintenance</h1>
        <p>
            We're currently performing some important updates to make your experience even better. 
            We'll be back shortly!
        </p>
        
        <div class="status">
            <h3>Maintenance Progress</h3>
            <div class="progress-bar">
                <div class="progress-fill"></div>
            </div>
            <div class="eta">Estimated completion: 1 hour</div>
        </div>
        
        <p>
            Thank you for your patience. If you have any urgent questions, 
            please contact us at <strong>support@#cgi.server_name#</strong>
        </p>
        
        <div class="social-links">
            <a href="#" title="Twitter">🐦</a>
            <a href="#" title="Facebook">📘</a>
            <a href="#" title="Email">📧</a>
        </div>
        
        <cfif local.showBypass>
            <div class="bypass">
                <strong>Development Mode:</strong> 
                <a href="?reload=true">Exit Maintenance Mode</a>
            </div>
        </cfif>
    </div>
    
    <script>
        // Auto-refresh every 5 minutes to check if maintenance is complete
        setTimeout(function() {
            window.location.reload();
        }, 300000);
    </script>
</body>
</html>
```

## Configuration Settings

Several Wheels configuration settings control event behavior:

### Error Handling Configuration
```cfm
<!--- In /config/settings.cfm or environment-specific settings files --->

<!--- Show detailed error information (false in production) --->
<cfset set(showErrorInformation=false) />

<!--- Email administrators on errors --->
<cfset set(sendEmailOnError=true) />
<cfset set(errorEmailAddress="admin@example.com,dev@example.com") />
<cfset set(errorEmailSubject="Application Error - Production") />
```

### Environment-Specific Event Behavior
```cfm
<!--- In /config/production/settings.cfm --->
<cfset set(showErrorInformation=false) />
<cfset set(sendEmailOnError=true) />

<!--- In /config/development/settings.cfm --->
<cfset set(showErrorInformation=true) />
<cfset set(sendEmailOnError=false) />
```

## Common Event Patterns

### Request Logging and Analytics
```cfm
<!--- In onRequestStart.cfm --->
<cfscript>
// Initialize request tracking
request.trackingData = {
    startTime: getTickCount(),
    url: cgi.path_info,
    method: cgi.request_method,
    userAgent: cgi.http_user_agent,
    ip: cgi.remote_addr
};

// Track API requests separately
if (reFindNoCase("^/api/", cgi.path_info)) {
    request.isApiRequest = true;
    request.apiVersion = listGetAt(cgi.path_info, 2, "/");
}
</cfscript>

<!--- In onRequestEnd.cfm --->
<cfscript>
if (StructKeyExists(request, "trackingData")) {
    request.trackingData.endTime = getTickCount();
    request.trackingData.duration = request.trackingData.endTime - request.trackingData.startTime;
    
    // Log to database for analytics
    model("RequestLog").create(request.trackingData);
}
</cfscript>
```

### Security Headers and CORS
```cfm
<!--- In onRequestStart.cfm --->
<cfscript>
// Set security headers
header name="X-Frame-Options" value="DENY";
header name="X-Content-Type-Options" value="nosniff";
header name="X-XSS-Protection" value="1; mode=block";
header name="Referrer-Policy" value="strict-origin-when-cross-origin";

// Content Security Policy
header name="Content-Security-Policy" value="default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'";

// CORS headers for API requests
if (request.isApiRequest ?: false) {
    header name="Access-Control-Allow-Origin" value="*";
    header name="Access-Control-Allow-Methods" value="GET, POST, PUT, DELETE, OPTIONS";
    header name="Access-Control-Allow-Headers" value="Content-Type, Authorization, X-Requested-With";
    
    // Handle preflight requests
    if (cgi.request_method == "OPTIONS") {
        header name="Access-Control-Max-Age" value="86400";
        abort;
    }
}
</cfscript>
```

### Rate Limiting
```cfm
<!--- In onRequestStart.cfm --->
<cfscript>
// Simple rate limiting for API requests
if (request.isApiRequest ?: false) {
    local.clientKey = cgi.remote_addr;
    local.rateLimitKey = "rate_limit_" & hash(local.clientKey);
    
    // Check current request count
    local.currentCount = cacheGet(local.rateLimitKey, 0);
    
    if (local.currentCount >= 100) { // 100 requests per hour
        header statuscode="429" statustext="Too Many Requests";
        header name="Retry-After" value="3600";
        writeOutput('{"error": "Rate limit exceeded", "limit": 100, "window": "1 hour"}');
        abort;
    }
    
    // Increment counter
    cachePut(local.rateLimitKey, local.currentCount + 1, createTimeSpan(0, 1, 0, 0));
}
</cfscript>
```

### Application Health Monitoring
```cfm
<!--- In onApplicationStart.cfm --->
<cfscript>
// Initialize health monitoring
application.healthMetrics = {
    startTime: Now(),
    requestCount: 0,
    errorCount: 0,
    lastError: "",
    memoryUsage: 0
};

// Schedule periodic health checks
application.healthCheckInterval = 300; // 5 minutes
</cfscript>

<!--- In onRequestStart.cfm --->
<cfscript>
// Update request counter
application.healthMetrics.requestCount++;

// Check memory usage periodically
if (application.healthMetrics.requestCount % 100 == 0) {
    application.healthMetrics.memoryUsage = getMemoryUsage().used;
    
    // Alert if memory usage is high
    if (application.healthMetrics.memoryUsage > 1024000000) { // 1GB
        writeLog(file="health", text="High memory usage: #application.healthMetrics.memoryUsage# bytes");
    }
}
</cfscript>

<!--- In onerror.cfm (before HTML output) --->
<cfscript>
// Update error metrics
application.healthMetrics.errorCount++;
application.healthMetrics.lastError = arguments.exception.message;
</cfscript>
```

## Best Practices

### 1. Keep Events Lightweight
```cfm
<!--- Good - minimal processing --->
<cfscript>
// Log essential information
writeLog(file="requests", text="Request: #cgi.path_info#");

// Set simple variables
request.startTime = getTickCount();
</cfscript>

<!--- Avoid - heavy processing that slows every request --->
<cfscript>
// Don't do complex database queries or API calls in onRequestStart
// unless absolutely necessary
</cfscript>
```

### 2. Handle Errors Gracefully
```cfm
<cfscript>
// Always wrap risky operations in try/catch
try {
    // Potentially failing operation
    model("Analytics").recordPageView();
} catch (any e) {
    // Log error but don't fail the request
    writeLog(file="events_errors", text="Analytics error: #e.message#");
}
</cfscript>
```

### 3. Use Appropriate Event Files
```cfm
<!--- Application initialization - onApplicationStart.cfm --->
<!--- Per-request setup - onRequestStart.cfm --->
<!--- Per-request cleanup - onRequestEnd.cfm --->
<!--- User-specific setup - onSessionStart.cfm --->
<!--- Error handling - onerror.cfm, onerror.json.cfm, onerror.xml.cfm --->
<!--- 404 handling - onmissingtemplate.cfm --->
<!--- Maintenance mode - onmaintenance.cfm --->
```

### 4. Consider Performance Impact
```cfm
<cfscript>
// Cache expensive operations
if (!StructKeyExists(application, "expensiveData")) {
    application.expensiveData = model("Config").loadExpensiveData();
}

// Use efficient logging
writeLog(file="requests", text="URL: #cgi.path_info# | Time: #getTickCount()#");
</cfscript>
```

### 5. Environment-Specific Behavior
```cfm
<cfscript>
// Different behavior per environment
if (get("environment") == "development") {
    // Detailed logging in development
    writeLog(file="debug", text="Debug: #serializeJSON(arguments)#");
} else {
    // Minimal logging in production
    writeLog(file="requests", text="Request: #cgi.path_info#");
}
</cfscript>
```

## Global Functions

You can add application-wide functions by placing them in `/app/global/functions.cfm` instead of modifying `Application.cfc`:

```cfm
<!--- /app/global/functions.cfm --->
<cfscript>
/**
 * Custom application-wide functions
 */

function formatCurrency(amount, currency = "USD") {
    return dollarFormat(arguments.amount) & " " & arguments.currency;
}

function isProduction() {
    return get("environment") == "production";
}

function logError(message, category = "application") {
    writeLog(file=arguments.category, text=arguments.message);
}

function getClientIP() {
    // Handle various proxy headers
    if (StructKeyExists(cgi, "http_x_forwarded_for")) {
        return listFirst(cgi.http_x_forwarded_for);
    } else if (StructKeyExists(cgi, "http_x_real_ip")) {
        return cgi.http_x_real_ip;
    } else {
        return cgi.remote_addr;
    }
}
</cfscript>
```

## Important Notes

- **Don't modify framework files**: Always use event files instead of modifying core Wheels files
- **Event execution order**: Events fire in the standard CFML lifecycle order
- **Scope access**: Event files have access to all appropriate scopes (application, session, request, etc.)
- **Error handling**: Events should handle their own errors to avoid breaking the application
- **Performance**: Keep event processing lightweight to avoid slowing down every request
- **Format-specific events**: Use `.json.cfm` and `.xml.cfm` variants for API error responses
- **Maintenance mode**: After including `onmaintenance.cfm`, Wheels automatically calls `cfabort`
- **404 responses**: Make sure 404 pages are larger than 512 bytes for proper browser display
- **Global functions**: Use `/app/global/functions.cfm` instead of modifying `Application.cfc`

Events provide a clean, maintainable way to extend your Wheels application's lifecycle behavior without touching framework code.