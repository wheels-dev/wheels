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

			it("is not behind the newest guide tree", () => {
				// When a version's guides are cut, bump variables.latest in
				// vendor/wheels/GuidesLink.cfc and cli/lucli/services/GuidesLink.cfc.
				for (var dir in DirectoryList(docsRoot, false, "name")) {
					var m = ReFind("^v([0-9]+)-([0-9]+)-0$", dir, 1, true);
					if (m.pos[1] > 0) {
						var tree = Mid(dir, m.pos[2], m.len[2]) & "." & Mid(dir, m.pos[3], m.len[3]);
						expect(guides.$compareMinor(tree, guides.latestVersion())).toBeLTE(0, "guides tree #dir# is newer than GuidesLink's latest (#guides.latestVersion()#)");
					}
				}
			});

			it("matches the CLI's copy", () => {
				var cliSource = FileRead(ExpandPath("/wheels/../..") & "/cli/lucli/services/GuidesLink.cfc");
				expect(cliSource).toInclude('variables.latest = "#guides.latestVersion()#"');
			});

			it("links only to pages that exist in every tree it can resolve to", () => {
				var pages = ["upgrading/3x-to-4x", "upgrading/2x-to-3x", "digging-deeper/packages", "command-line-tools/mcp-integration", "testing", "start-here/installing"];
				for (var tree in ["v4-0-0", latestSegment]) {
					for (var page in pages) {
						var base = docsRoot & tree & "/" & page;
						expect(FileExists(base & ".mdx") || FileExists(base & "/index.mdx")).toBeTrue("missing #tree#/#page#");
					}
				}
			});
		});
	}

}
