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
