/**
 * Fixture for the $promoteIncludedGlobalsToThis() memoization specs
 * (issue ##2897 PR C — promote-key set memoized per concrete class).
 *
 * Extends wheels.Global so instantiating it runs Global's pseudo-constructor,
 * which includes /app/global/functions.cfm and then promotes include-injected
 * UDFs from `variables` onto `this`.
 *
 * The private `privateProbe` method covers the open design point from the
 * ##2897 design comment: whether a concrete subclass's private methods are
 * already registered in the shared `variables` scope at the moment Global's
 * pseudo-constructor scan runs is ENGINE-DEPENDENT. The specs therefore never
 * assert a fixed outcome for it — they assert that the memoized path and the
 * fresh-scan path agree, which is the actual invariant. This is also why the
 * memo cache is keyed per concrete class name rather than app-wide.
 */
component extends="wheels.Global" {

	private string function privateProbe() {
		return "private";
	}

	/**
	 * Inject a custom function into `variables` only (NOT `this`) so specs can
	 * exercise the live-scan fallback path post-construction.
	 */
	public void function $injectVariablesFunction(required string functionName, required any fn) {
		variables[arguments.functionName] = arguments.fn;
	}

	public boolean function $hasThisKey(required string keyName) {
		return StructKeyExists(this, arguments.keyName);
	}

	public boolean function $hasVariablesKey(required string keyName) {
		return StructKeyExists(variables, arguments.keyName);
	}

}
