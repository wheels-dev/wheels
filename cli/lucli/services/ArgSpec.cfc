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
 * own downstream argv parser (generate, deploy, migrate, ...) — calls
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
		// Declaration order of the named options: variables.named is a struct,
		// whose iteration order on Lucee is not insertion order, and help lists
		// options in the order the command declares them.
		variables.namedOrder = [];
		// Keys parse() accepts without declaring or advertising them. `offline`
		// is the one documented GLOBAL flag ("applies to every command",
		// command-line-tools guide); commands that act on it read it through
		// $consumeOfflineFlag or declare it.
		variables.accepted = ["offline"];
		return this;
	}

	/**
	 * Accept a named key that parse() must not reject but the MCP schema must
	 * not advertise — a CLI-only spelling the command reads itself (e.g.
	 * upgrade's `--no-backup`, which LuCLI normalizes to backup=false).
	 */
	public any function accept(required string name) {
		arrayAppend(variables.accepted, arguments.name);
		return this;
	}

	public any function positional(
		required string name,
		boolean required = false,
		any default = "",
		string type = "string",
		string description = "",
		string choices = ""
	) {
		arrayAppend(variables.positionals, {
			"name" = arguments.name,
			"required" = arguments.required,
			"default" = arguments.default,
			"type" = arguments.type,
			"description" = arguments.description,
			"choices" = listToArray(arguments.choices)
		});
		return this;
	}

	public any function flag(
		required string name,
		boolean default = false,
		string description = ""
	) {
		$rememberOrder(arguments.name);
		variables.named[arguments.name] = {
			"default" = arguments.default,
			"type" = "boolean",
			"description" = arguments.description,
			"choices" = []
		};
		return this;
	}

	/**
	 * `choices` (comma-delimited) fixes the accepted values: parse() rejects
	 * anything else and toInputSchema() advertises them as a JSON Schema
	 * `enum`, so the parser and the MCP schema share one declaration (#2963).
	 * Positionals take the same argument.
	 */
	public any function option(
		required string name,
		any default = "",
		string type = "string",
		string description = "",
		string choices = ""
	) {
		$rememberOrder(arguments.name);
		variables.named[arguments.name] = {
			"default" = arguments.default,
			"type" = arguments.type,
			"description" = arguments.description,
			"choices" = listToArray(arguments.choices)
		};
		return this;
	}

	/**
	 * The declared choices for a positional or option (empty array when it
	 * has none). For commands that bind a value outside parse() — destroy's
	 * legacy <name> <type> reorder — and must validate it the same way.
	 */
	public array function choicesFor(required string name) {
		for (var p in variables.positionals) {
			if (p.name == arguments.name) {
				return p.choices;
			}
		}
		return structKeyExists(variables.named, arguments.name) ? variables.named[arguments.name].choices : [];
	}

	/**
	 * Throw Wheels.InvalidArguments when a supplied value is not one of the
	 * declared choices. Empty values are not validated: they mean "not
	 * given" (db's subcommand defaults to "" to print usage).
	 */
	private void function $assertChoice(required string name, required any value, required array choices) {
		if (!arrayLen(arguments.choices) || !isSimpleValue(arguments.value) || !len(trim(arguments.value))) {
			return;
		}
		if (!arrayFindNoCase(arguments.choices, trim(arguments.value))) {
			throw(
				type = "Wheels.InvalidArguments",
				message = "Invalid value '#arguments.value#' for #arguments.name#. Valid values: #arrayToList(arguments.choices, ', ')#."
			);
		}
	}

	/**
	 * `strict` (default) enforces the schema's additionalProperties:false: a
	 * named key that is not declared, not a positional's name, and not
	 * accept()ed throws Wheels.InvalidArguments naming it (#2963). Pass
	 * strict=false only for a partial spec whose caller forwards the rest to
	 * a parser that is itself strict (create -> new).
	 */
	public struct function parse(required struct coll, boolean strict = true) {
		var result = {};

		// LuCLI's runtime-owned MCP marker (wheels-dev/LuCLI#17) is never a
		// command argument; Module.structuredArgs() normally removes it first.
		if (structKeyExists(arguments.coll, "__lucliMcpCall")) {
			arguments.coll = structCopy(arguments.coll);
			structDelete(arguments.coll, "__lucliMcpCall");
		}

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
		// A key that is present with a NULL value (the stdio MCP transport
		// turns an empty JSON string into null) is "no value", never
		// "omitted": `migrate {action: null}` must not fall back to the default
		// action `latest`. structKeyExists() is false for a null value, so scan
		// the keys directly.
		var nullKeys = [];
		for (var nk in arguments.coll) {
			if (isNull(arguments.coll[nk])) {
				arrayAppend(nullKeys, nk);
			}
		}
		for (var nk in nullKeys) {
			if (reFindNoCase("^arg\d+$", nk)) {
				throw(type = "Wheels.InvalidArguments", message = "Positional argument #mid(nk, 4, len(nk))# has no value.");
			}
		}
		for (var p in variables.positionals) {
			if (arrayFindNoCase(nullKeys, p.name)) {
				throw(type = "Wheels.InvalidArguments", message = "<" & p.name & "> has no value.");
			}
		}
		// ...declared or not: an undeclared null key is still input the
		// command might read raw (upgrade's dry-run did, and applied).
		for (var nk in nullKeys) {
			throw(type = "Wheels.InvalidArguments", message = "--" & nk & " has no value.");
		}

		if (arguments.strict) {
			for (var key in arguments.coll) {
				if (
					reFindNoCase("^arg\d+$", key)
					|| structKeyExists(variables.named, key)
					|| arrayFindNoCase(variables.accepted, key)
					|| $isPositionalName(key)
				) {
					continue;
				}
				throw(
					type = "Wheels.InvalidArguments",
					message = "Unknown argument '--#key#'. Accepted: #arrayLen($acceptedNames()) ? arrayToList($acceptedNames(), ', ') : 'none (this command takes no arguments)'#."
				);
			}
		}

		var positionalIndices = $positionalIndices(arguments.coll);
		var positionalCount = arrayLen(variables.positionals);
		for (var i = 1; i <= positionalCount; i++) {
			var pSpec = variables.positionals[i];
			if (i <= arrayLen(positionalIndices)) {
				result[pSpec.name] = $coerce(arguments.coll["arg" & positionalIndices[i]], pSpec.type, pSpec.name);
				$assertChoice(pSpec.name, result[pSpec.name], pSpec.choices);
			} else if (structKeyExists(arguments.coll, pSpec.name) && isSimpleValue(arguments.coll[pSpec.name])) {
				// By-name fallback (#2963). LuCLI's MCP server delivers
				// tools/call arguments as named keys — toInputSchema()
				// advertises positionals as named properties, so
				// {type: "model"} arrives as type=model, never arg1. A typed
				// positional token still wins; the name only fills a slot the
				// tokens left unbound.
				//
				// A bare CLI `--name` arrives as name=true: a flag, not a value.
				// It must ERROR, never fall back to the default — MCP
				// migrate {action: "true"} falling back to `latest` would run
				// migrations.
				if (pSpec.type == "string" && compareNoCase(toString(arguments.coll[pSpec.name]), "true") == 0) {
					throw(
						type = "Wheels.InvalidArguments",
						message = "<" & pSpec.name & "> needs a value, e.g. --" & pSpec.name & "=<value> (a bare --" & pSpec.name & " is a flag)."
					);
				}
				result[pSpec.name] = $coerce(arguments.coll[pSpec.name], pSpec.type, pSpec.name);
				$assertChoice(pSpec.name, result[pSpec.name], pSpec.choices);
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
			if (reFindNoCase("^arg\d+$", key) || arrayFindNoCase(nullKeys, key)) {
				continue;
			}
			if (structKeyExists(variables.named, key)) {
				// A bare `--to` arrives as to=true: a flag, not a value. For a
				// string option that must ERROR, never bind the literal "true".
				if (
					variables.named[key].type == "string"
					&& isSimpleValue(arguments.coll[key])
					&& compareNoCase(trim(toString(arguments.coll[key])), "true") == 0
				) {
					throw(
						type = "Wheels.InvalidArguments",
						message = "--#key# needs a value, e.g. --#key#=<value> (a bare --#key# is a flag)."
					);
				}
				result[key] = $coerce(arguments.coll[key], variables.named[key].type, key);
				$assertChoice(key, result[key], variables.named[key].choices);
			}
		}

		return result;
	}

	/**
	 * Re-binds space-form option values (`--port 8931`). LuCLI hands that over
	 * as port="true" plus a positional one index past the gap the flag left
	 * (arg3 missing, arg4="8931"), so a value parser sees a bare flag.
	 *
	 * `matchers` maps each option that may arrive this way to a regex its
	 * value must match ("" matches anything). The candidates are the
	 * positionals that directly follow a gap. With one bare option and one
	 * candidate, the candidate binds when it matches. With several, each
	 * candidate must match exactly one bare option and each bare option
	 * exactly one candidate (e.g. a number for port, a name for engine);
	 * otherwise nothing is bound. Bound candidates leave the positionals.
	 */
	public struct function bindSpaceFormValues(required struct coll, required struct matchers) {
		var bare = [];
		for (var key in arguments.matchers) {
			if (
				structKeyExists(arguments.coll, key)
				&& isSimpleValue(arguments.coll[key])
				&& compareNoCase(trim(toString(arguments.coll[key])), "true") == 0
			) {
				arrayAppend(bare, key);
			}
		}
		if (!arrayLen(bare)) {
			return arguments.coll;
		}
		var maxIndex = 0;
		for (var k in arguments.coll) {
			if (reFindNoCase("^arg\d+$", k)) {
				maxIndex = max(maxIndex, val(mid(k, 4, len(k) - 3)));
			}
		}
		var candidates = [];
		for (var i = 1; i < maxIndex; i++) {
			if (!structKeyExists(arguments.coll, "arg" & i) && structKeyExists(arguments.coll, "arg" & (i + 1))) {
				arrayAppend(candidates, "arg" & (i + 1));
			}
		}
		if (arrayLen(candidates) != arrayLen(bare)) {
			return arguments.coll;
		}
		var binding = {};
		for (var argKey in candidates) {
			var value = toString(arguments.coll[argKey]);
			var owners = [];
			for (var key in bare) {
				var pattern = arguments.matchers[key];
				if (!len(pattern) || reFind(pattern, value)) {
					arrayAppend(owners, key);
				}
			}
			// A single bare option takes the single candidate if it fits;
			// several need a one-to-one match by value shape.
			if (arrayLen(owners) != 1 || structKeyExists(binding, owners[1])) {
				return arguments.coll;
			}
			binding[owners[1]] = argKey;
		}
		var result = duplicate(arguments.coll);
		for (var key in binding) {
			result[key] = result[binding[key]];
			structDelete(result, binding[key]);
		}
		return result;
	}

	/** bindSpaceFormValues() for one option whose value can be anything. */
	public struct function bindSpaceFormValue(required struct coll, required string key) {
		var matchers = {};
		matchers[arguments.key] = "";
		return bindSpaceFormValues(arguments.coll, matchers);
	}

	/**
	 * Reconstruct LuCLI's ordered argv from a structured argCollection.
	 *
	 * The inverse of LuCLI's parse: positionals (arg1, arg2, ...) emit first
	 * in index order, then named keys emit as `--key` (true), `--no-key`
	 * (false), or `--key=value`. This is the non-lossy passthrough that
	 * commands with their own downstream argv parsers (generate, create,
	 * browser, deploy, migrate, start) use to forward LuCLI's
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
		// Flag detection MUST use an exact string compare: CFML `==` coerces
		// both operands, so "1" == "true" and "0" == "false" evaluate TRUE.
		// That coercion turned `--release=1` into a bare --release flag (value
		// dropped) and the downstream deploy parser then swallowed --dry-run
		// as the version — a documented dry run dispatched live SSH and hung
		// ~76s against the config stub's placeholder host (issue #3111).
		// LuCLI normalizes flags to the literal strings "true"/"false"; MCP
		// argCollections may carry native booleans, which toString() renders
		// as "true"/"false" — both shapes match the exact compare.
		for (var key in arguments.coll) {
			// The runtime-owned MCP marker is never forwarded as a flag (#3980).
			if (reFindNoCase("^arg\d+$", key) || compareNoCase(key, "__lucliMcpCall") == 0) {
				continue;
			}
			if (isNull(arguments.coll[key])) {
				// The MCP transport turns "" into null; forwarding it as a flag
				// would change meaning downstream (#2963).
				throw(type = "Wheels.InvalidArguments", message = "--" & key & " has no value.");
			}
			var value = arguments.coll[key];
			if (!isSimpleValue(value)) {
				continue;
			}
			var stringValue = toString(value);
			if (compareNoCase(stringValue, "true") == 0) {
				arrayAppend(result, "--" & key);
			} else if (compareNoCase(stringValue, "false") == 0) {
				arrayAppend(result, "--no-" & key);
			} else {
				arrayAppend(result, "--" & key & "=" & stringValue);
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
	/**
	 * The options section of `wheels <cmd> --help` (issue 3962): one entry per
	 * positional and named option, in declaration order, with its description,
	 * accepted values and default, wrapped to `width` columns. Keys added with
	 * accept() are not listed, as they are not in the MCP schema either.
	 */
	public array function toHelpLines(numeric width = 100) {
		var entries = [];
		for (var p in variables.positionals) {
			arrayAppend(entries, {label = "<" & p.name & ">", text = $helpText(p.description, p.choices, p["default"], p.type)});
		}
		for (var optName in variables.namedOrder) {
			var spec = variables.named[optName];
			var label = "--" & optName & "=<value>";
			var text = $helpText(spec.description, spec.choices, spec["default"], spec.type);
			if (spec.type == "boolean") {
				var onByDefault = isBoolean(spec["default"]) && spec["default"];
				label = onByDefault ? "--[no-]" & optName : "--" & optName;
				if (onByDefault) {
					text &= (len(text) ? " " : "") & "(on by default)";
				}
			}
			arrayAppend(entries, {label = label, text = text});
		}
		var labelWidth = 0;
		for (var entry in entries) {
			labelWidth = max(labelWidth, len(entry.label));
		}
		labelWidth = min(labelWidth, 26);
		var indent = 2 + labelWidth + 2;
		var lines = [];
		for (var entry in entries) {
			var head = "  " & entry.label;
			var words = listToArray(entry.text, " ");
			var current = len(head) >= indent ? head : head & repeatString(" ", indent - len(head));
			if (len(head) >= indent) {
				arrayAppend(lines, head);
				current = repeatString(" ", indent);
			}
			var fresh = true;
			for (var word in words) {
				if (!fresh && len(current) + 1 + len(word) > arguments.width) {
					arrayAppend(lines, current);
					current = repeatString(" ", indent) & word;
				} else {
					current &= (fresh ? "" : " ") & word;
				}
				fresh = false;
			}
			arrayAppend(lines, reReplace(current, "\s+$", ""));
		}
		return lines;
	}

	private string function $helpText(
		required string description,
		required array choices,
		required any default,
		required string type
	) {
		var text = trim(arguments.description);
		if (arrayLen(arguments.choices)) {
			text &= (len(text) ? " " : "") & "[" & arrayToList(arguments.choices, ", ") & "]";
		}
		if (arguments.type != "boolean" && isSimpleValue(arguments.default) && len(trim(toString(arguments.default)))) {
			text &= (len(text) ? " " : "") & "(default: " & toString(arguments.default) & ")";
		}
		return text;
	}

	private void function $rememberOrder(required string name) {
		if (!arrayFindNoCase(variables.namedOrder, arguments.name)) {
			arrayAppend(variables.namedOrder, arguments.name);
		}
	}

	public struct function toInputSchema() {
		var properties = {};
		var required = [];

		for (var p in variables.positionals) {
			properties[p.name] = $toSchemaProperty(p.type, p["default"], p.description, p.choices);
			if (p.required) {
				arrayAppend(required, p.name);
			}
		}

		for (var optName in variables.named) {
			var spec = variables.named[optName];
			properties[optName] = $toSchemaProperty(spec.type, spec["default"], spec.description, spec.choices);
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
		string description = "",
		array choices = []
	) {
		var prop = {"type" = $toJsonSchemaType(arguments.type)};
		if (arrayLen(arguments.choices)) {
			prop["enum"] = arguments.choices;
		}
		// A default outside the enum (db's "" = print usage) would contradict
		// the schema, so it is left out; the command still applies it.
		if (!arrayLen(arguments.choices) || arrayFindNoCase(arguments.choices, toString(arguments.default))) {
			prop["default"] = arguments.default;
		}
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
	private boolean function $isPositionalName(required string name) {
		for (var p in variables.positionals) {
			if (p.name == arguments.name) {
				return true;
			}
		}
		return false;
	}

	/**
	 * Every name parse() accepts, for the unknown-argument message.
	 */
	private array function $acceptedNames() {
		var names = [];
		for (var p in variables.positionals) {
			arrayAppend(names, p.name);
		}
		for (var n in variables.named) {
			arrayAppend(names, n);
		}
		arraySort(names, "textnocase");
		return names;
	}

	private array function $positionalIndices(required struct coll) {
		var indices = [];
		for (var key in arguments.coll) {
			// An empty token is not a token (#2963): it must not bind a slot
			// and shadow the named key, or {arg1: "", action: "bogus"} would
			// bind action="" and fall back to the default action.
			if (
				reFindNoCase("^arg\d+$", key)
				&& !(isSimpleValue(arguments.coll[key]) && !len(trim(toString(arguments.coll[key]))))
			) {
				arrayAppend(indices, val(mid(key, 4, len(key))));
			}
		}
		arraySort(indices, "numeric");
		return indices;
	}

	/**
	 * Coerce a supplied value to its declared type, rejecting anything that is
	 * not a real value of that type (#2963). A value that cannot be read must
	 * never become a silent default: `strict=bogus` used to read as false and
	 * `--interval` (bare) as 0. Destructive verbs like `upgrade apply` depend
	 * on this to throw before acting.
	 */
	private any function $coerce(required any v, required string type, string name = "") {
		var label = len(arguments.name) ? "--" & arguments.name : "value";
		var text = trim(toString(arguments.v));
		switch (arguments.type) {
			case "boolean":
				// LuCLI normalizes flags to the strings "true"/"false"; MCP
				// clients send native booleans (toString gives "true"/"false").
				// Nothing else is a boolean here — not yes/no/1/0, not "".
				if (compareNoCase(text, "true") == 0) {
					return true;
				}
				if (compareNoCase(text, "false") == 0) {
					return false;
				}
				throw(
					type = "Wheels.InvalidArguments",
					message = "#label# expects true or false, got '#text#'."
				);
			case "numeric":
				if (!isNumeric(text)) {
					throw(
						type = "Wheels.InvalidArguments",
						message = "#label# expects a number, got '#text#'."
					);
				}
				return val(text);
			default:
				return toString(arguments.v);
		}
	}

}
