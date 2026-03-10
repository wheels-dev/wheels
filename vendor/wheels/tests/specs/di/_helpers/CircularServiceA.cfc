/**
 * Test service that depends on CircularServiceB (creates circular dependency).
 */
component {

	public CircularServiceA function init(required any circularServiceB) {
		variables.other = arguments.circularServiceB;
		return this;
	}

}
