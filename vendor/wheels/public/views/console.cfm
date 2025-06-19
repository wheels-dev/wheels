<!--- Console REPL Bridge - Executes code in Wheels application context --->
<cfscript>
setting showDebugOutput="no";

// Check if this is a valid console request
if (!structKeyExists(request, "wheels") || !structKeyExists(request.wheels, "params")) {
	// Return empty response if not a proper request
	writeOutput('{"success":false,"error":"Invalid request"}');
	cfabort;
}

// Initialize response
data = {
	"success": true,
	"output": "",
	"error": "",
	"detail": "",
	"wheelsVersion": application.wheels.version,
	"environment": application.wheels.environment
};

try {
	// Get command type
	if (!structKeyExists(request.wheels.params, "command")) {
		data.command = "test";
	} else {
		data.command = request.wheels.params.command;
	}

	switch (data.command) {
		case "test":
			// Test connection
			data.output = "Wheels console connected successfully!";
			data.models = structKeyArray(application.wheels.models);
			data.datasource = application.wheels.dataSourceName;
			break;
			
		case "execute":
			// Execute code
			if (structKeyExists(request.wheels.params, "code") && len(request.wheels.params.code)) {
				local.code = request.wheels.params.code;
				local.isScript = structKeyExists(request.wheels.params, "script") && request.wheels.params.script;
				
				// Create execution context with Wheels helpers
				local.context = {
					// Model access
					model: function(name) {
						return application.wheels.models[arguments.name];
					},
					
					// Direct query access
					query: function(sql) {
						local.q = new Query();
						local.q.setDatasource(application.wheels.dataSourceName);
						local.q.setSQL(arguments.sql);
						return local.q.execute().getResult();
					},
					
					// Include all global helper functions
					$includeHelpers: function() {
						// Helper functions are already loaded in the application context
						// No need to include additional files
					}
				};
				
				// Make application scope available
				local.context.application = application;
				
				// Execute the code
				if (local.isScript) {
					// CFScript execution
					savecontent variable="output" {
						// Import context variables
						for (local.key in local.context) {
							if (local.key != '$includeHelpers') {
								variables[local.key] = local.context[local.key];
							}
						}
						
						// Execute user code
						local.userCode = local.code;
						evaluate(local.userCode);
					}
					data.output = trim(output);
				} else {
					// Tag-based execution
					savecontent variable="output" {
						// Make context available
						for (local.key in local.context) {
							if (local.key != "$includeHelpers") {
								variables[local.key] = local.context[local.key];
							}
						}
						
						// Execute the tag-based code
						writeOutput(evaluate(local.code));
					}
					data.output = trim(output);
				}
				
				// If the last expression returned a value, show it
				try {
					local.result = evaluate(local.code);
					if (!isNull(local.result) && !isSimpleValue(local.result)) {
						if (isQuery(local.result)) {
							data.output &= chr(10) & chr(10) & "Query returned #local.result.recordCount# record(s)";
							if (local.result.recordCount > 0) {
								data.output &= chr(10) & "Columns: #local.result.columnList#";
							}
						} else if (isStruct(local.result)) {
							data.output &= chr(10) & chr(10) & "Struct with keys: #structKeyList(local.result)#";
						} else if (isArray(local.result)) {
							data.output &= chr(10) & chr(10) & "Array with #arrayLen(local.result)# element(s)";
						} else if (isObject(local.result)) {
							local.metadata = getMetadata(local.result);
							data.output &= chr(10) & chr(10) & "Object of type: #local.metadata.name#";
						}
					} else if (!isNull(local.result) && len(data.output) == 0) {
						data.output = local.result;
					}
				} catch (any e) {
					// Ignore - some expressions don't return values
				}
			} else {
				data.success = false;
				data.error = "No code provided";
			}
			break;
			
		default:
			data.success = false;
			data.error = "Unknown command: #data.command#";
	}
	
} catch (any e) {
	data.success = false;
	data.error = e.message;
	data.detail = e.detail;
	if (structKeyExists(e, "tagContext") && arrayLen(e.tagContext)) {
		data.line = e.tagContext[1].line;
		data.template = e.tagContext[1].template;
	}
}

// Output JSON response
</cfscript>
<cfheader name="Content-Type" value="application/json">
<cfoutput>#serializeJSON(data)#</cfoutput>
<cfabort>