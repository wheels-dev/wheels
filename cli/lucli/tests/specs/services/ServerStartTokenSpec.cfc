/**
 * The per-start token `wheels start` gives its server (#3769). Anyone who can
 * READ the token can answer the connection challenge, which skips the OS
 * peer check, so these pin that the token is only ever issued and used when
 * no other OS user can read or replace it.
 *
 * Hermetic: a temp lucliHome, like ServerRegistrySpec. POSIX only (the CLI
 * issues no token on Windows).
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.tempHome = getTempDirectory() & "wheels-token-#createUUID()#";
		directoryCreate(variables.tempHome & "/servers", true);
		variables.registry = new cli.lucli.services.ServerRegistry(lucliHome = variables.tempHome);
		variables.files = createObject("java", "java.nio.file.Files");
		variables.perms = createObject("java", "java.nio.file.attribute.PosixFilePermissions");
		variables.selfPid = createObject("java", "java.lang.ProcessHandle").current().pid();
		variables.posix = createObject("java", "java.nio.file.FileSystems").getDefault()
			.supportedFileAttributeViews().contains("posix");
		variables.tempProject = createObject("java", "java.io.File")
			.init(getTempDirectory() & "wheels-token-project-#createUUID()#").getCanonicalPath();
		directoryCreate(variables.tempProject, true);
	}

	function afterAll() {
		if (directoryExists(variables.tempHome)) {
			setMode(variables.tempHome & "/servers", "rwxr-xr-x");
			directoryDelete(variables.tempHome, true);
		}
		if (directoryExists(variables.tempProject)) directoryDelete(variables.tempProject, true);
	}

	private any function pathOf(required string location) {
		return createObject("java", "java.io.File").init(arguments.location).toPath();
	}

	private void function setMode(required string location, required string mode) {
		variables.files.setPosixFilePermissions(pathOf(arguments.location), variables.perms.fromString(arguments.mode));
	}

	private string function modeOf(required string location) {
		var noFollow = createObject("java", "java.lang.reflect.Array").newInstance(
			createObject("java", "java.lang.Class").forName("java.nio.file.LinkOption"),
			javaCast("int", 0)
		);
		return variables.perms.toString(variables.files.getPosixFilePermissions(pathOf(arguments.location), noFollow));
	}

	/** A fresh registration dir (rwxr-xr-x) under the temp home; returns its name. */
	private string function newRegistration(string projectPath = "", string pidContent = "") {
		var name = "tok-" & lCase(left(replace(createUUID(), "-", "", "all"), 12));
		var dir = variables.tempHome & "/servers/" & name;
		directoryCreate(dir, true);
		setMode(dir, "rwxr-xr-x");
		if (len(arguments.projectPath)) fileWrite(dir & "/.project-path", arguments.projectPath);
		if (len(arguments.pidContent)) fileWrite(dir & "/server.pid", arguments.pidContent);
		return name;
	}

	private string function tokenFile(required string name) {
		return variables.tempHome & "/servers/" & arguments.name & "/wheels-cli.token";
	}

	/** A registry whose OS introspection answers `owner`, with no command line to compare. */
	private any function introspectionRegistry(required string owner) {
		var reg = new cli.lucli.services.ServerRegistry(lucliHome = variables.tempHome);
		prepareMock(reg);
		reg.$("$processCommandLine", "");
		reg.$("listenerOwnedBy", arguments.owner);
		return reg;
	}

	function run() {

		describe("ServerRegistry per-start token (##3769)", () => {

			it("writes an owner-only (rw-------) token of 64 lowercase hex characters", () => {
				if (!variables.posix) return;
				var name = newRegistration();
				expect(registry.writeStartToken(name)).toBeTrue();
				expect(modeOf(tokenFile(name))).toBe("rw-------");
				var token = registry.readStartToken(name);
				expect(reFind("^[0-9a-f]{64}$", token)).toBe(1);
				expect(trim(fileRead(tokenFile(name)))).toBe(token);
			});

			it("rotates the token on every start", () => {
				if (!variables.posix) return;
				var name = newRegistration();
				registry.writeStartToken(name);
				var first = registry.readStartToken(name);
				registry.writeStartToken(name);
				expect(registry.readStartToken(name)).notToBe(first);
			});

			it("replaces a leftover world-readable token with a new owner-only file, never writing in place", () => {
				if (!variables.posix) return;
				var name = newRegistration();
				var stale = repeatString("a", 64);
				fileWrite(tokenFile(name), stale);
				setMode(tokenFile(name), "rw-r--r--");
				expect(registry.writeStartToken(name)).toBeTrue();
				expect(modeOf(tokenFile(name))).toBe("rw-------");
				expect(registry.readStartToken(name)).notToBe(stale);
				// The temp file is moved into place, so none is left behind.
				var leftovers = directoryList(variables.tempHome & "/servers/" & name, false, "name", "*.tmp");
				expect(arrayLen(leftovers)).toBe(0);
			});

			it("refuses to use a token another user can read", () => {
				if (!variables.posix) return;
				var name = newRegistration();
				registry.writeStartToken(name);
				for (var mode in ["rw-r--r--", "rw-rw----", "rw----r--", "rwx------"]) {
					setMode(tokenFile(name), mode);
					expect(registry.readStartToken(name)).toBe("", "used a #mode# token");
				}
			});

			it("issues no token, and removes an old one, when the registration dir is group- or world-writable", () => {
				if (!variables.posix) return;
				for (var mode in ["rwxrwxrwx", "rwxrwxr-x", "rwxr-xrwx"]) {
					var name = newRegistration();
					registry.writeStartToken(name);
					expect(fileExists(tokenFile(name))).toBeTrue();
					setMode(variables.tempHome & "/servers/" & name, mode);
					expect(registry.readStartToken(name)).toBe("", "read a token in a #mode# dir");
					expect(registry.writeStartToken(name)).toBeFalse("issued a token in a #mode# dir");
					expect(fileExists(tokenFile(name))).toBeFalse("left the old token in a #mode# dir");
					setMode(variables.tempHome & "/servers/" & name, "rwxr-xr-x");
				}
			});

			it("issues no token when the servers dir above it is group-writable", () => {
				if (!variables.posix) return;
				var name = newRegistration();
				setMode(variables.tempHome & "/servers", "rwxrwxr-x");
				try {
					expect(registry.writeStartToken(name)).toBeFalse();
					expect(fileExists(tokenFile(name))).toBeFalse();
				} finally {
					setMode(variables.tempHome & "/servers", "rwxr-xr-x");
				}
			});

			it("refuses a registration dir owned by another user", () => {
				if (!variables.posix) return;
				// A directory this user can't own: the filesystem root (root-owned,
				// not group- or world-writable), so only the owner check can refuse it.
				expect(registry.$dirIsPrivate(pathOf("/"))).toBeFalse();
				expect(registry.$dirIsPrivate(pathOf(variables.tempHome & "/servers"))).toBeTrue();
			});

			it("refuses a token that is a symlink, or a registration dir that is one", () => {
				if (!variables.posix) return;
				var name = newRegistration();
				var elsewhere = getTempDirectory() & "wheels-token-target-#createUUID()#";
				fileWrite(elsewhere, repeatString("b", 64));
				setMode(elsewhere, "rw-------");
				var linkedDir = "tok-link-" & lCase(left(replace(createUUID(), "-", "", "all"), 8));
				try {
					files.createSymbolicLink(pathOf(tokenFile(name)), pathOf(elsewhere), $noAttributes());
					expect(registry.readStartToken(name)).toBe("");

					files.createSymbolicLink(
						pathOf(variables.tempHome & "/servers/" & linkedDir),
						pathOf(variables.tempHome & "/servers/" & newRegistration()),
						$noAttributes()
					);
					expect(registry.writeStartToken(linkedDir)).toBeFalse();
				} finally {
					if (fileExists(elsewhere)) fileDelete(elsewhere);
					files.deleteIfExists(pathOf(variables.tempHome & "/servers/" & linkedDir));
				}
			});

			it("refuses a malformed token, and a name that escapes the servers dir", () => {
				if (!variables.posix) return;
				var name = newRegistration();
				registry.writeStartToken(name);
				fileWrite(tokenFile(name), "not-a-token");
				setMode(tokenFile(name), "rw-------");
				expect(registry.readStartToken(name)).toBe("");
				for (var bad in ["", "..", ".", "a/b", "..\x"]) {
					expect(registry.writeStartToken(bad)).toBeFalse("accepted name [#bad#]");
				}
			});

			it("deleteStartToken() removes the token", () => {
				if (!variables.posix) return;
				var name = newRegistration();
				registry.writeStartToken(name);
				registry.deleteStartToken(name);
				expect(fileExists(tokenFile(name))).toBeFalse();
			});

		});

		describe("verifyOwnServer() and the token (##3769)", () => {

			it("reads the token from the registration that verified, not the primary name (##3679 path)", () => {
				if (!variables.posix) return;
				var listener = createObject("java", "java.net.ServerSocket").init(0);
				var reg = introspectionRegistry("yes");
				// No lucee.json: the primary name is the project dir's basename,
				// which has no registration; the server runs under another name.
				var name = newRegistration(
					projectPath = variables.tempProject,
					pidContent = variables.selfPid & ":" & listener.getLocalPort()
				);
				try {
					reg.writeStartToken(name);
					var verdict = reg.verifyOwnServer(variables.tempProject);
					expect(verdict.port).toBe(listener.getLocalPort());
					expect(verdict.name).toBe(name);
					expect(verdict.token).toBe(reg.readStartToken(name));
					expect(verdict.challengeRequired).toBeFalse();
				} finally {
					listener.close();
					directoryDelete(variables.tempHome & "/servers/" & name, true);
				}
			});

			it("passes an unverifiable listener only with a token, and then requires the challenge", () => {
				if (!variables.posix) return;
				var reg = introspectionRegistry("unknown");
				var name = newRegistration(
					projectPath = variables.tempProject,
					pidContent = variables.selfPid & ":65000"
				);
				try {
					var without = reg.verifyOwnServer(variables.tempProject);
					expect(without.port).toBe(0);
					expect(without.reason).toBe("unverifiable");

					reg.writeStartToken(name);
					var withToken = reg.verifyOwnServer(variables.tempProject);
					expect(withToken.port).toBe(65000);
					expect(withToken.challengeRequired).toBeTrue();
					expect(len(withToken.token)).toBe(64);
				} finally {
					directoryDelete(variables.tempHome & "/servers/" & name, true);
				}
			});

			it("a token never overrides a listener the OS says is someone else's", () => {
				if (!variables.posix) return;
				var reg = introspectionRegistry("no");
				var name = newRegistration(
					projectPath = variables.tempProject,
					pidContent = variables.selfPid & ":65000"
				);
				try {
					reg.writeStartToken(name);
					var verdict = reg.verifyOwnServer(variables.tempProject);
					expect(verdict.port).toBe(0);
					expect(verdict.reason).toBe("listener-mismatch");
				} finally {
					directoryDelete(variables.tempHome & "/servers/" & name, true);
				}
			});

			it("tokenRegistrationFor() finds this project's live registration", () => {
				var name = newRegistration(
					projectPath = variables.tempProject,
					pidContent = variables.selfPid & ":65000"
				);
				try {
					expect(registry.tokenRegistrationFor(variables.tempProject)).toBe(name);
				} finally {
					directoryDelete(variables.tempHome & "/servers/" & name, true);
				}
			});

		});

	}

	/** An empty FileAttribute[] for createSymbolicLink's varargs. */
	private any function $noAttributes() {
		return createObject("java", "java.lang.reflect.Array").newInstance(
			createObject("java", "java.lang.Class").forName("java.nio.file.attribute.FileAttribute"),
			javaCast("int", 0)
		);
	}

}
