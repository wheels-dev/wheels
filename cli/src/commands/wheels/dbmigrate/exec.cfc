/**
 * Migrate to Version x
 *
 * wheels dbmigrate exec 20160730115754
 * wheels dbmigrate exec 0
 **/
component aliases='wheels db exec' extends="../base" {

	/**
	 *  Migrate to specific version
	 * @version.hint Version to migrate to
	 **/
	function run( required string version	) {
t		// Reconstruct arguments for handling --prefixed options
		arguments = reconstructArgs(arguments);

		var loc={
			version = arguments.version
		}

		print.line("DBMigrateBridge > MigrateTo > #loc.version#");
		print.redline($sendToCliCommand("&command=migrateTo&version=#loc.version#").message);
	}
}