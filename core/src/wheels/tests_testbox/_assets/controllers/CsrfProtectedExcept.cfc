component extends="Controller" {

	function config() {
		protectsFromForgery(except = "show");
	}

	function show() {
		renderText("Show ran.");
	}

	function update() {
		renderText("Update ran.");
	}

}
