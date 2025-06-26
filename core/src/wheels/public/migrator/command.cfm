<cfscript>
param name="request.wheels.params.command";
param name="request.wheels.params.version";

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
</cfoutput>
</div>
<script>
$(document).ready(function() {
	$(".execute").on("click", function(e){
		var res = $("#result");
		var url = $(this).data("data-url");
			res.html('<div class="ui active inverted dimmer"><div class="ui text loader">Loading</div><p></p><p></p><p></p><p></p></div>');
		var resp = $.ajax({
				url: url,
				method: 'post'
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
<!--- cfformat-ignore-end --->
