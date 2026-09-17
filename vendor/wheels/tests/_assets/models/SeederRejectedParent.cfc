component extends="Model" {
	function config() {
		table("c_o_r_e_refparents");
		// Like auth scaffolds, require a transient value generated column data cannot supply.
		validatesPresenceOf("passwordConfirmation");
	}
}
