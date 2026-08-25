/**
 * Test service that records onDIcomplete() invocations so specs can prove
 * the hook ran once, on the constructed instance, and not a second time.
 */
component {

	public any function init() {
		variables.initialized = true;
		variables.completeCount = 0;
		return this;
	}

	public void function onDIcomplete() {
		variables.completeCount = variables.completeCount + 1;
		if (!structKeyExists(request, "$wheelsDICompleteLog")) {
			request.$wheelsDICompleteLog = [];
		}
		arrayAppend(request.$wheelsDICompleteLog, this);
	}

	public numeric function getCompleteCount() {
		return variables.completeCount;
	}

	public boolean function isInitialized() {
		return variables.initialized ?: false;
	}

}
