component extends="Model" {

	/*
	 * Backs AutomaticValidationsColumnTypesSpec (#3898). The table is created by the migrator in
	 * the spec, one column per column helper, and automatic validations are turned on for this
	 * model only; the runner's global setting stays off.
	 */
	function config() {
		table("c_o_r_e_autovalidatedtypes");
		automaticValidations(true);
	}

}
