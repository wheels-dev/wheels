/**
 * Module whose new() records the collection it receives instead of
 * scaffolding a project, so specs can check what `generate app` forwards to
 * `wheels new` without writing an app to disk.
 */
component extends="cli.lucli.Module" {

	public string function new() {
		variables.capturedNewArgs = structuredArgs(arguments);
		variables.offlineInsideNew = $isOffline();
		return "";
	}

	public struct function capturedNewArgs() {
		return variables.capturedNewArgs ?: {};
	}

	public boolean function wasOfflineInsideNew() {
		return variables.offlineInsideNew ?: false;
	}

}
