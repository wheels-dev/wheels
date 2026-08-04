component extends="wheels.WheelsTest" {

	function run() {

		describe("Base adapter identity-retrieval template", () => {

			describe("$parseInsertColumnList", () => {

				it("strips quotes, spaces and newlines from the column list", () => {
					var probe = CreateObject("component", "wheels.tests._assets.adapters.BaseProbe");
					var insertSql = "INSERT INTO users ([id], ""name"",#Chr(10)#age) VALUES (1,'x',2)";
					expect(probe.$parseInsertColumnList(insertSql)).toBe("id,name,age");
				});

				it("returns empty string when the column list parens are missing or unclosed", () => {
					var probe = CreateObject("component", "wheels.tests._assets.adapters.BaseProbe");
					expect(probe.$parseInsertColumnList("INSERT INTO users ")).toBe("");
					expect(probe.$parseInsertColumnList("INSERT INTO users (id")).toBe("");
				});

				// $parseInsertColumnList used to fork on $isBoxLangEngine(). The
				// result must now be identical no matter what that flag reports,
				// so pin both settings to the same expectation — a reintroduced
				// fork fails here rather than only on the boxlang matrix legs.
				it("parses identically regardless of the BoxLang engine flag", () => {
					var insertSql = "INSERT INTO users ([id], ""name"",#Chr(10)#age) VALUES (1,'x',2)";
					for (var flag in [false, true]) {
						var probe = CreateObject("component", "wheels.tests._assets.adapters.BaseProbe");
						probe.boxlangMode = flag;
						expect(probe.$parseInsertColumnList(insertSql)).toBe("id,name,age");
					}
				});

				it("preserves spaces inside a quoted identifier", () => {
					var probe = CreateObject("component", "wheels.tests._assets.adapters.BaseProbe");
					var insertSql = "INSERT INTO orders ([order date], id) VALUES ('x',1)";
					expect(probe.$parseInsertColumnList(insertSql)).toBe("order date,id");
				});
			});

			describe("$identitySelect template", () => {

				it("returns void and runs no query when primaryKey is empty (bulk path)", () => {
					var probe = CreateObject("component", "wheels.tests._assets.adapters.BaseProbe");
					var result = {sql: "INSERT INTO users (firstname) VALUES ('x')"};
					// CFML void functions don't return null — the variable simply
					// won't exist. Use IsNull() on the raw call to verify no return.
					expect(IsNull(probe.$identitySelect(
						queryAttributes = {},
						result = result,
						primaryKey = "",
						returningIdentity = ""
					))).toBeTrue();
					expect(ArrayLen(probe.capturedSql)).toBe(0);
				});

				it("publishes the default LAST_INSERT_ID lookup under generated_key", () => {
					var probe = CreateObject("component", "wheels.tests._assets.adapters.BaseProbe");
					ArrayAppend(probe.queryResults, QueryNew("lastId", "integer", [{lastId: 7}]));
					var rv = probe.$identitySelect(
						queryAttributes = {},
						result = {sql: "INSERT INTO users (firstname) VALUES ('x')"},
						primaryKey = "id",
						returningIdentity = ""
					);
					expect(rv).toBeStruct();
					expect(rv).toHaveKey("generated_key");
					expect(rv.generated_key).toBe(7);
					expect(ArrayLen(probe.capturedSql)).toBe(1);
					expect(probe.capturedSql[1]).toInclude("LAST_INSERT_ID()");
				});
			});
		});
	}

}
