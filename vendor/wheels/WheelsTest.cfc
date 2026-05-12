/**
 * Base WheelsTest spec for Wheels tests.
 * Dynamically binds methods from `application.wo` into both
 * the `variables` and `this` scope for convenience.
 *
 * This is the primary base class for BDD-style tests in Wheels.
 * Extends: wheels.Testbox (deprecated) → wheels.WheelsTest (current)
 */
component extends="wheels.wheelstest.system.BaseSpec" {

    // Pseudo-constructor (runs automatically)
    if (structKeyExists(application, "wo")) {
        local.methods = getMetaData(application.wo).functions;

        for (local.method in local.methods) {
            // Only add public, non-inherited methods
            if (local.method.access eq "public") {
                local.methodExists = structKeyExists(variables, local.method.name) || structKeyExists(this, local.method.name);

                if (!local.methodExists) {
                    variables[local.method.name] = application.wo[local.method.name];
                    this[local.method.name]      = application.wo[local.method.name];
                }
            }
        }
    }

    /**
     * Create a TestClient and visit the given path (HTTP GET).
     * Returns the TestClient for fluent assertion chaining.
     *
     * Usage in tests:
     *   visit("/users").assertOk().assertSee("John")
     *
     * @path URL path to visit
     */
    public any function visit(required string path) {
        return $testClient().get(arguments.path);
    }

    /**
     * Return a configured TestClient instance.
     * The base URL is auto-detected from the current server port.
     */
    public any function $testClient() {
        return new wheels.wheelstest.TestClient(baseUrl = $getTestBaseUrl());
    }

    /**
     * Auto-detect the base URL of the running test server.
     */
    private string function $getTestBaseUrl() {
        var port = CGI.SERVER_PORT;
        if (!Len(port) || port == 0) {
            port = 8080;
        }
        return "http://localhost:" & port;
    }

}
