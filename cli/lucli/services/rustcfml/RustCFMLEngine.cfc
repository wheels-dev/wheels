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
 *   install  — download, verify (pinned sha256) + cache the pinned binary
 *              for this platform
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
	 * Pinned engine version: the build the framework is tested against. It
	 * must equal tools/rustcfml/ENGINE_VERSION (the CI leg and the compat
	 * matrix run that build). The installed CLI doesn't ship tools/, so the pin
	 * lives here too: tools/rustcfml/bump-pin.sh rewrites this line when
	 * check-version.sh bumps ENGINE_VERSION, and RustCFMLEnginePinSpec fails
	 * on drift (#3812).
	 */
	variables.engineVersion = "v0.693.0";

	/**
	 * sha256 of each release asset of the pinned version. install() refuses a
	 * binary that doesn't match. These must equal tools/rustcfml/ENGINE_SHA256;
	 * tools/rustcfml/bump-pin.sh rewrites these lines from the release's
	 * published digests when it moves the pin, and RustCFMLEnginePinSpec fails
	 * on drift.
	 */
	variables.engineSha256 = {};
	variables.engineSha256["rustcfml-linux-aarch64"] = "95c74453632ab3da99b06e24b36539b3af642cdc29b60e38ebe4fe60a356d523";
	variables.engineSha256["rustcfml-linux-x86_64"] = "cb053823ddbebf5d130e5a0eaf564a2148d0d93c6781f253e4cd52e8a7bd75fb";
	variables.engineSha256["rustcfml-macos-aarch64"] = "890a970d31a49d98c779722aad86ac8846fdaad10901edb74078e814c495e333";

	variables.wheelsHome = "";

	/** The pinned RustCFML release tag, e.g. "v0.693.0". */
	public string function getEngineVersion() {
		return variables.engineVersion;
	}

	/** The pinned sha256 per release asset name (a copy). */
	public struct function getEngineSha256() {
		return duplicate(variables.engineSha256);
	}

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
	 *
	 * The binary is only ever used after its sha256 matches the pin for its
	 * release asset. A cached binary that doesn't match is discarded and
	 * downloaded again. A download goes to a temp file next to the final path,
	 * is verified, made executable, and only then renamed into place; on any
	 * failure the temp file is deleted and Wheels.RustCFML.InstallFailed (or
	 * Wheels.RustCFML.ChecksumMismatch for a mismatched download) is thrown.
	 */
	public string function install() {
		var asset = assetName();
		var expected = $expectedSha256(asset);
		var binDir = variables.wheelsHome & "/rustcfml/bin";
		var binPath = binDir & "/rustcfml-" & variables.engineVersion;
		if (fileExists(binPath)) {
			if ($sha256File(binPath) == expected) {
				return binPath;
			}
			// Never use a cached binary that doesn't match the pin.
			fileDelete(binPath);
		}

		if (!directoryExists(binDir)) {
			directoryCreate(binDir, true);
		}
		var downloadUrl = "https://github.com/RustCFML/RustCFML/releases/download/"
			& variables.engineVersion & "/" & asset;
		var tempPath = binPath & ".download-" & createUUID();
		try {
			var exit = $runSync(["curl", "-sSL", "--fail", "-o", tempPath, downloadUrl]);
			if (exit != 0) {
				throw(
					type = "Wheels.RustCFML.InstallFailed",
					message = "Could not download RustCFML " & variables.engineVersion & " (" & asset & ") from " & downloadUrl
				);
			}
			var actual = fileExists(tempPath) ? $sha256File(tempPath) : "";
			if (actual != expected) {
				throw(
					type = "Wheels.RustCFML.ChecksumMismatch",
					message = "The RustCFML " & variables.engineVersion & " download (" & asset & ") does not match its pinned sha256; it was deleted and not installed.",
					detail = "Expected sha256 " & expected & ", got " & (len(actual) ? actual : "no file") & " from " & downloadUrl & "."
				);
			}
			var tempFile = createObject("java", "java.io.File").init(tempPath);
			if (!tempFile.setExecutable(true, false) || !tempFile.renameTo(createObject("java", "java.io.File").init(binPath))) {
				throw(
					type = "Wheels.RustCFML.InstallFailed",
					message = "Could not install the verified RustCFML " & variables.engineVersion & " binary at " & binPath
				);
			}
		} catch (any e) {
			if (fileExists(tempPath)) fileDelete(tempPath);
			rethrow;
		}
		return binPath;
	}

	/**
	 * The pinned sha256 for release asset `asset`, or
	 * Wheels.RustCFML.InstallFailed when none is pinned (nothing unverified is
	 * ever downloaded or run).
	 */
	public string function $expectedSha256(required string asset) {
		if (!structKeyExists(variables.engineSha256, arguments.asset) || !len(variables.engineSha256[arguments.asset])) {
			throw(
				type = "Wheels.RustCFML.InstallFailed",
				message = "No sha256 is pinned for RustCFML " & variables.engineVersion & " (" & arguments.asset & "), so it can't be verified and won't be installed."
			);
		}
		return lCase(variables.engineSha256[arguments.asset]);
	}

	/** Lowercase hex sha256 of the file at `path`, read in chunks. */
	public string function $sha256File(required string path) {
		var digest = createObject("java", "java.security.MessageDigest").getInstance("SHA-256");
		var stream = createObject("java", "java.io.FileInputStream").init(arguments.path);
		try {
			var buffer = createObject("java", "java.lang.reflect.Array").newInstance(
				createObject("java", "java.lang.Byte").TYPE,
				javaCast("int", 65536)
			);
			var count = stream.read(buffer);
			while (count > 0) {
				digest.update(buffer, javaCast("int", 0), javaCast("int", count));
				count = stream.read(buffer);
			}
		} finally {
			stream.close();
		}
		return lCase(binaryEncode(digest.digest(), "hex"));
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

		// Another process on the port makes RustCFML exit at once ("Address
		// already in use"), which used to be reported as a successful start.
		if ($portInUse(arguments.port)) {
			throw(
				type = "Wheels.RustCFML.PortInUse",
				message = "Port " & arguments.port & " is already in use by another process, so RustCFML can't start there. Stop that process or pass --port=<a free port>."
			);
		}

		var bin = install();
		var logPath = variables.wheelsHome & "/rustcfml/servers/" & $projectKey(arguments.projectRoot) & ".log";
		$ensureParent(logPath);

		// The serve directory is passed as an ABSOLUTE path so the running
		// process's command line names this project: isProjectServerProcess()
		// relies on it to tell this project's server from a reused pid.
		var pb = createObject("java", "java.lang.ProcessBuilder").init(
			[bin, "--serve", $servePath(arguments.projectRoot), "--port", toString(arguments.port)]
		);
		// Run from the project root so `public` resolves, and detach I/O to a
		// log file so the server survives this command's exit without tying
		// itself to the CLI's stdout pipe.
		pb.directory(createObject("java", "java.io.File").init(arguments.projectRoot));
		pb.redirectOutput(createObject("java", "java.io.File").init(logPath));
		pb.redirectError(createObject("java", "java.io.File").init(logPath));
		var proc = pb.start();

		// Started means listening. Wait briefly for the port to open; a server
		// that exits first failed (e.g. it lost a race for the port) and is
		// reported as such, with the end of its log, and no state is recorded.
		var deadline = getTickCount() + 5000;
		while (getTickCount() < deadline && proc.isAlive() && !$portInUse(arguments.port)) {
			sleep(100);
		}
		if (!proc.isAlive()) {
			throw(
				type = "Wheels.RustCFML.StartFailed",
				message = "The RustCFML server exited right after starting. " & $logTail(logPath)
			);
		}

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

	/** Whether something is listening on `port` (IPv4 or IPv6). Public so specs can stub it. */
	public boolean function $portInUse(required numeric port) {
		return new modules.wheels.services.PortProbe().portInUse(arguments.port);
	}

	/** The last few lines of a server log, for an error message. */
	public string function $logTail(required string path) {
		if (!fileExists(arguments.path)) return "No log was written.";
		var lines = listToArray(fileRead(arguments.path), chr(10));
		var tail = [];
		for (var i = max(1, arrayLen(lines) - 4); i <= arrayLen(lines); i++) {
			arrayAppend(tail, trim(lines[i]));
		}
		return arrayLen(tail) ? "Log: " & arrayToList(tail, " | ") : "The log is empty.";
	}

	/**
	 * Is `pid` THIS project's RustCFML server (GHSA-x3cm-2j3q-jgg4)? A live
	 * pid is not proof: it can be stale and reused by another process. The
	 * process must run a binary this engine manages (under
	 * <wheelsHome>/rustcfml/bin) and its command line must serve this
	 * project's public directory by absolute path, as start() launches it.
	 * If the OS does not expose the executable or command line, the answer
	 * is no (fail closed). A server started by an older CLI with a relative
	 * `--serve public` is not recognised; restarting it fixes that.
	 */
	public boolean function isProjectServerProcess(required string pid, required string projectRoot) {
		var info = $processInfo(arguments.pid);
		if (!len(info.command) || !len(info.commandLine)) return false;
		var binDir = $binDir() & "/";
		if (left($canonical(info.command), len(binDir)) != binDir) return false;
		return find(" --serve " & $servePath(arguments.projectRoot) & " ", " " & info.commandLine & " ") > 0;
	}

	/** Canonical directory holding the RustCFML binaries this engine manages. */
	public string function $binDir() {
		return $canonical(variables.wheelsHome & "/rustcfml/bin");
	}

	/** Absolute path of the project's public directory, as passed to --serve. */
	public string function $servePath(required string projectRoot) {
		return $canonical(arguments.projectRoot) & "/public";
	}

	/**
	 * {command, commandLine} of `pid` ("" when not exposed). Public so specs
	 * can stub it.
	 */
	public struct function $processInfo(required string pid) {
		var info = {command: "", commandLine: ""};
		try {
			var handle = createObject("java", "java.lang.ProcessHandle").of(javaCast("long", arguments.pid));
			if (handle.isPresent()) {
				var details = handle.get().info();
				if (details.command().isPresent()) info.command = details.command().get();
				if (details.commandLine().isPresent()) info.commandLine = details.commandLine().get();
			}
		} catch (any e) {}
		return info;
	}

	private string function $canonical(required string path) {
		try {
			return replace(createObject("java", "java.io.File").init(arguments.path).getCanonicalPath(), "\", "/", "all");
		} catch (any e) {
			return replace(arguments.path, "\", "/", "all");
		}
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
		var system = createObject("java", "java.lang.System");
		var osName = system.getProperty("os.name");
		var osArch = system.getProperty("os.arch");
		// An x86_64 JVM on a Mac may be an Intel JDK under Rosetta on Apple
		// Silicon: ask the hardware, since the native binary runs there.
		var arm64Hardware = findNoCase("mac", osName) && !findNoCase("aarch64", osArch) && !findNoCase("arm64", osArch)
			? $macHasArm64Hardware()
			: false;
		return $assetFor(osName, osArch, arm64Hardware);
	}

	/** Whether this Mac's CPU is Apple Silicon (`sysctl hw.optional.arm64` is 1), whatever the JVM's arch. */
	public boolean function $macHasArm64Hardware() {
		try {
			var proc = createObject("java", "java.lang.ProcessBuilder").init(["/usr/sbin/sysctl", "-n", "hw.optional.arm64"])
				.redirectErrorStream(true).start();
			var answer = createObject("java", "java.io.BufferedReader")
				.init(createObject("java", "java.io.InputStreamReader").init(proc.getInputStream())).readLine();
			proc.waitFor();
			return !isNull(answer) && trim(answer) == "1";
		} catch (any e) {
			return false;
		}
	}

	/**
	 * The RustCFML release asset for `osName` / `osArch` (Java's os.name and
	 * os.arch), or Wheels.RustCFML.UnsupportedPlatform when RustCFML publishes
	 * no build for it. RustCFML releases ship Linux x86_64 and aarch64 and
	 * macOS aarch64 (Apple Silicon); there is no macOS x86_64 (Intel) build,
	 * which used to surface as a 404 from the download instead of this error.
	 * `arm64Hardware` marks an x86_64 JVM on Apple Silicon (Rosetta), which
	 * gets the native arm64 build.
	 */
	public string function $assetFor(required string osName, required string osArch, boolean arm64Hardware = false) {
		var isMac = findNoCase("mac", arguments.osName) > 0;
		var isLinux = findNoCase("linux", arguments.osName) > 0;
		var isArm = findNoCase("aarch64", arguments.osArch) > 0 || findNoCase("arm64", arguments.osArch) > 0;
		var isX64 = findNoCase("amd64", arguments.osArch) > 0 || findNoCase("x86_64", arguments.osArch) > 0;

		if (isMac && (isArm || arguments.arm64Hardware)) return "rustcfml-macos-aarch64";
		if (isLinux && isArm) return "rustcfml-linux-aarch64";
		if (isLinux && isX64) return "rustcfml-linux-x86_64";
		if (isMac && isX64) {
			throw(
				type = "Wheels.RustCFML.UnsupportedPlatform",
				message = "RustCFML publishes no macOS Intel (x86_64) build, so the RustCFML engine can't run on this Mac.",
				detail = "Use the default engine (wheels start), or run RustCFML on Apple Silicon or Linux."
			);
		}
		throw(
			type = "Wheels.RustCFML.UnsupportedPlatform",
			message = "RustCFML publishes no build for #arguments.osName# / #arguments.osArch#.",
			detail = "RustCFML builds exist for Linux (x86_64, aarch64) and macOS on Apple Silicon. Use the default engine (wheels start)."
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
	 * blocking curl download and the kill/liveness probes.
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
