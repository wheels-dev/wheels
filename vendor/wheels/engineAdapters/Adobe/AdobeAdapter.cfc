/**
 * Engine adapter for Adobe ColdFusion.
 * Overrides response access (FusionContext) and request timeout (RequestMonitor).
 */
component extends="wheels.engineAdapters.Base" output="false" {

	variables.engineName = "Adobe ColdFusion";

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

}
