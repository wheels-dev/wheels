/**
 * Shared lifecycle helper for deploy integration tests.
 *
 * Wraps tools/deploy-*-up.sh / tools/deploy-*-down.sh so individual
 * specs don't need inline ProcessBuilder boilerplate.
 */
component {

	public void function sshdUp() {
		runShell("bash tools/deploy-sshd-up.sh");
	}

	/**
	 * The sshd fixture is one shared Docker Compose project on fixed ports
	 * (22022/22023), so a teardown here would pull the containers out from under
	 * another checkout's CLI suite running at the same time ("Connection reset",
	 * "Exhausted available authentication methods"; #4232). `up -d` is
	 * idempotent, so the fixture stays up by default; set
	 * WHEELS_DEPLOY_SSHD_TEARDOWN=1 to stop it after each spec, or run
	 * tools/deploy-sshd-down.sh when done. CI runners are discarded anyway.
	 */
	public void function sshdDown() {
		var teardown = createObject("java", "java.lang.System").getenv("WHEELS_DEPLOY_SSHD_TEARDOWN");
		if (!isNull(teardown) && teardown == "1") {
			runShell("bash tools/deploy-sshd-down.sh");
		}
	}

	public void function e2eUp() {
		runShell("bash tools/deploy-e2e-up.sh");
	}

	public void function e2eDown() {
		runShell("bash tools/deploy-e2e-down.sh");
	}

	private void function runShell(required string cmd) {
		// Anchor cwd at the project root — CFC lives at
		// cli/lucli/tests/_helpers/, so ../../../../ resolves up to repo root.
		var here = getDirectoryFromPath(getCurrentTemplatePath());
		var projectRoot = getCanonicalPath(here & "../../../../");
		var pb = createObject("java", "java.lang.ProcessBuilder")
			.init(["sh", "-c", arguments.cmd]);
		pb.directory(createObject("java", "java.io.File").init(projectRoot));
		pb.redirectErrorStream(true);
		// Output to a file (no pipe to fill) and a bounded wait: a stuck docker or
		// sshd fixture fails this bundle with its output instead of hanging the
		// whole CLI suite request (#4232).
		var outFile = getTempFile(getTempDirectory(), "wheels-deploy-shell");
		pb.redirectOutput(createObject("java", "java.io.File").init(outFile));
		var proc = pb.start();
		var finished = proc.waitFor(javaCast("long", 180), createObject("java", "java.util.concurrent.TimeUnit").SECONDS);
		if (!finished) proc.destroyForcibly();
		var output = fileExists(outFile) ? fileRead(outFile, "utf-8") : "";
		if (fileExists(outFile)) fileDelete(outFile);
		if (!finished) {
			throw(
				type = "DeployShellHelper.ShellTimedOut",
				message = "Shell command did not finish within 180 s: #arguments.cmd#",
				detail = output
			);
		}
		var exit = proc.exitValue();
		if (exit != 0) {
			throw(
				type = "DeployShellHelper.ShellFailed",
				message = "Shell command failed (exit #exit#): #arguments.cmd#",
				detail = output
			);
		}
	}

}
