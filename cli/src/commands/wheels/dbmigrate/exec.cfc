/**
 * Migrate to Version x
 *
 * wheels dbmigrate exec 20160730115754
 * wheels dbmigrate exec 0
 **/
component aliases='wheels db exec' extends="../base" {

	property name="detailOutput" inject="DetailOutputService@wheels-cli";

	/**
	 *  Migrate to specific version
	 * @version.hint Version to migrate to
	 **/
	function run( required string version	) {
		// Reconstruct arguments for handling --prefixed options
		arguments = reconstructArgs(arguments);

		var loc={
			version = arguments.version
		}

		detailOutput.header("Migration Execution", 50);
		detailOutput.metric("Target Version", loc.version);
		detailOutput.divider();
		var result = $sendToCliCommand("&command=migrateTo&version=#loc.version#");
		if(!local.result.success){
			return;
		}
		
		if (structKeyExists(result, "success") && result.success) {
			detailOutput.statusSuccess("Migration completed successfully!");
		} else {
			detailOutput.statusFailed("Migration failed!");
		}
	}
}