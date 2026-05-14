component extends="wheels.WheelsTest" {

    function run() {

        describe("TextReporter", function() {

            it("runs report without throwing 'Page not found' for missing asset template", function() {
                var reporter = new wheels.wheelstest.system.reports.TextReporter();
                var results = new wheels.wheelstest.system.TestResult();
                var testbox = new wheels.wheelstest.system.TestBox();
                expect(function() {
                    reporter.runReport(
                        results    = results,
                        testbox    = testbox,
                        options    = {},
                        justReturn = true
                    );
                }).notToThrow();
            });

            it("returns a non-empty plain-text report for an empty result set", function() {
                var reporter = new wheels.wheelstest.system.reports.TextReporter();
                var results = new wheels.wheelstest.system.TestResult();
                var testbox = new wheels.wheelstest.system.TestBox();
                var output = reporter.runReport(
                    results    = results,
                    testbox    = testbox,
                    options    = {},
                    justReturn = true
                );
                expect(isSimpleValue(output)).toBeTrue();
                expect(len(trim(output))).toBeGT(0);
            });

        });

    }

}
