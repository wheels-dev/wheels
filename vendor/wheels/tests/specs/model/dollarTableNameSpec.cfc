/**
 * #3669 — table names containing `$` (e.g. `admin$users`) worked in 4.0.5 and
 * broke in 4.1.0 when `$dbinfo()` started rejecting non-identifier table
 * names. `$` is a legal identifier character after the first position on every
 * supported database, so each identifier check a `$` table name passes through
 * must accept it while still rejecting the metacharacters it guards against.
 */
component extends="wheels.WheelsTest" {

	variables.dollarTable = "c_o_r_e_admin$widgets";

	function beforeAll() {
		var ds = {datasource = application.wheels.dataSourceName};
		try {
			QueryExecute("DROP TABLE #variables.dollarTable#", [], ds);
		} catch (any e) {
		}
		QueryExecute("CREATE TABLE #variables.dollarTable# (id int NOT NULL, name varchar(50) NOT NULL, PRIMARY KEY(id))", [], ds);
		QueryExecute("INSERT INTO #variables.dollarTable# (id, name) VALUES (1, 'gamma')", [], ds);
		QueryExecute("INSERT INTO #variables.dollarTable# (id, name) VALUES (2, 'alpha')", [], ds);
		QueryExecute("INSERT INTO #variables.dollarTable# (id, name) VALUES (3, 'beta')", [], ds);
	}

	function afterAll() {
		try {
			QueryExecute("DROP TABLE #variables.dollarTable#", [], {datasource = application.wheels.dataSourceName});
		} catch (any e) {
		}
	}

	function run() {

		g = application.wo;

		describe("Table names containing $ (##3669)", () => {

			describe("a model mapped to a $ table", () => {

				it("initializes and reads its columns", () => {
					var widget = g.model("DollarWidget").findByKey(2);
					expect(widget.name).toBe("alpha");
				});

				it("counts and finds rows", () => {
					expect(g.model("DollarWidget").count()).toBe(3);
					var widgets = g.model("DollarWidget").findAll(order = "name");
					expect(widgets.recordCount).toBe(3);
					expect(widgets.name[1]).toBe("alpha");
				});

				it("paginates, which appends a table-qualified primary key to the order clause", () => {
					var widgets = g.model("DollarWidget").findAll(order = "name", page = 1, perPage = 2);
					expect(widgets.recordCount).toBe(2);
					expect(widgets.name[1]).toBe("alpha");
					expect(widgets.name[2]).toBe("beta");
				});

				it("filters with a table-qualified where clause", () => {
					var widgets = g.model("DollarWidget").findAll(where = "#dollarTable#.name = 'beta'");
					expect(widgets.recordCount).toBe(1);
					expect(widgets.id[1]).toBe(3);
				});

				it("returns an empty page with clean column names past the last page", () => {
					var widgets = g.model("DollarWidget").findAll(order = "name", page = 5, perPage = 2);
					expect(widgets.recordCount).toBe(0);
					expect(ListSort(LCase(widgets.columnList), "text")).toBe("id,name");
				});

			});

			describe("$dbinfo", () => {

				it("accepts a table name with $ after the first character", () => {
					var cols = g.$dbinfo(
						datasource = application.wheels.dataSourceName,
						type = "columns",
						table = dollarTable
					);
					expect(cols.recordCount).toBe(2);
				});

				it("still rejects a table name that starts with $", () => {
					expect(() => {
						g.$dbinfo(datasource = application.wheels.dataSourceName, type = "columns", table = "$widgets");
					}).toThrow("Wheels.InvalidArgument");
				});

				it("still rejects a quote in a $ table name", () => {
					expect(() => {
						g.$dbinfo(datasource = application.wheels.dataSourceName, type = "index", table = "admin$x'; DROP TABLE wheels--");
					}).toThrow("Wheels.InvalidArgument");
				});

			});

			describe("ORDER BY and GROUP BY dot-notation", () => {

				it("accepts a $ table in ORDER BY", () => {
					var widget = g.model("DollarWidget");
					var result = widget.$orderByClause(order = "#dollarTable#.name DESC", include = "");
					// Quoted like the bare column since 4374.
					expect(result).toBe(widget.$orderByClause(order = "name DESC", include = ""));
				});

				it("still rejects injection behind a $ table in ORDER BY", () => {
					expect(() => {
						g.model("DollarWidget").$orderByClause(order = "#dollarTable#.name;DELETE", include = "");
					}).toThrow("Wheels.InvalidOrderClause");
				});

				it("accepts a $ table in GROUP BY", () => {
					var result = g.model("DollarWidget").$groupByClause(
						select = "name",
						include = "",
						group = "#dollarTable#.name",
						distinct = false,
						returnAs = "query"
					);
					expect(result).toInclude("#dollarTable#.name");
				});

			});

			describe("QueryBuilder", () => {

				it("accepts a $ table prefix on a property", () => {
					var qb = new wheels.model.query.QueryBuilder(modelReference = g.model("DollarWidget"));
					expect(() => {
						qb.whereNull("#dollarTable#.name");
					}).notToThrow();
				});

				it("still rejects a leading $ on a property", () => {
					var qb = new wheels.model.query.QueryBuilder(modelReference = g.model("DollarWidget"));
					expect(() => {
						qb.whereNull("$name");
					}).toThrow("Wheels.InvalidPropertyName");
				});

			});

			describe("AutoMigrator generated CFC identifiers", () => {

				it("accepts a $ table name", () => {
					var autoMigrator = CreateObject("component", "wheels.migrator.AutoMigrator");
					expect(autoMigrator.$escapeCfcIdentifier("admin$users")).toBe("admin$users");
				});

				it("still rejects a hash, which would open a CFML expression", () => {
					var autoMigrator = CreateObject("component", "wheels.migrator.AutoMigrator");
					expect(() => {
						autoMigrator.$escapeCfcIdentifier("admin##users");
					}).toThrow("Wheels.Migrator.InvalidIdentifier");
				});

			});

		});

	}

}
