/**
 * Hardener B2 fixture: plugin with no this.version and no plugin.json
 * wheelsVersion. Empty compatibility must fail closed even when
 * loadIncompatiblePlugins stays true.
 */
component {

	public any function init() {
		return this;
	}

}
