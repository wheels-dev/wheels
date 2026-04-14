<cfsetting requestTimeOut="300">
<cfscript>
try {
	testBox = new wheels.wheelstest.system.TestBox(
		directory = "cli.lucli.tests.specs",
		options = { coverage = { enabled = false } }
	);

	local.sortedArray = testBox.getBundles();
	arraySort(local.sortedArray, "textNoCase");
	testBox.setBundles(local.sortedArray);

	if (!structKeyExists(url, "format") || url.format == "html") {
		result = testBox.run(
			reporter = "wheels.wheelstest.system.reports.SimpleReporter"
		);
	} else if (url.format == "json") {
		result = testBox.run(
			reporter = "wheels.wheelstest.system.reports.JSONReporter"
		);
		cfcontent(type = "application/json");
		local.parsed = deserializeJSON(result);
		if (local.parsed.totalFail > 0 || local.parsed.totalError > 0) {
			cfheader(statuscode = 417);
		} else {
			cfheader(statuscode = 200);
		}
	}

	writeOutput(result);
} catch (any e) {
	cfheader(statuscode = 500);
	cfcontent(type = "application/json");
	writeOutput('{"success":false,"error":"' & replace(e.message, '"', '\"', 'all') & '"}');
}
</cfscript>
