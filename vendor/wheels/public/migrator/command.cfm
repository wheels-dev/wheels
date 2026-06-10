<cfscript>
param name="request.wheels.params.command";
param name="request.wheels.params.version";

/*
 * Security: migration commands are destructive (reset/rollback the dev
 * database), are dispatched via the public component outside the middleware
 * pipeline and the controller CSRF layer, and degrade to GET when URL
 * rewriting is off. Mirror the consoleeval.cfm gates: localhost only, no
 * forwarded clients, and a custom anti-CSRF request header so a page the
 * developer merely visits cannot auto-submit a command.
 */

// ── Security: localhost only ────────────────────
local.remoteAddr = cgi.REMOTE_ADDR;
local.isLocalhost = false;
try {
	local.remoteInet = createObject("java", "java.net.InetAddress").getByName(local.remoteAddr);
	local.isLocalhost = local.remoteInet.isLoopbackAddress();
} catch (any e) {
	local.isLocalhost = false;
}
if (!local.isLocalhost) {
	cfheader(statuscode=403);
	cfcontent(type="text/plain", reset=true);
	writeOutput("Migrator commands are restricted to localhost");
	abort;
}

// ── Security: X-Forwarded-For proxy bypass prevention ──
if (len(trim(cgi.HTTP_X_FORWARDED_FOR))) {
	local.forwardedIps = listToArray(cgi.HTTP_X_FORWARDED_FOR);
	for (local.ip in local.forwardedIps) {
		try {
			local.fwdInet = createObject("java", "java.net.InetAddress").getByName(trim(local.ip));
			if (!local.fwdInet.isLoopbackAddress()) {
				cfheader(statuscode=403);
				cfcontent(type="text/plain", reset=true);
				writeOutput("Migrator commands are restricted to localhost");
				abort;
			}
		} catch (any e) {
			cfheader(statuscode=403);
			cfcontent(type="text/plain", reset=true);
			writeOutput("Migrator commands are restricted to localhost");
			abort;
		}
	}
}

// ── Security: anti-CSRF token via custom request header ──
// The token is generated when the migrator GUI renders (../views/migrator.cfm)
// and must round-trip in the X-Wheels-Csrf-Token header. Cross-site pages
// cannot set custom headers without a CORS preflight (which this endpoint
// never approves), so auto-submitted GET/form requests are blocked. Fails
// closed when no token has been issued yet.
local.suppliedCsrfToken = "";
local.requestHeaders = GetHTTPRequestData().headers;
if (structKeyExists(local.requestHeaders, "X-Wheels-Csrf-Token") && isSimpleValue(local.requestHeaders["X-Wheels-Csrf-Token"])) {
	local.suppliedCsrfToken = local.requestHeaders["X-Wheels-Csrf-Token"];
}
local.csrfTokenValid = false;
if (
	len(local.suppliedCsrfToken)
	&& structKeyExists(application, "wheels")
	&& structKeyExists(application.wheels, "$migratorCsrfToken")
	&& len(application.wheels.$migratorCsrfToken)
) {
	// Constant-time comparison to prevent timing attacks
	local.inputBytes = Hash(local.suppliedCsrfToken, "SHA-256").getBytes("UTF-8");
	local.expectedBytes = Hash(application.wheels.$migratorCsrfToken, "SHA-256").getBytes("UTF-8");
	local.csrfTokenValid = CreateObject("java", "java.security.MessageDigest").isEqual(local.inputBytes, local.expectedBytes);
}
if (!local.csrfTokenValid) {
	cfheader(statuscode=403);
	cfcontent(type="text/plain", reset=true);
	writeOutput("Missing or invalid migrator CSRF token. Open /wheels/migrator and use the GUI buttons.");
	abort;
}

executeAction = StructKeyExists(request.wheels.params, "confirm") && request.wheels.params.confirm ? true : false;
missingMigFlag = StructKeyExists(request.wheels.params, "missingMigFlag") && request.wheels.params.missingMigFlag ? true : false;

message = "";
result = "";

// To actually perform a destructive action, we need ?confirm=1 in the URL
// So POST to /wheels/migrator/migrateto/[VERSION] will request confirmation of that action
if (executeAction) {
	migrator = application.wheels.migrator;
	switch (request.wheels.params.command) {
		case "migrateTo":
			result = migrator.migrateTo(request.wheels.params.version, missingMigFlag);
			break;
		case "migrateTolatest":
			result = migrator.migrateToLatest();
			break;
		case "undoMigration":
			result = migrator.migrateTo(request.wheels.params.version);
			break;
		case "redoMigration":
			result = migrator.redoMigration(request.wheels.params.version);
			break;
		case "migrateIndividual":
			result = migrator.migrateIndividual(request.wheels.params.version);
			break;
		default:
	}
} else {
	switch (request.wheels.params.command) {
		case "migrateTo":
			message = "This will migrate the database schema to #request.wheels.params.version#";
			break;
		case "migrateTolatest":
			message = "This will migrate the database schema to the latest version";
			break;
		case "redoMigration":
			message = "This will redo the database migration at #request.wheels.params.version#";
			break;
		case "migrateIndividual":
			message = "This will run migration #request.wheels.params.version# individually (out of sequence)";
			break;
		default:
	}
}
</cfscript>
<!--- cfformat-ignore-start --->
<cfoutput>
	<div id="result" class="scrolling content longer">
		<cfif !executeAction>
			<div class="ui red message">Confirmation Required: #message#</div>
			<div class="ui red button execute" data-data-url="#urlFor(route='wheelsMigratorCommand', command=request.wheels.params.command, version=request.wheels.params.version, params="confirm=1&missingMigFlag=#missingMigFlag#")#">Execute</div>
		<cfelse>
			<pre><code class="sql" style="overflow-y: scroll; height:500px;">#result#</code></pre>
		</cfif>
	</div>
<cfif get("URLRewriting") eq "Off">
	<cfset method = 'get'>
<cfelse>
	<cfset method = 'post'>
</cfif>
</div>
<script>
$(document).ready(function() {
	$(".execute").on("click", function(e){
		var res = $("##result");
		var url = $(this).data("data-url");
			res.html('<div class="ui active inverted dimmer"><div class="ui text loader">Loading</div><p></p><p></p><p></p><p></p></div>');
		var resp = $.ajax({
				url: url,
				method: '#method#',
				headers: {'X-Wheels-Csrf-Token': '#JSStringFormat(application.wheels.$migratorCsrfToken)#'}
		})
		.done(function(data, status, req) {
			res.html(data);
		})
		.fail(function(e) {
			//alert( "error" );
		})
		.always(function(r) {
		//console.log(r);
		});
	});
});
</script>
</cfoutput>
<!--- cfformat-ignore-end --->
