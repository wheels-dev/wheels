/**
 * Engine adapter for Lucee CFML.
 * Lucee is the primary target engine — most defaults in Base.cfc
 * already match Lucee behavior. This adapter only overrides where
 * Lucee differs from the common defaults.
 */
component extends="wheels.engineAdapters.Base" output="false" {

	variables.engineName = "Lucee";

	public boolean function isLucee() {
		return true;
	}

	/**
	 * Lucee uppercases method names passed to onMissingMethod, so we
	 * lowercase the property names after stripping the finder prefix.
	 */
	public array function dynamicFinderProperties(required string methodName, required string prefix) {
		return ListToArray(
			LCase(
				ReplaceNoCase(
					ReplaceNoCase(
						ReplaceNoCase(arguments.methodName, "And", "|", "all"),
						"findAllBy", "", "all"
					),
					"findOneBy", "", "all"
				)
			),
			"|"
		);
	}

	/**
	 * Lucee default port is 60000 (when running in Docker/CommandBox).
	 */
	public numeric function getDefaultPort() {
		return 60000;
	}

}
