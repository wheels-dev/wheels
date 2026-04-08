/**
 * Engine adapter for Adobe ColdFusion.
 * Overrides response access (FusionContext), request timeout (RequestMonitor),
 * and Oracle TIMESTAMP handling for $convertToString.
 */
component extends="wheels.engineAdapters.Base" output="false" {

	variables.engineName = "Adobe ColdFusion";

	public boolean function isAdobe() {
		return true;
	}

	/**
	 * Adobe CF requires getFusionContext() to access the response object.
	 */
	public any function getResponse() {
		return GetPageContext().getFusionContext().getResponse();
	}

	/**
	 * Adobe CF uses the Java RequestMonitor class for timeout values.
	 */
	public numeric function getRequestTimeout() {
		return CreateObject("java", "coldfusion.runtime.RequestMonitor").GetRequestTimeout();
	}

	/**
	 * Adobe CF also needs Oracle TIMESTAMP coercion in $convertToString.
	 * (Both Adobe and BoxLang encounter oracle.sql.TIMESTAMP objects.)
	 */
	public any function coerceOracleObject(required any value) {
		if (!IsObject(arguments.value) || IsStruct(arguments.value)) {
			return arguments.value;
		}
		try {
			local.className = GetMetadata(arguments.value).getName();
		} catch (any e) {
			return arguments.value;
		}
		if (local.className == "oracle.sql.TIMESTAMP" || local.className == "oracle.sql.DATE") {
			try {
				return ParseDateTime(arguments.value.toString());
			} catch (any e) {
				return arguments.value.toString();
			}
		}
		return arguments.value;
	}

}
