<cfscript>
		// Debugging and error settings.
		// Derived from the environment up front, before anything below can throw:
		// a startup failure's minimal error page reads showErrorInformation, so
		// it must never be briefly true in production (issue ##3671).
		application.$wheels.showDebugInformation = application.$wheels.environment == "development";
		application.$wheels.showErrorInformation = application.$wheels.environment != "production";
		application.$wheels.sendEmailOnError = false;
		application.$wheels.errorEmailSubject = "Error";
		application.$wheels.excludeFromErrorEmail = "";
		application.$wheels.errorEmailToAddress = "";
		application.$wheels.errorEmailFromAddress = "";
		application.$wheels.includeErrorInEmailSubject = true;
		// ListLen, not Find: a Host such as "example." has a dot but one label.
		if (ListLen(request.cgi.server_name, ".") >= 2) {
			application.$wheels.errorEmailAddress = "webmaster@"
			& Reverse(ListGetAt(Reverse(request.cgi.server_name), 2, "."))
			& "."
			& Reverse(ListGetAt(Reverse(request.cgi.server_name), 1, "."));
		} else {
			application.$wheels.errorEmailAddress = "";
		}
		// Error lifecycle hooks — callbacks invoked when an error occurs.
		// Packages and app code can register via registerOnError(callback).
		application.$wheels.onErrorCallbacks = [];
		if (application.$wheels.environment == "production") {
			application.$wheels.sendEmailOnError = true;
		}
</cfscript>
