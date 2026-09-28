component extends="Model" {

	function config() {
		// `$` inside a table name is legal on every supported database (#3669).
		table("c_o_r_e_admin$widgets");
	}

}
