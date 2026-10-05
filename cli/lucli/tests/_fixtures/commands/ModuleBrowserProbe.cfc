/**
 * Output-capturing Module whose process runner returns a spec-controlled
 * result, so the browser-setup specs can drive the launch probe through a
 * timeout, a crash, a missing screenshot or a success without Playwright.
 * With `writeShot`, the fake writes the screenshot (the last argv element)
 * before returning, the way a real run that got that far would.
 */
component extends="cli.lucli.tests._fixtures.commands.ModuleOutputCapture" {

	public void function setProcessResult(
		numeric exitCode = 0,
		boolean timedOut = false,
		string output = "",
		boolean writeShot = false
	) {
		variables.fakeProcess = {
			exitCode: arguments.exitCode,
			timedOut: arguments.timedOut,
			output: arguments.output,
			writeShot: arguments.writeShot,
			lastShot: ""
		};
	}

	/** The screenshot path of the last probe, for checking it was removed. */
	public string function lastShot() {
		return variables.fakeProcess.lastShot;
	}

	public struct function $browserRunProcess(required array argv, required numeric timeoutSeconds) {
		var shot = arguments.argv[arrayLen(arguments.argv)];
		variables.fakeProcess.lastShot = shot;
		if (variables.fakeProcess.writeShot) {
			fileWrite(shot, "png");
		}
		return {
			exitCode: variables.fakeProcess.exitCode,
			timedOut: variables.fakeProcess.timedOut,
			output: variables.fakeProcess.output
		};
	}

}
