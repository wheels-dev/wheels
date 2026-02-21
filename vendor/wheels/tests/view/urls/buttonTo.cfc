component extends="wheels.tests.Test" {

	function setup() {
		_controller = controller(name = "dummy");
		oldURLRewriting = application.wheels.URLRewriting;
		application.wheels.URLRewriting = "On";
		oldScriptName = request.cgi.script_name;
		request.cgi.script_name = "/index.cfm";
		set(functionName = "buttonTo", encode = false);
		if(structKeyExists(request, "$wheelsProtectedFromForgery")){
		$oldrequestfromforgery = request.$wheelsProtectedFromForgery;
		}
		request.$wheelsProtectedFromForgery = true;
	}

	function teardown() {
		application.wheels.URLRewriting = oldURLRewriting;
		request.cgi.script_name = oldScriptName;
		set(functionName = "buttonTo", encode = true);
		if(structKeyExists(variables, "$oldrequestfromforgery")){
		request.$wheelsProtectedFromForgery = $oldrequestfromforgery;
		}
	}

	function test_buttonto_inner_encoding() {
		actual = _controller.buttonTo(
			text = "<Click>",
			class = "form-class",
			inputClass = "input class",
			confirm = "confirm-value",
			disable = "disable-value",
			encode = true
		);
		expected = '<form action="#application.wheels.webpath#" class="form-class" confirm="confirm-value" disable="disable-value" method="post"><button class="input&##x20;class" type="submit" value="save">' & '&lt;Click&gt;' & '</button>' & _controller.authenticityTokenField() & '</form>';
		assert('actual eq expected');
	}

	function test_buttonto_inner_icon() {
		actual = _controller.buttonTo(
			text = "<i class='fa fa-icon' /> Edit",
			class = "form-class",
			inputClass = "input class",
			confirm = "confirm-value",
			disable = "disable-value",
			encode = 'attributes',
			value = "customvalue"
		);
		expected = '<form action="#application.wheels.webpath#" class="form-class" confirm="confirm-value" disable="disable-value" method="post" value="customvalue"><button class="input&##x20;class" type="submit" value="save">' & '<i class=''fa fa-icon'' /> Edit' & '</button>' & _controller.authenticityTokenField() & '</form>';
		assert('actual eq expected');
	}

	function test_buttonto_attributes() {
		actual = _controller.buttonTo(
			class = "form-class",
			inputClass = "input-class",
			confirm = "confirm-value",
			disable = "disable-value"
		);
		expected = '<form action="#application.wheels.webpath#" class="form-class" confirm="confirm-value" disable="disable-value" method="post"><button class="input-class" type="submit" value="save">' & '</button>' & _controller.authenticityTokenField() & '</form>';
		assert('actual eq expected');
	}

	function test_buttonto_with_delete_method_argument() {
		actual = _controller.buttonTo(method = "delete");
		expected = '<form action="#application.wheels.webpath#" method="post"><input id="_method" name="_method" type="hidden" value="delete"><button type="submit" value="save">' & '</button>' & _controller.authenticityTokenField() & '</form>';
		assert('actual eq expected');
	}

	function test_buttonto_with_put_method_argument() {
		actual = _controller.buttonTo(method = "put");
		expected = '<form action="#application.wheels.webpath#" method="post"><input id="_method" name="_method" type="hidden" value="put"><button type="submit" value="save">' & '</button>' & _controller.authenticityTokenField() & '</form>';
		assert('actual eq expected');
	}

	// why one would do this I don't know.. but this is how it should render
	function test_buttonto_with_get_method_argument() {
		actual = _controller.buttonTo(method = "get");
		expected = '<form action="#application.wheels.webpath#" method="get"><button type="submit" value="save"></button></form>';
		assert('actual eq expected');
	}

}
