/**
 * Copy CLI snippets to your project for customization
 */
component extends="../base" {
    
    /**
     * Copy CLI snippets to your project for customization
     * 
     * @type Snippet type to copy (model, controller, view, migration, all)
     * @force Overwrite existing snippets
     * @help Copy built-in snippets to your project for customization
     */
    function run(string type = "all", boolean force = false) {
        ensureWheelsProject();
        
        var snippetSource = getDirectoryFromPath(getCurrentTemplatePath()) & "../../../snippets";
        var snippetDest = getConfigPath("snippets");
        
        // Ensure snippets directory exists
        if (!directoryExists(snippetDest)) {
            directoryCreate(snippetDest, true);
        }
        
        print.line();
        print.boldBlueLine("Copying Wheels CLI snippets for customization");
        print.line();
        print.yellowLine("Snippets use CommandBox's @VARIABLE@ placeholder system:");
        print.indentedLine("✓ CFML-safe (no hash mark conflicts)");
        print.indentedLine("✓ Works with CSS colors and HTML fragments");
        print.indentedLine("✓ Battle-tested CommandBox standard");
        print.line();
        
        if (arguments.type == "all") {
            copyAllSnippets(snippetSource, snippetDest, arguments.force);
        } else {
            copySnippetType(arguments.type, snippetSource, snippetDest, arguments.force);
        }
        
        print.line();
        print.greenBoldLine("✅ Snippets copied successfully!");
        print.line();
        print.yellowLine("Snippet location:");
        print.indentedLine(snippetDest);
        print.line();
        print.boldLine("Available snippet variables:");
        print.line();
        
        // Show available variables based on template type
        if (arguments.type == "all" || arguments.type == "model") {
            print.greenLine("Model snippets:");
            print.indentedLine("@MODEL_NAME@         - Model name (e.g., User)");
            print.indentedLine("@TABLE_NAME@         - Database table name (e.g., users)");
            print.indentedLine("@PROPERTY_DEFINITIONS@ - Property definitions");
            print.indentedLine("@VALIDATIONS@        - Validation rules");
            print.indentedLine("@ASSOCIATIONS@       - Model associations");
            print.indentedLine("@TIMESTAMP@          - Generation timestamp");
            print.indentedLine("@GENERATED_BY@       - Generator information");
            print.line();
        }
        
        if (arguments.type == "all" || arguments.type == "controller") {
            print.greenLine("Controller snippets:");
            print.indentedLine("@CONTROLLER_NAME@    - Controller name (e.g., Users)");
            print.indentedLine("@MODEL_NAME@         - Associated model name");
            print.indentedLine("@SINGULAR_LOWER_NAME@ - Singular lowercase (e.g., user)");
            print.indentedLine("@PLURAL_LOWER_NAME@  - Plural lowercase (e.g., users)");
            print.indentedLine("@CONTROLLER_ACTIONS@ - Controller action methods");
            print.line();
        }
        
        print.yellowLine("Customization tips:");
        print.indentedLine("• Edit snippets in config/snippets/ to match your coding style");
        print.indentedLine("• Add your own variables and logic");
        print.indentedLine("• Snippets support full CFML syntax");
        print.indentedLine("• Changes apply to all future generated files");
        print.line();
        
        print.line("The CLI will automatically use your custom snippets when generating files.");
    }
    
    private function copyAllSnippets(source, dest, force) {
        var types = ["model", "controller", "view", "migration"];
        
        for (var type in types) {
            if (directoryExists(arguments.source & "/" & type)) {
                copySnippetType(type, arguments.source, arguments.dest, arguments.force);
            }
        }
        
        // Copy snippet configuration if exists
        var configFile = arguments.source & "/snippets.json";
        if (fileExists(configFile)) {
            var destFile = arguments.dest & "/snippets.json";
            
            if (fileExists(destFile) && !arguments.force) {
                if (confirm("Snippet configuration already exists. Overwrite?")) {
                    fileCopy(configFile, destFile);
                    print.greenLine("✓ Copied: snippets.json");
                } else {
                    print.yellowLine("⚠️  Skipped: snippets.json");
                }
            } else {
                fileCopy(configFile, destFile);
                print.greenLine("✓ Copied: snippets.json");
            }
        }
    }
    
    private function copySnippetType(type, source, dest, force) {
        var sourceDir = arguments.source & "/" & arguments.type;
        var destDir = arguments.dest & "/" & arguments.type;
        
        if (!directoryExists(sourceDir)) {
            error("Snippet type '#arguments.type#' not found. Valid types: model, controller, view, migration, all");
        }
        
        if (directoryExists(destDir) && !arguments.force) {
            if (!confirm("Snippets for '#arguments.type#' already exist. Overwrite?")) {
                print.yellowLine("Skipping #arguments.type# snippets...");
                return;
            }
        }
        
        print.yellowLine("Copying #arguments.type# snippets...");
        directoryCreate(destDir, true);
        
        var files = directoryList(sourceDir, false, "path", "*.cfc|*.cfm|*.txt");
        var copiedCount = 0;
        
        for (var file in files) {
            var fileName = getFileFromPath(file);
            var destFile = destDir & "/" & fileName;
            
            if (fileExists(destFile) && !arguments.force) {
                if (confirm("  File '#fileName#' exists. Overwrite?")) {
                    fileCopy(file, destFile);
                    print.greenLine("  ✓ Copied: #fileName#");
                    copiedCount++;
                } else {
                    print.yellowLine("  ⚠️  Skipped: #fileName#");
                }
            } else {
                fileCopy(file, destFile);
                print.greenLine("  ✓ Copied: #fileName#");
                copiedCount++;
            }
        }
        
        if (copiedCount > 0) {
            print.indentedLine("Copied #copiedCount# #arguments.type# snippet#copiedCount != 1 ? 's' : ''#");
        }
    }
}