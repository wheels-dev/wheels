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
		if (!StructKeyExists(application, "$wheelstestLifecycleLog")) {
			application.$wheelstestLifecycleLog = [];
		}
		ArrayAppend(application.$wheelstestLifecycleLog, "B:onPluginLoad");
	}

	public void function onPluginActivate(required app) {
		if (!StructKeyExists(application, "$wheelstestLifecycleLog")) {
			application.$wheelstestLifecycleLog = [];
		}
		ArrayAppend(application.$wheelstestLifecycleLog, "B:onPluginActivate");
	}

}
