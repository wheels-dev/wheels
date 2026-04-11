<cfsetting requestTimeOut="300">
<cfscript>
setting showDebugOutput="no";
try {
	testBox = new wheels.wheelstest.system.TestBox(
		directory = "cli.lucli.tests.specs",
		options = { coverage = { enabled = false } }
	);

	local.sortedArray = testBox.getBundles();
	arraySort(local.sortedArray, "textNoCase");
	testBox.setBundles(local.sortedArray);

	param name="request.wheels.params.format" default="json";

	if (request.wheels.params.format == "json") {
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
	} else {
		result = testBox.run(
			reporter = "wheels.wheelstest.system.reports.SimpleReporter"
		);
	}

	writeOutput(result);
} catch (any e) {
	cfheader(statuscode = 500);
	cfcontent(type = "application/json");
	writeOutput('{"success":false,"error":"' & replace(e.message, '"', '\"', 'all') & '"}');
}
</cfscript>
