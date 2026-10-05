/**
 * A post whose delete and save callbacks log to request.$depLog, for dependentCallbacksSpec.
 */
component extends="Model" {

	function config() {
		table("c_o_r_e_posts");
		beforeDelete("logDelete");
		beforeSave("logSave");
	}

	function logDelete() {
		$logDependentCallback("delete");
		return true;
	}

	function logSave() {
		$logDependentCallback("save");
		return true;
	}

	function $logDependentCallback(required string event) {
		if (!StructKeyExists(request, "$depLog")) {
			request.$depLog = [];
		}
		ArrayAppend(request.$depLog, arguments.event);
	}

}
