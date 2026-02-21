<cfscript>
		// CSRF protection settings.
		application.$wheels.csrfStore = "session";
		application.$wheels.csrfCookieEncryptionAlgorithm = "AES";
		application.$wheels.csrfCookieEncryptionSecretKey = "";
		application.$wheels.csrfCookieEncryptionEncoding = "Base64";
		application.$wheels.csrfCookieName = "_wheels_authenticity";
		application.$wheels.csrfCookieDomain = "";
		application.$wheels.csrfCookieEncodeValue = "";
		application.$wheels.csrfCookieHttpOnly = "";
		application.$wheels.csrfCookiePath = "/";
		application.$wheels.csrfCookiePreserveCase = "";
		application.$wheels.csrfCookieSecure = "";

		// CORS (Cross-Origin Resource Sharing) settings.
		application.$wheels.allowCorsRequests = false;
		application.$wheels.accessControlAllowOrigin = "*";
		application.$wheels.accessControlAllowMethods = "GET, POST, PATCH, PUT, DELETE, OPTIONS";
		application.$wheels.accessControlAllowMethodsByRoute = false;
		application.$wheels.accessControlAllowCredentials = false;
		application.$wheels.accessControlAllowHeaders = "Origin, Content-Type, X-Auth-Token, X-Requested-By, X-Requested-With";

		// IP based restriction settings
		application.$wheels.debugAccessIPs = [];
		application.$wheels.allowIPBasedDebugAccess = false;
</cfscript>
