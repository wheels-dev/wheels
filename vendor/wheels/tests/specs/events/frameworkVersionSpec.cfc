component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo;

		describe("Framework version resolution", () => {

			it("exposes application.wheels.version as a non-empty string after boot", () => {
				expect(StructKeyExists(application.wheels, "version")).toBeTrue();
				expect(Len(application.wheels.version) > 0).toBeTrue("application.wheels.version is empty");
			});

			it("does not expose the literal unreplaced build placeholder at runtime", () => {
				expect(application.wheels.version).notToBe("@build.version@");
			});

			it("$readFrameworkVersion reads the version key from a box.json file", () => {
				var tmp = getTempDirectory() & "wheels-version-#CreateUUID()#.json";
				fileWrite(tmp, '{"version":"4.1.2"}');
				try {
					expect(g.$readFrameworkVersion(tmp)).toBe("4.1.2");
				} finally {
					fileDelete(tmp);
				}
			});

			it("$readFrameworkVersion substitutes a dev sentinel when version is the unreplaced build placeholder", () => {
				var tmp = getTempDirectory() & "wheels-version-#CreateUUID()#.json";
				fileWrite(tmp, '{"version":"@build.version@"}');
				try {
					expect(g.$readFrameworkVersion(tmp)).toBe("0.0.0-dev");
				} finally {
					fileDelete(tmp);
				}
			});

			it("$readFrameworkVersion synthesizes <rootversion>-dev when placeholder is detected inside the wheels monorepo", () => {
				var fwTmp = getTempDirectory() & "wheels-version-fw-#CreateUUID()#.json";
				var rootTmp = getTempDirectory() & "wheels-version-root-#CreateUUID()#.json";
				fileWrite(fwTmp, '{"version":"@build.version@"}');
				fileWrite(rootTmp, '{"name":"Wheels.fw","slug":"wheels","version":"4.0.0"}');
				try {
					expect(g.$readFrameworkVersion(fwTmp, rootTmp)).toBe("4.0.0-dev");
				} finally {
					fileDelete(fwTmp);
					fileDelete(rootTmp);
				}
			});

			it("$readFrameworkVersion falls back to 0.0.0-dev when the enclosing box.json is not the wheels monorepo (vendored install)", () => {
				var fwTmp = getTempDirectory() & "wheels-version-fw-#CreateUUID()#.json";
				var rootTmp = getTempDirectory() & "wheels-version-root-#CreateUUID()#.json";
				fileWrite(fwTmp, '{"version":"@build.version@"}');
				fileWrite(rootTmp, '{"name":"SomeUserApp","slug":"user-app","version":"2.1.0"}');
				try {
					expect(g.$readFrameworkVersion(fwTmp, rootTmp)).toBe("0.0.0-dev");
				} finally {
					fileDelete(fwTmp);
					fileDelete(rootTmp);
				}
			});

			it("$readFrameworkVersion uses wheels-base-template's version verbatim when the framework's own box.json placeholder slipped through (##2326)", () => {
				// Installed-app path: the user's `wheels new`-scaffolded app has a
				// box.json at the app root populated from `wheels-base-template`
				// (slug=wheels-base-template), and that box.json carries the
				// precise framework SNAPSHOT version stamped at release time. If
				// the framework's own box.json substitution slipped through, we
				// still surface the correct version instead of "0.0.0-dev".
				var fwTmp = getTempDirectory() & "wheels-version-fw-#CreateUUID()#.json";
				var rootTmp = getTempDirectory() & "wheels-version-root-#CreateUUID()#.json";
				fileWrite(fwTmp, '{"version":"@build.version@"}');
				fileWrite(rootTmp, '{"name":"Wheels Base Template","slug":"wheels-base-template","version":"4.0.0-SNAPSHOT+1625"}');
				try {
					expect(g.$readFrameworkVersion(fwTmp, rootTmp)).toBe("4.0.0-SNAPSHOT+1625");
				} finally {
					fileDelete(fwTmp);
					fileDelete(rootTmp);
				}
			});

			it("$readFrameworkVersion ignores wheels-base-template when its own version is also the unreplaced placeholder (##2326)", () => {
				var fwTmp = getTempDirectory() & "wheels-version-fw-#CreateUUID()#.json";
				var rootTmp = getTempDirectory() & "wheels-version-root-#CreateUUID()#.json";
				fileWrite(fwTmp, '{"version":"@build.version@"}');
				fileWrite(rootTmp, '{"name":"Wheels Base Template","slug":"wheels-base-template","version":"@build.version@"}');
				try {
					expect(g.$readFrameworkVersion(fwTmp, rootTmp)).toBe("0.0.0-dev");
				} finally {
					fileDelete(fwTmp);
					fileDelete(rootTmp);
				}
			});

			it("$readFrameworkVersion prefers the monorepo signal over the base-template signal when both could match (##2326)", () => {
				// Defensive: if both the monorepo and base-template markers somehow
				// coexist at the same path, the monorepo signal (a dev checkout)
				// is the authoritative one and the suffix should be "-dev".
				var fwTmp = getTempDirectory() & "wheels-version-fw-#CreateUUID()#.json";
				var rootTmp = getTempDirectory() & "wheels-version-root-#CreateUUID()#.json";
				fileWrite(fwTmp, '{"version":"@build.version@"}');
				fileWrite(rootTmp, '{"name":"Wheels.fw","slug":"wheels","version":"4.0.0"}');
				try {
					expect(g.$readFrameworkVersion(fwTmp, rootTmp)).toBe("4.0.0-dev");
				} finally {
					fileDelete(fwTmp);
					fileDelete(rootTmp);
				}
			});

			it("$readFrameworkVersion falls back to 0.0.0-dev when the enclosing box.json is also unreplaced", () => {
				var fwTmp = getTempDirectory() & "wheels-version-fw-#CreateUUID()#.json";
				var rootTmp = getTempDirectory() & "wheels-version-root-#CreateUUID()#.json";
				fileWrite(fwTmp, '{"version":"@build.version@"}');
				fileWrite(rootTmp, '{"name":"Wheels.fw","slug":"wheels","version":"@build.version@"}');
				try {
					expect(g.$readFrameworkVersion(fwTmp, rootTmp)).toBe("0.0.0-dev");
				} finally {
					fileDelete(fwTmp);
					fileDelete(rootTmp);
				}
			});

			it("$readFrameworkVersion falls back to 0.0.0-dev when the enclosing box.json is missing", () => {
				var fwTmp = getTempDirectory() & "wheels-version-fw-#CreateUUID()#.json";
				var missingRoot = getTempDirectory() & "wheels-version-missing-#CreateUUID()#.json";
				fileWrite(fwTmp, '{"version":"@build.version@"}');
				try {
					expect(g.$readFrameworkVersion(fwTmp, missingRoot)).toBe("0.0.0-dev");
				} finally {
					fileDelete(fwTmp);
				}
			});

			it("application.wheels.version resolves to <rootversion>-dev at boot in a monorepo dev checkout (regression for ##2291)", () => {
				// Regression for ##2291. Asserts the *runtime boot* result — not a direct
				// call — because $readFrameworkVersion is bound into the spec's scope by
				// WheelsTest.cfc, which shifts GetCurrentTemplatePath() to this file and
				// bypasses the code path we want to cover. application.wheels.version is
				// populated by onapplicationstart.cfc calling $readFrameworkVersion() with
				// no arguments, so whatever it resolved to is the answer we need to check.
				//
				// With the bug (one-level "../box.json"): default rootBoxJsonPath points at
				// vendor/box.json, which does not exist, so the helper falls through to
				// "0.0.0-dev" even in a monorepo checkout.
				// With the fix (two-level "../../box.json"): default rootBoxJsonPath points
				// at <repo-root>/box.json and yields "<rootversion>-dev".
				var wheelsDir = ExpandPath("/wheels/");
				var fwBoxPath = wheelsDir & "box.json";
				var rootBoxPath = wheelsDir & "../../box.json";
				if (!FileExists(fwBoxPath) || !FileExists(rootBoxPath)) {
					return;
				}
				var fwBox = DeserializeJSON(FileRead(fwBoxPath));
				var rootBox = DeserializeJSON(FileRead(rootBoxPath));
				if (!IsStruct(fwBox) || (fwBox.version ?: "") != "@build.version@") {
					return;
				}
				var isWheelsRepo = IsStruct(rootBox)
					&& (
						((rootBox.slug ?: "") == "wheels")
						|| ((rootBox.name ?: "") == "Wheels.fw")
					);
				if (!isWheelsRepo || (rootBox.version ?: "") == "" || rootBox.version == "@build.version@") {
					return;
				}
				expect(application.wheels.version).toBe(rootBox.version & "-dev");
			});

			it("$readFrameworkVersion throws Wheels.VersionReadFailed when the file is missing", () => {
				var missing = getTempDirectory() & "wheels-version-missing-#CreateUUID()#.json";
				var threw = false;
				try {
					g.$readFrameworkVersion(missing);
				} catch (Wheels.VersionReadFailed e) {
					threw = true;
				}
				expect(threw).toBeTrue("expected Wheels.VersionReadFailed when box.json is missing");
			});

			it("$readFrameworkVersion throws Wheels.VersionReadFailed when the JSON has no version key", () => {
				var tmp = getTempDirectory() & "wheels-version-#CreateUUID()#.json";
				fileWrite(tmp, '{"testbox":{"runner":"/tests/runner.cfm"}}');
				var threw = false;
				try {
					g.$readFrameworkVersion(tmp);
				} catch (Wheels.VersionReadFailed e) {
					threw = true;
				} finally {
					fileDelete(tmp);
				}
				expect(threw).toBeTrue("expected Wheels.VersionReadFailed when version key is absent");
			});

			it("$readFrameworkVersion throws Wheels.VersionReadFailed when the JSON is malformed", () => {
				var tmp = getTempDirectory() & "wheels-version-#CreateUUID()#.json";
				fileWrite(tmp, "this is not json {");
				var threw = false;
				try {
					g.$readFrameworkVersion(tmp);
				} catch (Wheels.VersionReadFailed e) {
					threw = true;
				} finally {
					fileDelete(tmp);
				}
				expect(threw).toBeTrue("expected Wheels.VersionReadFailed when box.json is malformed");
			});

		});

	}

}
