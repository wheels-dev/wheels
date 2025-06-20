/**
 * Migration to version 0
 **/
component  aliases='wheels db reset'  extends="../base"  {

	/**
	 * 
	 **/
	function run() {
		var DBMigrateInfo=$sendToCliCommand();
		print.line("Resetting Database Schema");
		command('wheels dbmigrate exec').params(version=0).run();
		command('wheels dbmigrate info').run();
	}

}