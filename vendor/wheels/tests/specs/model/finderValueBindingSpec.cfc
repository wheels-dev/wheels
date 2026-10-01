component extends="wheels.WheelsTest" {

	private boolean function sqlHasSentinel(required array frags) {
		for (var f in arguments.frags) {
			if (IsSimpleValue(f) && Find(Chr(2), f) > 0) {
				return true;
			}
		}
		return false;
	}

	/*
	 * Sizes and growth bound for the binding-linearity specs. `large` is
	 * `factor` times `small`. A linear binder's time grows about `factor` times
	 * between them; a quadratic one grows faster. The small size is chosen so
	 * the small call takes well over 10ms on Lucee 7, above the ~1ms timer
	 * resolution, so taking the fastest run does not inflate the growth.
	 * Lucee 7 measurements with factor 10 (fastest of three runs):
	 *   current binder              plain 9.6-10.1x, run of quotes 9.1-10.9x
	 *                               (small call 26-28ms)
	 *   scanner that copies the rest of the string for every character
	 *   (quadratic)                 plain 40-42x, run of quotes 41-50x
	 * so 25 leaves more than 2x headroom above a linear binder and still
	 * fails a quadratic one.
	 *
	 * RustCFML and BoxLang: the WHERE literal scanner is super-linear on these
	 * engines whatever the framework does. On RustCFML Mid() costs O(index) (it
	 * walks the string to reach a character), so the scan is quadratic (about
	 * 70x for factor 10). BoxLang measured 29-42x for factor 10 in CI. These
	 * engines get a "no worse than quadratic" bound instead: a quadratic
	 * binder grows about 100x for factor 10, and 250 adds 2.5x for timer and
	 * machine noise. That is not "anything goes": a cubic or backtracking
	 * regression grows 1000x or more and still fails. The sizes are smaller to
	 * keep the run short. Tightening this is tracked separately.
	 */
	private struct function linearityPlan(required string kind) {
		var adapter = application.wheels.engineAdapter;
		var superLinear = adapter.isRustCFML() || adapter.isBoxLang();
		var plan = {factor = 10, maxGrowth = superLinear ? 250 : 25};
		if (arguments.kind == "plain") {
			plan.small = superLinear ? 3000 : 50000;
		} else {
			plan.small = superLinear ? 1500 : 30000;
		}
		plan.large = plan.small * plan.factor;
		return plan;
	}

	// Milliseconds to turn a WHERE string holding one value of the given size
	// into SQL and bound parameters, the same two steps a finder runs before it
	// queries. No query is executed, so the time measures the binder only and
	// does not depend on the database (Oracle, for one, refuses to bind a string
	// over 4000 characters). The quotes value is escaped the way a dynamic finder
	// escapes it, so `size` quote characters become 2 * `size` in the string.
	private numeric function bindingTime(required string kind, required numeric size) {
		var author = model("author");
		var whereString = arguments.kind == "plain"
			? "lastName = '" & RepeatString("z", arguments.size) & "'"
			: "firstName = '" & RepeatString("''", arguments.size) & "'";
		var t0 = GetTickCount();
		var sqlParts = author.$addWhereClause(sql = ["SELECT 1"], where = whereString, include = "", includeSoftDeletes = false);
		author.$addWhereClauseParameters(sql = sqlParts, where = whereString);
		return GetTickCount() - t0;
	}

	// Fastest of three runs at each size (the caller has already warmed the
	// path up), and the growth from the small size to the large one.
	private struct function bindingGrowth(required string kind, required struct plan) {
		var rv = {small = 0, large = 0};
		var sizeKeys = ["small", "large"];
		var sizeKey = "";
		var best = 0;
		var t = 0;
		var i = 0;
		for (sizeKey in sizeKeys) {
			best = -1;
			for (i = 1; i <= 3; i++) {
				t = bindingTime(arguments.kind, arguments.plan[sizeKey]);
				if (best < 0 || t < best) {
					best = t;
				}
			}
			rv[sizeKey] = best;
		}
		rv.growth = Round(rv.large / Max(rv.small, 1) * 10) / 10;
		rv.summary = "#arguments.plan.small# chars took #rv.small#ms, #arguments.plan.large# chars took #rv.large#ms, growth #rv.growth#x (limit #arguments.plan.maxGrowth#x)";
		return rv;
	}

	/*
	 * Regression spec: values passed to dynamic finders, key finders, the
	 * chainable query builder, and uniqueness validation must be bound as a
	 * single parameter, so a quote character in the value cannot change the
	 * shape of the WHERE clause. A value that matches no row must return no
	 * row even when it contains a quote; a legitimate value with an apostrophe
	 * (O'Brien) must still match.
	 *
	 * The probe value is inert: it is a string that no seeded row equals. If it
	 * is bound as one value, every query below returns zero rows. If the quote
	 * ends the literal and the remainder is read as SQL, the queries return
	 * rows they should not.
	 */

	// A value equal to no seeded firstName. The embedded quote is the boundary
	// under test; the rest is a condition that would be always-true if it ran.
	variables.PROBE = "zznomatch' OR firstName <> '";
	variables.PROBE_USERNAME = "zznouser' OR username <> '";
	variables.PROBE_KEY = "zznokey' OR '1'='1";

	function run() {
		describe("finder value binding", () => {

			it("binds a single-property dynamic finder value as one parameter", () => {
				var q = model("author").findAllByFirstName(value = variables.PROBE, returnAs = "query");
				expect(q.recordCount).toBe(0, "returned #q.recordCount# rows");
			});

			it("findOneBy returns no object for a non-matching quoted value", () => {
				var r = model("author").findOneByFirstName(variables.PROBE);
				expect(IsObject(r)).toBeFalse();
			});

			it("binds a multi-property dynamic finder value as one parameter", () => {
				var r = model("author").findOneByFirstNameAndLastName(values = [variables.PROBE, "zzx"]);
				expect(IsObject(r)).toBeFalse();
			});

			it("still matches a legitimate value containing an apostrophe", () => {
				var total = model("author").count();
				expect(total).toBeGT(0, "no seeded authors");
				var seeded = model("author").findOne(returnAs = "query");
				// Store and read back an apostrophe value through a dynamic finder.
				transaction {
					var a = model("author").create(firstName = "O'Brien", lastName = "Tester");
					var found = model("author").findOneByFirstName("O'Brien");
					transaction action = "rollback";
				}
				expect(IsObject(found)).toBeTrue("O'Brien lookup failed");
				expect(found.lastName).toBe("Tester");
			});

			it("binds a string/UUID key finder value as one parameter", () => {
				var r = model("uuidRecord").findByKey(variables.PROBE_KEY);
				expect(IsObject(r)).toBeFalse();
			});

			it("updateByKey on a non-matching quoted key changes no rows", () => {
				transaction {
					model("uuidRecord").create(uuidid = LCase(CreateUUID()), name = "keep");
					model("uuidRecord").updateByKey(key = variables.PROBE_KEY, name = "changed");
					var changed = model("uuidRecord").count(where = "name = 'changed'");
					transaction action = "rollback";
				}
				expect(changed).toBe(0, "#changed# rows changed");
			});

			it("deleteByKey on a non-matching quoted key deletes no rows", () => {
				transaction {
					var before = model("uuidRecord").count();
					model("uuidRecord").create(uuidid = LCase(CreateUUID()), name = "keep");
					model("uuidRecord").deleteByKey(variables.PROBE_KEY);
					var after = model("uuidRecord").count();
					transaction action = "rollback";
				}
				expect(after).toBe(before + 1, "expected only the created row; before=#before# after=#after#");
			});

			it("binds a query builder where(prop, value) as one parameter", () => {
				var q = model("author").where("firstName", variables.PROBE).get();
				expect(q.recordCount).toBe(0, "returned #q.recordCount# rows");
			});

			it("binds a query builder where(prop, op, value) as one parameter", () => {
				var q = model("author").where("firstName", "=", variables.PROBE).get();
				expect(q.recordCount).toBe(0, "returned #q.recordCount# rows");
			});

			it("honours a hand-written where string that already escapes a quote", () => {
				transaction {
					model("author").create(firstName = "O'Brien", lastName = "Hand");
					var q = model("author").findAll(where = "firstName = 'O''Brien'", returnAs = "query");
					transaction action = "rollback";
				}
				expect(q.recordCount).toBe(1, "escaped hand-written where matched #q.recordCount# rows");
			});

			it("does not pass through the remainder of a hand-written escaped injection", () => {
				var q = model("author").findAll(where = "firstName = 'zzx'' OR firstName <> '''", returnAs = "query");
				expect(q.recordCount).toBe(0, "returned #q.recordCount# rows");
			});

			it("an unbalanced quote in a value does not return every row", () => {
				var state = {rows = -1, threw = false};
				try {
					state.rows = model("author").findAllByFirstName(value = "zzx' OR 1=1 --", returnAs = "query").recordCount;
				} catch (any e) {
					state.threw = true;
				}
				expect(state.threw || state.rows == 0).toBeTrue("returned #state.rows# rows without throwing");
			});

			// The two specs below guard that binding a value stays roughly linear in
			// its length. They compare the binder's time at two sizes instead of using
			// a fixed wall-clock budget, which depends on the engine and the machine.
			// Each first runs a real finder with a 3000-character value, which every
			// supported database can bind, then warms the binder up before timing.
			// See linearityPlan() and bindingTime().
			it("binds a long plain value in time that scales linearly and matches nothing", () => {
				expect(model("author").findAllByLastName(value = RepeatString("z", 3000), returnAs = "query").recordCount).toBe(0);
				var plan = linearityPlan("plain");
				bindingTime("plain", plan.large);
				var ratio = bindingGrowth("plain", plan);
				// Recorded on passing runs too, so the margin is visible in every leg's result JSON.
				debug(var = "plain value: #ratio.summary#", label = "binding linearity");
				expect(ratio.growth).toBeLT(plan.maxGrowth, "plain value: #ratio.summary#");
			});

			it("binds a value with a long run of quotes in linear time instead of crashing", () => {
				expect(model("author").findAllByFirstName(value = RepeatString("'", 3000), returnAs = "query").recordCount).toBe(0);
				var plan = linearityPlan("quotes");
				bindingTime("quotes", plan.large);
				var ratio = bindingGrowth("quotes", plan);
				// Recorded on passing runs too, so the margin is visible in every leg's result JSON.
				debug(var = "run of quotes: #ratio.summary#", label = "binding linearity");
				expect(ratio.growth).toBeLT(plan.maxGrowth, "run of quotes: #ratio.summary#");
			});

			it("uniqueness validation is not defeated by a quote in the value", () => {
				// A username that no user holds must pass the uniqueness check.
				var u = model("user").new(username = variables.PROBE_USERNAME, password = "x");
				u.valid();
				var errs = u.errorsOn("username");
				var taken = false;
				for (var e in errs) {
					if (FindNoCase("taken", e.message)) {
						taken = true;
					}
				}
				expect(taken).toBeFalse("uniqueness reported a free username as taken: #SerializeJSON(errs)#");
			});

		});

		// The IN-list path binds each value individually (split on the quoted
		// separator), so a quote in an IN value cannot change the clause. This
		// path is unchanged by the single-literal fix; these guard against a
		// regression and document that it is already safe.
		describe("IN list value binding", () => {

			it("binds each whereIn value; a quote-bearing non-match returns no rows", () => {
				var q = model("author").whereIn("firstName", ["zznope", variables.PROBE]).get();
				expect(q.recordCount).toBe(0, "returned #q.recordCount# rows");
			});

			it("whereIn preserves a real apostrophe value", () => {
				transaction {
					model("author").create(firstName = "O'Brien", lastName = "InList");
					var q = model("author").whereIn("firstName", ["O'Brien", "zznope"]).get();
					transaction action = "rollback";
				}
				expect(q.recordCount).toBe(1, "returned #q.recordCount# rows");
			});

			it("a hand-written escaped IN list matches an apostrophe value", () => {
				transaction {
					model("author").create(firstName = "O'Brien", lastName = "HandIn");
					var q = model("author").findAll(where = "firstName IN ('zznope','O''Brien')", returnAs = "query");
					transaction action = "rollback";
				}
				expect(q.recordCount).toBe(1, "returned #q.recordCount# rows");
			});

			it("a hand-written IN list with an escaped injection value returns no rows", () => {
				var q = model("author").findAll(where = "firstName IN ('zzx'' OR firstName <> ''')", returnAs = "query");
				expect(q.recordCount).toBe(0, "returned #q.recordCount# rows");
			});

			it("whereNotIn with a quote-bearing value excludes only that value", () => {
				var total = model("author").count();
				var q = model("author").whereNotIn("firstName", [variables.PROBE]).get();
				expect(q.recordCount).toBe(total, "returned #q.recordCount# of #total# rows");
			});

			it("binds a whereIn value that closes the paren as one value", () => {
				var q = model("author").whereIn("firstName", ["zzx') OR (firstName <> '"]).get();
				expect(q.recordCount).toBe(0, "returned #q.recordCount# rows");
			});

			it("does not pass through a hand-written IN whose value closes the paren", () => {
				var q = model("author").findAll(where = "firstName IN ('zzx'') OR (firstName <> ''')", returnAs = "query");
				expect(q.recordCount).toBe(0, "returned #q.recordCount# rows");
			});

			it("binds each of several whereIn values when one closes the paren", () => {
				var q = model("author").whereIn("firstName", ["zznope", "zzx') OR (1=1) OR (firstName <> '"]).get();
				expect(q.recordCount).toBe(0, "returned #q.recordCount# rows");
			});

			it("rejects a numeric value with a trailing newline", () => {
				var state = {rows = -1, threw = ""};
				try {
					state.rows = model("author").findAllByFirstName(value = "zznope", returnAs = "query").recordCount;
				} catch (any e) {}
				// id is an integer column; a trailing LF must not slip through the shape check.
				var ib = {threw = ""};
				try {
					model("author").where("id", "1" & Chr(10)).get();
				} catch (any e) {
					ib.threw = e.type;
				}
				expect(ib.threw).toBe("Wheels.InvalidValue", "type=#ib.threw#");
			});

			it("binds a large IN list (a batch of keys) quickly instead of crashing", () => {
				// Each IN value binds as its own parameter, and SQL Server accepts at
				// most 2100 parameters per statement, so it gets a batch under that
				// limit. Every other database takes the full 6000.
				var batchSize = FindNoCase("SQLServer", application.wo.get("adapterName")) ? 2000 : 6000;
				var values = [];
				for (var i = 1; i <= batchSize; i++) {
					ArrayAppend(values, "v#i#");
				}
				var t0 = GetTickCount();
				var q = model("author").whereIn("firstName", values).get();
				var elapsed = GetTickCount() - t0;
				expect(q.recordCount).toBe(0, "returned #q.recordCount# rows");
				expect(elapsed).toBeLT(5000, "took #elapsed#ms");
			});

			it("binds a batch of 1000 UUID keys without a cap", () => {
				var ids = [];
				for (var i = 1; i <= 1000; i++) {
					ArrayAppend(ids, LCase(CreateUUID()));
				}
				var q = model("uuidRecord").whereIn("uuidid", ids).get();
				expect(q.recordCount).toBe(0, "returned #q.recordCount# rows");
			});

			it("binds hand-written IN lists whatever the spacing", () => {
				transaction {
					model("author").create(firstName = "O'Brien", lastName = "Spacing");
					var unspaced = model("author").findAll(where = "firstName IN ('zznope','O''Brien')", returnAs = "query");
					var spaced = model("author").findAll(where = "firstName IN ('zznope', 'O''Brien')", returnAs = "query");
					var newlined = model("author").findAll(where = "firstName IN ('zznope',#Chr(10)#'O''Brien')", returnAs = "query");
					transaction action = "rollback";
				}
				expect(unspaced.recordCount).toBe(1, "unspaced #unspaced.recordCount#");
				expect(spaced.recordCount).toBe(1, "spaced #spaced.recordCount#");
				expect(newlined.recordCount).toBe(1, "newlined #newlined.recordCount#");
			});

			it("rejects an unbalanced quote with a clear error", () => {
				var state = {threw = ""};
				try {
					model("author").findAll(where = "firstName = 'unterminated", returnAs = "query");
				} catch (any e) {
					state.threw = e.type;
				}
				expect(state.threw).toBe("Wheels.InvalidWhereClause", "type=#state.threw#");
			});

		});

		describe("unbound literals (GHSA-96rm)", () => {

			it("leaves no sentinel in the SQL for a BETWEEN clause", () => {
				expect(sqlHasSentinel(model("author").$whereClause(where = "firstName BETWEEN 'a' AND 'z'", include = "", sql = ["SELECT 1"]))).toBeFalse();
			});

			it("leaves no sentinel in the SQL for a function-argument literal", () => {
				expect(sqlHasSentinel(model("author").$whereClause(where = "firstName = UPPER('tony')", include = "", sql = ["SELECT 1"]))).toBeFalse();
			});

			it("leaves no sentinel in the SQL for a LIKE ... ESCAPE clause", () => {
				expect(sqlHasSentinel(model("author").$whereClause(where = "firstName LIKE 'x!_y' ESCAPE '!'", include = "", sql = ["SELECT 1"]))).toBeFalse();
			});

			it("whereBetween on a string column returns rows", () => {
				expect(model("author").whereBetween("firstName", "A", "z").get().recordCount).toBeGT(0);
			});

			it("whereBetween on a date column returns rows", () => {
				// Oracle rejects the ISO date string format here under its NLS date
				// settings (ORA-01843). That predates this spec and is tracked
				// separately.
				if (FindNoCase("Oracle", application.wo.get("adapterName"))) {
					skip("Oracle rejects the ISO date string format here (NLS); tracked separately.");
				}
				expect(model("sqltype").whereBetween("dateTimeType", "1900-01-01", "2100-01-01").get().recordCount).toBeGT(0);
			});

			it("a hand-written BETWEEN returns rows", () => {
				expect(model("author").findAll(where = "firstName BETWEEN 'A' AND 'z'", returnAs = "query").recordCount).toBeGT(0);
			});

			it("parameterize=false binds an ordinary IN value", () => {
				expect(model("author").findAll(where = "firstName IN ('zznope','zzmiss')", parameterize = false, returnAs = "query").recordCount).toBe(0);
			});

			it("parameterize=false IN preserves an apostrophe value", () => {
				transaction {
					model("author").create(firstName = "O'Brien", lastName = "PF");
					var q = model("author").findAll(where = "firstName IN ('zznope','O''Brien')", parameterize = false, returnAs = "query");
					transaction action = "rollback";
				}
				expect(q.recordCount).toBe(1, "rows=" & q.recordCount);
			});

			it("binds a value containing a comma as one parameter", () => {
				// A comma in a value goes through the bound (cfqueryparam) path;
				// a non-parameterized comma value is a separate engine concern.
				var q = model("author").findAllByLastName(value = "a,b,c", returnAs = "query");
				expect(q.recordCount).toBe(0, "rows=" & q.recordCount);
			});

			it("binds a value containing a backslash as one parameter", () => {
				// A backslash goes through the bound (cfqueryparam) path; a
				// non-parameterized backslash literal is a separate engine
				// concern (some drivers reject it) and not what masking guards.
				var q = model("author").findAllByLastName(value = "a" & Chr(92) & "b,c", returnAs = "query");
				expect(q.recordCount).toBe(0, "rows=" & q.recordCount);
			});

			it("rejects a value containing the Chr(7) list separator", () => {
				var state = {threw = ""};
				try {
					model("author").whereIn("firstName", ["Alice" & Chr(7) & "Bob"]).get();
				} catch (any e) {
					state.threw = e.type;
				}
				expect(state.threw).toBe("Wheels.InvalidWhereClause", "type=" & state.threw);
			});

		});
	}

}
