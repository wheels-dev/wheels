/**
 * Throwaway helper that evaluates a global-includes `.cfm` file in its OWN
 * component scope and returns the user-defined functions it declares.
 *
 * Used by `Global.cfc::$reincludeGlobals` for the bare `?reload=true`
 * soft-reload (issue #2792). Evaluating the include in a fresh instance per
 * call is what makes re-including an overwritten helper file safe on Adobe CF:
 * including a file that re-declares a function name into a scope that already
 * holds that function throws "Routines cannot be declared more than once". A
 * brand-new instance has a clean scope, so the declaration never collides with
 * the copy already bound to `application.wo`.
 *
 * [section: Internal]
 * [category: Reload]
 */
component output="false" {

	/**
	 * Evaluate `file` and return a struct of the user-defined functions it
	 * declared, keyed by function name.
	 *
	 * @file Mapping-relative path to the `.cfm` to evaluate (e.g. "/app/global/functions.cfm").
	 */
	public struct function loadFunctions(required string file) {
		include "#arguments.file#";

		var fns = {};
		// Lucee adds include-declared functions to `local`; Adobe CF adds them
		// to `variables`. Collect from both. Skip this component's own method.
		for (var localKey in local) {
			if (IsCustomFunction(local[localKey])) {
				fns[localKey] = local[localKey];
			}
		}
		for (var varKey in variables) {
			if (varKey != "loadFunctions" && IsCustomFunction(variables[varKey])) {
				fns[varKey] = variables[varKey];
			}
		}
		return fns;
	}

}
