component extends="wheels.WheelsTest" {

    /**
     * Covers the MockBox expectation-verification surface: createEmptyMock()
     * stub generation plus the injected call-count assertions ($count/$once/
     * $times/$never/$atLeast/$atMost) and the illegal-state guards for the
     * fluent expectation builders ($callback/$throws/$args) called outside a
     * $() chain. Exercising createEmptyMock also drives MockGenerator
     * (generateMethodsFromMD/generateClass/writeStub/outputQuotedValue).
     */
    function run() {

        describe("MockBox verification surface", () => {

            beforeEach(() => {
                mb = new wheels.wheelstest.system.MockBox();
            });

            it("createEmptyMock() generates a stub with no methods", () => {
                var mock = mb.createEmptyMock(className = "wheels.wheelstest.system.util.Util");
                expect(isObject(mock)).toBeTrue();
                expect(structKeyExists(mock, "slugify")).toBeFalse();
            });

            it("$count()/$once()/$times()/$never()/$atLeast()/$atMost() verify call counts", () => {
                var mock = mb.createEmptyMock(className = "wheels.wheelstest.system.util.Util");
                expect(mock.$count()).toBe(0);
                expect(mock.$count(methodName = "slugify")).toBe(-1);
                expect(mock.$never()).toBeTrue();
                expect(mock.$once()).toBeFalse();

                mock.$("slugify").$results("ok");
                mock.slugify("hello world");
                mock.slugify("second call");

                expect(mock.$count(methodName = "slugify")).toBe(2);
                expect(mock.$once(methodName = "slugify")).toBeFalse();
                expect(mock.$times(count = 2, methodName = "slugify")).toBeTrue();
                expect(mock.$never(methodName = "slugify")).toBeFalse();
                expect(mock.$atLeast(minNumberOfInvocations = 2, methodName = "slugify")).toBeTrue();
                expect(mock.$atMost(maxNumberOfInvocations = 2, methodName = "slugify")).toBeTrue();
            });

            it("$callback()/$throws()/$args() outside a $() chain throw illegal-state errors", () => {
                // The verification state lives on the MOCK, not the bare
                // MockBox instance.
                var mock = mb.createEmptyMock(className = "wheels.wheelstest.system.util.Util");
                expect(() => mock.$callback(target = function() {
                    return 1;
                })).toThrow(type = "MockFactory.IllegalStateException");
                expect(() => mock.$throws()).toThrow(type = "MockFactory.IllegalStateException");
                expect(() => mock.$args()).toThrow(type = "MockBox.IllegalStateException");
            });

            it("$debug() returns the debug struct and $reset() clears state", () => {
                var mock = mb.createEmptyMock(className = "wheels.wheelstest.system.util.Util");
                expect(mock.$debug()).toBeStruct();
                mock.$reset();
                expect(mock.$count()).toBe(0);
            });

        });

    }

}
