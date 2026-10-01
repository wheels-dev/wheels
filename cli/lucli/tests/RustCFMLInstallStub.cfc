/**
 * A RustCFMLEngine whose download never touches the network: the `curl` call
 * install() makes through $runSync() writes `payload` to its `-o` path (and
 * exits with `curlExit`). The wheels home is a temp dir, the asset is fixed,
 * and the asset's sha256 pin is `pin` (none when blank), so specs can drive
 * install() through a matching, mismatched, failed or skipped download.
 */
component extends="cli.lucli.services.rustcfml.RustCFMLEngine" {

	public any function init(
		required string wheelsHome,
		string asset = "rustcfml-linux-x86_64",
		string payload = "",
		string pin = "",
		numeric curlExit = 0
	) {
		variables.wheelsHome = arguments.wheelsHome;
		variables.stubAsset = arguments.asset;
		variables.stubPayload = arguments.payload;
		variables.stubCurlExit = arguments.curlExit;
		variables.stubCalls = [];
		if (!structKeyExists(variables, "engineSha256")) variables.engineSha256 = {};
		structDelete(variables.engineSha256, arguments.asset);
		if (len(arguments.pin)) variables.engineSha256[arguments.asset] = arguments.pin;
		return this;
	}

	public string function assetName() {
		return variables.stubAsset;
	}

	public numeric function $runSync(required array cmdArgs) {
		arrayAppend(variables.stubCalls, arguments.cmdArgs);
		if (arguments.cmdArgs[1] == "curl") {
			var outAt = arrayFind(arguments.cmdArgs, "-o");
			if (outAt > 0 && len(variables.stubPayload)) {
				fileWrite(arguments.cmdArgs[outAt + 1], variables.stubPayload);
			}
			return variables.stubCurlExit;
		}
		return 0;
	}

	/** Every download (curl) command install() ran. */
	public array function downloads() {
		var found = [];
		for (var cmd in variables.stubCalls) {
			if (cmd[1] == "curl") arrayAppend(found, cmd);
		}
		return found;
	}

	/** Absolute path of the pinned binary install() manages. */
	public string function binPath() {
		return variables.wheelsHome & "/rustcfml/bin/rustcfml-" & getEngineVersion();
	}

}
