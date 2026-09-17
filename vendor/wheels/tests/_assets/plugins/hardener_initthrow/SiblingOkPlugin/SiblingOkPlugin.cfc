/**
 * Hardener S10: healthy sibling after InitThrowPlugin (alphabetical: Init then Sibling).
 */
component {
	function init() {
		this.version = "99.9.9";
		return this;
	}

	public string function $siblingOkProbe() {
		return "sibling-ok";
	}
}
