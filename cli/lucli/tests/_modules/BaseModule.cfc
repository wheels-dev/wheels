/**
 * Test-only stand-in for LuCLI's runtime `modules.BaseModule`.
 *
 * `cli/lucli/Module.cfc` declares `extends="modules.BaseModule"`. At LuCLI
 * runtime that base class is supplied by the LuCLI distribution and resolved
 * through a `/modules` mapping. Inside the framework's OWN TestBox harness
 * (`/wheels/cli/tests`) there is no LuCLI runtime, so any command spec that
 * does `new cli.lucli.Module()` used to fail at load with
 * "invalid component definition, can't find component [modules.BaseModule]".
 * That swallowed bundle error is what issue #2829 / PR #2831 unmasked.
 *
 * This double mirrors the inherited surface Module.cfc relies on. The command
 * methods build and RETURN their output strings (specs assert on the return
 * value, e.g. `var out = mod.deploy()`), so out()/err() are intentionally
 * no-ops and executeCommand() is a no-op — the specs exercise dry-run /
 * buffered paths that never dispatch a real command.
 *
 * Surface kept in sync (by signature, not behaviour) with the real base class:
 * LuCLI `src/main/resources/modules/BaseModule.cfc`.
 */
component {

	function init(
		boolean verboseEnabled = false,
		boolean timingEnabled  = false,
		string cwd             = "",
		any timer,
		struct moduleConfig    = {},
		struct envVars         = {},
		struct secrets         = {},
		struct runtimeContext  = {}
	) {
		variables.verboseEnabled = arguments.verboseEnabled;
		variables.timingEnabled  = arguments.timingEnabled;
		variables.cwd            = arguments.cwd;
		variables.moduleConfig   = arguments.moduleConfig;
		variables.envVars        = arguments.envVars;
		variables.secrets        = arguments.secrets;
		variables.runtimeContext = arguments.runtimeContext;
		variables.timer          = isNull(arguments.timer)
			? { "start": function(){}, "stop": function(){} }
			: arguments.timer;
		return this;
	}

	// Console echo — a no-op in the harness; command methods build and return
	// their own output independently of these.
	private void function out(any message, string colour = "", string style = "") {}
	private void function err(any message) {}

	function getEnv(string envKeyName, string defaultValue = "") {
		if (structKeyExists(variables.envVars, arguments.envKeyName)) {
			return variables.envVars[arguments.envKeyName];
		}
		if (structKeyExists(server, "env") && structKeyExists(server.env, arguments.envKeyName)) {
			return server.env[arguments.envKeyName];
		}
		return arguments.defaultValue;
	}

	function getSecret(string secretName, string defaultValue = "") {
		return structKeyExists(variables.secrets, arguments.secretName)
			? variables.secrets[arguments.secretName]
			: arguments.defaultValue;
	}

	function verbose(any message) {}

	function getAbsolutePath(string cwd, string path) {
		var fileObj    = createObject("java", "java.io.File");
		var targetFile = fileObj.init(arguments.path);
		if (!targetFile.isAbsolute()) {
			targetFile = fileObj.init(arguments.cwd, arguments.path);
		}
		return targetFile.getCanonicalPath();
	}

	public string function executeCommand(required string command, array args = [], string projectDir = "") {
		return "";
	}

	function version() {
		return variables.moduleConfig.version ?: "Version not specified";
	}

	public string function showHelp() {
		return "";
	}
}
