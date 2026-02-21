component extends="wheels.tests.Test" {

	public void function setup() {
		config = {path = "wheels", fileName = "Mapper", method = "$init"};
		_params = {controller = "test", action = "index"};
		_originalRoutes = Duplicate(application.wheels.routes);
	}

	public void function teardown() {
		application.wheels.routes = _originalRoutes;
	}

	public struct function $mapper() {
		local.args = Duplicate(config);
		StructAppend(local.args, arguments, true);
		return $createObjectFromRoot(argumentCollection = local.args);
	}

	public struct function $inspect() {
		return variables;
	}

	public void function $clearRoutes() {
		application.wheels.routes = [];
	}

	// draw

	function test_draw_defaults() {
		mapper = $mapper().$draw();
		mapper.inspect = $inspect;
		mapperVarScope = mapper.inspect();
		assert('mapperVarScope.restful eq true AND mapperVarScope.methods eq true');
	}

	function test_draw_restful_false() {
		mapper = $mapper(restful = false).$draw(restful = false);
		mapper.inspect = $inspect;
		mapperVarScope = mapper.inspect();
		assert('mapperVarScope.restful eq false AND mapperVarScope.methods eq false');
	}

	function test_draw_restful_false_methods_true() {
		mapper = $mapper(restful = false, methods = true).$draw(restful = false, methods = true);
		mapper.inspect = $inspect;
		mapperVarScope = mapper.inspect();
		assert('mapperVarScope.restful eq false AND mapperVarScope.methods eq true');
	}

	function test_draw_mapFormat_false() {
		mapper = $mapper(mapFormat = false).$draw();
		mapper.inspect = $inspect;
		mapperVarScope = mapper.inspect();
		assert('mapperVarScope.mapFormat eq false');
	}

	function test_draw_resets_the_stack() {
		mapper = $mapper().$draw();
		mapper.inspect = $inspect;
		mapperVarScope = mapper.inspect();
		stackLen = ArrayLen(mapperVarScope.scopeStack);
		assert('stackLen eq 1');
	}

	function test_end_removes_top_of_stack() {
		mapper = $mapper().$draw();
		mapper.inspect = $inspect;
		drawVarScope = mapper.inspect();
		drawLen = ArrayLen(drawVarScope.scopeStack);
		mapper.end();
		endVarScope = mapper.inspect();
		endLen = ArrayLen(endVarScope.scopeStack);
		assert('drawLen eq 1 and endLen eq 0');
	}

}
