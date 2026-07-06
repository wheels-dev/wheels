/**
 * JVM capability probes for the test framework. Some engines (e.g. RustCFML)
 * run without a JVM: createObject("java", ...) can succeed anyway because it
 * returns a lazy stub, and java.lang.System property writes can be lossy.
 * These probes answer "can this engine actually do the JVM-backed thing?"
 * truthfully by exercising the behavior, not just constructing objects.
 *
 * Results are cached per instance in the variables scope as plain booleans —
 * never store function references anywhere an Adobe CF application scope
 * might receive them.
 */
component output="false" {

    /**
     * True when the engine exposes real JVM class loading — i.e.
     * java.lang.ClassLoader.getPlatformClassLoader() actually executes.
     * A bare createObject("java", "java.lang.ClassLoader") succeeds on
     * RustCFML (lazy stub), so the probe MUST call a method to be truthful.
     * BrowserLauncher requires this for its Playwright URLClassLoader.
     */
    public boolean function hasJvmClassLoading() {
        if (!structKeyExists(variables, "jvmClassLoadingResult")) {
            // Struct field instead of a bare local: local.X writes inside
            // catch blocks don't persist on BoxLang (Cross-Engine Invariant 11).
            var state = {available = false};
            try {
                var loader = createObject("java", "java.lang.ClassLoader").getPlatformClassLoader();
                if (!isNull(loader)) {
                    state.available = true;
                }
            } catch (any e) {
                // No JVM behind the object (or ClassLoader inaccessible):
                // capability absent. state.available stays false.
            }
            variables.jvmClassLoadingResult = state.available;
        }
        return variables.jvmClassLoadingResult;
    }

    /**
     * True when java.lang.System property writes round-trip: setProperty on
     * one System object is visible via getProperty on a FRESH System object.
     * The fresh-instance re-read defends against a known engine bug where
     * setProperty nulls the receiver variable, which would otherwise
     * false-negative a working write (and NPE a re-read on the same handle).
     * Used to guard specs that stash/restore JVM system properties.
     */
    public boolean function canWriteSystemProperties() {
        if (!structKeyExists(variables, "systemPropertiesResult")) {
            variables.systemPropertiesResult = $probeSystemProperties();
        }
        return variables.systemPropertiesResult;
    }

    /**
     * Uncached probe body for canWriteSystemProperties(). Round-trips a
     * throwaway key so real config keys are never touched, and best-effort
     * clears it afterward so no probe residue leaks into later reads.
     */
    public boolean function $probeSystemProperties() {
        var state = {ok = false};
        var probeKey = "wheels.capabilityProbe";
        var probeValue = "probe-" & createUUID();
        try {
            createObject("java", "java.lang.System").setProperty(probeKey, probeValue);
            // Re-read via a FRESH System instance — see function comment.
            var readBack = createObject("java", "java.lang.System").getProperty(probeKey);
            if (!isNull(readBack) && readBack == probeValue) {
                state.ok = true;
            }
        } catch (any e) {
            // Any throw = capability absent. state.ok stays false.
        }
        // Best-effort cleanup in its own try so a clearProperty failure can
        // never flip an otherwise-decided result.
        try {
            createObject("java", "java.lang.System").clearProperty(probeKey);
        } catch (any e) {
            // Swallow: leaving the throwaway key behind is harmless compared
            // to mis-reporting the capability.
        }
        return state.ok;
    }

}
