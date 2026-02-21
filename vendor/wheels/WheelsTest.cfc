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

}
