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
