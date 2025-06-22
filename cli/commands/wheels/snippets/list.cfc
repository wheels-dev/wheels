/**
 * List available snippets and their override status
 */
component extends="commands.wheels.BaseCommand" {
    
    /**
     * List available snippets and their override status
     * 
     * @type Snippet type to list (model, controller, view, migration, all)
     * @verbose Show template details and variables
     * @help Display available CLI snippets and customization status
     */
    function run(string type = "all", boolean verbose = false) {
        ensureWheelsProject();
        
        print.line();
        print.boldBlueLine("Wheels CLI Snippets");
        print.yellowLine("Snippet System: CommandBox @VARIABLE@ placeholders");
        print.line(repeatString("=", 60));
        print.line();
        
        var builtInPath = getDirectoryFromPath(getCurrentTemplatePath()) & "../../../snippets";
        var projectPath = getConfigPath("snippets");
        
        var types = arguments.type == "all" ? ["model", "controller", "view", "migration"] : [arguments.type];
        
        for (var snippetType in types) {
            listSnippetsForType(snippetType, builtInPath, projectPath, arguments.verbose);
        }
        
        if (directoryExists(projectPath)) {
            print.yellowLine("Custom snippets location:");
            print.indentedLine(projectPath);
            print.line();
            print.line("Your custom snippets will be used instead of built-in snippets.");
        } else {
            print.yellowLine("No custom snippets found.");
            print.line("Run 'wheels snippets copy' to customize snippets for your project.");
        }
        
        if (!arguments.verbose) {
            print.line();
            print.line("Use --verbose to see snippet details and available variables.");
        }
    }
    
    private function listSnippetsForType(type, builtInPath, projectPath, verbose) {
        var builtInDir = arguments.builtInPath & "/" & arguments.type;
        
        if (!directoryExists(builtInDir)) {
            return;
        }
        
        print.greenBoldLine(uCase(arguments.type) & " Snippets:");
        
        var snippets = directoryList(builtInDir, false, "name", "*.cfc|*.cfm");
        
        if (arrayLen(snippets) == 0) {
            print.indentedLine("No snippets found");
            print.line();
            return;
        }
        
        for (var snippet in snippets) {
            var projectSnippet = arguments.projectPath & "/" & arguments.type & "/" & snippet;
            var status = "Built-in";
            var statusColor = "white";
            
            if (fileExists(projectSnippet)) {
                status = "Customized";
                statusColor = "green";
            }
            
            if (statusColor == "green") {
                print.indentedGreenLine("✓ #snippet# [#status#]");
            } else {
                print.indentedLine("  #snippet# [#status#]");
            }
            
            if (arguments.verbose) {
                showSnippetDetails(arguments.type, snippet);
            }
        }
        
        print.line();
    }
    
    private function showSnippetDetails(type, snippet) {
        print.indentedLine("    └─ Description: #getSnippetDescription(arguments.type, arguments.snippet)#");
        
        var variables = getSnippetVariables(arguments.type, arguments.snippet);
        if (arrayLen(variables) > 0) {
            print.indentedLine("    └─ Variables:");
            for (var variable in variables) {
                print.indentedLine("       • @#variable#@");
            }
        }
    }
    
    private function getSnippetDescription(type, snippet) {
        var descriptions = {
            "model" = {
                "Model.cfc" = "Basic model with minimal configuration",
                "ModelWithValidation.cfc" = "Model with validation helpers and custom rules",
                "ModelWithAudit.cfc" = "Model with audit trail and soft deletes",
                "ModelComplete.cfc" = "Full-featured model with all enhancements"
            },
            "controller" = {
                "Controller.cfc" = "Basic controller with empty actions",
                "ResourceController.cfc" = "RESTful controller with CRUD actions",
                "ApiController.cfc" = "API controller with JSON responses"
            },
            "view" = {
                "index.cfm" = "List view template",
                "show.cfm" = "Detail view template",
                "new.cfm" = "Create form template",
                "edit.cfm" = "Edit form template",
                "_form.cfm" = "Shared form partial"
            },
            "migration" = {
                "Migration.cfc" = "Database migration template"
            }
        };
        
        if (structKeyExists(descriptions, arguments.type) && 
            structKeyExists(descriptions[arguments.type], arguments.snippet)) {
            return descriptions[arguments.type][arguments.snippet];
        }
        
        return "Custom snippet";
    }
    
    private function getSnippetVariables(type, snippet) {
        var variables = [];
        
        switch(arguments.type) {
            case "model":
                variables = [
                    "MODEL_NAME",
                    "TABLE_NAME", 
                    "TIMESTAMP",
                    "GENERATED_BY",
                    "PROPERTY_DEFINITIONS",
                    "VALIDATIONS",
                    "ASSOCIATIONS"
                ];
                break;
                
            case "controller":
                variables = [
                    "CONTROLLER_NAME",
                    "MODEL_NAME",
                    "SINGULAR_LOWER_NAME",
                    "PLURAL_LOWER_NAME",
                    "PLURAL_NAME",
                    "TIMESTAMP",
                    "GENERATED_BY",
                    "CONTROLLER_ACTIONS"
                ];
                break;
                
            case "view":
                variables = [
                    "MODEL_NAME",
                    "SINGULAR_LOWER_NAME",
                    "PLURAL_LOWER_NAME",
                    "PLURAL_NAME",
                    "TABLE_HEADERS",
                    "TABLE_CELLS",
                    "FORM_FIELDS"
                ];
                break;
                
            case "migration":
                variables = [
                    "MIGRATION_NAME",
                    "TABLE_NAME",
                    "TIMESTAMP",
                    "GENERATED_BY",
                    "COLUMN_DEFINITIONS"
                ];
                break;
        }
        
        return variables;
    }
}