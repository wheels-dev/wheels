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
		
		// Check if we're in a running wheels app (core/wheels structure)
		if(isWheelsApp(getCWD())) {
			local.wheelsPath = fileSystemUtil.resolvePath("core/wheels");
			local.boxJsonPath = fileSystemUtil.resolvePath("core/wheels/box.json");
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
		// Check for core/wheels folder
		if (!directoryExists(arguments.path & "/core/wheels")) {
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

}
