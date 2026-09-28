/**
 * Recognizes an engine notice that reaches Application.cfc onError() before
 * the application starts but does not stop the request (#3726).
 *
 * Adobe ColdFusion 2025 without its optional graphqlclient package reports
 * "The graphqlclient package is not installed." while it applies an
 * application's datasource declarations (ApplicationSettings.loadAppDatasources
 * calls ServiceFactory.getGraphQLClientService). It calls onError() with that
 * notice, with no event name, before onApplicationStart, and then continues
 * the same request: onApplicationStart and onRequest still run. Rendering the
 * notice makes that request an HTTP 500; returning lets it complete.
 *
 * Measured on cold Adobe 2025 starts (healthcheck off, one first request):
 * returning here gives a first 200 only together with the Adobe super-scope
 * primer (wheels.events.SuperScopePrimer, ##3730). Without the primer, the
 * continued request fails in onApplicationStart instead.
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
				text = "Adobe ColdFusion reported '#variables.message#' while applying the application's datasources, before the application started. Wheels does not use that optional package, so the notice was logged instead of rendered as an error. Install it with the ColdFusion package manager (cfpm install graphqlclient) to silence this notice (##3726)."
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
