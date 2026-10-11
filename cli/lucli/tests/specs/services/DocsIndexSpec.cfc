/**
 * services.DocsIndex: the offline docs/API lookup behind `wheels lookup`.
 *
 * Runs against a small fixture index with the same shape
 * tools/build/scripts/build-docs-index.mjs writes (that builder has its own
 * node tests): API entries (one per function, with parameters and an example)
 * and guide entries (one per ## / ### section).
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.fixture = GetDirectoryFromPath(GetCurrentTemplatePath()) & "../../_fixtures/docs-index/docs-index.json";
		variables.index = new cli.lucli.services.DocsIndex(variables.fixture);
	}

	private array function ids(required array items) {
		var rv = [];
		for (var item in arguments.items) {
			ArrayAppend(rv, item.id);
		}
		return rv;
	}

	private string function thrownType(required any fn) {
		var state = {type: ""};
		try {
			arguments.fn();
		} catch (any e) {
			state.type = e.type;
		}
		return state.type;
	}

	function run() {

		describe("DocsIndex (wheels lookup)", () => {

			it("reports a missing index file", () => {
				expect(new cli.lucli.services.DocsIndex(variables.fixture & ".missing").exists()).toBeFalse();
				expect(index.exists()).toBeTrue();
			});

			it("reports which framework version, API JSON and guides tree it was built from", () => {
				var meta = index.meta();
				expect(meta.frameworkVersion).toBe("4.2.0");
				expect(meta.apiSource).toBe("v4.2.0.json");
				expect(meta.guidesSlug).toBe("v4-2-0");
			});

			it("returns the full API entry for an exact function name", () => {
				var rv = index.lookup("findAll");
				expect(rv.mode).toBe("exact");
				expect(ids(rv.entries)).toBe(["api:model.findAll"]);
				expect(rv.entries[1].params[1].name).toBe("where");
				expect(rv.entries[1].example).toInclude("findAll(");
			});

			it("matches a name case-insensitively, with or without () or a scope", () => {
				expect(ids(index.lookup("FINDALL()").entries)).toBe(["api:model.findAll"]);
				expect(ids(index.lookup("model.findAll").entries)).toBe(["api:model.findAll"]);
				expect(index.lookup("mapper.findAll").mode).toBe("search");
			});

			it("lists every scope a name exists in", () => {
				var rv = index.lookup("delete");
				expect(rv.mode).toBe("exact");
				expect(ArrayLen(rv.entries)).toBe(2);
				expect(ids(rv.entries)).toInclude("api:model.delete");
				expect(ids(rv.entries)).toInclude("api:mapper.delete");
				expect(ids(index.lookup("mapper.delete").entries)).toBe(["api:mapper.delete"]);
			});

			it("ranks a guide section whose heading matches a phrase first", () => {
				var rv = index.lookup("nested resources");
				expect(rv.mode).toBe("search");
				expect(rv.results[1].id).toBe("guides:basics/routing##nested-resources");
				expect(rv.results[1].url).toBe("https://guides.wheels.dev/v4-2-0/basics/routing/##nested-resources");
				expect(rv.results[1].title).toBe("Routing › Nested resources");
				expect(rv.results[1].snippet).toInclude("Nest one resource");
			});

			it("finds API entries by words in their hint", () => {
				var rv = index.lookup("HTTP DELETE method", "api");
				expect(rv.results[1].id).toBe("api:mapper.delete");
				expect(rv.results[1].title).toBe("delete()");
			});

			it("filters by kind", () => {
				for (var r in index.lookup("records", "api", 20).results) {
					expect(r.kind).toBe("api");
				}
				var guides = index.lookup("findAll", "guides");
				expect(guides.mode).toBe("search");
				expect(ids(guides.results)).toBe(["guides:basics/reading-records##finding-many"]);
			});

			it("returns at most limit results, and never more than 20", () => {
				expect(ArrayLen(index.lookup("the", "all", 2).results)).toBe(2);
				expect(index.lookup("the", "all", 500).limit).toBe(20);
				expect(index.lookup("the", "all", 0).limit).toBe(1);
			});

			it("returns the whole entry for an id from an earlier result", () => {
				var rv = index.lookup("guides:basics/routing##nested-resources");
				expect(rv.mode).toBe("id");
				expect(rv.entries[1].text).toInclude("callback=function(map)");
				expect(ids(index.lookup("api:mapper.resources").entries)).toBe(["api:mapper.resources"]);
				expect(index.lookup("api:model.nothingLikeThis").entries).toBe([]);
			});

			it("returns no results for a query nothing matches", () => {
				var rv = index.lookup("zzqx nothingmatches");
				expect(rv.mode).toBe("search");
				expect(rv.results).toBe([]);
			});

			it("refuses an unknown kind or an empty query", () => {
				expect(thrownType(() => index.lookup("findAll", "blog"))).toBe("Wheels.InvalidArguments");
				expect(thrownType(() => index.lookup("   "))).toBe("Wheels.InvalidArguments");
			});

		});

	}

}
