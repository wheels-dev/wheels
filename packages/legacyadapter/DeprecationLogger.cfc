/**
 * Centralized deprecation logging for the Wheels legacy adapter.
 *
 * Tracks deprecated API usage with configurable severity levels.
 * Deduplicates warnings per-request to avoid log spam.
 *
 * Modes:
 *   silent — no output (adapter installed but quiet)
 *   log    — WriteLog only (default)
 *   warn   — WriteLog + stores in request scope for debug panel
 *   error  — throws an exception (use during Stage 3 to find stragglers)
 */
component output="false" {

	/**
	 * Initialize the deprecation logger.
	 *
	 * @mode Logging mode: silent, log, warn, or error
	 */
	public any function init(string mode = "log") {
		variables.mode = arguments.mode;
		return this;
	}

	/**
	 * Returns the current logging mode.
	 */
	public string function getMode() {
		return variables.mode;
	}

	/**
	 * Sets the logging mode at runtime.
	 *
	 * @mode Logging mode: silent, log, warn, or error
	 */
	public void function setMode(required string mode) {
		if (!ListFindNoCase("silent,log,warn,error", arguments.mode)) {
			Throw(
				type = "Wheels.LegacyAdapter.InvalidMode",
				message = "Invalid deprecation logger mode: '#arguments.mode#'. Valid modes: silent, log, warn, error."
			);
		}
		variables.mode = arguments.mode;
	}

	/**
	 * Log a deprecation warning.
	 *
	 * @oldMethod The deprecated method or pattern name
	 * @newMethod The replacement method or pattern
	 * @message Additional migration guidance
	 */
	public void function logDeprecation(
		required string oldMethod,
		required string newMethod,
		string message = ""
	) {
		if (variables.mode == "silent") {
			return;
		}

		var key = arguments.oldMethod & "->" & arguments.newMethod;

		/* deduplicate within the current request */
		$ensureRequestScope();
		if (StructKeyExists(request.wheels.deprecations.seen, key)) {
			return;
		}
		request.wheels.deprecations.seen[key] = true;

		var logText = "[Wheels Legacy Adapter] '#arguments.oldMethod#' is deprecated. Use '#arguments.newMethod#' instead.";
		if (Len(arguments.message)) {
			logText = logText & " " & arguments.message;
		}

		/* record for debug panel */
		var entry = {
			oldMethod: arguments.oldMethod,
			newMethod: arguments.newMethod,
			message: arguments.message,
			timestamp: Now()
		};
		ArrayAppend(request.wheels.deprecations.entries, entry);

		if (variables.mode == "error") {
			Throw(
				type = "Wheels.LegacyAdapter.DeprecatedAPI",
				message = logText
			);
		}

		WriteLog(type = "warning", text = logText);
	}

	/**
	 * Returns all deprecation entries logged in the current request.
	 */
	public array function getRequestDeprecations() {
		$ensureRequestScope();
		return request.wheels.deprecations.entries;
	}

	/**
	 * Returns the count of unique deprecations logged in the current request.
	 */
	public numeric function getRequestDeprecationCount() {
		$ensureRequestScope();
		return ArrayLen(request.wheels.deprecations.entries);
	}

	/**
	 * Resets the per-request deprecation tracking.
	 */
	public void function resetRequestDeprecations() {
		request.wheels.deprecations = {seen: {}, entries: []};
	}

	/**
	 * Ensures the request-scope struct exists for deprecation tracking.
	 */
	public void function $ensureRequestScope() {
		if (!StructKeyExists(request, "wheels")) {
			request.wheels = {};
		}
		if (!StructKeyExists(request.wheels, "deprecations")) {
			request.wheels.deprecations = {seen: {}, entries: []};
		}
	}

}
