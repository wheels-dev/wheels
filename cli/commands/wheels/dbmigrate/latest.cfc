/**
 * Migration to Latest
 **/
component  aliases='wheels db latest'  extends="../base"  {

	/**
	 * 
	 **/
	function run() {
		var DBMigrateInfo=$sendToCliCommand();
		print.line("Updating Database Schema to Latest Version")
			.line("Latest Version is #DBMigrateInfo.lastVersion#");
		command('wheels dbmigrate exec version=#DBMigrateInfo.lastVersion#').run();
		command('wheels dbmigrate info').run();
	}

}