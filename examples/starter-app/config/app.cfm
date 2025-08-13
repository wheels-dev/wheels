<cfscript>
	/*
		Place settings that should go in the Application.cfc's "this" scope here.

		Examples:
		this.name = "MyAppName";
		this.sessionTimeout = CreateTimeSpan(0,0,5,0);
	*/

	// Added via CFWheels CLI
	this.name = "starterApp";

	this.datasources["starterApp"] = {
		class: this.env.DB_CLASS, 
		bundleName: this.env.DB_BUNDLENAME, 
		bundleVersion: this.env.DB_BUNDLEVERSION,
		connectionString: "jdbc:mysql://#this.env.DB_HOST#:#this.env.DB_PORT#/#this.env.DB_NAME#?characterEncoding=UTF-8&serverTimezone=UTC&maxReconnects=3",
		username: this.env.DB_USER,
		password: "encrypted:#this.env.DB_PASSWORD#",
		
		// optional settings
		connectionLimit: val(this.env.DB_CONNECTIONLIMIT), // default:-1
		liveTimeout: val(this.env.DB_LIVETIMEOUT), // default: -1; unit: minutes
		alwaysSetTimeout: this.env.DB_ALWAYSSETTIMEOUT EQ "true", // default: false
		validate: this.env.DB_VALIDATE EQ "true" // default: false
		
	};

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
