<cfscript>
/**
 * Console REPL eval endpoint
 *
 * Accepts a CFML expression via POST, evaluates it in the full Wheels
 * application context (model(), service(), get(), etc.), and returns
 * the result as JSON.
 *
 * Security: localhost-only + development mode + reload password
 */
cfheader(statuscode="200");
cfcontent(type="application/json");

// ── Security: localhost only ────────────────────
local.remoteAddr = cgi.REMOTE_ADDR;
if (!listFind("127.0.0.1,::1,0:0:0:0:0:0:0:1", local.remoteAddr)) {
	writeOutput(serializeJSON({success: false, error: "Console access restricted to localhost"}));
	abort;
}

// ── Security: development mode only ─────────────
if (
	structKeyExists(application, "wheels")
	&& structKeyExists(application.wheels, "environment")
	&& application.wheels.environment != "development"
) {
	writeOutput(serializeJSON({success: false, error: "Console only available in development mode. Current: " & application.wheels.environment}));
	abort;
}

// ── Parse request body ──────────────────────────
local.requestBody = toString(getHTTPRequestData().content);
if (!isJSON(local.requestBody)) {
	writeOutput(serializeJSON({success: false, error: "Invalid request: expected JSON body"}));
	abort;
}

local.payload = deserializeJSON(local.requestBody);
local.expression = local.payload.expression ?: "";
local.password = local.payload.password ?: "";

if (!len(trim(local.expression))) {
	writeOutput(serializeJSON({success: false, error: "Empty expression"}));
	abort;
}

// ── Security: reload password ───────────────────
if (
	structKeyExists(application.wheels, "reloadPassword")
	&& len(application.wheels.reloadPassword)
	&& Compare(Hash(local.password, "SHA-256"), Hash(application.wheels.reloadPassword, "SHA-256")) != 0
) {
	writeOutput(serializeJSON({
		success: false,
		error: "Invalid reload password. Set RELOAD_PASSWORD in .env or pass --password to wheels console"
	}));
	abort;
}

// ── Built-in commands ───────────────────────────
if (local.expression == "__ping__") {
	writeOutput(serializeJSON({
		success: true,
		result: "pong",
		type: "string",
		output: "",
		environment: application.wheels.environment ?: "unknown",
		version: application.wheels.version ?: "unknown"
	}));
	abort;
}

if (local.expression == "__env__") {
	local.envInfo = {
		environment: application.wheels.environment ?: "unknown",
		version: application.wheels.version ?: "unknown",
		datasource: application.wheels.dataSourceName ?: "unknown",
		urlRewriting: application.wheels.URLRewriting ?: "unknown"
	};
	writeOutput(serializeJSON({
		success: true,
		result: serializeJSON(local.envInfo),
		type: "struct",
		output: ""
	}));
	abort;
}

// ── Evaluate expression ─────────────────────────
local.response = {success: true, output: "", result: "", type: "void", error: ""};

try {
	local.captured = "";
	savecontent variable="local.captured" {
		local.evalResult = evaluate(local.expression);
	}
	local.response.output = local.captured;

	if (!isNull(local.evalResult)) {
		// Query objects (from findAll, etc.)
		if (isQuery(local.evalResult)) {
			local.response.type = "query";
			local.cols = listToArray(local.evalResult.columnList);
			local.rows = [];
			local.rowCount = 0;
			for (local.row in local.evalResult) {
				local.rowCount++;
				// Limit to 100 rows to avoid huge responses
				if (local.rowCount > 100) break;
				local.r = {};
				for (local.col in local.cols) {
					local.r[local.col] = isNull(local.row[local.col]) ? "" : local.row[local.col];
				}
				arrayAppend(local.rows, local.r);
			}
			local.response.result = serializeJSON({
				columns: local.cols,
				recordCount: local.evalResult.recordCount,
				data: local.rows
			});

		// Wheels model objects (from findByKey, findOne, new)
		} else if (
			isObject(local.evalResult)
			&& structKeyExists(local.evalResult, "properties")
			&& isCustomFunction(local.evalResult.properties)
		) {
			local.response.type = "model";
			try {
				local.props = local.evalResult.properties();
				// Add key if available
				if (structKeyExists(local.evalResult, "key") && isCustomFunction(local.evalResult.key)) {
					local.props["_key"] = local.evalResult.key();
				}
				if (structKeyExists(local.evalResult, "isNew") && isCustomFunction(local.evalResult.isNew)) {
					local.props["_isNew"] = local.evalResult.isNew();
				}
				local.response.result = serializeJSON(local.props);
			} catch (any e) {
				local.response.result = getMetadata(local.evalResult).name ?: "Model";
				local.response.type = "object";
			}

		// Simple values (strings, numbers, booleans)
		} else if (isSimpleValue(local.evalResult)) {
			if (isNumeric(local.evalResult)) {
				local.response.type = "number";
			} else if (isBoolean(local.evalResult)) {
				local.response.type = "boolean";
			} else {
				local.response.type = "string";
			}
			local.response.result = toString(local.evalResult);

		// Structs
		} else if (isStruct(local.evalResult)) {
			local.response.type = "struct";
			local.response.result = serializeJSON(local.evalResult);

		// Arrays
		} else if (isArray(local.evalResult)) {
			local.response.type = "array";
			local.response.result = serializeJSON(local.evalResult);

		// Other objects (services, components, etc.)
		} else if (isObject(local.evalResult)) {
			local.response.type = "object";
			local.meta = getMetadata(local.evalResult);
			local.response.result = local.meta.name ?: "Object";

		// Fallback
		} else {
			local.response.type = "unknown";
			try {
				local.response.result = serializeJSON(local.evalResult);
			} catch (any e) {
				local.response.result = "[unserializable result]";
			}
		}
	}
} catch (any e) {
	local.response.success = false;
	local.response.error = e.message;
	if (len(e.detail ?: "")) {
		local.response.error &= " -- " & e.detail;
	}
}

writeOutput(serializeJSON(local.response));
abort;
</cfscript>
