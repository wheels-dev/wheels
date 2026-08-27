/**
 * Test double for events hardener S2 / S3 / S4.
 *
 * Extends the real EventMethods so `$runOnError` executes the genuine
 * status map, `$mail` swallow, and JSON/XML serialization, while:
 * - `$header` records status/content-type instead of writing the live
 *   test-runner response (a leaked 500 would look like a suite failure)
 * - `$mail` records the call and can be told to throw
 * - `$fireOnErrorCallbacks` / `$restoreTestRunnerApplicationScope` /
 *   `$includeAndReturnOutput` are no-op'd so the spec only exercises
 *   the error-response contract
 */
component extends="wheels.events.EventMethods" {

	public any function init() {
		this.headerCalls = [];
		this.mailCalls = 0;
		this.mailShouldThrow = false;
		this.formatOverride = "json";
		return this;
	}

	public void function $header() {
		var recorded = {};
		for (var key in arguments) {
			recorded[key] = arguments[key];
		}
		ArrayAppend(this.headerCalls, recorded);
	}

	public void function $mail() {
		this.mailCalls = this.mailCalls + 1;
		if (this.mailShouldThrow) {
			throw(type = "UnitTest.MailFailure", message = "forced mail failure");
		}
	}

	public void function $fireOnErrorCallbacks(required any exception) {
	}

	public void function $restoreTestRunnerApplicationScope() {
	}

	public string function $getRequestFormat() {
		return this.formatOverride;
	}

	public string function $includeAndReturnOutput() {
		return "on-error-double-body";
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
