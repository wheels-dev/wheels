<cfsetting requestTimeOut="1800">
<cfscript>
    try {
        // Disable module loading to avoid BINDER errors
        // Create a simple TestBox instance without modules
        testBoxConfig = {
            directory: "wheels.tests_testbox.specs",
            recurse: true,
            bundles: "",
            labels: "",
            excludes: "",
            reportpath: "/wheels/tests_testbox",
            runner: [],
            callbacks: {},
            modules: {
                // Disable module loading
                autoLoad: false
            },
            coverage: {
                enabled: false
            }
        };
        
        // Create TestBox instance with minimal configuration
        testBox = createObject("component", "testbox.system.TestBox");
        testBox.init(argumentCollection=testBoxConfig);
        
        // Sort bundles alphabetically
        local.sortedArray = testBox.getBundles();
        arraySort(local.sortedArray, "textNoCase");
        testBox.setBundles(local.sortedArray);
        
        // Run tests
        if (!structKeyExists(url, "reporter")) {
            url.reporter = "wheels.tests_testbox.Reporter";
        }
        
        results = testBox.run(reporter=url.reporter);
        
        // Output based on reporter type
        if (findNoCase("json", url.reporter)) {
            cfcontent(type="application/json");
            writeOutput(results);
        } else {
            // For HTML reporter, include the navigation
            include "_navigation.cfm";
            writeOutput(results);
        }
        
    } catch (any e) {
        cfheader(statuscode="500", statustext="Internal Server Error");
        cfcontent(type="text/html");
        writeOutput("<h1>Error Running Tests</h1>");
        writeOutput("<p><strong>Message:</strong> #e.message#</p>");
        writeOutput("<p><strong>Detail:</strong> #e.detail#</p>");
        if (structKeyExists(e, "stackTrace")) {
            writeOutput("<h2>Stack Trace:</h2>");
            writeOutput("<pre>#e.stackTrace#</pre>");
        }
    }
</cfscript>