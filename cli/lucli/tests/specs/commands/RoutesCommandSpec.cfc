/**
 * `wheels routes --filter=` and `--format=`.
 *
 * Both flags were advertised in the wrapper's help for as long as the
 * command existed, and neither was ever read — routes() fetched every
 * route and printed the table unconditionally. Found rehearsing
 * `wheels routes --filter=posts` as a before/after for the scaffold beat:
 * it returned all 57 routes, which on stage reads as a bug.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.probe = new cli.lucli.tests._fixtures.commands.ModuleArgvProbe(
			cwd = expandPath("/")
		);
		// The shape /wheels/cli?command=routes returns, trimmed to what matters.
		variables.table = [
			{methods: "get",    pattern: "/wheels/info",       controller: "wheels.public", action: "info",   name: "wheelsInfo"},
			{methods: "get",    pattern: "/posts",             controller: "posts",         action: "index",  name: "posts"},
			{methods: "get",    pattern: "/posts/[key]",       controller: "posts",         action: "show",   name: "post"},
			{methods: "delete", pattern: "/posts/[key]",       controller: "posts",         action: "delete", name: "post"},
			{methods: "get",    pattern: "/comments/[key]",    controller: "comments",      action: "show",   name: "comment"},
			{methods: "get",    pattern: "/",                  controller: "main",          action: "index",  name: "root"}
		];
	}

	function run() {

		describe("$filterRoutes()", () => {

			it("keeps only routes whose pattern contains the text", () => {
				var kept = probe.$filterRoutesProbe(table, "posts");
				expect(arrayLen(kept)).toBe(3);
				for (var r in kept) {
					expect(r.controller).toBe("posts");
				}
			});

			it("is case-insensitive — a presenter should not have to match case", () => {
				expect(arrayLen(probe.$filterRoutesProbe(table, "POSTS"))).toBe(3);
				expect(arrayLen(probe.$filterRoutesProbe(table, "Posts"))).toBe(3);
			});

			it("matches on the route NAME, not just the pattern", () => {
				// `root` appears only in the name field.
				var kept = probe.$filterRoutesProbe(table, "root");
				expect(arrayLen(kept)).toBe(1);
				expect(kept[1].pattern).toBe("/");
			});

			it("matches on controller##action", () => {
				var kept = probe.$filterRoutesProbe(table, "comments##show");
				expect(arrayLen(kept)).toBe(1);
				expect(kept[1].controller).toBe("comments");
			});

			it("treats brackets literally — [key] is a substring, not a regex class", () => {
				// A regex would read [key] as "one of k,e,y" and match almost everything.
				var kept = probe.$filterRoutesProbe(table, "[key]");
				expect(arrayLen(kept)).toBe(3);
				for (var r in kept) {
					expect(r.pattern).toInclude("[key]");
				}
			});

			it("returns an empty array when nothing matches", () => {
				expect(arrayLen(probe.$filterRoutesProbe(table, "nomatch"))).toBe(0);
			});

			it("does not mutate the input", () => {
				var before = arrayLen(table);
				probe.$filterRoutesProbe(table, "posts");
				expect(arrayLen(table)).toBe(before);
			});

		});

		describe("routes ArgSpec", () => {

			it("defaults filter to empty and format to text", () => {
				var opts = probe.$parseRoutesArgs({});
				expect(opts.filter).toBe("");
				expect(opts.format).toBe("text");
			});

			it("reads --filter and --format from the structured handoff", () => {
				var opts = probe.$parseRoutesArgs({filter: "posts", format: "json"});
				expect(opts.filter).toBe("posts");
				expect(opts.format).toBe("json");
			});

		});

	}

}
