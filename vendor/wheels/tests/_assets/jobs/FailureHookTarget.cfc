/**
 * The app-wide failure hook the hook specs point jobsOnFailure at (core-suite fixture). It keeps
 * the last event it was called with in the application scope.
 */
component {

	public void function record(required struct event) {
		application["$hookSpecGlobal"] = Duplicate(arguments.event);
		if (!StructKeyExists(application, "$hookSpecGlobalCount")) {
			application["$hookSpecGlobalCount"] = 0;
		}
		application["$hookSpecGlobalCount"] = application["$hookSpecGlobalCount"] + 1;
	}

}
