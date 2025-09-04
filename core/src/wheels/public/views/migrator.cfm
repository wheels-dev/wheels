<cfinclude template="../layout/_header.cfm">
<cfscript>
datasourceAvailable = true;
try {
	availableMigrations = application.wheels.migrator.getAvailableMigrations();
	CreateObject("java", "java.util.Collections").reverse(availableMigrations);
	currentVersion = application.wheels.migrator.getCurrentMigrationVersion();
	if (ArrayLen(availableMigrations)) latestVersion = availableMigrations[1]["version"];
} catch (database err) {
	datasourceAvailable = false;
	message = err.message;
}
// Get any remaining Missing Migrations
if(structKeyExists(variables, "latestVersion") && currentVersion == latestVersion){
	local.remainingMigrations = [];
	for(local.migration in availableMigrations){
		if(local.migration.status != "migrated") arrayAppend(local.remainingMigrations, local.migration);
	}
}
</cfscript>
<!--- cfformat-ignore-start --->
<cfoutput>
	<div class="ui container">
		#pageHeader("Migrator", "Database Migrations")#

		<cfinclude template="../migrator/_navigation.cfm">
		<cfif datasourceAvailable>
		<cfif arrayLen(availableMigrations)>

			<div class="ui segment">

			<cfscript>
			latestClass = currentVersion EQ latestVersion ? "disabled" : "performmigration";
			resetClass = currentVersion EQ 0 ? "disabled" : "performmigration";
			</cfscript>
				<cfif structKeyExists(local, "remainingMigrations") && arrayLen(local.remainingMigrations)>
					<div class="ui button violet performmigration"
						data-data-url="#urlFor(route='wheelsMigratorCommand', command="migrateto", version='#local.remainingMigrations[1]["version"]#', params="missingMigFlag=1")#">Migrate Missing Migrations</div>
				<cfelse>
					<div class="ui button violet #latestClass#"
						data-data-url="#urlFor(route='wheelsMigratorCommand', command="migrateto", version='#latestVersion#')#">Migrate To Latest</div>
				</cfif>

					<div class="ui button red #resetClass#"
						data-data-url="#urlFor(route='wheelsMigratorCommand', command="migrateto", version=0)#">Reset Database</div>
				#startTable(title="Available Migrations", colspan=4)#
				<cfloop from="1" to="#arrayLen(availableMigrations)#" index="m">
					<cfscript>
						mig = availableMigrations[m];
						class="";
						hasMigrated=false;
						if(mig.status EQ "migrated"){
							class="positive";
							hasMigrated=true;
						}
						if(mig.version EQ currentVersion){
							class="active";
						}
					</cfscript>
					<tr class="#class#">
						<td>
							<cfif hasMigrated>
								<svg xmlns="http://www.w3.org/2000/svg" height="15px" width="15px" viewBox="0 0 448 512"><path d="M438.6 105.4c12.5 12.5 12.5 32.8 0 45.3l-256 256c-12.5 12.5-32.8 12.5-45.3 0l-128-128c-12.5-12.5-12.5-32.8 0-45.3s32.8-12.5 45.3 0L160 338.7 393.4 105.4c12.5-12.5 32.8-12.5 45.3 0z"/></svg>
							<cfelse>
								<div class="ui icon button teal tiny previewsql"
									data-data-url="#urlFor(route='wheelsMigratorSQL', version='#mig.version#')#"
									data-content="Preview SQL">
									<svg xmlns="http://www.w3.org/2000/svg" height="12" width="14" viewBox="0 0 640 512"><path fill="##ffffff" d="M392.8 1.2c-17-4.9-34.7 5-39.6 22l-128 448c-4.9 17 5 34.7 22 39.6s34.7-5 39.6-22l128-448c4.9-17-5-34.7-22-39.6zm80.6 120.1c-12.5 12.5-12.5 32.8 0 45.3L562.7 256l-89.4 89.4c-12.5 12.5-12.5 32.8 0 45.3s32.8 12.5 45.3 0l112-112c12.5-12.5 12.5-32.8 0-45.3l-112-112c-12.5-12.5-32.8-12.5-45.3 0zm-306.7 0c-12.5-12.5-32.8-12.5-45.3 0l-112 112c-12.5 12.5-12.5 32.8 0 45.3l112 112c12.5 12.5 32.8 12.5 45.3 0s12.5-32.8 0-45.3L77.3 256l89.4-89.4c12.5-12.5 12.5-32.8 0-45.3z"/></svg>
								</div>
							</cfif>
						</td>
						<td>#mig.version#</td>
						<td>#replace(mig.name, '_', ' ', 'all')#</td>
						<td>

							<cfif !hasMigrated>
								<div class="ui icon button violet tiny performmigration"
									data-data-url="#urlFor(route='wheelsMigratorCommand', command="migrateto", version='#mig.version#')#"
									data-content="Migrate To this schema (Up)">
									<svg xmlns="http://www.w3.org/2000/svg" height="12px" width="12px" viewBox="0 0 512 512"><path fill="##ffffff" d="M463.5 224H472c13.3 0 24-10.7 24-24V72c0-9.7-5.8-18.5-14.8-22.2s-19.3-1.7-26.2 5.2L413.4 96.6c-87.6-86.5-228.7-86.2-315.8 1c-87.5 87.5-87.5 229.3 0 316.8s229.3 87.5 316.8 0c12.5-12.5 12.5-32.8 0-45.3s-32.8-12.5-45.3 0c-62.5 62.5-163.8 62.5-226.3 0s-62.5-163.8 0-226.3c62.2-62.2 162.7-62.5 225.3-1L327 183c-6.9 6.9-8.9 17.2-5.2 26.2s12.5 14.8 22.2 14.8H463.5z"/></svg>
								</div>
							</cfif>
							<cfif hasMigrated>
								<cfif mig.version NEQ currentVersion>
								<div class="ui icon button red tiny performmigration"
									data-data-url="#urlFor(route='wheelsMigratorCommand', command="migrateto", version='#mig.version#')#"
								data-content="Migrate To this schema (Down)">
								<svg xmlns="http://www.w3.org/2000/svg" height="12px" width="12px" viewBox="0 0 512 512"><path fill="##ffffff" d="M48.5 224H40c-13.3 0-24-10.7-24-24V72c0-9.7 5.8-18.5 14.8-22.2s19.3-1.7 26.2 5.2L98.6 96.6c87.6-86.5 228.7-86.2 315.8 1c87.5 87.5 87.5 229.3 0 316.8s-229.3 87.5-316.8 0c-12.5-12.5-12.5-32.8 0-45.3s32.8-12.5 45.3 0c62.5 62.5 163.8 62.5 226.3 0s62.5-163.8 0-226.3c-62.2-62.2-162.7-62.5-225.3-1L185 183c6.9 6.9 8.9 17.2 5.2 26.2s-12.5 14.8-22.2 14.8H48.5z"/></svg>
								</div>
							</cfif>
								<div class="ui icon button red tiny performmigration"
									data-data-url="#urlFor(route='wheelsMigratorCommand', command="redomigration", version='#mig.version#')#"
								data-content="Redo This Migration (Down then Up)">
								<svg xmlns="http://www.w3.org/2000/svg" height="12px" width="12px" viewBox="0 0 512 512"><path fill="##ffffff" d="M105.1 202.6c7.7-21.8 20.2-42.3 37.8-59.8c62.5-62.5 163.8-62.5 226.3 0L386.3 160H352c-17.7 0-32 14.3-32 32s14.3 32 32 32H463.5c0 0 0 0 0 0h.4c17.7 0 32-14.3 32-32V80c0-17.7-14.3-32-32-32s-32 14.3-32 32v35.2L414.4 97.6c-87.5-87.5-229.3-87.5-316.8 0C73.2 122 55.6 150.7 44.8 181.4c-5.9 16.7 2.9 34.9 19.5 40.8s34.9-2.9 40.8-19.5zM39 289.3c-5 1.5-9.8 4.2-13.7 8.2c-4 4-6.7 8.8-8.1 14c-.3 1.2-.6 2.5-.8 3.8c-.3 1.7-.4 3.4-.4 5.1V432c0 17.7 14.3 32 32 32s32-14.3 32-32V396.9l17.6 17.5 0 0c87.5 87.4 229.3 87.4 316.7 0c24.4-24.4 42.1-53.1 52.9-83.7c5.9-16.7-2.9-34.9-19.5-40.8s-34.9 2.9-40.8 19.5c-7.7 21.8-20.2 42.3-37.8 59.8c-62.5 62.5-163.8 62.5-226.3 0l-.1-.1L125.6 352H160c17.7 0 32-14.3 32-32s-14.3-32-32-32H48.4c-1.6 0-3.2 .1-4.8 .3s-3.1 .5-4.6 1z"/></svg>
								</div>

							</cfif>
						</td>
					</tr>
				</cfloop>
				#endTable()#
			</div>
			</div>
		<cfelse>
		<div class="ui placeholder segment">
			<div class="ui icon header">
				<svg xmlns="http://www.w3.org/2000/svg" height="70" width="50" viewBox="0 0 448 512"><path d="M448 73.1v45.7C448 159.1 347.7 192 224 192S0 159.1 0 118.9V73.1C0 32.9 100.3 0 224 0s224 32.9 224 73.1zM448 176v102.9C448 319.1 347.7 352 224 352S0 319.1 0 278.9V176c48.1 33.1 136.2 48.6 224 48.6S399.9 209.1 448 176zm0 160v102.9C448 479.1 347.7 512 224 512S0 479.1 0 438.9V336c48.1 33.1 136.2 48.6 224 48.6S399.9 369.1 448 336z"/></svg><br>
				No migration files found!<br><small>Perhaps start by using the templating system?</small>
			</div>
		</div>
		</cfif>
	<cfelse>

		<div class="ui placeholder segment">
			<div class="ui icon header">
				<i class="database icon"></i>
				Database Error<br><small>
			#message#</small>
			</div>
		</div>
	</cfif>

	</div><!--/container-->

	<div class="ui longer previewsqlmodal modal">
		<svg xmlns="http://www.w3.org/2000/svg" height="16" width="12" viewBox="0 0 384 512"><path fill="##ffffff" d="M342.6 150.6c12.5-12.5 12.5-32.8 0-45.3s-32.8-12.5-45.3 0L192 210.7 86.6 105.4c-12.5-12.5-32.8-12.5-45.3 0s-12.5 32.8 0 45.3L146.7 256 41.4 361.4c-12.5 12.5-12.5 32.8 0 45.3s32.8 12.5 45.3 0L192 301.3 297.4 406.6c12.5 12.5 32.8 12.5 45.3 0s12.5-32.8 0-45.3L237.3 256 342.6 150.6z"/></svg>
		<div class="header">
			Preview SQL
		</div>
		<div class="content">
		<div class="ui placeholder">
			<div class="paragraph">
				<div class="line"></div>
				<div class="line"></div>
				<div class="line"></div>
				<div class="line"></div>
				<div class="line"></div>
			</div>
			<div class="paragraph">
				<div class="line"></div>
				<div class="line"></div>
				<div class="line"></div>
			</div>
		</div>
		</div>

		<div class="actions">
			<div class="ui cancel button">Close</div>
		</div>
	</div>


	<div class="ui migratorcommandmodal modal">
		<svg xmlns="http://www.w3.org/2000/svg" height="16" width="12" viewBox="0 0 384 512"><path fill="##ffffff" d="M342.6 150.6c12.5-12.5 12.5-32.8 0-45.3s-32.8-12.5-45.3 0L192 210.7 86.6 105.4c-12.5-12.5-32.8-12.5-45.3 0s-12.5 32.8 0 45.3L146.7 256 41.4 361.4c-12.5 12.5-12.5 32.8 0 45.3s32.8 12.5 45.3 0L192 301.3 297.4 406.6c12.5 12.5 32.8 12.5 45.3 0s12.5-32.8 0-45.3L237.3 256 342.6 150.6z"/></svg>
		<div class="header">
			Perform Migration
		</div>
		<div class="content longer"></div>
		<div class="actions">
			<div class="ui cancel button">Close</div>
		</div>
	</div>
