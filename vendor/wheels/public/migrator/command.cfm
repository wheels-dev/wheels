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

	include "/wheels/public/migrator/_guard.cfm";

if (!StructKeyExists(variables, "$migratorComputeResult")) {
	variables.$migratorComputeResult = function() {
		local.executeAction = StructKeyExists(request.wheels.params, "confirm") && request.wheels.params.confirm ? true : false;
		local.missingMigFlag = StructKeyExists(request.wheels.params, "missingMigFlag") && request.wheels.params.missingMigFlag ? true : false;

		local.message = "";
		local.result = "";

		// To actually perform a destructive action, we need ?confirm=1 in the URL
		// So POST to /wheels/migrator/migrateto/[VERSION] will request confirmation of that action
		if (local.executeAction) {
			local.migrator = application.wheels.migrator;
			switch (request.wheels.params.command) {
				case "migrateTo":
					local.result = local.migrator.migrateTo(request.wheels.params.version, local.missingMigFlag);
					break;
				case "migrateTolatest":
					local.result = local.migrator.migrateToLatest();
					break;
				case "undoMigration":
					local.result = local.migrator.migrateTo(request.wheels.params.version);
					break;
				case "redoMigration":
					local.result = local.migrator.redoMigration(request.wheels.params.version);
					break;
				case "migrateIndividual":
					local.result = local.migrator.migrateIndividual(request.wheels.params.version);
					break;
				default:
			}
		} else {
			switch (request.wheels.params.command) {
				case "migrateTo":
					local.message = "This will migrate the database schema to #request.wheels.params.version#";
					break;
				case "migrateTolatest":
					local.message = "This will migrate the database schema to the latest version";
					break;
				case "redoMigration":
					local.message = "This will redo the database migration at #request.wheels.params.version#";
					break;
				case "migrateIndividual":
					local.message = "This will run migration #request.wheels.params.version# individually (out of sequence)";
					break;
				default:
			}
		}

		return {
			executeAction: local.executeAction,
			missingMigFlag: local.missingMigFlag,
			message: local.message,
			result: local.result
		};
	};
}

$migratorEnforceLocalhost();
$migratorEnforceNoForwardedClients();
$migratorVerifyCsrfToken();
local.computed = $migratorComputeResult();
executeAction = local.computed.executeAction;
missingMigFlag = local.computed.missingMigFlag;
message = local.computed.message;
result = local.computed.result;
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
