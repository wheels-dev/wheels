/**
 * Get configuration values
 *
 * {code:bash}
 * wheels get environment
 * wheels get settings
 * wheels get settings cacheQueries
 * {code}
 */
component extends="base" {

	/**
	 * @help Get environment or settings values
	 */
	public void function run() {
		print.line("Usage: wheels get <environment|settings> [settingName]");
		print.line("");
		print.line("Examples:");
		print.line("  wheels get environment      - Show current environment");
		print.line("  wheels get settings         - Show all settings");
		print.line("  wheels get settings cache   - Show cache-related settings");
	}

}