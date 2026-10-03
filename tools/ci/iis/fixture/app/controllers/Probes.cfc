// IIS test job fixture (tools/ci/iis): plain-text actions the checks can match exactly.
component extends="Controller" {

	function hello() {
		renderText("probe:hello");
	}

	// What Wheels sees on this stack, printed in the job log.
	function diag() {
		var info = {
			scriptName = cgi.script_name,
			pathInfo = cgi.path_info,
			requestUri = StructKeyExists(cgi, "request_uri") ? cgi.request_uri : "",
			requestCgiPathInfo = request.cgi.path_info,
			webPath = application.wheels.webPath,
			subpath = StructKeyExists(application.wheels, "subpath") ? application.wheels.subpath : ""
		};
		renderText(SerializeJSON(info));
	}

	function nested() {
		renderText("probe:nested:#params.id#:#params.itemId#");
	}

}
