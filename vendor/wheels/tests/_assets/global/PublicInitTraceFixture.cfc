/**
 * Order-trace fixture for Public.$init's include-then-promote contract.
 *
 * Extends wheels.Public and records when `$includePublicHelpers` starts,
 * when it returns, and when `$scanAndPromoteIncludedGlobals` runs. Specs
 * reset the trace after construction (Global's pseudo-constructor also
 * calls the promote scan) and then invoke `$init`.
 *
 * On the 4.0.6 nest (`include` + promote in the same `$init` body) the
 * include helper is never called, so the trace is only `promote`. After
 * the include is extracted, the trace is include-start, include-return,
 * promote — prove the scan runs after the include method returns.
 */
component extends="wheels.Public" {

	public void function $resetInitTrace() {
		variables.$initTrace = [];
	}

	public array function $getInitTrace() {
		if (!StructKeyExists(variables, "$initTrace") || !IsArray(variables.$initTrace)) {
			return [];
		}
		return variables.$initTrace;
	}

	public void function $includePublicHelpers() {
		if (!StructKeyExists(variables, "$initTrace") || !IsArray(variables.$initTrace)) {
			variables.$initTrace = [];
		}
		ArrayAppend(variables.$initTrace, "include-start");
		super.$includePublicHelpers();
		ArrayAppend(variables.$initTrace, "include-return");
	}

	public array function $scanAndPromoteIncludedGlobals() {
		if (!StructKeyExists(variables, "$initTrace") || !IsArray(variables.$initTrace)) {
			variables.$initTrace = [];
		}
		ArrayAppend(variables.$initTrace, "promote");
		return super.$scanAndPromoteIncludedGlobals();
	}

}
