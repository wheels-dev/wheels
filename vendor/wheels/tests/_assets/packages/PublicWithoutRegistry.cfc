component extends="wheels.Public" {

	/**
	 * Overrides the parent's file-existence check to return false —
	 * simulates a generated user app where cli/ is not shipped.
	 */
	private boolean function $registryClientAvailable() {
		return false;
	}
}
