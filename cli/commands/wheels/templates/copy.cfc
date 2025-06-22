/**
 * Copy CLI templates to your project for customization
 */
component extends="commands.wheels.BaseCommand" {
    
    /**
     * Copy CLI templates to your project for customization
     * 
     * @type Template type to copy (model, controller, view, migration, all)
     * @force Overwrite existing templates
     * @help Copy built-in templates to your project for customization
     */
    function run(string type = "all", boolean force = false) {
        ensureWheelsProject();
        
        var templateSource = getDirectoryFromPath(getCurrentTemplatePath()) & "../../../templates";
        var templateDest = getConfigPath("templates");
        
        // Ensure templates directory exists
        if (!directoryExists(templateDest)) {
            directoryCreate(templateDest, true);
        }
        
        print.line();
        print.boldBlueLine("Copying Wheels CLI templates for customization");
        print.line();
        print.yellowLine("Templates use CommandBox's @VARIABLE@ placeholder system:");
        print.indentedLine("✓ CFML-safe (no hash mark conflicts)");
        print.indentedLine("✓ Works with CSS colors and HTML fragments");
        print.indentedLine("✓ Battle-tested CommandBox standard");
        print.line();
        
        if (arguments.type == "all") {
            copyAllTemplates(templateSource, templateDest, arguments.force);
        } else {
            copyTemplateType(arguments.type, templateSource, templateDest, arguments.force);
        }
        
        print.line();
        print.greenBoldLine("✅ Templates copied successfully!");
        print.line();
        print.yellowLine("Template location:");
        print.indentedLine(templateDest);
        print.line();
        print.boldLine("Available template variables:");
        print.line();
        
        // Show available variables based on template type
        if (arguments.type == "all" || arguments.type == "model") {
            print.greenLine("Model templates:");
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
            print.greenLine("Controller templates:");
            print.indentedLine("@CONTROLLER_NAME@    - Controller name (e.g., Users)");
            print.indentedLine("@MODEL_NAME@         - Associated model name");
            print.indentedLine("@SINGULAR_LOWER_NAME@ - Singular lowercase (e.g., user)");
            print.indentedLine("@PLURAL_LOWER_NAME@  - Plural lowercase (e.g., users)");
            print.indentedLine("@CONTROLLER_ACTIONS@ - Controller action methods");
            print.line();
        }
        
        print.yellowLine("Customization tips:");
        print.indentedLine("• Edit templates in config/templates/ to match your coding style");
        print.indentedLine("• Add your own variables and logic");
        print.indentedLine("• Templates support full CFML syntax");
        print.indentedLine("• Changes apply to all future generated files");
        print.line();
        
        print.line("The CLI will automatically use your custom templates when generating files.");
    }
    
    private function copyAllTemplates(source, dest, force) {
        var types = ["model", "controller", "view", "migration"];
        
        for (var type in types) {
            if (directoryExists(arguments.source & "/" & type)) {
                copyTemplateType(type, arguments.source, arguments.dest, arguments.force);
            }
        }
        
        // Copy template configuration if exists
        var configFile = arguments.source & "/templates.json";
        if (fileExists(configFile)) {
            var destFile = arguments.dest & "/templates.json";
            
            if (fileExists(destFile) && !arguments.force) {
                if (confirm("Template configuration already exists. Overwrite?")) {
                    fileCopy(configFile, destFile);
                    print.greenLine("✓ Copied: templates.json");
                } else {
                    print.yellowLine("⚠️  Skipped: templates.json");
                }
            } else {
                fileCopy(configFile, destFile);
                print.greenLine("✓ Copied: templates.json");
            }
        }
    }
    
    private function copyTemplateType(type, source, dest, force) {
        var sourceDir = arguments.source & "/" & arguments.type;
        var destDir = arguments.dest & "/" & arguments.type;
        
        if (!directoryExists(sourceDir)) {
            error("Template type '#arguments.type#' not found. Valid types: model, controller, view, migration, all");
        }
        
        if (directoryExists(destDir) && !arguments.force) {
            if (!confirm("Templates for '#arguments.type#' already exist. Overwrite?")) {
                print.yellowLine("Skipping #arguments.type# templates...");
                return;
            }
        }
        
        print.yellowLine("Copying #arguments.type# templates...");
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
            print.indentedLine("Copied #copiedCount# #arguments.type# template#copiedCount != 1 ? 's' : ''#");
        }
    }
}