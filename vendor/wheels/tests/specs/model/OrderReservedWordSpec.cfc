/**
 * Ordering by a column whose name is a reserved word, through order="table.column"
 * as well as order="column" (4374): the qualified form is quoted like the bare one.
 * The spec owns its table, c_o_r_e_reservedorders, created with the adapter's own
 * identifier quoting, and drops it afterwards. As of #4440 the H2 adapter quotes
 * identifiers in the datasource's own fold case, so this runs unskipped there too;
 * the second describe pins that probe and the default-folding behaviour on H2.
 */
component extends="wheels.WheelsTest" {

	function beforeAll() {
		variables.ds = application.wheels.dataSourceName;
		variables.table = "c_o_r_e_reservedorders";
		variables.dialect = application.wo.model("author").$dialectName();
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

	// Hoisted out of the `finally` below: a for loop over a var inside `finally`
	// miscompiles on Lucee 7 (see the finally-loop invariant in CLAUDE.md).
	private void function $deleteRows(required array keys) {
		for (var key in arguments.keys) {
			try {
				application.wo.model("CasePreservation").deleteByKey(key = key);
			} catch (any e) {
			}
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

		describe("H2 identifier case (##4440)", () => {

			beforeEach(() => {
				if (variables.dialect != "H2") {
					skip("identifier folding is an H2 concern");
				}
			});

			it("probes the default fold case as upper", () => {
				var adapter = CreateObject("component", "wheels.databaseAdapters.H2.H2Model");
				adapter.$init(dataSource = application.wheels.dataSourceName, username = "", password = "");
				// The suite's H2 datasource only sets MODE=MySQL, so H2's default folding applies.
				expect(adapter.$readIdentifierCase(dataSource = application.wheels.dataSourceName)).toBe("upper");
				expect(adapter.$identifierCase()).toBe("upper");
			});

			it("resolves reads and writes against an unquoted-created table under default folding", () => {
				// tests/populate.cfm creates c_o_r_e_casepreservation unquoted with a mixed-case
				// `isHidden` column. H2 folds that to ISHIDDEN; the adapter now sends "ISHIDDEN",
				// which must still resolve for order=, where= and save() on a schema it did not create.
				var model = application.wo.model("CasePreservation");
				var names = model.propertyNames();
				var hidden = "";
				for (var i = 1; i <= ListLen(names); i++) {
					if (CompareNoCase(ListGetAt(names, i), "isHidden") == 0) {
						hidden = ListGetAt(names, i);
					}
				}
				expect(Len(hidden)).toBeGT(0);

				// The fixture is not seeded, and only this spec writes to it.
				QueryExecute("DELETE FROM c_o_r_e_casepreservation", [], {datasource = variables.ds});

				var created = [];
				try {
					var highProps = {};
					highProps[hidden] = 1;
					var high = model.create(properties = highProps);
					ArrayAppend(created, high.id);

					var lowProps = {};
					lowProps[hidden] = 0;
					var low = model.create(properties = lowProps);
					ArrayAppend(created, low.id);

					var byOrder = model.findAll(order = "#hidden# DESC", returnAs = "query");
					expect(byOrder.recordCount).toBe(2);
					expect(byOrder.id[1]).toBe(high.id);
					expect(byOrder.id[2]).toBe(low.id);

					var filtered = model.findAll(where = "#hidden# = 0", returnAs = "query");
					expect(filtered.recordCount).toBe(1);
					expect(filtered.id[1]).toBe(low.id);

					var target = model.findByKey(low.id);
					target[hidden] = 1;
					expect(target.save()).toBeTrue();
					var reread = model.findByKey(low.id);
					expect(reread[hidden]).toBe(1);
				} finally {
					$deleteRows(created);
				}
			});

		});

	}

}
