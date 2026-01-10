<cfscript>
    // Place code here that should be executed on the "onRequestStart" event.
    /*
      If authenticated, try and force a refresh on any auth'd page to stop browser caching
      of potentially sensitive information
    */
    if(isAuthenticated()){
    	cfheader(name="Cache-Control", value="no-store, must-revalidate");
    }
</cfscript>