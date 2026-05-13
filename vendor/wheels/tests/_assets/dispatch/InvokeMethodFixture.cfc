/**
 * Fixture for engineAdapter.invokeMethod() receiver-context tests.
 *
 * Mirrors the Public.cfc shape that triggered issue #2646 on BoxLang:
 * a public handler that calls an internal $-prefixed helper on the same
 * component. The bug manifests when the dispatcher invokes the handler
 * in a way that loses the component receiver — the in-component call to
 * the helper then fails with "Function [$privateHelper] not found".
 */
component {

	variables.state = {helperCalled: false, handlerCompleted: false};

	public any function $init() {
		return this;
	}

	/**
	 * Internal helper prefixed with $ — matches the Public.cfc pattern
	 * ($blockInProduction, $loadRegistryPackages, etc).
	 */
	public void function $privateHelper() {
		variables.state.helperCalled = true;
	}

	/**
	 * Public handler that calls an internal helper first. This is the
	 * exact shape of every Public.cfc handler reachable through
	 * /wheels/info, /wheels/routes, etc.
	 */
	public void function publicHandler() {
		$privateHelper();
		variables.state.handlerCompleted = true;
	}

	public struct function getState() {
		return variables.state;
	}

	public void function resetState() {
		variables.state = {helperCalled: false, handlerCompleted: false};
	}

}
