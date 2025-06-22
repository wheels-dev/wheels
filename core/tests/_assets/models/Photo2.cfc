component extends="Model" {

	function config() {
		table("photos");
		property(name = "DESCRIPTION1", column = "description");
		property(name = "photoid", column = "id");
	}

}
