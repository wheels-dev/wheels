/**
 * Provides information about the CLI module, and also any identified wheels version
 *
 * {code:bash}
 * wheels info
 * {code}
 **/
component extends="base" {

	property name='fileSystem' inject='fileSystem';
	/**
	 *
	 **/
	function run() {
		// Gather system info
		local.current = {
			directory = getCWD(),
			moduleRoot = expandPath("/wheels-cli/"),
			wheelsVersion = $getWheelsVersion(),
			serverInfo = serverService.resolveServerDetails(serverProps={ webroot=getCWD() })
		};
		
		// Display Wheels logo
		print.line();
		print.cyanLine(" ,-----.,------.,--.   ,--.,--.                 ,--.");
		print.cyanLine("'  .--./|  .---'|  |   |  ||  ,---.  ,---.  ,--.|  | ,---.");
		print.cyanLine("|  |    |  `--, |  |.'.|  ||  .-.  || .-. :|  |)|  |(  .-'");
		print.cyanLine("'  '--'\|  |`   |   ,'.   ||  | |  |\   --.|  `.|  |.-'  `)");
		print.cyanLine(" `-----'`--'    '--'   '--'`--' `--' `----'`---'`--'`----'");
		print.line();
		
		// Display main information
		Style.commandHeader("WHEELS INFO");
		
		// System information
		Style.sectionHeader("System Information");
		
		local.sysInfoTable = [
			["Wheels Version", local.current.wheelsVersion],
			["CommandBox Module", local.current.moduleRoot],
			["Working Directory", local.current.directory]
		];
		
		// Try to add server information if available
		if (isDefined("local.current.serverInfo.serverInfo")) {
			local.serverInfo = local.current.serverInfo.serverInfo;
			arrayAppend(local.sysInfoTable, ["Server Status", structKeyExists(local.serverInfo, "status") ? local.serverInfo.status : "Unknown"]);
			
			if (structKeyExists(local.serverInfo, "name")) {
				arrayAppend(local.sysInfoTable, ["Server Name", local.serverInfo.name]);
			}
			
			if (structKeyExists(local.serverInfo, "engineName")) {
				arrayAppend(local.sysInfoTable, ["Engine", local.serverInfo.engineName & " " & (structKeyExists(local.serverInfo, "engineVersion") ? local.serverInfo.engineVersion : "")]);
			}
			
			if (structKeyExists(local.serverInfo, "host") && structKeyExists(local.serverInfo, "port")) {
				arrayAppend(local.sysInfoTable, ["URL", "http://" & local.serverInfo.host & ":" & local.serverInfo.port]);
			}
		}
		
		Style.table(local.sysInfoTable);
		
		// Get installed plugins
		local.pluginsCommand = $sendToCliCommand(urlstring="&command=pluginsList");
		
		if (structKeyExists(local.pluginsCommand, "plugins") && isArray(local.pluginsCommand.plugins) && arrayLen(local.pluginsCommand.plugins) > 0) {
			Style.sectionHeader("Installed Plugins");
			
			local.pluginsTable = [];
			
			for (local.plugin in local.pluginsCommand.plugins) {
				local.version = structKeyExists(local.plugin, "version") ? local.plugin.version : "Unknown";
				local.author = structKeyExists(local.plugin, "author") ? local.plugin.author : "Unknown";
				local.status = structKeyExists(local.plugin, "enabled") && local.plugin.enabled ? "Enabled" : "Disabled";
				
				arrayAppend(local.pluginsTable, [local.plugin.name, local.version, local.author, local.status]);
			}
			
			Style.table(local.pluginsTable, ["Plugin", "Version", "Author", "Status"]);
		}
		
		// Show helpful tips
		Style.sectionHeader("Helpful Commands");
		
		local.commands = [
			"wheels watch - Monitor file changes and auto-reload",
			"wheels test - Run application tests",
			"wheels generate controller Users - Create a new controller",
			"wheels dbmigrate up - Run database migrations"
		];
		
		Style.bulletList(local.commands);
		
		// Show docs link
		Style.info("For more information, visit https://wheels.dev/docs");
		print.line();
	}
}
