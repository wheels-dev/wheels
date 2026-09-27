/**
 * Finder results hand app code CFML dates for datetime columns, on every
 * engine and database (#3719). BoxLang's Oracle driver used to return raw
 * oracle.sql.TIMESTAMP objects, which DateFormat(), DateCompare(), output,
 * concatenation and SerializeJSON() all choke on. The finder specs below run
 * everywhere; on BoxLang + Oracle they exercise the conversion in
 * OracleModel.$normalizeOracleTemporalColumns(). The unit specs call that
 * function directly with a real oracle.sql.TIMESTAMP wherever the Oracle
 * driver is on the classpath.
 */
component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo;

		describe("finder datetime values are CFML dates (##3719)", () => {

			it("findAll returns datetime columns that DateFormat accepts", () => {
				var posts = g.model("Post").findAll(order = "id", maxRows = 3);
				expect(posts.recordCount).toBeGT(0);
				for (var i = 1; i <= posts.recordCount; i++) {
					expect(IsDate(posts.createdAt[i])).toBeTrue("createdAt row #i# is not a date");
					expect(Len(DateFormat(posts.createdAt[i], "yyyy-mm-dd"))).toBe(10);
					expect(DateCompare(posts.createdAt[i], DateAdd("yyyy", 100, Now()))).toBe(-1);
				}
			});

			it("findOne and findByKey return datetime properties as dates", () => {
				var first = g.model("Post").findOne(order = "id");
				expect(IsDate(first.createdAt)).toBeTrue();
				expect(IsDate(first.updatedAt)).toBeTrue();
				var byKey = g.model("Post").findByKey(first.id);
				expect(IsDate(byKey.createdAt)).toBeTrue();
				expect(DateFormat(byKey.createdAt, "yyyy-mm-dd")).toBe(DateFormat(first.createdAt, "yyyy-mm-dd"));
				// Output and concatenation work too.
				expect(Len("created " & byKey.createdAt)).toBeGT(8);
			});

			it("serializes datetime values as dates, not driver internals", () => {
				var post = g.model("Post").findOne(order = "id");
				var posts = g.model("Post").findAll(order = "id", maxRows = 1);
				var json = SerializeJSON({fromObject = post.createdAt, fromQuery = posts.createdAt[1]});
				expect(json).notToInclude("bytes");
				expect(json).notToInclude("oracle");
			});

		});

		describe("finder datetime values keep their milliseconds on Oracle (##3719)", () => {

			it("findByKey and findAll(returnType=array) read back a fractional TIMESTAMP exactly", () => {
				var isOracle = CreateObject("component", "wheels.migrator.Migration").init().adapter.adapterName() == "Oracle";
				if (!isOracle) {
					skip("Oracle TIMESTAMP literal; the fractional round-trip is specific to the Oracle legs.");
				}
				var first = g.model("Post").findOne(order = "id");
				var state = {byKey = "", rows = []};
				transaction action="begin" {
					QueryExecute(
						"UPDATE c_o_r_e_posts SET createdat = TIMESTAMP '2026-07-25 17:20:00.789' WHERE id = :id",
						{id = {value = first.id, cfsqltype = "cf_sql_integer"}},
						{datasource = application.wheels.dataSourceName}
					);
					state.byKey = g.model("Post").findByKey(key = first.id, reload = true).createdAt;
					state.rows = g.model("Post").findAll(where = "id = #first.id#", returnType = "array", reload = true);
					transaction action="rollback";
				}
				expect(IsDate(state.byKey)).toBeTrue();
				expect(DateTimeFormat(state.byKey, "yyyy-mm-dd HH:nn:ss")).toBe("2026-07-25 17:20:00");
				expect(DatePart("l", state.byKey)).toBe(789);
				expect(ArrayLen(state.rows)).toBe(1);
				expect(IsDate(state.rows[1].createdAt)).toBeTrue();
				expect(DatePart("l", state.rows[1].createdAt)).toBe(789);
			});

		});

		describe("OracleModel.$normalizeOracleTemporalColumns (##3719)", () => {

			it("leaves text, numbers, dates and empty values alone", () => {
				var adapter = CreateObject("component", "wheels.databaseAdapters.Oracle.OracleModel");
				var stamp = CreateDateTime(2026, 7, 25, 17, 20, 0);
				var q = QueryNew("label,amount,happened");
				QueryAddRow(q);
				QuerySetCell(q, "label", "first", 1);
				QuerySetCell(q, "amount", 12, 1);
				QuerySetCell(q, "happened", stamp, 1);
				QueryAddRow(q);
				QuerySetCell(q, "label", "", 2);
				QuerySetCell(q, "amount", "", 2);
				QuerySetCell(q, "happened", "", 2);
				var normalized = adapter.$normalizeOracleTemporalColumns(q);
				expect(normalized.label[1]).toBe("first");
				expect(normalized.amount[1]).toBe(12);
				expect(DateCompare(normalized.happened[1], stamp)).toBe(0);
				expect(normalized.label[2]).toBe("");
			});

			it("converts oracle.sql.TIMESTAMP cells to CFML dates, keeping NULLs empty", () => {
				var probe = {ts = ""};
				try {
					probe.ts = CreateObject("java", "oracle.sql.TIMESTAMP").init(
						CreateObject("java", "java.sql.Timestamp").valueOf("2026-07-25 17:20:00.789")
					);
				} catch (any e) {
					probe.ts = "";
				}
				if (IsSimpleValue(probe.ts)) {
					skip("oracle.sql.TIMESTAMP is not on this engine's classpath (runs on the Oracle legs).");
				}
				var adapter = CreateObject("component", "wheels.databaseAdapters.Oracle.OracleModel");
				var q = QueryNew("happened");
				QueryAddRow(q);
				QuerySetCell(q, "happened", "", 1);
				QueryAddRow(q);
				QuerySetCell(q, "happened", probe.ts, 2);
				var normalized = adapter.$normalizeOracleTemporalColumns(q);
				expect(normalized.happened[1]).toBe("");
				expect(IsDate(normalized.happened[2])).toBeTrue();
				expect(DateTimeFormat(normalized.happened[2], "yyyy-mm-dd HH:nn:ss")).toBe("2026-07-25 17:20:00");
				// Full precision: the milliseconds survive (rev1-r2, #3725).
				expect(DatePart("l", normalized.happened[2])).toBe(789);
			});

			it("converts driver values in returnType array and struct results too", () => {
				var probe = {ts = ""};
				try {
					probe.ts = CreateObject("java", "oracle.sql.TIMESTAMP").init(
						CreateObject("java", "java.sql.Timestamp").valueOf("2026-07-25 17:20:00.789")
					);
				} catch (any e) {
					probe.ts = "";
				}
				if (IsSimpleValue(probe.ts)) {
					skip("oracle.sql.TIMESTAMP is not on this engine's classpath (runs on the Oracle legs).");
				}
				var adapter = CreateObject("component", "wheels.databaseAdapters.Oracle.OracleModel");
				var asArray = adapter.$normalizeOracleTemporalResult([{id = 1, happened = probe.ts, label = "x"}]);
				expect(IsDate(asArray[1].happened)).toBeTrue();
				expect(DatePart("l", asArray[1].happened)).toBe(789);
				expect(asArray[1].label).toBe("x");
				var asStruct = adapter.$normalizeOracleTemporalResult({"1" = {id = 1, happened = probe.ts}});
				expect(IsDate(asStruct["1"].happened)).toBeTrue();
			});

			it("leaves a non-temporal oracle.sql value (NUMBER) untouched", () => {
				// The conversion reads numbers as epoch milliseconds, so a raw
				// oracle.sql.NUMBER must never be treated as a timestamp.
				var probe = {num = ""};
				try {
					probe.num = CreateObject("java", "oracle.sql.NUMBER").init(JavaCast("int", 42));
				} catch (any e) {
					probe.num = "";
				}
				if (IsSimpleValue(probe.num)) {
					skip("oracle.sql.NUMBER is not on this engine's classpath (runs on the Oracle legs).");
				}
				var adapter = CreateObject("component", "wheels.databaseAdapters.Oracle.OracleModel");
				expect(adapter.$isOracleDriverValue(probe.num)).toBeFalse();
				var q = QueryNew("amount");
				QueryAddRow(q);
				QuerySetCell(q, "amount", probe.num, 1);
				var normalized = adapter.$normalizeOracleTemporalColumns(q);
				expect(IsDate(normalized.amount[1])).toBeFalse("the NUMBER cell was rewritten as a date");
			});

		});

	}

}
