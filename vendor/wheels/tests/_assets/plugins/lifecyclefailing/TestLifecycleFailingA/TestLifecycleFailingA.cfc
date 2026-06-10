/**
 * Test fixture: legacy plugin whose lifecycle hooks always throw. Sorts
 * before TestLifecycleWorkingB so specs can prove a throwing hook is logged
 * and skipped without aborting the load/activate chain for sibling plugins.
 */
component {

	function init() {
		this.version = "99.9.9";
		return this;
	}

	public void function onPluginLoad(required app) {
		Throw(type = "Tests.PluginOnLoadBoom", message = "plugin onPluginLoad failure fixture");
	}

	public void function onPluginActivate(required app) {
		Throw(type = "Tests.PluginOnActivateBoom", message = "plugin onPluginActivate failure fixture");
	}

}
