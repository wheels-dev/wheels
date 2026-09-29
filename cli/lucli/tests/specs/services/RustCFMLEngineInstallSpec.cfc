/**
 * RustCFMLEngine.install() verifies the engine binary against the pinned
 * sha256 for its release asset before using it: a download that doesn't match
 * is refused and deleted, and a cached binary is re-checked rather than
 * trusted. The download is stubbed (RustCFMLInstallStub), so no network.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function run() {

		describe("RustCFMLEngine.install() checksum verification", () => {

			beforeEach(() => {
				variables.home = getTempDirectory() & "wheels-rustcfml-install-" & createUUID();
				directoryCreate(variables.home, true, true);
				variables.good = "rustcfml engine build " & createUUID();
				variables.goodSha = lCase(hash(variables.good, "SHA-256"));
			});

			afterEach(() => {
				if (directoryExists(variables.home)) directoryDelete(variables.home, true);
			});

			it("installs a download that matches the pin", () => {
				var engine = new cli.lucli.tests.RustCFMLInstallStub(
					wheelsHome = variables.home, payload = variables.good, pin = variables.goodSha
				);
				var bin = engine.install();
				expect(bin).toBe(engine.binPath());
				expect(fileExists(bin)).toBeTrue();
				expect(fileRead(bin)).toBe(variables.good);
				expect(createObject("java", "java.io.File").init(bin).canExecute()).toBeTrue("the binary is not executable");
				expect(arrayLen(engine.downloads())).toBe(1);
				// Only the final binary is left: the download went to a temp file.
				expect(directoryList(getDirectoryFromPath(bin), false, "name")).toBe([listLast(bin, "/")]);
			});

			it("refuses a download that doesn't match the pin, deletes it and throws", () => {
				var engine = new cli.lucli.tests.RustCFMLInstallStub(
					wheelsHome = variables.home, payload = "something else", pin = variables.goodSha
				);
				var state = {type = "", message = ""};
				try {
					engine.install();
				} catch (any e) {
					state.type = e.type;
					state.message = e.message & " " & e.detail;
				}
				expect(state.type).toBe("Wheels.RustCFML.ChecksumMismatch");
				expect(state.message).toInclude(variables.goodSha);
				expect(fileExists(engine.binPath())).toBeFalse("the unverified download was installed");
				expect(directoryList(getDirectoryFromPath(engine.binPath()), false, "name")).toBe([]);
			});

			it("does not trust an existing binary whose hash doesn't match the pin", () => {
				var engine = new cli.lucli.tests.RustCFMLInstallStub(
					wheelsHome = variables.home, payload = variables.good, pin = variables.goodSha
				);
				directoryCreate(getDirectoryFromPath(engine.binPath()), true, true);
				fileWrite(engine.binPath(), "a different binary");
				var bin = engine.install();
				expect(arrayLen(engine.downloads())).toBe(1, "the mismatched binary was returned without a fresh download");
				expect(fileRead(bin)).toBe(variables.good);
			});

			it("never leaves an unverified binary in place when the re-download also mismatches", () => {
				var engine = new cli.lucli.tests.RustCFMLInstallStub(
					wheelsHome = variables.home, payload = "still wrong", pin = variables.goodSha
				);
				directoryCreate(getDirectoryFromPath(engine.binPath()), true, true);
				fileWrite(engine.binPath(), "a different binary");
				expect(() => engine.install()).toThrow(type = "Wheels.RustCFML.ChecksumMismatch");
				expect(fileExists(engine.binPath())).toBeFalse();
			});

			it("returns an existing binary that matches the pin without downloading", () => {
				var engine = new cli.lucli.tests.RustCFMLInstallStub(
					wheelsHome = variables.home, payload = "never used", pin = variables.goodSha
				);
				directoryCreate(getDirectoryFromPath(engine.binPath()), true, true);
				fileWrite(engine.binPath(), variables.good);
				expect(engine.install()).toBe(engine.binPath());
				expect(arrayLen(engine.downloads())).toBe(0);
				expect(fileRead(engine.binPath())).toBe(variables.good);
			});

			it("cleans up and throws InstallFailed when the download fails", () => {
				var engine = new cli.lucli.tests.RustCFMLInstallStub(
					wheelsHome = variables.home, payload = "partial", pin = variables.goodSha, curlExit = 22
				);
				expect(() => engine.install()).toThrow(type = "Wheels.RustCFML.InstallFailed");
				expect(directoryList(getDirectoryFromPath(engine.binPath()), false, "name")).toBe([]);
			});

			it("refuses an asset with no pinned checksum before downloading", () => {
				var engine = new cli.lucli.tests.RustCFMLInstallStub(
					wheelsHome = variables.home, asset = "rustcfml-unpinned", payload = variables.good
				);
				expect(() => engine.install()).toThrow(type = "Wheels.RustCFML.InstallFailed");
				expect(arrayLen(engine.downloads())).toBe(0);
			});

			it("hashes a file to lowercase hex sha256", () => {
				var engine = new cli.lucli.tests.RustCFMLInstallStub(wheelsHome = variables.home);
				var path = variables.home & "/sample.bin";
				fileWrite(path, variables.good);
				expect(engine.$sha256File(path)).toBe(variables.goodSha);
			});

		});

	}

}
