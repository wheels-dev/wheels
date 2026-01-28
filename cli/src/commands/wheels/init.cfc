/**
 * Init: This will attempt to bootstrap an EXISTING wheels app to work with the CLI.
 *
 * We'll assume: the database/datasource exists, the other config, like reloadpassword is set
 * If there's no box.json, create it, and ask for the version number
 * If there's no server.json, create it, and ask for cfengine preference
 * We'll ignore the bootstrap3 templating, as this will probably be in place too.
 *
 * {code:bash}
 * wheels init
 * {code}
 **/
component  extends="base"  {

	property name="detailOutput" inject="DetailOutputService@wheels-cli";

	/**
	 *
	 **/
	function run() {

		requireWheelsApp(getCWD());
		detailOutput.header("Wheels init")
				   .output("This function will attempt to add a few things")
				   .output("to an EXISTING Wheels installation to help")
				   .output("the CLI interact.")
				   .line()
				   .output("We're going to assume the following:")
				   .output("- you've already setup a local datasource/database", true)
				   .output("- you've already set a reload password", true)
				   .line()
				   .output("We're going to try and do the following:")
				   .output("- create a box.json to help keep track of the wheels version", true)
				   .output("- create a server.json", true)
				   .divider()
				   .line();

		if(!confirm("Sound ok? [y/n] ")){
			detailOutput.getPrint().redBoldLine("Ok, aborting...").toConsole();
			return;
		}

		var serverJsonLocation=fileSystemUtil.resolvePath("server.json");
		var wheelsBoxJsonLocation=fileSystemUtil.resolvePath("vendor/wheels/box.json");
		var boxJsonLocation=fileSystemUtil.resolvePath("box.json");

		var wheelsVersion = $getWheelsVersion();
		detailOutput.statusInfo(wheelsVersion);

		// Create a wheels/box.json if one doesn't exist
		if(!fileExists(wheelsBoxJsonLocation)){
			var wheelsBoxJSON = fileRead( getTemplate('/WheelsBoxJSON.txt' ) );
			wheelsBoxJSON = replaceNoCase( wheelsBoxJSON, "|version|", trim(wheelsVersion), 'all' );

			// Make box.json
			detailOutput.statusInfo("Creating wheels/box.json");
			file action='write' file=wheelsBoxJsonLocation mode ='777' output='#trim(wheelsBoxJSON)#';
			detailOutput.create(wheelsBoxJsonLocation);
			detailOutput.statusSuccess("Created wheels/box.json");

		} else {
			detailOutput.statusInfo("wheels/box.json exists, skipping");
		}

		// Create a server.json if one doesn't exist
		if(!fileExists(serverJsonLocation)){
			var appName       = ask( message = "Please enter an application name (we use this to make the server.json servername unique): ", defaultResponse = 'myapp');
				appName 	  = helpers.stripSpecialChars(appName);
			var setEngine     = ask( message = 'Please enter a default cfengine: ', defaultResponse = 'lucee@6' );

			// Make server.json server name unique to this app: assumes lucee by default
			detailOutput.statusInfo("Creating default server.json");
			var serverJSON = fileRead( getTemplate('/ServerJSON.txt' ) );
			serverJSON = replaceNoCase( serverJSON, "|appName|", trim(appName), 'all' );
			serverJSON = replaceNoCase( serverJSON, "|setEngine|", setEngine, 'all' );
			file action='write' file=serverJsonLocation mode ='777' output='#trim(serverJSON)#';
			detailOutput.create(serverJsonLocation);
			detailOutput.statusSuccess("Created server.json");

		} else {
			detailOutput.statusInfo("server.json exists, skipping");
		}

		// Create a box.json if one doesn't exist
		if(!fileExists(boxJsonLocation)){
			if(!isDefined("appName")) {
				var appName = ask("Please enter an application name (we use this to make the box.json servername unique): ");
				appName 	  = helpers.stripSpecialChars(appName);
			}
			var boxJSON = fileRead( getTemplate('/BoxJSON.txt' ) );
			boxJSON = replaceNoCase( boxJSON, "|version|", trim(wheelsVersion), 'all' );
			boxJSON = replaceNoCase( boxJSON, "|appName|", trim(appName), 'all' );

			// Make box.json
			detailOutput.statusInfo("Creating box.json");
			file action='write' file=boxJsonLocation mode ='777' output='#trim(boxJSON)#';
			detailOutput.create(boxJsonLocation);
			detailOutput.statusSuccess("Created box.json");

		} else {
			detailOutput.statusInfo("box.json exists, skipping");
		}

	}

}