/**
 * Engine adapter for Lucee CFML.
 * Lucee is the primary target engine — most defaults in Base.cfc
 * already match Lucee behavior. This adapter only sets the engine name.
 */
component extends="wheels.engineAdapters.Base" output="false" {

	variables.engineName = "Lucee";

}
