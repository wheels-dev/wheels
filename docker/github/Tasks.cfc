/**
 * Tasks for running Wheels test suite
 *
 * NOTE: These don't currently work as 127.0.0.1 is the localhost of the commandbox server, not the github VM
 */
component {

	/**
	 * Pings the server until it returns a valid response
	 */
	function serverUp(required string cfengine) {
		local.port = this.getPort(arguments.cfengine);
		local.maxIterations = 10;
		local.waitSeconds = 6;
		local.endpoint = "http://127.0.0.1:#local.port#";

		print.line(local.endpoint);

		local.iterations = 0;
		while (true) {
			local.iterations++;
			print.line("Attempt #local.iterations#!");
			Sleep(local.waitSeconds * 1000);
			cfhttp(url = local.endpoint, result = "local.response");
			if (local.response.statusCode == 200) {
				print.line("Server Up");
				break;
			}
			if (local.iterations gte local.maxIterations) {
				Throw(message = "Loop Timeout");
			}
		}
	}

	/**
	 * Runs the test suite and returns the response
	 */
	function runTests(required string cfengine, required string dbengine) {
		local.port = this.getPort(arguments.cfengine);
		local.db = this.getDB(arguments.dbengine);
		local.endpoint = "http://127.0.0.1:#local.port#/wheels/tests/core?db=#local.db#&format=txt&only=failure,error";
		print.line("RUNNING TESTS (#arguments.cfengine#/#arguments.dbengine#)");
		cfhttp(url = local.endpoint, result = "local.response");
		print.line(local.response.fileContent);
	}

	/**
	 * maps a cfengine to it's docker port
	 */
	private numeric function getPort(required string cfengine) {
		local.maps = {"lucee5" = 60005, "lucee6" = 60006, "adobe2016" = 62016, "adobe2018" = 62018};
		if (StructKeyExists(local.maps, arguments.cfengine)) {
			return local.maps[arguments.cfengine];
		}
		Throw(message = "Unsupported CFML Engine");
	}

	/**
	 * maps a db docker container name to it's test param
	 */
	private numeric function getDB(required string dbengine) {
		local.maps = {"mysql56" = "mysql"};
		if (StructKeyExists(local.maps, arguments.dbengine)) {
			return local.maps[arguments.dbengine];
		}
		return LCase(arguments.dbengine);
	}

}
