<cfscript>
	/*
		RustCFML datasource configuration.
		Overrides config/app.cfm for RustCFML which uses native Rust database
		drivers (rusqlite) instead of JDBC.
	*/

	this.datasources["wheelstestdb_sqlite"] = {
		database: "/app/wheelstestdb.db",
		type: "sqlite"
	};

	this.datasources["wheelstestdb_sqlite_tenant_b"] = {
		database: "/app/wheelstestdb_tenant_b.db",
		type: "sqlite"
	};
</cfscript>
