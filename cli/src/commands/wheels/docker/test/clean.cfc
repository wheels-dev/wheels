/**
 * Clean up Docker test environment
 *
 * Removes all test containers, volumes, and generated files
 *
 * {code:bash}
 * wheels docker:test:clean
 * wheels docker:test:clean --keep-images
 * {code}
 */
component extends="../../base" {
    
    property name="fileSystemUtil" inject="FileSystem";
    
    /**
     * @keepImages.hint Don't remove Docker images
     * @force.hint Don't prompt for confirmation
     */
    function run(
        boolean keepImages = false,
        boolean force = false
    ) {
        var testDir = fileSystemUtil.resolvePath(".wheels-test");
        
        if (!directoryExists(testDir)) {
            print.yellowLine("No test environment found in current directory.");
            return;
        }
        
        if (!arguments.force) {
            print.line();
            print.yellowLine("This will remove:");
            print.line("  - All test containers");
            print.line("  - All test volumes");
            print.line("  - The .wheels-test directory");
            if (!arguments.keepImages) {
                print.line("  - Downloaded Docker images (if not used elsewhere)");
            }
            print.line();
            
            if (!confirm("Are you sure you want to clean up? [y/n]")) {
                print.line("Cleanup cancelled.");
                return;
            }
        }
        
        print.line();
        print.yellowLine("Cleaning up Docker test environment...");
        
        // Stop and remove containers and volumes
        if (fileExists("#testDir#/docker-compose.yml")) {
            command("!cd .wheels-test && docker compose down -v").run();
            print.greenLine("✓ Containers and volumes removed");
        }
        
        // Remove images if requested
        if (!arguments.keepImages && fileExists("#testDir#/docker-compose.yml")) {
            // Parse docker-compose.yml to get image names
            var composeContent = fileRead("#testDir#/docker-compose.yml");
            var imagePattern = "image:\s*([^\s]+)";
            var matches = reMatchNoCase(imagePattern, composeContent);
            
            for (var match in matches) {
                var imageName = trim(replaceNoCase(match, "image:", ""));
                if (len(imageName) && !findNoCase(":", imageName)) {
                    continue; // Skip if it's not a tagged image
                }
                print.line("  Removing image: #imageName#");
                try {
                    command("!docker rmi #imageName#").run();
                } catch (any e) {
                    // Image might be in use by other containers
                    print.yellowLine("  Could not remove #imageName# (may be in use)");
                }
            }
        }
        
        // Remove .wheels-test directory
        if (directoryExists(testDir)) {
            directoryDelete(testDir, true);
            print.greenLine("✓ .wheels-test directory removed");
        }
        
        print.line();
        print.greenBoldLine("✓ Docker test environment cleaned up successfully!");
    }
}