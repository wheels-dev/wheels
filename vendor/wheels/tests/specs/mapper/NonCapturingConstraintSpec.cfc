component extends="wheels.WheelsTest" {

	function run() {

		describe("$nonCapturingConstraint", function() {

			beforeEach(function(currentSpec) {
				m = new wheels.Mapper();
				m.$init();
				prepareMock(m);
				makePublic(m, "$nonCapturingConstraint");
				makePublic(m, "$patternToRegex");
			});

			afterEach(function(currentSpec) {
				structDelete(variables, "m");
			});

			it("normalizes a Java named capture group to a non-capturing group", function() {
				// `(?<num>\d{4})` is a Java named capturing group — it would shift
				// every subsequent route variable's matched-value position. Rewrite
				// to `(?:\d{4})` so route-var positional extraction stays correct.
				expect(m.$nonCapturingConstraint("(?<num>\d{4})")).toBe("(?:\d{4})");
			});

			it("normalizes a named capture group with quantifiers", function() {
				expect(m.$nonCapturingConstraint("(?<slug>[a-z0-9-]+)"))
					.toBe("(?:[a-z0-9-]+)");
			});

			it("normalizes nested named capture groups", function() {
				expect(m.$nonCapturingConstraint("(?<outer>(?<inner>\d{2})\-\d{2})"))
					.toBe("(?:(?:\d{2})\-\d{2})");
			});

			it("leaves a positive lookbehind untouched", function() {
				// `(?<=foo)bar` is a positive lookbehind, NOT a capturing group.
				expect(m.$nonCapturingConstraint("(?<=foo)bar")).toBe("(?<=foo)bar");
			});

			it("leaves a negative lookbehind untouched", function() {
				expect(m.$nonCapturingConstraint("(?<!foo)bar")).toBe("(?<!foo)bar");
			});

			it("leaves an explicit non-capturing group untouched", function() {
				expect(m.$nonCapturingConstraint("(?:\d{4})")).toBe("(?:\d{4})");
			});

			it("leaves a positive lookahead untouched", function() {
				expect(m.$nonCapturingConstraint("foo(?=bar)")).toBe("foo(?=bar)");
			});

			it("still rewrites bare capturing groups (regression for ##2944)", function() {
				expect(m.$nonCapturingConstraint("(\d{4})")).toBe("(?:\d{4})");
			});

			it("treats `<` inside a character class as literal, not a named group", function() {
				// `[(<]` is a character class containing `(` and `<` literals — must
				// stay untouched, otherwise the class semantics widen.
				expect(m.$nonCapturingConstraint("[(<]+")).toBe("[(<]+");
			});

			it("$patternToRegex keeps route var positions aligned when constraint contains a named group", function() {
				// With a named group inside the constraint, the outer route-var
				// capturing group must still be group #1 (not shifted by the
				// constraint's inner capture).
				local.regex = m.$patternToRegex(
					pattern = "/archive/[year]",
					constraints = {year = "(?<n>\d{4})"}
				);
				expect(local.regex).toBe("^archive\/((?:\d{4}))\/?$");
			});
		});
	}
}
