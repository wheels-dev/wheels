/**
 * Provides information about the CLI module, and also any identified wheels version
 *
 * {code:bash}
 * wheels info
 * {code}
 **/
component  extends="base"  {

	property name='fileSystem' inject='fileSystem';
	/**
	 *
	 **/
	function run(  ) {
		var current={
			directory		= getCWD(),
			moduleRoot		= expandPath("/wheels-cli/"),
			wheelsVersion	= $getWheelsVersion()
		};
		print.redLine(",--.   ,--.,--.                   ,--.            ,-----.,--.   ,--. ")
			.redLine("|  |   |  ||  ,---.  ,---.  ,---. |  | ,---.     '  .--./|  |   |  | ")
			.redLine("|  |.'.|  ||  .-.  || .-. :| .-. :|  |(  .-'     |  |    |  |   |  | ")
			.redLine("|   ,'.   ||  | |  |\   --.\   --.|  |.-'  `)    '  '--'\|  '--.|  | ")
			.redLine("'--'   '--'`--' `--' `----' `----'`--'`----'      `-----'`-----'`--' ")
			.yellowBoldLine( "============================ Wheels CLI ============================" )
			.yellowBoldLine( "Current Working Directory: #current.directory#")
			.yellowBoldLine( "CommandBox Module Root: #current.moduleRoot#")
			.yellowBoldLine( "Current Wheels Version in this directory: #current.wheelsVersion#")
			.yellowBoldLine( "====================================================================" );
	}

}
