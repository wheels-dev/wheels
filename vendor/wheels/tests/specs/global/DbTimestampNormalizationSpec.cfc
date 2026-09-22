/**
 * Pins `$normalizeDbTimestamp()` — the one place that turns a timestamp read
 * back from a database into a CFML date (#3649).
 *
 * The shapes it has to absorb, all observed in the wild:
 * - a CFML date (Lucee/MySQL return these directly),
 * - epoch milliseconds, as a plain number (Lucee + sqlite-jdbc) or boxed
 *   `java.lang.Long` (Adobe + sqlite-jdbc),
 * - a `java.util.Date`,
 * - Oracle's `oracle.sql.TIMESTAMP`, which is NOT a `java.util.Date` and which
 *   Adobe CF's `IsDate()` answers with the string "NO" — the shape behind the
 *   `Expected [NO] to be true` failures on the adobe2023 + oracle leg,
 * - a datetime string with fractional seconds ("…20:24:54.205"), which
 *   `IsDate()` also rejects.
 *
 * The Java-object shapes need a JVM, so those assertions skip on RustCFML.
 * Equivalence is asserted against a known epoch instant rather than a formatted
 * string, so the spec holds in any timezone.
 */
component extends="wheels.WheelsTest" {

	function beforeAll() {
		g = application.wo;
		// 2026-07-25T10:20:00Z — an arbitrary fixed instant.
		millis = 1785000000000;
	}

	function run() {

		describe("$normalizeDbTimestamp (##3649)", () => {

			it("returns a CFML date unchanged", () => {
				var written = DateAdd("n", -5, Now());
				expect(DateDiff("s", g.$normalizeDbTimestamp(written), written)).toBe(0);
			});

			it("converts epoch milliseconds to the same instant as the Java date", () => {
				if (g.$engineAdapter().isRustCFML()) {
					return;
				}
				var fromNumber = g.$normalizeDbTimestamp(millis);
				var fromJava = g.$normalizeDbTimestamp(
					CreateObject("java", "java.util.Date").init(JavaCast("long", millis))
				);
				expect(IsDate(fromNumber)).toBeTrue();
				expect(DateDiff("s", fromNumber, fromJava)).toBe(0);
			});

			it("bridges oracle.sql.TIMESTAMP-shaped objects through timestampValue()", () => {
				if (g.$engineAdapter().isRustCFML()) {
					return;
				}
				var stub = new wheels.tests._assets.db.OracleTimestampStub(millis);
				// The object is not recognized as a date — that is the whole
				// problem. (Do not assert IsDate(stub) is false: Adobe returns
				// the *string* "NO" for that shape, which is not a boolean.)
				var normalized = g.$normalizeDbTimestamp(stub);
				expect(IsDate(normalized)).toBeTrue();
				expect(DateDiff("s", normalized, g.$normalizeDbTimestamp(millis))).toBe(0);
			});

			it("accepts fractional-second datetime strings", () => {
				var normalized = g.$normalizeDbTimestamp("2026-07-25 10:20:00.205");
				expect(IsDate(normalized)).toBeTrue();
				expect(DateTimeFormat(normalized, "yyyy-mm-dd HH:nn:ss")).toBe("2026-07-25 10:20:00");
			});

			it("reports an unrecognized value as empty rather than guessing", () => {
				expect(g.$normalizeDbTimestamp("not a timestamp")).toBe("");
				expect(g.$normalizeDbTimestamp("")).toBe("");
			});

		});

	}

}
