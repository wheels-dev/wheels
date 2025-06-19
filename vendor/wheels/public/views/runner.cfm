<!--- Script Runner Bridge - Executes scripts in Wheels application context --->
<cfscript>
setting showDebugOutput="no";
setting requestTimeout="300";

// Initialize response
data = {
	"success": true,
	"output": "",
	"error": "",
	"detail": "",
	"wheelsVersion": application.wheels.version,
	"environment": application.wheels.environment,
	"executionTime": 0
};

try {
	var startTime = getTickCount();
	
	// Get script content from POST
	if (!structKeyExists(form, "scriptContent") || !len(form.scriptContent)) {
		throw(message="No script content provided");
	}
	
	var scriptContent = form.scriptContent;
	var params = {};
	var verbose = false;
	
	// Parse parameters
	if (structKeyExists(form, "params") && len(form.params)) {
		params = deserializeJSON(form.params);
	}
	
	if (structKeyExists(form, "verbose")) {
		verbose = form.verbose;
	}
	
	// Create execution context with Wheels helpers and passed parameters
	request.scriptParams = params;
	request.scriptVerbose = verbose;
	
	// Make Wheels components available
	request.model = function(name) {
		return application.wheels.models[arguments.name];
	};
	
	request.query = function(sql) {
		var q = new Query();
		q.setDatasource(application.wheels.dataSourceName);
		q.setSQL(arguments.sql);
		return q.execute().getResult();
	};
	
	// Execute the script
	savecontent variable="output" {
		// Create a temporary file to execute
		var tempFile = getTempDirectory() & "wheels_runner_" & createUUID() & ".cfm";
		fileWrite(tempFile, scriptContent);
		
		try {
			// Include and execute the script
			include tempFile;
		} finally {
			// Clean up temp file
			if (fileExists(tempFile)) {
				fileDelete(tempFile);
			}
		}
	}
	
	data.output = trim(output);
	data.executionTime = getTickCount() - startTime;
	
	// Add execution time if verbose
	if (verbose) {
		if (len(data.output)) {
			data.output &= chr(10) & chr(10);
		}
		data.output &= "Execution completed in #data.executionTime#ms";
	}
	
} catch (any e) {
	data.success = false;
	data.error = e.message;
	data.detail = e.detail;
	if (structKeyExists(e, "tagContext") && arrayLen(e.tagContext)) {
		data.line = e.tagContext[1].line;
		data.template = listLast(e.tagContext[1].template, "/\");
	}
}
</cfscript>
<cfcontent reset="true" type="application/json"><cfoutput>#serializeJSON(data)#</cfoutput>
<cfabort>