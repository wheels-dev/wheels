/**
 * Inspects and manages LuCLI's per-project server registrations under
 * `<lucliHome>/servers/<name>/`. Used by Module.cfc's start() and stop()
 * to mediate stale-registration cases that LuCLI's own `server start`
 * prompt handles with `lucli ...` recovery hints — `lucli` isn't on PATH
 * after `brew install wheels`, so the wheels wrapper has to recover
 * before the user sees an unactionable prompt.
 *
 * The service takes `lucliHome` via constructor injection (no env lookup,
 * no Java system property reads) so tests can point it at a temp dir.
 *
 * Onboarding findings F1, F2 from the 2026-05-01 fresh-VM tutorial run.
 */
component {

	variables.TOKEN_FILE = "wheels-cli.token";

	public function init(required string lucliHome) {
		variables.lucliHome = arguments.lucliHome;
		return this;
	}

	/**
	 * Server name LuCLI assigns to a project rooted at the given path. LuCLI
	 * registers the server under the `name` in the project's `lucee.json`;
	 * only when that file is absent, unparseable, or has no non-empty string
	 * `name` does it fall back to the directory basename (computed via Java
	 * so it's portable across `/` and `\` separators). Deriving the name from
	 * the basename alone missed the server in worktrees, clones into a
	 * differently named directory, and apps whose `lucee.json` name was
	 * edited (#3679). If LuCLI ever moves to a different scheme this needs
	 * to follow.
	 */
	public string function serverNameFor(required string projectRoot) {
		if (!len(arguments.projectRoot)) return "";
		var configured = $configuredServerName(arguments.projectRoot);
		if (len(configured)) return configured;
		try {
			return createObject("java", "java.io.File")
				.init(arguments.projectRoot)
				.getName();
		} catch (any e) {
			return listLast(arguments.projectRoot, "/\");
		}
	}

	/**
	 * Classify a possibly-stale registration at `<lucliHome>/servers/<serverName>/`.
	 *
	 * Returns:
	 *   exists          : registration directory is present
	 *   alive           : a recorded pid is currently running (server up)
	 *   ours            : registration's `.project-path` matches this cwd
	 *   registeredPath  : raw `.project-path` content for diagnostics
	 *
	 * Empty serverName, missing lucliHome, or absent registration directory
	 * all return `{exists: false, alive: false, ours: false, registeredPath: ""}`
	 * — caller treats the "no registration" case the same as "fresh project."
	 */
	public struct function inspect(
		required string serverName,
		required string projectRoot
	) {
		var rv = { exists: false, alive: false, ours: false, registeredPath: "" };
		if (!len(arguments.serverName) || !len(variables.lucliHome)) return rv;

		var regDir = variables.lucliHome & "/servers/" & arguments.serverName;
		if (!directoryExists(regDir)) return rv;
		rv.exists = true;

		// Compare `.project-path` to canonical cwd to detect ours-vs-theirs.
		// Reading the canonical path resolves symlinks so a worktree under a
		// `/tmp` symlink doesn't falsely mismatch its own registration.
		var pp = regDir & "/.project-path";
		if (fileExists(pp)) {
			rv.registeredPath = trim(fileRead(pp));
			var canonicalCwd = arguments.projectRoot;
			try {
				canonicalCwd = createObject("java", "java.io.File")
					.init(arguments.projectRoot)
					.getCanonicalPath();
			} catch (any e) {}
			if (len(rv.registeredPath) && rv.registeredPath == canonicalCwd) {
				rv.ours = true;
			}
		}

		// `server.pid` format is "<pid>:<port>". Pid alive ⇒ server is up.
		var pidFile = regDir & "/server.pid";
		if (fileExists(pidFile)) {
			try {
				var pid = listFirst(trim(fileRead(pidFile)), ":");
				if (len(pid) && isNumeric(pid) && $isProcessAlive(pid)) {
					rv.alive = true;
				}
			} catch (any e) {}
		}

		return rv;
	}

	/**
	 * The registered server that is running on `port`, as
	 * `{name, projectPath}`; both are "" when no live registration records
	 * that port. Reads each registration's `server.pid` ("<pid>:<port>") and
	 * checks the pid is alive, as inspect() does.
	 */
	public struct function registrationOnPort(required numeric port) {
		var rv = {name: "", projectPath: ""};
		var serversDir = variables.lucliHome & "/servers";
		if (!len(variables.lucliHome) || !directoryExists(serversDir)) return rv;
		for (var name in directoryList(serversDir, false, "name")) {
			var regDir = serversDir & "/" & name;
			if (!fileExists(regDir & "/server.pid")) continue;
			var parts = listToArray(trim(fileRead(regDir & "/server.pid")), ":");
			if (
				arrayLen(parts) == 2 && isNumeric(parts[1]) && isNumeric(parts[2])
				&& parts[2] == arguments.port && $isProcessAlive(parts[1])
			) {
				rv.name = name;
				rv.projectPath = fileExists(regDir & "/.project-path") ? trim(fileRead(regDir & "/.project-path")) : "";
				return rv;
			}
		}
		return rv;
	}

	/**
	 * Port of the project's OWN running Lucee server, or 0. Ownership is
	 * proven by verifyOwnServer(): registration, live server process AND the
	 * listener on the port all have to match.
	 *
	 * This is the authoritative "is MY server running" answer — unlike a
	 * bare port probe, it proves ownership via the `.project-path` marker,
	 * so callers that must not attach to a sibling app (e.g. `wheels test`)
	 * can refuse when it returns 0 instead of falling back to a heuristic
	 * port that may belong to a different project.
	 */
	public numeric function ownServerPort(required string projectRoot) {
		return verifyOwnServer(arguments.projectRoot).port;
	}

	/**
	 * Prove that the server on this project's registered port IS this
	 * project's server (GHSA-x3cm-2j3q-jgg4). A matching `.project-path` and a
	 * live pid are not enough: the pid can be stale and reused, or another
	 * process can hold the port. Ownership needs all of:
	 *
	 *   1. a registration whose `.project-path` is this project;
	 *   2. a live recorded pid whose command line is this registration's
	 *      Lucee server (`-Dcatalina.base=<lucliHome>/servers/<name>`),
	 *      when the OS exposes the command line;
	 *   3. every process LISTENING on the recorded port is that pid.
	 *
	 * Returns `{port, reason, pid, hosts, name, token, challengeRequired}`:
	 * port > 0 only when all hold (then pid is the server process and hosts
	 * the addresses it binds, see boundHosts); otherwise port is 0 and reason
	 * is one of not-registered, registered-elsewhere, not-running, no-port,
	 * pid-not-server, listener-mismatch, unverifiable.
	 *
	 * `name` is the registration that passed, and `token` its per-start
	 * token ("" when it has none; see readStartToken). When the OS cannot
	 * tell who listens (step 3 unknown), a server with a token still passes
	 * with challengeRequired=true: the CLI must then prove each connection
	 * with the token challenge (#3769), since there is nothing to fall back to.
	 */
	public struct function verifyOwnServer(required string projectRoot) {
		var name = serverNameFor(arguments.projectRoot);
		if (!len(name)) return {port: 0, reason: "not-registered", pid: "", hosts: [], name: "", token: "", challengeRequired: false};
		var best = $verifyRegistration(name, arguments.projectRoot);
		if (best.port > 0 || !len(variables.lucliHome)) return best;

		// A registration under another name whose `.project-path` points at
		// this project also counts (#3679: a `lucee.json` name edited after
		// the server started, or a LuCLI naming scheme serverNameFor() does not
		// mirror). It is held to exactly the same proof as the primary one.
		var serversDir = variables.lucliHome & "/servers";
		if (!directoryExists(serversDir)) return best;
		for (var entry in directoryList(serversDir, false, "name")) {
			if (entry == name) continue;
			var candidate = $verifyRegistration(entry, arguments.projectRoot);
			if (candidate.port > 0) return candidate;
			// Prefer the reason from a registration that IS this project's
			// over "not-registered" / "registered-elsewhere" from the primary.
			if (
				listFindNoCase("not-registered,registered-elsewhere", best.reason)
				&& !listFindNoCase("not-registered,registered-elsewhere", candidate.reason)
			) {
				best = candidate;
			}
		}
		return best;
	}

	/**
	 * verifyOwnServer()'s proof for one registration directory,
	 * `<lucliHome>/servers/<name>/`. Public so specs can drive it directly.
	 */
	public struct function $verifyRegistration(required string name, required string projectRoot) {
		var rv = {port: 0, reason: "not-registered", pid: "", hosts: [], name: arguments.name, token: "", challengeRequired: false};
		var name = arguments.name;
		if (!len(name)) return rv;
		var reg = inspect(name, arguments.projectRoot);
		if (!reg.exists) return rv;
		if (!reg.ours) {
			rv.reason = "registered-elsewhere";
			return rv;
		}
		if (!reg.alive) {
			rv.reason = "not-running";
			return rv;
		}

		var regDir = variables.lucliHome & "/servers/" & name;
		var pid = "";
		var port = 0;
		try {
			var raw = trim(fileRead(regDir & "/server.pid"));
			pid = listFirst(raw, ":");
			// LuCLI writes "<pid>:<port>" into server.pid. A pid-only file
			// (older format) has no usable port.
			if (listLen(raw, ":") > 1 && isNumeric(listGetAt(raw, 2, ":"))) {
				port = val(listGetAt(raw, 2, ":"));
			}
		} catch (any e) {}
		if (port <= 0) {
			rv.reason = "no-port";
			return rv;
		}

		var cmdLine = $processCommandLine(pid);
		if (len(cmdLine) && !$commandLineIsServer(cmdLine, regDir)) {
			rv.reason = "pid-not-server";
			return rv;
		}

		// The per-start token (#3769) comes from THIS registration, the one
		// the server runs from (its catalina.base), never from the primary
		// name: under the #3679 fallback the two can differ.
		rv.token = readStartToken(name);
		var owner = listenerOwnedBy(port, pid);
		if (owner == "yes") {
			rv.port = port;
			rv.reason = "";
			rv.pid = pid;
			rv.hosts = boundHosts(pid, port);
		} else if (owner == "unknown" && len(rv.token)) {
			// The OS can't say who listens (no /proc, lsof or netstat), but
			// the server can prove itself per connection: every check above
			// (registration, .project-path, live pid, command line) still
			// holds, and the challenge replaces only the socket introspection.
			rv.port = port;
			rv.reason = "";
			rv.pid = pid;
			rv.hosts = boundHosts(pid, port);
			rv.challengeRequired = true;
		} else {
			rv.reason = owner == "no" ? "listener-mismatch" : "unverifiable";
		}
		return rv;
	}

	// ── Per-start token (#3769) ─────────────────────────────────────

	/**
	 * Give the server registered as `name` a fresh per-start token, readable
	 * by this OS user only: `<lucliHome>/servers/<name>/wheels-cli.token`,
	 * which the server finds in its own catalina.base. Returns true when a
	 * token was written.
	 *
	 * Any token can answer the connection challenge, so it must never be
	 * readable by another user. It is written to a new owner-only temp file in
	 * the same directory and moved over the old one atomically: an in-place
	 * write would keep a leftover file's wider permissions. No token is
	 * issued (and any old one is removed) when the registration directory, or
	 * the servers directory above it, is not a real directory owned by this
	 * user and closed to group/other writes, or carries a macOS ACL (which can
	 * grant, and hand down to new files, access the mode bits don't show);
	 * or on Windows and other platforms whose file access we can't read from
	 * the mode bits. Without a token the CLI proves the server the way it
	 * always has, through the OS.
	 */
	public boolean function writeStartToken(required string name) {
		if (!$tokenStorageSafe(arguments.name)) {
			deleteStartToken(arguments.name);
			return false;
		}
		var files = createObject("java", "java.nio.file.Files");
		var regDir = $path(variables.lucliHome & "/servers/" & arguments.name);
		var tmp = "";
		try {
			tmp = files.createTempFile(regDir, ".wheels-cli-token-", ".tmp", $ownerOnlyAttributes());
			// Checked while the file is still empty, so no secret byte is ever
			// written to a file another user can read.
			if ($hasExtendedAcl(tmp)) throw(type = "Wheels.TokenStorageUnsafe", message = "token file carries an ACL");
			files.write(tmp, charsetDecode(new ServerChallenge().newSecret(), "utf-8"), $writeOptions());
			var moveOptions = $noOptions("java.nio.file.CopyOption", 2);
			var copyOption = createObject("java", "java.nio.file.StandardCopyOption");
			var arrays = createObject("java", "java.lang.reflect.Array");
			arrays.set(moveOptions, javaCast("int", 0), copyOption.ATOMIC_MOVE);
			arrays.set(moveOptions, javaCast("int", 1), copyOption.REPLACE_EXISTING);
			files.move(tmp, regDir.resolve(variables.TOKEN_FILE), moveOptions);
			tmp = "";
		} catch (any e) {
			if (!isSimpleValue(tmp)) {
				try { files.deleteIfExists(tmp); } catch (any cleanupErr) {}
			}
			deleteStartToken(arguments.name);
			return false;
		}
		// Belt and braces: never leave a token another user could read.
		if (!len(readStartToken(arguments.name))) {
			deleteStartToken(arguments.name);
			return false;
		}
		return true;
	}

	/**
	 * The token of the server registered as `name`, or "" when there is
	 * none that is safe to use: the storage checks of writeStartToken()
	 * hold, the file is a regular file (not a link) owned by this user with
	 * no group or other permission bits and no ACL, and it holds exactly 64
	 * lowercase hex characters.
	 */
	public string function readStartToken(required string name) {
		try {
			if (!$tokenStorageSafe(arguments.name)) return "";
			var files = createObject("java", "java.nio.file.Files");
			var tokenPath = $path(variables.lucliHome & "/servers/" & arguments.name & "/" & variables.TOKEN_FILE);
			var noFollow = $noFollow();
			if (!files.isRegularFile(tokenPath, noFollow)) return "";
			if (!$ownedByCurrentUser(tokenPath)) return "";
			var ownerOnly = createObject("java", "java.nio.file.attribute.PosixFilePermissions").fromString("rw-------");
			var perms = files.getPosixFilePermissions(tokenPath, noFollow);
			if (!ownerOnly.containsAll(perms)) return "";
			if ($hasExtendedAcl(tokenPath)) return "";
			var token = trim(charsetEncode(files.readAllBytes(tokenPath), "utf-8"));
			return new ServerChallenge().isNonce(token) ? token : "";
		} catch (any e) {
			return "";
		}
	}

	public void function deleteStartToken(required string name) {
		if (!$isRegistrationName(arguments.name) || !len(variables.lucliHome)) return;
		try {
			createObject("java", "java.nio.file.Files").deleteIfExists(
				$path(variables.lucliHome & "/servers/" & arguments.name & "/" & variables.TOKEN_FILE)
			);
		} catch (any e) {}
	}

	/** Remove the start token of every registration, e.g. after `wheels stop --all`. */
	public void function deleteAllStartTokens() {
		var serversDir = variables.lucliHome & "/servers";
		if (!len(variables.lucliHome) || !directoryExists(serversDir)) return;
		for (var entry in directoryList(serversDir, false, "name")) {
			deleteStartToken(entry);
		}
	}

	/**
	 * The server name a `lucee*.json` config file declares (a relative path
	 * resolves against `projectRoot`), or "" when there is none.
	 */
	public string function serverNameInConfig(required string configPath, string projectRoot = "") {
		var configFile = arguments.configPath;
		if (!fileExists(configFile) && len(arguments.projectRoot)) {
			configFile = arguments.projectRoot & "/" & arguments.configPath;
		}
		return $nameInConfigFile(configFile);
	}

	/**
	 * Name of this project's registration to give a start token: the primary
	 * name when its `.project-path` is this project, else the first other
	 * registration that is this project's and alive. "" when there is none.
	 */
	public string function tokenRegistrationFor(required string projectRoot) {
		var name = serverNameFor(arguments.projectRoot);
		if (len(name) && inspect(name, arguments.projectRoot).ours) return name;
		var serversDir = variables.lucliHome & "/servers";
		if (!len(variables.lucliHome) || !directoryExists(serversDir)) return "";
		for (var entry in directoryList(serversDir, false, "name")) {
			var reg = inspect(entry, arguments.projectRoot);
			if (reg.ours && reg.alive) return entry;
		}
		return "";
	}

	/**
	 * Name of a RUNNING registration that belongs to this project, checking the
	 * name serverNameFor() derives first and then every other registration
	 * whose `.project-path` is this project. After a lucee.json `name` change
	 * the server can still run under its old name. "" when none is alive.
	 */
	public string function aliveRegistrationFor(required string projectRoot) {
		var name = serverNameFor(arguments.projectRoot);
		if (len(name)) {
			var primary = inspect(name, arguments.projectRoot);
			if (primary.ours && primary.alive) return name;
		}
		var serversDir = variables.lucliHome & "/servers";
		if (!len(variables.lucliHome) || !directoryExists(serversDir)) return "";
		for (var entry in directoryList(serversDir, false, "name")) {
			if (entry == name) continue;
			var reg = inspect(entry, arguments.projectRoot);
			if (reg.ours && reg.alive) return entry;
		}
		return "";
	}

	/**
	 * Linux and macOS only; the servers dir and the registration dir are
	 * private to this user. On Linux the mode bits are the whole story (a
	 * POSIX ACL's mask shows in the group bits); macOS ACLs don't show there,
	 * so they are checked separately. Elsewhere we can't tell, so no token.
	 */
	public boolean function $tokenStorageSafe(required string name) {
		if (!$isRegistrationName(arguments.name) || !len(variables.lucliHome)) return false;
		try {
			var fs = createObject("java", "java.nio.file.FileSystems").getDefault();
			if (!fs.supportedFileAttributeViews().contains("posix")) return false;
			if (!listFindNoCase("linux,mac", $aclPlatform())) return false;
			// LUCLI_HOME too: whoever can write it can swap `servers/` under us.
			return $dirIsPrivate($path(variables.lucliHome))
				&& $dirIsPrivate($path(variables.lucliHome & "/servers"))
				&& $dirIsPrivate($path(variables.lucliHome & "/servers/" & arguments.name));
		} catch (any e) {
			return false;
		}
	}

	/** A real directory (not a link), owned by this user, not group- or world-writable, with no macOS ACL. */
	public boolean function $dirIsPrivate(required any dirPath) {
		var files = createObject("java", "java.nio.file.Files");
		var noFollow = $noFollow();
		if (!files.isDirectory(arguments.dirPath, noFollow)) return false;
		if (!$ownedByCurrentUser(arguments.dirPath)) return false;
		var perms = files.getPosixFilePermissions(arguments.dirPath, noFollow);
		var perm = createObject("java", "java.nio.file.attribute.PosixFilePermission");
		if (perms.contains(perm.GROUP_WRITE) || perms.contains(perm.OTHERS_WRITE)) return false;
		return !$hasExtendedAcl(arguments.dirPath);
	}

	/** A single path segment: not empty, no separator, not `.` or `..`. */
	private boolean function $isRegistrationName(required string name) {
		return len(arguments.name) && !reFind("[/\\]|^\.\.?$", arguments.name);
	}

	/** WRITE + TRUNCATE_EXISTING + NOFOLLOW_LINKS: never write the token through a planted link. */
	private any function $writeOptions() {
		var opts = $noOptions("java.nio.file.OpenOption", 3);
		var arrays = createObject("java", "java.lang.reflect.Array");
		var std = createObject("java", "java.nio.file.StandardOpenOption");
		arrays.set(opts, javaCast("int", 0), std.WRITE);
		arrays.set(opts, javaCast("int", 1), std.TRUNCATE_EXISTING);
		arrays.set(opts, javaCast("int", 2), createObject("java", "java.nio.file.LinkOption").NOFOLLOW_LINKS);
		return opts;
	}

	/** "linux", "mac" or "other": decides whether the mode bits describe a file's access. */
	private string function $aclPlatform() {
		var osName = lCase(createObject("java", "java.lang.System").getProperty("os.name"));
		if (findNoCase("linux", osName)) return "linux";
		if (findNoCase("mac", osName)) return "mac";
		return "other";
	}

	/**
	 * Whether `target` carries a macOS extended ACL, which can grant another
	 * user access that its mode bits don't show (and that new files inherit).
	 * Java can't read these on macOS, so ask `ls -led`: ACL entries follow
	 * the first line as ` N: ...`. Anything we can't read counts as an ACL, so
	 * the caller falls back to the OS proof. Always false off macOS.
	 */
	public boolean function $hasExtendedAcl(required any target) {
		if ($aclPlatform() != "mac") return false;
		var result = $runCommand(["/bin/ls", "-led", arguments.target.toString()]);
		if (!result.ran || result.exitCode != 0 || !len(result.output)) return true;
		var lines = listToArray(result.output, chr(10));
		if (reFind("^\S+\+\s", lines[1])) return true;
		for (var i = 2; i <= arrayLen(lines); i++) {
			if (reFind("^\s*[0-9]+: ", lines[i])) return true;
		}
		return false;
	}

	private boolean function $ownedByCurrentUser(required any target) {
		var owner = createObject("java", "java.nio.file.Files").getOwner(arguments.target, $noFollow());
		return owner.getName() == createObject("java", "java.lang.System").getProperty("user.name");
	}

	private any function $path(required string location) {
		return createObject("java", "java.io.File").init(arguments.location).toPath();
	}

	/** A one-element LinkOption[] holding NOFOLLOW_LINKS. */
	private any function $noFollow() {
		var opts = $noOptions("java.nio.file.LinkOption", 1);
		createObject("java", "java.lang.reflect.Array").set(
			opts,
			javaCast("int", 0),
			createObject("java", "java.nio.file.LinkOption").NOFOLLOW_LINKS
		);
		return opts;
	}

	/** A one-element FileAttribute[] for POSIX rw------- (owner read/write only). */
	private any function $ownerOnlyAttributes() {
		var perms = createObject("java", "java.nio.file.attribute.PosixFilePermissions");
		var attrs = $noOptions("java.nio.file.attribute.FileAttribute", 1);
		createObject("java", "java.lang.reflect.Array").set(
			attrs,
			javaCast("int", 0),
			perms.asFileAttribute(perms.fromString("rw-------"))
		);
		return attrs;
	}

	/** A typed Java array of `size` nulls, for varargs parameters. */
	private any function $noOptions(required string className, numeric size = 0) {
		return createObject("java", "java.lang.reflect.Array").newInstance(
			createObject("java", "java.lang.Class").forName(arguments.className),
			javaCast("int", arguments.size)
		);
	}

	/**
	 * Is every process listening on TCP `port` the process `pid`?
	 * Returns "yes", "no" (nothing listens, or something else does too), or
	 * "unknown" when this OS gives no way to tell, which callers must treat
	 * as not owned. Linux reads /proc (no tools needed); Windows uses
	 * netstat; macOS and other Unixes use lsof.
	 */
	public string function listenerOwnedBy(required numeric port, required string pid) {
		if (!isNumeric(arguments.pid) || arguments.port <= 0) return "no";
		var osName = lCase(createObject("java", "java.lang.System").getProperty("os.name"));
		if (fileExists("/proc/net/tcp")) {
			return $listenerOwnedByProc(arguments.port, arguments.pid);
		}
		var listeners = findNoCase("windows", osName)
			? $windowsListeningPids(arguments.port)
			: $lsofListeningPids(arguments.port);
		if (!listeners.known) return "unknown";
		if (!arrayLen(listeners.pids)) return "no";
		for (var listenerPid in listeners.pids) {
			if (listenerPid != arguments.pid) return "no";
		}
		return "yes";
	}

	/**
	 * Does process `pid` hold the server end of the TCP connection whose
	 * CLIENT end is our local port `clientPort`, connected to `serverPort`?
	 *
	 * This is the peer-identity check (GHSA-x3cm-2j3q-jgg4): the CLI opens a
	 * connection, asks this, and only then writes the request on that same
	 * connection. It inspects only the server process's own sockets, so a
	 * squatter owned by another OS user (invisible to an unprivileged lsof)
	 * still fails it: the server simply does not hold the peer socket.
	 *
	 * Returns "yes", "no" (not held by `pid`, or not accepted yet: callers
	 * poll briefly), or "unknown" (no way to tell on this OS; fail closed).
	 */
	public string function peerHeldBy(required string pid, required numeric serverPort, required numeric clientPort) {
		if (!isNumeric(arguments.pid)) return "no";
		if (fileExists("/proc/net/tcp")) {
			return $peerHeldByProc(arguments.pid, arguments.serverPort, arguments.clientPort);
		}

		var osName = lCase(createObject("java", "java.lang.System").getProperty("os.name"));
		if (findNoCase("windows", osName)) {
			return $peerHeldByNetstat(arguments.pid, arguments.serverPort, arguments.clientPort);
		}
		return $peerHeldByLsof(arguments.pid, arguments.serverPort, arguments.clientPort);
	}

	/**
	 * peerHeldBy() on Linux: the ESTABLISHED sockets from /proc/net/tcp{,6}
	 * whose local end is `serverPort` and remote end is `clientPort`, matched
	 * by inode against the sockets `pid` holds open.
	 */
	public string function $peerHeldByProc(required string pid, required numeric serverPort, required numeric clientPort) {
		var inodes = $procEstablishedInodes(arguments.serverPort, arguments.clientPort);
		if (!arrayLen(inodes)) return "no";
		var held = $procSocketInodes(arguments.pid);
		if (isNull(held)) return "unknown";
		for (var inode in inodes) {
			if (structKeyExists(held, inode)) return "yes";
		}
		return "no";
	}

	/**
	 * Inodes of the ESTABLISHED sockets in /proc/net/tcp{,6} whose local end
	 * is `serverPort` and remote end is `clientPort`.
	 */
	public array function $procEstablishedInodes(required numeric serverPort, required numeric clientPort) {
		var inodes = [];
		for (var table in ["/proc/net/tcp", "/proc/net/tcp6"]) {
			if (!fileExists(table)) continue;
			var lines = listToArray(fileRead(table), chr(10));
			for (var n = 2; n <= arrayLen(lines); n++) {
				var cols = listToArray(trim(lines[n]), " ");
				if (arrayLen(cols) < 10 || cols[4] != "01") continue;
				if (
					inputBaseN(listLast(cols[2], ":"), 16) == arguments.serverPort
					&& inputBaseN(listLast(cols[3], ":"), 16) == arguments.clientPort
					&& cols[10] != "0"
				) {
					arrayAppend(inodes, cols[10]);
				}
			}
		}
		return inodes;
	}

	/**
	 * peerHeldBy() on Windows: the TCP (and TCPv6) connection from netstat
	 * whose local end is `serverPort` and remote end is `clientPort`, and the
	 * pid that owns it.
	 */
	public string function $peerHeldByNetstat(required string pid, required numeric serverPort, required numeric clientPort) {
		var result = $runCommand(["netstat", "-ano", "-p", "TCP"]);
		var result6 = $runCommand(["netstat", "-ano", "-p", "TCPv6"]);
		if (!result.ran || result.exitCode != 0) return "unknown";
		for (var line in listToArray(result.output & chr(10) & (result6.ran ? result6.output : ""), chr(10) & chr(13))) {
			var cols = listToArray(trim(line), " " & chr(9));
			if (
				arrayLen(cols) == 5
				&& listLast(cols[2], ":") == arguments.serverPort
				&& listLast(cols[3], ":") == arguments.clientPort
			) {
				return cols[5] == arguments.pid ? "yes" : "no";
			}
		}
		return "no";
	}

	/**
	 * peerHeldBy() on macOS and other Unixes: `pid`'s TCP connections on
	 * `clientPort` from lsof, looking for one whose ends are `serverPort`
	 * and `clientPort`.
	 */
	public string function $peerHeldByLsof(required string pid, required numeric serverPort, required numeric clientPort) {
		var lsof = $lsofPath();
		if (!len(lsof)) return "unknown";
		var result = $runCommand([lsof, "-nP", "-a", "-p", arguments.pid, "-iTCP:" & arguments.clientPort, "-Fn"]);
		if (!result.ran) return "unknown";
		for (var line in listToArray(result.output, chr(10) & chr(13))) {
			if (left(line, 1) != "n" || !find("->", line)) continue;
			var ends = listToArray(mid(line, 2, len(line)), "->", false, true);
			if (
				arrayLen(ends) == 2
				&& listLast(ends[1], ":") == arguments.serverPort
				&& listLast(ends[2], ":") == arguments.clientPort
			) {
				return "yes";
			}
		}
		return "no";
	}

	/**
	 * The addresses to connect to for `pid`'s listener on `port`, taken
	 * from what it actually binds, never from resolving "localhost": an
	 * IPv4 or dual-stack wildcard and 127.0.0.1 give 127.0.0.1 first; an
	 * IPv6 wildcard also allows ::1; an IPv6-loopback-only server gives ::1;
	 * a specific address gives that address. Defaults to 127.0.0.1.
	 */
	public array function boundHosts(required string pid, required numeric port) {
		var addrs = $listenAddresses(arguments.pid, arguments.port);
		var wanted = [];
		for (var a in addrs) {
			if (a == "0.0.0.0" || a == "127.0.0.1" || a == "*4") arrayAppend(wanted, "127.0.0.1");
		}
		for (var a in addrs) {
			if (a == "*6" || a == "::") {
				arrayAppend(wanted, "127.0.0.1");
				arrayAppend(wanted, "::1");
			}
			if (a == "::1") arrayAppend(wanted, "::1");
		}
		for (var a in addrs) {
			if (len(a) && !listFindNoCase("0.0.0.0,127.0.0.1,*4,*6,::,::1", a)) arrayAppend(wanted, a);
		}
		var hosts = [];
		for (var h in wanted) {
			if (!arrayFindNoCase(hosts, h)) arrayAppend(hosts, h);
		}
		if (!arrayLen(hosts)) arrayAppend(hosts, "127.0.0.1");
		return hosts;
	}

	/**
	 * Listen addresses of `pid` on `port`: "0.0.0.0", "::", "*4"/"*6"
	 * (wildcard of that family, as lsof reports it), or a literal address.
	 */
	private array function $listenAddresses(required string pid, required numeric port) {
		var addrs = [];
		if (fileExists("/proc/net/tcp")) {
			var held = $procSocketInodes(arguments.pid);
			if (isNull(held)) return addrs;
			for (var table in ["/proc/net/tcp", "/proc/net/tcp6"]) {
				if (!fileExists(table)) continue;
				var lines = listToArray(fileRead(table), chr(10));
				for (var n = 2; n <= arrayLen(lines); n++) {
					var cols = listToArray(trim(lines[n]), " ");
					if (arrayLen(cols) < 10 || cols[4] != "0A" || !structKeyExists(held, cols[10])) continue;
					if (inputBaseN(listLast(cols[2], ":"), 16) != arguments.port) continue;
					var decoded = $procHexAddress(listFirst(cols[2], ":"));
					if (len(decoded)) arrayAppend(addrs, decoded);
				}
			}
			return addrs;
		}
		var osName = lCase(createObject("java", "java.lang.System").getProperty("os.name"));
		if (findNoCase("windows", osName)) {
			var result = $runCommand(["netstat", "-ano"]);
			if (!result.ran) return addrs;
			for (var line in listToArray(result.output, chr(10) & chr(13))) {
				var cols = listToArray(trim(line), " " & chr(9));
				if (arrayLen(cols) == 5 && cols[5] == arguments.pid && listLast(cols[3], ":") == "0" && listLast(cols[2], ":") == arguments.port) {
					var localAddr = reReplace(cols[2], ":\d+$", "");
					arrayAppend(addrs, replace(replace(localAddr, "[", ""), "]", ""));
				}
			}
			return addrs;
		}
		var lsof = $lsofPath();
		if (!len(lsof)) return addrs;
		var result = $runCommand([lsof, "-nP", "-a", "-p", arguments.pid, "-iTCP:" & arguments.port, "-sTCP:LISTEN", "-Ftn"]);
		if (!result.ran) return addrs;
		var family = "";
		for (var line in listToArray(result.output, chr(10) & chr(13))) {
			if (left(line, 1) == "t") family = mid(line, 2, len(line));
			if (left(line, 1) != "n") continue;
			var localAddr = reReplace(mid(line, 2, len(line)), ":\d+$", "");
			if (localAddr == "*") {
				arrayAppend(addrs, family == "IPv6" ? "*6" : "*4");
			} else {
				arrayAppend(addrs, replace(replace(localAddr, "[", ""), "]", ""));
			}
		}
		return addrs;
	}

	/**
	 * A /proc/net/tcp{,6} local address (hex, 32-bit words in host byte
	 * order) as a connectable literal: "0.0.0.0", "::", "127.0.0.1", "::1",
	 * an IPv4-mapped address as plain IPv4, or any other specific address,
	 * so a server bound to e.g. 192.168.1.5 is reached there.
	 */
	public string function $procHexAddress(required string hex) {
		if (!reFind("^[0-9A-Fa-f]{8}([0-9A-Fa-f]{24})?$", arguments.hex)) return "";
		var bytes = [];
		for (var w = 0; w < len(arguments.hex) / 8; w++) {
			var word = mid(arguments.hex, w * 8 + 1, 8);
			// Each 32-bit word is little-endian on the machines /proc runs on.
			for (var b = 4; b >= 1; b--) {
				arrayAppend(bytes, inputBaseN(mid(word, (b - 1) * 2 + 1, 2), 16));
			}
		}
		if (arrayLen(bytes) == 4) {
			return arrayToList(bytes, ".");
		}
		var allZero = true;
		for (var i = 1; i <= 16; i++) {
			if (bytes[i] != 0) allZero = false;
		}
		if (allZero) return "::";
		var mapped = bytes[11] == 255 && bytes[12] == 255;
		for (var i = 1; i <= 10; i++) {
			if (bytes[i] != 0) mapped = false;
		}
		if (mapped) return bytes[13] & "." & bytes[14] & "." & bytes[15] & "." & bytes[16];
		var loopback = bytes[16] == 1;
		for (var i = 1; i <= 15; i++) {
			if (bytes[i] != 0) loopback = false;
		}
		if (loopback) return "::1";
		var groups = [];
		for (var i = 1; i <= 16; i += 2) {
			arrayAppend(groups, lCase(formatBaseN(bytes[i] * 256 + bytes[i + 1], 16)));
		}
		return arrayToList(groups, ":");
	}

	/** Socket inodes held by `pid` (Linux /proc), or null if unreadable. */
	private any function $procSocketInodes(required string pid) {
		var fdDir = "/proc/" & arguments.pid & "/fd";
		var held = {};
		try {
			var files = createObject("java", "java.nio.file.Files");
			for (var fd in directoryList(fdDir, false, "name")) {
				try {
					var target = files.readSymbolicLink(createObject("java", "java.io.File").init(fdDir & "/" & fd).toPath()).toString();
					var m = reFind("^socket:\[(\d+)\]$", target, 1, true);
					if (arrayLen(m.match) > 1) held[m.match[2]] = true;
				} catch (any e) {}
			}
		} catch (any e) {
			return javaCast("null", "");
		}
		return held;
	}

	private string function $lsofPath() {
		for (var bin in ["/usr/sbin/lsof", "/usr/bin/lsof", "/sbin/lsof", "/bin/lsof"]) {
			if (fileExists(bin)) return bin;
		}
		return "";
	}

	/**
	 * Executable path of `pid`, or "" when the OS does not expose it.
	 * Public so specs can stub it.
	 */
	public string function $processCommand(required string pid) {
		try {
			var handle = createObject("java", "java.lang.ProcessHandle").of(javaCast("long", arguments.pid));
			if (handle.isPresent()) {
				var cmd = handle.get().info().command();
				if (cmd.isPresent()) return cmd.get();
			}
		} catch (any e) {}
		return "";
	}

	/**
	 * Command line of `pid`, or "" when the OS does not expose it (then the
	 * listener check alone decides). Public so specs can stub it.
	 */
	public string function $processCommandLine(required string pid) {
		try {
			var handle = createObject("java", "java.lang.ProcessHandle").of(javaCast("long", arguments.pid));
			if (handle.isPresent()) {
				var cmd = handle.get().info().commandLine();
				if (cmd.isPresent()) return cmd.get();
			}
		} catch (any e) {}
		return "";
	}

	private boolean function $commandLineIsServer(required string cmdLine, required string regDir) {
		var candidates = [arguments.regDir];
		try {
			arrayAppend(candidates, createObject("java", "java.io.File").init(arguments.regDir).getCanonicalPath());
		} catch (any e) {}
		var normalized = replace(arguments.cmdLine, "\", "/", "all");
		for (var dir in candidates) {
			var d = replace(dir, "\", "/", "all");
			if (find("catalina.base=" & d & " ", normalized & " ") || find("catalina.base=""" & d & """", normalized)) {
				return true;
			}
		}
		return false;
	}

	/**
	 * Linux: the LISTEN sockets on `port` from /proc/net/tcp{,6}, matched by
	 * inode against the sockets `pid` holds open in /proc/<pid>/fd.
	 */
	private string function $listenerOwnedByProc(required numeric port, required string pid) {
		var inodes = [];
		for (var table in ["/proc/net/tcp", "/proc/net/tcp6"]) {
			if (!fileExists(table)) continue;
			var lines = listToArray(fileRead(table), chr(10));
			for (var n = 2; n <= arrayLen(lines); n++) {
				var cols = listToArray(trim(lines[n]), " ");
				if (arrayLen(cols) < 10 || cols[4] != "0A") continue;
				if (inputBaseN(listLast(cols[2], ":"), 16) == arguments.port && cols[10] != "0") {
					arrayAppend(inodes, cols[10]);
				}
			}
		}
		if (!arrayLen(inodes)) return "no";

		var held = $procSocketInodes(arguments.pid);
		if (isNull(held)) return "unknown";
		for (var inode in inodes) {
			if (!structKeyExists(held, inode)) return "no";
		}
		return "yes";
	}

	private struct function $lsofListeningPids(required numeric port) {
		var bin = $lsofPath();
		if (len(bin)) {
			var result = $runCommand([bin, "-nP", "-iTCP:" & arguments.port, "-sTCP:LISTEN", "-t"]);
			// lsof exits 1 with no output when nothing matches.
			if (!result.ran || (result.exitCode != 0 && len(trim(result.output)))) {
				return {known: false, pids: []};
			}
			var pids = [];
			for (var line in listToArray(result.output, chr(10) & chr(13))) {
				if (isNumeric(trim(line))) arrayAppend(pids, trim(line));
			}
			return {known: true, pids: pids};
		}
		return {known: false, pids: []};
	}

	private struct function $windowsListeningPids(required numeric port) {
		var result = $runCommand(["netstat", "-ano", "-p", "TCP"]);
		var result6 = $runCommand(["netstat", "-ano", "-p", "TCPv6"]);
		if (!result.ran || result.exitCode != 0) return {known: false, pids: []};
		var pids = [];
		for (var line in listToArray(result.output & chr(10) & (result6.ran ? result6.output : ""), chr(10) & chr(13))) {
			// Proto, Local, Foreign, State, PID. State is localized, so a
			// listener is recognized by its unconnected foreign address
			// (0.0.0.0:0 / [::]:0) instead of the word LISTENING.
			var cols = listToArray(trim(line), " " & chr(9));
			if (
				arrayLen(cols) == 5
				&& cols[1] == "TCP"
				&& listLast(cols[3], ":") == "0"
				&& listLast(cols[2], ":") == arguments.port
				&& isNumeric(cols[5])
			) {
				arrayAppend(pids, cols[5]);
			}
		}
		return {known: true, pids: pids};
	}

	/**
	 * Runs an introspection command (lsof, netstat, ls) and returns its exit code
	 * and output. Bounded: output goes to a temp file (no pipe to fill or block on)
	 * and a command still running after `timeoutSeconds` is killed and reported as
	 * not run, the same as a missing command, so a stuck lsof can't hang the CLI.
	 */
	private struct function $runCommand(required array cmdArgs, numeric timeoutSeconds = 15) {
		var outFile = getTempFile(getTempDirectory(), "wheels-cmd");
		try {
			var pb = createObject("java", "java.lang.ProcessBuilder").init(arguments.cmdArgs);
			pb.redirectErrorStream(true);
			pb.redirectOutput(createObject("java", "java.io.File").init(outFile));
			var proc = pb.start();
			var finished = proc.waitFor(
				javaCast("long", arguments.timeoutSeconds),
				createObject("java", "java.util.concurrent.TimeUnit").SECONDS
			);
			if (!finished) {
				proc.destroyForcibly();
				return {ran: false, exitCode: -1, output: ""};
			}
			return {ran: true, exitCode: proc.exitValue(), output: fileRead(outFile, "utf-8")};
		} catch (any e) {
			return {ran: false, exitCode: -1, output: ""};
		} finally {
			// Best effort: on Windows a file the killed process still holds can't
			// be deleted yet, and that must not replace the result.
			try {
				if (fileExists(outFile)) fileDelete(outFile);
			} catch (any cleanupError) {
			}
		}
	}

	/**
	 * Wipe a stale `<lucliHome>/servers/<name>/` registration directory so
	 * the next `wheels start` boots cleanly. Best-effort — silently ignores
	 * lock-induced delete failures (rare, but possible on Windows when a
	 * dead process still holds a handle on a child file).
	 */
	public void function clean(required string serverName) {
		if (!len(arguments.serverName) || !len(variables.lucliHome)) return;
		try {
			var regDir = variables.lucliHome & "/servers/" & arguments.serverName;
			if (directoryExists(regDir)) {
				directoryDelete(regDir, true);
			}
		} catch (any e) {}
	}

	/**
	 * The non-empty string `name` from `<projectRoot>/lucee.json`, or "" when
	 * the file is missing, malformed, or carries no usable name.
	 */
	private string function $configuredServerName(required string projectRoot) {
		return $nameInConfigFile(arguments.projectRoot & "/lucee.json");
	}

	private string function $nameInConfigFile(required string configFile) {
		if (!len(arguments.configFile) || !fileExists(arguments.configFile)) return "";
		try {
			var cfg = deserializeJSON(fileRead(arguments.configFile));
			if (isStruct(cfg) && structKeyExists(cfg, "name") && isSimpleValue(cfg.name)) {
				return trim(cfg.name);
			}
		} catch (any e) {}
		return "";
	}

	/**
	 * True if the given POSIX pid is alive. Uses `kill -0` semantics via
	 * Java's ProcessHandle (Java 9+) so we don't shell out.
	 */
	private boolean function $isProcessAlive(required string pid) {
		try {
			var ProcessHandle = createObject("java", "java.lang.ProcessHandle");
			var optional = ProcessHandle.of(javaCast("long", arguments.pid));
			if (optional.isPresent()) {
				return optional.get().isAlive();
			}
		} catch (any e) {}
		return false;
	}

}
