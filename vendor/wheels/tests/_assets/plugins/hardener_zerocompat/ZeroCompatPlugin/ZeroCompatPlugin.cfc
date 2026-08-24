/**
 * Hardener S3: this.version = "0.0.0" is not a declared compat list.
 * loadIncompatiblePlugins stays true.
 */
component {
	function init() {
		this.version = "0.0.0";
		return this;
	}

	public string function $zeroCompatProbe() {
		return "should-not-load";
	}
}
