<cfscript>
param name="request.wheels.params.migrationName";
param name="request.wheels.params.templateName";

// Creating a migration writes a file to disk, so this endpoint gets the same
// localhost + no-forwarded-client + CSRF-token gate as migrator/command.cfm.
include "/wheels/public/migrator/_guard.cfm";
$migratorApplyDevToolGuards();

migrator = application.wheels.migrator;

if (StructKeyExists(request.wheels.params, "migrationPrefix") && Len(request.wheels.params.migrationPrefix)) {
	message = migrator.createMigration(
		request.wheels.params.migrationName,
		request.wheels.params.templateName,
		request.wheels.params.migrationPrefix
	);
} else {
	message = migrator.createMigration(request.wheels.params.migrationName, request.wheels.params.templateName);
}
</cfscript>
<!--- cfformat-ignore-start --->
<cfoutput>
	<div class="ui info message">
		<div class="header">Result</div>
		#EncodeForHTML(message)#
	</div>
</cfoutput>
<!--- cfformat-ignore-end --->
