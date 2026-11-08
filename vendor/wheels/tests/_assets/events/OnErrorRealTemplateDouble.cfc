/**
 * EventMethods double for #4688 XSS regression: keeps the REAL
 * `$includeAndReturnOutput` so `wheelserror.cfm` actually renders, while
 * recording headers instead of writing the live test-runner response and
 * no-op'ing the error/email side effects.
 */
component extends="wheels.events.EventMethods" {

	public any function init() {
		this.headerCalls = [];
		this.formatOverride = "html";
		return this;
	}

	public void function $header() {
		var recorded = {};
		for (var key in arguments) {
			recorded[key] = arguments[key];
		}
		ArrayAppend(this.headerCalls, recorded);
	}

	public void function $fireOnErrorCallbacks(required any exception) {
	}

	public void function $restoreTestRunnerApplicationScope() {
	}

	public string function $getRequestFormat() {
		return this.formatOverride;
	}

	// The test-runner request carries Accept: application/json and ?format=json;
	// this double exercises the HTML path, so hide both from the agent-format
	// detector.
	public string function $errorFormatParam() {
		return "";
	}

	public string function $errorAcceptHeader() {
		return "";
	}

	public void function $content() {
	}

	public numeric function $lastStatusCode() {
		var i = ArrayLen(this.headerCalls);
		while (i >= 1) {
			if (StructKeyExists(this.headerCalls[i], "statusCode")) {
				return Val(this.headerCalls[i].statusCode);
			}
			i--;
		}
		return 0;
	}

}
