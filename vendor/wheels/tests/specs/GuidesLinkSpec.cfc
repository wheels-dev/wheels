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
				expect(DirectoryExists(docsRoot & latestSegment)).toBeTrue("missing guides tree " & latestSegment);
			});

			it("is not behind the newest released guide tree", () => {
				// When a version's guides are released, bump variables.latest in
				// vendor/wheels/GuidesLink.cfc and cli/lucli/services/GuidesLink.cfc.
				// A tree marked status 'snapshot' in versions.ts (in development) is
				// allowed to be newer: links don't point at unreleased guides.
				var ahead = $treesAheadOfLatest(DirectoryList(docsRoot, false, "name"), $snapshotSlugs(), guides);
				expect(ArrayLen(ahead)).toBe(0, "released guide tree(s) newer than GuidesLink's latest (#guides.latestVersion()#): #ArrayToList(ahead)#");
			});

			it("lets a newer snapshot tree pass and still fails a newer released tree", () => {
				var next = "v" & ListFirst(guides.latestVersion(), ".") & "-" & (ListLast(guides.latestVersion(), ".") + 1) & "-0";
				expect(ArrayLen($treesAheadOfLatest([next], [next], guides))).toBe(0);
				expect($treesAheadOfLatest([next], [], guides)).toBe([next]);
			});

			it("reads the snapshot status from versions.ts", () => {
				var source = FileRead(ExpandPath("/wheels/../..") & "/web/packages/ui/src/data/versions.ts");
				for (var slug in $snapshotSlugs()) {
					expect(ReFind("slug: '#slug#'[^}]*status: 'snapshot'", source)).toBeGT(0);
				}
			});

			it("matches the CLI's copy", () => {
				var cliSource = FileRead(ExpandPath("/wheels/../..") & "/cli/lucli/services/GuidesLink.cfc");
				expect(cliSource).toInclude('variables.latest = "#guides.latestVersion()#"');
			});

			it("pins only allowlisted pages, and each exists in its pinned tree", () => {
				var root = ExpandPath("/wheels/../..") & "/";
				var allowed = $pinnedPages();
				var found = 0;
				for (var file in ["cli/lucli/Module.cfc", "cli/lucli/services/Doctor.cfc"]) {
					for (var call in ReMatch('pinned\(\s*"v[0-9]+-[0-9]+-0"\s*,\s*"[a-z0-9/_-]+"', FileRead(root & file))) {
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

	// Guide trees (vN-M-0 directory names) newer than GuidesLink's latest that
	// are not marked 'snapshot'.
	private array function $treesAheadOfLatest(required array dirs, required array snapshotSlugs, required any guides) {
		var ahead = [];
		for (var dir in arguments.dirs) {
			var m = ReFind("^v([0-9]+)-([0-9]+)-0$", dir, 1, true);
			if (m.pos[1] > 0 && !ArrayFindNoCase(arguments.snapshotSlugs, dir)) {
				var tree = Mid(dir, m.pos[2], m.len[2]) & "." & Mid(dir, m.pos[3], m.len[3]);
				if (arguments.guides.$compareMinor(tree, arguments.guides.latestVersion()) > 0) {
					ArrayAppend(ahead, dir);
				}
			}
		}
		return ahead;
	}

	// Slugs that versions.ts lists in GUIDES_VERSIONS with status 'snapshot'.
	private array function $snapshotSlugs() {
		var source = FileRead(ExpandPath("/wheels/../..") & "/web/packages/ui/src/data/versions.ts");
		var start = Find("GUIDES_VERSIONS", source);
		var block = Mid(source, start, Find("];", source, start) - start);
		var slugs = [];
		for (var entry in ReMatch("\{[^}]*\}", block)) {
			if (Find("status: 'snapshot'", entry)) {
				var m = ReFind("slug: '([^']+)'", entry, 1, true);
				if (m.pos[1] > 0) {
					ArrayAppend(slugs, Mid(entry, m.pos[2], m.len[2]));
				}
			}
		}
		return slugs;
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
