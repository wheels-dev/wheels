<cfscript>
// MCP (Model Context Protocol) Server Implementation
// Implements Streamable HTTP transport with JSON-RPC 2.0

// Set CORS headers for cross-origin requests
cfheader(name="Access-Control-Allow-Origin", value="*");
cfheader(name="Access-Control-Allow-Methods", value="GET, POST, OPTIONS");
cfheader(name="Access-Control-Allow-Headers", value="Content-Type, Accept, Mcp-Session-Id");

// Handle OPTIONS preflight requests
if (cgi.request_method == "OPTIONS") {
	cfheader(statusCode="200", statusText="OK");
	abort;
}

// For POST requests that get routed as GET due to internal routing restrictions,
// check if there's form data in the body that indicates this is actually a JSON-RPC POST
local.actualMethod = cgi.request_method;
if (cgi.request_method == "GET") {
	// Check if this is actually a POST request that was routed as GET
	local.httpData = getHTTPRequestData();
	local.bodyContent = toString(local.httpData.content);
	if (len(trim(local.bodyContent)) > 0) {
		try {
			local.testJson = deserializeJSON(local.bodyContent);
			if (structKeyExists(local.testJson, "jsonrpc") && structKeyExists(local.testJson, "method")) {
				// This looks like a JSON-RPC request sent via POST
				local.actualMethod = "POST";
			}
		} catch (any e) {
			// Not JSON, continue as GET
		}
	}
}

try {
	// Initialize or get session manager
	if (!structKeyExists(application, "mcpSessionManager")) {
		application.mcpSessionManager = createObject("component", "wheels.public.mcp.SessionManager").init();
	}
	local.sessionManager = application.mcpSessionManager;

	// Initialize MCP server instance
	if (!structKeyExists(application, "mcpServer")) {
		application.mcpServer = createObject("component", "wheels.public.mcp.McpServer").init();
	}
	local.mcpServer = application.mcpServer;

	// Handle GET requests (SSE support or query-based testing)
	if (local.actualMethod == "GET") {
		// Check if this is a query-based JSON-RPC request for testing
		if (structKeyExists(url, "method") && url.method == "POST" && structKeyExists(url, "body")) {
			// Decode the body and treat as POST
			local.actualMethod = "POST";
			local.requestBody = urlDecode(url.body);
			local.sessionId = structKeyExists(cgi, "http_mcp_session_id") ? cgi.http_mcp_session_id : local.sessionManager.createSession();
		} else {
			// Check if client accepts SSE
			local.acceptHeader = cgi.http_accept ?: "";
			if (find("text/event-stream", local.acceptHeader)) {
				// Return SSE stream
				cfheader(name="Content-Type", value="text/event-stream");
				cfheader(name="Cache-Control", value="no-cache");
				cfheader(name="Connection", value="keep-alive");

				// Create or get session
				local.sessionId = local.sessionManager.createSession();
				cfheader(name="Mcp-Session-Id", value=local.sessionId);

				// Send initial SSE message
				writeOutput("data: " & serializeJSON({
					"type": "connection",
					"sessionId": local.sessionId,
					"status": "connected"
				}) & chr(10) & chr(10));
				cfflush();
				abort;
			} else {
				// Return 405 Method Not Allowed for non-SSE GET requests
				cfheader(statusCode="405", statusText="Method Not Allowed");
				writeOutput("GET requests must accept text/event-stream");
				abort;
			}
		}
	}

	// Handle POST requests (JSON-RPC messages)
	if (local.actualMethod == "POST") {
		// Get session ID from header or create new one (may already be set for query-based requests)
		if (!structKeyExists(local, "sessionId")) {
			local.sessionId = structKeyExists(cgi, "http_mcp_session_id") ? cgi.http_mcp_session_id : local.sessionManager.createSession();
		}

		// Get request body (may have already been read for method detection or query params)
		if (!structKeyExists(local, "requestBody")) {
			if (structKeyExists(local, "bodyContent")) {
				local.requestBody = local.bodyContent;
			} else {
				local.httpData = getHTTPRequestData();
				local.requestBody = toString(local.httpData.content);
			}
		}

		if (len(trim(local.requestBody)) == 0) {
			// Return 400 Bad Request for empty body
			cfheader(statusCode="400", statusText="Bad Request");
			cfheader(name="Content-Type", value="application/json");
			local.errorResponse = {
				"jsonrpc": "2.0",
				"error": {
					"code": -32600,
					"message": "Invalid Request",
					"data": "Request body is empty"
				}
			};
			local.errorResponse["id"] = javaCast("null", "");
			writeOutput(serializeJSON(local.errorResponse));
			abort;
		}

		// Parse JSON-RPC request
		try {
			local.jsonRpcRequest = deserializeJSON(local.requestBody);
		} catch (any e) {
			// Return 400 Bad Request for invalid JSON
			cfheader(statusCode="400", statusText="Bad Request");
			cfheader(name="Content-Type", value="application/json");
			local.errorResponse = {
				"jsonrpc": "2.0",
				"error": {
					"code": -32700,
					"message": "Parse error",
					"data": e.message
				}
			};
			local.errorResponse["id"] = javaCast("null", "");
			writeOutput(serializeJSON(local.errorResponse));
			abort;
		}

		// Process the JSON-RPC request
		local.response = local.mcpServer.handleRequest(local.jsonRpcRequest, local.sessionId);

		// Set response headers
		cfheader(name="Mcp-Session-Id", value=local.sessionId);
		cfheader(name="Content-Type", value="application/json");
		cfheader(statusCode="200", statusText="OK");

		// Return JSON-RPC response
		writeOutput(serializeJSON(local.response));
		abort;
	}

	// Return 405 Method Not Allowed for other methods
	cfheader(statusCode="405", statusText="Method Not Allowed");
	cfheader(name="Content-Type", value="application/json");
	writeOutput(serializeJSON({
		"error": "Only GET and POST methods are supported",
		"supportedMethods": ["GET", "POST"]
	}));

} catch (any e) {
	// Handle unexpected errors
	cfheader(statusCode="500", statusText="Internal Server Error");
	cfheader(name="Content-Type", value="application/json");
	writeOutput(serializeJSON({
		"error": "Internal server error",
		"message": e.message,
		"detail": structKeyExists(e, "detail") ? e.detail : ""
	}));
}
</cfscript>