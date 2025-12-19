/**
 * Reloads a wheels app: will ask for your reload password (and optional mode, we assume development)
 * Will only work on a running server
 *
 * {code:bash}
 * wheels reload
 * {code}
 *
 * {code:bash}
 * wheels reload mode="production"
 * {code}
 **/
component aliases='wheels r'  extends="base"  {

	/**
	 * @mode.hint Mode to switch to
	 * @mode.options development,testing,maintenance,production
	 * @password The reload password
	 **/

	property name="detailOutput" inject="DetailOutputService@wheels-cli";
	
	function run(string mode="development", string password="") {
		requireWheelsApp(getCWD());
		arguments=reconstructArgs(arguments);
  		var serverDetails = $getServerInfo();

  		getURL = serverDetails.serverURL &
  			"/index.cfm?reload=#mode#&password=#password#";
  		var loc = new Http( url=getURL ).send().getPrefix();
  		detailOutput.statusSuccess("Reload Request sent");
	}

}
