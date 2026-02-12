/**
 * No-op coverage service stub.
 * Wheels disables coverage (enabled=false), so this stub satisfies the interface
 * without pulling in the full coverage system.
 */
component {

	function init(struct options = {}) {
		return this;
	}

	function beginCapture() {}

	function endCapture(boolean resetData = false) {}

	function processCoverage(required any results, required any testbox) {}

}
