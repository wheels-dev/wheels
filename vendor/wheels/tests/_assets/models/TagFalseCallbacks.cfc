component extends="Model" {

	function config() {
		table("_c_o_r_e_tags");
		afterSave("callbackThatReturnsFalse");
		afterDelete("callbackThatReturnsFalse");
	}

	function callbackThatReturnsFalse() {
		return false;
	}

}
