component {
    // Setup the test environment
    function setTestboxEnvironment() {
        // creating backup for original environment
        if (structKeyExists(server, "boxlang")) {
            application.$$$wheels = {}
            for (local.key in application.wheels) {
                if (IsSimpleValue(application.wheels[local.key]) || IsArray(application.wheels[local.key]) || IsStruct(application.wheels[local.key])) {
                    application.$$$wheels[local.key] = application.wheels[local.key]
                }
            }
        } else {
            application.$$$wheels = Duplicate(application.wheels)
        }

        // load testbox routes
        application.wo.$include(template = "/tests/routes.cfm")
        application.wo.$setNamedRoutePositions()

        local.AssetPath = "/tests/_assets/"
        
        application.wo.set(rewriteFile = "index.cfm")
        application.wo.set(controllerPath = local.AssetPath & "controllers")
        application.wo.set(viewPath = local.AssetPath & "views")
        application.wo.set(modelPath = local.AssetPath & "models")
        application.wo.set(wheelsComponentPath = "/wheels")

        /* turn off default validations for testing */
        application.wheels.automaticValidations = false
        application.wheels.assetQueryString = false
        application.wheels.assetPaths = false

        /* redirections should always delay when testing */
        application.wheels.functions.redirectTo.delay = true

        /* enable transactions for proper test isolation */
        application.wheels.transactionMode = "commit"

        /* turn off request query caching */
        application.wheels.cacheQueriesDuringRequest = false

        // CSRF
        application.wheels.csrfCookieName = "_wheels_test_authenticity"
        application.wheels.csrfCookieEncryptionAlgorithm = "AES"
        application.wheels.csrfCookieEncryptionSecretKey = GenerateSecretKey("AES")
        application.wheels.csrfCookieEncryptionEncoding = "Base64"

        // Setup CSRF token and cookie. The cookie can always be in place, even when the session-based CSRF storage is being
        // tested.
        dummyController = application.wo.controller("dummy")
        csrfToken = dummyController.$generateCookieAuthenticityToken()

        cookie[application.wheels.csrfCookieName] = Encrypt(
            SerializeJSON({authenticityToken = csrfToken}),
            application.wheels.csrfCookieEncryptionSecretKey,
            application.wheels.csrfCookieEncryptionAlgorithm,
            application.wheels.csrfCookieEncryptionEncoding
        )
        if(structKeyExists(url, "db") && listFind("mysql,sqlserver,postgres,h2", url.db)){
            application.wheels.dataSourceName = "wheelstestdb_" & url.db;
        } else if (application.wheels.coreTestDataSourceName eq "|datasourceName|") {
            application.wheels.dataSourceName = "wheelstestdb"; 
        } else {
            application.wheels.dataSourceName = application.wheels.coreTestDataSourceName;
        }
        application.testenv.db = application.wo.$dbinfo(datasource = application.wheels.dataSourceName, type = "version")

        local.populate = StructKeyExists(url, "populate") ? url.populate : true
        if (local.populate) {
            include "/tests/populate.cfm"
        }
    }
}