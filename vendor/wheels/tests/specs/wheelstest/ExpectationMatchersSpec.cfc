component extends="wheels.WheelsTest" {

    /**
     * Covers the Expectation matchers the suite never reaches: range/close-to,
     * satisfaction predicates, case-sensitive string matchers, deep-key and
     * membership matchers, and the negated (`not`) flow. Expectations are
     * built from a bare BaseSpec instance so nothing registers with the
     * active runner.
     */
    function run() {

        describe("Expectation matchers", () => {

            beforeEach(() => {
                spec = new wheels.wheelstest.system.BaseSpec();
            });

            describe("numeric matchers", () => {

                it("toBeBetween() passes inside the range and fails outside it", () => {
                    expect(() => spec.expect(5).toBeBetween(1, 10)).notToThrow();
                    expect(() => spec.expect(15).toBeBetween(1, 10))
                        .toThrow(type = "TestBox.AssertionFailed");
                });

                it("toBeCloseTo() passes within the delta and fails outside it", () => {
                    expect(() => spec.expect(10.2).toBeCloseTo(10, 0.3)).notToThrow();
                    expect(() => spec.expect(11).toBeCloseTo(10, 0.3))
                        .toThrow(type = "TestBox.AssertionFailed");
                });

            });

            describe("satisfaction matchers", () => {

                it("toSatisfy() passes when the predicate returns true", () => {
                    expect(() => spec.expect(6).toSatisfy(function(v) {
                        return v mod 2 == 0;
                    })).notToThrow();
                    expect(() => spec.expect(7).toSatisfy(function(v) {
                        return v mod 2 == 0;
                    })).toThrow(type = "TestBox.AssertionFailed");
                });

                it("notToSatisfy() flips the predicate result", () => {
                    expect(() => spec.expect(7).notToSatisfy(function(v) {
                        return v mod 2 == 0;
                    })).notToThrow();
                    expect(() => spec.expect(6).notToSatisfy(function(v) {
                        return v mod 2 == 0;
                    })).toThrow(type = "TestBox.AssertionFailed");
                });

            });

            describe("case-sensitive string matchers", () => {

                it("toStartWithCase()/toEndWithCase() honor case", () => {
                    expect(() => spec.expect("Hello World").toStartWithCase("Hello")).notToThrow();
                    expect(() => spec.expect("hello world").toStartWithCase("Hello"))
                        .toThrow(type = "TestBox.AssertionFailed");
                    expect(() => spec.expect("Hello World").toEndWithCase("World")).notToThrow();
                    expect(() => spec.expect("hello world").toEndWithCase("World"))
                        .toThrow(type = "TestBox.AssertionFailed");
                });

                it("toMatchWithCase() is a case-sensitive regex check", () => {
                    expect(() => spec.expect("Hello World").toMatchWithCase("^Hello")).notToThrow();
                    expect(() => spec.expect("hello world").toMatchWithCase("^Hello"))
                        .toThrow(type = "TestBox.AssertionFailed");
                });

                it("toContain()/toContainWithCase() check membership", () => {
                    expect(() => spec.expect("Hello World").toContain("lo Wo")).notToThrow();
                    expect(() => spec.expect("Hello World").toContain("xyz"))
                        .toThrow(type = "TestBox.AssertionFailed");
                    expect(() => spec.expect("Hello World").toContainWithCase("World")).notToThrow();
                    expect(() => spec.expect("Hello World").toContainWithCase("world"))
                        .toThrow(type = "TestBox.AssertionFailed");
                });

            });

            describe("struct and membership matchers", () => {

                it("toHaveKeyWithCase() finds present keys and rejects missing ones", () => {
                    // CFML struct literals are case-insensitive, so the case
                    // dimension can't be asserted with a literal — use a
                    // truly-missing key for the failing path.
                    expect(() => spec.expect({Name = "Luis"}).toHaveKeyWithCase("Name")).notToThrow();
                    expect(() => spec.expect({Name = "Luis"}).toHaveKeyWithCase("missing"))
                        .toThrow(type = "TestBox.AssertionFailed");
                });

                it("toHaveDeepKey() searches nested structures by key name", () => {
                    expect(() => spec.expect({a = {b = {c = 1}}}).toHaveDeepKey("c")).notToThrow();
                    expect(() => spec.expect({a = {}}).toHaveDeepKey("c"))
                        .toThrow(type = "TestBox.AssertionFailed");
                });

                it("toBeIn()/toBeInWithCase() check collection membership", () => {
                    expect(() => spec.expect(2).toBeIn([1, 2, 3])).notToThrow();
                    expect(() => spec.expect(4).toBeIn([1, 2, 3]))
                        .toThrow(type = "TestBox.AssertionFailed");
                    expect(() => spec.expect("B").toBeInWithCase(["a", "B"])).notToThrow();
                    expect(() => spec.expect("b").toBeInWithCase(["a", "B"]))
                        .toThrow(type = "TestBox.AssertionFailed");
                });

            });

            describe("fail and negation plumbing", () => {

                it("fail() throws TestBox.AssertionFailed", () => {
                    expect(() => spec.expect(true).fail("nope")).toThrow(type = "TestBox.AssertionFailed");
                });

                it("_not() toggles the negation flag on the expectation", () => {
                    var e = spec.expect(1);
                    expect(e.notToBe(2)).toBeTypeOf("component");
                });

            });

        });

    }

}
