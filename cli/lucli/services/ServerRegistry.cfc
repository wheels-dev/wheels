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
	 * Server name LuCLI assigns to a project rooted at the given path —
	 * the basename of the directory, computed via Java so it's portable
	 * across `/` and `\` separators. Mirrors LuCLI's own derivation; if
	 * LuCLI ever moves to a different scheme this needs to follow.
	 */
	public string function serverNameFor(required string projectRoot) {
		if (!len(arguments.projectRoot)) return "";
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
