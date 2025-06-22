<cfsilent>
	<cfscript>
	if (testResults.numErrors || testResults.numFailures) {
		cfheader(statustext="Expectation Failed", statuscode=417);
	} else {
		cfheader(statustext="OK", statuscode=200);
	}
	cfsetting(showdebugoutput=false);
	request.wheels.showDebugInformation = false;
	cfcontent(type="text/plain");
	width = 128;
	hr = Chr(13) & RepeatString("=", width) & Chr(13);
	heading = "TEST RESULTS";
	padding = Ceiling(((width - 2) - Len(heading)) / 2);
	content = [
		RepeatString("*", width),
		'*#RepeatString(" ", padding)##heading##RepeatString(" ", padding)#*',
		RepeatString("*", width),
		'',
		'Tests: #testResults.numTests#',
		'OK: #testResults.ok#',
		'Success: #testResults.numTests - testResults.numFailures - testResults.numErrors#',
		'Failures: #testResults.numFailures#',
		'Errors: #testResults.numErrors#',
		'Time: #DateDiff("s", testResults.begin, testResults.end)# seconds'
	];
	for (local.i = 1; local.i <= ArrayLen(testResults.results); local.i++) {
		ArrayAppend(content, hr);
		ArrayAppend(content, "** #testResults.results[local.i].packageName# **");
		ArrayAppend(content, "#testResults.results[local.i].testName# (#testResults.results[local.i].time#ms)");
		ArrayAppend(content, "Status: #testResults.results[local.i].status#");
		if (testResults.results[local.i].status != "Success") {
			// TODO: fix this hacky html removal
			message = testResults.results[local.i].message;
			message = Replace(message, '><', '>#Chr(13)#<', 'all');
			message = ReplaceList(message, "<ul>,</ul>,<li>,</li>", ",,,");
			ArrayAppend(content, message);
		}
		if (StructKeyExists(testResults.results[local.i], "debugString")) {
			ArrayAppend(content, testResults.results[local.i].debugString);
		}
	}
	</cfscript>
</cfsilent><cfcontent reset="true"><cfoutput>#ArrayToList(content, Chr(13))#</cfoutput>
