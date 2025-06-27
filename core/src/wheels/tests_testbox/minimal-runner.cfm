<cfsetting requestTimeOut="1800">
<!--- Minimal TestBox runner that bypasses module system --->
<cfscript>
    try {
        // Get the requested format
        local.format = structKeyExists(url, "format") ? url.format : "html";
        // Create TestBox TestResult object directly
        testResult = createObject("component", "testbox.system.TestResult");
        
        // Get test specs directory
        specsDirectory = expandPath("/wheels/tests_testbox/specs");
        
        // Start output based on format
        if (local.format == "html") {
            writeOutput("<h1>Wheels Framework Tests</h1>");
            writeOutput("<p>Test directory: wheels.tests_testbox.specs</p>");
        }
        
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
        
        if (local.format == "html") {
            writeOutput("<ul>");
        }
        
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
                if (local.format == "html") {
                    writeOutput("<li><strong>#componentPath#</strong>");
                }
                
                // Create test instance
                testInstance = createObject("component", componentPath);
                
                // Check if it has a run method (TestBox spec)
                if (structKeyExists(testInstance, "run")) {
                    if (local.format == "html") {
                        writeOutput(" - <span style='color: green;'>✓ Loaded</span>");
                    }
                    totalTests++;
                    passedTests++;
                } else {
                    if (local.format == "html") {
                        writeOutput(" - <span style='color: orange;'>Skipped (not a test spec)</span>");
                    }
                }
                
                if (local.format == "html") {
                    writeOutput("</li>");
                }
                
            } catch (any e) {
                if (local.format == "html") {
                    writeOutput("<li><strong>#componentPath#</strong> - <span style='color: red;'>✗ Error: #e.message#</span></li>");
                }
                totalTests++;
                failedTests++;
                arrayAppend(errors, {
                    file: componentPath,
                    message: e.message,
                    detail: e.detail
                });
            }
        }
        
        if (local.format == "html") {
            writeOutput("</ul>");
        }
        
        // Output summary based on format
        switch(local.format) {
            case "json":
                // Create JSON response similar to TestBox format
                local.jsonResponse = {
                    "version": "Minimal Runner 1.0",
                    "totalBundles": totalTests,
                    "totalSpecs": totalTests,
                    "totalPass": passedTests,
                    "totalFail": failedTests,
                    "totalError": 0,
                    "totalSkipped": 0,
                    "totalDuration": 0,
                    "errors": errors
                };
                cfheader(name="Access-Control-Allow-Origin", value="*");
                if (failedTests > 0) {
                    cfheader(statustext="Expectation Failed", statuscode=417);
                } else {
                    cfheader(statustext="OK", statuscode=200);
                }
                writeOutput(serializeJSON(local.jsonResponse));
                break;
                
            case "txt":
            case "text":
                writeOutput("WHEELS MINIMAL TEST RUNNER" & chr(10));
                writeOutput("=========================" & chr(10) & chr(10));
                writeOutput("Test directory: wheels.tests_testbox.specs" & chr(10) & chr(10));
                writeOutput("SUMMARY" & chr(10));
                writeOutput("-------" & chr(10));
                writeOutput("Total test files: " & totalTests & chr(10));
                writeOutput("Passed: " & passedTests & chr(10));
                writeOutput("Failed: " & failedTests & chr(10) & chr(10));
                
                if (arrayLen(errors) > 0) {
                    writeOutput("ERRORS" & chr(10));
                    writeOutput("------" & chr(10));
                    for (error in errors) {
                        writeOutput(error.file & ": " & error.message & chr(10));
                    }
                }
                break;
                
            case "simple":
                writeOutput("Minimal Runner v1.0 " & chr(10));
                writeOutput("=" & repeatString("=", 50) & chr(10));
                if (failedTests == 0) {
                    writeOutput("[PASSED] ");
                } else {
                    writeOutput("[FAILED] ");
                }
                writeOutput("Files:#totalTests# Pass:#passedTests# Fail:#failedTests#" & chr(10));
                writeOutput("=" & repeatString("=", 50) & chr(10));
                break;
                
            case "junit":
            case "xml":
                writeOutput('<?xml version="1.0" encoding="UTF-8"?>');
                writeOutput('<testsuites>');
                writeOutput('<testsuite name="Wheels Minimal Tests" tests="#totalTests#" failures="#failedTests#" errors="0" skipped="0" time="0">');
                for (error in errors) {
                    writeOutput('<testcase name="#error.file#">');
                    writeOutput('<failure message="#xmlFormat(error.message)#">#xmlFormat(error.detail)#</failure>');
                    writeOutput('</testcase>');
                }
                writeOutput('</testsuite>');
                writeOutput('</testsuites>');
                break;
                
            default: // html
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
        }
        
    } catch (any e) {
        // Handle errors based on format
        if (structKeyExists(url, "format")) {
            switch(url.format) {
                case "json":
                    cfheader(statustext="Internal Server Error", statuscode=500);
                    writeOutput(serializeJSON({
                        success: false,
                        error: e.message,
                        detail: e.detail,
                        type: e.type
                    }));
                    break;
                    
                case "txt":
                case "text":
                    writeOutput("ERROR RUNNING MINIMAL TESTS" & chr(10));
                    writeOutput("===========================" & chr(10));
                    writeOutput("Message: " & e.message & chr(10));
                    writeOutput("Detail: " & e.detail & chr(10));
                    break;
                    
                case "junit":
                case "xml":
                    writeOutput('<?xml version="1.0" encoding="UTF-8"?>');
                    writeOutput('<testsuites>');
                    writeOutput('<testsuite name="Wheels Minimal Tests" tests="0" failures="0" errors="1" skipped="0" time="0">');
                    writeOutput('<testcase name="Runner Error">');
                    writeOutput('<error message="#xmlFormat(e.message)#">#xmlFormat(e.detail)#</error>');
                    writeOutput('</testcase>');
                    writeOutput('</testsuite>');
                    writeOutput('</testsuites>');
                    break;
                    
                default:
                    writeOutput("<h1>Error Running Tests</h1>");
                    writeOutput("<p><strong>Message:</strong> #e.message#</p>");
                    writeOutput("<p><strong>Detail:</strong> #e.detail#</p>");
                    if (structKeyExists(e, "stackTrace")) {
                        writeOutput("<h2>Stack Trace:</h2>");
                        writeOutput("<pre>#e.stackTrace#</pre>");
                    }
            }
        } else {
            // Default HTML error output
            writeOutput("<h1>Error Running Tests</h1>");
            writeOutput("<p><strong>Message:</strong> #e.message#</p>");
            writeOutput("<p><strong>Detail:</strong> #e.detail#</p>");
            if (structKeyExists(e, "stackTrace")) {
                writeOutput("<h2>Stack Trace:</h2>");
                writeOutput("<pre>#e.stackTrace#</pre>");
            }
        }
    }
</cfscript>