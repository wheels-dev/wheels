/**
 * Test fixture for asserting what Module.cfc actually PRINTS, not just
 * what it returns or throws.
 *
 * The BaseModule test double's out() is a no-op, so specs normally can't
 * see console output — fine for return-value contracts, blind for output
 * ordering bugs. The #3039 review's blocking finding is exactly such a
 * bug: the pre-swap restore one-liner (`rm -rf … && mv …`) printed before
 * the service-level refusal checks ran, so every refusal path handed the
 * user a restore command for a backup that was never made.
 *
 * This fixture extends Module and overrides out() to accumulate every
 * line, so refusal specs can assert the restore command is ABSENT from
 * the printed output (and success specs can assert it is present).
 */
component extends="cli.lucli.Module" {

	void function out(any message, string colour = "", string style = "") {
		if (!structKeyExists(variables, "capturedLines")) {
			variables.capturedLines = [];
		}
		arrayAppend(variables.capturedLines, toString(arguments.message));
	}

	/**
	 * Everything out() printed so far, newline-joined, in order.
	 */
	public string function capturedOutput() {
		if (!structKeyExists(variables, "capturedLines")) {
			return "";
		}
		return arrayToList(variables.capturedLines, chr(10));
	}

}
