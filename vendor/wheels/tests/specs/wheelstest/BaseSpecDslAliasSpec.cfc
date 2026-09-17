component extends="wheels.WheelsTest" {

    /**
     * Covers the BaseSpec DSL surface that the BDD specs never touch directly:
     * the story/feature/given/scenario/when aliases (plus their focused and
     * x-skipped variants), the then/test/fit/ftest/xtest spec aliases, the
     * assertion facade (assert/fail/expectedException/addAssertions),
     * expectAll collection unrolling, and the utility helpers (querySim,
     * debug buffer, print/println, engine predicates, getProperty).
     *
     * Everything drives a BARE BaseSpec instance — the aliases record suite
     * state on the instance without being executed by a runner, so the
     * focused variants cannot hijack this run.
     */
    function run() {

        describe("BaseSpec DSL surface", () => {

            beforeEach(() => {
                spec = new wheels.wheelstest.system.BaseSpec();
            });

            describe("BDD aliases", () => {

                it("story() registers a suite titled 'Story: ...'", () => {
                    spec.story("login", () => {});
                    expect(arrayLen(spec.$suites)).toBe(1);
                    expect(spec.$suites[1].name).toBe("Story: login");
                });

                it("feature() registers a suite titled 'Feature: ...'", () => {
                    spec.feature("checkout", () => {});
                    expect(spec.$suites[1].name).toBe("Feature: checkout");
                });

                it("given() registers a suite titled 'Given ...'", () => {
                    spec.given("a user", () => {});
                    expect(spec.$suites[1].name).toBe("Given a user");
                });

                it("scenario() registers a suite titled 'Scenario: ...'", () => {
                    spec.scenario("happy path", () => {});
                    expect(spec.$suites[1].name).toBe("Scenario: happy path");
                });

                it("when() registers a suite titled 'When ...'", () => {
                    spec.when("clicked", () => {});
                    expect(spec.$suites[1].name).toBe("When clicked");
                });

                it("fdescribe()/fstory()/ffeature()/fgiven()/fscenario()/fwhen() mark suites focused", () => {
                    spec.fdescribe("focused describe", () => {});
                    spec.fstory("focused story", () => {});
                    spec.ffeature("focused feature", () => {});
                    spec.fgiven("focused given", () => {});
                    spec.fscenario("focused scenario", () => {});
                    spec.fwhen("focused when", () => {});
                    expect(arrayLen(spec.$focusedTargets.suites)).toBe(6);
                    expect(spec.$focusedTargets.suites).toInclude("/focused describe");
                    expect(spec.$focusedTargets.suites).toInclude("/Story: focused story");
                });

                it("x-variants register skipped suites", () => {
                    spec.xdescribe("skipped", () => {});
                    spec.xstory("skipped story", () => {});
                    spec.xfeature("skipped feature", () => {});
                    spec.xgiven("skipped given", () => {});
                    spec.xscenario("skipped scenario", () => {});
                    spec.xwhen("skipped when", () => {});
                    for (var suite in spec.$suites) {
                        expect(suite.skip).toBeTrue();
                    }
                });

                it("then() registers a spec titled 'Then ...'", () => {
                    spec.describe("suite", () => {
                        spec.then("the outcome is visible", () => {});
                    });
                    expect(spec.$suites[1].specs[1].name).toBe("Then the outcome is visible");
                });

                it("fthen()/fit()/ftest() record focused specs", () => {
                    spec.describe("suite", () => {
                        spec.fthen("focused then", () => {});
                        spec.fit("focused it", () => {});
                        spec.ftest("focused test", () => {});
                    });
                    expect(arrayLen(spec.$focusedTargets.specs)).toBe(3);
                    expect(spec.$focusedTargets.specs[1]).toInclude("/suite/Then focused then");
                });

                it("test()/xtest()/xthen() record specs with skip semantics", () => {
                    spec.describe("suite", () => {
                        spec.test("plain test", () => {});
                        spec.xtest("skipped test", () => {});
                        spec.xthen("skipped then", () => {});
                    });
                    expect(spec.$suites[1].specs[1].name).toBe("plain test");
                    expect(spec.$suites[1].specs[2].skip).toBeTrue();
                    expect(spec.$suites[1].specs[3].skip).toBeTrue();
                });

            });

            describe("assertion facade", () => {

                it("assert() passes for truthy expressions and throws on falsy", () => {
                    expect(() => spec.assert(expression = (2 + 2 == 4))).notToThrow();
                    expect(() => spec.assert(expression = (2 + 2 == 5), message = "math broke"))
                        .toThrow(type = "TestBox.AssertionFailed");
                });

                it("fail() always throws TestBox.AssertionFailed", () => {
                    expect(() => spec.fail(message = "boom")).toThrow(type = "TestBox.AssertionFailed");
                });

                it("expectedException() records type and regex on the spec", () => {
                    spec.expectedException(type = "Wheels.CustomError", regex = "must .*");
                    expect(spec.$expectedException.type).toBe("Wheels.CustomError");
                    expect(spec.$expectedException.regex).toBe("must .*");
                });

                it("addAssertions() registers struct-based custom assertions on the assert object", () => {
                    spec.addAssertions({
                        isEven = function(actual) {
                            return actual mod 2 == 0;
                        }
                    });
                    // Custom assertions are plain predicates: they RETURN the
                    // verdict instead of throwing (the built-in matchers wrap
                    // the boolean into a fail()).
                    expect(spec.$assert.isEven(4)).toBeTrue();
                    expect(spec.$assert.isEven(3)).toBeFalse();
                });

            });

            describe("expectAll collection unrolling", () => {

                it("unrolls an array through the matcher", () => {
                    spec.expectAll([1, 2, 3]).toBeNumeric();
                    expect(isObject(spec.expectAll([]).toBeArray())).toBeTrue();
                });

                it("unrolls a struct through the matcher", () => {
                    spec.expectAll({a = 1, b = 2}).toBeNumeric();
                });

                it("fails for a non-collection actual", () => {
                    expect(() => spec.expectAll("not a collection").toBeNumeric())
                        .toThrow(type = "TestBox.AssertionFailed");
                });

            });

            describe("utility helpers", () => {

                it("querySim() builds a query from compact text", () => {
                    var q = spec.querySim("id,name
1|luis
2|peter");
                    expect(q.recordCount).toBe(2);
                    expect(q.name[2]).toBe("peter");
                });

                it("debug() appends to the debug buffer and clearDebugBuffer() empties it", () => {
                    spec.debug("entry one");
                    expect(arrayLen(spec.getDebugBuffer())).toBe(1);
                    spec.clearDebugBuffer();
                    expect(arrayLen(spec.getDebugBuffer())).toBe(0);
                });

                it("engine predicates return booleans", () => {
                    expect(spec.isAdobe()).toBeTypeOf("boolean");
                    expect(spec.isLucee()).toBeTypeOf("boolean");
                    expect(spec.isBoxLang()).toBeTypeOf("boolean");
                    expect(spec.isWindows()).toBeTypeOf("boolean");
                    expect(spec.isLinux()).toBeTypeOf("boolean");
                    expect(spec.isMac()).toBeTypeOf("boolean");
                });

                it("getProperty() reads a this-scope property from a mocked component", () => {
                    // prepareMock() mocks the target; for component instances
                    // the mock carries the original's this-scope keys
                    // ($testID is set by the BaseSpec pseudo-constructor).
                    var target = new wheels.wheelstest.system.BaseSpec();
                    expect(spec.getProperty(target = target, name = "$testID", scope = "this"))
                        .toBe(target.$testID);
                });

                it("console() writes to the engine console", () => {
                    spec.console(var = {hello = "world"}, label = "spec probe");
                    expect(true).toBeTrue();
                });

                it("getEnv() returns the lazy Env singleton", () => {
                    expect(isObject(spec.getEnv())).toBeTrue();
                });

                it("getProperty() honors the defaultValue when the key is absent", () => {
                    var target = {};
                    expect(spec.getProperty(target = target, name = "missing", defaultValue = "fallback")).toBe("fallback");
                });

            });

        });

    }

}
