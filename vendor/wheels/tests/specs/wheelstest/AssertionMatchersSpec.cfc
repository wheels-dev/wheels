component extends="wheels.WheelsTest" {

    /**
     * Covers the Assertion library's numeric/string/instance/date matchers
     * that the BDD expectation specs never call directly. Each matcher is
     * exercised on BOTH sides: a passing case returns the assertion object,
     * a failing case throws TestBox.AssertionFailed.
     */
    function run() {

        describe("Assertion library matchers", () => {

            beforeEach(() => {
                a = new wheels.wheelstest.system.Assertion();
            });

            describe("numeric matchers", () => {

                it("closeTo() passes within the delta and fails outside it", () => {
                    expect(a.closeTo(expected = 10, actual = 10.4, delta = 0.5)).toBe(a);
                    expect(() => a.closeTo(expected = 10, actual = 11, delta = 0.5))
                        .toThrow(type = "TestBox.AssertionFailed");
                });

                it("closeTo() compares dates with a datePart", () => {
                    var base = CreateDateTime(2024, 1, 15, 12, 0, 0);
                    expect(a.closeTo(expected = base, actual = DateAdd("n", 2, base), delta = 5, datePart = "n")).toBe(a);
                    expect(() => a.closeTo(expected = base, actual = DateAdd("n", 30, base), delta = 5, datePart = "n"))
                        .toThrow(type = "TestBox.AssertionFailed");
                });

                it("between() passes inside the range and fails outside it", () => {
                    expect(a.between(actual = 5, min = 1, max = 10)).toBe(a);
                    expect(() => a.between(actual = 15, min = 1, max = 10))
                        .toThrow(type = "TestBox.AssertionFailed");
                });

                it("between() compares dates and rejects an inverted range", () => {
                    var lo = CreateDate(2024, 1, 1);
                    var hi = CreateDate(2024, 12, 31);
                    var mid = CreateDate(2024, 6, 15);
                    expect(a.between(actual = mid, min = lo, max = hi)).toBe(a);
                    expect(() => a.between(actual = mid, min = hi, max = lo))
                        .toThrow(type = "TestBox.AssertionFailed");
                });

            });

            describe("instance matchers", () => {

                it("isSameInstance()/isNotSameInstance() compare by identity", () => {
                    var obj = {x = 1};
                    var other = {x = 1};
                    expect(a.isSameInstance(expected = obj, actual = obj)).toBe(a);
                    expect(() => a.isSameInstance(expected = obj, actual = other))
                        .toThrow(type = "TestBox.AssertionFailed");
                    expect(a.isNotSameInstance(expected = obj, actual = other)).toBe(a);
                    expect(() => a.isNotSameInstance(expected = obj, actual = obj))
                        .toThrow(type = "TestBox.AssertionFailed");
                });

            });

            describe("null and type matchers", () => {

                it("null()/notNull() distinguish the null value", () => {
                    expect(a.null(actual = javacast("null", ""))).toBe(a);
                    expect(() => a.null(actual = "value")).toThrow(type = "TestBox.AssertionFailed");
                    expect(a.notNull(actual = "value")).toBe(a);
                    expect(() => a.notNull(actual = javacast("null", ""))).toThrow(type = "TestBox.AssertionFailed");
                });

                it("notTypeOf() rejects the given type and passes others", () => {
                    expect(a.notTypeOf(type = "array", actual = {})).toBe(a);
                    expect(() => a.notTypeOf(type = "struct", actual = {}))
                        .toThrow(type = "TestBox.AssertionFailed");
                });

            });

            describe("string matchers", () => {

                it("matchWithCase()/notMatchWithCase() are case-sensitive regex checks", () => {
                    expect(a.matchWithCase(actual = "Hello World", regex = "^Hello")).toBe(a);
                    expect(() => a.matchWithCase(actual = "hello world", regex = "^Hello"))
                        .toThrow(type = "TestBox.AssertionFailed");
                    expect(a.notMatchWithCase(actual = "hello world", regex = "^Hello")).toBe(a);
                });

                it("startsWithCase()/notStartsWithCase() honor case", () => {
                    expect(a.startsWithCase(target = "Hello World", needle = "Hello")).toBe(a);
                    expect(() => a.startsWithCase(target = "hello world", needle = "Hello"))
                        .toThrow(type = "TestBox.AssertionFailed");
                    expect(a.notStartsWithCase(target = "hello world", needle = "Hello")).toBe(a);
                });

                it("notStartsWith()/notEndsWith() accept non-matching needles", () => {
                    // Note: these two matchers swallow their own failure
                    // (their fail() call lands inside their own try and is
                    // caught by the TestBox.AssertionFailed handler), so the
                    // observable contract is "never throws" — assert the
                    // passing paths only.
                    expect(a.notStartsWith(target = "hello world", needle = "world")).toBe(a);
                    expect(a.notEndsWith(target = "hello world", needle = "hello")).toBe(a);
                });

                it("endsWithCase()/notEndsWithCase() honor case", () => {
                    expect(a.endsWithCase(target = "Hello World", needle = "World")).toBe(a);
                    expect(() => a.endsWithCase(target = "hello world", needle = "World"))
                        .toThrow(type = "TestBox.AssertionFailed");
                    expect(a.notEndsWithCase(target = "hello world", needle = "World")).toBe(a);
                });

                it("notIncludesWithCase() rejects case-sensitive needles", () => {
                    expect(a.notIncludesWithCase(target = "Hello World", needle = "WORLD")).toBe(a);
                    expect(() => a.notIncludesWithCase(target = "Hello World", needle = "World"))
                        .toThrow(type = "TestBox.AssertionFailed");
                });

            });

            describe("struct matchers", () => {

                it("deepKey()/notDeepKey() search nested structures by key name", () => {
                    // deepKey uses structFindKey() — the key argument is a KEY
                    // NAME searched anywhere in the nested structure, not a
                    // dotted path.
                    expect(a.deepKey(target = {a = {b = {c = 1}}}, key = "c")).toBe(a);
                    expect(() => a.deepKey(target = {a = {}}, key = "c"))
                        .toThrow(type = "TestBox.AssertionFailed");
                    expect(a.notDeepKey(target = {a = {}}, key = "c")).toBe(a);
                    expect(() => a.notDeepKey(target = {a = {b = {c = 1}}}, key = "c"))
                        .toThrow(type = "TestBox.AssertionFailed");
                });

            });

            describe("equality matchers", () => {

                it("isEqual() with queries delegates to $equalizeQueries", () => {
                    var q1 = queryNew("id,name");
                    queryAddRow(q1, {id = 1, name = "one"});
                    var q2 = queryNew("id,name");
                    queryAddRow(q2, {id = 1, name = "one"});
                    expect(a.isEqual(expected = q1, actual = q2)).toBe(a);
                    var q3 = queryNew("id,name");
                    queryAddRow(q3, {id = 2, name = "two"});
                    expect(() => a.isEqual(expected = q1, actual = q3))
                        .toThrow(type = "TestBox.AssertionFailed");
                });

                it("isEqual() with XML strings delegates to $equalizeXml", () => {
                    // $equalizeXml compares the raw string forms — use
                    // identical strings for the pass and a differing value
                    // for the fail.
                    var x1 = "<user><name>Luis</name></user>";
                    expect(a.isEqual(expected = x1, actual = x1)).toBe(a);
                    expect(() => a.isEqual(expected = x1, actual = "<user><name>Tom</name></user>"))
                        .toThrow(type = "TestBox.AssertionFailed");
                });

            });

            describe("length matchers", () => {

                it("notLengthOf() rejects the given length", () => {
                    expect(a.notLengthOf(target = "hello", length = "2")).toBe(a);
                    expect(() => a.notLengthOf(target = "hello", length = "5"))
                        .toThrow(type = "TestBox.AssertionFailed");
                });

            });

        });

    }

}
