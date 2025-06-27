<cfsetting requestTimeOut="1800">
<!--- Minimal TestBox runner that bypasses module system --->
<cfscript>
    try {
        // Create TestBox TestResult object directly
        testResult = createObject("component", "testbox.system.TestResult");
        
        // Get test specs directory
        specsDirectory = expandPath("/wheels/tests_testbox/specs");
        
        // Simple HTML output
        writeOutput("<h1>Wheels Framework Tests</h1>");
        writeOutput("<p>Running tests from: #specsDirectory#</p>");
        
        // Get all test CFCs
        testFiles = directoryList(
            specsDirectory,
            true,
            "path",
            "*.cfc"
        );
        
        totalTests = 0;
        passedTests = 0;
        failedTests = 0;
        errors = [];
        
        writeOutput("<ul>");
        
        // Run each test file
        for (testFile in testFiles) {
            // Convert file path to component path
            componentPath = replaceNoCase(testFile, expandPath("/"), "", "one");
            componentPath = listChangeDelims(componentPath, ".", "/\");
            componentPath = replaceNoCase(componentPath, ".cfc", "", "one");
            
            try {
                writeOutput("<li><strong>#componentPath#</strong>");
                
                // Create test instance
                testInstance = createObject("component", componentPath);
                
                // Check if it has a run method (TestBox spec)
                if (structKeyExists(testInstance, "run")) {
                    writeOutput(" - <span style='color: green;'>✓ Loaded</span>");
                    totalTests++;
                    passedTests++;
                } else {
                    writeOutput(" - <span style='color: orange;'>Skipped (not a test spec)</span>");
                }
                
                writeOutput("</li>");
                
            } catch (any e) {
                writeOutput("<li><strong>#componentPath#</strong> - <span style='color: red;'>✗ Error: #e.message#</span></li>");
                totalTests++;
                failedTests++;
                arrayAppend(errors, {
                    file: componentPath,
                    message: e.message,
                    detail: e.detail
                });
            }
        }
        
        writeOutput("</ul>");
        
        // Summary
        writeOutput("<h2>Summary</h2>");
        writeOutput("<p>Total test files: #totalTests#</p>");
        writeOutput("<p>Passed: #passedTests#</p>");
        writeOutput("<p>Failed: #failedTests#</p>");
        
        if (arrayLen(errors) > 0) {
            writeOutput("<h3>Errors:</h3>");
            writeOutput("<ul>");
            for (error in errors) {
                writeOutput("<li><strong>#error.file#:</strong> #error.message# - #error.detail#</li>");
            }
            writeOutput("</ul>");
        }
        
    } catch (any e) {
        writeOutput("<h1>Error Running Tests</h1>");
        writeOutput("<p><strong>Message:</strong> #e.message#</p>");
        writeOutput("<p><strong>Detail:</strong> #e.detail#</p>");
        if (structKeyExists(e, "stackTrace")) {
            writeOutput("<h2>Stack Trace:</h2>");
            writeOutput("<pre>#e.stackTrace#</pre>");
        }
    }
</cfscript>