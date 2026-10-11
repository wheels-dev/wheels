<cfscript>
		// Debugging and error settings.
		// Derived from the environment up front, before anything below can throw:
		// a startup failure's minimal error page reads showErrorInformation, so
		// it must never be briefly true in production (issue ##3671).
		application.$wheels.showDebugInformation = application.$wheels.environment == "development";
		application.$wheels.showErrorInformation = application.$wheels.environment != "production";
		// Unknown arguments to framework declarations (associations, validations, callbacks, ...):
		// "warn" logs them to wheels.log, "throw" raises Wheels.UnknownArgument, "off" ignores them.
		application.$wheels.strictArguments = application.$wheels.environment == "development" ? "warn" : "off";
		application.$wheels.sendEmailOnError = false;
		application.$wheels.errorEmailSubject = "Error";
		application.$wheels.excludeFromErrorEmail = "";
		application.$wheels.errorEmailToAddress = "";
		application.$wheels.errorEmailFromAddress = "";
		application.$wheels.includeErrorInEmailSubject = true;
		// No default recipient. Error emails carry request and session data, so
		// the address must come from configuration, never from the request.
		application.$wheels.errorEmailAddress = "";
		// Error lifecycle hooks — callbacks invoked when an error occurs.
		// Packages and app code can register via registerOnError(callback).
		application.$wheels.onErrorCallbacks = [];
		if (application.$wheels.environment == "production") {
			application.$wheels.sendEmailOnError = true;
		}
</cfscript>
