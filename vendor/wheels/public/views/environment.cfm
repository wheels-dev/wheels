<!--- Environment Management Bridge - Get/Set Wheels environment --->
<cfscript>
setting showDebugOutput="no";

// Check if this is a valid environment request
if (!structKeyExists(request, "wheels") || !structKeyExists(request.wheels, "params")) {
	// Return empty response if not a proper request
	cfcontent(reset="true", type="application/json");
	writeOutput('{"success":false,"error":"Invalid request"}');
	cfabort();
}

// Initialize response
data = {
	"success": true,
	"environment": application.wheels.environment,
	"wheelsVersion": application.wheels.version,
	"datasource": application.wheels.dataSourceName,
	"message": ""
};

try {
	// Add server info if available
	if (structKeyExists(server, "coldfusion")) {
		data.serverName = server.coldfusion.productname & " " & server.coldfusion.productversion;
	} else if (structKeyExists(server, "lucee")) {
		data.serverName = "Lucee " & server.lucee.version;
	}
	
	// Get command
	if (!structKeyExists(request.wheels.params, "command")) {
		data.command = "get";
	} else {
		data.command = request.wheels.params.command;
	}
	
	switch (data.command) {
		case "get":
			// Add environment-specific settings
			data.settings = {
				"cacheQueries": application.wheels.cacheQueries,
				"cachePartials": application.wheels.cachePartials,
				"cachePages": application.wheels.cachePages,
				"cacheActions": application.wheels.cacheActions,
				"showDebugInformation": application.wheels.showDebugInformation,
				"showErrorInformation": application.wheels.showErrorInformation
			};
			break;
			
		case "set":
			// Setting environment requires application restart
			if (structKeyExists(request.wheels.params, "value")) {
				var newEnvironment = request.wheels.params.value;
				var validEnvironments = "development,testing,production,maintenance";
				
				if (listFindNoCase(validEnvironments, newEnvironment)) {
					// Note: Actually changing the environment would require application restart
					// This is just acknowledging the request
					data.message = "Environment change to '#newEnvironment#' acknowledged. Restart required.";
					data.newEnvironment = newEnvironment;
				} else {
					data.success = false;
					data.message = "Invalid environment: #newEnvironment#";
				}
			} else {
				data.success = false;
				data.message = "No environment value provided";
			}
			break;
			
		default:
			data.success = false;
			data.message = "Unknown command: #data.command#";
	}
	
} catch (any e) {
	data.success = false;
	data.message = e.message & ': ' & e.detail;
}
</cfscript>
<cfcontent reset="true" type="application/json"><cfoutput>#serializeJSON(data)#</cfoutput>
<cfabort>