/**
 * Generate a mailer component for sending emails
 * 
 * Examples:
 * wheels generate mailer Welcome
 * wheels generate mailer UserNotifications --methods="accountCreated,passwordReset,orderConfirmation"
 * wheels generate mailer OrderMailer --from="orders@example.com" --layout="email"
 */
component aliases='wheels g mailer' extends="../base" {
    
    property name="codeGenerationService" inject="CodeGenerationService@wheels-cli";
    property name="helpers" inject="helpers@wheels-cli";
    property name="detailOutput" inject="DetailOutputService@wheels-cli";
    
    /**
     * @name.hint Name of the mailer (e.g., WelcomeMailer, UserNotificationMailer)
     * @methods.hint Comma-separated list of email methods to generate
     * @from.hint Default from email address
     * @layout.hint Default layout template to use
     * @createViews.hint Create view templates for each method (default: true)
     * @force.hint Overwrite existing files
     */
    function run(
        required string name,
        string methods = "sendEmail",
        string from = "",
        string layout = "",
        boolean createViews = true,
        boolean force = false
    ) {
        detailOutput.header("📧", "Generating mailer: #arguments.name#");
        
        // Ensure name ends with "Mailer"
        if (!reFindNoCase("Mailer$", arguments.name)) {
            arguments.name &= "Mailer";
        }
        
        // Validate mailer name
        var validation = codeGenerationService.validateName(arguments.name, "mailer");
        if (!validation.valid) {
            error("Invalid mailer name: " & arrayToList(validation.errors, ", "));
            return;
        }
        
        // Set up paths
        var mailersDir = helpers.getAppPath() & "/mailers";
        if (!directoryExists(mailersDir)) {
            directoryCreate(mailersDir);
            detailOutput.output("Created mailers directory: /mailers");
        }
        
        var mailerPath = mailersDir & "/" & arguments.name & ".cfc";
        
        // Check if file exists
        if (fileExists(mailerPath) && !arguments.force) {
            error("Mailer already exists: #arguments.name#.cfc. Use force=true to overwrite.");
            return;
        }
        
        // Parse methods
        var methodList = listToArray(arguments.methods, ",");
        
        // Generate mailer content
        var mailerContent = generateMailerContent(arguments, methodList);
        
        // Write mailer file
        fileWrite(mailerPath, mailerContent);
        detailOutput.success("Created mailer: /mailers/#arguments.name#.cfc");
        
        // Create view templates if requested
        if (arguments.createViews) {
            createMailerViews(arguments.name, methodList);
        }
        
        // Create test file
        createMailerTest(arguments.name, methodList);
        
        // Show usage example
        detailOutput.separator();
        detailOutput.output("Usage example:");
        detailOutput.code('// In your controller or model
mailer = createObject("component", "mailers.#arguments.name#");
mailer.#methodList[1]#(to="user@example.com", subject="Welcome!");', "cfscript");
    }
    
    /**
     * Generate mailer component content
     */
    private string function generateMailerContent(required struct args, required array methods) {
        var content = "/**" & chr(10);
        content &= " * #args.name# - Handles email notifications" & chr(10);
        content &= " */" & chr(10);
        content &= "component extends=""wheels.Mailer"" {" & chr(10) & chr(10);
        
        // Constructor
        content &= chr(9) & "/**" & chr(10);
        content &= chr(9) & " * Constructor - Configure default settings" & chr(10);
        content &= chr(9) & " */" & chr(10);
        content &= chr(9) & "function config() {" & chr(10);
        
        if (len(args.from)) {
            content &= chr(9) & chr(9) & 'defaultFrom = "#args.from#";' & chr(10);
        }
        
        if (len(args.layout)) {
            content &= chr(9) & chr(9) & 'defaultLayout = "#args.layout#";' & chr(10);
        }
        
        content &= chr(9) & "}" & chr(10) & chr(10);
        
        // Generate methods
        for (var method in methods) {
            content &= generateMailerMethod(trim(method), args.name);
        }
        
        content &= "}";
        
        return content;
    }
    
    /**
     * Generate individual mailer method
     */
    private string function generateMailerMethod(required string methodName, required string mailerName) {
        var content = chr(9) & "/**" & chr(10);
        content &= chr(9) & " * Send #humanize(methodName)# email" & chr(10);
        content &= chr(9) & " * @to.hint Recipient email address" & chr(10);
        content &= chr(9) & " * @subject.hint Email subject line" & chr(10);
        content &= chr(9) & " * @data.hint Additional data to pass to the view" & chr(10);
        content &= chr(9) & " */" & chr(10);
        content &= chr(9) & "function #methodName#(" & chr(10);
        content &= chr(9) & chr(9) & "required string to," & chr(10);
        content &= chr(9) & chr(9) & "string subject = ""#humanize(methodName)#""," & chr(10);
        content &= chr(9) & chr(9) & "struct data = {}" & chr(10);
        content &= chr(9) & ") {" & chr(10);
        
        // Method body
        content &= chr(9) & chr(9) & "// Prepare email data" & chr(10);
        content &= chr(9) & chr(9) & "local.emailData = duplicate(arguments.data);" & chr(10);
        content &= chr(9) & chr(9) & "local.emailData.to = arguments.to;" & chr(10);
        content &= chr(9) & chr(9) & "local.emailData.subject = arguments.subject;" & chr(10) & chr(10);
        
        content &= chr(9) & chr(9) & "// Set email properties" & chr(10);
        content &= chr(9) & chr(9) & "to(arguments.to);" & chr(10);
        content &= chr(9) & chr(9) & "subject(arguments.subject);" & chr(10);
        
        if (len(variables.from ?: "")) {
            content &= chr(9) & chr(9) & "from(defaultFrom);" & chr(10);
        }
        
        content &= chr(10);
        content &= chr(9) & chr(9) & "// Render email template" & chr(10);
        content &= chr(9) & chr(9) & "template(""/#lCase(mailerName)#/#methodName#"");" & chr(10);
        
        content &= chr(10);
        content &= chr(9) & chr(9) & "// Send the email" & chr(10);
        content &= chr(9) & chr(9) & "return deliver();" & chr(10);
        content &= chr(9) & "}" & chr(10) & chr(10);
        
        return content;
    }
    
    /**
     * Create view templates for mailer methods
     */
    private void function createMailerViews(required string mailerName, required array methods) {
        var viewsDir = helpers.getAppPath() & "/views/" & lCase(mailerName);
        
        if (!directoryExists(viewsDir)) {
            directoryCreate(viewsDir);
            detailOutput.output("Created views directory: /views/#lCase(mailerName)#");
        }
        
        for (var method in methods) {
            var viewPath = viewsDir & "/" & trim(method) & ".cfm";
            
            if (!fileExists(viewPath)) {
                var viewContent = generateMailerView(trim(method), mailerName);
                fileWrite(viewPath, viewContent);
                detailOutput.output("Created view: /views/#lCase(mailerName)#/#trim(method)#.cfm");
            }
        }
    }
    
    /**
     * Generate mailer view template
     */
    private string function generateMailerView(required string methodName, required string mailerName) {
        var content = "<!--- Email template for #humanize(methodName)# --->" & chr(10);
        content &= "<cfoutput>" & chr(10);
        content &= chr(10);
        content &= "<h2>#humanize(methodName)#</h2>" & chr(10);
        content &= chr(10);
        content &= "<p>Hello,</p>" & chr(10);
        content &= chr(10);
        content &= "<p>" & chr(10);
        content &= chr(9) & "This is the email template for the #methodName# action." & chr(10);
        content &= chr(9) & "Customize this template with your email content." & chr(10);
        content &= "</p>" & chr(10);
        content &= chr(10);
        content &= "<!--- Access passed data --->" & chr(10);
        content &= '<cfif structKeyExists(variables, "data")>' & chr(10);
        content &= chr(9) & "<!--- Use data passed from the mailer method --->" & chr(10);
        content &= "</cfif>" & chr(10);
        content &= chr(10);
        content &= "<p>Best regards,<br>Your Team</p>" & chr(10);
        content &= chr(10);
        content &= "</cfoutput>";
        
        return content;
    }
    
    /**
     * Create test file for mailer
     */
    private void function createMailerTest(required string mailerName, required array methods) {
        var testsDir = helpers.getTestPath() & "/specs/mailers";

        if (!directoryExists(testsDir)) {
            directoryCreate(testsDir, true);
        }

        var testPath = testsDir & "/" & mailerName & "Spec.cfc";

        if (!fileExists(testPath)) {
            var testContent = generateMailerTest(mailerName, methods);
            fileWrite(testPath, testContent);
            detailOutput.output("Created test: /tests/specs/mailers/#mailerName#Spec.cfc");
        }
    }
    
    /**
     * Generate mailer test content
     */
    private string function generateMailerTest(required string mailerName, required array methods) {
        var content = "component extends=""wheels.Test"" {" & chr(10) & chr(10);
        
        content &= chr(9) & "function setup() {" & chr(10);
        content &= chr(9) & chr(9) & "mailer = createObject(""component"", ""mailers.#mailerName#"");" & chr(10);
        content &= chr(9) & "}" & chr(10) & chr(10);
        
        for (var method in methods) {
            content &= chr(9) & "function test_#trim(method)#() {" & chr(10);
            content &= chr(9) & chr(9) & "// Test that #trim(method)# sends email correctly" & chr(10);
            content &= chr(9) & chr(9) & "local.result = mailer.#trim(method)#(" & chr(10);
            content &= chr(9) & chr(9) & chr(9) & "to = ""test@example.com""," & chr(10);
            content &= chr(9) & chr(9) & chr(9) & "subject = ""Test Subject""" & chr(10);
            content &= chr(9) & chr(9) & ");" & chr(10);
            content &= chr(10);
            content &= chr(9) & chr(9) & "assert(""Email should be sent successfully"");" & chr(10);
            content &= chr(9) & "}" & chr(10) & chr(10);
        }
        
        content &= "}";
        
        return content;
    }
    
    /**
     * Convert method name to human readable format
     */
    private string function humanize(required string text) {
        // Convert camelCase to Title Case
        var result = reReplace(text, "([A-Z])", " \1", "all");
        result = trim(result);
        result = uCase(left(result, 1)) & mid(result, 2, len(result));
        return result;
    }
}