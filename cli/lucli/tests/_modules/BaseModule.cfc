// Test double for LuCLI's modules.BaseModule — see #2829 / PR #2831.
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

	void function out(any message, string colour = "", string style = "") {}
	void function err(any message) {}

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
