/**
 * A post whose delete and save callbacks log to request.$depLog, for dependentCallbacksSpec.
 */
component extends="Model" {

	function config() {
		table("c_o_r_e_posts");
		beforeDelete("logDelete");
		beforeSave("logSave");
		afterFind("logFind");
		afterRollback("logRollback");
	}

	function logFind() {
		$logDependentCallback("find");
		return true;
	}

	function logRollback() {
		$logDependentCallback("rollback");
		return true;
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
