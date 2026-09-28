component extends="Model" {

	function config() {
		// `_and_` / `_or_` segments inside a table name must not be read as
		// where-clause conjunctions when the name is written in uppercase (#3675).
		table("c_o_r_e_x_and_y_or_z");
	}

}
