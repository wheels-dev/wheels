/**
 * Defense-in-depth coverage for `mcpHiddenTools()` — the function LuCLI reads
 * to filter the MCP `tools/list` surface. Auto-discovered MCP tools include
 * every public function in Module.cfc; without an exclusion path, a
 * `$`-prefixed public helper (kept public only so unit tests can reach it —
 * the cli/CLAUDE.md "public for specs" carve-out) leaks into `tools/list`
 * verbatim, surfacing as a callable MCP tool.
 *
 * Issue #2963 / wave-2 §5.2 (Part 2) flagged this: the static denylist works
 * for the two known cases (`$normalizeTestFilter`, `$resolveAppTestDataSource`),
 * but a future `$publicHelperFour` added without a denylist update would leak.
 * The fix structurally discovers every `$`-prefixed public function via
 * `getMetaData(this)` so the exclusion is self-maintaining.
 *
 * Like every other Module.cfc spec, source-level inspection — Module extends
 * `modules.BaseModule`, which is only resolvable at LuCLI runtime, not in
 * TestBox (see UpgradeCommandSpec / MainCommandSpec).
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.moduleSource = fileRead(expandPath("/cli/lucli/Module.cfc"));
	}

	function run() {

		describe("mcpHiddenTools() — structural $-prefix exclusion (##2963)", () => {

			it("walks the module's own public functions via getMetaData(this)", () => {
				// The fix replaces the hard-coded list with reflection over
				// the module's own metadata, so adding a new $-prefixed public
				// helper can't accidentally leak as an MCP tool. Source-level:
				// the function body must call getMetaData(this) (or this.$ ...
				// → metadata-driven discovery), not just return a static array.
				var startIdx = reFindNoCase("(?m)^[ \t]*public\s+array\s+function\s+mcpHiddenTools\s*\(", variables.moduleSource);
				expect(startIdx).toBeGT(0);
				var body = mid(variables.moduleSource, startIdx, 2500);
				expect(body).toInclude("getMetaData(this)");
			});

			it("excludes every $-prefixed public function discovered in the module", () => {
				// The discovery loop must filter on the leading `$` so future
				// $publicHelper functions are auto-excluded. Match any of the
				// idiomatic prefix tests (left, mid, find/findNoCase at position 1).
				var startIdx = reFindNoCase("(?m)^[ \t]*public\s+array\s+function\s+mcpHiddenTools\s*\(", variables.moduleSource);
				expect(startIdx).toBeGT(0);
				var body = mid(variables.moduleSource, startIdx, 2500);
				// One of these prefix tests must appear inside the function
				// body. Loose match so an equivalent rewrite still passes.
				var hasLeftPrefix = reFindNoCase("left\s*\(\s*[a-zA-Z_]+\.name\s*,\s*1\s*\)\s*==\s*""\$""", body) > 0;
				var hasFindPrefix = reFindNoCase("find\s*\(\s*""\$""\s*,\s*[a-zA-Z_]+\.name\s*\)\s*==\s*1", body) > 0;
				var hasReFindPrefix = reFindNoCase("reFind(NoCase)?\s*\(\s*""\^\\\$""\s*,\s*[a-zA-Z_]+\.name\s*\)", body) > 0;
				expect(hasLeftPrefix || hasFindPrefix || hasReFindPrefix).toBeTrue();
			});

			it("keeps non-$-prefixed CLI-only commands in the hidden list", () => {
				// The structural prefix filter doesn't cover commands like
				// `start`, `stop`, `new`, `console`, `browser` — these are
				// public, non-$-prefixed, and CLI-only. They must remain in
				// the explicit denylist that the function returns. Source:
				// the literal strings still appear in the function body.
				var startIdx = reFindNoCase("(?m)^[ \t]*public\s+array\s+function\s+mcpHiddenTools\s*\(", variables.moduleSource);
				expect(startIdx).toBeGT(0);
				var body = mid(variables.moduleSource, startIdx, 2500);
				expect(body).toInclude("""start""");
				expect(body).toInclude("""stop""");
				expect(body).toInclude("""new""");
				expect(body).toInclude("""console""");
				expect(body).toInclude("""browser""");
				expect(body).toInclude("""mcp""");
			});

			it("returns an array (the LuCLI mcpHiddenTools() contract)", () => {
				// LuCLI calls mcpHiddenTools() and expects an array of
				// string names. Source-level: the return type is `array`
				// and the body returns one. Smoke test against the
				// declaration only — full integration is covered by LuCLI's
				// own tools/list invocations end-to-end.
				expect(reFindNoCase("(?m)^[ \t]*public\s+array\s+function\s+mcpHiddenTools\s*\(", variables.moduleSource)).toBeGT(0);
			});

		});

	}

}
