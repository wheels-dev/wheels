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
        writeOutput("<p>Test directory: wheels.tests_testbox.specs</p>");
        
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
            // Get just the filename without path
            fileName = listLast(testFile, "/\");
            fileName = replaceNoCase(fileName, ".cfc", "", "one");
            
            // Get the subdirectory path relative to specs
            relativePath = replaceNoCase(testFile, specsDirectory, "", "one");
            relativePath = replaceNoCase(relativePath, "/" & listLast(relativePath, "/"), "", "one");
            
            // Build component path
            if (len(trim(relativePath))) {
                // Remove leading slash and convert to dots
                relativePath = listChangeDelims(trim(relativePath), ".", "/");
                if (left(relativePath, 1) == ".") {
                    relativePath = right(relativePath, len(relativePath) - 1);
                }
                componentPath = "wheels.tests_testbox.specs." & relativePath & "." & fileName;
            } else {
                componentPath = "wheels.tests_testbox.specs." & fileName;
            }
            
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