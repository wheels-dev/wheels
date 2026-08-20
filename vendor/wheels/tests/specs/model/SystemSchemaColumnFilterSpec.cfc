component extends="wheels.WheelsTest" {

	function run() {
		g = application.wo

		// Regression for issue #3349.
		//
		// `cfdbinfo(type="columns")` passes no schema restriction to JDBC's getColumns(), so the
		// table name is matched across every schema on the connection. PostgreSQL and YugabyteDB
		// ship real ANSI `information_schema` views named `sequences`, `tables`, `columns`,
		// `views`, `triggers` and more — so an application table named `sequences` silently
		// collected a second batch of columns from `information_schema.sequences`.
		//
		// These specs drive the filter with a hand-built catalog result rather than a live
		// PostgreSQL connection, so the logic is covered on every engine × database leg
		// including the SQLite-only ones. The end-to-end behaviour is verified separately
		// against a real PostgreSQL container.
		describe("Tests that $excludeSystemSchemaRows", () => {

			$catalogResult = function() {
				var q = QueryNew("table_schem,table_name,column_name,type_name")
				var rows = [
					["public", "sequences", "id", "uuid"],
					["public", "sequences", "name", "varchar"],
					["public", "sequences", "value", "int8"],
					["information_schema", "sequences", "sequence_catalog", '"information_schema"."sql_identifier"'],
					["information_schema", "sequences", "start_value", '"information_schema"."character_data"'],
					["pg_catalog", "sequences", "oid", "oid"],
					["crdb_internal", "sequences", "descriptor_id", "int8"],
					["pg_extension", "sequences", "ext_col", "int8"]
				]
				for (var row in rows) {
					QueryAddRow(q)
					QuerySetCell(q, "table_schem", row[1])
					QuerySetCell(q, "table_name", row[2])
					QuerySetCell(q, "column_name", row[3])
					QuerySetCell(q, "type_name", row[4])
				}
				return q
			}

			it("keeps only the application schema's columns", () => {
				result = g.$excludeSystemSchemaRows(columns = $catalogResult())

				expect(result.recordCount).toBe(3)
				expect(ValueList(result.column_name)).toBe("id,name,value")
			})

			it("drops every system schema, not just information_schema", () => {
				result = g.$excludeSystemSchemaRows(columns = $catalogResult())

				// `crdb_internal` and `pg_extension` collide too, reached via
				// CockroachDBModel extends PostgreSQLModel
				expect(ValueList(result.table_schem)).toBe("public,public,public")
			})

			it("preserves every column of the source result", () => {
				source = $catalogResult()
				result = g.$excludeSystemSchemaRows(columns = source)

				expect(ListSort(result.columnList, "textnocase")).toBe(ListSort(source.columnList, "textnocase"))
			})

			it("returns a result with no table_schem column untouched", () => {
				// several engines' cfdbinfo omits it; filtering must not blank the result
				noSchema = QueryNew("column_name")
				QueryAddRow(noSchema)
				QuerySetCell(noSchema, "column_name", "id")

				result = g.$excludeSystemSchemaRows(columns = noSchema)

				expect(result.recordCount).toBe(1)
			})

			it("is case-insensitive about the schema name", () => {
				upper = QueryNew("table_schem,column_name")
				QueryAddRow(upper)
				QuerySetCell(upper, "table_schem", "INFORMATION_SCHEMA")
				QuerySetCell(upper, "column_name", "sequence_catalog")

				expect(g.$excludeSystemSchemaRows(columns = upper).recordCount).toBe(0)
			})
		})

		describe("Tests that the PostgreSQL adapter", () => {

			// Before this, an unmapped type left `local.rv` unassigned and the return threw
			// `key [RV] doesn't exist` — which names neither the column, the type, nor the
			// table, and reads like a framework bug rather than a schema problem.
			it("names the offending type instead of throwing key [RV] doesn't exist", () => {
				adapter = CreateObject("component", "wheels.databaseAdapters.PostgreSQL.PostgreSQLModel")
				thrown = {type: "", message: ""}

				try {
					adapter.$getType(type = '"information_schema"."sql_identifier"')
				} catch (any e) {
					thrown.type = e.type
					thrown.message = e.message
				}

				expect(thrown.type).toBe("Wheels.UnknownColumnType")
				expect(thrown.message).toInclude("sql_identifier")
			})

			it("still maps the types it knows", () => {
				adapter = CreateObject("component", "wheels.databaseAdapters.PostgreSQL.PostgreSQLModel")

				expect(adapter.$getType(type = "int8")).toBe("cf_sql_bigint")
				expect(adapter.$getType(type = "uuid")).toBe("cf_sql_varchar")
				expect(adapter.$getType(type = "jsonb")).toBe("cf_sql_longvarchar")
			})
		})
	}

}
