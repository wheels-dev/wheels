<cfscript>
application.wheels.controllerPath = "/wheels/rocketunit_tests/_assets/controllers";
application.wheels.modelPath = "/wheels/rocketunit_tests/_assets/models";

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

// Same datasource rule as the core runner: never the app's primary datasource
// unless the request asks for it (useTestDB=false).
coreDataSource = $coreTestDataSource(
	primary = application.wheels.dataSourceName,
	coreName = StructKeyExists(application.wheels, "coreTestDataSourceName") ? application.wheels.coreTestDataSourceName : application.wheels.dataSourceName,
	requestUrl = url,
	testDbList = "mysql,sqlserver,postgres,h2,cockroachdb"
);
if (coreDataSource.action == "refuse") {
	cfheader(statuscode = 409);
	cfcontent(type = "application/json");
	WriteOutput(SerializeJSON({
		success = false,
		error = "Test database not available",
		message = coreDataSource.message,
		datasource = coreDataSource.decision.primary,
		candidate = coreDataSource.decision.candidate
	}));
	abort;
}
application.wheels.dataSourceName = coreDataSource.target;

/* For JS Test Runner */
$header(name="Access-Control-Allow-Origin", value="*");

/* set migration level for tests*/
application.wheels.migrationLevel = 2;

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
// csrfCookieEncryptionAlgorithm is intentionally not overridden here — tests run
// against the engine-aware framework default resolved in events/init/security.cfm
// (AES/GCM/NoPadding where the engine supports it, random-IV CBC otherwise).
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
