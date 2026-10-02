/**
 * A RustCFML engine backend for a platform RustCFML publishes no build for:
 * isInstalled(), install() and start() throw what RustCFMLEngine.$assetFor() throws on an
 * Intel Mac. Used to pin the CLI's exit status for that case (#3815).
 */
component {

	public boolean function isInstalled() {
		$refuse();
	}

	public string function getEngineVersion() {
		return "0.0.0-stub";
	}

	public string function install() {
		$refuse();
	}

	public struct function start(required string projectRoot, numeric port = 8513) {
		$refuse();
	}

	private void function $refuse() {
		throw(
			type = "Wheels.RustCFML.UnsupportedPlatform",
			message = "RustCFML publishes no macOS Intel (x86_64) build, so the RustCFML engine can't run on this Mac.",
			detail = "Use the default engine (wheels start), or run RustCFML on Apple Silicon or Linux."
		);
	}

}
