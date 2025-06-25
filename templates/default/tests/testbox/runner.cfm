<cfscript>
	// Simple test runner for application tests
	try {
		// Check if we have TestBox available
		if (!directoryExists(expandPath("/vendor/testbox"))) {
			writeOutput("TestBox not found. Please ensure TestBox is installed in /vendor/testbox");
			abort;
		}
		
		// Create TestBox instance
		testBox = new testbox.system.TestBox(
			directory = "/tests/specs",
			options = { coverage = { enabled = false } }
		);
		
		// Run the tests
		result = testBox.run(
			reporter = structKeyExists(url, "reporter") ? url.reporter : "simple"
		);
		
		// Output the results
		writeOutput(result);
		
	} catch (any e) {
		writeOutput("<h1>Error Running Tests</h1>");
		writeOutput("<p>#e.message#</p>");
		writeOutput("<p>#e.detail#</p>");
		if (structKeyExists(e, "tagContext") && arrayLen(e.tagContext)) {
			writeOutput("<h2>Stack Trace:</h2><ul>");
			for (var context in e.tagContext) {
				writeOutput("<li>#context.template#:#context.line#</li>");
			}
			writeOutput("</ul>");
		}
	}
</cfscript>