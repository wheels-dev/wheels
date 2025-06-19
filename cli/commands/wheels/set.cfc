/**
 * Set configuration values
 *
 * {code:bash}
 * wheels set environment development
 * wheels set settings cacheQueries false
 * wheels set datasource myapp
 * {code}
 */
component extends="base" {

	/**
	 * @help Set environment, settings, or datasource values
	 */
	public void function run() {
		print.line("Usage: wheels set <environment|settings|datasource> <value>");
		print.line("");
		print.line("Examples:");
		print.line("  wheels set environment production");
		print.line("  wheels set settings cacheQueries true");
		print.line("  wheels set datasource myapp");
	}

}