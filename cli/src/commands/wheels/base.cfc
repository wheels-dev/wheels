/**
 * Base CFC: Everything extends from here.
 **/
component excludeFromHelp=true {
	property name='serverService' inject='ServerService';
	property name='Formatter'     inject='Formatter';
	property name='Helpers'       inject='helpers@wheels-cli';
	property name='packageService' inject='packageService';
	property name="ConfigService" inject="ConfigService";
	property name="JSONService" inject="JSONService";

//=====================================================================
//= 	Scaffolding
//=====================================================================

	// Try and get wheels version from box.json: otherwise, go ask.
	// alternative is to get via /wheels/events/onapplicationstart.cfm but that feels a bit hacky.
	// we could also test for the existence of /wheels/dbmigrate, but that only gives us the major version.
	string function $getWheelsVersion(){
		// Determine which directory structure we're in
		local.currentPath = getCWD();
		local.wheelsPath = "";
		local.boxJsonPath = "";
		
		// Check if we're in a running wheels app (vendor/wheels structure)
		if(isWheelsApp(getCWD())) {
			local.wheelsPath = fileSystemUtil.resolvePath("vendor/wheels");
			local.boxJsonPath = fileSystemUtil.resolvePath("vendor/wheels/box.json");
			local.rootJson = fileSystemUtil.resolvePath("box.json");
		}
		// Check if we're in wheels source structure (core/src/wheels)
		else if(isWheelsInstall(getCWD())) {
			local.wheelsPath = fileSystemUtil.resolvePath("core/src/wheels");
			local.boxJsonPath = fileSystemUtil.resolvePath("core/src/wheels/box.json");
			local.rootJson = fileSystemUtil.resolvePath("template/base/src/box.json");
		}
		// If neither structure is detected, throw an error
		else {
			error("We're currently looking in #getCWD()#, can't find a valid wheels directory structure. Are you sure you are in the correct root directory?");
		}
		
		// Verify the wheels directory exists
		if(!directoryExists(local.wheelsPath)) {
			error("We're currently looking in #getCWD()#, can't find the wheels folder at #local.wheelsPath#. Are you sure you are in the correct root?");
		}
		
		// Check wheels box.json first for wheels-core version
		if(fileExists(local.boxJsonPath)){
			local.wheelsBoxJSON = packageService.readPackageDescriptorRaw(local.wheelsPath);
			if(structKeyExists(local.wheelsBoxJSON, "version")){
				return local.wheelsBoxJSON.version;
			}
		}
		
		// Check root box.json
		if(fileExists(local.rootJson)){
			local.boxJSON = packageService.readPackageDescriptorRaw( getCWD() );
			// Check if wheels-core is in dependencies
			if(structKeyExists(local.boxJSON, "dependencies") && structKeyExists(local.boxJSON.dependencies, "wheels-core")){
				// Extract version from dependency string like "^3.0.0-SNAPSHOT+695"
				local.wheelsDep = local.boxJSON.dependencies["wheels-core"];
				local.wheelsDep = reReplace(local.wheelsDep, "[\^~>=<]", "", "all");
				return local.wheelsDep;
			}
			return local.boxJSON.version;
		}
		// Check for onapplicationstart.cfm method (adjust path based on structure)
		else if(isWheelsApp() && fileExists(fileSystemUtil.resolvePath("app/events/onapplicationstart.cfm"))) {
			// For running app structure
			local.target = fileSystemUtil.resolvePath("app/events/onapplicationstart.cfm");
			local.content = fileRead(local.target);
			local.content = listFirst(mid(local.content, (find('application.$wheels.version', local.content) + 31), 20), '"');
			return local.content;
		}
		else if(isWheelsInstall() && fileExists(fileSystemUtil.resolvePath("templates/base/src/app/events/onapplicationstart.cfm"))) {
			// For wheels source structure
			local.target = fileSystemUtil.resolvePath("templates/base/src/app/events/onapplicationstart.cfm");
			local.content = fileRead(local.target);
			local.content = listFirst(mid(local.content, (find('application.$wheels.version', local.content) + 31), 20), '"');
			return local.content;
		}
		else {
			print.line("You don't have a box.json, so we don't know which version of wheels this is.");
			print.line("We're currently looking in #getCWD()#");
			if(confirm("Would you like to try and create one? [y/n]")){
				local.version = ask("Which Version is it? Please enter your response in semVar format, i.e '1.4.5'");
				command('init').params(name="WHEELS", version=local.version, slugname="wheels").run();
				return local.version;
			} else {
				error("Ok, aborting");
			}
		}
	}

	//Use this function for commands that should work Only if the application is running
	boolean function isWheelsApp(string path = getCWD()) {
		// Check for vendor/wheels folder
		if (!directoryExists(arguments.path & "/vendor/wheels")) {
			return false;
		}
		// Check for config folder
		if (!directoryExists(arguments.path & "/config")) {
			return false;
		}
		// Check for app folder
		if (!directoryExists(arguments.path & "/app")) {
			return false;
		}
		return true;
	}

	// Use this function for commands that should work even if the application is not running
	boolean function isWheelsInstall(string path = getCWD()) {
		// Check for /core/src/wheels folder
		if (!directoryExists(arguments.path & "/core/src/wheels")) {
			return false;
		}
		// Check for config folder
		if (!directoryExists(arguments.path & "/templates/base/src/config")) {
			return false;
		}
		// Check for app folder
		if (!directoryExists(arguments.path & "/templates/base/src/app")) {
			return false;
		}
		return true;
	}

	/**
	* Checks whether the current Wheels version matches the provided version.
	* @version The version to compare against. Accepts "2", "2.0", "2.0.1", etc.
	* @scope One of "major", "minor", or "patch"
	*/
	boolean function $isWheelsVersion(required any version, string scope="major") {
		var current = listToArray($getWheelsVersion(), ".");
		var compare = listToArray(arguments.version, ".");

		// Fill missing parts with 0s
		while (arrayLen(current) < 3) {
			arrayAppend(current, "0");
		}
		while (arrayLen(compare) < 3) {
			arrayAppend(compare, "0");
		}

		switch (scope) {
			case "major":
				return compare[1] == current[1];
			case "minor":
				return compare[1] == current[1] && compare[2] == current[2];
			case "patch":
				return compare[1] == current[1] && compare[2] == current[2] && compare[3] == current[3];
			default:
				return false;
		}
	}


	/**
	 * Prompt user for confirmation
	 * @message The message to display
	 * @defaultResponse Default response if non-interactive
	 */
	boolean function confirm(required string message, boolean defaultResponse = false) {
		// Check if we're in non-interactive mode
		if (structKeyExists(shell, "getNonInteractiveFlag") && shell.getNonInteractiveFlag()) {
			return arguments.defaultResponse;
		}
		
		// Try to use shell's ask method
		try {
			var response = shell.ask(arguments.message);
			return (lCase(left(trim(response), 1)) == "y");
		} catch (any e) {
			// If we can't interact, return default
			return arguments.defaultResponse;
		}
	}

	// Replace default objectNames
	string function $replaceDefaultObjectNames(required string content,required struct obj){
		local.rv=arguments.content;
		local.rv 	 = replaceNoCase( local.rv, '|ObjectNameSingular|', obj.objectNameSingular, 'all' );
		local.rv 	 = replaceNoCase( local.rv, '|ObjectNamePlural|',   obj.objectNamePlural, 'all' );
		local.rv 	 = replaceNoCase( local.rv, '|ObjectNameSingularC|', obj.objectNameSingularC, 'all' );
		local.rv 	 = replaceNoCase( local.rv, '|ObjectNamePluralC|',   obj.objectNamePluralC, 'all' );
		return local.rv;
	}

    // Inject CLI content into template
    function $injectIntoView(required struct objectNames, required string property, required string type, string action="input"){
        if(arguments.action EQ "input"){
            local.target=fileSystemUtil.resolvePath("app/views/#objectNames.objectNamePlural#/_form.cfm");
            local.inject=$generateFormField(objectname=objectNames.objectNameSingular, property=arguments.property, type=arguments.type);
        } else if(arguments.action EQ "output"){
            local.target=fileSystemUtil.resolvePath("app/views/#objectNames.objectNamePlural#/show.cfm");
            local.inject=$generateOutputField(objectname=objectNames.objectNameSingular, property=arguments.property, type=arguments.type);
        }
        local.content=fileRead(local.target);
        // inject into position CLI-Appends-Here
        local.content = replaceNoCase(local.content, '<!--- CLI-Appends-Here --->', local.inject & cr & '<!--- CLI-Appends-Here --->', 'all');
        // Replace tokens with ## tags
        local.content = Replace(local.content, "~[~", "##", "all");
        local.content = Replace(local.content, "~]~", "##", "all");
        // Finally write out the file
        file action='write' file='#local.target#' mode ='777' output='#trim(local.content)#';
    }

    // Inject CLI content into index template
    function $injectIntoIndex(required struct objectNames, required string property, required string type){
        local.target=fileSystemUtil.resolvePath("app/views/#objectNames.objectNamePlural#/index.cfm");
        local.thead="					<th>#helpers.capitalize(arguments.property)#</th>";
        local.tbody="					<td>" & cr & "						~[~#arguments.property#~]~" & cr & "					</td>";

        local.content=fileRead(local.target);
        // inject into position CLI-Appends-Here
        local.content = replaceNoCase(local.content, '                    <!--- CLI-Appends-thead-Here --->', local.thead & cr & '                    <!--- CLI-Appends-thead-Here --->', 'all');
        local.content = replaceNoCase(local.content, '                    <!--- CLI-Appends-tbody-Here --->', local.tbody & cr & '                    <!--- CLI-Appends-tbody-Here --->', 'all');
        // Replace tokens with ## tags
        local.content = Replace(local.content, "~[~", "##", "all");
        local.content = Replace(local.content, "~]~", "##", "all");
        // Finally write out the file
        file action='write' file='#local.target#' mode ='777' output='#trim(local.content)#';
    }

    // Returns contents for a default (non crud) action
    function $returnAction(required string name, string hint=""){
    	var rv="";
    	var name = trim(arguments.name);
    	var hint = trim(arguments.hint);

    	rv = fileRead( getTemplateDirectory() & '/ActionContent.txt' );

    	if(len(hint) == 0){
    		hint = name;
    	}

		rv = replaceNoCase( rv, '|ActionHint|', hint, 'all' );
		rv = replaceNoCase( rv, '|Action|', name, 'all' ) & cr & cr;
        return rv;
    }

	// Default output for show.cfm:
 	function $generateOutputField(required string objectName, required string property, required string type){
		var rv="<p><strong>#helpers.capitalize(property)#</strong><br />~[~";
		switch(type){
			// Return a checkbox
			case "boolean":
				rv&="yesNoFormat(#objectName#.#property#)";
			break;
			// Return a calendar
			case "date":
				rv&="dateFormat(#objectName#.#property#)";
			break;
			// Return a time picker
			case "time":
				rv&="timeFormat(#objectName#.#property#)";
			break;
			// Return a calendar and time picker
			case "datetime":
			case "timestamp":
				rv&="dateTimeFormat(#objectName#.#property#)";
			break;
			// Return a text field if everything fails, i.e assume string
			// Let's escape the output to be safe
			default:
				rv&="encodeForHTML(#objectName#.#property#)";
			break;
		}
		rv&="~]~</p>";
		return rv;
 	}

 	function $generateFormField(required string objectName, required string property, required string type){
		var rv="";
		switch(type){
			// Return a checkbox
			case "boolean":
				rv="checkbox(objectName='#objectName#', property='#property#')";
			break;
			// Return a textarea
			case "text":
				rv="textArea(objectName='#objectName#', property='#property#')";
			break;
			// Return a calendar
			case "date":
				rv="dateSelect(objectName='#objectName#', property='#property#')";
			break;
			// Return a time picker
			case "time":
				rv="timeSelect(objectName='#objectName#', property='#property#')";
			break;
			// Return a calendar and time picker
			case "datetime":
			case "timestamp":
				rv="dateTimeSelect(objectName='#objectName#', property='#property#')";
			break;
			// Return a text field if everything fails, i.e assume string
			default:
				rv="textField(objectName='#objectName#', property='#property#')";
			break;
		}
		// We need to make these rather unique incase the view file has *any* pre-existing
		rv = "~[~" & rv & "~]~";
		return rv;
 	}
//=====================================================================
//= 	DB Migrate
//=====================================================================
	// Before we can even think about using DBmigrate, we've got to check a few things
	function $preConnectionCheck(){
		var serverJSON=fileSystemUtil.resolvePath("server.json");
 			if(!fileExists(serverJSON)){
 				error("We really need a server.json with a port number and a servername. We can't seem to find it.");
 			}

		// Wheels folder in expected place? (just a good check to see if the user has actually installed wheels...)
 		var wheelsFolder=fileSystemUtil.resolvePath("core/src/wheels");
 			if(!isWheelsApp()){
 				error("We can't find your wheels folder. Check you have installed Wheels, and you're running this from the site root: If you've not started an app yet, try wheels new myApp");
 			}

			 // Plugins in place?
 		var pluginsFolder=fileSystemUtil.resolvePath("app/plugins");
 			if(!directoryExists(pluginsFolder)){
 				error("We can't find your plugins folder. Check you have installed Wheels, and you're running this from the site root.");
 			}

			 // Wheels 1.x requires dbmigrate plugin
 		// Wheels 2.x has dbmigrate + dbmigratebridge equivalents in core
 		if($isWheelsVersion(1, "major")){

 			var DBMigratePluginLocation=fileSystemUtil.resolvePath("app/plugins/dbmigrate");
 			if(!directoryExists(DBMigratePluginLocation)){
 				error("We can't find your plugins/dbmigrate folder? Please check the plugin is successfully installed; if you've not started the server using server start for the first time, this folder may not be created yet.");
 			}

			var DBMigrateBridgePluginLocation=fileSystemUtil.resolvePath("app/plugins/dbmigratebridge");
 			if(!directoryExists(DBMigrateBridgePluginLocation)){
 				error("We can't find your plugins/dbmigratebridge folder? Please check the plugin is successfully installed;  if you've not started the server using server start for the first time, this folder may not be created yet.");
 			}
 		}

	}

	// Get information about the currently running server so we can send commmands
	function $getServerInfo(){
		// First, try to read port from server.json if it exists
		var serverJSON = fileSystemUtil.resolvePath("server.json");
		if (fileExists(serverJSON)) {
			try {
				var serverConfig = deserializeJSON(fileRead(serverJSON));

				// Check for port in web.http.port (new format)
				if (structKeyExists(serverConfig, "web") && structKeyExists(serverConfig.web, "http") && structKeyExists(serverConfig.web.http, "port") && serverConfig.web.http.port > 0) {
					local.port = serverConfig.web.http.port;
					local.host = structKeyExists(serverConfig.web, "host") ? serverConfig.web.host : "localhost";

					// If host is "localhost", convert to 127.0.0.1 for consistency
					if (local.host == "localhost") {
						local.host = "127.0.0.1";
					}

					local.serverURL = "http://" & local.host & ":" & local.port;
					return local;
				}

				// Check for port in web.port (legacy format)
				if (structKeyExists(serverConfig, "web") && structKeyExists(serverConfig.web, "port") && serverConfig.web.port > 0) {
					local.port = serverConfig.web.port;
					local.host = structKeyExists(serverConfig.web, "host") ? serverConfig.web.host : "localhost";

					// If host is "localhost", convert to 127.0.0.1 for consistency
					if (local.host == "localhost") {
						local.host = "127.0.0.1";
					}

					local.serverURL = "http://" & local.host & ":" & local.port;
					return local;
				}

				// Also check for port directly in server config root
				if (structKeyExists(serverConfig, "port") && serverConfig.port > 0) {
					local.port = serverConfig.port;
					local.host = structKeyExists(serverConfig, "host") ? serverConfig.host : "localhost";

					// If host is "localhost", convert to 127.0.0.1 for consistency
					if (local.host == "localhost") {
						local.host = "127.0.0.1";
					}

					local.serverURL = "http://" & local.host & ":" & local.port;
					return local;
				}
			} catch (any e) {
				// Continue to fallback
			}
		}

		// Try to get server status using box server status command
		try {
			var serverStatusResult = command("server status").params(getCWD()).run(returnOutput=true);

			// Parse the output to find the port
			// Looking for pattern like "http://127.0.0.1:63155" or "(running)  http://127.0.0.1:63155"
			var portMatch = reFindNoCase("https?://[^:]+:(\d+)", serverStatusResult, 1, true);
			if (arrayLen(portMatch.pos) >= 2 && portMatch.pos[2] > 0) {
				local.port = mid(serverStatusResult, portMatch.pos[2], portMatch.len[2]);

				// Extract host from the same match
				var hostMatch = reFindNoCase("https?://([^:]+):", serverStatusResult, 1, true);
				if (arrayLen(hostMatch.pos) >= 2 && hostMatch.pos[2] > 0) {
					local.host = mid(serverStatusResult, hostMatch.pos[2], hostMatch.len[2]);
				} else {
					local.host = "127.0.0.1";
				}

				local.serverURL = "http://" & local.host & ":" & local.port;
				return local;
			}

			// Check if server is not running
			if (findNoCase("stopped", serverStatusResult) || findNoCase("not running", serverStatusResult)) {
				error("Server is not running. Please start the server using 'box server start' before running database migrations.");
			}
		} catch (any e) {
			// Continue to next fallback
		}

		// Fall back to original method
		var serverDetails = serverService.resolveServerDetails( serverProps={ webroot=getCWD() } );

		// Check if we got a valid port from serverService
		if (structKeyExists(serverDetails, "serverInfo") && structKeyExists(serverDetails.serverInfo, "port") && serverDetails.serverInfo.port > 0) {
			local.host = serverDetails.serverInfo.host;
			local.port = serverDetails.serverInfo.port;
			local.serverURL = "http://" & local.host & ":" & local.port;
			return local;
		}

		// If we still don't have a valid port, throw an error
		error("Unable to determine server port. Please ensure your server is running or that server.json contains a valid port configuration.");
	}

	// Construct remote URL depending on wheels version
	string function $getBridgeURL() {
		var serverInfo=$getServerInfo();
		var geturl=serverInfo.serverUrl;

		// Don't add /public if server is already using public as webroot
		// This is determined by checking server.json configuration
		var serverJSON = fileSystemUtil.resolvePath("server.json");
		var addPublic = false;

		if (fileExists(serverJSON)) {
			try {
				var serverConfig = deserializeJSON(fileRead(serverJSON));
				// Check if webroot is set to public
				if (!structKeyExists(serverConfig, "web") || !structKeyExists(serverConfig.web, "webroot") ||
					!findNoCase("public", serverConfig.web.webroot)) {
					// Webroot is NOT public, so we might need to add /public
					if (fileExists(fileSystemUtil.resolvePath("public/index.cfm"))) {
						addPublic = true;
					}
				}
			} catch (any e) {
				// If we can't read server.json, fall back to old behavior
				if (fileExists(fileSystemUtil.resolvePath("public/index.cfm"))) {
					addPublic = true;
				}
			}
		}

		if (addPublic) {
			getURL &= "/public";
		}

		getURL &= "/?controller=wheels&action=wheels&view=cli";
  		return geturl;
	}

	// Basically sends a command
	function $sendToCliCommand(string urlstring="&command=info"){
		targetURL=$getBridgeURL() & arguments.urlstring;

		$preConnectionCheck();

		loc = new Http( url=targetURL ).send().getPrefix();
		print.line("Sending: " & targetURL);

		if(isJson(loc.filecontent)){
  			loc.result=deserializeJSON(loc.filecontent);
  			if(structKeyexists(loc.result, "success") && loc.result.success){
					print.line("Call to bridge was successful.");
  				return loc.result;
  			}else{
				error("Bridge response received but indicates failure.");
			}
  		} else {
  			// Check if this is likely an application error
  			if (find("<title>", loc.filecontent) && find("error", lCase(loc.filecontent))) {
  				print.redLine("Your application appears to have an error that's preventing CLI access.");
  				print.line("");
  				print.yellowLine("Common causes:");
  				print.line("  - Syntax errors in routes.cfm or other configuration files");
  				print.line("  - Missing required files or directories");
  				print.line("  - Database connection issues");
  				print.line("");
  				print.yellowLine("To debug:");
  				print.line("  1. Visit your application in a browser: #replace(targetURL, '?controller=wheels&action=wheels&view=cli&command=info', '')#");
  				print.line("  2. Fix any errors shown");
  				print.line("  3. Try the CLI command again");
  			} else {
  				print.line(helpers.stripTags(Formatter.unescapeHTML(loc.filecontent)));
  			}
  			print.line("");
  			print.line("Tried #targetURL#");
  			error("Error returned from DBMigrate Bridge");
  		}
	}

  	// Create the physical migration cfc in /db/migrate/
	function $createMigrationFile(required string name, required string action, required string content){
			var directory=fileSystemUtil.resolvePath("app/migrator/migrations");
			if(!directoryExists(directory)){
				directoryCreate(directory);
			}
	  		extendsPath="wheels.migrator.Migration";
	  		content=replaceNoCase(content, "|DBMigrateExtends|", extendsPath, "all");
			content=replaceNoCase(content, "|DBMigrateDescription|", "CLI #action#_#name#", "all");
			var fileName=dateformat(now(),'yyyymmdd') & timeformat(now(),'HHMMSS') & "_cli_#action#_" & name & ".cfc";
			var filePath=directory & "/" & fileName;
			file action='write' file='#filePath#' mode ='777' output='#trim( content )#';
			print.line( 'Created #fileName#' );
			// Return the relative path
			return "app/migrator/migrations/" & fileName;
	}

	//=====================================================================
//=     Templates
//=====================================================================

    // Return .txt template location
    public string function getTemplate(required string template){
			//Copy template files to the application folder if they do not exist there
			ensureSnippetTemplatesExist();
			var templateDirectory=getTemplateDirectory();
			var rv=templateDirectory & "/" & template;
			return rv;
	}

	// NB, this path is the only place with the module folder name in it: would be good to find a way around that
	public string function getTemplateDirectory(){
			var current={
		webRoot		= getCWD(),
		moduleRoot	= expandPath("/wheels-cli/")
	};

			// attempt to get the templates directory from the current web root
			if ( directoryExists( current.webRoot & "app/snippets" ) ) {
					var templateDirectory=current.webRoot & "app/snippets";
			} else if ( directoryExists( current.moduleRoot & "templates" ) ) {
					var templateDirectory=current.moduleRoot & "templates";
			} else {
					error( "#templateDirectory# Template Directory can't be found." );
			}
			return templateDirectory;
	}

	/*
	 * Copies template files to the application folder if they do not exist there
	 */
	public void function ensureSnippetTemplatesExist() {
		var current = {
			webRoot     = getCWD(),
			moduleRoot  = expandPath("/wheels-cli/templates/"),
			targetDir   = getCWD() & "app/snippets/"
		};

		// Only proceed if the app folder exists
		if (!directoryExists(current.webRoot & "app/")) {
			return;
		}

		// Create target directory if it doesn't exist
		if (!directoryExists(current.targetDir)) {
			directoryCreate(current.targetDir);
		}

		// List of root-level files and folders to exclude
		var excludedRootFiles = [];
		var excludedFolders = [];

		// Get all entries in the templates directory
		var entries = directoryList(current.moduleRoot, false, "query");

		for (var entry in entries) {
			var entryPath = current.moduleRoot & entry.name;
			var targetPath = current.targetDir & entry.name;

			if (entry.type == "File") {
				// Copy only non-excluded files that are missing
				if (!arrayContainsNoCase(excludedRootFiles, entry.name)) {
					if (!fileExists(targetPath)) {
						fileCopy(entryPath, targetPath);
					}
				}
			} else if (entry.type == "Dir") {
				// Copy only non-excluded folders that are missing
				if (!arrayContainsNoCase(excludedFolders, entry.name)) {
					// Ensure directory exists
					if (!directoryExists(targetPath)) {
						directoryCreate(targetPath);
					}
					// Recursively copy missing contents
					copyMissingFolderContents(entryPath, targetPath);
				}
			}
		}
	}

	/**
	 * Recursively copies missing files and folders from source to target.
	 */
	private void function copyMissingFolderContents(required string source, required string target) {
		var items = directoryList(arguments.source, false, "query");

		for (var item in items) {
			var sourcePath = arguments.source & "/" & item.name;
			var targetPath = arguments.target & "/" & item.name;

			if (item.type == "File") {
				if (!fileExists(targetPath)) {
					fileCopy(sourcePath, targetPath);
				}
			} else if (item.type == "Dir") {
				if (!directoryExists(targetPath)) {
					directoryCreate(targetPath);
				}
				// Recursive call to handle nested folders
				copyMissingFolderContents(sourcePath, targetPath);
			}
		}
	}

	function reconstructArgs(required struct argStruct) {
        local.result = {};

        for (local.key in arguments.argStruct) {
            if (find("=", local.key)) {
                local.parts = listToArray(local.key, "=");
                if (arrayLen(local.parts) == 2 && arguments.argStruct[local.key] == true) {
                    local.result[local.parts[1]] = local.parts[2];
                } else {
                    local.result[local.parts[1]] = local.parts[2] ?: true;
                }
            } else {
                local.result[local.key] = arguments.argStruct[local.key];
            }
        }

        return local.result;
    }

	// Copy helper functions from create.cfc
	private struct function getDatasourceInfo(required string datasourceName) {
		try {
			// Try to get datasource info from app.cfm
			local.appPath = getCWD();
			local.appCfcPath = local.appPath & "/config/app.cfm";
			
			if (fileExists(local.appCfcPath)) {
				local.content = fileRead(local.appCfcPath);
				
				// Remove all types of comments before parsing
				// 1. Remove CFML multi-line comments: <!--- ... --->
				local.content = REReplace(local.content, "<!---[\s\S]*?--->", "", "all");
				
				// 2. Remove JavaScript/CFScript multi-line comments: /* ... */
				local.content = REReplace(local.content, "/\*[\s\S]*?\*/", "", "all");
				
				// 3. Remove JavaScript/CFScript single-line comments: // ...
				// BUT we need to be careful not to remove // from URLs (http://, jdbc:mysql://, etc.)
				// Only remove // that appears at the beginning of a line or after whitespace
				local.content = REReplace(local.content, "(^|\s)//[^\r\n]*", "\1", "all");
				
				// Look for datasource definition in this.datasources['name']
				local.pattern = "this\.datasources\[['""]#arguments.datasourceName#['""]]\s*=\s*\{([^}]+)\}";
				local.match = reFindNoCase(local.pattern, local.content, 1, true);

				if (arrayLen(local.match.pos) > 0 && local.match.pos[1] > 0) {
					local.dsDefinition = mid(local.content, local.match.pos[1], local.match.len[1]);
					local.dsInfo = {
						"datasource": arguments.datasourceName,
						"database": "",
						"driver": "",
						"host": "localhost",
						"port": "",
						"username": "",
						"password": ""
					};
					
					// Extract driver class - handle both single and double quotes
					local.classMatch = reFindNoCase("class\s*:\s*['""]([^'""]+)['""]", local.dsDefinition, 1, true);
					if (arrayLen(local.classMatch.pos) >= 2 && local.classMatch.pos[2] > 0) {
						local.className = mid(local.dsDefinition, local.classMatch.pos[2], local.classMatch.len[2]);
						switch(local.className) {
							case "org.h2.Driver":
								local.dsInfo.driver = "H2";
								break;
							case "com.mysql.cj.jdbc.Driver":
							case "com.mysql.jdbc.Driver":
								local.dsInfo.driver = "MySQL";
								break;
							case "org.postgresql.Driver":
								local.dsInfo.driver = "PostgreSQL";
								break;
							case "com.microsoft.sqlserver.jdbc.SQLServerDriver":
								local.dsInfo.driver = "MSSQL";
								break;
						}
					}
					
					// Extract connection string - handle both single and double quotes
					local.connMatch = reFindNoCase("connectionString\s*:\s*['""]([^'""]+)['""]", local.dsDefinition, 1, true);
					if (arrayLen(local.connMatch.pos) >= 2 && local.connMatch.pos[2] > 0) {
						local.connString = mid(local.dsDefinition, local.connMatch.pos[2], local.connMatch.len[2]);
						
						// Parse H2 database path
						if (local.dsInfo.driver == "H2") {
							if (find("jdbc:h2:file:", local.connString)) {
								local.dbPath = replaceNoCase(local.connString, "jdbc:h2:file:", "");
								local.dbPath = listFirst(local.dbPath, ";");
								local.dsInfo.database = local.dbPath;
							}
						}
						
						// Parse database name from connection string for other drivers
						if (local.dsInfo.driver == "MySQL") {
							// jdbc:mysql://host:port/database?parameters
							// Extract host and port first
							local.hostPortMatch = reFindNoCase("jdbc:mysql://([^:/]+)(?::(\d+))?/", local.connString, 1, true);
							if (arrayLen(local.hostPortMatch.pos) >= 2 && local.hostPortMatch.pos[2] > 0) {
								local.dsInfo.host = mid(local.connString, local.hostPortMatch.pos[2], local.hostPortMatch.len[2]);
								if (arrayLen(local.hostPortMatch.pos) >= 3 && local.hostPortMatch.pos[3] > 0) {
									local.dsInfo.port = mid(local.connString, local.hostPortMatch.pos[3], local.hostPortMatch.len[3]);
								}
							}
							
							// Extract database name
							local.dbMatch = reFindNoCase("jdbc:mysql://[^/]+/([^?;]+)", local.connString, 1, true);
							if (arrayLen(local.dbMatch.pos) >= 2 && local.dbMatch.pos[2] > 0) {
								local.dsInfo.database = mid(local.connString, local.dbMatch.pos[2], local.dbMatch.len[2]);
							}
						} else if (local.dsInfo.driver == "PostgreSQL") {
							// jdbc:postgresql://host:port/database
							// Extract host and port first
							local.hostPortMatch = reFindNoCase("jdbc:postgresql://([^:/]+)(?::(\d+))?/", local.connString, 1, true);
							if (arrayLen(local.hostPortMatch.pos) >= 2 && local.hostPortMatch.pos[2] > 0) {
								local.dsInfo.host = mid(local.connString, local.hostPortMatch.pos[2], local.hostPortMatch.len[2]);
								if (arrayLen(local.hostPortMatch.pos) >= 3 && local.hostPortMatch.pos[3] > 0) {
									local.dsInfo.port = mid(local.connString, local.hostPortMatch.pos[3], local.hostPortMatch.len[3]);
								}
							}
							
							// Extract database name
							local.dbMatch = reFindNoCase("jdbc:postgresql://[^/]+/([^?;]+)", local.connString, 1, true);
							if (arrayLen(local.dbMatch.pos) >= 2 && local.dbMatch.pos[2] > 0) {
								local.dsInfo.database = mid(local.connString, local.dbMatch.pos[2], local.dbMatch.len[2]);
							}
						} else if (local.dsInfo.driver == "MSSQL") {
							// jdbc:sqlserver://host:port;databaseName=database
							// Extract host and port first
							local.hostPortMatch = reFindNoCase("jdbc:sqlserver://([^:/]+)(?::(\d+))?", local.connString, 1, true);
							if (arrayLen(local.hostPortMatch.pos) >= 2 && local.hostPortMatch.pos[2] > 0) {
								local.dsInfo.host = mid(local.connString, local.hostPortMatch.pos[2], local.hostPortMatch.len[2]);
								if (arrayLen(local.hostPortMatch.pos) >= 3 && local.hostPortMatch.pos[3] > 0) {
									local.dsInfo.port = mid(local.connString, local.hostPortMatch.pos[3], local.hostPortMatch.len[3]);
								}
							}
							
							// Extract database name
							// First try databaseName=
							local.dbMatch = reFindNoCase("databaseName=([^;]+)", local.connString, 1, true);
							if (arrayLen(local.dbMatch.pos) >= 2 && local.dbMatch.pos[2] > 0) {
								local.dsInfo.database = mid(local.connString, local.dbMatch.pos[2], local.dbMatch.len[2]);
							} else {
								// Try database=
								local.dbMatch = reFindNoCase("database=([^;]+)", local.connString, 1, true);
								if (arrayLen(local.dbMatch.pos) >= 2 && local.dbMatch.pos[2] > 0) {
									local.dsInfo.database = mid(local.connString, local.dbMatch.pos[2], local.dbMatch.len[2]);
								}
							}
						}
					}
					
					// Extract username - handle both single and double quotes
					local.userMatch = reFindNoCase("username\s*[:=]\s*['""]([^'""]*)['""]", local.dsDefinition, 1, true);
					if (arrayLen(local.userMatch.pos) >= 2 && local.userMatch.pos[2] > 0) {
						local.dsInfo.username = mid(local.dsDefinition, local.userMatch.pos[2], local.userMatch.len[2]);
					}
					// Extract password - handle both single and double quotes
					local.passwordMatch = reFindNoCase("password\s*[:=]\s*['""]([^'""]*)['""]", local.dsDefinition, 1, true);
					if (arrayLen(local.passwordMatch.pos) >= 2 && local.passwordMatch.pos[2] > 0) {
						local.dsInfo.password = mid(local.dsDefinition, local.passwordMatch.pos[2], local.passwordMatch.len[2]);
					}
					return local.dsInfo;
				}
			}
			
			// If not found in app.cfm, return empty struct
			return {};
		} catch (any e) {
			// Server might not be running or file read error
			return {};
		}
	}

	private string function getEnvironment(required string appPath) {
		// Same logic as get environment command
		local.environment = "";
		
		// Check .env file
		local.envFile = arguments.appPath & "/.env";
		if (FileExists(local.envFile)) {
			local.envContent = FileRead(local.envFile);
			local.envMatch = REFind("(?m)^WHEELS_ENV\s*=\s*(.+)$", local.envContent, 1, true);
			if (local.envMatch.pos[1] > 0) {
				local.environment = Trim(Mid(local.envContent, local.envMatch.pos[2], local.envMatch.len[2]));
			}
		}
		
		// Check environment variable
		if (!Len(local.environment)) {
			local.sysEnv = CreateObject("java", "java.lang.System");
			local.wheelsEnv = local.sysEnv.getenv("WHEELS_ENV");
			if (!IsNull(local.wheelsEnv) && Len(local.wheelsEnv)) {
				local.environment = local.wheelsEnv;
			}
		}
		
		// Default to development
		if (!Len(local.environment)) {
			local.environment = "development";
		}
		
		return local.environment;
	}

	private string function getDataSourceName(required string appPath, required string environment) {
		// Check environment-specific settings first
		local.envSettingsFile = arguments.appPath & "/config/" & arguments.environment & "/settings.cfm";
		if (FileExists(local.envSettingsFile)) {
			local.dsName = extractDataSourceName(FileRead(local.envSettingsFile));
			if (Len(local.dsName)) return local.dsName;
		}
		
		// Check general settings
		local.settingsFile = arguments.appPath & "/config/settings.cfm";
		if (FileExists(local.settingsFile)) {
			local.dsName = extractDataSourceName(FileRead(local.settingsFile));
			if (Len(local.dsName)) return local.dsName;
		}
		
		return "";
	}

	private string function extractDataSourceName(required string content) {
		// Step 1: Remove multi-line block comments: /* ... */
		local.cleaned = REReplace(arguments.content, "/\*[\s\S]*?\*/", "", "all");

		// Step 2: Remove single-line comments: // ... until end of line
		local.cleaned = REReplace(local.cleaned, "//.*", "", "all");

		// Step 3: Match set(dataSourceName="...")
		local.pattern = "set\s*\(\s*dataSourceName\s*=\s*[""']([^""']+)[""']";
		local.match = REFind(local.pattern, local.cleaned, 1, true);

		if (arrayLen(local.match.pos) >= 2 && local.match.pos[2] > 0) {
			return Mid(local.cleaned, local.match.pos[2], local.match.len[2]);
		}
		return "";
	}

	private string function buildJDBCUrl(required struct dsInfo) {
		local.driver = arguments.dsInfo.driver;
		local.host = arguments.dsInfo.host ?: "localhost";
		local.port = arguments.dsInfo.port ?: "";
		local.database = arguments.dsInfo.database ?: "";
		
		switch (local.driver) {
			case "MySQL":
			case "MySQL5":
				if (!Len(local.port)) local.port = "3306";
				return "jdbc:mysql://#local.host#:#local.port#/#local.database#";
			case "PostgreSQL":
				if (!Len(local.port)) local.port = "5432";
				return "jdbc:postgresql://#local.host#:#local.port#/#local.database#";
			case "MSSQLServer":
			case "MSSQL":
				if (!Len(local.port)) local.port = "1433";
				local.database = "master";
				return "jdbc:sqlserver://#local.host#:#local.port#;databaseName=#local.database#;encrypt=false;trustServerCertificate=true";
			case "H2":
				return "jdbc:h2:#local.database#";
			default:
				return "";
		}
	}

	/**
	 * Print formatted output helpers
	 */
	private void function printHeader(required string text) {
		systemOutput("", true, true);
		systemOutput("==================================================================", true, true);
		systemOutput("  " & arguments.text, true, true);
		systemOutput("==================================================================", true, true);
		systemOutput("", true, true);
	}

	private void function printDivider() {
		systemOutput("------------------------------------------------------------------", true, true);
	}

	private void function printInfo(required string label, required string value) {
		systemOutput("  " & PadRight(arguments.label & ":", 20) & arguments.value, true, true);
	}

	private void function printStep(required string message) {
		systemOutput("", true, true);
		systemOutput(">> " & arguments.message, true, true);
	}

	private void function printSuccess(required string message, boolean bold = false) {
		if (arguments.bold) {
			print.boldGreenLine(arguments.message);
		} else {
			print.greenLine("  [OK] " & arguments.message);
		}
		systemOutput("", true, false); // Force flush
	}

	private void function printWarning(required string message) {
		print.yellowLine("  [WARN] " & arguments.message);
		systemOutput("", true, false); // Force flush
	}

	private void function printError(required string message) {
		print.redLine("  [ERROR] " & arguments.message);
		systemOutput("", true, false); // Force flush
	}

	private string function PadRight(required string text, required numeric length) {
		if (Len(arguments.text) >= arguments.length) {
			return Left(arguments.text, arguments.length);
		}
		return arguments.text & RepeatString(" ", arguments.length - Len(arguments.text));
	}

	/**
	 * Check if database exists
	 */
	private boolean function checkDatabaseExists(required any conn, required string dbName, required string dbType) {
		local.exists = false;
		
		switch (arguments.dbType) {
			case "MySQL":
				local.stmt = arguments.conn.createStatement();
				local.query = "SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = '" & arguments.dbName & "'";
				local.rs = local.stmt.executeQuery(local.query);
				local.exists = local.rs.next();
				local.rs.close();
				local.stmt.close();
				break;
				
			case "PostgreSQL":
				local.stmt = arguments.conn.prepareStatement("SELECT 1 FROM pg_database WHERE datname = ?");
				local.stmt.setString(1, arguments.dbName);
				local.rs = local.stmt.executeQuery();
				local.exists = local.rs.next();
				local.rs.close();
				local.stmt.close();
				break;
				
			case "SQLServer":
				local.stmt = arguments.conn.createStatement();
				local.query = "SELECT name FROM sys.databases WHERE name = '" & arguments.dbName & "'";
				local.rs = local.stmt.executeQuery(local.query);
				local.exists = local.rs.next();
				local.rs.close();
				local.stmt.close();
				break;
		}
		
		return local.exists;
	}

	/**
	 * Get database-specific configuration
	 */
	private struct function getDatabaseConfig(required string dbType, required struct dsInfo) {
		local.config = {
			tempDS: Duplicate(arguments.dsInfo),
			driverClasses: []
		};
		
		switch (arguments.dbType) {
			case "MySQL":
				local.config.tempDS.database = "information_schema"; // Connect to system database
				local.config.driverClasses = [
					"com.mysql.cj.jdbc.Driver",      // MySQL 8.0+
					"com.mysql.jdbc.Driver",         // MySQL 5.x
					"org.mariadb.jdbc.Driver"        // MariaDB
				];
				break;
				
			case "PostgreSQL":
				local.config.tempDS.database = "postgres"; // Connect to system database
				local.config.driverClasses = [
					"org.postgresql.Driver",         // Standard PostgreSQL driver
					"postgresql.Driver"              // Alternative name
				];
				break;
				
			case "SQLServer":
				local.config.tempDS.database = "master"; // Connect to system database
				local.config.driverClasses = [
					"com.microsoft.sqlserver.jdbc.SQLServerDriver"
				];
				break;
		}
		
		return local.config;
	}


		/**
	 * Get list of available databases
	 */
	private array function getAvailableDatabases(required struct dsInfo) {
		local.databases = [];
		
		try {
			switch(arguments.dsInfo.driver) {
				case "MySQL":
				case "MySQL5":
					local.databases = getMySQLDatabases(arguments.dsInfo);
					break;
				case "PostgreSQL":
					local.databases = getPostgreSQLDatabases(arguments.dsInfo);
					break;
				case "MSSQLServer":
				case "MSSQL":
					local.databases = getSQLServerDatabases(arguments.dsInfo);
					break;
			}
		} catch (any e) {
			printError("Error fetching databases: " & e.message);
		}
		
		return local.databases;
	}

	/**
	* Enhanced getMySQLDatabases with better error handling
	* Add this to base.cfc to replace the existing function
	*/
	private array function getMySQLDatabases(required struct dsInfo) {
		local.databases = [];
		
		try {
			// Build temporary connection without specific database
			local.tempDS = Duplicate(arguments.dsInfo);
			local.tempDS.database = "information_schema";
			
			printStep("Attempting to connect to MySQL server...");
			printInfo("Host", local.tempDS.host ?: "localhost");
			printInfo("Port", (StructKeyExists(local.tempDS, "port") && Len(local.tempDS.port)) ? local.tempDS.port : "3306");
			printInfo("User", local.tempDS.username ?: "");
			
			// Get connection
			local.connResult = getDatabaseConnection(local.tempDS, "MySQL");
			
			if (!local.connResult.success) {
				printError("Failed to connect to MySQL server");
				printError("Error: " & local.connResult.error);
				
				// Try command line as fallback
				printStep("Trying command line fallback...");
				local.cmd = "mysql";
				local.cmd &= " -h " & (arguments.dsInfo.host ?: "localhost");
				local.cmd &= " -P " & (arguments.dsInfo.port ?: "3307");
				local.cmd &= " -u " & (arguments.dsInfo.username ?: "");
				if (Len(arguments.dsInfo.password ?: "")) {
					local.envVars = {"MYSQL_PWD": arguments.dsInfo.password};
				} else {
					local.envVars = {};
				}
				local.cmd &= " -e ""SHOW DATABASES"" -s -N";
				
				local.result = runCommand(local.cmd, local.envVars);
				if (local.result.success && Len(local.result.output)) {
					local.dbList = ListToArray(local.result.output, Chr(10));
					for (local.db in local.dbList) {
						local.dbName = Trim(local.db);
						if (Len(local.dbName) && !ListFindNoCase("information_schema,mysql,performance_schema,sys", local.dbName)) {
							ArrayAppend(local.databases, local.dbName);
						}
					}
					printSuccess("Retrieved databases via command line");
				} else {
					printError("Command line fallback also failed");
					if (Len(local.result.error)) {
						printError("Error: " & local.result.error);
					}
				}
				
				return local.databases;
			}
			
			local.conn = local.connResult.connection;
			
			try {
				local.stmt = local.conn.createStatement();
				local.rs = local.stmt.executeQuery("SHOW DATABASES");
				
				while (local.rs.next()) {
					local.dbName = local.rs.getString(1);
					// Exclude system databases
					if (!ListFindNoCase("information_schema,mysql,performance_schema,sys", local.dbName)) {
						ArrayAppend(local.databases, local.dbName);
					}
				}
				
				local.rs.close();
				local.stmt.close();
				printSuccess("Retrieved " & ArrayLen(local.databases) & " databases");
			} finally {
				local.conn.close();
			}
			
		} catch (any e) {

			// Provide specific troubleshooting based on error
			if (FindNoCase("Communications link failure", e.message)) {
				print.line();
				printWarning("Connection failed. Please check:");
				print.line("1. MySQL server is running on port " & (arguments.dsInfo.port ?: "3306"));
				print.line("2. Firewall is not blocking the connection");
				print.line("3. MySQL is configured to accept connections from " & (arguments.dsInfo.host ?: "localhost"));
				print.line();
				print.line("To verify MySQL is running:");
				print.line("- Windows: Check Services for MySQL");
				print.line("- Command: netstat -an | findstr :" & (arguments.dsInfo.port ?: "3306"));
			} else if (FindNoCase("Access denied", e.message)) {
				printWarning("Authentication failed. Check username and password.");
			}
		}
		
		return local.databases;
	}


	/**
	 * Get PostgreSQL databases
	 */
	private array function getPostgreSQLDatabases(required struct dsInfo) {
		local.databases = [];
		
		try {
			// Build temporary connection to postgres database
			local.tempDS = Duplicate(arguments.dsInfo);
			local.tempDS.database = "postgres";
			
			// Get connection
			local.connResult = getDatabaseConnection(local.tempDS, "PostgreSQL");
			
			if (!local.connResult.success) {
				return local.databases;
			}
			
			local.conn = local.connResult.connection;
			
			try {
				local.stmt = local.conn.createStatement();
				local.rs = local.stmt.executeQuery(
					"SELECT datname FROM pg_database WHERE datistemplate = false AND datname NOT IN ('postgres')"
				);
				
				while (local.rs.next()) {
					ArrayAppend(local.databases, local.rs.getString(1));
				}
				
				local.rs.close();
				local.stmt.close();
			} finally {
				local.conn.close();
			}
			
		} catch (any e) {
			// Fallback approach if direct connection fails
		}
		
		return local.databases;
	}

	/**
	 * Get SQL Server databases
	 */
	private array function getSQLServerDatabases(required struct dsInfo) {
		local.databases = [];
		
		try {
			// Build temporary connection to master database
			local.tempDS = Duplicate(arguments.dsInfo);
			local.tempDS.database = "master";
			
			// Get connection
			local.connResult = getDatabaseConnection(local.tempDS, "SQLServer");
			
			if (!local.connResult.success) {
				return local.databases;
			}
			
			local.conn = local.connResult.connection;
			
			try {
				local.stmt = local.conn.createStatement();
				local.rs = local.stmt.executeQuery(
					"SELECT name FROM sys.databases WHERE name NOT IN ('master', 'tempdb', 'model', 'msdb')"
				);
				
				while (local.rs.next()) {
					ArrayAppend(local.databases, local.rs.getString(1));
				}
				
				local.rs.close();
				local.stmt.close();
			} finally {
				local.conn.close();
			}
			
		} catch (any e) {
			// Fallback approach if direct connection fails
		}
		
		return local.databases;
	}

		/**
	* Get database connection
	* This function should be added to base.cfc
	*/
	private struct function getDatabaseConnection(required struct dsInfo, required string dbType, string systemDatabase = "") {
		local.result = {
			success: false,
			connection: "",
			error: "",
			driverClass: ""
		};
		
		try {
			// Get database-specific configuration
			local.dbConfig = getDatabaseConfig(arguments.dbType, arguments.dsInfo, arguments.systemDatabase);
			
			// Build connection URL
			local.url = buildJDBCUrl(local.dbConfig.tempDS);
			local.username = local.dbConfig.tempDS.username ?: "";
			local.password = local.dbConfig.tempDS.password ?: "";
			
			printStep("Connecting to " & arguments.dbType & " database...");
			
			// Try to load driver
			local.driver = "";
			local.driverFound = false;
			
			for (local.driverClass in local.dbConfig.driverClasses) {
				try {
					local.driver = createObject("java", local.driverClass);
					local.result.driverClass = local.driverClass;
					local.driverFound = true;
					printSuccess("Driver found: " & local.driverClass);
					break;
				} catch (any driverError) {
					// Continue trying other drivers
				}
			}
			
			if (!local.driverFound) {
				local.result.error = "No " & arguments.dbType & " driver found. Ensure JDBC driver is in classpath.";
				return local.result;
			}
			
			// Create properties for connection
			local.props = createObject("java", "java.util.Properties");
			local.props.setProperty("user", local.username);
			local.props.setProperty("password", local.password);
			
			// Test if driver accepts the URL
			if (!local.driver.acceptsURL(local.url)) {
				local.result.error = arguments.dbType & " driver does not accept the URL format";
				return local.result;
			}
			
			// Connect using driver directly
			print.line(local.url);
			print.redLine(local.props);
			local.conn = local.driver.connect(local.url, local.props);
			
			if (isNull(local.conn)) {
				local.result.error = "Failed to establish connection to " & arguments.dbType;
				return local.result;
			}
			
			local.result.success = true;
			local.result.connection = local.conn;
			printSuccess("Connected successfully to " & arguments.dbType & " database!");
			return local.result;
			
		} catch (any e) {
			local.result.error = e.message;
			if (StructKeyExists(e, "detail")) {
				local.result.error &= " - " & e.detail;
			}
			return local.result;
		}
	}

	/**
	* Get database-specific configuration
	* This function should also be in base.cfc
	*/
	private struct function getDatabaseConfig(required string dbType, required struct dsInfo, string systemDatabase = "") {
		local.config = {
			tempDS: Duplicate(arguments.dsInfo),
			driverClasses: []
		};
		
		switch (arguments.dbType) {
			case "MySQL":
				if (Len(arguments.systemDatabase)) {
					local.config.tempDS.database = arguments.systemDatabase;
				} else if (!Len(local.config.tempDS.database)) {
					local.config.tempDS.database = "information_schema"; // Default system DB
				}
				local.config.driverClasses = [
					"com.mysql.cj.jdbc.Driver",
					"com.mysql.jdbc.Driver",
					"org.mariadb.jdbc.Driver"
				];
				break;
				
			case "PostgreSQL":
				if (Len(arguments.systemDatabase)) {
					local.config.tempDS.database = arguments.systemDatabase;
				} else if (!Len(local.config.tempDS.database)) {
					local.config.tempDS.database = "postgres"; // Default system DB
				}
				local.config.driverClasses = [
					"org.postgresql.Driver",
					"postgresql.Driver"
				];
				break;
				
			case "SQLServer":
			case "MSSQL":
				if (Len(arguments.systemDatabase)) {
					local.config.tempDS.database = arguments.systemDatabase;
				} else if (!Len(local.config.tempDS.database)) {
					local.config.tempDS.database = "master"; // Default system DB
				}
				local.config.driverClasses = [
					"com.microsoft.sqlserver.jdbc.SQLServerDriver"
				];
				break;
				
			case "H2":
				// H2 doesn't need a system database
				local.config.driverClasses = [
					"org.h2.Driver"
				];
				break;
		}
		
		return local.config;
	}

	/**
	* Add this FileAppend helper function to base.cfc
	* ColdFusion doesn't have FileAppend built-in, so we create one
	*/
	private void function FileAppend(required string filepath, required string content) {
		local.file = FileOpen(arguments.filepath, "append");
		FileWrite(local.file, arguments.content);
		FileClose(local.file);
	}

    /**
     * Get server configuration
     */
    function getServerConfig(string servername = "") {
        try {
            // Try to get actual server info from CommandBox
            local.serverDetails = serverService.resolveServerDetails( serverProps={ name=arguments.servername } );
            local.serverInfo = serverService.getServerInfoByName( len(arguments.servername) ? arguments.servername : local.serverDetails.defaultName );
            
            if (structKeyExists(local.serverInfo, "host") && structKeyExists(local.serverInfo, "port")) {
                return {
                    host = local.serverInfo.host,
                    port = local.serverInfo.port
                };
            }
        } catch (any e) {
            // Try alternative method
        }
        
        // Try alternative method to get server info
        try {
            local.serverInfo = $getServerInfo();
            if (structKeyExists(local.serverInfo, "host") && structKeyExists(local.serverInfo, "port")) {
                return {
                    host = local.serverInfo.host,
                    port = local.serverInfo.port
                };
            }
        } catch (any e) {
            // Fallback to defaults
        }
        
        // Final fallback
        return {
            host = "localhost",
            port = "8080"
        };
    }

	    
    /**
     * Build test URL with parameters
     */
    private function buildTestUrl(
        required string type,
        string servername = "",
        string format = "txt"
    ) {
        // Get actual server configuration
        local.serverConfig = getServerConfig(arguments.servername);
        local.baseUrl = "http://#local.serverConfig.host#:#local.serverConfig.port#/";
        
        // http://localhost:8080/wheels/app/tests?format=txt

        // Build base URL based on type
        switch (arguments.type) {
            case "app":
                local.url = local.baseUrl & "/wheels/app/tests?format=#arguments.format#";
                break;
            case "core":
                local.url = local.baseUrl & "/wheels/core/tests?format=#arguments.format#";
                break;
            case "plugin":
                local.url = local.baseUrl & "/wheels/plugins/tests?format=#arguments.format#";
                break;
            default:
                // Default to app tests for invalid types
                local.url = local.baseUrl & "/wheels/app/tests?format=#arguments.format#";
                break;
        }
        
        return local.url;
    }

	/**
	* Resolve the test directory based on type and optional subdirectory
	*
	* @type Valid options: "app", "core"
	* @directory Optional subdirectory (with or without leading slash)
	*/
	private string function resolveTestDirectory(
		string type="app",
		string directory = ""
	) {
		var baseDirectory = "";

		switch (arguments.type) {
			case "app":
				baseDirectory = "tests/specs";
				break;
			case "core":
				baseDirectory = "wheels/tests_testbox/specs";
				break;
			default:
				error("Invalid type specified. Valid types are: app, core.");
		}

		// Normalize subdirectory (remove leading slash if present)
		if (len(trim(arguments.directory))) {
			var subDir = reReplace(arguments.directory, "^/+", ""); // strip leading slashes
			return baseDirectory & "/" & subDir;
		}

		return baseDirectory;
	}

}
