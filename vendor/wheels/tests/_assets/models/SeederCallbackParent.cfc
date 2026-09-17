component extends="Model" {
	function config() {
		table("c_o_r_e_refparents");
		beforeSave("writeThenAbort");
	}
	function writeThenAbort() {
		model("RefParent").create(name = "SeederCallbackSideEffect");
		return false;
	}
}
