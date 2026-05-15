component {
	public any function init() {
		this.version = "1.0.0";
		return this;
	}

	public string function $sharedFn() {
		return "from-pkgfirst";
	}
}
