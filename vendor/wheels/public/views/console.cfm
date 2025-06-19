<!--- Console REPL Bridge - Executes code in Wheels application context --->
<cfscript>
setting showDebugOutput="no";

// Check if this is a valid console request
if (!structKeyExists(request, "wheels") || !structKeyExists(request.wheels, "params")) {
	// Return empty response if not a proper request
	writeOutput('{"success":false,"error":"Invalid request"}');
	abort;
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
				var code = request.wheels.params.code;
				var isScript = structKeyExists(request.wheels.params, "script") && request.wheels.params.script;
				
				// Create execution context with Wheels helpers
				var context = {
					// Model access
					model: function(name) {
						return application.wheels.models[arguments.name];
					},
					
					// Direct query access
					query: function(sql) {
						var q = new Query();
						q.setDatasource(application.wheels.dataSourceName);
						q.setSQL(arguments.sql);
						return q.execute().getResult();
					},
					
					// Include all global helper functions
					$includeHelpers: function() {
						// Include view helpers
						include "/wheels/global/helpers.cfm";
						include "/wheels/view/helpers.cfm";
						include "/wheels/controller/helpers.cfm";
						include "/wheels/model/helpers.cfm";
					}
				};
				
				// Make application scope available
				context.application = application;
				
				// Include Wheels helpers into context
				savecontent variable="helperOutput" {
					context.$includeHelpers();
				}
				
				// Execute the code
				if (isScript) {
					// CFScript execution
					savecontent variable="output" {
						// Import context variables
						for (var key in context) {
							if (key != '$includeHelpers') {
								variables[key] = context[key];
							}
						}
						
						// Execute user code
						var userCode = code;
						evaluate(userCode);
					}
					data.output = trim(output);
				} else {
					// Tag-based execution
					savecontent variable="output" {
						// Make context available
						for (var key in context) {
							if (key != "$includeHelpers") {
								variables[key] = context[key];
							}
						}
						
						// Execute the tag-based code
						writeOutput(evaluate(code));
					}
					data.output = trim(output);
				}
				
				// If the last expression returned a value, show it
				try {
					var result = evaluate(code);
					if (!isNull(result) && !isSimpleValue(result)) {
						if (isQuery(result)) {
							data.output &= chr(10) & chr(10) & "Query returned #result.recordCount# record(s)";
							if (result.recordCount > 0) {
								data.output &= chr(10) & "Columns: #result.columnList#";
							}
						} else if (isStruct(result)) {
							data.output &= chr(10) & chr(10) & "Struct with keys: #structKeyList(result)#";
						} else if (isArray(result)) {
							data.output &= chr(10) & chr(10) & "Array with #arrayLen(result)# element(s)";
						} else if (isObject(result)) {
							var metadata = getMetadata(result);
							data.output &= chr(10) & chr(10) & "Object of type: #metadata.name#";
						}
					} else if (!isNull(result) && len(data.output) == 0) {
						data.output = result;
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