component {
	/**
	 * The decoy: a second root CFC. Before the entry-point fix this fixture was
	 * a coin flip — DirectoryList returned CFCs in filesystem order, and the
	 * loader took the FIRST one regardless of what it was.
	 */
	public any function init() {
		this.version = "1.0.0";
		return this;
	}

	public string function $entryMarker() {
		return "maindeclared-DECOY";
	}
}
