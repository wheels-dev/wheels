// Fixture for pluginsSharedInstanceSpec (issue #2897, Stage 3): a Plugins
// subclass that exposes whether $initializeMixins left scratch state behind in
// the instance's own variables scope. Unscoped `$wheels.*` writes land there —
// a data race the moment one instance is shared across concurrent requests
// (the cached application[appKey].PluginObj). The probe shares its parent's
// variables scope, so any unscoped write made by the inherited method is
// observable here.
component extends="wheels.Plugins" {

	public boolean function $hasScratchState() {
		return StructKeyExists(variables, "$wheels");
	}

}
