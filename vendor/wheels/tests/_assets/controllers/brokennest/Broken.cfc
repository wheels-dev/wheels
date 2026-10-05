/**
 * F14 fixture: a NESTED controller that (incorrectly) declares extends="Controller"
 * instead of extends="wheels.tests._assets.controllers.Controller". A bare extends
 * name resolves relative to this file's own package (brokennest/), where no
 * Controller.cfc exists, so instantiation fails — which is exactly the mistake the
 * $missingBaseControllerHint catch-path annotates. Loaded on demand by
 * NestedControllerHintSpec; never compiled by the directory= spec scan.
 */
component extends="Controller" {
	function config() {
		return this;
	}
}
