<cfsetting requestTimeOut="1800">
<cfscript>
    try {
        // Get the requested format
        local.format = structKeyExists(url, "format") ? url.format : "html";

        // Create TestBox configuration for app tests
        testBoxConfig = {
            directory: "tests",
            recurse: true,
            bundles: "",
            labels: "",
            excludes: "",
            reportpath: "/tests",
            runner: [],
            callbacks: {},
            modules: {
                // Disable module loading to avoid BINDER errors
                autoLoad: false
            },
            coverage: {
                enabled: false
            }
        };

        // Create TestBox instance
        testBox = createObject("component", "testbox.system.TestBox");
        testBox.init(argumentCollection=testBoxConfig);

        // Sort bundles alphabetically
        local.sortedArray = testBox.getBundles();
        arraySort(local.sortedArray, "textNoCase");
        testBox.setBundles(local.sortedArray);

        // Run tests based on format
        switch(local.format) {
            case "json":
                result = testBox.run(reporter="testbox.system.reports.JSONReporter");
                cfheader(name="Access-Control-Allow-Origin", value="*");

                // Parse result to set proper status code
                DeJsonResult = DeserializeJSON(result);
                if (DeJsonResult.totalFail > 0 || DeJsonResult.totalError > 0) {
                    cfheader(statustext="Expectation Failed", statuscode=417);
                } else {
                    cfheader(statustext="OK", statuscode=200);
                }

                writeOutput(result);
                break;

            case "txt":
            case "text":
                result = testBox.run(reporter="testbox.system.reports.TextReporter");
                writeOutput(result);
                break;

            case "junit":
            case "xml":
                result = testBox.run(reporter="testbox.system.reports.ANTJUnitReporter");
                writeOutput(result);
                break;

            case "simple":
                result = testBox.run(reporter="testbox.system.reports.SimpleReporter");
                writeOutput(result);
                break;

            default: // html
                // For HTML, get JSON results and format them
                result = testBox.run(reporter="testbox.system.reports.JSONReporter");

                // Use the HTML formatter
                type = "App";
                include "/wheels/core_tests/html.cfm";
        }

    } catch (any e) {
        // Handle errors based on format
        if (structKeyExists(url, "format")) {
            switch(url.format) {
                case "json":
                    writeOutput(serializeJSON({
                        success: false,
                        error: e.message,
                        detail: e.detail,
                        type: e.type
                    }));
                    break;

                case "txt":
                case "text":
                    writeOutput("ERROR RUNNING APPLICATION TESTS" & chr(10));
                    writeOutput("================================" & chr(10));
                    writeOutput("Message: " & e.message & chr(10));
                    writeOutput("Detail: " & e.detail & chr(10));
                    if (structKeyExists(e, "stackTrace")) {
                        writeOutput("Stack Trace:" & chr(10));
                        writeOutput(e.stackTrace);
                    }
                    break;

                default:
                    writeOutput("<h1>Error Running Application Tests</h1>");
                    writeOutput("<p><strong>Message:</strong> #e.message#</p>");
                    writeOutput("<p><strong>Detail:</strong> #e.detail#</p>");
                    if (structKeyExists(e, "stackTrace")) {
                        writeOutput("<h2>Stack Trace:</h2>");
                        writeOutput("<pre>#e.stackTrace#</pre>");
                    }
            }
        } else {
            // Default HTML error output
            writeOutput("<h1>Error Running Application Tests</h1>");
            writeOutput("<p><strong>Message:</strong> #e.message#</p>");
            writeOutput("<p><strong>Detail:</strong> #e.detail#</p>");
            if (structKeyExists(e, "stackTrace")) {
                writeOutput("<h2>Stack Trace:</h2>");
                writeOutput("<pre>#e.stackTrace#</pre>");
            }
        }
    }
</cfscript>
