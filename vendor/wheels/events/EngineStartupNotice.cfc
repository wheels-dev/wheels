/**
 * Recognizes an engine notice that reaches Application.cfc onError() before
 * the application starts but does not stop the request (#3726).
 *
 * Adobe ColdFusion 2025 without its optional graphqlclient package reports
 * "The graphqlclient package is not installed." while it applies an
 * application's datasource declarations (ApplicationSettings.loadAppDatasources
 * calls ServiceFactory.getGraphQLClientService). It invokes onError() with
 * that notice and then carries on starting the application and serving the
 * request, so rendering it as an error page turns a working first request
 * into an HTTP 500.
 *
 * isBenign() matches that exact signature and nothing else: an empty event
 * name (before the application starts), type "Application", the exact English
 * message, and both Java frames in the stack. A different message (including
 * a localized one), type or event name, or a missing frame is a real error
 * and is rendered as usual.
 *
 * Deliberately standalone (no wheels.Global): it runs before application.wo
 * exists, and it never throws.
 */
component output=false {

	variables.message = "The graphqlclient package is not installed.";
	variables.frames = [
		"coldfusion.runtime.ApplicationSettings.loadAppDatasources",
		"ServiceFactory.getGraphQLClientService"
	];

	public boolean function isBenign(required any exception, string eventName = "") {
		try {
			if (Len(Trim(arguments.eventName))) {
				return false;
			}
			if (CompareNoCase($field(arguments.exception, "Type"), "Application") != 0) {
				return false;
			}
			if (Compare($field(arguments.exception, "Message"), variables.message) != 0) {
				return false;
			}
			local.stack = $field(arguments.exception, "StackTrace");
			for (local.frame in variables.frames) {
				if (!Find(local.frame, local.stack)) {
					return false;
				}
			}
			return true;
		} catch (any e) {
			return false;
		}
	}

	/**
	 * Record the notice once, where an operator will look, instead of
	 * rendering it.
	 */
	public void function record() {
		try {
			WriteLog(
				file = "wheels",
				type = "information",
				text = "Adobe ColdFusion reported '#variables.message#' while applying the application's datasources. It is an optional engine package and does not affect Wheels; the request continues. Install it with the ColdFusion package manager (cfpm install graphqlclient) to silence this notice (##3726)."
			);
		} catch (any e) {
			// Logging must never break error handling.
		}
	}

	/** A simple field of the exception, or "" when absent or not simple. */
	public string function $field(required any exception, required string key) {
		try {
			if (StructKeyExists(arguments.exception, arguments.key)) {
				local.value = arguments.exception[arguments.key];
				if (IsSimpleValue(local.value)) {
					return ToString(local.value);
				}
			}
		} catch (any e) {
			// Not struct-like: no such field.
		}
		return "";
	}

}
