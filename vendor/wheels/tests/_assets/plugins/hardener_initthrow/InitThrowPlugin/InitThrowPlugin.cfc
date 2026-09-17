/**
 * Hardener S10: init() throws. Sibling plugins must still load.
 */
component {
	function init() {
		Throw(type = "Tests.HardenerInitBoom", message = "plugin init() failure fixture");
	}
}
