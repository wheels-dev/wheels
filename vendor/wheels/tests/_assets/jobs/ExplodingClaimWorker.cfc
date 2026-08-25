/**
 * Test worker whose claim always persist-fails. S6: processNext must
 * contain that as a failed result, not an idle skip.
 */
component extends="wheels.JobWorker" {

	public boolean function $claimJob(required string jobId) {
		throw(type = "Wheels.JobClaimFailed", message = "claim persist failed");
	}

}
