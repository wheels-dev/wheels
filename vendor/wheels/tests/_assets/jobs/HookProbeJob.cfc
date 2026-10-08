/**
 * A job with every lifecycle hook (core-suite fixture). Each hook appends to a list in the
 * application scope so the hook specs can check what ran, in what order, with what.
 * data.mode picks what perform() does: "text" (default), "struct", "void", "long" or "fail".
 */
component extends="wheels.Job" {

	function config() {
		super.config();
		this.maxRetries = 1;
	}

	public void function beforePerform(struct data = {}) {
		$note("before");
		if (StructKeyExists(arguments.data, "failBefore") && arguments.data.failBefore) {
			throw(type = "Spec.BeforeFailure", message = "before failed");
		}
	}

	public any function perform(struct data = {}) {
		$note("perform");
		local.mode = StructKeyExists(arguments.data, "mode") ? arguments.data.mode : "text";
		if (local.mode == "fail") {
			throw(type = "Spec.HookFailure", message = "perform failed", detail = "spec detail");
		}
		if (local.mode == "struct") {
			return {count = 2, ok = true};
		}
		if (local.mode == "long") {
			return RepeatString("x", 5000);
		}
		if (local.mode == "void") {
			return;
		}
		return "done";
	}

	public void function afterPerform(struct data = {}, any result) {
		$note("after");
	}

	public void function onSuccess(any result) {
		if (IsNull(arguments.result)) {
			$note("success:none");
		} else if (IsSimpleValue(arguments.result)) {
			$note("success:" & Left(arguments.result, 10));
		} else {
			$note("success:complex");
		}
		if (StructKeyExists(application, "$hookSpecSuccessThrows") && application["$hookSpecSuccessThrows"]) {
			throw(type = "Spec.SuccessHookFailure", message = "onSuccess failed");
		}
	}

	public void function onFailure(struct error, numeric attempt, boolean isFinal) {
		local.finalText = arguments.isFinal ? "true" : "false";
		$note("failure:#arguments.attempt#:#local.finalText#:#arguments.error.type#");
	}

	private void function $note(required string entry) {
		if (!StructKeyExists(application, "$hookSpecLog")) {
			application["$hookSpecLog"] = "";
		}
		application["$hookSpecLog"] = ListAppend(application["$hookSpecLog"], arguments.entry, "|");
	}

}
