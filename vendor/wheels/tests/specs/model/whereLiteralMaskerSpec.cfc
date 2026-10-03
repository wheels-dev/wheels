/**
 * $maskWhereLiterals scans with Find() jumps instead of one Mid() per character
 * (#3903). Its output must not change, so these specs compare it with the
 * previous per-character implementation (kept here verbatim as
 * referenceMask) on hand-picked edge cases and on generated strings, including
 * the exception thrown for an unbalanced quote or a control character.
 */
component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo;
		variables.ref = g.model("author");

		describe("The WHERE literal masker", () => {

			it("matches the previous implementation on edge cases", () => {
				var cases = [
					"",
					"id = 1",
					"lastName = 'smith'",
					"lastName = ''",
					"lastName = 'O''Brien'",
					"lastName = ''''",
					"lastName = 'a''''b'",
					"a = 'x' AND b = 'y,z' OR c IN ('p','q','r')",
					"note = '(paren)' AND t = '{not odbc}'",
					"createdAt > {ts '2020-01-02 03:04:05'}",
					"createdAt > '{ts ''2020-01-02 03:04:05''}'",
					"d = {d '2020-01-02'} AND t = {t '03:04:05'}",
					"x = {ts 'not a date'}",
					"x = '{' AND y = '}'",
					"{brace} = 1",
					"lastName = 'trailing",
					"lastName = 'a' AND",
					"a = 'b",
					"title = 'back\slash' AND body LIKE '%50\%%' ESCAPE '\'",
					"name = 'caf" & Chr(233) & "' AND city = '" & Chr(26085) & Chr(26412) & "'",
					"bad = '" & Chr(7) & "'",
					"bad = '" & Chr(2) & "x'",
					"plain text with no quote {but a brace}"
				];
				for (var w in cases) {
					var cmp = compareMaskers(w);
					expect(cmp.same).toBeTrue(cmp.detail);
				}
			});

			it("matches the previous implementation on generated strings", () => {
				var tokens = ["a", "b ", "'", "''", "{", "}", "{ts '2020-01-02 03:04:05'}", "{d '2020-01-02'}", "'{t ''03:04:05''}'", ",", "(", ")", " AND ", "IN ", "\", Chr(233), "x = "];
				var rng = {seed = 12345};
				for (var n = 1; n <= 400; n++) {
					var parts = [];
					var len = 1 + nextRandom(rng) % 12;
					for (var k = 1; k <= len; k++) {
						ArrayAppend(parts, tokens[1 + nextRandom(rng) % ArrayLen(tokens)]);
					}
					var w = ArrayToList(parts, "");
					var cmp = compareMaskers(w);
					expect(cmp.same).toBeTrue(cmp.detail);
				}
			});

			it("masks a long literal and a long run of doubled quotes the same way", () => {
				for (var w in ["lastName = '" & RepeatString("z", 5000) & "'", "firstName = '" & RepeatString("''", 3000) & "'"]) {
					var cmp = compareMaskers(w);
					expect(cmp.same).toBeTrue(cmp.detail);
				}
			});


			// A long run of braces that do not start an ODBC date, before a distant quote
			// or after the last literal, must not make each brace search the rest of the
			// string again for the next quote (review of #3903).
			it("scans a long brace run in linear time", () => {
				var superLinear = application.wheels.engineAdapter.isRustCFML();
				var plan = {small = superLinear ? 2000 : 20000, factor = 10, maxGrowth = superLinear ? 250 : 25};
				for (var shape in ["leading", "trailing"]) {
					var ratio = maskGrowth(shape, plan);
					debug(var = "#shape# brace run: #ratio.summary#", label = "masker linearity");
					expect(ratio.growth).toBeLT(plan.maxGrowth, "#shape# brace run: #ratio.summary#");
				}
			});

		});

	}

	// A small linear congruential generator (ZX81: x * 75 + 74 mod 65537), so every
	// engine sees the same strings. Its products stay well inside a 32-bit integer,
	// which Adobe CF requires for the % operator.
	private numeric function nextRandom(required struct rng) {
		arguments.rng.seed = (arguments.rng.seed * 75 + 74) % 65537;
		return arguments.rng.seed;
	}

	private string function braceRun(required string shape, required numeric size) {
		return arguments.shape == "leading"
			? RepeatString("{", arguments.size) & " x = 'v'"
			: "x = 'v' " & RepeatString("{", arguments.size);
	}

	// Fastest of three runs of $maskWhereLiterals at each size, after one warm-up.
	private struct function maskGrowth(required string shape, required struct plan) {
		var rv = {};
		var large = arguments.plan.small * arguments.plan.factor;
		variables.ref.$maskWhereLiterals(braceRun(arguments.shape, large));
		for (var sizeKey in ["small", "large"]) {
			var w = braceRun(arguments.shape, sizeKey == "small" ? arguments.plan.small : large);
			var best = 0;
			for (var run = 1; run <= 3; run++) {
				var t0 = GetTickCount();
				variables.ref.$maskWhereLiterals(w);
				var took = GetTickCount() - t0;
				best = (run == 1 || took < best) ? took : best;
			}
			rv[sizeKey] = best;
		}
		rv.growth = Round(rv.large / Max(rv.small, 1) * 10) / 10;
		rv.summary = "#arguments.plan.small# braces took #rv.small#ms, #large# took #rv.large#ms, growth #rv.growth#x (limit #arguments.plan.maxGrowth#x)";
		return rv;
	}

	private struct function compareMaskers(required string where) {
		var current = runMasker(true, arguments.where);
		var previous = runMasker(false, arguments.where);
		return {
			same = (Compare(current.out, previous.out) == 0 && current.error == previous.error),
			detail = "where [" & arguments.where & "]: current [" & current.out & "|" & current.error & "] previous [" & previous.out & "|" & previous.error & "]"
		};
	}

	private struct function runMasker(required boolean current, required string where) {
		var state = {out = "", error = ""};
		try {
			state.out = arguments.current ? variables.ref.$maskWhereLiterals(arguments.where) : referenceMask(arguments.where);
		} catch (any e) {
			state.error = e.type;
		}
		return state;
	}

	// The per-character implementation before #3903, unchanged apart from calling
	// the model's helpers through variables.ref.
	private string function referenceMask(required string where) {
		if (Find("'", arguments.where) == 0) {
			return arguments.where;
		}
		local.sentinel = variables.ref.$whereLiteralSentinel();
		local.out = CreateObject("java", "java.lang.StringBuilder").init();
		local.n = Len(arguments.where);
		local.i = 1;
		while (local.i <= local.n) {
			local.ch = Mid(arguments.where, local.i, 1);
			// A CFML date interpolated into the string renders as an ODBC escape,
			// {ts '2020-01-01 00:00:00'} (or {d '...'} / {t '...'}), either bare or
			// inside a quoted literal. Its inner quotes would otherwise end the
			// surrounding literal early. Only the exact form with a date/time value
			// (digits, - : . and spaces) is recognised; it is masked as one literal
			// holding the inner value. Anything else falls through to the ordinary
			// handling below.
			if (local.ch == "'" || local.ch == "{") {
				local.odbc = variables.ref.$matchOdbcDateLiteral(arguments.where, local.i, local.ch == "'");
				if (local.odbc.matched) {
					local.out.append("'");
					local.out.append(local.sentinel);
					// The escape kind rides in front of the hex ("ts:", "d:", "t:"), so a
					// position that isn't bound can write the escape back (see
					// $restoreMaskedLiterals); a bound position takes the plain value.
					local.out.append(local.odbc.kind & ":");
					local.out.append(LCase(BinaryEncode(CharsetDecode(local.odbc.value, "utf-8"), "hex")));
					local.out.append("'");
					local.i += local.odbc.length;
					continue;
				}
			}
			if (local.ch != "'") {
				local.out.append(local.ch);
				local.i += 1;
				continue;
			}
			// A string literal: consume to its closing quote, treating a
			// doubled quote ('') as one escaped quote that stays in the value.
			local.value = CreateObject("java", "java.lang.StringBuilder").init();
			local.i += 1;
			local.closed = false;
			while (local.i <= local.n) {
				local.c = Mid(arguments.where, local.i, 1);
				if (local.c == "'") {
					if (local.i < local.n && Mid(arguments.where, local.i + 1, 1) == "'") {
						local.value.append("'");
						local.i += 2;
					} else {
						local.i += 1;
						local.closed = true;
						break;
					}
				} else {
					local.value.append(local.c);
					local.i += 1;
				}
			}
			if (!local.closed) {
				Throw(
					type = "Wheels.InvalidWhereClause",
					message = "The where clause contains an unbalanced quote.",
					extendedInfo = "A string literal in the `where` argument was opened with a single quote that is never closed. Escape a literal quote by doubling it ('')."
				);
			}
			local.literalValue = local.value.toString();
			// The IN-list binder joins decoded elements with Chr(7); a value
			// carrying Chr(7) (or the Chr(2) sentinel) would re-split or be
			// mis-decoded, so reject those control characters outright — they
			// are never part of legitimate SQL string data (GHSA-96rm).
			if (Find(Chr(7), local.literalValue) > 0 || Find(Chr(2), local.literalValue) > 0) {
				Throw(
					type = "Wheels.InvalidWhereClause",
					message = "A where-clause value contains a control character that cannot be bound safely.",
					extendedInfo = "Remove the Chr(2)/Chr(7) control character from the value, or bind it through a parameter."
				);
			}
			if (!Len(local.literalValue)) {
				// An empty string literal carries nothing to mask; leaving it as
				// `''` keeps the runner's existing empty-string / NULL handling.
				local.out.append("''");
			} else {
				local.out.append("'");
				local.out.append(local.sentinel);
				local.out.append(LCase(BinaryEncode(CharsetDecode(local.literalValue, "utf-8"), "hex")));
				local.out.append("'");
			}
		}
		return local.out.toString();
	}
}
