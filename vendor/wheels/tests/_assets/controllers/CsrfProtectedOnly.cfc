component extends="Controller" {

	function config() {
		protectsFromForgery(only = "create");
	}

	function index() {
		renderText("Index ran.");
	}

	function create() {
		renderText("Create ran.");
	}

}
