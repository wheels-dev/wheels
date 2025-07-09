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

	/**
	 *
	 **/
	function run() {

		print.greenBoldLine( "==================================== Wheels init ===================================" )
			   .greenBoldLine( " This function will attempt to add a few things " )
				 .greenBoldLine( " to an EXISTING Wheels installation to help   " )
				 .greenBoldLine( " the CLI interact." )
				 .greenBoldLine( " " )
				 .greenBoldLine( " We're going to assume the following:" )
				 .greenBoldLine( "  - you've already setup a local datasource/database" )
				 .greenBoldLine( "  - you've already set a reload password" )
				 .greenBoldLine( " " )
				 .greenBoldLine( " We're going to try and do the following:" )
				 .greenBoldLine( "  - create a box.json to help keep track of the wheels version" )
				 .greenBoldLine( "  - create a server.json" )
				 .greenBoldLine( "====================================================================================" )
			 .line().toConsole();
		if(!confirm("Sound ok? [y/n] ")){
			error("Ok, aborting...");
		}

		var serverJsonLocation=fileSystemUtil.resolvePath("server.json");
		var wheelsBoxJsonLocation=fileSystemUtil.resolvePath("vendor/wheels/box.json");
		var boxJsonLocation=fileSystemUtil.resolvePath("box.json");

		var wheelsVersion = $getWheelsVersion();
		print.greenline(wheelsVersion);

		// Create a wheels/box.json if one doesn't exist
		if(!fileExists(wheelsBoxJsonLocation)){
			var wheelsBoxJSON = fileRead( getTemplate('/WheelsBoxJSON.txt' ) );
			wheelsBoxJSON = replaceNoCase( wheelsBoxJSON, "|version|", trim(wheelsVersion), 'all' );

				 // Make box.json
	 		print.greenline( "========= Creating wheels/box.json" ).toConsole();
			file action='write' file=wheelsBoxJsonLocation mode ='777' output='#trim(wheelsBoxJSON)#';

		} else {
 			print.greenline( "========= wheels/box.json exists, skipping" ).toConsole();
		}

		// Create a server.json if one doesn't exist
		if(!fileExists(serverJsonLocation)){
			var appName       = ask( message = "Please enter an application name: we use this to make the server.json servername unique: ", defaultResponse = 'myapp');
				appName 	  = helpers.stripSpecialChars(appName);
			var setEngine     = ask( message = 'Please enter a default cfengine: ', defaultResponse = 'lucee5' );

			// Make server.json server name unique to this app: assumes lucee by default
	 		print.greenline( "========= Creating default server.json" ).toConsole();
			var serverJSON = fileRead( getTemplate('/ServerJSON.txt' ) );
		 		serverJSON = replaceNoCase( serverJSON, "|appName|", trim(appName), 'all' );
		 		serverJSON = replaceNoCase( serverJSON, "|setEngine|", setEngine, 'all' );
		 		file action='write' file=serverJsonLocation mode ='777' output='#trim(serverJSON)#';

		} else {
 			print.greenline( "========= server.json exists, skipping" ).toConsole();
		}

		// Create a box.json if one doesn't exist
		if(!fileExists(boxJsonLocation)){
			if(!isDefined("appName")) {
				var appName = ask("Please enter an application name: we use this to make the box.json servername unique: ");
				appName 	  = helpers.stripSpecialChars(appName);
			}
			var boxJSON = fileRead( getTemplate('/BoxJSON.txt' ) );
			boxJSON = replaceNoCase( boxJSON, "|version|", trim(wheelsVersion), 'all' );
			boxJSON = replaceNoCase( boxJSON, "|appName|", trim(appName), 'all' );

				 // Make box.json
	 		print.greenline( "========= Creating box.json" ).toConsole();
			file action='write' file=boxJsonLocation mode ='777' output='#trim(boxJSON)#';

		} else {
 			print.greenline( "========= box.json exists, skipping" ).toConsole();
		}

	}

}
