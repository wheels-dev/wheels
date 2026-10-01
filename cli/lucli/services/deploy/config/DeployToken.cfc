/**
 * Shape check for values that are interpolated into deploy shell commands as
 * bare tokens: the release version (container names, image tags, labels) and
 * the destination (labels, env-file paths). Both come from CLI flags, CI
 * variables or git ref names, so they are validated where they are used rather
 * than trusted from the caller.
 */
component {

	/**
	 * Returns the value unchanged when it is a safe token; throws
	 * Wheels.Deploy.InvalidInput otherwise. `allowEmpty` admits "" (an unset
	 * destination) without admitting anything else.
	 */
	public string function assert(
		required string value,
		required string kind,
		boolean allowEmpty = false
	) {
		if (arguments.allowEmpty && !len(arguments.value)) {
			return arguments.value;
		}
		// Length and "no character outside the class" are checked separately:
		// in the CFML regex dialect `$` also matches before a trailing line
		// feed, so an anchored ^...$ pattern would admit "v1<LF>".
		if (len(arguments.value) < 1 || len(arguments.value) > 128 || reFind("[^A-Za-z0-9._-]", arguments.value)) {
			throw(
				type = "Wheels.Deploy.InvalidInput",
				message = "Invalid deploy #arguments.kind# '#arguments.value#': use 1-128 letters, digits, dots, underscores or hyphens."
			);
		}
		return arguments.value;
	}

}
