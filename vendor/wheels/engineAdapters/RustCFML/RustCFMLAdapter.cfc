/**
 * Engine adapter for RustCFML — an experimental, JVM-free CFML runtime
 * written in Rust (https://github.com/RustCFML/RustCFML).
 *
 * RustCFML's CFML semantics track Lucee closely, so Base.cfc's
 * Lucee-shaped defaults apply unchanged for most behavior. This adapter
 * records the divergences we've confirmed against RustCFML so far; add an
 * override here whenever a new divergence is found rather than scattering
 * `serverName == "RustCFML"` checks through the framework.
 */
component extends="wheels.engineAdapters.Base" output="false" {

	variables.engineName = "RustCFML";

	public boolean function isRustCFML() {
		return true;
	}

	/**
	 * RustCFML (as of 0.41.0) does not implement the `cfcache` built-in.
	 * Returning false makes Wheels skip its cfcache-backed template/static
	 * cache (see Global.cfc $cache) so the framework boots and serves
	 * cacheless-but-working instead of erroring on the missing built-in.
	 */
	public boolean function supportsCfcache() {
		return false;
	}

}
