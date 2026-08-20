component output="false" {

	// These four helpers MUST stay as methods of this CFC (not in
	// vendor/wheels/global/*.cfm). Lucee compiles a function from a
	// component-body include as a UDF of that include template
	// (`global.tags_cfm$cf.udfCall`). `include` inside those UDFs then
	// resolves relative to `vendor/wheels/global/` and does not apply
	// application mappings the same way a method on wheels.Global does —
	// so `onAbort`'s `$include("../../#eventPath#/onabort.cfm")` looks
	// for `/app/events/onabort.cfm` under the webroot and 500s. Keep
	// every `include` statement that apps rely on for mapping-absolute
	// or `../../`-prefixed event/config paths here (issue ##3241).
	public void function $include(required string template) {
		// Hoist the resolve: a function call inside the `include` attribute
		// is one Adobe teardown trigger. Mapping-absolute includes still
		// fail after applicationStop() drops THIS.mappings — fall back
		// via $tryIncludeTemplate (issue ##3241).
		$tryIncludeTemplate($resolveGlobalIncludeTemplate(arguments.template));
	}

	public void function $includeAndOutput(required string template) {
		$tryIncludeTemplate($resolveGlobalIncludeTemplate(arguments.template));
	}

	public string function $includeAndReturnOutput(required string $template) {
		// Make it so the developer can reference passed in arguments in the loc scope if they prefer.
		if (StructKeyExists(arguments, "$type") AND arguments.$type IS "partial") {
			local = arguments;
		}
		// Include the template and return the result.
		// Variable is set to $wheels to limit chances of it being overwritten in the included template.
		// Include stays in this function: `local = arguments` above must be
		// visible to partials, and savecontent must wrap the include itself
		// (a helper on this output=false CFC would capture nothing).
		// cfformat-ignore-start
		local.resolved = $resolveGlobalIncludeTemplate(arguments.$template);
		var includeState = {done = false, output = ""};
		var captured = "";
		try {
			savecontent variable="captured" {
				include "#local.resolved#"
			};
			includeState.output = captured;
			includeState.done = true;
		} catch (any e) {
			if (!$isMissingMappedInclude(e)) {
				rethrow;
			}
		}
		if (!includeState.done) {
			var fallbacks = $mappedIncludeFallbacks(local.resolved);
			var fbCount = ArrayLen(fallbacks);
			for (var fbIndex = 1; fbIndex <= fbCount; fbIndex++) {
				try {
					savecontent variable="captured" {
						include "#fallbacks[fbIndex]#"
					};
					includeState.output = captured;
					includeState.done = true;
					break;
				} catch (any e) {
					if (fbIndex == fbCount || !$isMissingMappedInclude(e)) {
						rethrow;
					}
				}
			}
		}
		// cfformat-ignore-end
		return includeState.output;
	}

	/**
	 * Includes a config file like /config/settings.cfm or /config/services.cfm
	 * during application start, capturing any output it produces.
	 *
	 * If the file fails to compile or run, the failure is logged and rethrown
	 * as a named `Wheels.ConfigIncludeFailed` error that carries the failing
	 * template path and the original engine message (original type/detail are
	 * preserved in `detail`). This is deliberate fail-closed behavior in EVERY
	 * environment: an app whose config did not load must not boot on framework
	 * defaults and serve traffic. The named error propagates out of
	 * onApplicationStart by design, and renders on the development error page
	 * now that onError no longer masks application-start errors.
	 *
	 * If the include succeeds but the captured output is non-empty — almost
	 * always a sign that the file is missing a cfscript wrapper, so Lucee/Adobe
	 * parse the body as markup and any cfscript-style code becomes literal
	 * output text that never executes — log a clear warning pointing the
	 * developer at the most likely cause, and discard the output so it doesn't
	 * leak into the response of whichever request happened to trigger
	 * onApplicationStart.
	 *
	 * Note for maintainers: deliberately avoids putting any literal cf-tags
	 * in this docblock — Lucee 7's tag scanner reads CFC comments before
	 * compilation and treats unclosed tags as an error.
	 *
	 * @template Mapping-relative path like "/config/services.cfm".
	 */
	public void function $includeConfig(required string template) {
		try {
			// cfformat-ignore-start
			local.resolved = $resolveGlobalIncludeTemplate(arguments.template);
			var configIncludeState = {done = false, output = ""};
			var configCaptured = "";
			try {
				savecontent variable="configCaptured" {
					include "#local.resolved#"
				};
				configIncludeState.output = configCaptured;
				configIncludeState.done = true;
			} catch (any e) {
				if (!$isMissingMappedInclude(e)) {
					rethrow;
				}
			}
			if (!configIncludeState.done) {
				var configFallbacks = $mappedIncludeFallbacks(local.resolved);
				var configFbCount = ArrayLen(configFallbacks);
				for (var configFbIndex = 1; configFbIndex <= configFbCount; configFbIndex++) {
					try {
						savecontent variable="configCaptured" {
							include "#configFallbacks[configFbIndex]#"
						};
						configIncludeState.output = configCaptured;
						configIncludeState.done = true;
						break;
					} catch (any e) {
						if (configFbIndex == configFbCount || !$isMissingMappedInclude(e)) {
							rethrow;
						}
					}
				}
			}
			local.$wheelsConfigOutput = configIncludeState.output;
			// cfformat-ignore-end
		} catch (any e) {
			// Fail closed: a compile-time or runtime failure in a config template is a
			// boot-blocking configuration error in EVERY environment. Booting anyway
			// would silently run the app on framework defaults (no DI registrations,
			// default settings, …) and serve traffic fail-open — strictly worse than
			// a hard stop. Log the offending template, then rethrow a NAMED, located
			// error that says what broke, where, and why — instead of the old masked,
			// app-wide HTTP 500 whose secondary onError failure hid the real cause
			// (the canonical trigger is Adobe CF rejecting a top-level
			// `var di = injector();` in config/services.cfm — a compile error on
			// Adobe, accepted on Lucee — issue #3063). The throw is unconditional:
			// no environment branching, no swallowed path.
			try {
				writeLog(
					file = "wheels",
					type = "error",
					text = "Wheels: " & arguments.template & " failed to compile or run during"
						& " onApplicationStart — application start was aborted (fail-closed)."
						& " Error: " & e.message
				);
			} catch (any logErr) {
				// Logging is best-effort during application start.
			}
			Throw(
				type = "Wheels.ConfigIncludeFailed",
				message = "Failed to include config template '" & arguments.template & "': " & e.message,
				detail = "Original exception type: " & e.type & "."
					& (StructKeyExists(e, "detail") && Len(e.detail) ? " " & e.detail : "")
					& " Application start was aborted because this config file could not be"
					& " loaded — fix the file and restart (booting without it would run the"
					& " application on framework defaults)."
			);
		}
		if (Len(Trim(local.$wheelsConfigOutput))) {
			local.preview = Left(Trim(local.$wheelsConfigOutput), 200);
			local.scriptOpen = Chr(60) & "cfscript" & Chr(62);
			local.scriptClose = Chr(60) & "/cfscript" & Chr(62);
			try {
				writeLog(
					file = "wheels",
					type = "warning",
					text = "Wheels: " & arguments.template & " produced output during onApplicationStart"
						& " — this almost always means the file body is missing a "
						& local.scriptOpen & "..." & local.scriptClose & " wrapper, so the engine is"
						& " parsing CFScript-style code as literal markup (registrations like"
						& " var di = injector(); never execute, and the bare lines would leak onto"
						& " every response if not captured here)."
						& " First 200 chars of captured output: " & local.preview
				);
			} catch (any e) {
				// Logging is best-effort during application start.
			}
		}
	}

	/**
	 * Rewrite `$include` templates so Application.cfc's
	 * `../../#eventPath#/onabort.cfm` (eventPath is `/app/events`) becomes
	 * the mapping-absolute `/app/events/onabort.cfm`.
	 *
	 * `"../../" & "/app/events/onabort.cfm"` concatenates to
	 * `../../../app/events/onabort.cfm`. After the DC7 split, `$include`
	 * compiled from `vendor/wheels/global/tags.cfm` resolved that against
	 * the include (or the webroot) and looked for
	 * `public/app/events/onabort.cfm` — LuCLI 1 fail / 4 error, Lucee
	 * smoke `onabort` / `onapplicationend` misses (issue ##3241). Collapse
	 * a leading `../` chain as if the include lived on this CFC
	 * (`/wheels/Global.cfc`). Mapping-absolute paths (`/app/...`,
	 * `/config/...`, `/wheels/...`) and other relative templates are
	 * unchanged except for the historical LCase.
	 */
	public string function $resolveGlobalIncludeTemplate(required string template) {
		var normalized = Replace(arguments.template, "\", "/", "all");
		if (!Len(normalized)) {
			return normalized;
		}
		if (Left(normalized, 1) == "/") {
			return LCase(normalized);
		}
		if (Left(normalized, 3) != "../") {
			return LCase(normalized);
		}
		var segments = ["wheels"];
		var parts = ListToArray(normalized, "/");
		var partCount = ArrayLen(parts);
		for (var partIndex = 1; partIndex <= partCount; partIndex++) {
			var part = parts[partIndex];
			if (!Len(part) || part == ".") {
				continue;
			}
			if (part == "..") {
				if (ArrayLen(segments)) {
					ArrayDeleteAt(segments, ArrayLen(segments));
				}
			} else {
				ArrayAppend(segments, part);
			}
		}
		if (!ArrayLen(segments)) {
			return "/";
		}
		return "/" & LCase(ArrayToList(segments, "/"));
	}

	/**
	 * True when `include` failed because a CF mapping (`/wheels`, `/app`)
	 * is gone — Adobe CF 2023 `applicationStop()` teardown — not because
	 * the template has a compile/runtime error.
	 */
	public boolean function $isMissingMappedInclude(required any exception) {
		var text = arguments.exception.message;
		if (StructKeyExists(arguments.exception, "detail") && IsSimpleValue(arguments.exception.detail)) {
			text &= " " & arguments.exception.detail;
		}
		if (FindNoCase("Could not find the included template", text)) {
			return true;
		}
		// Lucee: Page [/wheels/...] [filesystem path] not found
		if (FindNoCase("Page [", text) && FindNoCase("not found", text)) {
			return true;
		}
		return false;
	}

	/**
	 * Mapping-free include paths for a mapping-absolute template.
	 * [1] relative to this CFC (`vendor/wheels/Global.cfc`).
	 * [2] relative to the front controller (`public/index.cfm`).
	 * Pure so it can be unit-tested without applicationStop().
	 */
	public array function $mappedIncludeFallbacks(required string template) {
		var normalized = Replace(arguments.template, "\", "/", "all");
		if (!Len(normalized) || Left(normalized, 1) != "/") {
			return [];
		}
		if (Left(normalized, 8) == "/wheels/") {
			return [
				Mid(normalized, 9, Len(normalized)),
				"../vendor" & normalized
			];
		}
		return [
			"../.." & normalized,
			".." & normalized
		];
	}

	/**
	 * `include` a mapping-absolute template, then the mapping-free
	 * fallbacks when Adobe teardown has dropped THIS.mappings.
	 * Page/event includes only — cluster function files must stay as
	 * component-body includes so UDFs compile into this CFC.
	 */
	public void function $tryIncludeTemplate(required string template) {
		var resolved = arguments.template;
		var state = {done = false};
		try {
			include "#resolved#";
			state.done = true;
		} catch (any e) {
			if (!$isMissingMappedInclude(e)) {
				rethrow;
			}
		}
		if (state.done) {
			return;
		}
		var fallbacks = $mappedIncludeFallbacks(resolved);
		var fbCount = ArrayLen(fallbacks);
		if (!fbCount) {
			throw(
				type = "Wheels.MissingInclude",
				message = "Could not include template '" & resolved & "'"
			);
		}
		for (var fbIndex = 1; fbIndex <= fbCount; fbIndex++) {
			try {
				include "#fallbacks[fbIndex]#";
				return;
			} catch (any e) {
				if (fbIndex == fbCount || !$isMissingMappedInclude(e)) {
					rethrow;
				}
			}
		}
	}

	// Focused collaborators for the former Global.cfc monolith (issue ##3241).
	// Component-body includes compile into this CFC so every Global-derived
	// type (Model, Controller, Dispatch, …) inherits the helpers with no
	// per-instance mixin copy. Each include MUST be wrapped in cfscript
	// tags — an include is tag-context, so bare script would leak as
	// output (same contract as /app/global/functions.cfm).
	//
	// Mapping-absolute `/wheels/...` is the boot path. Adobe CF 2023
	// applicationStop() drops THIS.mappings before onApplicationEnd; the
	// next Global method call re-evaluates these includes and
	// `include "/wheels/global/locking.cfm"` 500s (authorized reload
	// probe, issue ##3241). Fall back to a path relative to this CFC,
	// then a path relative to public/index.cfm. Do not move these includes
	// into a method — method-body includes declare UDFs locally, not on
	// the component (see $reincludeGlobals).
	try {
		include "/wheels/global/locking.cfm";
	} catch (any e) {
		if (!$isMissingMappedInclude(e)) {
			rethrow;
		}
		try {
			include "global/locking.cfm";
		} catch (any e2) {
			if (!$isMissingMappedInclude(e2)) {
				rethrow;
			}
			include "../vendor/wheels/global/locking.cfm";
		}
	}
	try {
		include "/wheels/global/tags.cfm";
	} catch (any e) {
		if (!$isMissingMappedInclude(e)) {
			rethrow;
		}
		try {
			include "global/tags.cfm";
		} catch (any e2) {
			if (!$isMissingMappedInclude(e2)) {
				rethrow;
			}
			include "../vendor/wheels/global/tags.cfm";
		}
	}
	try {
		include "/wheels/global/settings.cfm";
	} catch (any e) {
		if (!$isMissingMappedInclude(e)) {
			rethrow;
		}
		try {
			include "global/settings.cfm";
		} catch (any e2) {
			if (!$isMissingMappedInclude(e2)) {
				rethrow;
			}
			include "../vendor/wheels/global/settings.cfm";
		}
	}
	try {
		include "/wheels/global/cache.cfm";
	} catch (any e) {
		if (!$isMissingMappedInclude(e)) {
			rethrow;
		}
		try {
			include "global/cache.cfm";
		} catch (any e2) {
			if (!$isMissingMappedInclude(e2)) {
				rethrow;
			}
			include "../vendor/wheels/global/cache.cfm";
		}
	}
	try {
		include "/wheels/global/objects.cfm";
	} catch (any e) {
		if (!$isMissingMappedInclude(e)) {
			rethrow;
		}
		try {
			include "global/objects.cfm";
		} catch (any e2) {
			if (!$isMissingMappedInclude(e2)) {
				rethrow;
			}
			include "../vendor/wheels/global/objects.cfm";
		}
	}
	try {
		include "/wheels/global/routing.cfm";
	} catch (any e) {
		if (!$isMissingMappedInclude(e)) {
			rethrow;
		}
		try {
			include "global/routing.cfm";
		} catch (any e2) {
			if (!$isMissingMappedInclude(e2)) {
				rethrow;
			}
			include "../vendor/wheels/global/routing.cfm";
		}
	}
	try {
		include "/wheels/global/strings.cfm";
	} catch (any e) {
		if (!$isMissingMappedInclude(e)) {
			rethrow;
		}
		try {
			include "global/strings.cfm";
		} catch (any e2) {
			if (!$isMissingMappedInclude(e2)) {
				rethrow;
			}
			include "../vendor/wheels/global/strings.cfm";
		}
	}
	try {
		include "/wheels/global/request.cfm";
	} catch (any e) {
		if (!$isMissingMappedInclude(e)) {
			rethrow;
		}
		try {
			include "global/request.cfm";
		} catch (any e2) {
			if (!$isMissingMappedInclude(e2)) {
				rethrow;
			}
			include "../vendor/wheels/global/request.cfm";
		}
	}
	try {
		include "/wheels/global/util.cfm";
	} catch (any e) {
		if (!$isMissingMappedInclude(e)) {
			rethrow;
		}
		try {
			include "global/util.cfm";
		} catch (any e2) {
			if (!$isMissingMappedInclude(e2)) {
				rethrow;
			}
			include "../vendor/wheels/global/util.cfm";
		}
	}
	try {
		include "/wheels/global/plugins.cfm";
	} catch (any e) {
		if (!$isMissingMappedInclude(e)) {
			rethrow;
		}
		try {
			include "global/plugins.cfm";
		} catch (any e2) {
			if (!$isMissingMappedInclude(e2)) {
				rethrow;
			}
			include "../vendor/wheels/global/plugins.cfm";
		}
	}
	try {
		include "/wheels/global/pagination.cfm";
	} catch (any e) {
		if (!$isMissingMappedInclude(e)) {
			rethrow;
		}
		try {
			include "global/pagination.cfm";
		} catch (any e2) {
			if (!$isMissingMappedInclude(e2)) {
				rethrow;
			}
			include "../vendor/wheels/global/pagination.cfm";
		}
	}
	try {
		include "/wheels/global/cors.cfm";
	} catch (any e) {
		if (!$isMissingMappedInclude(e)) {
			rethrow;
		}
		try {
			include "global/cors.cfm";
		} catch (any e2) {
			if (!$isMissingMappedInclude(e2)) {
				rethrow;
			}
			include "../vendor/wheels/global/cors.cfm";
		}
	}
	try {
		include "/wheels/global/lifecycle.cfm";
	} catch (any e) {
		if (!$isMissingMappedInclude(e)) {
			rethrow;
		}
		try {
			include "global/lifecycle.cfm";
		} catch (any e2) {
			if (!$isMissingMappedInclude(e2)) {
				rethrow;
			}
			include "../vendor/wheels/global/lifecycle.cfm";
		}
	}

	// User-defined global functions
	try {
		include "/app/global/functions.cfm";
	} catch (any e) {
		if (!$isMissingMappedInclude(e)) {
			rethrow;
		}
		try {
			include "../../app/global/functions.cfm";
		} catch (any e2) {
			if (!$isMissingMappedInclude(e2)) {
				rethrow;
			}
			include "../app/global/functions.cfm";
		}
	}

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
