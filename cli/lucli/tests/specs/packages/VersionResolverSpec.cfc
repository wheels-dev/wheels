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

			describe("pre-release versions", () => {

				// Registry order is ascending, so the RC precedes its release.
				var rcManifest = {
					name: "wheels-rc",
					versions: [
						{version: "1.1.0", wheelsVersion: ">=4.0", tarball: "x", sha256: "a"},
						{version: "1.2.0-rc.1", wheelsVersion: ">=4.0", tarball: "x", sha256: "b"},
						{version: "1.2.0", wheelsVersion: ">=4.0", tarball: "x", sha256: "c"}
					]
				};

				it("picks the stable release over its equal pre-release with no pin", () => {
					var r = new cli.lucli.services.packages.VersionResolver();
					expect(r.pick(rcManifest, "4.1.2").version).toBe("1.2.0");
				});

				it("matches an exact release pin to the release, not its pre-release", () => {
					var r = new cli.lucli.services.packages.VersionResolver();
					expect(r.pick(rcManifest, "4.1.2", "1.2.0").version).toBe("1.2.0");
				});

				it("honours an exact pre-release pin", () => {
					var r = new cli.lucli.services.packages.VersionResolver();
					expect(r.pick(rcManifest, "4.1.2", "1.2.0-rc.1").version).toBe("1.2.0-rc.1");
				});

				it("picks the newest stable when only a pre-release is newer", () => {
					var r = new cli.lucli.services.packages.VersionResolver();
					var m = {
						name: "wheels-rc",
						versions: [
							{version: "1.1.0", wheelsVersion: ">=4.0", tarball: "x", sha256: "a"},
							{version: "1.2.0-rc.1", wheelsVersion: ">=4.0", tarball: "x", sha256: "b"}
						]
					};
					expect(r.pick(m, "4.1.2").version).toBe("1.1.0");
					expect(r.pick(m, "4.1.2", "^1.0.0").version).toBe("1.1.0");
				});

				it("considers pre-releases when a range pin names one", () => {
					var r = new cli.lucli.services.packages.VersionResolver();
					var m = {
						name: "wheels-rc",
						versions: [
							{version: "1.1.0", tarball: "x", sha256: "a"},
							{version: "1.2.0-rc.1", tarball: "x", sha256: "b"},
							{version: "1.2.0-rc.2", tarball: "x", sha256: "c"}
						]
					};
					expect(r.pick(m, "4.1.2", ">=1.2.0-rc.1").version).toBe("1.2.0-rc.2");
				});

				it("throws NoCompatibleVersion when only pre-releases exist and no pin names one", () => {
					var r = new cli.lucli.services.packages.VersionResolver();
					var m = {name: "wheels-rc", versions: [{version: "1.0.0-beta.1", tarball: "x", sha256: "a"}]};
					var state = {type: ""};
					try {
						r.pick(m, "4.1.2");
					} catch (any e) {
						state.type = e.type;
					}
					expect(state.type).toBe("Wheels.Packages.NoCompatibleVersion");
				});

				it("treats a snapshot runtime like its release for wheelsVersion", () => {
					var r = new cli.lucli.services.packages.VersionResolver();
					var m = {name: "x", versions: [{version: "1.0.0", wheelsVersion: ">=4.1.2", tarball: "t", sha256: "s"}]};
					expect(r.pick(m, "4.1.2-snapshot.500").version).toBe("1.0.0");
					expect(ArrayLen(r.compatibleVersions(m, "4.1.2-snapshot.500"))).toBe(1);
				});

				it("compatibleVersions orders a release above its pre-release", () => {
					var r = new cli.lucli.services.packages.VersionResolver();
					var list = r.compatibleVersions(rcManifest, "4.1.2");
					expect(ArrayLen(list)).toBe(3);
					expect(list[1].version).toBe("1.2.0");
					expect(list[2].version).toBe("1.2.0-rc.1");
					expect(list[3].version).toBe("1.1.0");
				});
			});
		});
	}
}
