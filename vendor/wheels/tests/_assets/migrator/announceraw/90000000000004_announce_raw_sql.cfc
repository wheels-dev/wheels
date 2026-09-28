component extends="wheels.migrator.Migration" hint="raw queryExecute then announce — the migrator cannot see the SQL" {

	function up() {
		queryExecute("UPDATE c_o_r_e_tags SET name = name WHERE 1 = 0", {}, {datasource: application.wheels.dataSourceName});
		announce("raw SQL through queryExecute, then announce");
	}

	function down() {
		queryExecute("UPDATE c_o_r_e_tags SET name = name WHERE 1 = 0", {}, {datasource: application.wheels.dataSourceName});
		announce("raw SQL through queryExecute, then announce (down)");
	}

}
