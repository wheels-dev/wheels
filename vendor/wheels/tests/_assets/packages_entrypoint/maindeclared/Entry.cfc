component {
	public any function init() {
		this.version = "1.0.0";
		return this;
	}

	/** Who am I — lets a spec assert WHICH root CFC the loader instantiated. */
	public string function $entryMarker() {
		return "maindeclared-entry";
	}
}
