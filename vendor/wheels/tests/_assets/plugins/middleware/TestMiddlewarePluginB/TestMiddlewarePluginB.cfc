component {

	function init() {
		this.version = "99.9.9";
		return this;
	}

	public void function onPluginLoad(required app) {
		// Register middleware with options
		arguments.app.registerMiddleware(
			"wheels.tests._assets.middleware.TestMiddlewareB",
			{priority: 10}
		);
	}

}
