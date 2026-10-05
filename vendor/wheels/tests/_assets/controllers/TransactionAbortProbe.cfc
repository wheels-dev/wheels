/**
 * Test-asset controller for transactionAbortRollbackSpec. Runs one scenario of a write inside a
 * Wheels transaction (invokeWithTransaction with transaction = "commit") that ends the request with
 * `abort`, or completes normally, for the row marker in params.marker.
 */
component extends="Controller" {

	function run() {
		var methods = {
			abort = "insertThenAbort",
			nestedAbort = "outerThenNestedAbort",
			savepointAbort = "outerThenSavepointAbort",
			commit = "insertThenReturn",
			savepointFalse = "outerThenSavepointFalse"
		};
		model("transactionAbortProbe").invokeWithTransaction(
			method = methods[params.scenario],
			transaction = "commit",
			marker = params.marker
		);
		renderText("done");
	}

}
