component extends="wheels.tests.Test" {

	function setup() {
		_controller = controller(name = "dummy");
		args = {};
		args.name = "input";
		args.attributes = {};
		args.attributes.type = "text";
		args.attributes.class = "wheelstest";
		args.attributes.size = "30";
		args.attributes.maxlength = "50";
		args.attributes.name = "inputtest";
		args.attributes.firstname = "tony";
		args.attributes.lastname = "petruzzi";
		args.attributes._firstname = "tony";
		args.attributes._lastname = "petruzzi";
		args.attributes.id = "inputtest";
		args.skip = "firstname,lastname";
		args.skipStartingWith = "_";
		args.attributes.onmouseover = "function(this){this.focus();}";
	}

	function test_with_all_options() {
		e = _controller.$tag(argumentCollection = args);
		r = '<input class="wheelstest" id="inputtest" maxlength="50" name="inputtest" onmouseover="function(this){this.focus();}" size="30" type="text">';
		assert("e eq r");
	}

	function test_passing_through_class() {
		request.wheels.testPaginationLinksQuery = {currentPage = 2, totalPages = 3};
		r = controller("dummy").paginationLinks(classForCurrent = "active", handle = "testPaginationLinksQuery");
		assert(Find("<span class=""active"">2</span>", r));
	}

	function test_addclass_attribute_adds_value_in_class() {
		args.addClass = "newClass";
		e = _controller.$tag(argumentCollection = args);
		r = '<input class="wheelstest newClass" id="inputtest" maxlength="50" name="inputtest" onmouseover="function(this){this.focus();}" size="30" type="text">';
		assert("e eq r");
	}

}
