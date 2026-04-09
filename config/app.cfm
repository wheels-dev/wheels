<cfscript>
	/*
		Use this file to set variables for the Application.cfc's "this" scope.

		Examples:
		this.name = "MyAppName";
		this.sessionTimeout = CreateTimeSpan(0,0,5,0);
	*/
	this.name = "wheels-dev";

	this.datasources['wheels-dev'] = {
		class: 'org.h2.Driver'
	, connectionString: 'jdbc:h2:file:./db/h2/wheels-dev;MODE=MySQL'
	, username: 'sa'
	};

	// CI datasource injection: when WHEELS_CI=true, define SQLite datasources
	// directly so tests can run without Lucee Admin configuration.
	if (server.system.environment.WHEELS_CI ?: "" == "true") {
		this.datasources["wheelstestdb_sqlite"] = {
			class: "org.sqlite.JDBC",
			connectionString: "jdbc:sqlite:#expandPath('../')#wheelstestdb.db"
		};
		this.datasources["wheelstestdb_sqlite_tenant_b"] = {
			class: "org.sqlite.JDBC",
			connectionString: "jdbc:sqlite:#expandPath('../')#wheelstestdb_tenant_b.db"
		};
	}

	// CLI-Appends-Here
</cfscript>
