/**
 * DIAGNOSTIC ONLY (#3709, diag branch, never merged). One suspect per request,
 * selected by ?leakphase=; the workflow takes a live-object histogram (after a
 * full GC) between requests. The phase whose Oracle statement count grows by
 * ~N is the one that leaves statements open.
 */
component extends="wheels.WheelsTest" {
	function run() {
		describe("leak probe (##3709)", () => {
			it("runs the selected phase", () => {
				var phase = StructKeyExists(url, "leakphase") ? url.leakphase : "";
				var n = StructKeyExists(url, "leakn") ? Val(url.leakn) : 200;
				var ds = application.wheels.dataSourceName;
				var g = application.wo;
				for (var i = 1; i <= n; i++) {
					switch (phase) {
						case "dbinfo_columns":
							g.$dbinfo(type = "columns", table = "c_o_r_e_authors", datasource = ds);
							break;
						case "dbinfo_index":
							g.$dbinfo(type = "index", table = "c_o_r_e_authors", datasource = ds);
							break;
						case "query_plain":
							queryExecute("SELECT id FROM c_o_r_e_authors WHERE id = " & i, {}, {datasource: ds});
							break;
						case "query_param":
							queryExecute("SELECT id FROM c_o_r_e_authors WHERE id = :id", {id: {value: i, cfsqltype: "cf_sql_integer"}}, {datasource: ds});
							break;
						case "finder":
							g.model("author").findAll(where = "id = " & i);
							break;
					}
				}
				expect(true).toBeTrue();
			});
		});
	}
}
