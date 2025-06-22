/**
 * List available templates and their override status
 */
component extends="commands.wheels.BaseCommand" {
    
    /**
     * List available templates and their override status
     * 
     * @type Template type to list (model, controller, view, migration, all)
     * @verbose Show template details and variables
     * @help Display available CLI templates and customization status
     */
    function run(string type = "all", boolean verbose = false) {
        ensureWheelsProject();
        
        print.line();
        print.boldBlueLine("Wheels CLI Templates");
        print.yellowLine("Template System: CommandBox @VARIABLE@ placeholders");
        print.line("=" repeatString 60);
        print.line();
        
        var builtInPath = getDirectoryFromPath(getCurrentTemplatePath()) & "../../../templates";
        var projectPath = getConfigPath("templates");
        
        var types = arguments.type == "all" ? ["model", "controller", "view", "migration"] : [arguments.type];
        
        for (var templateType in types) {
            listTemplatesForType(templateType, builtInPath, projectPath, arguments.verbose);
        }
        
        if (directoryExists(projectPath)) {
            print.yellowLine("Custom templates location:");
            print.indentedLine(projectPath);
            print.line();
            print.line("Your custom templates will be used instead of built-in templates.");
        } else {
            print.yellowLine("No custom templates found.");
            print.line("Run 'wheels templates copy' to customize templates for your project.");
        }
        
        if (!arguments.verbose) {
            print.line();
            print.line("Use --verbose to see template details and available variables.");
        }
    }
    
    private function listTemplatesForType(type, builtInPath, projectPath, verbose) {
        var builtInDir = arguments.builtInPath & "/" & arguments.type;
        
        if (!directoryExists(builtInDir)) {
            return;
        }
        
        print.greenBoldLine(uCase(arguments.type) & " Templates:");
        
        var templates = directoryList(builtInDir, false, "name", "*.cfc|*.cfm");
        
        if (arrayLen(templates) == 0) {
            print.indentedLine("No templates found");
            print.line();
            return;
        }
        
        for (var template in templates) {
            var projectTemplate = arguments.projectPath & "/" & arguments.type & "/" & template;
            var status = "Built-in";
            var statusColor = "white";
            
            if (fileExists(projectTemplate)) {
                status = "Customized";
                statusColor = "green";
            }
            
            if (statusColor == "green") {
                print.indented#statusColor#Line("✓ #template# [#status#]");
            } else {
                print.indentedLine("  #template# [#status#]");
            }
            
            if (arguments.verbose) {
                showTemplateDetails(arguments.type, template);
            }
        }
        
        print.line();
    }
    
    private function showTemplateDetails(type, template) {
        print.indentedLine("    └─ Description: #getTemplateDescription(arguments.type, arguments.template)#");
        
        var variables = getTemplateVariables(arguments.type, arguments.template);
        if (arrayLen(variables) > 0) {
            print.indentedLine("    └─ Variables:");
            for (var variable in variables) {
                print.indentedLine("       • @#variable#@");
            }
        }
    }
    
    private function getTemplateDescription(type, template) {
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
            structKeyExists(descriptions[arguments.type], arguments.template)) {
            return descriptions[arguments.type][arguments.template];
        }
        
        return "Custom template";
    }
    
    private function getTemplateVariables(type, template) {
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