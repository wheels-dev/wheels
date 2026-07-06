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
	 * RustCFML implements the `cfcache` built-in as of v0.417. Earlier
	 * builds lacked it and this override returned false so Wheels degraded
	 * its cfcache-backed template/static cache (see Global.cfc $cache) to a
	 * no-op. The override is kept (returning the Base default) purely as a
	 * record of the resolved divergence.
	 */
	public boolean function supportsCfcache() {
		return true;
	}

	/**
	 * RustCFML has no JVM and therefore no AWT/ImageIO-backed image runtime,
	 * so Base.cfc's cfimage action="info" implementation is unavailable.
	 * Callers such as $imageTag() use this to skip the width/height probe
	 * and render the tag without dimensions instead of erroring.
	 */
	public boolean function supportsImageInfo() {
		return false;
	}

	/**
	 * Defensive fallback for callers that reach imageInfo() despite
	 * supportsImageInfo() being false: returns the same struct shape
	 * Base.cfc's cfimage action="info" produces, with width/height 0
	 * meaning "unknown" ($imageTag only emits the attributes when > 0).
	 */
	public struct function imageInfo(required string source) {
		return {width: 0, height: 0, source: arguments.source};
	}

}
