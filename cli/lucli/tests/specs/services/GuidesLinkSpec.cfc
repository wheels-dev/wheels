component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.guides = new cli.lucli.services.GuidesLink();
		variables.latestSegment = "v" & Replace(guides.latestVersion(), ".", "-") & "-0";
	}

	function run() {

		describe("GuidesLink service (##3931)", () => {

			it("uses the project's or the upgrade target's minor version", () => {
				expect(guides.link("upgrading/3x-to-4x/", "4.0.6")).toBe("https://guides.wheels.dev/v4-0-0/upgrading/3x-to-4x/");
				expect(guides.link("upgrading/3x-to-4x/", "4.1.3")).toBe("https://guides.wheels.dev/v4-1-0/upgrading/3x-to-4x/");
			});

			it("uses the latest guides with no version, a dev build or a version not yet documented", () => {
				expect(guides.segment("")).toBe(latestSegment);
				expect(guides.segment("0.0.0-dev")).toBe(latestSegment);
				expect(guides.segment("9.9.0")).toBe(latestSegment);
			});

			it("links an upgrade target of the latest minor to that minor's guides", () => {
				var target = guides.latestVersion() & ".0";
				expect(guides.link("upgrading/", target)).toBe("https://guides.wheels.dev/" & latestSegment & "/upgrading/");
				expect(guides.segment("4.2.0")).toBe("v4-2-0");
			});

			it("never links older than the 4.0 guides", () => {
				expect(guides.segment("3.0.0")).toBe("v4-0-0");
			});

			it("is used for every guide link in Module.cfc and Doctor.cfc", () => {
				var root = ExpandPath("/cli/lucli/");
				for (var file in ["Module.cfc", "services/Doctor.cfc"]) {
					expect(ReFind("guides\.wheels\.dev/v[0-9]+-[0-9]+-0", FileRead(root & file))).toBe(0, "#file# hard-codes a guides version");
				}
			});
		});
	}

}
