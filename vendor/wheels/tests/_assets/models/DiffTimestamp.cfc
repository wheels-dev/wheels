/**
 * A table with declared DATETIME, DATE and TIME columns, created and dropped by
 * AutoMigratorDiffSpec on SQLite, for diffing date columns against their model.
 */
component extends="Model" {

	function config() {
		table("c_o_r_e_difftimestamps");
	}

}
