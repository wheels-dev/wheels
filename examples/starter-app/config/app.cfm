<cfscript>
	/*
		Place settings that should go in the Application.cfc's "this" scope here.

		Examples:
		this.name = "MyAppName";
		this.sessionTimeout = CreateTimeSpan(0,0,5,0);
	*/

	// Added via Wheels CLI
	this.name = "starterApp";

	// Embedded database: boots with no external database server.
	//
	// `wheels start` (the default): SQLite. The Wheels CLI provides the SQLite
	// JDBC driver; the data files are db/development.sqlite and db/test.sqlite.
	// Create the schema with `wheels migrate latest`; see the README.
	//
	// `box server start` (CommandBox): H2. CommandBox's Lucee has no SQLite
	// driver, so server.json installs the H2 extension and sets
	// WHEELS_STARTER_DB=h2, which selects the H2 files under db/h2/.
	//
	// To use a server-based database (MySQL/PostgreSQL/etc.) instead, copy
	// .env.example to .env, fill in your credentials, and swap the datasource
	// definitions below for ones that read this.env.DB_* (see .env.example for
	// the full set of keys).
	if (StructKeyExists(server.system.environment, "WHEELS_STARTER_DB") && server.system.environment.WHEELS_STARTER_DB == "h2") {
		this.datasources["starterApp"] = {
			class: "org.h2.Driver",
			connectionString: "jdbc:h2:file:" & expandPath("../db/h2/starterApp") & ";MODE=MySQL",
			username: "sa"
		};
		// Test database datasource (used by the app test suite).
		this.datasources["starterApp_test"] = {
			class: "org.h2.Driver",
			connectionString: "jdbc:h2:file:" & expandPath("../db/h2/starterApp_test") & ";MODE=MySQL",
			username: "sa"
		};
	} else {
		this.datasources["starterApp"] = {
			class: "org.sqlite.JDBC",
			connectionString: "jdbc:sqlite:" & expandPath("../db/development.sqlite")
		};
		// Test database datasource (used by the app test suite).
		this.datasources["starterApp_test"] = {
			class: "org.sqlite.JDBC",
			connectionString: "jdbc:sqlite:" & expandPath("../db/test.sqlite")
		};
	}

	// buffer the output of a tag/function body to output in case of a exception
	// Currently setting this to true as otherwise you can't do dump then abort in a controller for debugging in
	// Lucee 5.3 and ACF2018(?)
	// Also currently breaks exception handlers if this is false
	this.bufferOutput = true;

	// lifespan of a untouched application scope
	this.applicationTimeout = createTimeSpan( 1, 0, 0, 0 );
	// session handling enabled or not
	this.sessionManagement = true;
	// cfml or jee based sessions
	this.sessionType = "cfml";
	// untouched session lifespan: set to 30 minutes by default here
	this.sessionTimeout = createTimeSpan( 0, 0, 30, 0 );
	//this.sessionStorage = "oxfordlieder_sessions";
	this.sessionStorage = "memory";

	// client scope enabled or not
	this.clientManagement = false;
	this.clientTimeout = createTimeSpan( 90, 0, 0, 0 );
	this.clientStorage = "cookie";

	// using domain cookies or not
	this.setDomainCookies = false;
	this.setClientCookies = true;

	this.sessioncookie.httponly = true;
	this.sessioncookie.encodedvalue = true;
	// Set cookies to SSL Only
	// Set this to true if you're Using SSL!
	// Only set to false for easy local development
	if ((cgi.server_name != "127.0.0.1" && cgi.server_name != "localhost")) {
		this.sessioncookie.secure = true;
	} else {
		this.sessioncookie.secure = false;
	}

	// max lifespan of a running request
	this.requestTimeout=createTimeSpan(0,0,0,50);

	// charset
	this.charset.web="UTF-8";
	this.charset.resource="UTF-8";

	// This assumes you're using a local smtp server to deliver mail, such as papercut on wind0ze.
	// You'll either want to delete this block or add your own SMTP at /lucee/admin/server.cfm
	if(cgi.server_name CONTAINS "127.0.0.1" || cgi.server_name CONTAINS "localhost"){
		// Default Development STMP Server
		this.tag.mail.server="127.0.0.1";
		this.tag.mail.port=25;
	}
</cfscript>
