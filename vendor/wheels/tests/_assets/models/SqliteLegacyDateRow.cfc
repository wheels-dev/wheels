component extends="Model" {

	/*
	 * Backs sqliteDateColumnSpec (#4093): a table with columns declared DATE and TIME outside the
	 * migrator, holding a row written the pre-#4093 way (epoch milliseconds). Automatic
	 * validations are on for this model only.
	 */
	function config() {
		table("c_o_r_e_sqlitelegacyrows");
		automaticValidations(true);
	}

}
