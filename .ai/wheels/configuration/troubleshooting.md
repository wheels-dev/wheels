# Configuration Troubleshooting

## Troubleshooting Configuration

### Common Issues

#### Configuration not loading

**Symptoms:**
- Settings don't take effect
- Application behaves as if using defaults
- No errors displayed

**Solutions:**
- Check file syntax for CFML errors
- Verify file permissions (files must be readable)
- Ensure proper `<cfscript>` tags
- Confirm file paths are correct

**Debug Steps:**
```cfm
// Check if configuration file exists
<cfif FileExists(ExpandPath("/config/settings.cfm"))>
    <cfoutput>Configuration file found</cfoutput>
<cfelse>
    <cfoutput>Configuration file NOT found</cfoutput>
</cfif>

// Dump current settings
<cfdump var="#application.wheels.settings#" label="Current Settings">
```

#### Settings not taking effect

**Symptoms:**
- Configuration appears to load but settings don't work
- Old settings still active after changes

**Solutions:**
- Issue reload: `?reload=true`
- Check environment-specific overrides in `/config/[environment]/settings.cfm`
- Verify setting name spelling (case-sensitive)
- Clear application scope if necessary

**Debug Steps:**
```cfm
// Check specific setting value
<cfoutput>Environment: #get("environment")#</cfoutput>
<cfoutput>Show Debug: #get("showDebugInformation")#</cfoutput>
<cfoutput>Cache Actions: #get("cacheActions")#</cfoutput>

// Check if environment override exists
<cfset environmentFile = "/config/" & get("environment") & "/settings.cfm">
<cfif FileExists(ExpandPath(environmentFile))>
    <cfoutput>Environment override file exists: #environmentFile#</cfoutput>
<cfelse>
    <cfoutput>No environment override file found</cfoutput>
</cfif>
```

#### Route conflicts

**Symptoms:**
- URLs don't resolve to expected controllers/actions
- Wrong controller actions are called
- 404 errors for valid URLs

**Solutions:**
- Check route order (first match wins)
- Use route debugging: Click "Routes" in debug footer
- Verify pattern syntax
- Ensure `.end()` is called on mapper

**Debug Steps:**
```cfm
// Enable route debugging in footer
set(showDebugInformation = true);

// Check route order in browser debug footer
// Look for "Routes" link at bottom of page

// Test specific route matching
<cfset routeExists = application.wheels.routes.findRoute(
    controller = "users",
    action = "show"
)>
<cfif IsStruct(routeExists)>
    <cfoutput>Route found: #routeExists.pattern#</cfoutput>
<cfelse>
    <cfoutput>Route not found</cfoutput>
</cfif>
```

#### Database connection issues

**Symptoms:**
- Database errors on application start
- "Datasource not found" errors
- Connection timeout errors

**Solutions:**
- Verify datasource configuration in `app.cfm`
- Check database driver availability
- Test connection in ColdFusion Administrator
- Ensure database server is running

**Debug Steps:**
```cfm
// Test database connection
<cftry>
    <cfquery name="testQuery" datasource="#get('dataSourceName')#">
        SELECT 1 as test
    </cfquery>
    <cfoutput>Database connection successful</cfoutput>
<cfcatch>
    <cfoutput>Database connection failed: #cfcatch.message#</cfoutput>
</cfcatch>
</cftry>

// Check datasource configuration
<cfdump var="#application.datasources#" label="Configured Datasources">
```

## Environment-Specific Issues

### Development Environment Problems

#### Caching interfering with development

**Problem:** Changes not reflected immediately
**Solution:**
```cfm
// In /config/development/settings.cfm
set(cacheActions = false);
set(cachePages = false);
set(cachePartials = false);
set(cacheControllerConfig = false);
set(cacheModelConfig = false);
```

#### Debug information not showing

**Problem:** Can't see debug panel or error details
**Solution:**
```cfm
// Enable all debug features
set(showDebugInformation = true);
set(showErrorInformation = true);

// Check if debug panel is being hidden by CSS
// Look for debug-footer CSS classes
```

### Production Environment Problems

#### Performance issues

