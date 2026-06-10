/**
 * Test fixture: healthy legacy plugin that records each lifecycle hook into
 * application.$wheelstestLifecycleFailingLog. Sorted AFTER
 * FailingLifecyclePlugin alphabetically — specs assert that this plugin's
 * hooks still fire even after the sibling's onPluginLoad / onPluginActivate
 * threw.
 */
component {

	function init() {
		this.version = "99.9.9";
		return this;
	}

	public void function onPluginLoad(required app) {
		if (!StructKeyExists(arguments.app, "$wheelstestLifecycleFailingLog")) {
			arguments.app.$wheelstestLifecycleFailingLog = [];
		}
		ArrayAppend(arguments.app.$wheelstestLifecycleFailingLog, "Working:onPluginLoad");
	}

	public void function onPluginActivate(required app) {
		if (!StructKeyExists(arguments.app, "$wheelstestLifecycleFailingLog")) {
			arguments.app.$wheelstestLifecycleFailingLog = [];
		}
		ArrayAppend(arguments.app.$wheelstestLifecycleFailingLog, "Working:onPluginActivate");
	}

}
