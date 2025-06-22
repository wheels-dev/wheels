component extends="Model" {

	function config() {
		table("users");
		property(name = "birthDay", column = "birthday");
		automaticValidations(true);
	}

}
