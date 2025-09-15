<cfscript>
// Check for JSON format request
param name="request.wheels.params.format" default="html";

system = CreateObject("java", "java.lang.System");

applicationMeta = getApplicationMetadata();
paths = [
	'eventPath',
	'filePath',
	'imagePath',
	'javascriptPath',
	'modelPath',
	'pluginPath',
	'pluginComponentPath',
	'stylesheetPath',
	'viewPath',
	'controllerPath',
	'assetQueryString',
	'assetPaths'
];

components = ['enablePluginsComponent', 'enableMigratorComponent', 'enablePublicComponent'];
environment = [
	'hostName',
	'environment',
	'allowEnvironmentSwitchViaUrl',
	'redirectAfterReload',
	'ipExceptions',
	'showDebugInformation',
	'urlRewriting'
];

csrf = [
	'csrfStore',
	'csrfCookieEncryptionAlgorithm',
	'csrfCookieEncryptionSecretKey',
	'csrfCookieEncryptionEncoding',
	'csrfCookieName',
	'csrfCookieDomain',
	'csrfCookieEncodeValue',
	'csrfCookieHttpOnly',
	'csrfCookiePath',
	'csrfCookiePreserveCase',
	'csrfCookieSecure'
];

cors = [
	'allowCorsRequests',
	'accessControlAllowOrigin',
	'accessControlAllowMethods',
	'accessControlAllowMethodsByRoute',
	'accessControlAllowCredentials',
	'accessControlAllowHeaders'
];


settings = [
	{
		name = 'Error Handling',
		values = [
			// 'errorEmailServer' // Check this
			'errorEmailAddress',
			'errorEmailSubject',
			'excludeFromErrorEmail',
			'sendEmailOnError',
			'showErrorInformation'
		]
	},
	{
		name = 'Caching',
		values = [
			// 'cacheRoutes' // Check this
			'cacheActions',
			'cacheControllerConfig',
			'cacheCullInterval',
			'cacheCullPercentage',
			'cacheDatabaseSchema',
			'cacheDatePart',
			'cacheFileChecking',
			'cacheImages',
			'cacheModelConfig',
			'cachePages',
			'cachePartials',
			'cacheQueries',
			'cacheQueriesDuringRequest',
			'clearQueryCacheOnReload',
			'defaultCacheTime',
			'maximumItemsToCache'
		]
	},
	{
		name = 'Migrator',
		values = [
			'autoMigrateDatabase',
			'migratorTableName',
			'createMigratorTable',
			'writeMigratorSQLFiles',
			'migratorObjectCase',
			'allowMigrationDown'
		]
	},
	{
		name = 'Plugins',
		values = [
			'deletePluginDirectories',
			'loadIncompatiblePlugins',
			'overwritePlugins',
			'showIncompatiblePlugins'
		]
	},
	{
		name = 'Models',
		values = [
			// 'afterFindCallbackLegacySupport' // Check
			'automaticValidations',
			'setUpdatedAtOnCreate',
			'softDeleteProperty',
			'tableNamePrefix',
			'timeStampOnCreateProperty',
			'timeStampOnUpdateProperty',
			'transactionMode',
			'useExpandedColumnAliases',
			'modelRequireConfig'
		]
	},
	{
		name = 'Other',
		values = [
			// 'loadDefaultRoutes' Check
			'obfuscateUrls',
			'booleanAttributes',
			// ,'disableEngineCheck'
			'encodeURLs',
			'encodeHtmlTags',
			'encodeHtmlAttributes',
			'uncountables',
			'irregulars',
			'flashAppend',
			'formats',
			'mimetypes'
		]
	}
];

