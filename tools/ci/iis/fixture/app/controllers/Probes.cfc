// IIS test job fixture (tools/ci/iis): plain-text actions the checks can match exactly.
component extends="Controller" {

	function hello() {
		renderText("probe:hello");
	}

	function nested() {
		renderText("probe:nested:#params.id#:#params.itemId#");
	}

}
