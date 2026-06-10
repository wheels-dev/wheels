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
 * `ArgSpec` consumes LuCLI's structured map directly. Each command either
 * declares its positionals, flags, and options up front and calls
 * `.parse(arguments)` for a typed result struct, or — when it forwards to its
 * own downstream argv parser (generate, deploy, packages, ...) — calls
 * `.toArgv(arguments)` for a non-lossy collection->argv reconstruction. Either
 * way: no per-command flatten, no re-parse, no lossy `false` round trip. The
 * Module.cfc getArgs()/argsFromCollection() shim this replaced has been removed
 * now that every call site is converted (#2861).
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
		string type = "string",
		string description = ""
	) {
		arrayAppend(variables.positionals, {
			"name" = arguments.name,
			"required" = arguments.required,
			"default" = arguments.default,
			"type" = arguments.type,
			"description" = arguments.description
		});
		return this;
	}

	public any function flag(
		required string name,
		boolean default = false,
		string description = ""
	) {
		variables.named[arguments.name] = {
			"default" = arguments.default,
			"type" = "boolean",
			"description" = arguments.description
		};
		return this;
	}

	public any function option(
		required string name,
		any default = "",
		string type = "string",
		string description = ""
	) {
		variables.named[arguments.name] = {
			"default" = arguments.default,
			"type" = arguments.type,
			"description" = arguments.description
		};
		return this;
	}

	public struct function parse(required struct coll) {
		var result = {};

		// 1. Seed named defaults so every declared option is present in the result.
		for (var optName in variables.named) {
			result[optName] = variables.named[optName]["default"];
		}

		// 2. Bind positionals in declaration order. LuCLI numbers positionals
		//    by GLOBAL token index, so a named option/flag between positionals
		//    leaves a numbering gap (`wheels new --port=3000 blog` arrives as
		//    {port="3000", arg2="blog"} — there is no arg1). Collect every
		//    arg<N> key and sort numerically instead of probing literal
		//    arg1..argN; fixed-index probing made gap-following positionals
		//    silently bind nothing (the appName above was ignored).
		var positionalIndices = $positionalIndices(arguments.coll);
		var positionalCount = arrayLen(variables.positionals);
		for (var i = 1; i <= positionalCount; i++) {
			var pSpec = variables.positionals[i];
			if (i <= arrayLen(positionalIndices)) {
				result[pSpec.name] = $coerce(arguments.coll["arg" & positionalIndices[i]], pSpec.type);
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

		// Positionals in numeric arg<N> order. LuCLI numbers positionals by
		// global token index, so a flag between two positionals leaves a gap
		// (arg1, arg2, arg4, ...). The previous loop stopped at the first gap
		// and silently dropped every positional after a flag — `wheels g
		// scaffold Post --force title:string body:text` lost both columns.
		// Collect-and-sort heals the gaps (mirrors parseTestArgs).
		for (var idx in $positionalIndices(arguments.coll)) {
			arrayAppend(result, arguments.coll["arg" & idx]);
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

	/**
	 * Emit a JSON-Schema-compatible input schema describing this spec.
	 *
	 * The auto-discovered MCP tools in Module.cfc currently advertise empty
	 * `properties` so clients can't discover parameters (#2963). Per the
	 * cross-framework research (FastMCP, MCP TypeScript SDK, Symfony
	 * JsonDescriptor): derive the schema from the same typed declaration
	 * the command already uses. One source of truth, no hand-written drift.
	 *
	 * Result shape (matches MCP `tools/list[].inputSchema`):
	 *
	 *     {
	 *       "type": "object",
	 *       "properties": {
	 *         "appName":    {"type": "string",  "description": "...", "default": ""},
	 *         "sqlite":     {"type": "boolean", "description": "...", "default": true},
	 *         "datasource": {"type": "string",  "description": "...", "default": ""}
	 *       },
	 *       "required": ["appName"],
	 *       "additionalProperties": false
	 *     }
	 *
	 * Type mapping follows CFML/ArgSpec coercion: positional/option strings
	 * become JSON Schema "string"; numeric-typed options become "number";
	 * flags become "boolean". `additionalProperties: false` matches the
	 * mcpHiddenTools surface convention — unknown keys are rejected at the
	 * MCP client.
	 */
	public struct function toInputSchema() {
		var properties = {};
		var required = [];

		for (var p in variables.positionals) {
			properties[p.name] = $toSchemaProperty(p.type, p["default"], p.description);
			if (p.required) {
				arrayAppend(required, p.name);
			}
		}

		for (var optName in variables.named) {
			var spec = variables.named[optName];
			properties[optName] = $toSchemaProperty(spec.type, spec["default"], spec.description);
		}

		return {
			"type" = "object",
			"properties" = properties,
			"required" = required,
			"additionalProperties" = false
		};
	}

	private struct function $toSchemaProperty(
		required string type,
		required any default,
		string description = ""
	) {
		var prop = {
			"type" = $toJsonSchemaType(arguments.type),
			"default" = arguments.default
		};
		if (len(arguments.description)) {
			prop["description"] = arguments.description;
		}
		return prop;
	}

	private string function $toJsonSchemaType(required string cfmlType) {
		switch (arguments.cfmlType) {
			case "boolean":
				return "boolean";
			case "numeric":
				return "number";
			default:
				return "string";
		}
	}

	/**
	 * Collect the numeric index of every positional (arg<N>) key in the
	 * collection, sorted ascending. LuCLI numbers positionals by global token
	 * index — a named option/flag consumes an index without producing an
	 * arg<N> key — so consumers must never assume the indices are contiguous
	 * or start at 1.
	 */
	private array function $positionalIndices(required struct coll) {
		var indices = [];
		for (var key in arguments.coll) {
			if (reFindNoCase("^arg\d+$", key)) {
				arrayAppend(indices, val(mid(key, 4, len(key))));
			}
		}
		arraySort(indices, "numeric");
		return indices;
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
