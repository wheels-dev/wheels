<!--- TestBox Test Runner for Wheels CLI --->
<cfscript>
    // Get TestBox instance
    testbox = new testbox.system.TestBox();
    
    // Configure test specs
    param name="url.directory" default="tests.specs";
    param name="url.recurse" default="true";
    param name="url.reporter" default="simple";
    
    // Run the tests
    results = testbox.run(
        directory = {
            mapping = url.directory,
            recurse = url.recurse
        },
        reporter = url.reporter
    );
    
    // Output results
    writeOutput(results);
</cfscript>