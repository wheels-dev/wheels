/**
 * `null` is the column option's 2.x name, renamed `allowNull` in 3.0. It's a deprecated alias
 * again: column(), the typed column functions and references() read it when `allowNull` isn't
 * passed, so a 2.x migration's `null = false` gives a NOT NULL column. `null` is a keyword on some
 * engines, so the specs pass it through argumentCollection. No table is created.
 */
component extends="wheels.WheelsTest" {

	function beforeAll() {
		variables.migration = CreateObject("component", "wheels.migrator.Migration").init();
	}

	function newTable() {
		return variables.migration.createTable(name = "c_o_r_e_nullalias", force = true, id = false);
	}

	// Column options with `null` set to `value`, plus `extra`.
	function options(required struct extra, required boolean value) {
		var rv = Duplicate(arguments.extra);
		rv["null"] = arguments.value;
		return rv;
	}

	function lastColumn(required any table) {
		return arguments.table.columns[ArrayLen(arguments.table.columns)];
	}

	function run() {

		describe("The null column option", () => {

			it("sets allowNull on the typed column functions", () => {
				var t = newTable();
				t.string(argumentCollection = options({columnNames = "title"}, false));
				expect(lastColumn(t).allowNull).toBeFalse();
				t.integer(argumentCollection = options({columnNames = "views"}, true));
				expect(lastColumn(t).allowNull).toBeTrue();
			});

			it("sets allowNull on column() and references()", () => {
				var t = newTable();
				t.column(argumentCollection = options({columnName = "code", columnType = "string"}, false));
				expect(lastColumn(t).allowNull).toBeFalse();
				t.references(argumentCollection = options({columnNames = "author"}, true));
				expect(lastColumn(t).allowNull).toBeTrue();
			});

			it("loses to allowNull when both are passed", () => {
				var t = newTable();
				t.string(argumentCollection = options({columnNames = "title", allowNull = true}, false));
				expect(lastColumn(t).allowNull).toBeTrue();
				t.references(argumentCollection = options({columnNames = "author", allowNull = false}, true));
				expect(lastColumn(t).allowNull).toBeFalse();
			});

			it("keeps references() NOT NULL by default", () => {
				var t = newTable();
				t.references(columnNames = "author");
				expect(lastColumn(t).allowNull).toBeFalse();
			});

			it("logs the deprecation once per request", () => {
				var t = newTable();
				StructDelete(request, "$wheelsMigratorNullAliasWarned");
				t.string(argumentCollection = options({columnNames = "a"}, false));
				expect(StructKeyExists(request, "$wheelsMigratorNullAliasWarned")).toBeTrue();
				expect(t.$warnNullAlias()).toBeFalse();
			});

		});

	}

}
