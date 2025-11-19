/**
 * Generate global helper functions for use throughout the application
 *
 * Examples:
 * wheels generate helper Format
 * wheels generate helper StringUtils --functions="truncate,highlight,slugify"
 * wheels generate helper DateHelpers --description="Date formatting helpers"
 */
component aliases='wheels g helper' extends="../base" {

    property name="codeGenerationService" inject="CodeGenerationService@wheels-cli";
    property name="helpers" inject="helpers@wheels-cli";
    property name="detailOutput" inject="DetailOutputService@wheels-cli";

    /**
     * @name.hint Name of the helper (e.g., FormatHelper, StringHelper)
     * @functions.hint Comma-separated list of functions to generate
     * @description.hint Helper description
     * @force.hint Overwrite existing files
     */
    function run(
        required string name,
        string functions = "helperFunction",
        string description = "",
        boolean force = false
    ) {
        arguments=reconstructArgs(arguments);
        detailOutput.header("", "Generating helper: #arguments.name#");

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

        // Set up helper directory
        var helperDir = helpers.getAppPath() & "/helpers";

        if (!directoryExists(helperDir)) {
            directoryCreate(helperDir);
            detailOutput.output("Created helpers directory: /app/helpers");
        }
        
        var helperPath = helperDir & "/" & arguments.name & ".cfm";
        
        // Check if file exists
        if (fileExists(helperPath) && !arguments.force) {
            error("Helper already exists: #arguments.name#.cfm. Use force=true to overwrite.");
            return;
        }
        
        // Parse functions
        var functionList = listToArray(arguments.functions, ",");

        // Validate function names don't already exist (unless we're forcing an overwrite)
        if (!arguments.force) {
            var existingFunctions = checkForExistingFunctions(helperDir, functionList, arguments.name);
            if (arrayLen(existingFunctions) > 0) {
                error("The following function(s) already exist in helper files: #arrayToList(existingFunctions, ', ')#");
                return;
            }
        }

        // Generate helper content
        var helperContent = generateHelperContent(arguments.name, functionList, arguments.description);

        // Write helper file
        fileWrite(helperPath, helperContent);
        detailOutput.success("Created helper: #replace(helperPath, helpers.getAppPath(), '')#");

        // Ensure helper is included in app/global/functions.cfm
        ensureHelperIncluded(arguments.name);

        // Create test file
        createHelperTest(arguments.name, functionList);

        // Show usage example
        detailOutput.separator();
        detailOutput.output("Usage example:");
        detailOutput.code('// Helper functions are automatically available globally
result = #functionList[1]#("some input");

// In views
<cfoutput>
    ##format#uCase(left(functionList[1], 1)) & mid(functionList[1], 2, len(functionList[1]))#(data)##
</cfoutput>', "cfscript");
    }
    
    /**
     * Check if any of the functions already exist in helper files
     */
    private array function checkForExistingFunctions(required string helperDir, required array functionList, required string currentHelperName) {
        var conflicts = [];

        // Get all helper files
        if (!directoryExists(arguments.helperDir)) {
            return conflicts;
        }

        var helperFiles = directoryList(arguments.helperDir, false, "path", "*.cfm");

        // Check each helper file for function definitions
        for (var helperFile in helperFiles) {
            var fileContent = fileRead(helperFile);
            var fileName = getFileFromPath(helperFile);

            // Skip the current helper file being generated (in case of updates)
            if (fileName == arguments.currentHelperName & ".cfm") {
                continue;
            }

            // Check each function we want to create
            for (var funcName in arguments.functionList) {
                var cleanFuncName = trim(funcName);

                // Search for function definitions with various patterns
                // Matches: function name(, public function name(, private function name(, etc.
                var pattern = "(public|private|package)?\s*function\s+#cleanFuncName#\s*\(";

                if (reFindNoCase(pattern, fileContent) > 0) {
                    arrayAppend(conflicts, "#cleanFuncName# (in #fileName#)");
                }
            }
        }

        return conflicts;
    }

    /**
     * Ensure helper is included in app/global/functions.cfm
     */
    private void function ensureHelperIncluded(required string helperName) {
        var functionsPath = helpers.getAppPath() & "/global/functions.cfm";
        var fileAlreadyExists = fileExists(functionsPath);

        if (!fileAlreadyExists) {
            createNewFunctionsFile(functionsPath, arguments.helperName);
            return;
        }

        // File exists, check if helper is already included
        var functionsContent = fileRead(functionsPath);
        var helperFileName = arguments.helperName & ".cfm";

        if (findNoCase(helperFileName, functionsContent) > 0) {
            detailOutput.output("Helper already included in functions.cfm");
            return;
        }

        // Add include to existing file
        addIncludeToFunctionsFile(functionsContent, functionsPath, arguments.helperName);
    }

    /**
     * Create new functions.cfm file
     */
    private void function createNewFunctionsFile(required string functionsPath, required string helperName) {
        var content = "";
        content &= "&lt;cfscript&gt;" & chr(10);
        content &= "//=====================================================================" & chr(10);
        content &= "//= " & chr(9) & "Global Functions" & chr(10);
        content &= "//=====================================================================" & chr(10);
        content &= 'include "../helpers/' & arguments.helperName & '.cfm";' & chr(10);
        content &= "&lt;/cfscript&gt;" & chr(10);
        fileWrite(arguments.functionsPath, content);
        detailOutput.success("Created: /app/global/functions.cfm");
    }


    /**
     * Add include statement to existing functions.cfm
     */
    private void function addIncludeToFunctionsFile(required string currentContent, required string functionsPath, required string helperName) {
        var includeStatement = 'include "../helpers/' & arguments.helperName & '.cfm";' & chr(10);
        var updatedContent = arguments.currentContent;

        // Use variables to avoid CFML tag interpretation
        var openingTag = chr(60) & "cfscript" & chr(62);
        var closingTag = chr(60) & "/cfscript" & chr(62);

        // Insert before closing cfscript tag
        if (findNoCase(closingTag, updatedContent) > 0) {
            updatedContent = reReplace(updatedContent, closingTag, includeStatement & closingTag, "one");
        } else if (findNoCase(openingTag, updatedContent) > 0) {
            // Has opening tag but no closing - add at end
            updatedContent &= includeStatement;
        } else {
            // No cfscript tags - wrap everything
            updatedContent = openingTag & chr(10) & updatedContent & includeStatement & closingTag & chr(10);
        }

        fileWrite(arguments.functionsPath, updatedContent);
        detailOutput.success("Added include to /app/global/functions.cfm");
    }

    /**
     * Generate helper component content
     */
    private string function generateHelperContent(required string helperName, required array functions, string description = "") {
        var content = '';
        content &= "/**" & chr(10);
        content &= " * #arguments.helperName#" & chr(10);
        if (len(trim(arguments.description))) {
            content &= " * #trim(arguments.description)#" & chr(10);
        }
        content &= " */" & chr(10);
        content &= "<cfscript>" & chr(10) & chr(10);

        // Generate functions
        for (var func in functions) {
            content &= generateHelperFunction(trim(func));
        }

        content &= "</cfscript>";
        return content;
    }

    /**
     * Generate individual helper function
     */
    private string function generateHelperFunction(required string functionName) {
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
    private void function createHelperTest(required string helperName, required array functions) {
        var testsDir = helpers.getTestPath() & "/specs/helpers";

        if (!directoryExists(testsDir)) {
            directoryCreate(testsDir, true);
        }

        var testPath = testsDir & "/" & helperName & "Spec.cfc";

        if (!fileExists(testPath)) {
            var testContent = generateHelperTest(helperName, functions);
            fileWrite(testPath, testContent);
            detailOutput.output("Created test: /tests/specs/helpers/#helperName#Spec.cfc");
        }
    }
    
    /**
     * Generate helper test content
     */
    private string function generateHelperTest(required string helperName, required array functions) {
        var content = "component extends=""wheels.Test"" {" & chr(10) & chr(10);

        content &= chr(9) & "function setup() {" & chr(10);
        content &= chr(9) & chr(9) & "// Global helpers are automatically included" & chr(10);
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