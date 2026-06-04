component extends="wheels.WheelsTest" {

    function run() {

        describe("BDDRunner load/run-time error reporting", function() {

            it("captures an it() call outside describe() against the bundle instead of bubbling out", function() {
                // Reproduces issue #2829, case 1: a spec whose run() calls
                // it() at the top level (no enclosing describe) currently
                // bubbles up as a BundleRunnerMajorException, leaving the
                // CLI summary at "0 passed" with no filename or message.
                var testBox = new wheels.wheelstest.system.TestBox(
                    bundles = ["wheels.tests.resources.wheelstest.OrphanItFixture"]
                );
                var state = {threw: false, results: ""};
                try {
                    state.results = testBox.runRaw();
                } catch (any e) {
                    state.threw = true;
                }
                expect(state.threw).toBeFalse();
                expect(isObject(state.results)).toBeTrue();
                expect(state.results.getTotalError()).toBe(1);
                var bs = state.results.getBundleStats();
                expect(arrayLen(bs)).toBeGT(0);
                expect(bs[1].totalError).toBe(1);
                expect(bs[1].path).toInclude("OrphanItFixture");
                expect(isStruct(bs[1].globalException) || isObject(bs[1].globalException)).toBeTrue();
            });

            it("uses a positive error count when beforeAll() throws during spec load", function() {
                // Reproduces issue #2829, case 2: a spec whose beforeAll()
                // throws records totalError = -1, which sums into the global
                // count as "-1 error(s)" with no file context.
                var testBox = new wheels.wheelstest.system.TestBox(
                    bundles = ["wheels.tests.resources.wheelstest.BeforeAllErrorFixture"]
                );
                var results = testBox.runRaw();
                expect(results.getTotalError()).toBe(1);
                var bs = results.getBundleStats();
                expect(arrayLen(bs)).toBeGT(0);
                expect(bs[1].totalError).toBe(1);
                expect(bs[1].path).toInclude("BeforeAllErrorFixture");
                expect(isStruct(bs[1].globalException) || isObject(bs[1].globalException)).toBeTrue();
            });

        });

    }

}