**Problem:** Slow page loads, high memory usage
**Solutions:**
```cfm
// Enable aggressive caching
set(cacheActions = true);
set(cachePages = true);
set(cachePartials = true);
set(cacheQueries = true);
set(defaultCacheTime = 120);

// Increase cache limits
set(maximumItemsToCache = 10000);

// Monitor memory usage
<cfoutput>
Java Free Memory: #NumberFormat(GetMemoryUsage().free / 1024 / 1024, "0.00")# MB<br>
Java Used Memory: #NumberFormat(GetMemoryUsage().used / 1024 / 1024, "0.00")# MB<br>
Java Max Memory: #NumberFormat(GetMemoryUsage().max / 1024 / 1024, "0.00")# MB
</cfoutput>
```

#### Error emails not being sent

**Problem:** Not receiving error notifications
**Solutions:**
```cfm
// Verify email configuration
set(sendEmailOnError = true);
set(errorEmailAddress = "alerts@myapp.com");

// Test email functionality
<cfmail to="test@myapp.com" from="noreply@myapp.com" subject="Test Email">
This is a test email to verify mail configuration.
</cfmail>

// Check mail logs
<cflog file="mail" text="Testing mail configuration">
```

### Testing Environment Problems

#### Tests running slowly

**Problem:** Test suite takes too long to execute
**Solutions:**
```cfm
// Optimize test environment caching
set(cacheQueries = true); // Cache queries for speed
set(cacheActions = true); // Cache actions
set(cachePages = false); // Don't cache pages (might interfere)

// Use in-memory database for tests
this.datasources['test'] = {
    class: 'org.h2.Driver',
    connectionString: 'jdbc:h2:mem:test;DB_CLOSE_DELAY=-1',
    username: 'sa'
};
```

## Route Debugging

### Common Route Issues

#### Routes not working after reload

**Problem:** Routes worked before but stopped after reload
**Debug:**
```cfm
// Check for syntax errors in routes.cfm
// Verify all mappers end with .end()
// Look for missing commas or brackets
```

#### Nested resource routing errors

**Problem:** Trying to use Rails-style nested resources
**Incorrect:**
```cfm
.resources("posts", function(nested) {
    nested.resources("comments"); // This doesn't work
})
```

**Correct:**
```cfm
.resources("posts")
.resources("comments") // Separate declarations
```

#### Wildcard route catching everything

**Problem:** Custom routes never reached
**Solution:**
```cfm
mapper()
    // Put specific routes BEFORE wildcard
    .resources("posts")
    .get(name="search", pattern="search", to="search##index")

    // Wildcard MUST be last
    .wildcard()
.end();
```

### Route Testing Tools

#### Debug Route Resolution

```cfm
// Add this to any view to debug current route
<cfoutput>
<div class="debug-route">
    <h4>Current Route Debug</h4>
    <ul>
        <li>Controller: #params.controller#</li>
        <li>Action: #params.action#</li>
        <li>Key: #params.key#</li>
        <li>Route: #params.route#</li>
    </ul>
</div>
</cfoutput>
```

#### Test Route Helpers

```cfm
// Test route generation
<cftry>
    <cfset userUrl = urlFor(route="user", key=123)>
    <cfoutput>User URL: #userUrl#</cfoutput>
<cfcatch>
    <cfoutput>Route generation failed: #cfcatch.message#</cfoutput>
</cfcatch>
</cftry>
```

## Configuration Validation

### Settings Validation Script

