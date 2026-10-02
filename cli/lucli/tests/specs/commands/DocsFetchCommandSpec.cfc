/**
 * `wheels docs fetch` verifies the bundle against the .sha512 file the
 * release publishes next to it BEFORE unpacking, and every failure throws
 * Wheels.DocsFetchFailed (so the command exits non-zero) without leaving a
 * half-unpacked docs directory or a temp file behind.
 *
 * Drives the real docs() dispatch against a raw-socket HTTP stub
 * (cli.lucli.tests.StubHttpServer with per-path routes) serving a fake zip
 * and its checksum, so no network is involved. $docsBundleUrl() is pointed at
 * the stub and $resolveLucliHome() at a per-test temp home.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.testHelper = new cli.lucli.tests.TestHelper();
		variables.tempRoot = testHelper.scaffoldTempProject(expandPath("/"));
		variables.version = "9.9.9";
		directoryCreate(tempRoot & "/vendor/wheels", true, true);
		fileWrite(tempRoot & "/vendor/wheels/wheels.json", serializeJSON({version: variables.version}));

		variables.workDir = getTempDirectory() & "docs-fetch-spec-" & createUUID();
		directoryCreate(workDir, true);

		// A real bundle: contents at the zip root, like build-docs.sh makes.
		var src = workDir & "/bundle-src";
		directoryCreate(src & "/guides", true);
		fileWrite(src & "/manifest.json", serializeJSON({docsVersion: variables.version}));
		fileWrite(src & "/guides/index.html", "<h1>Guides</h1>");
		compress("zip", src, workDir & "/bundle.zip", false);
		variables.zipBytes = fileReadBinary(workDir & "/bundle.zip");
		variables.zipSha = lCase(hash(zipBytes, "SHA-512"));

		variables.zipName = "wheels-docs-#variables.version#.zip";
		variables.stubFactory = createObject("component", "cli.lucli.tests.StubHttpServer");
	}

	function afterAll() {
		if (directoryExists(variables.workDir)) directoryDelete(variables.workDir, true);
		testHelper.cleanupTempProject(variables.tempRoot);
	}

	/** `sha512sum` output shape: "<hex>  <file>\n". */
	private string function checksumFile(required string hex) {
		return arguments.hex & "  " & variables.zipName & chr(10);
	}

	/** Routes keyed by path; a missing key 404s (the stub's fixed status). */
	private any function startStub(required struct routes) {
		var bytesByPath = {};
		for (var path in arguments.routes) {
			bytesByPath[path] = stubFactory.binaryResponse(200, arguments.routes[path]);
		}
		return new cli.lucli.tests.StubHttpServer(statusCode = 404, bindAddress = "127.0.0.1", routes = bytesByPath);
	}

	private any function fetchModule(required any stub, required string home) {
		var m = new cli.lucli.Module(cwd = variables.tempRoot);
		prepareMock(m);
		m.$("$resolveLucliHome", arguments.home);
		m.$("$docsBundleUrl", "http://127.0.0.1:#arguments.stub.getPort()#/#variables.zipName#");
		m.$("$docsMountIntoWebroot");
		return m;
	}

	private string function newHome() {
		var home = variables.workDir & "/home-" & createUUID();
		directoryCreate(home & "/docs", true);
		return home;
	}

	/** Everything under <home>/docs other than the installed version dir. */
	private array function strayEntries(required string home) {
		var stray = [];
		for (var name in directoryList(arguments.home & "/docs", false, "name")) {
			if (name != variables.version) arrayAppend(stray, name);
		}
		return stray;
	}

	private array function tempFiles() {
		return directoryList(getTempDirectory(), false, "name", "wheels-docs-#variables.version#-*");
	}

	/** Runs docs() and returns the thrown type, or "" when it did not throw. */
	private string function runDocs(required any m, array argv = ["fetch"]) {
		var state = {type = ""};
		arguments.m.__arguments = arguments.argv;
		try {
			arguments.m.docs();
		} catch (any e) {
			state.type = e.type;
		}
		return state.type;
	}

	function run() {

		describe("wheels docs fetch — SHA-512 verification before unpacking", () => {

			it("installs the bundle when it matches the published checksum", () => {
				var home = newHome();
				var before = arrayLen(tempFiles());
				var stub = startStub({
					"/#zipName#": zipBytes,
					"/#zipName#.sha512": checksumFile(zipSha)
				});
				try {
					expect(runDocs(fetchModule(stub, home))).toBe("");
					var requested = arrayToList(stub.requests(), "|");
				} finally {
					stub.stop();
				}
				expect(fileExists(home & "/docs/#version#/manifest.json")).toBeTrue();
				expect(fileExists(home & "/docs/#version#/guides/index.html")).toBeTrue();
				expect(requested).toInclude("GET /#zipName#.sha512 ");
				expect(strayEntries(home)).toBeEmpty();
				expect(arrayLen(tempFiles())).toBe(before);
			});

			it("accepts an upper-case hash in the checksum file", () => {
				var home = newHome();
				var stub = startStub({
					"/#zipName#": zipBytes,
					"/#zipName#.sha512": checksumFile(uCase(zipSha))
				});
				try {
					expect(runDocs(fetchModule(stub, home))).toBe("");
				} finally {
					stub.stop();
				}
				expect(fileExists(home & "/docs/#version#/manifest.json")).toBeTrue();
			});

			it("refuses a bundle that does not match, leaving no unpacked dir or temp file", () => {
				var home = newHome();
				var before = arrayLen(tempFiles());
				var stub = startStub({
					"/#zipName#": zipBytes,
					"/#zipName#.sha512": checksumFile(lCase(hash("something else", "SHA-512")))
				});
				try {
					expect(runDocs(fetchModule(stub, home))).toBe("Wheels.DocsFetchFailed");
				} finally {
					stub.stop();
				}
				expect(directoryExists(home & "/docs/#version#")).toBeFalse();
				expect(strayEntries(home)).toBeEmpty();
				expect(arrayLen(tempFiles())).toBe(before);
			});

			it("keeps an existing install when a --force re-fetch does not match", () => {
				var home = newHome();
				directoryCreate(home & "/docs/#version#", true);
				fileWrite(home & "/docs/#version#/marker.txt", "previous install");
				var stub = startStub({
					"/#zipName#": zipBytes,
					"/#zipName#.sha512": checksumFile(lCase(hash("something else", "SHA-512")))
				});
				try {
					expect(runDocs(fetchModule(stub, home), ["fetch", "--force"])).toBe("Wheels.DocsFetchFailed");
				} finally {
					stub.stop();
				}
				expect(fileExists(home & "/docs/#version#/marker.txt")).toBeTrue();
				expect(fileExists(home & "/docs/#version#/manifest.json")).toBeFalse();
				expect(strayEntries(home)).toBeEmpty();
			});

			it("fails when the release publishes no checksum, without downloading the bundle", () => {
				var home = newHome();
				var stub = startStub({"/#zipName#": zipBytes});
				try {
					expect(runDocs(fetchModule(stub, home))).toBe("Wheels.DocsFetchFailed");
					var requested = arrayToList(stub.requests(), "|");
				} finally {
					stub.stop();
				}
				expect(requested).notToInclude("GET /#zipName# ");
				expect(directoryExists(home & "/docs/#version#")).toBeFalse();
				expect(strayEntries(home)).toBeEmpty();
			});

			it("fails when the checksum file holds no SHA-512 hash", () => {
				var home = newHome();
				var stub = startStub({
					"/#zipName#": zipBytes,
					"/#zipName#.sha512": "not a checksum" & chr(10)
				});
				try {
					expect(runDocs(fetchModule(stub, home))).toBe("Wheels.DocsFetchFailed");
				} finally {
					stub.stop();
				}
				expect(directoryExists(home & "/docs/#version#")).toBeFalse();
			});

			it("fails when the bundle download fails", () => {
				var home = newHome();
				var before = arrayLen(tempFiles());
				var stub = startStub({"/#zipName#.sha512": checksumFile(zipSha)});
				try {
					expect(runDocs(fetchModule(stub, home))).toBe("Wheels.DocsFetchFailed");
				} finally {
					stub.stop();
				}
				expect(directoryExists(home & "/docs/#version#")).toBeFalse();
				expect(strayEntries(home)).toBeEmpty();
				expect(arrayLen(tempFiles())).toBe(before);
			});

			it("fails when a matching download cannot be unpacked, leaving no partial dir", () => {
				var home = newHome();
				var notAZip = charsetDecode("this is not a zip archive", "utf-8");
				var stub = startStub({
					"/#zipName#": notAZip,
					"/#zipName#.sha512": checksumFile(lCase(hash(notAZip, "SHA-512")))
				});
				try {
					expect(runDocs(fetchModule(stub, home))).toBe("Wheels.DocsFetchFailed");
				} finally {
					stub.stop();
				}
				expect(directoryExists(home & "/docs/#version#")).toBeFalse();
				expect(strayEntries(home)).toBeEmpty();
			});

			it("installs when the CLI home path contains a space", () => {
				var home = variables.workDir & "/home sp ace-" & createUUID();
				directoryCreate(home & "/docs", true);
				var stub = startStub({
					"/#zipName#": zipBytes,
					"/#zipName#.sha512": checksumFile(zipSha)
				});
				try {
					expect(runDocs(fetchModule(stub, home))).toBe("");
				} finally {
					stub.stop();
				}
				expect(fileExists(home & "/docs/#version#/manifest.json")).toBeTrue();
				expect(fileExists(home & "/docs/#version#/guides/index.html")).toBeTrue();
				expect(strayEntries(home)).toBeEmpty();
			});

			it("fails an archive entry that would unpack outside the docs directory", () => {
				var home = newHome();
				var evilZip = variables.workDir & "/evil-" & createUUID() & ".zip";
				var zos = createObject("java", "java.util.zip.ZipOutputStream").init(
					createObject("java", "java.io.FileOutputStream").init(evilZip)
				);
				zos.putNextEntry(createObject("java", "java.util.zip.ZipEntry").init("../escaped.txt"));
				zos.write(charsetDecode("escaped", "utf-8"));
				zos.closeEntry();
				zos.close();
				var evilBytes = fileReadBinary(evilZip);
				var stub = startStub({
					"/#zipName#": evilBytes,
					"/#zipName#.sha512": checksumFile(lCase(hash(evilBytes, "SHA-512")))
				});
				try {
					expect(runDocs(fetchModule(stub, home))).toBe("Wheels.DocsFetchFailed");
				} finally {
					stub.stop();
				}
				expect(fileExists(home & "/docs/escaped.txt")).toBeFalse();
				expect(directoryExists(home & "/docs/#version#")).toBeFalse();
				expect(strayEntries(home)).toBeEmpty();
			});

			it("fails when the framework version cannot be determined", () => {
				var bareRoot = variables.workDir & "/not-a-project-" & createUUID();
				directoryCreate(bareRoot, true);
				var m = new cli.lucli.Module(cwd = bareRoot);
				expect(runDocs(m)).toBe("Wheels.DocsFetchFailed");
			});

		});

		describe("wheels docs fetch — an installed bundle and offline mode", () => {

			afterEach(() => {
				structDelete(request, "$wheelsOffline");
			});

			it("mounts an already-installed bundle into the webroot without downloading", () => {
				var home = newHome();
				directoryCreate(home & "/docs/#version#", true);
				var stub = startStub({});
				try {
					var m = fetchModule(stub, home);
					expect(runDocs(m)).toBe("");
					var requested = stub.requests();
				} finally {
					stub.stop();
				}
				expect(m.$count("$docsMountIntoWebroot")).toBe(1);
				expect(requested).toBeEmpty();
			});

			it("refuses the download with --offline, before any network access", () => {
				var home = newHome();
				var stub = startStub({
					"/#zipName#": zipBytes,
					"/#zipName#.sha512": checksumFile(zipSha)
				});
				try {
					var m = fetchModule(stub, home);
					var state = {type = "", message = ""};
					m.__arguments = ["fetch", "--offline"];
					try {
						m.docs();
					} catch (any e) {
						state.type = e.type;
						state.message = e.message;
					}
					var requested = stub.requests();
				} finally {
					stub.stop();
				}
				expect(state.type).toBe("Wheels.DocsFetchFailed");
				expect(state.message).toInclude("--offline");
				expect(requested).toBeEmpty();
				expect(directoryExists(home & "/docs/#version#")).toBeFalse();
				expect(m.$count("$docsMountIntoWebroot")).toBe(0);
			});

			it("still mounts an already-installed bundle with --offline", () => {
				var home = newHome();
				directoryCreate(home & "/docs/#version#", true);
				var stub = startStub({});
				try {
					var m = fetchModule(stub, home);
					expect(runDocs(m, ["fetch", "--offline"])).toBe("");
					var requested = stub.requests();
				} finally {
					stub.stop();
				}
				expect(m.$count("$docsMountIntoWebroot")).toBe(1);
				expect(requested).toBeEmpty();
			});

			it("refuses a --force re-fetch with --offline and keeps the installed bundle", () => {
				var home = newHome();
				directoryCreate(home & "/docs/#version#", true);
				fileWrite(home & "/docs/#version#/marker.txt", "previous install");
				var stub = startStub({
					"/#zipName#": zipBytes,
					"/#zipName#.sha512": checksumFile(zipSha)
				});
				try {
					expect(runDocs(fetchModule(stub, home), ["fetch", "--force", "--offline"])).toBe("Wheels.DocsFetchFailed");
					var requested = stub.requests();
				} finally {
					stub.stop();
				}
				expect(requested).toBeEmpty();
				expect(fileExists(home & "/docs/#version#/marker.txt")).toBeTrue();
			});

		});
	}
}
