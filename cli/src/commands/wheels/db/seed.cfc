/**
 * Generate and populate test data
 * 
 * {code:bash}
 * wheels db:seed
 * wheels db:seed --count=10
 * wheels db:seed --models=user,post
 * {code}
 */
component extends="../base" {

    /**
     * @models Comma-delimited list of models to seed (defaults to all)
     * @count Number of records to generate per model
     * @environment Environment to seed (defaults to current)
     * @dataFile Path to JSON file containing seed data
     */
    function run(
        string models="",
        numeric count=5,
        string environment="",
        string dataFile=""
    ) {
        // Welcome message
        print.line();
        print.boldMagentaLine("Wheels Database Seed");
        print.line();
        
        // Create URL parameters
        local.urlParams = "&command=dbSeed&count=#arguments.count#";
        
        if (len(trim(arguments.models))) {
            local.urlParams &= "&models=#urlEncodedFormat(arguments.models)#";
        }
        
        if (len(trim(arguments.environment))) {
            local.urlParams &= "&environment=#urlEncodedFormat(arguments.environment)#";
        }
        
        // Handle data file if provided
        if (len(trim(arguments.dataFile))) {
            local.filePath = fileSystemUtil.resolvePath(arguments.dataFile);
            if (!fileExists(local.filePath)) {
                error("Seed data file not found: #arguments.dataFile#");
            }
            
            try {
                local.seedData = fileRead(local.filePath);
                // Validate it's proper JSON
                local.seedData = deserializeJSON(local.seedData);
                local.urlParams &= "&dataProvided=true";
                
                // We'll also save this to a temporary location for the controller to access
                local.tempDataFile = fileSystemUtil.resolvePath("app/tmp/seed_data.json");
                file action='write' file='#local.tempDataFile#' mode='777' output='#serializeJSON(local.seedData)#';
                local.urlParams &= "&dataFile=#urlEncodedFormat(local.tempDataFile)#";
                
                print.yellowLine("Using seed data from: #arguments.dataFile#");
            } catch (any e) {
                error("Invalid JSON in seed data file: #e.message#");
            }
        }
        
        // Send command to seed database
        print.line("Seeding database...");
        local.result = $sendToCliCommand(urlstring=local.urlParams);
        if(!local.result.success){
			return;
		}
        
        // Display results
        if (structKeyExists(local.result, "success") && local.result.success) {
            print.boldGreenLine("Database seeded successfully");
            
            if (structKeyExists(local.result, "modelsSeeded") && isArray(local.result.modelsSeeded)) {
                print.line();
                print.yellowLine("Models seeded:");
                
                for (local.model in local.result.modelsSeeded) {
                    if (structKeyExists(local.model, "name") && structKeyExists(local.model, "count")) {
                        print.line(" - #local.model.name#: #local.model.count# records");
                    }
                }
            }
        } else {
            print.boldRedLine("Failed to seed database");
            if (structKeyExists(local.result, "message")) {
                print.redLine(local.result.message);
            }
        }
        
        print.line();
    }
}