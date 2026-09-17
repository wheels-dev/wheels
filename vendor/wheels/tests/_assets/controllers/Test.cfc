component extends="Controller" {

	function config() {
		provides("html,xml,json,xls");
	}

	function test() {
		variableForView = "variableForViewContent";
		variableForLayout = "variableForLayoutContent";
	}

	function testResolved() {
		// Named `resolved` on purpose: $includeAndReturnOutput used to declare a
		// bare `local.resolved`, which shadowed this variable in the view (#3518).
		resolved = {foo = "bar"};
	}

	function testRedirect() {
		redirectTo(action = "dummy");
		request.setInActionAfterRedirect = true;
		renderView(action = "test");
	}

	private struct function $dataForPartial() {
		var data = {};
		data.fruit = "Apple,Banana,Kiwi";
		data.somethingElse = true;
		return data;
	}

	private struct function partialDataImplicitPrivate() {
		return $dataForPartial();
	}

	public struct function partialDataImplicitPublic() {
		return $dataForPartial();
	}

	public struct function partialDataExplicitPublic() {
		var data = $dataForPartial();
		if (StructKeyExists(arguments, "passThrough")) {
			data.passThroughWorked = true;
		}
		return data;
	}

}
