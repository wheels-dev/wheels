component extends="Controller" {

	function config() {
		filters(through = "denyUnlessAllowed", only = "secret");
		filters(through = "denyCased", only = "casedAction", type = "Before");
	}

	function secret() {
		request.hardenerSecretRan = true;
		renderText("secret-ok");
	}

	function casedAction() {
		request.hardenerCasedRan = true;
		renderText("cased-ok");
	}

	function cachedShow() {
		renderText(request.hardenerCachePayload);
	}

	function cachedRedirect() {
		redirectTo(url = "/hardener-redirect-target", delay = true);
	}

	function noView() {
		// Intentionally empty: $callAction auto-renders and there is no view file.
	}

	public any function explodingLayout() {
		Throw(type = "Wheels.HardenerLayoutError", message = "layout exploded on purpose");
	}

	public any function blankLayout() {
		return "";
	}

	public any function namedLayout() {
		return "hardener_named_layout";
	}

	private function denyUnlessAllowed() {
		request.hardenerDenyRan = true;
		if (!StructKeyExists(request, "hardenerAllow") || !request.hardenerAllow) {
			return false;
		}
	}

	private function denyCased() {
		request.hardenerCasedFilterRan = true;
		return false;
	}

}
