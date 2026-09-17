/**
 * RustCFML engine backend for the Wheels CLI.
 *
 * RustCFML is a JVM-free CFML interpreter distributed as a single static
 * binary from github.com/RustCFML/RustCFML. It serves a Wheels app's
 * `public/` directory directly:
 *
 *   rustcfml --serve public --port 8513
 *
 * This service provides the CLI-facing lifecycle for that backend:
 *
 *   install  — download + cache the pinned binary for this platform
 *   start    — spawn `rustcfml --serve` as a detached background process,
 *              recording pid/port in a per-project state file
 *   stop     — kill the recorded pid and clear the state file
 *   status   — report whether a server is recorded and alive
 *
 * It is deliberately SEPARATE from LuCLI's server registry (which manages
 * Lucee Express + a JDK) — RustCFML has no JDK, no Lucee Express, no
 * CommandBox module, so it needs its own process/port lifecycle. Wiring
 * `wheels start --engine=rustcfml` and the HTTP-based commands to discover
 * this backend is a follow-up (see docs/releases/wheels-4.x-backlog.md #21).
 */
component {

	/**
	 * Pinned engine version. Keep in sync with tools/rustcfml/ENGINE_VERSION
	 * (the CI leg and compat matrix pin the same build).
	 */
	variables.engineVersion = "v0.637.0";

	variables.wheelsHome = "";

	public RustCFMLEngine function init() {
		variables.wheelsHome = $resolveWheelsHome();
		return this;
	}

	// -------------------------------------------------------------------------
	// Public lifecycle
	// -------------------------------------------------------------------------

	/**
	 * Download (if needed) and cache the RustCFML binary for this platform.
	 * Returns the absolute path to the executable.
	 */
	public string function install() {
		var asset = assetName();
		var binDir = variables.wheelsHome & "/rustcfml/bin";
		var binPath = binDir & "/rustcfml-" & variables.engineVersion;
		if (fileExists(binPath)) {
			return binPath;
		}

		if (!directoryExists(binDir)) {
			directoryCreate(binDir, true);
		}
		var url = "https://github.com/RustCFML/RustCFML/releases/download/"
			& variables.engineVersion & "/" & asset;
		var exit = $runSync(["curl", "-sSL", "--fail", "-o", binPath, url]);
		if (exit != 0) {
			if (fileExists(binPath)) fileDelete(binPath);
			throw(
				type = "Wheels.RustCFML.InstallFailed",
				message = "Could not download RustCFML " & variables.engineVersion & " (" & asset & ") from " & url
			);
		}
		$runSync(["chmod", "+x", binPath]);
		return binPath;
	}

	/**
	 * Start a detached RustCFML server for the project. Returns a struct
	 * {pid, port, log, statePath}.
	 */
	public struct function start(required string projectRoot, numeric port = 8513) {
		if (!$isWheelsProject(arguments.projectRoot)) {
			throw(
				type = "Wheels.RustCFML.NotWheelsProject",
				message = "No config/settings.cfm under " & arguments.projectRoot & " — run from a Wheels project directory."
			);
		}

		var existing = status(arguments.projectRoot);
		if (existing.running) {
			throw(
				type = "Wheels.RustCFML.AlreadyRunning",
				message = "A RustCFML server is already running for this project (pid " & existing.pid & ", port " & existing.port & ")."
			);
		}

		var bin = install();
		var logPath = variables.wheelsHome & "/rustcfml/servers/" & $projectKey(arguments.projectRoot) & ".log";
		$ensureParent(logPath);

		var pb = createObject("java", "java.lang.ProcessBuilder").init(
			[bin, "--serve", "public", "--port", toString(arguments.port)]
		);
		// Run from the project root so `public` resolves, and detach I/O to a
		// log file so the server survives this command's exit without tying
		// itself to the CLI's stdout pipe.
		pb.directory(createObject("java", "java.io.File").init(arguments.projectRoot));
		pb.redirectOutput(createObject("java", "java.io.File").init(logPath));
		pb.redirectError(createObject("java", "java.io.File").init(logPath));
		var proc = pb.start();

		var state = {
			pid = proc.pid(),
			port = arguments.port,
			binary = bin,
			projectRoot = arguments.projectRoot,
			startedAt = now()
		};
		$writeState(arguments.projectRoot, state);
		state.log = logPath;
		return state;
	}

	/**
	 * Stop a recorded RustCFML server. Returns true if one was killed,
	 * false when nothing was recorded.
	 */
	public boolean function stop(required string projectRoot) {
		var statePath = $statePath(arguments.projectRoot);
		if (!fileExists(statePath)) return false;
		var state = $readState(arguments.projectRoot);
		if (structKeyExists(state, "pid") && state.pid > 0) {
			$kill(state.pid);
		}
		fileDelete(statePath);
		return true;
	}

	/**
	 * Report the recorded state and whether the process is still alive.
	 */
	public struct function status(required string projectRoot) {
		var state = $readState(arguments.projectRoot);
		var running = false;
		if (structCount(state) && structKeyExists(state, "pid")) {
			running = $isAlive(state.pid);
		}
		state.running = running;
		return state;
	}

	// -------------------------------------------------------------------------
	// Pure helpers (unit-testable without spawning processes)
	// -------------------------------------------------------------------------

	/**
	 * Map the current OS/arch to the RustCFML release asset name.
	 * Mirrors tools/rustcfml/run-suite.sh.
	 */
	public string function assetName() {
		var os = createObject("java", "java.lang.System").getProperty("os.name");
		var arch = createObject("java", "java.lang.System").getProperty("os.arch");
		var isMac = findNoCase("mac", os) > 0;
		var isLinux = findNoCase("linux", os) > 0;
		var isArm = findNoCase("aarch64", arch) > 0 || findNoCase("arm64", arch) > 0;
		var isX64 = findNoCase("amd64", arch) > 0 || findNoCase("x86_64", arch) > 0;

		if (isMac && isArm) return "rustcfml-macos-aarch64";
		if (isMac && isX64) return "rustcfml-macos-x86_64";
		if (isLinux && isArm) return "rustcfml-linux-aarch64";
		if (isLinux && isX64) return "rustcfml-linux-x86_64";
		throw(
			type = "Wheels.RustCFML.UnsupportedPlatform",
			message = "No RustCFML binary for " & os & " / " & arch
		);
	}

	/**
	 * A stable filesystem-safe key for a project root.
	 */
	public string function $projectKey(required string projectRoot) {
		return hash(arguments.projectRoot, "MD5");
	}

	/**
	 * Absolute path to the per-project state file.
	 */
	public string function $statePath(required string projectRoot) {
		return variables.wheelsHome & "/rustcfml/servers/" & $projectKey(arguments.projectRoot) & ".json";
	}

	private struct function $readState(required string projectRoot) {
		var statePath = $statePath(arguments.projectRoot);
		if (!fileExists(statePath)) return {};
		try {
			return deserializeJSON(fileRead(statePath));
		} catch (any e) {
			return {};
		}
	}

	private void function $writeState(required string projectRoot, required struct state) {
		var statePath = $statePath(arguments.projectRoot);
		$ensureParent(statePath);
		fileWrite(statePath, serializeJSON(arguments.state));
	}

	private void function $ensureParent(required string path) {
		var dir = getDirectoryFromPath(arguments.path);
		if (!directoryExists(dir)) {
			directoryCreate(dir, true);
		}
	}

	// -------------------------------------------------------------------------
	// Process plumbing
	// -------------------------------------------------------------------------

	/**
	 * Run a command to completion; return its exit code. Used for the
	 * blocking curl download and the chmod call.
	 */
	public numeric function $runSync(required array cmdArgs) {
		var pb = createObject("java", "java.lang.ProcessBuilder").init(arguments.cmdArgs);
		pb.redirectErrorStream(true);
		var proc = pb.start();
		return proc.waitFor();
	}

	private numeric function $kill(required numeric pid) {
		var os = createObject("java", "java.lang.System").getProperty("os.name");
		var pidStr = toString(arguments.pid);
		if (findNoCase("win", os) > 0) {
			return $runSync(["taskkill", "/PID", pidStr, "/F"]);
		}
		return $runSync(["kill", pidStr]);
	}

	private boolean function $isAlive(required numeric pid) {
		var os = createObject("java", "java.lang.System").getProperty("os.name");
		var pidStr = toString(arguments.pid);
		if (findNoCase("win", os) > 0) {
			return $runSync(["tasklist", "/FI", "PID eq " & pidStr]) == 0;
		}
		// kill -0 is a POSIX "is it alive?" probe with no signal.
		return $runSync(["kill", "-0", pidStr]) == 0;
	}

	private string function $resolveWheelsHome() {
		try {
			var sys = createObject("java", "java.lang.System");
			var home = sys.getenv("LUCLI_HOME");
			if (isNull(home) || !len(trim(home))) {
				home = sys.getProperty("user.home") & "/.wheels";
			}
			return home;
		} catch (any e) {
			return "/tmp/.wheels";
		}
	}

	private boolean function $isWheelsProject(required string projectRoot) {
		return fileExists(arguments.projectRoot & "/config/settings.cfm");
	}

}
