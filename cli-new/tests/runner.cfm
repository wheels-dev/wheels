<cfscript>
// TestBox Runner for Wheels CLI
testbox = new testbox.system.TestBox();

// Run the tests
results = testbox.run(
    directory = {
        mapping = "tests.specs",
        recurse = true
    }
);

// Output results based on URL parameters
if (url.keyExists("reporter")) {
    writeOutput(results.print(reporter = url.reporter));
} else {
    writeOutput(results.print(reporter = "simple"));
}
</cfscript>