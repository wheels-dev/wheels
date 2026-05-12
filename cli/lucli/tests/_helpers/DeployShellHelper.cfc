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

	public void function sshdDown() {
		runShell("bash tools/deploy-sshd-down.sh");
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
		var proc = pb.start();
		// Drain stdout so child doesn't block on a full pipe. Also gives us
		// something to surface if the script fails.
		var output = $drainStream(proc.getInputStream());
		var exit = proc.waitFor();
		if (exit != 0) {
			throw(
				type = "DeployShellHelper.ShellFailed",
				message = "Shell command failed (exit #exit#): #arguments.cmd#",
				detail = output
			);
		}
	}

	private string function $drainStream(required any stream) {
		var baos = createObject("java", "java.io.ByteArrayOutputStream").init();
		var buffer = createObject("java", "java.lang.reflect.Array")
			.newInstance(createObject("java", "java.lang.Byte").TYPE, javaCast("int", 8192));
		while (true) {
			var n = arguments.stream.read(buffer);
			if (n <= 0) break;
			baos.write(buffer, javaCast("int", 0), javaCast("int", n));
		}
		return baos.toString("UTF-8");
	}

}
