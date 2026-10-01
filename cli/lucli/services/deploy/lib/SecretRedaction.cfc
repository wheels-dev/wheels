/**
 * Request-scoped registry of resolved secret values and config warnings for
 * one `wheels deploy` invocation. ConfigLoader registers the value of every
 * secret it resolves for a ${VAR} interpolation (and of every ${VAR} used in
 * env.clear); the deploy verbs register their env.secret values. Every
 * dry-run command list, rendered dry-run result and remote-failure message
 * passes through redact() before it is shown.
 */
component {

	variables.mask = "[REDACTED]";

	public SecretRedaction function init() {
		return this;
	}

	/** Called at the start of every `wheels deploy` command. */
	public void function reset() {
		request.$wheelsDeploySecretValues = [];
		request.$wheelsDeployConfigWarnings = [];
		request.$wheelsDeployWarningsShown = [];
	}

	public array function values() {
		return request.$wheelsDeploySecretValues ?: [];
	}

	/**
	 * Remember a resolved value for redaction. Values shorter than 4
	 * characters are not registered: replacing them would shred ordinary
	 * command text (the same floor the #3159 redaction uses).
	 */
	public void function register(required any value) {
		if (!isSimpleValue(arguments.value) || len(arguments.value) < 4) {
			return;
		}
		$ensure();
		if (!arrayFind(request.$wheelsDeploySecretValues, arguments.value)) {
			arrayAppend(request.$wheelsDeploySecretValues, arguments.value);
		}
	}

	public void function addWarning(required string message) {
		$ensure();
		if (!arrayFind(request.$wheelsDeployConfigWarnings, arguments.message)) {
			arrayAppend(request.$wheelsDeployConfigWarnings, arguments.message);
		}
	}

	public array function warnings() {
		return request.$wheelsDeployConfigWarnings ?: [];
	}

	/**
	 * Replace every registered value with [REDACTED], both as written and in
	 * the form shellEscape() puts on a command line (each ' becomes '\'').
	 */
	public string function redact(required string text) {
		var out = arguments.text;
		for (var v in (request.$wheelsDeploySecretValues ?: [])) {
			out = replace(out, v, variables.mask, "all");
			var escaped = replace(v, "'", "'\''", "all");
			if (escaped != v) {
				out = replace(out, escaped, variables.mask, "all");
			}
		}
		return out;
	}

	/**
	 * Final text for a deploy command's result: each config warning not yet
	 * shown in this command, as a "WARNING: ..." line, then the redacted text.
	 */
	public string function render(required string text) {
		$ensure();
		var lines = [];
		for (var w in request.$wheelsDeployConfigWarnings) {
			if (!arrayFind(request.$wheelsDeployWarningsShown, w)) {
				arrayAppend(lines, "WARNING: " & w);
				arrayAppend(request.$wheelsDeployWarningsShown, w);
			}
		}
		var body = redact(arguments.text);
		return arrayLen(lines) ? arrayToList(lines, chr(10)) & chr(10) & body : body;
	}

	public array function redactAll(required array lines) {
		var out = [];
		for (var line in arguments.lines) {
			arrayAppend(out, isSimpleValue(line) ? redact(line) : line);
		}
		return out;
	}

	private void function $ensure() {
		if (!structKeyExists(request, "$wheelsDeploySecretValues")) {
			request.$wheelsDeploySecretValues = [];
		}
		if (!structKeyExists(request, "$wheelsDeployConfigWarnings")) {
			request.$wheelsDeployConfigWarnings = [];
		}
		if (!structKeyExists(request, "$wheelsDeployWarningsShown")) {
			request.$wheelsDeployWarningsShown = [];
		}
	}

}
