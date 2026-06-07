/**
 * Typed argument-spec builder for Wheels CLI subcommands.
 *
 * LuCLI already parses the command line into a structured map and hands it
 * to each module function as `arguments` (positionals as `arg1, arg2, ...`;
 * `--key=value` as `key=value`; `--no-key` normalized to `key=false`).
 * `Module.cfc::argsFromCollection()` historically flattened that map back
 * to argv so each subcommand could re-parse it with a hand-rolled token
 * loop — a round trip that silently dropped `false` values (the root cause
 * of #2855) and could not distinguish `--no-X` from an explicit `--X=false`.
 *
 * `ArgSpec` consumes LuCLI's structured map directly. Each command declares
 * its positionals, flags, and options up front; `.parse(arguments)` returns
 * a typed result struct. No flatten, no re-parse, no lossy `false` round
 * trip. Designed to be adopted incrementally — `getArgs()` and
 * `argsFromCollection()` stay in place as a deprecated shim until every
 * call site is converted.
 *
 * Usage:
 *
 *     var spec = new services.ArgSpec()
 *         .positional(name = "appName", required = true)
 *         .flag(name = "sqlite",      default = true)   // --no-sqlite negates
 *         .flag(name = "routes",      default = true)
 *         .option(name = "datasource", default = "");
 *     var opts = spec.parse(arguments);
 *     // opts.appName, opts.sqlite (boolean), opts.datasource (string)
 *
 * See issue #2861 for the design discussion and cross-framework research.
 */
component {

	public any function init() {
		variables.positionals = [];
		variables.named = {};
		return this;
	}

	public any function positional(
		required string name,
		boolean required = false,
		any default = "",
		string type = "string"
	) {
		arrayAppend(variables.positionals, {
			"name" = arguments.name,
			"required" = arguments.required,
			"default" = arguments.default,
			"type" = arguments.type
		});
		return this;
	}

	public any function flag(
		required string name,
		boolean default = false
	) {
		variables.named[arguments.name] = {
			"default" = arguments.default,
			"type" = "boolean"
		};
		return this;
	}

	public any function option(
		required string name,
		any default = "",
		string type = "string"
	) {
		variables.named[arguments.name] = {
			"default" = arguments.default,
			"type" = arguments.type
		};
		return this;
	}

	public struct function parse(required struct coll) {
		var result = {};

		// 1. Seed named defaults so every declared option is present in the result.
		for (var optName in variables.named) {
			result[optName] = variables.named[optName]["default"];
		}

		// 2. Bind positionals from coll.arg1, arg2, ... in declaration order.
		var positionalCount = arrayLen(variables.positionals);
		for (var i = 1; i <= positionalCount; i++) {
			var pSpec = variables.positionals[i];
			var collKey = "arg" & i;
			if (structKeyExists(arguments.coll, collKey)) {
				result[pSpec.name] = $coerce(arguments.coll[collKey], pSpec.type);
			} else if (pSpec.required) {
				throw(
					type = "Wheels.CLI.MissingArgument",
					message = "Missing required argument <" & pSpec.name & ">"
				);
			} else {
				result[pSpec.name] = pSpec["default"];
			}
		}

		// 3. Bind named values — LuCLI already normalized --no-X to key=false,
		//    so we just consume the structured handoff. Unknown keys are
		//    ignored so a stray LuCLI flag never lands in the result.
		for (var key in arguments.coll) {
			if (reFindNoCase("^arg\d+$", key)) {
				continue;
			}
			if (structKeyExists(variables.named, key)) {
				result[key] = $coerce(arguments.coll[key], variables.named[key].type);
			}
		}

		return result;
	}

	/**
	 * Reconstruct LuCLI's ordered argv from a structured argCollection.
	 *
	 * The inverse of LuCLI's parse: positionals (arg1, arg2, ...) emit first
	 * in index order, then named keys emit as `--key` (true), `--no-key`
	 * (false), or `--key=value`. This is the non-lossy passthrough that
	 * commands with their own downstream argv parsers (generate, create, db,
	 * browser, deploy, packages, migrate, start) use to forward LuCLI's
	 * structured handoff to a flat-array parser — replacing the Module.cfc
	 * getArgs()/argsFromCollection() round trip (#2855, #2861).
	 *
	 * Contract dependency: LuCLI's parseArguments() normalizes `--no-X` to
	 * `X=false` and bare `--X` to `X=true` before dispatch. The `value=="false"`
	 * arm re-emits `--no-X` so downstream literal-token matchers (e.g.
	 * `--no-routes`, `--no-migration`) still see the user's negation (#2856).
	 */
	public array function toArgv(required struct coll) {
		var result = [];

		// Positionals in arg1..argN order. Stops at the first index gap,
		// mirroring the legacy argsFromCollection — dispatchers always pass
		// the sub-verb as the leading positional, so a gap never elides one.
		var i = 1;
		while (structKeyExists(arguments.coll, "arg" & i)) {
			arrayAppend(result, arguments.coll["arg" & i]);
			i++;
		}

		// Named keys, re-prefixed. --no-X for false preserves the negation.
		for (var key in arguments.coll) {
			if (reFindNoCase("^arg\d+$", key)) {
				continue;
			}
			var value = arguments.coll[key];
			if (isSimpleValue(value) && value == "true") {
				arrayAppend(result, "--" & key);
			} else if (isSimpleValue(value) && value == "false") {
				arrayAppend(result, "--no-" & key);
			} else if (isSimpleValue(value)) {
				arrayAppend(result, "--" & key & "=" & value);
			}
		}

		return result;
	}

	private any function $coerce(required any v, required string type) {
		switch (arguments.type) {
			case "boolean":
				// Normalize to a strict CFML boolean regardless of whether the
				// runtime handed us a literal true/false or the string "true"/
				// "false". `isBoolean("false")` is true on every supported
				// engine, but the *value* is still a string; the ternary forces
				// the conversion so downstream `if (out.flag)` is unambiguous.
				if (isBoolean(arguments.v)) {
					return arguments.v ? true : false;
				}
				return lCase(trim(toString(arguments.v))) == "true";
			case "numeric":
				return val(arguments.v);
			default:
				return toString(arguments.v);
		}
	}

}
