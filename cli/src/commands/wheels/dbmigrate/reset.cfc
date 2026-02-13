/**
 * Migration to version 0
 **/
component  aliases='wheels db reset'  extends="../base"  {

	/**
	 * 
	 **/
	function run() {
		try{
			var DBMigrateInfo=$sendToCliCommand();
			if(!DBMigrateInfo.success){
				return;
			}
			print.line("Resetting Database Schema").toConsole();
			command('wheels dbmigrate exec').params(version=0).run();
			command('wheels dbmigrate info').run();
		} catch (any e) {
			detailOutput.error("#e.message#");
			setExitCode(1);
		}
	}

}