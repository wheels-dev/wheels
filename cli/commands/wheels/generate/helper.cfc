/**
 * Generate helper functions for use in views and controllers
 * 
 * Examples:
 * wheels generate helper Format
 * wheels generate helper StringUtils --functions="truncate,highlight,slugify"
 * wheels generate helper DateHelpers --global=true
 * wheels generate helper ViewHelpers --type=view
 */
component aliases='wheels g helper' extends="../base" {
    
    property name="codeGenerationService" inject="CodeGenerationService@wheels-cli";
    property name="helpers" inject="helpers@wheels-cli";
    property name="detailOutput" inject="DetailOutputService@wheels-cli";
    
    /**
     * @name.hint Name of the helper (e.g., FormatHelper, StringHelper)
     * @functions.hint Comma-separated list of functions to generate
     * @type.hint Helper type: controller, view, or global (default: global)
     * @global.hint Make helper functions available globally (default: false)
     * @description.hint Helper description
     * @force.hint Overwrite existing files
     */
    function run(
        required string name,
        string functions = "helperFunction",
        string type = "global",
        boolean global = false,
        string description = "",
        boolean force = false
    ) {
        detailOutput.header("🛠️", "Generating helper: #arguments.name#");
        
        // Ensure name ends with "Helper" or "Helpers"
        if (!reFindNoCase("Helper(s)?$", arguments.name)) {
            arguments.name &= "Helper";
        }
        
        // Validate helper name
        var validation = codeGenerationService.validateName(arguments.name, "helper");
        if (!validation.valid) {
            error("Invalid helper name: " & arrayToList(validation.errors, ", "));
            return;
        }
        
        // Validate type
        if (!listFindNoCase("controller,view,global", arguments.type)) {
            error("Invalid helper type. Must be 'controller', 'view', or 'global'.");
            return;
        }
        
        // Set up paths based on type
        var helperDir = "";
        switch(arguments.type) {
            case "controller":
                helperDir = helpers.getAppPath() & "/controllers/helpers";
                break;
            case "view":
                helperDir = helpers.getAppPath() & "/views/helpers";
                break;
            default:
                helperDir = helpers.getAppPath() & "/helpers";
        }
        
        if (!directoryExists(helperDir)) {
            directoryCreate(helperDir);
            detailOutput.output("Created helpers directory: #replace(helperDir, helpers.getAppPath(), '')#");
        }
        
        var helperPath = helperDir & "/" & arguments.name & ".cfc";
        
        // Check if file exists
        if (fileExists(helperPath) && !arguments.force) {
            error("Helper already exists: #arguments.name#.cfc. Use --force to overwrite.");
            return;
        }
        
        // Parse functions
        var functionList = listToArray(arguments.functions, ",");
        
        // Generate helper content
        var helperContent = generateHelperContent(arguments, functionList);
        
        // Write helper file
        fileWrite(helperPath, helperContent);
        detailOutput.success("Created helper: #replace(helperPath, helpers.getAppPath(), '')#");
        
        // Create test file
        createHelperTest(arguments.name, functionList, arguments.type);
        
        // Show usage example
        detailOutput.separator();
        detailOutput.output("Usage example:");
        
        if (arguments.global || arguments.type == "global") {
            detailOutput.code('// Helper functions are automatically available globally
result = #functionList[1]#("some input");

// In views
<cfoutput>
    ##format#uCase(left(functionList[1], 1)) & mid(functionList[1], 2, len(functionList[1]))#(data)##
</cfoutput>', "cfscript");
        } else if (arguments.type == "controller") {
            detailOutput.code('// In your controller
component extends="Controller" {
    function config() {
        // Include the helper
        includeHelpers("#arguments.name#");
    }
    
    function index() {
        // Use the helper function
        result = #functionList[1]#("some input");
    }
}', "cfscript");
        } else {
            detailOutput.code('// In your view
<cfoutput>
    ##format#uCase(left(functionList[1], 1)) & mid(functionList[1], 2, len(functionList[1]))#(data)##
</cfoutput>', "cfscript");
        }
        
        // If global, show how to register
        if (arguments.global && arguments.type != "global") {
            detailOutput.separator();
            detailOutput.output("To make this helper global, add to /config/settings.cfm:");
            detailOutput.code('// Include helper globally
set(functionName = "includeHelpers", helper = "#arguments.name#");', "cfscript");
        }
    }
    
    /**
     * Generate helper component content
     */
    private string function generateHelperContent(required struct args, required array functions) {
        var content = "/**" & chr(10);
        content &= " * #args.name#" & chr(10);
        if (len(args.description)) {
            content &= " * #args.description#" & chr(10);
        }
        content &= " * Type: #args.type# helper" & chr(10);
        content &= " */" & chr(10);
        content &= "component {" & chr(10) & chr(10);
        
        // Include Wheels helper functions
        content &= chr(9) & "// Include Wheels framework helpers" & chr(10);
        content &= chr(9) & "include ""/wheels/global/functions.cfm"";" & chr(10) & chr(10);
        
        // Generate functions
        for (var func in functions) {
            content &= generateHelperFunction(trim(func), args.type);
        }
        
        content &= "}";
        
        return content;
    }
    
    /**
     * Generate individual helper function
     */
    private string function generateHelperFunction(required string functionName, required string type) {
        var content = chr(9) & "/**" & chr(10);
        content &= chr(9) & " * #humanize(functionName)# helper function" & chr(10);
        content &= chr(9) & " * @value.hint The value to process" & chr(10);
        content &= chr(9) & " * @options.hint Additional options" & chr(10);
        content &= chr(9) & " * @return Processed value" & chr(10);
        content &= chr(9) & " */" & chr(10);
        content &= chr(9) & "public any function #functionName#(" & chr(10);
        content &= chr(9) & chr(9) & "required any value," & chr(10);
        content &= chr(9) & chr(9) & "struct options = {}" & chr(10);
        content &= chr(9) & ") {" & chr(10);
        
        // Add sample implementation based on function name
        if (findNoCase("format", functionName)) {
            content &= generateFormatFunction(functionName);
        } else if (findNoCase("truncate", functionName)) {
            content &= generateTruncateFunction();
        } else if (findNoCase("highlight", functionName)) {
            content &= generateHighlightFunction();
        } else if (findNoCase("slugify", functionName)) {
            content &= generateSlugifyFunction();
        } else if (findNoCase("date", functionName)) {
            content &= generateDateFunction();
        } else if (findNoCase("currency", functionName) || findNoCase("money", functionName)) {
            content &= generateCurrencyFunction();
        } else {
            content &= chr(9) & chr(9) & "// TODO: Implement #functionName# logic" & chr(10);
            content &= chr(9) & chr(9) & "return arguments.value;" & chr(10);
        }
        
        content &= chr(9) & "}" & chr(10) & chr(10);
        
        return content;
    }
    
    // Sample function generators
    private string function generateFormatFunction(required string functionName) {
        var content = chr(9) & chr(9) & "// Format the value based on type" & chr(10);
        content &= chr(9) & chr(9) & "if (isNumeric(arguments.value)) {" & chr(10);
        content &= chr(9) & chr(9) & chr(9) & "return numberFormat(arguments.value, arguments.options.mask ?: ""0.00"");" & chr(10);
        content &= chr(9) & chr(9) & "} else if (isDate(arguments.value)) {" & chr(10);
        content &= chr(9) & chr(9) & chr(9) & "return dateFormat(arguments.value, arguments.options.mask ?: ""mm/dd/yyyy"");" & chr(10);
        content &= chr(9) & chr(9) & "} else {" & chr(10);
        content &= chr(9) & chr(9) & chr(9) & "return toString(arguments.value);" & chr(10);
        content &= chr(9) & chr(9) & "}" & chr(10);
        return content;
    }
    
    private string function generateTruncateFunction() {
        var content = chr(9) & chr(9) & "// Truncate text to specified length" & chr(10);
        content &= chr(9) & chr(9) & "local.length = arguments.options.length ?: 100;" & chr(10);
        content &= chr(9) & chr(9) & "local.suffix = arguments.options.suffix ?: ""..."";" & chr(10);
        content &= chr(10);
        content &= chr(9) & chr(9) & "if (len(arguments.value) <= local.length) {" & chr(10);
        content &= chr(9) & chr(9) & chr(9) & "return arguments.value;" & chr(10);
        content &= chr(9) & chr(9) & "}" & chr(10);
        content &= chr(10);
        content &= chr(9) & chr(9) & "return left(arguments.value, local.length - len(local.suffix)) & local.suffix;" & chr(10);
        return content;
    }
    
    private string function generateHighlightFunction() {
        var content = chr(9) & chr(9) & "// Highlight search terms in text" & chr(10);
        content &= chr(9) & chr(9) & "local.searchTerm = arguments.options.term ?: """";" & chr(10);
        content &= chr(9) & chr(9) & "local.highlightClass = arguments.options.class ?: ""highlight"";" & chr(10);
        content &= chr(10);
        content &= chr(9) & chr(9) & "if (!len(local.searchTerm)) {" & chr(10);
        content &= chr(9) & chr(9) & chr(9) & "return arguments.value;" & chr(10);
        content &= chr(9) & chr(9) & "}" & chr(10);
        content &= chr(10);
        content &= chr(9) & chr(9) & "return reReplaceNoCase(" & chr(10);
        content &= chr(9) & chr(9) & chr(9) & "arguments.value," & chr(10);
        content &= chr(9) & chr(9) & chr(9) & """(#local.searchTerm#)""," & chr(10);
        content &= chr(9) & chr(9) & chr(9) & """<span class=\""#local.highlightClass#\"">\\1</span>""," & chr(10);
        content &= chr(9) & chr(9) & chr(9) & """all""" & chr(10);
        content &= chr(9) & chr(9) & ");" & chr(10);
        return content;
    }
    
    private string function generateSlugifyFunction() {
        var content = chr(9) & chr(9) & "// Convert text to URL-friendly slug" & chr(10);
        content &= chr(9) & chr(9) & "local.slug = lCase(trim(arguments.value));" & chr(10);
        content &= chr(10);
        content &= chr(9) & chr(9) & "// Replace spaces with hyphens" & chr(10);
        content &= chr(9) & chr(9) & "local.slug = reReplace(local.slug, ""\s+"", ""-"", ""all"");" & chr(10);
        content &= chr(10);
        content &= chr(9) & chr(9) & "// Remove non-alphanumeric characters except hyphens" & chr(10);
        content &= chr(9) & chr(9) & "local.slug = reReplace(local.slug, ""[^a-z0-9\-]"", """", ""all"");" & chr(10);
        content &= chr(10);
        content &= chr(9) & chr(9) & "// Remove multiple consecutive hyphens" & chr(10);
        content &= chr(9) & chr(9) & "local.slug = reReplace(local.slug, ""\-+"", ""-"", ""all"");" & chr(10);
        content &= chr(10);
        content &= chr(9) & chr(9) & "// Trim hyphens from start and end" & chr(10);
        content &= chr(9) & chr(9) & "local.slug = reReplace(local.slug, ""^\-|\-$"", """", ""all"");" & chr(10);
        content &= chr(10);
        content &= chr(9) & chr(9) & "return local.slug;" & chr(10);
        return content;
    }
    
    private string function generateDateFunction() {
        var content = chr(9) & chr(9) & "// Format date with relative time support" & chr(10);
        content &= chr(9) & chr(9) & "if (!isDate(arguments.value)) {" & chr(10);
        content &= chr(9) & chr(9) & chr(9) & "return arguments.value;" & chr(10);
        content &= chr(9) & chr(9) & "}" & chr(10);
        content &= chr(10);
        content &= chr(9) & chr(9) & "local.format = arguments.options.format ?: ""medium"";" & chr(10);
        content &= chr(10);
        content &= chr(9) & chr(9) & "switch(local.format) {" & chr(10);
        content &= chr(9) & chr(9) & chr(9) & "case ""relative"":" & chr(10);
        content &= chr(9) & chr(9) & chr(9) & chr(9) & "return timeAgoInWords(arguments.value);" & chr(10);
        content &= chr(9) & chr(9) & chr(9) & "case ""short"":" & chr(10);
        content &= chr(9) & chr(9) & chr(9) & chr(9) & "return dateFormat(arguments.value, ""m/d/yy"");" & chr(10);
        content &= chr(9) & chr(9) & chr(9) & "case ""long"":" & chr(10);
        content &= chr(9) & chr(9) & chr(9) & chr(9) & "return dateFormat(arguments.value, ""mmmm d, yyyy"");" & chr(10);
        content &= chr(9) & chr(9) & chr(9) & "default:" & chr(10);
        content &= chr(9) & chr(9) & chr(9) & chr(9) & "return dateFormat(arguments.value, ""mmm d, yyyy"");" & chr(10);
        content &= chr(9) & chr(9) & "}" & chr(10);
        return content;
    }
    
    private string function generateCurrencyFunction() {
        var content = chr(9) & chr(9) & "// Format currency values" & chr(10);
        content &= chr(9) & chr(9) & "if (!isNumeric(arguments.value)) {" & chr(10);
        content &= chr(9) & chr(9) & chr(9) & "return arguments.value;" & chr(10);
        content &= chr(9) & chr(9) & "}" & chr(10);
        content &= chr(10);
        content &= chr(9) & chr(9) & "local.currency = arguments.options.currency ?: ""USD"";" & chr(10);
        content &= chr(9) & chr(9) & "local.symbol = arguments.options.symbol ?: ""$"";" & chr(10);
        content &= chr(10);
        content &= chr(9) & chr(9) & "return local.symbol & numberFormat(arguments.value, ""0.00"");" & chr(10);
        return content;
    }
    
    /**
     * Create test file for helper
     */
    private void function createHelperTest(required string helperName, required array functions, required string type) {
        var testsDir = helpers.getTestPath() & "/helpers";
        
        if (!directoryExists(testsDir)) {
            directoryCreate(testsDir);
        }
        
        var testPath = testsDir & "/" & helperName & "Test.cfc";
        
        if (!fileExists(testPath)) {
            var testContent = generateHelperTest(helperName, functions, type);
            fileWrite(testPath, testContent);
            detailOutput.output("Created test: /tests/helpers/#helperName#Test.cfc");
        }
    }
    
    /**
     * Generate helper test content
     */
    private string function generateHelperTest(required string helperName, required array functions, required string type) {
        var content = "component extends=""wheels.Test"" {" & chr(10) & chr(10);
        
        content &= chr(9) & "function setup() {" & chr(10);
        content &= chr(9) & chr(9) & "// Include the helper" & chr(10);
        content &= chr(9) & chr(9) & "include ""/app/helpers/#helperName#.cfc"";" & chr(10);
        content &= chr(9) & "}" & chr(10) & chr(10);
        
        for (var func in functions) {
            content &= chr(9) & "function test_#trim(func)#() {" & chr(10);
            content &= chr(9) & chr(9) & "// Test #trim(func)# function" & chr(10);
            content &= chr(9) & chr(9) & "local.input = ""test value"";" & chr(10);
            content &= chr(9) & chr(9) & "local.result = #trim(func)#(local.input);" & chr(10);
            content &= chr(10);
            content &= chr(9) & chr(9) & "assert(isDefined(""local.result""), ""Function should return a value"");" & chr(10);
            content &= chr(9) & "}" & chr(10) & chr(10);
        }
        
        content &= "}";
        
        return content;
    }
    
    /**
     * Convert method name to human readable format
     */
    private string function humanize(required string text) {
        var result = reReplace(text, "([A-Z])", " \1", "all");
        result = trim(result);
        result = uCase(left(result, 1)) & mid(result, 2, len(result));
        return result;
    }
}