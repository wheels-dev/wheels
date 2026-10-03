/**
 * $findMatchingRoute() scans only the routes that can match the request: those
 * whose method allows it and whose first path segment is the request's first
 * segment, plus routes whose first segment is a variable (#4157). These specs
 * pin that the index never changes WHICH route matches: a differential run
 * against a reference copy of the linear scan it replaced, over a corpus
 * generated from a 300+ route table, must agree on every route, captured group
 * and error message.
 */
component extends="wheels.WheelsTest" {

	function beforeAll() {
		_originalRoutes = Duplicate(application.wheels.routes);
		_originalStaticRoutes = StructKeyExists(application.wheels, "staticRoutes") ? StructCopy(application.wheels.staticRoutes) : {};
		_originalNamedRoutePositions = StructKeyExists(application.wheels, "namedRoutePositions") ? StructCopy(application.wheels.namedRoutePositions) : {};
		$buildFixtureTable();
		d = application.wo.$createObjectFromRoot(path = "wheels", fileName = "Dispatch", method = "$init");
	}

	function afterAll() {
		application.wheels.routes = _originalRoutes;
		application.wheels.staticRoutes = _originalStaticRoutes;
		application.wheels.namedRoutePositions = _originalNamedRoutePositions;
	}

	function run() {

		describe("Route index ($findMatchingRoute)", () => {

			it("matches exactly what the linear scan matched, over a corpus generated from the route table", () => {
				var corpus = $corpus();
				var mismatches = [];
				for (var c in corpus) {
					var expected = $referenceScan(c.path, c.method);
					var actual = $indexedScan(c.path, c.method);
					if (expected != actual) {
						ArrayAppend(mismatches, c.method & " /" & c.path & " | linear=" & expected & " | indexed=" & actual);
					}
				}
				expect(ArrayLen(application.wheels.routes)).toBeGT(300, "the fixture table must exceed the size where the scan cost shows");
				expect(ArrayLen(corpus)).toBeGT(1000);
				var shown = ArrayLen(mismatches) ? ArrayToList(ArraySlice(mismatches, 1, Min(5, ArrayLen(mismatches))), Chr(10)) : "";
				expect(ArrayLen(mismatches)).toBe(0, shown);
			});

			it("scans a small, declaration-ordered subset of the table for a dynamic path", () => {
				var candidates = d.$dynamicRouteCandidates(routes = application.wheels.routes, method = "GET", path = "admin/dogs/12/comments");
				var total = ArrayLen(application.wheels.routes);
				expect(ArrayLen(candidates)).toBeGT(0);
				expect(ArrayLen(candidates)).toBeLT(total / 4);
				for (var i = 2; i <= ArrayLen(candidates); i++) {
					expect(candidates[i]).toBeGT(candidates[i - 1], "candidates must stay in declaration order");
				}
			});

			it("never serves a stale index after the route table is replaced with one of the same size", () => {
				var saved = {
					routes = application.wheels.routes,
					staticRoutes = application.wheels.staticRoutes,
					named = application.wheels.namedRoutePositions
				};
				try {
					$clearRoutes();
					application.wo.mapper().get(name = "alphaThing", pattern = "alpha/[key]", to = "alpha##show").end();
					expect(d.$findMatchingRoute(path = "alpha/1", requestMethod = "GET").name).toBe("alphaThing");

					// Same route count, different content: the index must be rebuilt.
					$clearRoutes();
					application.wo.mapper().get(name = "betaThing", pattern = "beta/[key]", to = "beta##show").end();
					expect(d.$findMatchingRoute(path = "beta/1", requestMethod = "GET").name).toBe("betaThing");
					expect(() => {
						d.$findMatchingRoute(path = "alpha/1", requestMethod = "GET");
					}).toThrow("Wheels.RouteNotFound");
				} finally {
					application.wheels.routes = saved.routes;
					application.wheels.staticRoutes = saved.staticRoutes;
					application.wheels.namedRoutePositions = saved.named;
				}
			});

			it("keeps the exact-path static index ahead of an earlier placeholder route (##3073)", () => {
				expect(d.$findMatchingRoute(path = "dogs/featured", requestMethod = "GET").name).toBe("featuredDogs");
			});
		});
	}

	// ---- fixture -----------------------------------------------------------------

	private void function $buildFixtureTable() {
		$clearRoutes();
		var nouns = ["dogs", "cats", "pigs", "pages", "charts", "tabs", "cows", "products", "pictures", "cars", "bikes", "books", "coats", "plates", "users"];
		var noun = "";
		var m = application.wo.mapper();
		m.namespace("admin");
		for (noun in nouns) {
			m.resources(name = noun, nested = true)
				.resources(name = "comments", shallow = true)
				.end();
		}
		m.end();
		for (noun in nouns) {
			m.resources(noun);
		}
		m.get(name = "search", pattern = "search/[q]", to = "search##show")
			.get(name = "archive", pattern = "archive/[year]/[month]", to = "archive##show", constraints = {year = "\d{4}", month = "\d{1,2}"})
			.get(name = "featuredDogs", pattern = "dogs/featured", to = "dogs##featured")
			.get(name = "feed", pattern = "feed.xml", to = "feed##show")
			.post(name = "webhook", pattern = "hooks/[provider]", to = "hooks##create")
			.wildcard()
			.root(to = "home##index", method = "get")
			.end();
	}

	public void function $clearRoutes() {
		application.wheels.routes = [];
		application.wheels.staticRoutes = {};
		application.wheels.namedRoutePositions = {};
	}

	// ---- the two arms ----------------------------------------------------------------

	private string function $indexedScan(required string path, required string method) {
		try {
			var r = d.$findMatchingRoute(path = arguments.path, requestMethod = arguments.method);
			return $identity(r, StructKeyExists(r, "regexMatch") ? r.regexMatch : {});
		} catch (any e) {
			return "ERR:" & e.type & ":" & e.message;
		}
	}

	/**
	 * Reference: the linear scan $findMatchingRoute() used before the index, kept
	 * verbatim in its matching decisions (static index first, HEAD as GET, every
	 * route in declaration order, the two 404 messages).
	 */
	private string function $referenceScan(required string path, required string method) {
		var requestMethod = arguments.method == "HEAD" ? "GET" : arguments.method;
		var methodKey = UCase(requestMethod);
		var routes = application.wheels.routes;
		var route = {};
		var match = {};
		var staticKey = "";
		var alternatives = "";
		try {
			if (StructKeyExists(application.wheels, "staticRoutes")) {
				staticKey = methodKey & ":/" & arguments.path;
				if (StructKeyExists(application.wheels.staticRoutes, staticKey)) {
					return $identity(application.wheels.staticRoutes[staticKey], {});
				}
				if (!Len(arguments.path) && StructKeyExists(application.wheels.staticRoutes, methodKey & ":/")) {
					return $identity(application.wheels.staticRoutes[methodKey & ":/"], {});
				}
			}
			for (route in routes) {
				if (StructKeyExists(route, "methods") && !ListFindNoCase(route.methods, requestMethod)) {
					continue;
				}
				if (!StructKeyExists(route, "regex")) {
					route.regex = application.wheels.mapper.$patternToRegex(route.pattern);
				}
				match = ReFindNoCase(route.regex, arguments.path, 1, true);
				if (match.pos[1] > 0 || (!Len(arguments.path) && route.pattern == "/")) {
					return $identity(route, match);
				}
			}
			alternatives = "";
			for (route in routes) {
				if (ReFindNoCase(route.regex, arguments.path) || (!Len(arguments.path) && route.pattern == "/")) {
					alternatives = ListAppend(alternatives, route.methods);
				}
			}
			if (Len(alternatives)) {
				Throw(type = "Wheels.RouteNotFound", message = "Incorrect HTTP Verb for route");
			}
			Throw(type = "Wheels.RouteNotFound", message = "Could not find a route that matched this request.");
		} catch (any e) {
			return "ERR:" & e.type & ":" & e.message;
		}
	}

	private string function $identity(required struct route, required struct match) {
		var groups = "";
		if (StructKeyExists(arguments.match, "pos")) {
			for (var i = 1; i <= ArrayLen(arguments.match.pos); i++) {
				groups &= arguments.match.pos[i] & ":" & arguments.match.len[i] & ";";
			}
		}
		return (arguments.route.name ?: "") & "|" & arguments.route.pattern & "|" & (arguments.route.methods ?: "") & "|" & groups;
	}

	/**
	 * Every pattern instantiated, plus trailing-slash, case and `.json` variants and
	 * 404 paths, each with GET, HEAD, OPTIONS, POST, PUT, PATCH, DELETE and an
	 * unknown verb.
	 */
	private array function $corpus() {
		var paths = {};
		var route = {};
		var p = "";
		var m = "";
		var corpus = [];
		for (route in application.wheels.routes) {
			p = route.pattern;
			if (Find("[*", p)) {
				continue;
			}
			p = ReReplace(p, "\[format\]", "json", "all");
			p = ReReplace(p, "\[controller\]", "widgets", "all");
			p = ReReplace(p, "\[action\]", "show", "all");
			p = ReReplace(p, "\[year\]", "2026", "all");
			p = ReReplace(p, "\[month\]", "10", "all");
			p = ReReplace(p, "\[[A-Za-z]*[kK]ey\]", "12", "all");
			p = ReReplace(p, "\[[^\]]+\]", "abc", "all");
			p = ReReplace(p, "^/+", "");
			paths[p] = true;
			if (Len(p)) {
				paths[p & "/"] = true;
				paths[UCase(Left(p, 1)) & Mid(p, 2, Len(p))] = true;
				paths[p & ".json"] = true;
			}
		}
		for (p in ["nope/1/2/3", "archive/26/10", "dogs/12/comments/3/4/5", "zz9.json", "admin"]) {
			paths[p] = true;
		}
		for (p in paths) {
			for (m in ["GET", "HEAD", "OPTIONS", "POST", "PUT", "PATCH", "DELETE", "PROPFIND"]) {
				ArrayAppend(corpus, {path = p, method = m});
			}
		}
		return corpus;
	}
}
