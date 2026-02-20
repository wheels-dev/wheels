component extends="wheels.tests.Test" {

	function setup() {
		_controller = controller(name = "ControllerWithModelErrors");
		args = {};
		args.objectName = "user";
		args.class = "errors-found";
	}

	function test_all_options_supplied() {
		args.property = "firstname";
		args.prependText = "prepend ";
		args.appendText = " append";
		args.wrapperElement = "div";
		e = _controller.errorMessageOn(argumentcollection = args);
		r = '<div class="errors-found">prepend firstname error1 append</div>';
		assert("e eq r");
	}

}
