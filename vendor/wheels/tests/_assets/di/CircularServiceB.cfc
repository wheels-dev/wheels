/**
 * Test service that depends on CircularServiceA (creates circular dependency).
 */
component {

	public CircularServiceB function init(required any circularServiceA) {
		variables.other = arguments.circularServiceA;
		return this;
	}

}
