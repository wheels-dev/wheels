component extends="wheels.migrator.Migration" hint="an app base class that declares up(); migrations inheriting it are user code" {

	function up() {
		queryExecute("UPDATE c_o_r_e_tags SET name = name WHERE 1 = 0", {}, {datasource: application.wheels.dataSourceName});
		announce("up() inherited from an app base class");
	}

}
