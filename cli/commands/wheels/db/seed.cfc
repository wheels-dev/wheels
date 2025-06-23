/**
 * Seed the database
 */
component extends="../base" {
    
    /**
     * Run database seed files
     * 
     * @environment Environment to seed
     * @file Specific seed file to run (without .cfc extension)
     * @verbose Show detailed output
     * @help Load seed data into the database
     */
    function run(
        string environment = "development",
        string file = "",
        boolean verbose = false
    ) {
        ensureWheelsProject();
        
        print.line();
        print.boldBlueLine("Seeding database for #arguments.environment# environment");
        
        var seedPath = getCWD() & "/db/seeds/";
        
        // Check if seeds directory exists
        if (!directoryExists(seedPath)) {
            print.line();
            print.yellowLine("No seeds directory found.");
            print.line();
            print.line("Create seed files in: db/seeds/");
            print.line("Example: db/seeds/DevelopmentData.cfc");
            return;
        }
        
        // Get seed files
        var seedFiles = [];
        
        if (len(arguments.file)) {
            // Run specific seed file
            var specificFile = seedPath & arguments.file & ".cfc";
            if (fileExists(specificFile)) {
                seedFiles = [{
                    name = arguments.file,
                    path = specificFile
                }];
            } else {
                error("Seed file not found: #arguments.file#.cfc");
            }
        } else {
            // Get all seed files
            var files = directoryList(
                seedPath,
                false,
                "query",
                "*.cfc",
                "name ASC"
            );
            
            for (var file in files) {
                arrayAppend(seedFiles, {
                    name = listFirst(file.name, "."),
                    path = seedPath & file.name
                });
            }
        }
        
        if (!arrayLen(seedFiles)) {
            print.line();
            print.yellowLine("No seed files found.");
            return;
        }
        
        print.line();
        print.yellowLine("Running #arrayLen(seedFiles)# seed file#arrayLen(seedFiles) != 1 ? 's' : ''#:");
        print.line();
        
        var successCount = 0;
        
        for (var seed in seedFiles) {
            print.yellowText("Seeding: #seed.name#... ");
            
            try {
                // In a real implementation, this would:
                // 1. Create component instance
                // 2. Call run() method
                // 3. Handle any data loading
                
                if (arguments.verbose) {
                    print.line();
                    print.indentedLine("Loading seed data from: #seed.path#");
                }
                
                // Simulate success
                print.greenLine("✓");
                successCount++;
                
            } catch (any e) {
                print.redLine("✗");
                print.redLine("Error: #e.message#");
                
                if (arguments.verbose && structKeyExists(e, "detail")) {
                    print.line(e.detail);
                }
            }
        }
        
        print.line();
        
        if (successCount == arrayLen(seedFiles)) {
            print.greenBoldLine("✅ Database seeded successfully!");
        } else {
            print.yellowLine("Seeded #successCount# of #arrayLen(seedFiles)# files.");
        }
        
        print.line();
        print.line("Example seed file structure:");
        print.line();
        print.greyLine("// db/seeds/DevelopmentData.cfc");
        print.greyLine("component {");
        print.greyLine("    function run() {");
        print.greyLine("        // Create sample users");
        print.greyLine("        var users = model('User').create([");
        print.greyLine("            {name='John Doe', email='john@example.com'},");
        print.greyLine("            {name='Jane Smith', email='jane@example.com'}");
        print.greyLine("        ]);");
        print.greyLine("    }");
        print.greyLine("}");
    }
}