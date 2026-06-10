/**
 * Test fixture: legacy plugin whose onPluginLoad() and onPluginActivate()
 * lifecycle hooks both throw. Used by pluginsLifecycleIsolationSpec to prove
 * a broken legacy plugin is logged and skipped without aborting the
 * lifecycle for sibling plugins (mirrors the ServiceProvider isolation
 * landed in #2912).
 *
 * Alphabetical sort places this plugin BEFORE WorkingLifecyclePlugin, so
 * the failure happens before the sibling's hook would otherwise run.
 */
component {

	function init() {
		this.version = "99.9.9";
		return this;
	}

	public void function onPluginLoad(required app) {
		Throw(type = "Tests.PluginLoadBoom", message = "legacy plugin onPluginLoad() failure fixture");
	}

	public void function onPluginActivate(required app) {
		Throw(type = "Tests.PluginActivateBoom", message = "legacy plugin onPluginActivate() failure fixture");
	}

}
