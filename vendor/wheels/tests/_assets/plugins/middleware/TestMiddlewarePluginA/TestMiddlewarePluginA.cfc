component {

	function init() {
		this.version = "99.9.9";
		return this;
	}

	public void function onPluginLoad(required app) {
		// Register a middleware by CFC path
		arguments.app.registerMiddleware("wheels.tests._assets.middleware.TestMiddlewareA");
	}

}
