component extends="wheels.Controller" {

	function config() {
		protectsFromForgery();
	}

	function index() {
		renderText("index");
	}

}
