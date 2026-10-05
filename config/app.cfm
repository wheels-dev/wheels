<cfscript>
	/*
		Use this file to set variables for the Application.cfc's "this" scope.

		Examples:
		this.name = "MyAppName";
		this.sessionTimeout = CreateTimeSpan(0,0,5,0);
	*/
	this.name = "wheels-dev";

	// Anchor the H2 file to this app's root (#3689). A relative
	// `jdbc:h2:file:./db/...` resolves against the server process's working
	// directory, which for a LuCLI server is the Lucee Express install, so
	// every checkout on the machine shared (and locked) one database file.
	// expandPath("../") is the app root, as for the SQLite datasources below
	// and in the `wheels new` template.
	this.datasources['wheels-dev'] = {
		class: 'org.h2.Driver'
	, connectionString: "jdbc:h2:file:" & expandPath("../db/h2/wheels-dev") & ";MODE=MySQL"
	, username: 'sa'
	};

	// App tests (/wheels/app/tests, `wheels test`) run on `<datasource>_test`, a
	// separate database, and refuse to run without one.
	this.datasources['wheels-dev_test'] = {
		class: 'org.h2.Driver'
	, connectionString: "jdbc:h2:file:" & expandPath("../db/h2/wheels-dev_test") & ";MODE=MySQL"
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
