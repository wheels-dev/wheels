component output="false" {

	// Focused collaborators for the former Global.cfc monolith (issue ##3241).
	// Component-body includes compile into this CFC so every Global-derived
	// type (Model, Controller, Dispatch, …) inherits the helpers with no
	// per-instance mixin copy. Paths are mapping-absolute (`/wheels/...`)
	// because a relative include would resolve against the requesting
	// template, not this file. Each include MUST be wrapped in cfscript
	// tags — an include is tag-context, so bare script would leak as
	// output (same contract as /app/global/functions.cfm).
	include "/wheels/global/locking.cfm";
	include "/wheels/global/tags.cfm";
	include "/wheels/global/settings.cfm";
	include "/wheels/global/cache.cfm";
	include "/wheels/global/objects.cfm";
	include "/wheels/global/routing.cfm";
	include "/wheels/global/strings.cfm";
	include "/wheels/global/request.cfm";
	include "/wheels/global/util.cfm";
	include "/wheels/global/plugins.cfm";
	include "/wheels/global/pagination.cfm";
	include "/wheels/global/cors.cfm";
	include "/wheels/global/lifecycle.cfm";

	// User-defined global functions
	include "/app/global/functions.cfm";

	// Promote include-injected UDFs from `variables` to `this` so they're
	// discoverable via struct-iteration on engines (Adobe CF) where only
	// `this`-scope members are reliably enumerable. Declared methods on
	// Global.cfc are already in `this` via their `access` modifier and are
	// not clobbered by the `structKeyExists(this, ...)` guard. See #2790
	// and the auto-bind loop in `vendor/wheels/WheelsTest.cfc`.
	//
	// Delegated to `$promoteIncludedGlobalsToThis()` so the loop iterator
	// lives in a real function-local scope. Inlining a `local.X` iterator in
	// the pseudo-constructor materializes `variables.local` on the Global
	// instance — harmless on Lucee/Adobe (where `local` is reserved to the
	// function scope) but on BoxLang it shadows the method-local `local` of
	// every mixed-in `$`-helper (Migrator/Model `local.appKey`, …), throwing
	// "The key [...] was not found in the struct. Valid keys are ([VARKEY])".
	$promoteIncludedGlobalsToThis();

}
