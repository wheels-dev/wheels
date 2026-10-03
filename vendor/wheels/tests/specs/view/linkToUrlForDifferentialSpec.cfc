/**
 * Differential (characterization) gate for #4151 linkTo()/URLFor() cost reduction. Pins the
 * EXACT output of a corpus so the optimizations (de-dup $args, literal Replace in
 * $urlForSubstituteVariables, lighter $tag) stay byte-identical. Must pass on develop unchanged.
 *
 * Two mechanisms:
 *  - End-to-end GOLDEN strings for engine-independent cases: URLFor/linkTo produce deterministic
 *    URLs, and $tag sorts attributes alphabetically (so tag output is order-stable across engines).
 *    These guard the de-dup-$args (W1) call-flow change and the $tag (W3) change.
 *  - A verbatim REFERENCE COPY of $urlForSubstituteVariables ($refSubstituteVariables) with a
 *    sub-corpus that INCLUDES regex-backref values (\1, $1) in a pattern variable: that behaviour
 *    is engine-specific (no capture groups → empty/literal/error per engine), so we assert the
 *    live function equals the reference on THIS engine rather than a fixed golden. Guards the
 *    literal-Replace (W2) change.
 */
component extends="wheels.WheelsTest" {

	function run() {
		g = application.wo;

		describe("linkTo/URLFor differential (4151)", () => {

			it("end-to-end output stays byte-identical across the corpus, cached and uncached", () => {
				var c = g.controller(name = "dummy");

				var cases = {};
				cases["url_ctrl_action_key"] = () => c.URLFor(controller = "posts", action = "edit", key = 1);
				cases["url_route_root"]      = () => c.URLFor(route = "root");
				cases["url_params"]          = () => c.URLFor(controller = "posts", action = "index", params = "a=1&b=two");
				cases["url_format"]          = () => c.URLFor(controller = "posts", action = "show", key = 1, params = "format=json");
				cases["url_anchor"]          = () => c.URLFor(controller = "posts", action = "show", key = 1, anchor = "comments");
				cases["url_composite_key"]   = () => c.URLFor(controller = "posts", action = "show", key = "1,2");
				cases["url_encode_on"]       = () => c.URLFor(controller = "posts", action = "index", params = "q=a b&x=y", encode = true);
				cases["url_encode_off"]      = () => c.URLFor(controller = "posts", action = "index", params = "q=a b", encode = false);
				cases["link_basic"]          = () => c.linkTo(text = "Edit", controller = "posts", action = "edit", key = 1);
				cases["link_class_anchor"]   = () => c.linkTo(text = "Go", controller = "posts", action = "show", key = 1, anchor = "c", class = "btn", rel = "x");
				cases["link_href"]           = () => c.linkTo(text = "Ext", href = "/raw/path?x=1");
				var attrs5 = {id = "n1", class = "btn", "data-x" = "1", "data-y" = "2", title = "t", href = "/p/1"};
				cases["element_5attrs"]      = () => c.$element(name = "a", skip = "", content = "X", attributes = attrs5, encode = true, encodeExcept = "href");
				var attrsSkip = {id = "n2", class = "c", wheelsInternal = "hide", wheelsFoo = "hide2", href = "/p/2"};
				cases["element_skipstarting"] = () => c.$element(name = "a", skip = "", skipStartingWith = "wheels", content = "Y", attributes = attrsSkip, encode = true, encodeExcept = "href");

				var golden = goldenMap();
				var appKey = g.$appKey();
				var clearCache = () => {
					if (StructKeyExists(application[appKey], "urlForCache")) { StructClear(application[appKey].urlForCache); }
				};

				var capture = StructKeyExists(url, "capture") && url.capture;
				for (var name in cases) {
					clearCache();
					var uncached = cases[name]();
					var cached = cases[name]();
					if (capture) {
						debug(var = "GOLD|#name#|" & uncached, label = "capture");
						expect(Compare(uncached, cached)).toBe(0, "#name#: cached != uncached");
					} else {
						expect(uncached).toBe(golden[name], "#name# uncached diverged");
						expect(cached).toBe(golden[name], "#name# cached diverged");
						// W1 guard: the internal $argsResolved sentinel must never leak into output.
						expect(uncached).notToInclude("$argsResolved", "#name#: $argsResolved leaked into output");
					}
				}
			});

			it("the de-dup ($argsResolved) is output-neutral, including app-level URLFor overrides (W1)", () => {
				var c = g.controller(name = "dummy");
				// URLFor called with $argsResolved=true (linkTo's path, skipping the generic $args)
				// must produce byte-identical output to $argsResolved=false (the full $args path),
				// because the else-branch still applies application.wheels.functions.URLFor.
				var probe = (resolved) => c.URLFor(controller = "posts", action = "index", params = "q=a b&x=y", encode = true, "$argsResolved" = resolved);
				expect(probe(true)).toBe(probe(false), "de-dup changed URLFor output");

				// Same equivalence with an app-level override on a framework default (no signature
				// default, so it is actually applied via structAppendDefaults) — proving the override
				// reaches both paths identically after the de-dup.
				var prev = StructCopy(application.wheels.functions.URLFor);
				try {
					application.wheels.functions.URLFor.encode = false;
					expect(probe(true)).toBe(probe(false), "URLFor override not applied identically with de-dup");
				} finally {
					application.wheels.functions.URLFor = prev;
				}

				// The internal sentinel must never surface in linkTo output.
				var link = c.linkTo(text = "x", controller = "posts", action = "edit", key = 1);
				expect(link).notToInclude("argsResolved", "sentinel leaked into linkTo output");
			});

			it("$urlForSubstituteVariables stays identical to its pre-optimization reference (incl regex backrefs)", () => {
				var c = g.controller(name = "dummy");
				variables.ref = c;

				// Each probe: {rv, args, foundVariables, route}. Keys cover plain, encoded, and the
				// per-engine backref values (\1 / $1) in a pattern variable.
				var probes = [
					{rv = "/posts/[controller]/[action]/[key]", args = {route = "", controller = "posts", action = "edit", key = "7", format = "", params = "", encode = false, "$encodeForHtmlAttribute" = false, "$URLRewriting" = "On"}},
					{rv = "/p/[key]", args = {route = "", controller = "", action = "", key = "a\1b", format = "", params = "", encode = false, "$encodeForHtmlAttribute" = false, "$URLRewriting" = "On"}},
					{rv = "/p/[key]", args = {route = "", controller = "", action = "", key = "a$1b", format = "", params = "", encode = false, "$encodeForHtmlAttribute" = false, "$URLRewriting" = "On"}},
					{rv = "/p/[key]", args = {route = "", controller = "", action = "", key = "a b", format = "", params = "", encode = true, "$encodeForHtmlAttribute" = false, "$URLRewriting" = "On"}},
					{rv = "?controller=[controller]&action=[action]&key=[key]&format=[format]", args = {route = "", controller = "posts", action = "edit", key = "7", format = "", params = "", encode = false, "$encodeForHtmlAttribute" = false, "$URLRewriting" = "Off"}}
				];
				var fv = "controller,action,key,format";
				for (var p in probes) {
					var liveArgs = StructCopy(p.args);
					var refArgs = StructCopy(p.args);
					var live = c.$urlForSubstituteVariables(rv = p.rv, args = liveArgs, foundVariables = fv, coreVariables = fv, route = {});
					var reference = $refSubstituteVariables(rv = p.rv, args = refArgs, foundVariables = fv, coreVariables = fv, route = {});
					expect(live).toBe(reference, "substituteVariables diverged for key=[" & p.args.key & "]");
					// the params side-effect must match too
					expect(liveArgs.params).toBe(refArgs.params, "substituteVariables params side-effect diverged for key=[" & p.args.key & "]");
				}
			});

		});
	}

	// Engine-independent goldens captured from develop (the backref cases are covered by the
	// reference-copy test above, not here, because their output is engine-specific).
	private struct function goldenMap() {
		return {
			url_ctrl_action_key = "/posts/edit/1",
			url_route_root = "/",
			url_params = "/posts/index?a=1&b=two",
			url_format = "/posts/show/1?format=json",
			url_anchor = "/posts/show/1##comments",
			url_composite_key = "/posts/show/1%2C2",
			url_encode_on = "/posts/index?q=a+b&x=y",
			url_encode_off = "/posts/index?q=a b",
			link_basic = "<a href=""/posts/edit/1"">Edit</a>",
			link_class_anchor = "<a class=""btn"" href=""/posts/show/1##c"" rel=""x"">Go</a>",
			link_href = "<a href=""&##x2f;raw&##x2f;path&##x3f;x&##x3d;1"">Ext</a>",
			element_5attrs = "<a class=""btn"" data-x=""1"" data-y=""2"" href=""/p/1"" id=""n1"" title=""t"">X</a>",
			element_skipstarting = "<a class=""c"" href=""/p/2"" id=""n2"">Y</a>"
		};
	}

	// Verbatim copy of develop's $urlForSubstituteVariables (global/routing.cfm). The live function
	// is optimized in W2; this frozen copy is the byte-identical oracle. $-helpers resolve through
	// variables.ref (the controller context).
	private string function $refSubstituteVariables(required string rv, required struct args, required string foundVariables, required string coreVariables, required struct route) {
		local.rv = arguments.rv;
		for (local.i = 1; local.i <= ListLen(arguments.foundVariables); local.i++) {
			local.property = ListGetAt(arguments.foundVariables, local.i);
			local.reg = "\[\*?#local.property#\]";
			if (StructKeyExists(arguments.args, local.property) && Len(arguments.args[local.property])) {
				local.value = arguments.args[local.property];
			} else if (StructKeyExists(arguments.route, local.property)) {
				local.value = arguments.route[local.property];
			} else if (Len(arguments.args.route) && arguments.args.$URLRewriting != "Off") {
				Throw(type = "Wheels.IncorrectRoutingArguments", message = "Incorrect Arguments");
			} else {
				continue;
			}
			if (IsObject(local.value)) {
				local.value = local.value.key();
			}
			local.rawValue = local.value;
			if (arguments.args.encode && variables.ref.$get("encodeURLs")) {
				local.value = variables.ref.$encodeUrlParam(local.value);
				if (arguments.args.$encodeForHtmlAttribute) {
					local.value = EncodeForHTMLAttribute(local.value);
				}
			}
			if (!ReFind(local.reg, local.rv)) {
				if (!ListFindNoCase(arguments.coreVariables, local.property)) {
					if (arguments.args.encode && variables.ref.$get("encodeURLs")) {
						local.rawValue = Replace(Replace(local.rawValue, "&", "%26", "all"), "=", "%3D", "all");
					}
					arguments.args.params = ListAppend(arguments.args.params, "#local.property#=#local.rawValue#", "&");
				}
				continue;
			}
			if (local.property == "controller" || local.property == "action") {
				local.value = variables.ref.hyphenize(local.value);
			} else if (application.wheels.obfuscateUrls) {
				local.value = variables.ref.obfuscateParam(local.value);
			}
			local.rv = ReReplace(local.rv, local.reg, local.value);
		}
		return local.rv;
	}
}
