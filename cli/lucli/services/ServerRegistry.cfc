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
	 * Port of the project's OWN running Lucee server, resolved from the
	 * registry (`.project-path` matches this project AND the recorded pid is
	 * alive). Returns 0 when no such server is registered or alive.
	 *
	 * This is the authoritative "is MY server running" answer — unlike a
	 * bare port probe, it proves ownership via the `.project-path` marker,
	 * so callers that must not attach to a sibling app (e.g. `wheels test`)
	 * can refuse when it returns 0 instead of falling back to a heuristic
	 * port that may belong to a different project.
	 */
	public numeric function ownServerPort(required string projectRoot) {
		if (!len(variables.lucliHome)) return 0;
		var name = serverNameFor(arguments.projectRoot);
		if (!len(name)) return 0;
		var port = $ownRegistrationPort(name, arguments.projectRoot);
		if (port > 0) return port;

		// Fallback: any registration whose `.project-path` points at this
		// project proves ownership regardless of the name it was registered
		// under — covers a `lucee.json` name edited after the server started,
		// or a LuCLI naming scheme this service doesn't mirror (#3679).
		var serversDir = variables.lucliHome & "/servers";
		if (!directoryExists(serversDir)) return 0;
		for (var entry in directoryList(serversDir, false, "name")) {
			if (entry == name) continue;
			port = $ownRegistrationPort(entry, arguments.projectRoot);
			if (port > 0) return port;
		}
		return 0;
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
	 * Port recorded by the registration `<lucliHome>/servers/<serverName>/`
	 * when it is alive AND its `.project-path` matches this project; 0
	 * otherwise (including a pid-only `server.pid` with no port segment).
	 */
	private numeric function $ownRegistrationPort(
		required string serverName,
		required string projectRoot
	) {
		var reg = inspect(arguments.serverName, arguments.projectRoot);
		if (!reg.alive || !reg.ours) return 0;

		var pidFile = variables.lucliHome & "/servers/" & arguments.serverName & "/server.pid";
		if (!fileExists(pidFile)) return 0;
		try {
			var raw = trim(fileRead(pidFile));
			// LuCLI writes "<pid>:<port>" into server.pid. Split off the
			// port; a pid-only file (older format) has no usable port.
			if (listLen(raw, ":") > 1) {
				var port = listGetAt(raw, 2, ":");
				if (isNumeric(port) && val(port) > 0) return val(port);
			}
		} catch (any e) {}
		return 0;
	}

	/**
	 * The non-empty string `name` from `<projectRoot>/lucee.json`, or "" when
	 * the file is missing, malformed, or carries no usable name.
	 */
	private string function $configuredServerName(required string projectRoot) {
		var configFile = arguments.projectRoot & "/lucee.json";
		if (!fileExists(configFile)) return "";
		try {
			var cfg = deserializeJSON(fileRead(configFile));
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
