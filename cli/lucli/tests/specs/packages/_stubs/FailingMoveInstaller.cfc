/**
 * An Installer whose final move into vendor/ fails, to exercise the rollback
 * of an installed copy. failMove("partial") first leaves a half-written
 * target behind, as an interrupted cross-volume copy would.
 */
component extends="cli.lucli.services.packages.Installer" {

	public FailingMoveInstaller function failMove(string mode = "clean") {
		variables.failMode = arguments.mode;
		return this;
	}

	private void function $moveInto(required string src, required string dest) {
		if ((variables.failMode ?: "clean") == "partial") {
			DirectoryCreate(arguments.dest, true);
			FileWrite(arguments.dest & "/half-copied.txt", "partial");
		}
		Throw(type = "Spec.MoveFailed", message = "The final move into vendor/ failed.");
	}
}