// If JSON format is requested, build and return JSON response
if (request.wheels.params.format == "json") {
	local.infoData = {
		"version": get("version"),
		"timestamp": now(),
		"application": {
			"name": application.applicationName,
			"metadata": applicationMeta
		},
		"server": {
			"cfmlEngine": get("serverName") & " " & get("serverVersion"),
			"wheelsVersion": get("version"),
			"javaRuntime": system.getProperty("java.runtime.name"),
			"javaVersion": system.getProperty("java.version")
		},
		"paths": {},
		"components": {},
		"environment": {},
		"csrf": {},
		"cors": {},
		"settings": {}
	};

	// Collect path settings
	for (local.path in paths) {
		if (isDefined("application.wheels." & local.path)) {
			local.infoData.paths[local.path] = $get(local.path);
		}
	}

	// Collect component settings
	for (local.comp in components) {
		if (isDefined("application.wheels." & local.comp)) {
			local.infoData.components[local.comp] = $get(local.comp);
		}
	}

	// Collect environment settings
	for (local.env in environment) {
		if (isDefined("application.wheels." & local.env)) {
			local.infoData.environment[local.env] = $get(local.env);
		}
	}

	// Collect CSRF settings
	for (local.csrfSetting in csrf) {
		if (isDefined("application.wheels." & local.csrfSetting)) {
			// Don't expose secret keys in JSON
			if (local.csrfSetting != "csrfCookieEncryptionSecretKey") {
				local.infoData.csrf[local.csrfSetting] = $get(local.csrfSetting);
			}
		}
	}

	// Collect CORS settings
	for (local.corsSetting in cors) {
		if (isDefined("application.wheels." & local.corsSetting)) {
			local.infoData.cors[local.corsSetting] = $get(local.corsSetting);
		}
	}

	// Collect other settings
	for (local.settingGroup in settings) {
		local.groupName = local.settingGroup.name;
		local.infoData.settings[local.groupName] = {};
		for (local.settingName in local.settingGroup.values) {
			if (isDefined("application.wheels." & local.settingName)) {
				local.infoData.settings[local.groupName][local.settingName] = $get(local.settingName);
			}
		}
	}

	// Get database info
	try {
		local.db = $$getAllDatabaseInformation();
		local.infoData.database = {
			"datasourceName": local.db.datasource.name,
			"database": local.db.datasource.database_productname,
			"version": local.db.datasource.database_version,
			"driver": local.db.datasource.driver_name,
			"driverVersion": local.db.datasource.driver_version
		};
	} catch (any e) {
		local.infoData.database = {"error": e.message};
	}

	// Output JSON and abort
	cfcontent(type="application/json", reset=true);
	writeOutput(serializeJSON(local.infoData));
	abort;
}
</cfscript>

<cfinclude template="../layout/_header.cfm">

