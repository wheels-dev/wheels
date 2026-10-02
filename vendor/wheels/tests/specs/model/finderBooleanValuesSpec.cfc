/**
 * Boolean values in finders: `true`/`false` bind as a parameter instead of
 * throwing, through the query builder, dynamic finders and a hand-written
 * `where` string. Issue #3896.
 */
component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo

		describe("Boolean values in finders", () => {

			it("writes true and false as 1 and 0 for a boolean column", () => {
				var adapter = new wheels.databaseAdapters.Base();
				// Compare(), not toBe(): CFML == treats "true" and "1" as equal.
				expect(Compare(adapter.$quoteValue(str = "true", type = "boolean"), "1")).toBe(0);
				expect(Compare(adapter.$quoteValue(str = "false", type = "boolean"), "0")).toBe(0);
				expect(Compare(adapter.$quoteValue(str = "TRUE", type = "boolean"), "1")).toBe(0);
				expect(Compare(adapter.$quoteValue(str = "1", type = "boolean"), "1")).toBe(0);
				expect(Compare(adapter.$quoteValue(str = "0", type = "boolean"), "0")).toBe(0);
			})

			it("still rejects a non-boolean value for a boolean column", () => {
				var adapter = new wheels.databaseAdapters.Base();
				var state = {threw = ""};
				try {
					adapter.$quoteValue(str = "1 OR 1=1", type = "boolean");
				} catch (any e) {
					state.threw = e.type;
				}
				expect(state.threw).toBe("Wheels.InvalidValue");
			})

			it("binds a bare true or false in a hand-written where string", () => {
				var trueRows = g.model("sqltype").findAll(where = "booleanType = true", returnAs = "query").recordCount;
				var oneRows = g.model("sqltype").findAll(where = "booleanType = 1", returnAs = "query").recordCount;
				var falseRows = g.model("sqltype").findAll(where = "booleanType = FALSE", returnAs = "query").recordCount;
				var zeroRows = g.model("sqltype").findAll(where = "booleanType = 0", returnAs = "query").recordCount;
				expect(trueRows).toBe(oneRows);
				expect(falseRows).toBe(zeroRows);
				expect(trueRows + falseRows).toBe(g.model("sqltype").count());
			})

			it("does not read a word that starts with true as a boolean value", () => {
				// `trueish` is not a value the WHERE parser binds, exactly as before.
				var state = {threw = false};
				try {
					g.model("sqltype").findAll(where = "booleanType = trueish", returnAs = "query");
				} catch (any e) {
					state.threw = true;
				}
				expect(state.threw).toBeTrue();
			})

			it("binds true and false through the query builder and dynamic finders on a boolean column", () => {
				if (g.model("sqltype").$classData().properties.booleanType.validationtype != "boolean") {
					skip("booleanType is not a boolean column on this database (##3897)");
				}
				var total = g.model("sqltype").count();
				var t = g.model("sqltype").where("booleanType", true).count();
				var f = g.model("sqltype").where("booleanType", false).count();
				expect(t + f).toBe(total);
				var found = g.model("sqltype").findOneByBooleanType(value = true, returnAs = "query");
				expect(IsQuery(found) || IsBoolean(found)).toBeTrue();
				expect(g.model("sqltype").findAllByBooleanType(value = false, returnAs = "query").recordCount).toBe(f);
			})

			it("leaves TRUE and FALSE after IS or IS NOT as SQL literals", () => {
				// SQL Server has no IS TRUE predicate; Oracle's support depends on the release.
				if (ListFindNoCase("MicrosoftSQLServerModel,OracleModel", g.get("adapterName"))) {
					skip("IS TRUE is not portable to #g.get('adapterName')#");
				}
				var total = g.model("sqltype").count(where = "booleanType IS NOT NULL");
				var isTrue = g.model("sqltype").count(where = "booleanType IS TRUE");
				var isFalse = g.model("sqltype").count(where = "booleanType IS FALSE");
				expect(isTrue).toBe(g.model("sqltype").count(where = "booleanType = 1"));
				expect(isFalse).toBe(g.model("sqltype").count(where = "booleanType = 0"));
				expect(isTrue + isFalse).toBe(total);
				expect(g.model("sqltype").count(where = "booleanType IS NOT FALSE AND booleanType IS NOT NULL")).toBe(isTrue);
			})

		});

	}

}
