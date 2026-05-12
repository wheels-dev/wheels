component {

	function init() {
		this.version = "99.9.9";
		return this;
	}

	public void function onPluginLoad(required app) {
		if (!StructKeyExists(arguments.app, "$wheelstestLifecycleLog")) {
			arguments.app.$wheelstestLifecycleLog = [];
		}
		ArrayAppend(arguments.app.$wheelstestLifecycleLog, "B:onPluginLoad");
	}

	public void function onPluginActivate(required app) {
		if (!StructKeyExists(arguments.app, "$wheelstestLifecycleLog")) {
			arguments.app.$wheelstestLifecycleLog = [];
		}
		ArrayAppend(arguments.app.$wheelstestLifecycleLog, "B:onPluginActivate");
	}

	public string function $LifecycleTestMethodB() mixin="model" {
		return "fromB";
	}

}