<cfoutput>
	<!--- cfformat-ignore-start --->
	<div class="ui container">
		#pageHeader("System Information", "Note, these settings reflect the currently loaded environment")#

		<div class="ui top attached tabular menu stackable flex-wrap">
			<a class="item active" data-tab="system">System</a>
			<a class="item" data-tab="security">Security</a>
			<cfloop from="1" to="#ArrayLen(settings)#" index="s">
				<a class="item" data-tab="tab-#s#">#settings[s]['name']#</a>
			</cfloop>
			<a class="item" data-tab="utils">Utils</a>
		</div>
		#startTab(tab = 'system', active = true)#

		#startTable("Application")#
		<tr>
			<td class='four wide'>Application Name</td>
			<td class='eight wide'>
				#application.applicationName#
				<cfif NOT Len($get("reloadPassword"))>
					[<a href="?reload">Reload</a>]
				</cfif>
			</td>
		</tr>
		#endTable()#

		#startTable("Server")#
		<tr>
			<td class='four wide'>CFML Engine</td>
			<td class='eight wide'>#get("serverName")# #get("serverVersion")#</td>
		</tr>
		<tr>
			<td>Wheels Version</td>
			<td>#get("version")#</td>
		</tr>
		<tr>
			<td>Java Runtime</td>
			<td>#system.getProperty("java.runtime.name")#</td>
		</tr>
		<tr>
			<td>Java Version</td>
			<td>#system.getProperty("java.version")#</td>
		</tr>
		#endTable()#

		#startTable("Database")#

		<cfscript>
		try {
			db = $$getAllDatabaseInformation();
		} catch (any e) {
			dbError = e;
		}
		</cfscript>

		<tr>
			<td class='four wide'>Datasource Name</td>
			<td class='eight wide'>#get("dataSourceName")#</td>
		</tr>

		<cfif IsDefined("dbError")>
			<tr>
				<td colspan="2">
					<div class="ui error message">
						<div class="header">#dbError.message#</div>
						#dbError.detail#
					</div>
				</td>
			</tr>
		<cfelse>
			<tr>
				<td>Migrator Adapter Name</td>
				<td>#db.adapterName#</td>
			</tr>
			<tr>
				<td>Product Name</td>
				<td>#db.info.database_productName#</td>
			</tr>
			<tr>
				<td>Version</td>
				<td>#db.info.database_version#</td>
			</tr>
			<tr>
				<td>Driver Name</td>
				<td>#db.info.driver_name#</td>
			</tr>
			<tr>
				<td>Driver Version</td>
				<td>#db.info.driver_version#</td>
			</tr>
			<tr>
				<td>JDBC Version</td>
				<td>#db.info.jdbc_major_version#.#db.info.jdbc_minor_version#</td>
			</tr>
		</cfif>
		#endTable()#

		#startTable("Environment")#
		#outputSetting(environment)#
		#endTable()#

		#startTable("Mappings")#
			<cfloop collection="#applicationMeta.mappings#" item="key">
			<tr>
				<td class='four wide'>#Key#</td>
				<td class='eight wide'>#applicationMeta.mappings[key]#</td>
			</tr>
			</cfloop>
		#endTable()#

		#startTable("Paths")#
		#outputSetting(paths)#
		#endTable()#

		#startTable("Components")#
		#outputSetting(components)#
		#endTable()#

		#endTab()#

		#startTab(tab = 'security')#

		#startTable("CSRF")#
		#outputSetting(csrf)#
		#endTable()#

		#startTable("CORS")#
		#outputSetting(cors)#
		#endTable()#

		#endTab()#

		<cfloop from="1" to="#ArrayLen(settings)#" index="s">
			#startTab(tab = 'tab-#s#')#
			#startTable(settings[s]['name'])#
			#outputSetting(settings[s]['values'])#
			#endTable()#
			#endTab()#
		</cfloop>

		#startTab(tab = 'utils')#
		<div class="ui two column grid">
			<div class="column">
				<div class="ui card fluid">
					<div class="content">
						<div class="header">Documentation</div>
						<div class="description">
							<p>Download generated documentation as JSON</p>
							<a href="#urlFor(route = "wheelsApiDocs", params = "format=json")#" target="_blank" ,>
								<svg xmlns="http://www.w3.org/2000/svg" height="16" width="16" viewBox="0 0 512 512"><path d="M216 0h80c13.3 0 24 10.7 24 24v168h87.7c17.8 0 26.7 21.5 14.1 34.1L269.7 378.3c-7.5 7.5-19.8 7.5-27.3 0L90.1 226.1c-12.6-12.6-3.7-34.1 14.1-34.1H192V24c0-13.3 10.7-24 24-24zm296 376v112c0 13.3-10.7 24-24 24H24c-13.3 0-24-10.7-24-24V376c0-13.3 10.7-24 24-24h146.7l49 49c20.1 20.1 52.5 20.1 72.6 0l49-49H488c13.3 0 24 10.7 24 24zm-124 88c0-11-9-20-20-20s-20 9-20 20 9 20 20 20 20-9 20-20zm64 0c0-11-9-20-20-20s-20 9-20 20 9 20 20 20 20-9 20-20z"/></svg>
								Export Docs as JSON
							</a>
						</div>
					</div>
				</div>
			</div>
			<div class="column">
				<div class="ui card fluid">
					<div class="content">
						<div class="header">Build Release</div>
						<div class="description">
							<p>Build a zip for production distribution</p>
							<a href="#urlFor(route = "wheelsBuild")#" target="_blank">
								<svg xmlns="http://www.w3.org/2000/svg" height="16" width="16" viewBox="0 0 512 512"><path d="M32 32H480c17.7 0 32 14.3 32 32V96c0 17.7-14.3 32-32 32H32C14.3 128 0 113.7 0 96V64C0 46.3 14.3 32 32 32zm0 128H480V416c0 35.3-28.7 64-64 64H96c-35.3 0-64-28.7-64-64V160zm128 80c0 8.8 7.2 16 16 16H336c8.8 0 16-7.2 16-16s-7.2-16-16-16H176c-8.8 0-16 7.2-16 16z"/></svg>
								Create Zip
							</a>
						</div>
					</div>
				</div>
			</div>
		</div>
		#endTab()#
	</div>
	<!--/container-->

	<cfinclude template="../layout/_footer.cfm">
	<!--- cfformat-ignore-end --->
</cfoutput>
