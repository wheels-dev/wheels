/**
 * Generate a service object for business logic
 * 
 * Examples:
 * wheels generate service Payment
 * wheels generate service UserAuthentication --methods="login,logout,register,verify"
 * wheels generate service OrderProcessing --dependencies="PaymentService,EmailService"
 * wheels generate service DataExport --type=singleton
 */
component aliases='wheels g service' extends="../base" {
    
    property name="codeGenerationService" inject="CodeGenerationService@wheels-cli";
    property name="helpers" inject="helpers@wheels-cli";
    property name="detailOutput" inject="DetailOutputService@wheels-cli";
    
    /**
     * @name.hint Name of the service (e.g., PaymentService, UserService)
     * @methods.hint Comma-separated list of methods to generate
     * @dependencies.hint Comma-separated list of service dependencies
     * @type.hint Service type: transient or singleton (default: transient)
     * @description.hint Service description
     * @force.hint Overwrite existing files
     */
    function run(
        required string name,
        string methods = "",
        string dependencies = "",
        string type = "transient",
        string description = "",
        boolean force = false
    ) {
        detailOutput.header("⚙️", "Generating service: #arguments.name#");
        
        // Ensure name ends with "Service"
        if (!reFindNoCase("Service$", arguments.name)) {
            arguments.name &= "Service";
        }
        
        // Validate service name
        var validation = codeGenerationService.validateName(arguments.name, "service");
        if (!validation.valid) {
            error("Invalid service name: " & arrayToList(validation.errors, ", "));
            return;
        }
        
        // Validate type
        if (!listFindNoCase("transient,singleton", arguments.type)) {
            error("Invalid service type. Must be 'transient' or 'singleton'.");
            return;
        }
        
        // Set up paths
        var servicesDir = helpers.getAppPath() & "/services";
        if (!directoryExists(servicesDir)) {
            directoryCreate(servicesDir);
            detailOutput.output("Created services directory: /services");
        }
        
        var servicePath = servicesDir & "/" & arguments.name & ".cfc";
        
        // Check if file exists
        if (fileExists(servicePath) && !arguments.force) {
            error("Service already exists: #arguments.name#.cfc. Use force=true to overwrite.");
            return;
        }
        
        // Parse methods and dependencies
        var methodList = len(arguments.methods) ? listToArray(arguments.methods, ",") : [];
        var dependencyList = len(arguments.dependencies) ? listToArray(arguments.dependencies, ",") : [];
        
        // Generate service content
        var serviceContent = generateServiceContent(arguments, methodList, dependencyList);
        
        // Write service file
        fileWrite(servicePath, serviceContent);
        detailOutput.success("Created service: /services/#arguments.name#.cfc");
        
        // Create test file
        createServiceTest(arguments.name, methodList);
        
        // Show usage example
        detailOutput.separator();
        detailOutput.output("Usage example:");
        
        if (arguments.type == "singleton") {
            detailOutput.code('// In Application.cfc onApplicationStart()
application.#lCase(arguments.name)# = createObject("component", "services.#arguments.name#").init();

// Usage anywhere in the application
result = application.#lCase(arguments.name)#.someMethod();', "cfscript");
        } else {
            detailOutput.code('// In your controller or model
service = createObject("component", "services.#arguments.name#").init();
result = service.someMethod();

// Or with dependency injection
property name="#lCase(left(arguments.name, len(arguments.name)-7))#Service" inject="services.#arguments.name#";', "cfscript");
        }
    }
    
    /**
     * Generate service component content
     */
    private string function generateServiceContent(required struct args, required array methods, required array dependencies) {
        var content = "/**" & chr(10);
        content &= " * #args.name#" & chr(10);
        if (len(args.description)) {
            content &= " * #args.description#" & chr(10);
        }
        content &= " * Type: #args.type#" & chr(10);
        content &= " */" & chr(10);
        content &= "component";
        
        if (args.type == "singleton") {
            content &= " singleton";
        }
        
        content &= " {" & chr(10) & chr(10);
        
        // Properties for dependencies
        if (arrayLen(dependencies)) {
            content &= chr(9) & "// Service dependencies" & chr(10);
            for (var dep in dependencies) {
                var depName = trim(dep);
                if (!reFindNoCase("Service$", depName)) {
                    depName &= "Service";
                }
                content &= chr(9) & "property name=""#lCase(left(depName, 1)) & mid(depName, 2, len(depName))#"" type=""services.#depName#"";" & chr(10);
            }
            content &= chr(10);
        }
        
        // Constructor
        content &= chr(9) & "/**" & chr(10);
        content &= chr(9) & " * Constructor" & chr(10);
        if (arrayLen(dependencies)) {
            for (var dep in dependencies) {
                var depName = trim(dep);
                if (!reFindNoCase("Service$", depName)) {
                    depName &= "Service";
                }
                var paramName = lCase(left(depName, 1)) & mid(depName, 2, len(depName));
                content &= chr(9) & " * @#paramName#.hint #depName# instance" & chr(10);
            }
        }
        content &= chr(9) & " */" & chr(10);
        content &= chr(9) & "function init(";
        
        if (arrayLen(dependencies)) {
            var depParams = [];
            for (var dep in dependencies) {
                var depName = trim(dep);
                if (!reFindNoCase("Service$", depName)) {
                    depName &= "Service";
                }
                var paramName = lCase(left(depName, 1)) & mid(depName, 2, len(depName));
                arrayAppend(depParams, chr(10) & chr(9) & chr(9) & "services.#depName# #paramName#");
            }
            content &= arrayToList(depParams, ",");
            content &= chr(10) & chr(9);
        }
        
        content &= ") {" & chr(10);
        
        // Set dependencies
        if (arrayLen(dependencies)) {
            for (var dep in dependencies) {
                var depName = trim(dep);
                if (!reFindNoCase("Service$", depName)) {
                    depName &= "Service";
                }
                var paramName = lCase(left(depName, 1)) & mid(depName, 2, len(depName));
                content &= chr(9) & chr(9) & "variables.#paramName# = arguments.#paramName#;" & chr(10);
            }
            content &= chr(10);
        }
        
        content &= chr(9) & chr(9) & "return this;" & chr(10);
        content &= chr(9) & "}" & chr(10) & chr(10);
        
        // Generate methods
        if (arrayLen(methods)) {
            for (var method in methods) {
                content &= generateServiceMethod(trim(method));
            }
        } else {
            // Generate a sample method
            content &= generateServiceMethod("process");
        }
        
        // Private helper methods section
        content &= chr(9) & "// ========================================" & chr(10);
        content &= chr(9) & "// Private Methods" & chr(10);
        content &= chr(9) & "// ========================================" & chr(10) & chr(10);
        
        content &= chr(9) & "/**" & chr(10);
        content &= chr(9) & " * Private helper method example" & chr(10);
        content &= chr(9) & " */" & chr(10);
        content &= chr(9) & "private any function validateInput(required any input) {" & chr(10);
        content &= chr(9) & chr(9) & "// Add validation logic here" & chr(10);
        content &= chr(9) & chr(9) & "return true;" & chr(10);
        content &= chr(9) & "}" & chr(10);
        
        content &= "}";
        
        return content;
    }
    
    /**
     * Generate individual service method
     */
    private string function generateServiceMethod(required string methodName) {
        var content = chr(9) & "/**" & chr(10);
        content &= chr(9) & " * #humanize(methodName)#" & chr(10);
        content &= chr(9) & " * @data.hint Input data for processing" & chr(10);
        content &= chr(9) & " * @options.hint Additional options" & chr(10);
        content &= chr(9) & " * @return Result of the operation" & chr(10);
        content &= chr(9) & " */" & chr(10);
        content &= chr(9) & "public any function #methodName#(" & chr(10);
        content &= chr(9) & chr(9) & "required any data," & chr(10);
        content &= chr(9) & chr(9) & "struct options = {}" & chr(10);
        content &= chr(9) & ") {" & chr(10);
        
        content &= chr(9) & chr(9) & "try {" & chr(10);
        content &= chr(9) & chr(9) & chr(9) & "// Validate input" & chr(10);
        content &= chr(9) & chr(9) & chr(9) & "if (!validateInput(arguments.data)) {" & chr(10);
        content &= chr(9) & chr(9) & chr(9) & chr(9) & "throw(type=""ValidationException"", message=""Invalid input data"");" & chr(10);
        content &= chr(9) & chr(9) & chr(9) & "}" & chr(10);
        content &= chr(10);
        content &= chr(9) & chr(9) & chr(9) & "// Process the data" & chr(10);
        content &= chr(9) & chr(9) & chr(9) & "local.result = {" & chr(10);
        content &= chr(9) & chr(9) & chr(9) & chr(9) & "success = true," & chr(10);
        content &= chr(9) & chr(9) & chr(9) & chr(9) & "data = arguments.data," & chr(10);
        content &= chr(9) & chr(9) & chr(9) & chr(9) & "message = ""#humanize(methodName)# completed successfully""" & chr(10);
        content &= chr(9) & chr(9) & chr(9) & "};" & chr(10);
        content &= chr(10);
        content &= chr(9) & chr(9) & chr(9) & "// TODO: Implement actual business logic here" & chr(10);
        content &= chr(10);
        content &= chr(9) & chr(9) & chr(9) & "return local.result;" & chr(10);
        content &= chr(10);
        content &= chr(9) & chr(9) & "} catch (any e) {" & chr(10);
        content &= chr(9) & chr(9) & chr(9) & "// Handle errors" & chr(10);
        content &= chr(9) & chr(9) & chr(9) & "return {" & chr(10);
        content &= chr(9) & chr(9) & chr(9) & chr(9) & "success = false," & chr(10);
        content &= chr(9) & chr(9) & chr(9) & chr(9) & "error = e.message," & chr(10);
        content &= chr(9) & chr(9) & chr(9) & chr(9) & "detail = e.detail" & chr(10);
        content &= chr(9) & chr(9) & chr(9) & "};" & chr(10);
        content &= chr(9) & chr(9) & "}" & chr(10);
        content &= chr(9) & "}" & chr(10) & chr(10);
        
        return content;
    }
    
    /**
     * Create test file for service
     */
    private void function createServiceTest(required string serviceName, required array methods) {
        var testsDir = helpers.getTestPath() & "/services";
        
        if (!directoryExists(testsDir)) {
            directoryCreate(testsDir);
        }
        
        var testPath = testsDir & "/" & serviceName & "Test.cfc";
        
        if (!fileExists(testPath)) {
            var testContent = generateServiceTest(serviceName, methods);
            fileWrite(testPath, testContent);
            detailOutput.output("Created test: /tests/services/#serviceName#Test.cfc");
        }
    }
    
    /**
     * Generate service test content
     */
    private string function generateServiceTest(required string serviceName, required array methods) {
        var content = "component extends=""wheels.Test"" {" & chr(10) & chr(10);
        
        content &= chr(9) & "function setup() {" & chr(10);
        content &= chr(9) & chr(9) & "// Create service instance" & chr(10);
        content &= chr(9) & chr(9) & "service = createObject(""component"", ""services.#serviceName#"").init();" & chr(10);
        content &= chr(9) & "}" & chr(10) & chr(10);
        
        content &= chr(9) & "function test_service_initialization() {" & chr(10);
        content &= chr(9) & chr(9) & "assert(isObject(service), ""Service should be initialized"");" & chr(10);
        content &= chr(9) & chr(9) & "assert(isInstanceOf(service, ""services.#serviceName#""), ""Service should be correct type"");" & chr(10);
        content &= chr(9) & "}" & chr(10) & chr(10);
        
        var methodsToTest = arrayLen(methods) ? methods : ["process"];
        
        for (var method in methodsToTest) {
            content &= chr(9) & "function test_#trim(method)#() {" & chr(10);
            content &= chr(9) & chr(9) & "// Arrange" & chr(10);
            content &= chr(9) & chr(9) & "local.testData = {" & chr(10);
            content &= chr(9) & chr(9) & chr(9) & "// Add test data here" & chr(10);
            content &= chr(9) & chr(9) & "};" & chr(10);
            content &= chr(10);
            content &= chr(9) & chr(9) & "// Act" & chr(10);
            content &= chr(9) & chr(9) & "local.result = service.#trim(method)#(local.testData);" & chr(10);
            content &= chr(10);
            content &= chr(9) & chr(9) & "// Assert" & chr(10);
            content &= chr(9) & chr(9) & "assert(structKeyExists(local.result, ""success""), ""Result should have success flag"");" & chr(10);
            content &= chr(9) & chr(9) & "assert(local.result.success, ""Operation should succeed"");" & chr(10);
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