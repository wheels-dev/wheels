// Reports what middleware attached to the request, as seen from a controller action.
component extends="Controller" {

	function show() {
		var seen = {
			hasAuth = StructKeyExists(request, "auth"),
			authSuccess = "",
			principalId = "",
			strategy = "",
			note = ""
		};
		if (seen.hasAuth) {
			seen.authSuccess = request.auth.success;
			seen.principalId = StructKeyExists(request.auth, "principal") && IsStruct(request.auth.principal) && StructKeyExists(request.auth.principal, "id") ? request.auth.principal.id : "";
			seen.strategy = request.auth.strategy ?: "";
		}
		if (StructKeyExists(request.wheels, "middlewareContext") && StructKeyExists(request.wheels.middlewareContext, "note")) {
			seen.note = request.wheels.middlewareContext.note;
		}
		renderText(SerializeJSON(seen));
	}

}
