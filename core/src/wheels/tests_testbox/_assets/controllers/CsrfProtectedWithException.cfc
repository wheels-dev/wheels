component extends="Controller" {

	function config() {
		protectsFromForgery();
	}

	function index() {
		renderText("Index ran.");
	}

	function create() {
		renderText("Create ran.");
	}

	function update() {
		renderText("Update ran.");
	}

	function delete() {
		renderText("Delete ran.");
	}

}
