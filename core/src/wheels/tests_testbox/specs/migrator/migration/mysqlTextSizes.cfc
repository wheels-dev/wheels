component extends="testbox.system.BaseSpec" {

	function beforeAll() {
		migration = CreateObject("component", "wheels.migrator.Migration").init();
		originalMigratorObjectCase = Duplicate(application.wheels.migratorObjectCase);
	}

	function afterAll() {
		application.wheels.migratorObjectCase = originalMigratorObjectCase;
	}

	// Helper functions
	private boolean function isMySQL() {
		return migration.adapter.adapterName() == "MySQL";
	}

	private array function getTextType(string size = "") {
		switch (LCase(arguments.size)) {
			case "mediumtext":
				return ["MEDIUMTEXT"];
			case "longtext":
				return ["LONGTEXT"];
			default:
				return ["TEXT"];
		}
	}

	function run() {

		g = application.wo

		describe("MySQL Text Size Support Tests", function() {
			
			it("Creates a default text column", function() {
				if (!isMySQL()) {
					return true;
				}

				tableName = "dbm_mysql_text_tests";
				columnName = "defaultTextColumn";
				t = migration.createTable(name = tableName, force = true);
				t.text(columnName = columnName);
				t.create();

				info = g.$dbinfo(datasource = application.wheels.dataSourceName, table = tableName, type = "columns");
				actual = ListToArray(ValueList(info.TYPE_NAME))[2];
				migration.dropTable(tableName);

				expected = getTextType();

				expect(ArrayContainsNoCase(expected, actual)).toBeTrue();
			});

			it("Creates a medium text column", function() {
				if (!isMySQL()) {
					return true;
				}

				tableName = "dbm_mysql_text_tests";
				columnName = "mediumTextColumn";
				t = migration.createTable(name = tableName, force = true);
				t.text(columnName = columnName, size = "mediumtext");
				t.create();

				info = g.$dbinfo(datasource = application.wheels.dataSourceName, table = tableName, type = "columns");
				actual = ListToArray(ValueList(info.TYPE_NAME))[2];
				migration.dropTable(tableName);

				expected = getTextType("mediumtext");

				expect(ArrayContainsNoCase(expected, actual)).toBeTrue();
			});

			it("Creates a long text column", function() {
				if (!isMySQL()) {
					return true;
				}

				tableName = "dbm_mysql_text_tests";
				columnName = "longTextColumn";
				t = migration.createTable(name = tableName, force = true);
				t.text(columnName = columnName, size = "longtext");
				t.create();

				info = g.$dbinfo(datasource = application.wheels.dataSourceName, table = tableName, type = "columns");
				actual = ListToArray(ValueList(info.TYPE_NAME))[2];
				migration.dropTable(tableName);

				expected = getTextType("longtext");

				expect(ArrayContainsNoCase(expected, actual)).toBeTrue();
			});

			it("Creates multiple text columns with different sizes", function() {
				if (!isMySQL()) {
					return true;
				}

				tableName = "dbm_mysql_text_tests";
				t = migration.createTable(name = tableName, force = true);
				t.text(columnName = "defaultTextCol");
				t.text(columnName = "mediumTextCol", size = "mediumtext");
				t.text(columnName = "longTextCol", size = "longtext");
				t.create();

				info = g.$dbinfo(datasource = application.wheels.dataSourceName, table = tableName, type = "columns");
				actual = ListToArray(ValueList(info.TYPE_NAME));
				migration.dropTable(tableName);

				// The first column is the primary key
				expect(ArrayContainsNoCase(getTextType(), actual[2])).toBeTrue();
				expect(ArrayContainsNoCase(getTextType("mediumtext"), actual[3])).toBeTrue();
				expect(ArrayContainsNoCase(getTextType("longtext"), actual[4])).toBeTrue();
			});

			it("Creates multiple text columns with the same size", function() {
				if (!isMySQL()) {
					return true;
				}

				tableName = "dbm_mysql_text_tests";
				columnNames = "textA,textB";
				t = migration.createTable(name = tableName, force = true);
				t.text(columnNames = columnNames, size = "mediumtext");
				t.create();

				info = g.$dbinfo(datasource = application.wheels.dataSourceName, table = tableName, type = "columns");
				actual = ListToArray(ValueList(info.TYPE_NAME));
				migration.dropTable(tableName);

				expected = getTextType("mediumtext");

				expect(ArrayContainsNoCase(expected, actual[2])).toBeTrue();
				expect(ArrayContainsNoCase(expected, actual[3])).toBeTrue();
			});

			it("Defaults to TEXT when invalid size is provided", function() {
				if (!isMySQL()) {
					return true;
				}

				tableName = "dbm_mysql_text_tests";
				columnName = "invalidSizeColumn";
				t = migration.createTable(name = tableName, force = true);
				t.text(columnName = columnName, size = "invalid");
				t.create();

				info = g.$dbinfo(datasource = application.wheels.dataSourceName, table = tableName, type = "columns");
				actual = ListToArray(ValueList(info.TYPE_NAME))[2];
				migration.dropTable(tableName);

				expected = getTextType();

				expect(ArrayContainsNoCase(expected, actual)).toBeTrue();
			});

			it("Defaults to TEXT when empty size is provided", function() {
				if (!isMySQL()) {
					return true;
				}

				tableName = "dbm_mysql_text_tests";
				columnName = "emptySizeColumn";
				t = migration.createTable(name = tableName, force = true);
				t.text(columnName = columnName, size = "");
				t.create();

				info = g.$dbinfo(datasource = application.wheels.dataSourceName, table = tableName, type = "columns");
				actual = ListToArray(ValueList(info.TYPE_NAME))[2];
				migration.dropTable(tableName);

				expected = getTextType();

				expect(ArrayContainsNoCase(expected, actual)).toBeTrue();
			});

			it("Creates nullable text columns of all sizes", function() {
				if (!isMySQL()) {
					return true;
				}

				tableName = "dbm_mysql_text_tests";
				t = migration.createTable(name = tableName, force = true);
				t.text(columnName = "nullableText", allowNull = true);
				t.text(columnName = "mediumNullableText", allowNull = true, size = "mediumtext");
				t.text(columnName = "longNullableText", allowNull = true, size = "longtext");
				t.create();

				info = g.$dbinfo(datasource = application.wheels.dataSourceName, table = tableName, type = "columns");
				migration.dropTable(tableName);

				// Filter only our text columns
				textCols = [];
				for (var col in info) {
					if (ListFind("nullableText,mediumNullableText,longNullableText", col.COLUMN_NAME)) {
						ArrayAppend(textCols, col);
					}
				}

				// All should be nullable
				for (var col in textCols) {
					expect(col.IS_NULLABLE).toBeTrue();
				}
			});

			it("Creates non-nullable text columns of all sizes", function() {
				if (!isMySQL()) {
					return true;
				}

				tableName = "dbm_mysql_text_tests";
				t = migration.createTable(name = tableName, force = true);
				t.text(columnName = "nonNullText", allowNull = false);
				t.text(columnName = "mediumNonNullText", allowNull = false, size = "mediumtext");
				t.text(columnName = "longNonNullText", allowNull = false, size = "longtext");
				t.create();

				info = g.$dbinfo(datasource = application.wheels.dataSourceName, table = tableName, type = "columns");
				migration.dropTable(tableName);

				// Filter only our text columns
				textCols = [];
				for (var col in info) {
					if (ListFind("nonNullText,mediumNonNullText,longNonNullText", col.COLUMN_NAME)) {
						ArrayAppend(textCols, col);
					}
				}

				// All should be non-nullable
				for (var col in textCols) {
					expect(col.IS_NULLABLE).toBeFalse();
				}
			});

			it("Changes a column from TEXT to MEDIUMTEXT", function() {
				if (!isMySQL()) {
					return true;
				}

				tableName = "dbm_mysql_text_tests";
				columnName = "textToMedium";
				
				// Create table with regular text column
				t = migration.createTable(name = tableName, force = true);
				t.text(columnName = columnName);
				t.create();
				
				// Change to mediumtext
				migration.changeColumn(
					table = tableName,
					columnName = columnName,
					columnType = "text",
					size = "mediumtext"
				);
				
				info = g.$dbinfo(datasource = application.wheels.dataSourceName, table = tableName, type = "columns");
				
				// Get column info
				columnInfo = "";
				for (var col in info) {
					if (col.COLUMN_NAME == columnName) {
						columnInfo = col;
						break;
					}
				}
				
				migration.dropTable(tableName);
				
				expected = getTextType("mediumtext");
				actual = columnInfo.TYPE_NAME;
				
				expect(ArrayContainsNoCase(expected, actual)).toBeTrue();
			});

			it("Changes a column from MEDIUMTEXT to LONGTEXT", function() {
				if (!isMySQL()) {
					return true;
				}

				tableName = "dbm_mysql_text_tests";
				columnName = "mediumToLong";
				
				// Create table with medium text column
				t = migration.createTable(name = tableName, force = true);
				t.text(columnName = columnName, size = "mediumtext");
				t.create();
				
				// Change to longtext
				migration.changeColumn(
					table = tableName,
					columnName = columnName,
					columnType = "text",
					size = "longtext"
				);
				
				info = g.$dbinfo(datasource = application.wheels.dataSourceName, table = tableName, type = "columns");
				
				// Get column info
				columnInfo = "";
				for (var col in info) {
					if (col.COLUMN_NAME == columnName) {
						columnInfo = col;
						break;
					}
				}
				
				migration.dropTable(tableName);
				
				expected = getTextType("longtext");
				actual = columnInfo.TYPE_NAME;
				
				expect(ArrayContainsNoCase(expected, actual)).toBeTrue();
			});
		});
	}
}