<cfif get("URLRewriting") eq "Off">
	<cfset method = 'get'>
<cfelse>
	<cfset method = 'post'>
</cfif>
<script>
$(document).ready(function() {

// Click handlers
$(".previewsql").on("click", function(e){
	var url = $(this).data("data-url");
	var resp = $.ajax({
		url: url,
		method: 'get'
	})
	.done(function(data, status, req) {
		var res = $(".previewsqlmodal > .content");
		res.html(data);
		$('.ui.modal.longer.previewsqlmodal')
			.modal({
				onVisible: function(){
					hljs.initHighlightingOnLoad();
				}
			})
			.modal('show')
		;
		hljs.initHighlightingOnLoad();
	})
	.fail(function(e) {
		//alert( "error" );
	})
	.always(function(r) {
		//console.log(r);
	});
});
$(".performmigration").on("click", function(e){
	var url = $(this).data("data-url");
	var resp = $.ajax({
		url: url,
		method: '#method#'
	})
	.done(function(data, status, req) {
		var res = $(".migratorcommandmodal > .content");
		res.html(data);
		$('.ui.modal.migratorcommandmodal')
			.modal({
				onHidden: function(){
					location.reload();
				},
				onVisible: function(){
					hljs.initHighlightingOnLoad();
				}
			})
			.modal('show')
		;
	})
	.fail(function(e) {
		//alert( "error" );
	})
	.always(function(r) {
		//console.log(r);
	});
});
// Popups
$('.ui.icon.button')
	.popup()
;

});
</script>
</cfoutput>
<cfinclude template="../layout/_footer.cfm">
<!--- cfformat-ignore-end --->
