component extends="Model" {

	function config() {
		table("users");
		property(name = "firstName", sql = "'Calculated Property Column Override'");
	}

}
