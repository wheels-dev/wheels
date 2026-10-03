component extends="Model" {

	/*
	 * Backs sqliteDateColumnSpec (#4093): a table with TEXT date columns, as SQLite apps created
	 * before #4093 have them. Automatic validations are on for this model only.
	 */
	function config() {
		table("c_o_r_e_sqlitetextdatecols");
		automaticValidations(true);
	}

}
