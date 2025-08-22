<cfscript>
    // Place code here that should be executed on the "onApplicationStart" event.
    // Wrapping this in a try / catch and skipping the error, as otherwise you can't get to the migrations
    try {	
        // Place code here that should be executed on the "onApplicationStart" event.	// Application Settings
        application["settings"] = {};

        // Change this! It's only used once for encrypting cookie contents, but
        // Still, use generateSecretKey("AES") to generate a new one.
        application.encryptionKey = "7NNEID99l07DySzq1LJnEA==";
        createApplicationSettings();
    } catch (any e) {
        WriteOutput("Error: " & e.message);
    }
</cfscript>