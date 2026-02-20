component extends="wheels.tests.Test" {

	function setup() {
		_controller = controller(name = "dummy");
		imagePath = application.wheels.webPath & application.wheels.imagePath;
		set(functionName = "buttonTag", encode = false);
	}

	function teardown() {
		set(functionName = "buttonTag", encode = true);
	}

	function test_defaults() {
		r = _controller.buttonTag();
		e = '<button type="submit" value="save">Save changes</button>';
		assert('e eq r');
	}

	function test_with_icon_as_html() {
		r = _controller.buttonTag(content="<i class='fa fa-icon' /> Edit", encode="attributes");
		e = '<button type="submit" value="save"><i class=''fa fa-icon'' /> Edit</button>';
		assert('e eq r');
	}

	function test_with_image() {
		r = _controller.buttonTag(image = "http://www.cfwheels.com/logo.jpg");
		e = '<button type="submit" value="save"><img alt="Logo" src="http://www.cfwheels.com/logo.jpg" type="image"></button>';
		assert('e eq r');
	}

	function test_with_disable() {
		r = _controller.buttonTag(disable = "disable-value");
		e = '<button disable="disable-value" type="submit" value="save">Save changes</button>';
		assert('e eq r');
	}

	function test_append_prepend() {
		r = _controller.buttonTag(append = "a", prepend = "p");
		e = 'p<button type="submit" value="save">Save changes</button>a';
		assert('e eq r');
	}

}
