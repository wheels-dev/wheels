component extends="Model" {

	function config() {
		table("users");
		automaticValidations(true);
		property(name = "id", automaticValidations = false);
	}

}
