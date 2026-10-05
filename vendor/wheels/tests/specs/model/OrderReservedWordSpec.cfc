/**
 * Ordering by a column whose name is a reserved word, through order="table.column"
 * as well as order="column" (4374): the qualified form is quoted like the bare one.
 * The spec owns its table, c_o_r_e_reservedorders, created with the adapter's own
 * identifier quoting so it works on every database, and drops it afterwards.
 */
component extends="wheels.WheelsTest" {

	function beforeAll() {
		variables.ds = application.wheels.dataSourceName;
		variables.table = "c_o_r_e_reservedorders";
		$dropTable();
		QueryExecute(
			"CREATE TABLE #variables.table# (id INT NOT NULL PRIMARY KEY, #$q('order')# INT NOT NULL, #$q('group')# VARCHAR(20) NOT NULL)",
			[],
			{datasource = variables.ds}
		);
		var rows = [[1, 2, "b"], [2, 3, "a"], [3, 1, "c"]];
		for (var row in rows) {
			QueryExecute(
				"INSERT INTO #variables.table# (id, #$q('order')#, #$q('group')#) VALUES (#row[1]#, #row[2]#, '#row[3]#')",
				[],
				{datasource = variables.ds}
			);
		}
	}

	function afterAll() {
		$dropTable();
	}

	// An identifier quoted by the model adapter ("x", `x` or [x], per database).
	private string function $q(required string name) {
		var pair = application.wo.model("author").$quotedTableColumn("t", arguments.name);
		return Mid(pair, Find(".", pair) + 1, Len(pair));
	}

	private void function $dropTable() {
		try {
			QueryExecute("DROP TABLE #variables.table#", [], {datasource = variables.ds});
		} catch (any e) {
		}
	}

	function run() {

		describe("order by a reserved-word column (4374)", () => {

			it("orders by table.column the same as by the bare column", () => {
				var model = application.wo.model("ReservedOrder");
				var qualified = model.findAll(order = "#variables.table#.order DESC", returnAs = "query");
				var bare = model.findAll(order = "order DESC", returnAs = "query");
				expect(ValueList(qualified.id)).toBe("2,1,3");
				expect(ValueList(bare.id)).toBe("2,1,3");
			});

			it("orders by a second reserved-word column, qualified and ascending", () => {
				var rows = application.wo.model("ReservedOrder").findAll(order = "#variables.table#.group", returnAs = "query");
				expect(ValueList(rows.id)).toBe("2,1,3");
			});

		});

	}

}
