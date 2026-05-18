<cfscript>
	/*
		RustCFML-specific settings for the Wheels test suite.
		Only SQLite is configured — RustCFML uses native Rust database drivers,
		not JDBC, so the datasource configuration differs from Lucee/ACF.
	*/

	set(coreTestDataSourceName="wheelstestdb_sqlite");
	set(dataSourceName="wheelstestdb_sqlite");

	set(URLRewriting="On");
	set(reloadPassword="");

	// CLI-Appends-Here
</cfscript>
