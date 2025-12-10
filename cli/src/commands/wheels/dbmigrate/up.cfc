/**
 * Migration one version UP
 **/
component aliases='wheels db up' extends="../base" {

	property name="detailOutput" inject="DetailOutputService@wheels-cli";

	/**
	 *
	 **/
	function run() {
		var DBMigrateInfo = $sendToCliCommand();
		if(!DBMigrateInfo.success){
			return;
		}
		var migrations = DBMigrateInfo.migrations;

		// Check we're not already at the latest version
		if (DBMigrateInfo.currentVersion == DBMigrateInfo.lastVersion) {
			detailOutput.statusSuccess("We're all up to date already!");
			return;
		}

		// Get current version as an index of the migration array
		var currentIndex = 0;
		var newIndex = 0;
		migrations.each(function(migration, i, array) {
			if (migration.version == DBMigrateInfo.currentVersion) {
				currentIndex = i;
			}
		});

		if (currentIndex < arrayLen(migrations)) {
			newIndex = ++currentIndex;
			detailOutput.statusInfo("Migrating to #migrations[newIndex]['cfcfile']#");
			detailOutput.migrate(migrations[newIndex]['cfcfile']);
			
			command('wheels dbmigrate exec')
				.params(version = migrations[newIndex]["version"])
				.run();
		} else {
			detailOutput.statusWarning("No more versions to go to?");
		}		
		detailOutput.separator();
		command('wheels dbmigrate info').run();
	}

}