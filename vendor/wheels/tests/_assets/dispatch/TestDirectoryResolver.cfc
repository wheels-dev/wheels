/**
 * Helper extracted from app-runner.cfm so the directory-scoping rule is
 * unit-testable without spinning up an HTTP request. app-runner.cfm reads
 * url.directory, hands it to this resolver, and uses the returned dotted
 * path as the TestBox directory mapping.
 *
 * Convention: only accept dotted paths beginning with "tests." so the
 * resolver cannot be tricked into compiling arbitrary CFCs (e.g. by
 * passing `?directory=vendor.wheels.lib`). Empty / whitespace / malformed
 * inputs fall back to the project's `tests.specs` default, matching how
 * the framework's own runner behaves when no scope is requested.
 *
 * The CLI's `$normalizeTestFilter()` is responsible for converting short
 * forms (`models`, `controllers`) into the dotted form this resolver
 * accepts (`tests.specs.models`, `tests.specs.controllers`). If a bare
 * short name reaches here, the regex rejects it and the resolver returns
 * the default — silent fallback is the failure mode this helper exists
 * to make testable.
 *
 * See issue #2489.
 *
 * Scope visibility (issue #3083): `resolveDirectory()` collapses a rejected
 * value to the default with no signal, so a caller driving the URL directly
 * cannot tell "ran the scope I asked for" from "ran the entire suite because
 * my value was rejected." `resolveScope()` returns the same resolution plus
 * the `rejected` flag and the original `requested` value; `scopeWarnings()`
 * turns a rejection (or a 0-bundle discovery) into a human/CI-readable
 * warning; and `injectScopeMetadata()` threads those facts into the JSON
 * payload the runners emit. Both the core runner
 * (`vendor/wheels/tests/runner.cfm`) and the app-test runner
 * (`vendor/wheels/tests/app-runner.cfm`) call these so neither silently
 * reports green for the wrong scope.
 */
component {

	variables.DEFAULT_DIRECTORY = "tests.specs";
	variables.ACCEPTED_PATH_REGEX = "^tests(\.[a-zA-Z0-9_]+)*$";

	public string function resolveDirectory(required struct url) {
		return resolveScope(url = arguments.url).resolved;
	}

	/**
	 * Resolve a requested directory against an allowlist while recording
	 * whether the request was rejected (and silently replaced by the
	 * default). Parameterized by `defaultDirectory` / `allowlistPattern` so
	 * the same logic serves the app runner (`tests.*` default `tests.specs`)
	 * and the core runner (`wheels.tests` / `vendor.<pkg>.tests`, default
	 * `wheels.tests.specs`).
	 *
	 * Returns: { requested, resolved, rejected }
	 *   requested — the trimmed url.directory ("" when none was supplied)
	 *   resolved  — the directory actually handed to TestBox
	 *   rejected  — true when a non-empty value failed the allowlist and was
	 *               swapped for the default (the silent-fallback trap)
	 */
	public struct function resolveScope(
		required struct url,
		string defaultDirectory = variables.DEFAULT_DIRECTORY,
		string allowlistPattern = variables.ACCEPTED_PATH_REGEX
	) {
		var scope = {
			requested = "",
			resolved = arguments.defaultDirectory,
			rejected = false
		};
		if (!StructKeyExists(arguments.url, "directory")) {
			return scope;
		}
		scope.requested = Trim(arguments.url.directory);
		if (!Len(scope.requested)) {
			scope.requested = "";
			return scope;
		}
		if (ReFindNoCase(arguments.allowlistPattern, scope.requested)) {
			scope.resolved = scope.requested;
		} else {
			scope.rejected = true;
		}
		return scope;
	}

	/**
	 * Build warnings describing scope-resolution problems that would
	 * otherwise produce a misleading green run: a rejected directory (the
	 * full suite ran instead of the requested scope) and a 0-bundle
	 * discovery (an allowlist-passing single spec FILE matches no bundles
	 * yet still reports green — the inverse trap, fixed with `testBundles=`).
	 */
	public array function scopeWarnings(required struct scope, required numeric bundlesDiscovered) {
		var warnings = [];
		if (arguments.scope.rejected) {
			ArrayAppend(
				warnings,
				"Requested directory '" & arguments.scope.requested & "' is not an accepted test scope; "
				& "ran '" & arguments.scope.resolved & "' (the full default suite) instead. "
				& "Use a fully-qualified dotted path under '" & arguments.scope.resolved & "' (e.g. '"
				& arguments.scope.resolved & ".model')."
			);
		}
		if (arguments.bundlesDiscovered <= 0) {
			ArrayAppend(
				warnings,
				"No test bundles were discovered for directory '" & arguments.scope.resolved & "'. "
				& "A single spec FILE is not a directory scope — use testBundles= to run one bundle."
			);
		}
		return warnings;
	}

	/**
	 * Splice the scope-visibility fields into the runner's JSON payload
	 * without re-serializing (and so without risking struct-key case changes
	 * on the existing keys CI parsers depend on). The metadata object is
	 * prepended inside the result's outer braces; the original result body is
	 * left byte-for-byte intact. Falls back to a wrapper object if the result
	 * isn't a JSON object so the metadata is never lost.
	 */
	public string function injectScopeMetadata(
		required string resultJson,
		required struct scope,
		required numeric bundlesDiscovered,
		required array warnings
	) {
		var meta = {
			"directoryRequested" = arguments.scope.requested,
			"directoryResolved" = arguments.scope.resolved,
			"directoryRejected" = arguments.scope.rejected,
			"bundlesDiscovered" = arguments.bundlesDiscovered,
			"warnings" = arguments.warnings
		};
		var metaJson = SerializeJSON(meta);
		var body = Trim(arguments.resultJson);
		if (!Len(body) || Left(body, 1) != "{" || body == "{}") {
			return SerializeJSON({"scope" = meta, "testResult" = arguments.resultJson});
		}
		// metaJson is a non-empty object, so it has at least one field and
		// Len(metaJson) > 2 — stripping the outer braces is safe.
		var inner = Mid(metaJson, 2, Len(metaJson) - 2);
		return "{" & inner & "," & Mid(body, 2, Len(body) - 1);
	}

}
