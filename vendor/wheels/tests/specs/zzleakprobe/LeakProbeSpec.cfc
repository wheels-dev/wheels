/**
 * DIAGNOSTIC ONLY (#3732, diag branch, never merged). One suspect per request,
 * selected by ?leakphase=; the workflow counts live Oracle statement objects
 * (after a full GC) before and after each request.
 *
 * Separates Adobe's cfdbinfo from the Oracle driver: the jdbc_* phases call
 * the same DatabaseMetaData methods directly on a pooled connection. If the
 * *_closed phases retain nothing while dbinfo_columns does, cfdbinfo is not
 * closing its result sets; if they retain as much, it is the driver.
 */
component extends="wheels.WheelsTest" {
	function run() {
		describe("leak probe (##3732)", () => {
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
						case "jdbc_columns_closed":
							metaProbe(ds, "columns", true);
							break;
						case "jdbc_columns_open":
							metaProbe(ds, "columns", false);
							break;
						case "jdbc_pk_closed":
							metaProbe(ds, "pk", true);
							break;
						case "jdbc_fk_closed":
							metaProbe(ds, "fk", true);
							break;
						case "jdbc_index_closed":
							metaProbe(ds, "index", true);
							break;
						case "dict_columns":
							queryExecute(
								"SELECT c.column_name, c.data_type, c.data_length, c.data_precision, c.data_scale, c.nullable, c.column_id
								FROM user_tab_columns c WHERE c.table_name = :t ORDER BY c.column_id",
								{t: {value: "C_O_R_E_AUTHORS", cfsqltype: "cf_sql_varchar"}},
								{datasource: ds}
							);
							break;
						case "query_plain":
							queryExecute("SELECT id FROM c_o_r_e_authors WHERE id = " & i, {}, {datasource: ds});
							break;
					}
				}
				expect(true).toBeTrue();
			});
		});
	}

	/** One DatabaseMetaData call on a pooled Adobe connection; `closeIt` closes the ResultSet. */
	private void function metaProbe(required string ds, required string kind, required boolean closeIt) {
		var conn = createObject("java", "coldfusion.server.ServiceFactory").getDataSourceService().getDatasource(arguments.ds).getConnection();
		try {
			var md = conn.getMetaData();
			var rs = "";
			switch (arguments.kind) {
				case "columns":
					rs = md.getColumns(javaCast("null", ""), javaCast("null", ""), "C_O_R_E_AUTHORS", javaCast("null", ""));
					break;
				case "pk":
					rs = md.getPrimaryKeys(javaCast("null", ""), javaCast("null", ""), "C_O_R_E_AUTHORS");
					break;
				case "fk":
					rs = md.getImportedKeys(javaCast("null", ""), javaCast("null", ""), "C_O_R_E_AUTHORS");
					break;
				case "index":
					rs = md.getIndexInfo(javaCast("null", ""), javaCast("null", ""), "C_O_R_E_AUTHORS", javaCast("boolean", false), javaCast("boolean", true));
					break;
			}
			while (rs.next()) {
				rs.getString(1);
			}
			if (arguments.closeIt) {
				rs.close();
			}
		} finally {
			conn.close();
		}
	}
}
