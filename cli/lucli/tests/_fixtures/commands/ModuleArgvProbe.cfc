/**
 * Test fixture for Module.cfc's private argument-handling helpers.
 *
 * Module.cfc keeps its arg-sourcing and per-command parse helpers private to
 * keep the LuCLI-dispatch surface tight (public functions become CLI
 * subcommands / MCP tools). This fixture extends Module and exposes thin
 * public pass-throughs so specs can unit-test the parsing layer without
 * booting a server or triggering command side effects.
 *
 *   - $structuredArgs / $argvToCollection : the ArgSpec sourcing layer (#2861)
 *   - $parse<Command>Args : per-command parse helpers migrated to ArgSpec
 *
 * Some helpers read the instance-level __arguments fallback. That value lives
 * in the `variables` scope (create() sets it via an unscoped assignment, and
 * the helpers read it unscoped) — a spec setting `probe.__arguments` would only
 * touch the `this` scope, which the helpers never see. So the wrappers that
 * exercise the fallback take it as an argument and seed `variables` directly,
 * and ALWAYS reset it (defaulting to []) on every call, so this shared probe
 * never carries a stale __arguments from a prior spec.
 */
component extends="cli.lucli.Module" {

	public struct function $argvToCollection(required array argv) {
		return argvToCollection(arguments.argv);
	}

	public struct function $structuredArgs(struct callerArgs = {}, array underscoreArguments = []) {
		variables.__arguments = arguments.underscoreArguments;
		return structuredArgs(arguments.callerArgs);
	}

	public struct function $parseNewArgs(required struct coll) {
		return parseNewArgs(arguments.coll);
	}

	public struct function $parseSeedArgs(required struct coll) {
		return parseSeedArgs(arguments.coll);
	}

	public struct function $parseNotesArgs(required struct coll) {
		return parseNotesArgs(arguments.coll);
	}

	public struct function $parseAnalyzeArgs(required struct coll) {
		return parseAnalyzeArgs(arguments.coll);
	}

	public boolean function $parseVerboseFlag(required struct coll) {
		return parseVerboseFlag(arguments.coll);
	}

	public struct function $parseUpgradeArgs(required struct coll) {
		return parseUpgradeArgs(arguments.coll);
	}

	public struct function $parseDestroyArgs(required struct coll) {
		return parseDestroyArgs(arguments.coll);
	}

	public struct function $parseConsoleArgs(required struct coll) {
		return parseConsoleArgs(arguments.coll);
	}

	public struct function $parseTestArgs(required struct coll) {
		return parseTestArgs(arguments.coll);
	}

}
