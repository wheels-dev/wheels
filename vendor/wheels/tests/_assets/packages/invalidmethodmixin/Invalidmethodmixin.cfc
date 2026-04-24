component {
	public any function init() {
		this.version = "1.0.0";
		return this;
	}

	// Valid target, follows the manifest default
	public string function $validHelper() {
		return "valid";
	}

	// Typo in per-method metadata — must cause the package to fail to load
	public string function $badTarget() mixin="controler" {
		return "should-never-be-injected";
	}
}
