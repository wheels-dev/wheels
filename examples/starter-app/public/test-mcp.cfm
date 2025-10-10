<cfscript>
// Simple MCP test endpoint
cfheader(name="Content-Type", value="application/json");

// Handle CORS
cfheader(name="Access-Control-Allow-Origin", value="*");
cfheader(name="Access-Control-Allow-Methods", value="GET, POST, OPTIONS");
cfheader(name="Access-Control-Allow-Headers", value="Content-Type, Accept, Mcp-Session-Id");

if (cgi.request_method == "OPTIONS") {
	cfheader(statusCode="200");
	abort;
}

// Simple test response
local.response = {
	"message": "MCP test endpoint is working",
	"method": cgi.request_method,
	"timestamp": now(),
	"server": "Wheels CFML"
};

if (cgi.request_method == "POST") {
	// Try to read JSON body
	try {
		local.httpData = getHTTPRequestData();
		local.requestBody = toString(local.httpData.content);

		if (len(trim(local.requestBody))) {
			local.jsonRequest = deserializeJSON(local.requestBody);
			local.response.receivedData = local.jsonRequest;
		}
	} catch (any e) {
		local.response.parseError = e.message;
	}
}

writeOutput(serializeJSON(local.response));
</cfscript>