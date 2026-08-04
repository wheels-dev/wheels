component extends="Model" {

	function config() {
		table("c_o_r_e_posts");
	}

	/**
	 * Model-side counterpart to the controller fixture of the same name. The model
	 * layer has always registered `super<name>`; this pins that so the parity the
	 * issue #3325 fix establishes cannot regress from either side.
	 */
	public string function columnNames() {
		return "wrapped:" & superColumnNames();
	}

}
