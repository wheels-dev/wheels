component extends="wheels.WheelsTest" {
    function run() {
        describe("Runner spec selection", function() {
            it("selects a spec by its name case-insensitively", function() {
                var runner = new wheels.wheelstest.system.runners.BaseRunner();
                var result = new wheels.wheelstest.system.TestResult(testSpecs = ["SUBMITS A CART"]);
                expect(runner.canRunSpec({id: "abc123", name: "submits a cart"}, result)).toBeTrue();
            });
            it("keeps ID selection case-insensitive", function() {
                var runner = new wheels.wheelstest.system.runners.BaseRunner();
                var result = new wheels.wheelstest.system.TestResult(testSpecs = ["ABC123"]);
                expect(runner.canRunSpec({id: "abc123", name: "submits a cart"}, result)).toBeTrue();
            });
            it("skips a spec when neither its name nor ID matches", function() {
                var runner = new wheels.wheelstest.system.runners.BaseRunner();
                var result = new wheels.wheelstest.system.TestResult(testSpecs = ["another spec"]);
                expect(runner.canRunSpec({id: "abc123", name: "submits a cart"}, result)).toBeFalse();
            });
            it("runs all specs without a selection filter", function() {
                var runner = new wheels.wheelstest.system.runners.BaseRunner();
                var result = new wheels.wheelstest.system.TestResult();
                expect(runner.canRunSpec({id: "abc123", name: "submits a cart"}, result)).toBeTrue();
            });
        });
    }
}