```cfm
<!--- Create /config/validate.cfm for configuration testing --->
<cfoutput>
<h2>Configuration Validation</h2>

<h3>Environment</h3>
<p>Current Environment: <strong>#get("environment")#</strong></p>

<h3>Database</h3>
<cftry>
    <cfquery name="dbTest" datasource="#get('dataSourceName')#">
        SELECT 1 as working
    </cfquery>
    <p style="color: green;">✓ Database connection successful</p>
<cfcatch>
    <p style="color: red;">✗ Database connection failed: #cfcatch.message#</p>
</cfcatch>
</cftry>

<h3>Critical Settings</h3>
<ul>
    <li>Debug Information: #get("showDebugInformation")#</li>
    <li>Error Information: #get("showErrorInformation")#</li>
    <li>Send Error Email: #get("sendEmailOnError")#</li>
    <li>Cache Actions: #get("cacheActions")#</li>
    <li>Cache Pages: #get("cachePages")#</li>
    <li>URL Rewriting: #get("URLRewriting")#</li>
</ul>

<h3>Route Testing</h3>
<cftry>
    <cfset homeUrl = urlFor(route="root")>
    <p style="color: green;">✓ Root route working: #homeUrl#</p>
<cfcatch>
    <p style="color: red;">✗ Root route failed: #cfcatch.message#</p>
</cfcatch>
</cftry>

<h3>File Permissions</h3>
<cfset configFiles = [
    "/config/app.cfm",
    "/config/environment.cfm",
    "/config/settings.cfm",
    "/config/routes.cfm"
]>
<cfloop array="#configFiles#" index="file">
    <cfif FileExists(ExpandPath(file))>
        <p style="color: green;">✓ #file# exists and readable</p>
    <cfelse>
        <p style="color: red;">✗ #file# not found or not readable</p>
    </cfif>
</cfloop>
</cfoutput>
```

## Performance Debugging

### Memory Usage Monitoring

```cfm
<cffunction name="getMemoryInfo">
    <cfset local.runtime = CreateObject("java", "java.lang.Runtime").getRuntime()>
    <cfset local.mb = 1024 * 1024>

    <cfreturn {
        maxMemory = local.runtime.maxMemory() / local.mb,
        totalMemory = local.runtime.totalMemory() / local.mb,
        freeMemory = local.runtime.freeMemory() / local.mb,
        usedMemory = (local.runtime.totalMemory() - local.runtime.freeMemory()) / local.mb
    }>
</cffunction>

<cfset memInfo = getMemoryInfo()>
<cfoutput>
<div class="memory-debug">
    <h4>Memory Usage</h4>
    <ul>
        <li>Used: #NumberFormat(memInfo.usedMemory, "0.00")# MB</li>
        <li>Free: #NumberFormat(memInfo.freeMemory, "0.00")# MB</li>
        <li>Total: #NumberFormat(memInfo.totalMemory, "0.00")# MB</li>
        <li>Max: #NumberFormat(memInfo.maxMemory, "0.00")# MB</li>
    </ul>
</div>
</cfoutput>
```

### Cache Debugging

```cfm
<cfif get("showDebugInformation")>
    <cfoutput>
    <div class="cache-debug">
        <h4>Cache Status</h4>
        <ul>
            <li>Cache Actions: #get("cacheActions")#</li>
            <li>Cache Pages: #get("cachePages")#</li>
            <li>Cache Partials: #get("cachePartials")#</li>
            <li>Cache Queries: #get("cacheQueries")#</li>
            <li>Default Cache Time: #get("defaultCacheTime")# minutes</li>
        </ul>
    </div>
    </cfoutput>
</cfif>
```

## Emergency Fixes

### Quick Configuration Reset

```cfm
// In case of configuration corruption, reset to defaults
// Add this to /config/emergency-reset.cfm

<cfscript>
// Minimal working configuration
set(environment = "development");
set(dataSourceName = "");
set(showDebugInformation = true);
set(showErrorInformation = true);
set(sendEmailOnError = false);

// Disable all caching
set(cacheActions = false);
set(cachePages = false);
set(cachePartials = false);
set(cacheQueries = false);

// Basic URL rewriting
set(URLRewriting = "On");
</cfscript>

<cfoutput>
<h2>Emergency Configuration Reset</h2>
<p>Configuration has been reset to safe defaults.</p>
<p><a href="?reload=true">Reload Application</a></p>
</cfoutput>
```

### Configuration Backup

```cfm
// Create configuration backup before making changes
<cfset configBackup = {
    environment = get("environment"),
    dataSourceName = get("dataSourceName"),
    showDebugInformation = get("showDebugInformation"),
    cacheActions = get("cacheActions"),
    cachePages = get("cachePages")
}>

<cffile action="write"
        file="#ExpandPath('/config/backup-' & DateFormat(Now(), 'yyyymmdd') & '.json')#"
        output="#SerializeJSON(configBackup)#">
```