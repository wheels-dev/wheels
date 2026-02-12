<cfscript>
		// Debugging and error settings.
		application.$wheels.showDebugInformation = true;
		application.$wheels.showErrorInformation = true;
		application.$wheels.sendEmailOnError = false;
		application.$wheels.errorEmailSubject = "Error";
		application.$wheels.excludeFromErrorEmail = "";
		application.$wheels.errorEmailToAddress = "";
		application.$wheels.errorEmailFromAddress = "";
		application.$wheels.includeErrorInEmailSubject = true;
		if (Find(".", request.cgi.server_name)) {
			application.$wheels.errorEmailAddress = "webmaster@"
			& Reverse(ListGetAt(Reverse(request.cgi.server_name), 2, "."))
			& "."
			& Reverse(ListGetAt(Reverse(request.cgi.server_name), 1, "."));
		} else {
			application.$wheels.errorEmailAddress = "";
		}
		if (application.$wheels.environment == "production") {
			application.$wheels.showErrorInformation = false;
			application.$wheels.sendEmailOnError = true;
		}
		if (application.$wheels.environment != "development") {
			application.$wheels.showDebugInformation = false;
		}
</cfscript>
