/**
 * Oracle INTEGER is NUMBER(38), which identity ids and many existing schemas use. Wheels typed
 * NUMBER(38) as cf_sql_integer (32-bit), so an id above 2,147,483,647 could be rejected,
 * clamped or wrapped at bind time, and a find, update or delete by it could act on a
 * different row (#4089). Decoy rows sit at 2147483647 (a clamp) and 410065408 (9000000000
 * wrapped mod 2^32), so a wrong-row hit is visible.
 */
component extends="wheels.WheelsTest" {

	function beforeAll() {
		variables.migration = CreateObject("component", "wheels.migrator.Migration").init();
		variables.isOracle = variables.migration.adapter.adapterName() == "Oracle";
		variables.ds = application.wo.get("dataSourceName");
	}

	function afterAll() {
		if (variables.isOracle) {
			try {
				QueryExecute("DROP TABLE c_o_r_e_orabigids", [], {datasource = variables.ds});
			} catch (any e) {
				// already gone
			}
		}
		StructDelete(application.wheels.models, "OraBigId");
	}

	function run() {

		describe("An Oracle NUMBER(38) id above 2^31", () => {

			beforeEach(() => {
				if (!variables.isOracle) {
					return;
				}
				try {
					QueryExecute("DROP TABLE c_o_r_e_orabigids", [], {datasource = variables.ds});
				} catch (any e) {
					// first run
				}
				QueryExecute("CREATE TABLE c_o_r_e_orabigids (id INTEGER PRIMARY KEY, label VARCHAR2(40), counter INTEGER)", [], {datasource = variables.ds});
				QueryExecute("INSERT INTO c_o_r_e_orabigids (id, label, counter) VALUES (7, 'small', 1)", [], {datasource = variables.ds});
				QueryExecute("INSERT INTO c_o_r_e_orabigids (id, label, counter) VALUES (2147483647, 'clamp target', 1)", [], {datasource = variables.ds});
				QueryExecute("INSERT INTO c_o_r_e_orabigids (id, label, counter) VALUES (410065408, 'wrap target', 1)", [], {datasource = variables.ds});
				QueryExecute("INSERT INTO c_o_r_e_orabigids (id, label, counter) VALUES (9000000000, 'big', 1)", [], {datasource = variables.ds});
				StructDelete(application.wheels.models, "OraBigId");
			});

			it("is found by key", () => {
				if (!variables.isOracle) {
					skip("Oracle only.");
				}
				var row = model("OraBigId").findByKey(9000000000);
				expect(IsObject(row)).toBeTrue("no row found for id 9000000000");
				expect(row.label).toBe("big");
			});

			it("updates only that row", () => {
				if (!variables.isOracle) {
					skip("Oracle only.");
				}
				var row = model("OraBigId").findByKey(9000000000);
				expect(IsObject(row)).toBeTrue("no row found for id 9000000000");
				row.update(counter = 2);
				var counters = QueryExecute("SELECT counter FROM c_o_r_e_orabigids ORDER BY id", [], {datasource = variables.ds});
				expect(ValueList(counters.counter)).toBe("1,1,1,2");
			});

			it("deletes only that row", () => {
				if (!variables.isOracle) {
					skip("Oracle only.");
				}
				model("OraBigId").deleteByKey(9000000000);
				var labels = QueryExecute("SELECT label FROM c_o_r_e_orabigids ORDER BY id", [], {datasource = variables.ds});
				expect(ValueList(labels.label)).toBe("small,wrap target,clamp target");
			});

			// An ordinary small id keeps working after INTEGER columns bind as 64-bit.
			it("leaves small ids working for find, update and delete", () => {
				if (!variables.isOracle) {
					skip("Oracle only.");
				}
				var row = model("OraBigId").findByKey(7);
				expect(row.label).toBe("small");
				row.update(counter = 5);
				expect(model("OraBigId").findByKey(7).counter).toBe(5);
				model("OraBigId").deleteByKey(7);
				expect(model("OraBigId").count(where = "id = 7")).toBe(0);
			});

			// NUMBER(38) holds values beyond 64 bits. No numeric bind is exact for them, so they bind
			// as text, which Oracle converts exactly (##4162).
			it("stores and finds a value beyond 64 bits exactly", () => {
				if (!variables.isOracle) {
					skip("Oracle only.");
				}
				model("OraBigId").updateAll(where = "id = 7", counter = "123456789012345678901234567890", callbacks = false);
				var raw = QueryExecute("SELECT TO_CHAR(counter) AS c FROM c_o_r_e_orabigids WHERE id = 7", [], {datasource = variables.ds});
				expect(raw.c).toBe("123456789012345678901234567890");
				expect(model("OraBigId").count(where = "counter = 123456789012345678901234567890")).toBe(1);
				expect(model("OraBigId").count(where = "counter = 123456789012345678901234567891")).toBe(0);
			});

			it("compares an aggregate against a value beyond 64 bits", () => {
				if (!variables.isOracle) {
					skip("Oracle only.");
				}
				model("OraBigId").updateAll(where = "id = 7", counter = "123456789012345678901234567890", callbacks = false);
				var totals = model("OraBigId").findAll(select = "label, counterTotal", group = "label", where = "counterTotal > 123456789012345678901234567889");
				expect(totals.recordCount).toBe(1);
				expect(totals.label).toBe("small");
			});

			// A cf_sql_bigint bind compared with an expression, not a column.
			it("compares an aggregate against a small value", () => {
				if (!variables.isOracle) {
					skip("Oracle only.");
				}
				var totals = model("OraBigId").findAll(select = "label, counterTotal", group = "label", where = "counterTotal > 0 AND counterTotal < 2", order = "label");
				expect(totals.recordCount).toBe(4);
				expect(model("OraBigId").count(where = "id > 2147483647")).toBe(1);
			});

		});

	}

}
