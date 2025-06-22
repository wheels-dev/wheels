<cfscript>
application.wheels.controllerPath = "/wheels/tests/_assets/controllers";
application.wheels.modelPath = "/wheels/tests/_assets/models";

application.wheels.showDebugInformation = false;

if(structKeyExists(url, "db") && url.db == "sqlserver"){
	createDB = queryExecute(
		"IF NOT EXISTS (
			SELECT *
			FROM sys.databases
			WHERE name = 'wheelstestdb'
			)
		BEGIN
			CREATE DATABASE [wheelstestdb]
		END", {}, {datasource = "msdb_sqlserver"});
}

if(structKeyExists(url, "db") && listFind("mysql,sqlserver,postgres,h2", url.db)){
	application.wheels.dataSourceName = "wheelstestdb_" & url.db;
} else if (application.wheels.coreTestDataSourceName eq "|datasourceName|") {
	application.wheels.dataSourceName = "wheelstestdb";
} else {
	application.wheels.dataSourceName = application.wheels.coreTestDataSourceName;
}

/* For JS Test Runner */
$header(name="Access-Control-Allow-Origin", value="*");

/* turn off default validations for testing */
application.wheels.automaticValidations = false;
application.wheels.assetQueryString = false;
application.wheels.assetPaths = false;

/* redirections should always delay when testing */
application.wheels.functions.redirectTo.delay = true;

/* turn off transactions by default */
application.wheels.transactionMode = "none";

/* turn off request query caching */
application.wheels.cacheQueriesDuringRequest = false;

// CSRF
application.wheels.csrfCookieName = "_wheels_test_authenticity";
application.wheels.csrfCookieEncryptionAlgorithm = "AES";
application.wheels.csrfCookieEncryptionSecretKey = GenerateSecretKey("AES");
application.wheels.csrfCookieEncryptionEncoding = "Base64";

// Setup CSRF token and cookie. The cookie can always be in place, even when the session-based CSRF storage is being
// tested.
dummyController = controller("dummy");
csrfToken = dummyController.$generateCookieAuthenticityToken();

cookie[application.wheels.csrfCookieName] = Encrypt(
	SerializeJSON({authenticityToken = csrfToken}),
	application.wheels.csrfCookieEncryptionSecretKey,
	application.wheels.csrfCookieEncryptionAlgorithm,
	application.wheels.csrfCookieEncryptionEncoding
);

application.testenv.db = $dbinfo(datasource = application.wheels.dataSourceName, type = "version");
</cfscript>
