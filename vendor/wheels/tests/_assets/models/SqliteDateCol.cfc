component extends="Model" {

	/*
	 * Backs sqliteDateColumnSpec (#4093): a table the migrator creates with date, datetime, time
	 * and timestamp columns. Automatic validations are on for this model only.
	 */
	function config() {
		table("c_o_r_e_sqlitedatecols");
		automaticValidations(true);
	}

}
