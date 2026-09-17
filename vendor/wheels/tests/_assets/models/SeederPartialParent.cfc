component extends="Model" {
	function config() {
		table("c_o_r_e_refparents");
		validate("rejectSecondGeneratedRow");
	}
	function rejectSecondGeneratedRow() {
		if (this.name == "TestUser2") {
			addError(property = "name", message = "Second generated row rejected");
		}
	}
}
