/**
 * Test fixture: healthy legacy plugin loaded after TestLifecycleFailingA.
 * Logs its lifecycle hook invocations so specs can prove the failing
 * sibling did not abort the chain.
 */
component {

	function init() {
		this.version = "99.9.9";
		return this;
	}

	public void function onPluginLoad(required app) {
		if (!StructKeyExists(arguments.app, "$wheelstestLifecycleLog")) {
			arguments.app.$wheelstestLifecycleLog = [];
		}
		ArrayAppend(arguments.app.$wheelstestLifecycleLog, "B:onPluginLoad");
	}

	public void function onPluginActivate(required app) {
		if (!StructKeyExists(arguments.app, "$wheelstestLifecycleLog")) {
			arguments.app.$wheelstestLifecycleLog = [];
		}
		ArrayAppend(arguments.app.$wheelstestLifecycleLog, "B:onPluginActivate");
	}

}
