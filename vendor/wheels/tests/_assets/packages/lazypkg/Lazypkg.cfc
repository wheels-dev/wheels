component {
	public any function init() {
		this.version = "1.0.0";
		this.initialized = true;
		return this;
	}

	public string function $lazypkgHelper() {
		return "lazypkg-works";
	}
}
