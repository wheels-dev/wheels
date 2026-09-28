/**
 * #3675 — `$whereClause()` split the where string on every uppercase `AND` / `OR`
 * bounded by a non-alphanumeric, so `_` and `$` inside an identifier counted as a
 * boundary. A table-qualified condition on `C_O_R_E_X_AND_Y_OR_Z` (Oracle folds
 * unquoted identifiers to uppercase, so such names are common there) was cut in
 * two and failed with a misleading `Wheels.ColumnNotFound`. The leading-keyword
 * strip had the same flaw: a condition starting with `ORDER_NO` lost its `OR`.
 */
component extends="wheels.WheelsTest" {

	variables.andOrTable = "c_o_r_e_x_and_y_or_z";

	function beforeAll() {
		var ds = {datasource = application.wheels.dataSourceName};
		try {
			QueryExecute("DROP TABLE #variables.andOrTable#", [], ds);
		} catch (any e) {
		}
		QueryExecute("CREATE TABLE #variables.andOrTable# (id int NOT NULL, name varchar(50) NOT NULL, order_no varchar(50) NOT NULL, PRIMARY KEY(id))", [], ds);
		QueryExecute("INSERT INTO #variables.andOrTable# (id, name, order_no) VALUES (1, 'gamma', 'n1')", [], ds);
		QueryExecute("INSERT INTO #variables.andOrTable# (id, name, order_no) VALUES (2, 'alpha', 'n2')", [], ds);
		QueryExecute("INSERT INTO #variables.andOrTable# (id, name, order_no) VALUES (3, 'beta', 'n3')", [], ds);
	}

	function afterAll() {
		try {
			QueryExecute("DROP TABLE #variables.andOrTable#", [], {datasource = application.wheels.dataSourceName});
		} catch (any e) {
		}
	}

	function run() {

		g = application.wo;

		describe("Where clauses on identifiers containing AND / OR (##3675)", () => {

			it("resolves an uppercase table-qualified condition", () => {
				var widgets = g.model("AndOrWidget").findAll(where = "#UCase(andOrTable)#.name = 'beta'");
				expect(widgets.recordCount).toBe(1);
				expect(widgets.id[1]).toBe(3);
			});

			it("still resolves a lowercase table-qualified condition", () => {
				var widgets = g.model("AndOrWidget").findAll(where = "#andOrTable#.name = 'beta'");
				expect(widgets.recordCount).toBe(1);
				expect(widgets.id[1]).toBe(3);
			});

			it("still splits real AND / OR keywords between uppercase qualified conditions", () => {
				var qualifier = UCase(andOrTable);
				var widgets = g.model("AndOrWidget").findAll(
					where = "(#qualifier#.name = 'beta' OR #qualifier#.name = 'alpha') AND #qualifier#.id > 1",
					order = "id"
				);
				expect(widgets.recordCount).toBe(2);
				expect(widgets.id[1]).toBe(2);
				expect(widgets.id[2]).toBe(3);
			});

			it("binds one parameter per condition when parsing the where clause", () => {
				var qualifier = UCase(andOrTable);
				var parts = g.model("AndOrWidget").$whereClause(where = "#qualifier#.name = 'a' OR #qualifier#.id = 1");
				var paramCount = 0;
				for (var part in parts) {
					if (IsStruct(part)) {
						paramCount++;
					}
				}
				expect(paramCount).toBe(2);
			});

			it("paginates with an uppercase table-qualified condition", () => {
				var widgets = g.model("AndOrWidget").findAll(
					where = "#UCase(andOrTable)#.id > 1",
					order = "name",
					page = 1,
					perPage = 1
				);
				expect(widgets.recordCount).toBe(1);
				expect(widgets.name[1]).toBe("alpha");
			});

			it("keeps a leading OR inside a property name that starts the condition", () => {
				var widgets = g.model("AndOrWidget").findAll(where = "ORDER_NO = 'n2'");
				expect(widgets.recordCount).toBe(1);
				expect(widgets.id[1]).toBe(2);
			});

		});

	}

}
