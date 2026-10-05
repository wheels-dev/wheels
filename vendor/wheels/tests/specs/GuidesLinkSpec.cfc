component extends="wheels.WheelsTest" {

	/*
	 * Guide links in framework and CLI messages are built from the running version
	 * instead of a hard-coded guides.wheels.dev/v4-0-0/ (#3931), clamped to the
	 * guide trees that exist.
	 */
	function run() {

		describe("wheels.GuidesLink", () => {

			beforeEach(() => {
				guides = new wheels.GuidesLink();
				latestSegment = "v" & Replace(guides.latestVersion(), ".", "-") & "-0";
				docsRoot = ExpandPath("/wheels/../..") & "/web/sites/guides/src/content/docs/";
			});

			it("uses the running minor version", () => {
				expect(guides.segment("4.0.6")).toBe("v4-0-0");
				expect(guides.segment("4.1.3")).toBe("v4-1-0");
				expect(guides.segment("4.1.3-snapshot.12")).toBe("v4-1-0");
			});

			it("never links to a version whose guides aren't cut yet", () => {
				expect(guides.segment("9.9.0")).toBe(latestSegment);
			});

			it("never links older than the 4.0 guides", () => {
				expect(guides.segment("3.0.0")).toBe("v4-0-0");
			});

			it("uses the latest guides for an unknown or dev version", () => {
				expect(guides.segment("")).toBe(latestSegment);
				expect(guides.segment("0.0.0-dev")).toBe(latestSegment);
				expect(guides.segment("@build.version@")).toBe(latestSegment);
			});

			it("builds a full URL", () => {
				expect(guides.link("upgrading/", "4.0.1")).toBe("https://guides.wheels.dev/v4-0-0/upgrading/");
			});

			it("links to a guide tree that exists", () => {
				$requireRepoPath("web/sites/guides/src/content/docs");
				expect(DirectoryExists(docsRoot & latestSegment)).toBeTrue("missing guides tree " & latestSegment);
			});

			it("is not behind the newest guide tree, released or in development", () => {
				$requireRepoPath("web/sites/guides/src/content/docs");
				// When a version's guides tree is cut, bump variables.latest in
				// vendor/wheels/GuidesLink.cfc and cli/lucli/services/GuidesLink.cfc.
				// A tree still marked 'snapshot' counts too: the code on that branch
				// ships as that minor, and an upgrade check for it must link that
				// minor's upgrading/ page, which older trees don't have.
				var ahead = $treesAheadOfLatest(DirectoryList(docsRoot, false, "name"), guides);
				expect(ArrayLen(ahead)).toBe(0, "guide tree(s) newer than GuidesLink's latest (#guides.latestVersion()#): #ArrayToList(ahead)#");
			});

			it("flags a guide tree one minor ahead of latest", () => {
				var next = "v" & ListFirst(guides.latestVersion(), ".") & "-" & (ListLast(guides.latestVersion(), ".") + 1) & "-0";
				expect($treesAheadOfLatest([next], guides)).toBe([next]);
				expect(ArrayLen($treesAheadOfLatest([latestSegment, "v4-0-0", "index.mdx"], guides))).toBe(0);
			});

			it("links an upgrade to the latest minor to that minor's upgrade guide", () => {
				$requireRepoPath("web/sites/guides/src/content/docs");
				var target = guides.latestVersion() & ".0";
				expect(guides.segment(target)).toBe(latestSegment);
				expect(DirectoryExists(docsRoot & latestSegment & "/upgrading")).toBeTrue("missing #latestSegment#/upgrading");
			});

			it("matches the CLI's copy", () => {
				$requireRepoPath("web/sites/guides/src/content/docs");
				var cliSource = FileRead(ExpandPath("/wheels/../..") & "/cli/lucli/services/GuidesLink.cfc");
				expect(cliSource).toInclude('variables.latest = "#guides.latestVersion()#"');
			});

			it("pins only allowlisted pages, and each exists in its pinned tree", () => {
				$requireRepoPath("web/sites/guides/src/content/docs");
				var root = ExpandPath("/wheels/../..") & "/";
				var allowed = $pinnedPages();
				var found = 0;
				// Every CLI component, not just the two that build GuidesLink today,
				// so a pinned() added in another service is checked too. The CLI's
				// own specs are skipped: a fixture may quote a pinned() call.
				for (var path in DirectoryList(root & "cli/lucli", true, "path", "*.cfc")) {
					if (ReFind("[\\/]cli[\\/]lucli[\\/]tests[\\/]", path)) {
						continue;
					}
					var file = ReplaceNoCase(path, root, "");
					for (var call in ReMatch('pinned\(\s*"v[0-9]+-[0-9]+-0"\s*,\s*"[a-z0-9/_-]+"', FileRead(path))) {
						var parts = ReMatch('"[^"]+"', call);
						var entry = ReReplace(parts[1], '"', "", "all") & "/" & ReReplace(ReReplace(parts[2], '"', "", "all"), "/$", "");
						found++;
						expect(ArrayFindNoCase(allowed, entry)).toBeGT(0, "#file# pins #entry#, which isn't in $pinnedPages()");
						var base = docsRoot & entry;
						expect(FileExists(base & ".mdx") || FileExists(base & "/index.mdx")).toBeTrue("missing pinned page #entry#");
					}
				}
				expect(found).toBe(ArrayLen(allowed), "an allowlisted pinned page is no longer used");
			});

			it("links only to pages that exist in every tree it can resolve to", () => {
				$requireRepoPath("web/sites/guides/src/content/docs");
				var pages = $linkedPages();
				expect(ArrayLen(pages)).toBeGT(5, "the source scan found too few GuidesLink calls");
				for (var tree in ["v4-0-0", latestSegment]) {
					for (var page in pages) {
						var base = docsRoot & tree & "/" & page;
						expect(FileExists(base & ".mdx") || FileExists(base & "/index.mdx")).toBeTrue("missing #tree#/#page#");
					}
				}
			});
		});
	}

	// Pages linked with the CLI's GuidesLink.pinned(tree, path): fixed to one
	// tree because the page exists only there, so link()'s clamping would
	// 404. Each entry needs its reason here.
	private array function $pinnedPages() {
		return [
			// The 4.1 -> 4.2 upgrade guide is only in the 4.2 docs. `wheels
			// upgrade check` links it for an upgrade into 4.2 (#4236).
			"v4-2-0/upgrading/4x-1-to-4x-2",
			// The 4.0 -> 4.1 upgrade guide isn't in the v4-0-0 docs. `wheels
			// upgrade check` links it for the public/Application.cfc fixes it
			// documents.
			"v4-1-0/upgrading/4x-0-to-4x-1"
		];
	}

	// Guide trees (vN-M-0 directory names) newer than GuidesLink's latest.
	private array function $treesAheadOfLatest(required array dirs, required any guides) {
		var ahead = [];
		for (var dir in arguments.dirs) {
			var m = ReFind("^v([0-9]+)-([0-9]+)-0$", dir, 1, true);
			if (m.pos[1] > 0) {
				var tree = Mid(dir, m.pos[2], m.len[2]) & "." & Mid(dir, m.pos[3], m.len[3]);
				if (arguments.guides.$compareMinor(tree, arguments.guides.latestVersion()) > 0) {
					ArrayAppend(ahead, dir);
				}
			}
		}
		return ahead;
	}

	// Every guides path passed to GuidesLink.link() as a literal in the files
	// that build guide links, plus the upgrade check's computed path.
	private array function $linkedPages() {
		var root = ExpandPath("/wheels/../..") & "/";
		var files = [
			"vendor/wheels/Plugins.cfc",
			"vendor/wheels/Test.cfc",
			"vendor/wheels/public/mcp/McpServer.cfc",
			"vendor/wheels/public/views/mcp.cfm",
			"cli/lucli/Module.cfc",
			"cli/lucli/services/Doctor.cfc"
		];
		var pages = ["upgrading/3x-to-4x", "upgrading/2x-to-3x"];
		for (var file in files) {
			for (var call in ReMatch('link\(\s*"[a-z0-9/_-]+"', FileRead(root & file))) {
				var page = ReReplace(ReReplace(call, '^link\(\s*"', ""), '/?"$', "");
				if (!ArrayFindNoCase(pages, page)) {
					ArrayAppend(pages, page);
				}
			}
		}
		return pages;
	}

}
