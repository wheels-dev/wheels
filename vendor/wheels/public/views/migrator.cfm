<cfscript>
// Check for JSON format request
param name="request.wheels.params.format" default="html";

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

// Detect out-of-sequence migrations: unmigrated files with version < currentVersion
outOfSequenceMigrations = [];
if (datasourceAvailable && structKeyExists(variables, "currentVersion") && currentVersion > 0) {
	for (local.mig in availableMigrations) {
		if (local.mig.status != "migrated" && local.mig.version < currentVersion) {
			ArrayAppend(outOfSequenceMigrations, local.mig);
		}
	}
}

// If JSON format is requested, return JSON response
if (request.wheels.params.format == "json") {
	local.migratorData = {
		"version": application.wheels.version,
		"timestamp": now(),
		"migrator": {
			"datasourceAvailable": datasourceAvailable
		}
	};

	if (datasourceAvailable) {
		local.migratorData.migrator.currentVersion = currentVersion;
		if (structKeyExists(variables, "latestVersion")) {
			local.migratorData.migrator.latestVersion = latestVersion;
		}
		local.migratorData.migrator.migrations = availableMigrations;
		local.migratorData.migrator.migrationsCount = ArrayLen(availableMigrations);

		// Count migrated vs pending
		local.migratedCount = 0;
		local.pendingCount = 0;
		for (local.mig in availableMigrations) {
			if (structKeyExists(local.mig, "status") && local.mig.status == "migrated") {
				local.migratedCount++;
			} else {
				local.pendingCount++;
			}
		}
		local.migratorData.migrator.migratedCount = local.migratedCount;
		local.migratorData.migrator.pendingCount = local.pendingCount;
		local.migratorData.migrator.outOfSequenceCount = ArrayLen(outOfSequenceMigrations);

		if (structKeyExists(variables, "local") && structKeyExists(local, "remainingMigrations")) {
			local.migratorData.migrator.remainingMigrations = local.remainingMigrations;
		}
	} else {
		local.migratorData.migrator.error = message;
	}

	cfcontent(type="application/json", reset=true);
	writeOutput(serializeJSON(local.migratorData));
	abort;
}
</cfscript>
<cfinclude template="../layout/_header.cfm">
<!--- cfformat-ignore-start --->
<cfoutput>
	<div class="ui container">
		#pageHeader("Migrator", "Database Migrations")#

		<cfinclude template="../migrator/_navigation.cfm">
		<cfif datasourceAvailable>
		<cfif arrayLen(availableMigrations)>

			<!--- Migration Status Summary --->
			<cfscript>
			migratedCount = 0;
			pendingCount = 0;
			for (local.mig in availableMigrations) {
				if (local.mig.status EQ "migrated") migratedCount++;
				else pendingCount++;
			}
			</cfscript>
			<div style="display:grid;grid-template-columns:repeat(auto-fill,minmax(160px,1fr));gap:12px;margin-bottom:1.5em;">
				<div style="background:##181825;border:1px solid ##45475a;border-radius:6px;padding:14px 16px;">
					<div style="font-size:10px;font-weight:700;color:##6c7086;text-transform:uppercase;letter-spacing:.5px;">Total</div>
					<div style="font-size:24px;font-weight:700;color:##cdd6f4;margin-top:2px;">#ArrayLen(availableMigrations)#</div>
				</div>
				<div style="background:##181825;border:1px solid ##45475a;border-radius:6px;padding:14px 16px;">
					<div style="font-size:10px;font-weight:700;color:##6c7086;text-transform:uppercase;letter-spacing:.5px;">Migrated</div>
					<div style="font-size:24px;font-weight:700;color:##a6e3a1;margin-top:2px;">#migratedCount#</div>
				</div>
				<div style="background:##181825;border:1px solid ##45475a;border-radius:6px;padding:14px 16px;">
					<div style="font-size:10px;font-weight:700;color:##6c7086;text-transform:uppercase;letter-spacing:.5px;">Pending</div>
					<div style="font-size:24px;font-weight:700;<cfif pendingCount GT 0>color:##f9e2af;<cfelse>color:##a6adc8;</cfif>margin-top:2px;">#pendingCount#</div>
				</div>
				<div style="background:##181825;border:1px solid ##45475a;border-radius:6px;padding:14px 16px;">
					<div style="font-size:10px;font-weight:700;color:##6c7086;text-transform:uppercase;letter-spacing:.5px;">Current Version</div>
					<div style="font-size:13px;font-weight:600;color:##89b4fa;margin-top:6px;font-family:monospace;">#currentVersion#</div>
				</div>
				<cfif ArrayLen(outOfSequenceMigrations)>
				<div style="background:##181825;border:1px solid ##f38ba8;border-radius:6px;padding:14px 16px;">
					<div style="font-size:10px;font-weight:700;color:##f38ba8;text-transform:uppercase;letter-spacing:.5px;">Out of Sequence</div>
					<div style="font-size:24px;font-weight:700;color:##f38ba8;margin-top:2px;">#ArrayLen(outOfSequenceMigrations)#</div>
				</div>
				</cfif>
			</div>

			<!--- Out-of-Sequence Warning Banner --->
			<cfif ArrayLen(outOfSequenceMigrations)>
			<div style="background:##2a1f2e;border:1px solid ##f38ba8;border-radius:8px;padding:16px 20px;margin-bottom:1.5em;">
				<div style="display:flex;align-items:center;gap:10px;margin-bottom:10px;">
					<svg xmlns="http://www.w3.org/2000/svg" height="18" width="18" viewBox="0 0 512 512"><path fill="##f38ba8" d="M256 32c14.2 0 27.3 7.5 34.5 19.8l216 368c7.3 12.4 7.3 27.7 .2 40.1S486.3 480 472 480H40c-14.3 0-27.6-7.7-34.7-20.1s-7-27.8 .2-40.1l216-368C228.7 39.5 241.8 32 256 32zm0 128c-13.3 0-24 10.7-24 24V296c0 13.3 10.7 24 24 24s24-10.7 24-24V184c0-13.3-10.7-24-24-24zm32 224a32 32 0 1 0 -64 0 32 32 0 1 0 64 0z"/></svg>
					<strong style="color:##f38ba8;font-size:14px;">Out-of-Sequence Migrations Detected</strong>
				</div>
				<p style="color:##cdd6f4;margin:0 0 12px;font-size:13px;line-height:1.5;">
					#ArrayLen(outOfSequenceMigrations)# migration<cfif ArrayLen(outOfSequenceMigrations) GT 1>s</cfif>
					exist with version numbers lower than the current database version (#currentVersion#).
					This typically happens when multiple developers create migrations on separate branches.
					These migrations can be run individually if they don't conflict with existing schema.
				</p>
				<div style="display:flex;flex-wrap:wrap;gap:8px;">
					<cfloop array="#outOfSequenceMigrations#" index="oosMig">
						<div class="ui small button violet performmigration"
							data-command="migrateIndividual"
							data-version="#oosMig.version#"
							data-data-url="#urlFor(route='wheelsMigratorCommand', command="migrateIndividual", version='#oosMig.version#')#"
							style="margin:0;">
							Run #oosMig.version# &mdash; #replace(oosMig.name, '_', ' ', 'all')#
						</div>
					</cfloop>
					<cfif ArrayLen(outOfSequenceMigrations) GT 1>
						<div class="ui small button teal runAllOutOfSequence" style="margin:0;">
							Run All Out-of-Sequence
						</div>
					</cfif>
				</div>
			</div>
			</cfif>

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

				<!--- Inline Results Section (replaces modal popup) --->
				<div id="migrationResults" style="display:none;margin-top:16px;">
					<div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:8px;">
						<strong style="color:##cdd6f4;font-size:13px;" id="resultsHeader">Migration Results</strong>
						<div style="display:flex;gap:8px;">
							<button onclick="copyMigrationResults()" class="ui tiny button"
								style="background:##313244;color:##cdd6f4;border:1px solid ##45475a;margin:0;"
								title="Copy to clipboard">
								<svg xmlns="http://www.w3.org/2000/svg" height="12" width="12" viewBox="0 0 448 512" style="margin-right:4px;vertical-align:middle;"><path fill="##cdd6f4" d="M208 0H332.1c12.7 0 24.9 5.1 33.9 14.1l67.9 67.9c9 9 14.1 21.2 14.1 33.9V336c0 26.5-21.5 48-48 48H208c-26.5 0-48-21.5-48-48V48c0-26.5 21.5-48 48-48zM48 128h80v64H64V448H256V416h64v48c0 26.5-21.5 48-48 48H48c-26.5 0-48-21.5-48-48V176c0-26.5 21.5-48 48-48z"/></svg>
								Copy
							</button>
							<button onclick="toggleResultsCollapse()" class="ui tiny button"
								style="background:##313244;color:##cdd6f4;border:1px solid ##45475a;margin:0;"
								id="toggleResultsBtn">
								Collapse
							</button>
							<button onclick="clearResults()" class="ui tiny button"
								style="background:##313244;color:##f38ba8;border:1px solid ##45475a;margin:0;">
								Clear
							</button>
						</div>
					</div>
					<div id="resultsContent">
						<pre id="resultsOutput" style="background:##11111b;border:1px solid ##45475a;border-radius:6px;padding:16px;color:##cdd6f4;font-family:'JetBrains Mono',Consolas,monospace;font-size:12px;line-height:1.6;max-height:500px;overflow-y:auto;white-space:pre-wrap;word-break:break-word;margin:0;user-select:text;-webkit-user-select:text;"></pre>
					</div>
				</div>

				#startTable(title="Available Migrations", colspan=5)#
				<cfloop from="1" to="#arrayLen(availableMigrations)#" index="m">
					<cfscript>
						mig = availableMigrations[m];
						class="";
						hasMigrated=false;
						isOutOfSequence=false;
						if(mig.status EQ "migrated"){
							class="positive";
							hasMigrated=true;
						}
						if(mig.version EQ currentVersion){
							class="active";
						}
						// Check if this is an out-of-sequence migration
						if (!hasMigrated && mig.version < currentVersion) {
							isOutOfSequence = true;
						}
					</cfscript>
					<tr class="#class#"<cfif isOutOfSequence> style="background:##2a1f2e !important;"</cfif>>
						<td>
							<cfif hasMigrated>
								<svg xmlns="http://www.w3.org/2000/svg" height="15px" width="15px" viewBox="0 0 448 512"><path fill="##a6e3a1" d="M438.6 105.4c12.5 12.5 12.5 32.8 0 45.3l-256 256c-12.5 12.5-32.8 12.5-45.3 0l-128-128c-12.5-12.5-12.5-32.8 0-45.3s32.8-12.5 45.3 0L160 338.7 393.4 105.4c12.5-12.5 32.8-12.5 45.3 0z"/></svg>
							<cfelseif isOutOfSequence>
								<svg xmlns="http://www.w3.org/2000/svg" height="15px" width="15px" viewBox="0 0 512 512"><path fill="##f38ba8" d="M256 32c14.2 0 27.3 7.5 34.5 19.8l216 368c7.3 12.4 7.3 27.7 .2 40.1S486.3 480 472 480H40c-14.3 0-27.6-7.7-34.7-20.1s-7-27.8 .2-40.1l216-368C228.7 39.5 241.8 32 256 32zm0 128c-13.3 0-24 10.7-24 24V296c0 13.3 10.7 24 24 24s24-10.7 24-24V184c0-13.3-10.7-24-24-24zm32 224a32 32 0 1 0 -64 0 32 32 0 1 0 64 0z"/></svg>
							<cfelse>
								<div class="ui icon button teal tiny previewsql"
									data-data-url="#urlFor(route='wheelsMigratorSQL', version='#mig.version#')#"
									data-content="Preview SQL">
									<svg xmlns="http://www.w3.org/2000/svg" height="12" width="14" viewBox="0 0 640 512"><path fill="##ffffff" d="M392.8 1.2c-17-4.9-34.7 5-39.6 22l-128 448c-4.9 17 5 34.7 22 39.6s34.7-5 39.6-22l128-448c4.9-17-5-34.7-22-39.6zm80.6 120.1c-12.5 12.5-12.5 32.8 0 45.3L562.7 256l-89.4 89.4c-12.5 12.5-12.5 32.8 0 45.3s32.8 12.5 45.3 0l112-112c12.5-12.5 12.5-32.8 0-45.3l-112-112c-12.5-12.5-32.8-12.5-45.3 0zm-306.7 0c-12.5-12.5-32.8-12.5-45.3 0l-112 112c-12.5 12.5-12.5 32.8 0 45.3l112 112c12.5 12.5 32.8 12.5 45.3 0s12.5-32.8 0-45.3L77.3 256l89.4-89.4c12.5-12.5 12.5-32.8 0-45.3z"/></svg>
								</div>
							</cfif>
						</td>
						<td style="font-family:monospace;font-size:12px;">#mig.version#</td>
						<td>
							#replace(mig.name, '_', ' ', 'all')#
							<cfif isOutOfSequence>
								<span style="display:inline-block;background:##f38ba8;color:##1e1e2e;font-size:10px;font-weight:700;padding:2px 6px;border-radius:3px;margin-left:6px;vertical-align:middle;">OUT OF SEQUENCE</span>
							</cfif>
						</td>
						<td>
							<cfif mig.loadError NEQ "">
								<span style="color:##f38ba8;font-size:12px;" data-content="#EncodeForHTMLAttribute(mig.loadError)#" class="popup-trigger"
									title="#EncodeForHTMLAttribute(mig.loadError)#">Load Error</span>
							<cfelse>
								<span style="color:##6c7086;font-size:12px;">#mig.details#</span>
							</cfif>
						</td>
						<td>
							<cfif isOutOfSequence>
								<div class="ui icon button violet tiny performmigration"
									data-command="migrateIndividual"
									data-version="#mig.version#"
									data-data-url="#urlFor(route='wheelsMigratorCommand', command="migrateIndividual", version='#mig.version#')#"
									data-content="Run this migration individually">
									<svg xmlns="http://www.w3.org/2000/svg" height="12px" width="12px" viewBox="0 0 384 512"><path fill="##ffffff" d="M73 39c-14.8-9.1-33.4-9.4-48.5-.9S0 62.6 0 80V432c0 17.4 9.4 33.4 24.5 41.9s33.7 8.1 48.5-.9L361 297c14.3-8.8 23-24.2 23-41s-8.7-32.2-23-41L73 39z"/></svg>
								</div>
								<div class="ui icon button teal tiny previewsql"
									data-data-url="#urlFor(route='wheelsMigratorSQL', version='#mig.version#')#"
									data-content="Preview SQL">
									<svg xmlns="http://www.w3.org/2000/svg" height="12" width="14" viewBox="0 0 640 512"><path fill="##ffffff" d="M392.8 1.2c-17-4.9-34.7 5-39.6 22l-128 448c-4.9 17 5 34.7 22 39.6s34.7-5 39.6-22l128-448c4.9-17-5-34.7-22-39.6zm80.6 120.1c-12.5 12.5-12.5 32.8 0 45.3L562.7 256l-89.4 89.4c-12.5 12.5-12.5 32.8 0 45.3s32.8 12.5 45.3 0l112-112c12.5-12.5 12.5-32.8 0-45.3l-112-112c-12.5-12.5-32.8-12.5-45.3 0zm-306.7 0c-12.5-12.5-32.8-12.5-45.3 0l-112 112c-12.5 12.5-12.5 32.8 0 45.3l112 112c12.5 12.5 32.8 12.5 45.3 0s12.5-32.8 0-45.3L77.3 256l89.4-89.4c12.5-12.5 12.5-32.8 0-45.3z"/></svg>
								</div>
							<cfelseif !hasMigrated>
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
				<svg xmlns="http://www.w3.org/2000/svg" height="70" width="50" viewBox="0 0 448 512"><path fill="##6c7086" d="M448 73.1v45.7C448 159.1 347.7 192 224 192S0 159.1 0 118.9V73.1C0 32.9 100.3 0 224 0s224 32.9 224 73.1zM448 176v102.9C448 319.1 347.7 352 224 352S0 319.1 0 278.9V176c48.1 33.1 136.2 48.6 224 48.6S399.9 209.1 448 176zm0 160v102.9C448 479.1 347.7 512 224 512S0 479.1 0 438.9V336c48.1 33.1 136.2 48.6 224 48.6S399.9 369.1 448 336z"/></svg><br>
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

	<!--- SQL Preview Modal (kept as modal since it's reference only, not results) --->
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

<cfif get("URLRewriting") eq "Off">
	<cfset method = 'get'>
<cfelse>
	<cfset method = 'post'>
</cfif>
<style>
##migrationResults pre::selection,
##migrationResults pre *::selection {
	background: ##89b4fa;
	color: ##1e1e2e;
}
.migration-running {
	opacity: 0.6;
	pointer-events: none;
}
.migration-spinner {
	display: inline-block;
	width: 14px;
	height: 14px;
	border: 2px solid ##45475a;
	border-top-color: ##89b4fa;
	border-radius: 50%;
	animation: migspin 0.6s linear infinite;
	margin-right: 6px;
	vertical-align: middle;
}
@keyframes migspin {
	to { transform: rotate(360deg); }
}
</style>
<script>
var resultsCollapsed = false;

function showResults(html, label) {
	var container = document.getElementById('migrationResults');
	var output = document.getElementById('resultsOutput');
	var header = document.getElementById('resultsHeader');
	container.style.display = 'block';
	// Strip HTML tags and extract text content for clean output
	var temp = document.createElement('div');
	temp.innerHTML = html;
	// Check if it contains a confirmation prompt (not yet executed)
	var confirmBtn = temp.querySelector('.execute');
	if (confirmBtn) {
		// This is a confirmation step - show it and wire up the execute button
		output.innerHTML = '';
		var msgDiv = temp.querySelector('.ui.red.message');
		if (msgDiv) {
			output.textContent = msgDiv.textContent.trim();
		}
		output.innerHTML += '\n\n';
		var executeBtn = document.createElement('button');
		executeBtn.className = 'ui small button red';
		executeBtn.textContent = 'Confirm & Execute';
		executeBtn.style.cssText = 'margin-top:8px;';
		executeBtn.setAttribute('data-url', confirmBtn.getAttribute('data-data-url'));
		executeBtn.onclick = function() {
			var url = this.getAttribute('data-url');
			this.remove();
			output.textContent = output.textContent.trim() + '\n\nExecuting...\n';
			runMigrationRequest(url, label);
		};
		output.appendChild(executeBtn);
	} else {
		// This is the actual result
		var pre = temp.querySelector('pre');
		if (pre) {
			output.textContent = pre.textContent;
		} else {
			output.textContent = temp.textContent.trim();
		}
	}
	if (label) header.textContent = label;
	container.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
}

function runMigrationRequest(url, label) {
	var output = document.getElementById('resultsOutput');
	var container = document.getElementById('migrationResults');
	container.style.display = 'block';
	output.textContent = 'Running migration...\n';
	if (label) document.getElementById('resultsHeader').textContent = label;

	var xhr = new XMLHttpRequest();
	xhr.open('#method#', url, true);
	xhr.onload = function() {
		if (xhr.status >= 200 && xhr.status < 300) {
			showResults(xhr.responseText, label);
		} else {
			output.textContent = 'Error: HTTP ' + xhr.status + '\n' + xhr.responseText;
		}
	};
	xhr.onerror = function() {
		output.textContent = 'Network error occurred.';
	};
	xhr.send();
}

function copyMigrationResults() {
	var output = document.getElementById('resultsOutput');
	var text = output.textContent || output.innerText;
	if (navigator.clipboard) {
		navigator.clipboard.writeText(text).then(function() {
			// Brief visual feedback
			var btn = document.querySelector('[onclick="copyMigrationResults()"]');
			var orig = btn.innerHTML;
			btn.innerHTML = '<svg xmlns="http://www.w3.org/2000/svg" height="12" width="12" viewBox="0 0 448 512" style="margin-right:4px;vertical-align:middle;"><path fill="##a6e3a1" d="M438.6 105.4c12.5 12.5 12.5 32.8 0 45.3l-256 256c-12.5 12.5-32.8 12.5-45.3 0l-128-128c-12.5-12.5-12.5-32.8 0-45.3s32.8-12.5 45.3 0L160 338.7 393.4 105.4c12.5-12.5 32.8-12.5 45.3 0z"/></svg>Copied';
			setTimeout(function() { btn.innerHTML = orig; }, 1500);
		});
	} else {
		// Fallback for older browsers
		var range = document.createRange();
		range.selectNodeContents(output);
		var sel = window.getSelection();
		sel.removeAllRanges();
		sel.addRange(range);
		document.execCommand('copy');
	}
}

function toggleResultsCollapse() {
	var content = document.getElementById('resultsContent');
	var btn = document.getElementById('toggleResultsBtn');
	resultsCollapsed = !resultsCollapsed;
	content.style.display = resultsCollapsed ? 'none' : 'block';
	btn.textContent = resultsCollapsed ? 'Expand' : 'Collapse';
}

function clearResults() {
	document.getElementById('migrationResults').style.display = 'none';
	document.getElementById('resultsOutput').textContent = '';
}

$(document).ready(function() {

// SQL Preview (still uses modal since it's reference info)
$(".previewsql").on("click", function(e){
	var url = $(this).data("data-url");
	$.ajax({
		url: url,
		method: 'get'
	})
	.done(function(data) {
		var res = $(".previewsqlmodal > .content");
		res.html(data);
		$('.ui.modal.longer.previewsqlmodal')
			.modal({
				onVisible: function(){
					if (typeof hljs !== 'undefined') hljs.initHighlightingOnLoad();
				}
			})
			.modal('show');
		if (typeof hljs !== 'undefined') hljs.initHighlightingOnLoad();
	});
});

// Migration execution - now inline instead of modal
$(".performmigration").on("click", function(e){
	if ($(this).hasClass('disabled')) return;
	var url = $(this).data("data-url");
	var btn = $(this);
	var label = 'Migration Results';

	// Build a descriptive label
	var version = btn.data('version');
	var command = btn.data('command');
	if (command === 'migrateIndividual' && version) {
		label = 'Individual Migration: ' + version;
	} else if (btn.text().trim().indexOf('Latest') >= 0) {
		label = 'Migrate To Latest';
	} else if (btn.text().trim().indexOf('Reset') >= 0) {
		label = 'Reset Database';
	} else if (btn.text().trim().indexOf('Missing') >= 0) {
		label = 'Missing Migrations';
	}

	runMigrationRequest(url, label);
});

// Run All Out-of-Sequence button
$(".runAllOutOfSequence").on("click", function(e) {
	var oosButtons = $(".performmigration[data-command='migrateIndividual']");
	if (oosButtons.length === 0) return;

	var output = document.getElementById('resultsOutput');
	var container = document.getElementById('migrationResults');
	container.style.display = 'block';
	document.getElementById('resultsHeader').textContent = 'Running All Out-of-Sequence Migrations';
	output.textContent = 'Running ' + oosButtons.length + ' out-of-sequence migration(s)...\n\n';

	var urls = [];
	oosButtons.each(function() {
		urls.push({
			url: $(this).data('data-url'),
			version: $(this).data('version')
		});
	});

	// Run sequentially to avoid conflicts
	function runNext(index) {
		if (index >= urls.length) {
			output.textContent += '\n--- All out-of-sequence migrations complete ---\n';
			output.textContent += 'Reload the page to see updated status.\n';
			return;
		}
		var item = urls[index];
		// First request gets the confirmation
		output.textContent += 'Migration ' + item.version + '...\n';
		var xhr = new XMLHttpRequest();
		xhr.open('#method#', item.url, true);
		xhr.onload = function() {
			// Parse response for confirm URL
			var temp = document.createElement('div');
			temp.innerHTML = xhr.responseText;
			var confirmBtn = temp.querySelector('.execute');
			if (confirmBtn) {
				var confirmUrl = confirmBtn.getAttribute('data-data-url');
				// Execute the confirmed migration
				var xhr2 = new XMLHttpRequest();
				xhr2.open('#method#', confirmUrl, true);
				xhr2.onload = function() {
					var temp2 = document.createElement('div');
					temp2.innerHTML = xhr2.responseText;
					var pre = temp2.querySelector('pre');
					if (pre) {
						output.textContent += pre.textContent + '\n';
					} else {
						output.textContent += temp2.textContent.trim() + '\n';
					}
					runNext(index + 1);
				};
				xhr2.onerror = function() {
					output.textContent += 'Error running migration ' + item.version + '\n';
					runNext(index + 1);
				};
				xhr2.send();
			} else {
				// Direct result (no confirmation needed)
				var pre = temp.querySelector('pre');
				if (pre) {
					output.textContent += pre.textContent + '\n';
				} else {
					output.textContent += temp.textContent.trim() + '\n';
				}
				runNext(index + 1);
			}
		};
		xhr.onerror = function() {
			output.textContent += 'Network error for migration ' + item.version + '\n';
			runNext(index + 1);
		};
		xhr.send();
	}
	runNext(0);
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
