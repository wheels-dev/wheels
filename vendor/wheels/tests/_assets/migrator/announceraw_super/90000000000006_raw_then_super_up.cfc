component extends="wheels.migrator.Migration" hint="own up() that runs raw SQL and then calls super.up()" {

	function up() {
		queryExecute("UPDATE c_o_r_e_tags SET name = name WHERE 1 = 0", {}, {datasource: application.wheels.dataSourceName});
		super.up();
	}

	function down() {
	}

}
