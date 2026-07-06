/**
 * Specs for wheels.wheelstest.EngineCapabilities — the JVM capability probes
 * that let browser tests and system-property-stashing specs skip cleanly on
 * engines without a JVM (e.g. RustCFML) instead of erroring mid-setup.
 */
component extends="wheels.WheelsTest" {

    function run() {

        describe("EngineCapabilities JVM probes", () => {

            it("hasJvmClassLoading returns a boolean and is stable across calls (cached)", () => {
                var caps = new wheels.wheelstest.EngineCapabilities();
                var first = caps.hasJvmClassLoading();
                expect(IsBoolean(first)).toBeTrue();
                expect(caps.hasJvmClassLoading()).toBe(first);
            });

            it("canWriteSystemProperties returns a boolean and is stable across calls (cached)", () => {
                var caps = new wheels.wheelstest.EngineCapabilities();
                var first = caps.canWriteSystemProperties();
                expect(IsBoolean(first)).toBeTrue();
                expect(caps.canWriteSystemProperties()).toBe(first);
            });

            it("both probes return true on JVM engines", () => {
                if (application.wheels.engineAdapter.isRustCFML()) {
                    debug("Skipping: non-JVM engine — the probes legitimately report false here");
                    return;
                }
                var caps = new wheels.wheelstest.EngineCapabilities();
                expect(caps.hasJvmClassLoading()).toBeTrue();
                expect(caps.canWriteSystemProperties()).toBeTrue();
            });

            it("canWriteSystemProperties leaves no probe-key residue behind", () => {
                var caps = new wheels.wheelstest.EngineCapabilities();
                if (!caps.canWriteSystemProperties()) {
                    debug("Skipping: system properties not writable on this engine, nothing to inspect");
                    return;
                }
                var leftover = createObject("java", "java.lang.System").getProperty("wheels.capabilityProbe");
                expect(isNull(leftover)).toBeTrue("expected the wheels.capabilityProbe property to be cleared after probing");
            });

            it("BrowserLauncher exposes a working probe via $engineCapabilities()", () => {
                var launcher = new wheels.wheelstest.BrowserLauncher();
                var probe = launcher.$engineCapabilities();
                expect(IsBoolean(probe.hasJvmClassLoading())).toBeTrue();
                // Repeat call keeps working (the cache key must not shadow the
                // function name in the variables scope).
                expect(IsBoolean(launcher.$engineCapabilities().hasJvmClassLoading())).toBeTrue();
            });

        });

    }

}
