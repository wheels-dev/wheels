component extends="wheels.tests.Test" {

	function setup() {
		params = {controller = "dummy", action = "dummy"};
		_controller = controller("dummy", params);
		_controller.before1 = before1;
		_controller.before2 = before2;
		_controller.before3 = before3;
		_controller.after1 = after1;
		_controller.after2 = after2;
	}


	function test_return_correct_type() {
		_controller.filters(through = "before1", type = "before");
		_controller.filters(through = "before2", type = "before");
		_controller.filters(through = "before3", type = "before");
		_controller.filters(through = "after1", type = "after");
		_controller.filters(through = "after2", type = "after");

		before = _controller.filterChain("before");
		after = _controller.filterChain("after");
		all = _controller.filterChain();

		assert('ArrayLen(before) eq 3');
		assert('before[1].through eq "before1"');
		assert('before[2].through eq "before2"');
		assert('before[3].through eq "before3"');

		assert('ArrayLen(after) eq 2');
		assert('after[1].through eq "after1"');
		assert('after[2].through eq "after2"');

		assert('ArrayLen(all) eq 5');
	}

	function before1() {
		return "before1";
	}

	function before2() {
		return "before2";
	}

	function before3() {
		return "before3";
	}

	function after1() {
		return "after1";
	}

	function after2() {
		return "after2";
	}

}
