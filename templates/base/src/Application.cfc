component {
    this.name = "WheelsTestEnvironment";
    this.sessionManagement = true;
    this.sessionTimeout = createTimeSpan(0, 0, 30, 0);
    
    // Set up mappings
    this.mappings["/wheels"] = expandPath("vendor/wheels");
    
    // Include app configuration if it exists
    if (fileExists(expandPath("config/app.cfm"))) {
        include "config/app.cfm";
    }
    
    // Handle requests to /wheels/* by serving from vendor/wheels
    public void function onRequestStart(string targetPage) {
        // Check if this is a wheels framework request
        if (findNoCase("/wheels/", CGI.SCRIPT_NAME)) {
            // Extract the path after /wheels/
            local.wheelsPath = reReplaceNoCase(CGI.SCRIPT_NAME, "^.*/wheels/", "");
            local.fullPath = expandPath("vendor/wheels/" & local.wheelsPath);
            
            // If the file exists, include it
            if (fileExists(local.fullPath)) {
                include "vendor/wheels/" & local.wheelsPath;
                abort;
            }
        }
        
        // Otherwise, continue with normal Wheels request handling
        include "vendor/wheels/events/onrequeststart.cfm";
    }
    
    // Include other Wheels application events
    include "vendor/wheels/events/onapplicationstart.cfm";
    include "vendor/wheels/events/onrequest.cfm";
    include "vendor/wheels/events/onrequestend.cfm";
    include "vendor/wheels/events/onerror.cfm";
    include "vendor/wheels/events/onmissingtemplate.cfm";
    include "vendor/wheels/events/onsessionstart.cfm";
    include "vendor/wheels/events/onsessionend.cfm";
}