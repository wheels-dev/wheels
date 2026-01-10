component extends="wheels.tests.Test" {

	function setup() {
		migration = CreateObject("component", "wheels.migrator.Migration").init();
	}

	function test_createTable_generates_table() {
		tableName = "dbm_createtable_tests";
		t = migration.createTable(name = tableName, force = true);
		t.string(columnNames = 'stringcolumn, secondstringcolumn ', limit = 255); // notice the untrimmed column name
		t.text(columnNames = 'textcolumn');
		t.boolean(columnNames = 'booleancolumn', default = false, allowNull = false);
		t.integer(columnNames = 'integercolumn', default = 0);
		t.binary(columnNames = "binarycolumn");
		t.date(columnNames = "datecolumn");
		t.dateTime(columnNames = "datetimecolumn");
		t.time(columnNames = "timecolumn");
		t.decimal(columnNames = "decimalcolumn");
		t.float(columnNames = "floatcolumn");
		// TODO: this datatype doesn't work on sqlserver
		// t.bigInteger(columnNames="bigintegercolumn", default=0);
		t.timeStamps();
		t.create();

		actual = ListSort(model(tableName).findAll().columnList, "text");
		expected = ListSort(
			"id,stringcolumn,secondstringcolumn,textcolumn,booleancolumn,integercolumn,binarycolumn,datecolumn,datetimecolumn,timecolumn,decimalcolumn,floatcolumn,createdat,updatedat,deletedat",
			"text"
		);

		migration.dropTable(tableName);
		assert("actual eq expected");
	}

	function test_createTable_generates_table_using_MicrosoftSQLServer_datatypes() {
		tableName = "dbm_createtable_sqlserver_tests";
		if (migration.adapter.adapterName() eq "MicrosoftSQLServer") {
			t = migration.createTable(name = tableName, force = true);
			t.char(columnNames = "charcolumn");
			t.uniqueIdentifier(columnNames = "uniqueidentifiercolumn");
			t.create();
			actual = ListSort(model(tableName).findAll().columnList, "text");
			expected = ListSort("id,charcolumn,uniqueidentifiercolumn", "text");
			migration.dropTable(tableName);
			assert("actual eq expected");
		}
	}

}
