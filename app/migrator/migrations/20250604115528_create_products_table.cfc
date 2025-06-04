/*
  |----------------------------------------------------------------------------------------------|
	| Parameter  | Required | Type    | Default | Description                                      |
  |----------------------------------------------------------------------------------------------|
	| name       | Yes      | string  |         | table name, in pluralized form                   |
	| force      | No       | boolean | false   | drop existing table of same name before creating |
	| id         | No       | boolean | true    | if false, defines a table with no primary key    |
	| primaryKey | No       | string  | id      | overrides default primary key name               |
  |----------------------------------------------------------------------------------------------|

    EXAMPLE:
      t = createTable(name='employees', force=false, id=true, primaryKey='empId');
			t.string(columnNames='firstName,lastName', default='', null=true, limit='255');
			t.text(columnNames='bio', default='', null=true);
			t.timestamps();
			t.create();
*/
component extends="wheels.migrator.Migration" hint="Migration: create_products_table" {

	function up() {
		transaction {
			try {
				t = createTable(name = 'products', force='false', id='true', primaryKey='id');
				t.string(columnNames='name', default='', null=true, limit='255');
				t.text(columnNames='description', default='', null=true);
				t.decimal(columnNames='price', default='', null=true, precision='10', scale='2');
				t.integer(columnNames='stock', default='', null=true, limit='11');
				t.boolean(columnNames='active', default='', null=true);
				t.timestamps();
				t.create();
			} catch (any e) {
				local.exception = e;
			}

			if (StructKeyExists(local, "exception")) {
				transaction action="rollback";
				Throw(errorCode = "1", detail = local.exception.detail, message = local.exception.message, type = "any");
			} else {
				transaction action="commit";
			}
		}
	}

	function down() {
		transaction {
			try {
				dropTable('products');
			} catch (any e) {
				local.exception = e;
			}

			if (StructKeyExists(local, "exception")) {
				transaction action="rollback";
				Throw(errorCode = "1", detail = local.exception.detail, message = local.exception.message, type = "any");
			} else {
				transaction action="commit";
			}
		}
	}

}
