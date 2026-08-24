/**
 * Hardener S3: this.version = "*" is not a declared compat list.
 * loadIncompatiblePlugins stays true.
 */
component {
	function init() {
		this.version = "*";
		return this;
	}

	public string function $starCompatProbe() {
		return "should-not-load";
	}
}
