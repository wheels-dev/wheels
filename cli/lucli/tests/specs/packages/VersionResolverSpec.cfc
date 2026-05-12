component extends="wheels.wheelstest.system.BaseSpec" {

	function run() {
		describe("VersionResolver", () => {

			var manifest = {
				name: "wheels-sentry",
				versions: [
					{version: "1.0.0", wheelsVersion: ">=4.0", tarball: "x", sha256: "a"},
					{version: "1.1.0", wheelsVersion: ">=4.0", tarball: "x", sha256: "b"},
					{version: "1.2.0", wheelsVersion: ">=5.0", tarball: "x", sha256: "c"},
					{version: "0.9.0", wheelsVersion: ">=3.0", tarball: "x", sha256: "d"}
				]
			};

			it("picks the highest version satisfying both runtime and pin", () => {
				var r = new cli.lucli.services.packages.VersionResolver();
				var chosen = r.pick(manifest, "4.0.0");
				expect(chosen.version).toBe("1.1.0");
			});

			it("honours an exact pin even if a higher compat version exists", () => {
				var r = new cli.lucli.services.packages.VersionResolver();
				var chosen = r.pick(manifest, "4.0.0", "1.0.0");
				expect(chosen.version).toBe("1.0.0");
			});

			it("honours a caret pin", () => {
				var r = new cli.lucli.services.packages.VersionResolver();
				var chosen = r.pick(manifest, "4.0.0", "^1.0.0");
				expect(chosen.version).toBe("1.1.0");
			});

			it("skips versions whose wheelsVersion constraint fails", () => {
				var r = new cli.lucli.services.packages.VersionResolver();
				// 1.2.0 requires >=5.0, runtime is 4.0 → must not be chosen
				var chosen = r.pick(manifest, "4.0.0");
				expect(chosen.version).notToBe("1.2.0");
			});

			it("throws Wheels.Packages.NoCompatibleVersion when nothing matches", () => {
				var r = new cli.lucli.services.packages.VersionResolver();
				var threw = false;
				try {
					r.pick(manifest, "2.0.0");  // nothing satisfies <4.0 except 0.9.0 (needs >=3.0 which 2.0 fails)
				} catch (any e) {
					threw = true;
					expect(e.type).toBe("Wheels.Packages.NoCompatibleVersion");
				}
				expect(threw).toBeTrue();
			});

			it("throws Wheels.Packages.NoVersions when versions array is empty", () => {
				var r = new cli.lucli.services.packages.VersionResolver();
				var threw = false;
				try {
					r.pick({name: "x", versions: []}, "4.0.0");
				} catch (any e) {
					threw = true;
					expect(e.type).toBe("Wheels.Packages.NoVersions");
				}
				expect(threw).toBeTrue();
			});

			it("treats missing wheelsVersion as 'any runtime'", () => {
				var r = new cli.lucli.services.packages.VersionResolver();
				var m = {name: "x", versions: [{version: "1.0.0", tarball: "t", sha256: "s"}]};
				var chosen = r.pick(m, "2.0.0");
				expect(chosen.version).toBe("1.0.0");
			});

			it("compatibleVersions returns every match, highest first", () => {
				var r = new cli.lucli.services.packages.VersionResolver();
				var list = r.compatibleVersions(manifest, "4.0.0");
				expect(ArrayLen(list)).toBe(3);           // 0.9.0, 1.0.0, 1.1.0 match
				expect(list[1].version).toBe("1.1.0");    // highest first
				expect(list[ArrayLen(list)].version).toBe("0.9.0");
			});
		});
	}
}
